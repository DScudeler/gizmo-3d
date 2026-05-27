#include "rotationgeometrycalculator.h"

#include <QtQml/qjsengine.h>
#include <QVariantMap>
#include <QVariantList>
#include <cmath>

static inline QVector3D toVec(const QJSValue &v)
{
    return v.toVariant().value<QVector3D>();
}
static inline double numOr(const QJSValue &obj, const char *key, double def)
{
    const QJSValue p = obj.property(QString::fromLatin1(key));
    return p.isNumber() ? p.toNumber() : def;
}

RotationGeometryCalculator::RotationGeometryCalculator(QObject *parent) : QObject(parent) {}

QPointF RotationGeometryCalculator::Projector::project(const QVector3D &world)
{
    if (viewport) {
        QVector3D out;
        mapMethod.invoke(viewport, Qt::DirectConnection,
                         Q_RETURN_ARG(QVector3D, out), Q_ARG(QVector3D, world));
        return QPointF(out.x(), out.y());
    }
    const QJSValue r = jsFn.callWithInstance(jsProjector,
                                             QJSValueList{ engine->toScriptValue(world) });
    return QPointF(r.property(QStringLiteral("x")).toNumber(),
                   r.property(QStringLiteral("y")).toNumber());
}

RotationGeometryCalculator::Projector
RotationGeometryCalculator::resolveProjector(const QJSValue &projectorVal)
{
    Projector p;
    // Production fast path: the View3DProjectionAdapter projector exposes its View3D; call
    // mapFrom3DScene natively (no JS round-trip per point).
    const QJSValue v3 = projectorVal.property(QStringLiteral("view3d"));
    if (v3.isQObject()) {
        if (QObject *vp = v3.toQObject()) {
            const int idx = vp->metaObject()->indexOfMethod("mapFrom3DScene(QVector3D)");
            if (idx >= 0) {
                p.viewport = vp;
                p.mapMethod = vp->metaObject()->method(idx);
                p.valid = true;
                return p;
            }
        }
    }
    // Fallback (mock/test projectors): call the JS projectWorldToScreen closure.
    QJSValue fn = projectorVal.property(QStringLiteral("projectWorldToScreen"));
    if (fn.isCallable()) {
        p.jsProjector = projectorVal;
        p.jsFn = fn;
        p.engine = qjsEngine(this);
        p.valid = (p.engine != nullptr);
    }
    return p;
}

void RotationGeometryCalculator::ensureTable(int segments)
{
    if (segments == m_tableSegments)
        return;
    m_cos.assign(segments + 1, 0.0);
    m_sin.assign(segments + 1, 0.0);
    for (int i = 0; i <= segments; ++i) {
        const double a = (double(i) / segments) * M_PI * 2.0;
        m_cos[i] = std::cos(a);
        m_sin[i] = std::sin(a);
    }
    m_tableSegments = segments;
}

QVariant RotationGeometryCalculator::calculateCircleGeometry(const QJSValue &config)
{
    if (!config.isObject())
        return QVariant();

    Projector proj = resolveProjector(config.property(QStringLiteral("projector")));
    if (!proj.valid) {
        qWarning("RotationGeometryCalculator: invalid projector");
        return QVariant();
    }

    const QVector3D target = toVec(config.property(QStringLiteral("targetPosition")));
    const QJSValue axes = config.property(QStringLiteral("axes"));
    const QVector3D ax = toVec(axes.property(QStringLiteral("x")));
    const QVector3D ay = toVec(axes.property(QStringLiteral("y")));
    const QVector3D az = toVec(axes.property(QStringLiteral("z")));

    const double gizmoSize = numOr(config, "gizmoSize", 80.0);
    const double maxScreenRadius = numOr(config, "maxScreenRadius", 100.0);
    int segments = 48;
    {
        const QJSValue s = config.property(QStringLiteral("segments"));
        if (s.isNumber()) segments = s.toInt();
    }
    const double smoothing = numOr(config, "smoothingFactor", 0.3);

    const QPointF center = proj.project(target);

    auto axisScale = [&](const QVector3D &axis) {
        const QPointF s = proj.project(target + axis);
        const double dx = s.x() - center.x(), dy = s.y() - center.y();
        return std::sqrt(dx * dx + dy * dy);
    };
    const double sx = axisScale(QVector3D(1, 0, 0));
    const double sy = axisScale(QVector3D(0, 1, 0));
    const double sz = axisScale(QVector3D(0, 0, 1));
    const double xyS = (sx + sy) / 2.0, yzS = (sy + sz) / 2.0, zxS = (sz + sx) / 2.0;

    double rXY = xyS > 0 ? gizmoSize / xyS : 1.0;
    double rYZ = yzS > 0 ? gizmoSize / yzS : 1.0;
    double rZX = zxS > 0 ? gizmoSize / zxS : 1.0;

    const QJSValue prev = config.property(QStringLiteral("previousRadii"));
    if (prev.isObject()) {
        auto lerp = [](double a, double b, double t) { return a + (b - a) * t; };
        rXY = lerp(prev.property(QStringLiteral("xy")).toNumber(), rXY, smoothing);
        rYZ = lerp(prev.property(QStringLiteral("yz")).toNumber(), rYZ, smoothing);
        rZX = lerp(prev.property(QStringLiteral("zx")).toNumber(), rZX, smoothing);
    }

    ensureTable(segments);

    auto genCircle = [&](const QVector3D &a1, const QVector3D &a2, double r) {
        QVector<QPointF> out;
        out.reserve(segments + 1);
        for (int i = 0; i <= segments; ++i) {
            const double c = m_cos[i], s = m_sin[i];
            const QVector3D w(target.x() + a1.x() * c * r + a2.x() * s * r,
                              target.y() + a1.y() * c * r + a2.y() * s * r,
                              target.z() + a1.z() * c * r + a2.z() * s * r);
            out.append(proj.project(w));
        }
        return out;
    };
    auto genCircleZX = [&](const QVector3D &aX, const QVector3D &aZ, double r) {
        QVector<QPointF> out;
        out.reserve(segments + 1);
        for (int i = 0; i <= segments; ++i) {
            const double c = m_cos[i], s = m_sin[i];   // sin on X, cos on Z (matches original)
            const QVector3D w(target.x() + aX.x() * s * r + aZ.x() * c * r,
                              target.y() + aX.y() * s * r + aZ.y() * c * r,
                              target.z() + aX.z() * s * r + aZ.z() * c * r);
            out.append(proj.project(w));
        }
        return out;
    };

    QVector<QPointF> xy = genCircle(ax, ay, rXY);
    QVector<QPointF> yz = genCircle(ay, az, rYZ);
    QVector<QPointF> zx = genCircleZX(ax, az, rZX);

    auto clamp = [&](QVector<QPointF> &pts, double &radius) {
        double maxDist = 0.0;
        for (const QPointF &p : pts) {
            const double dx = p.x() - center.x(), dy = p.y() - center.y();
            maxDist = std::max(maxDist, std::sqrt(dx * dx + dy * dy));
        }
        if (maxDist > maxScreenRadius) {
            const double k = maxScreenRadius / maxDist;
            for (QPointF &p : pts)
                p = QPointF(center.x() + (p.x() - center.x()) * k,
                            center.y() + (p.y() - center.y()) * k);
            radius *= k;
        }
    };
    clamp(xy, rXY);
    clamp(yz, rYZ);
    clamp(zx, rZX);

    auto toList = [](const QVector<QPointF> &v) {
        QVariantList l;
        l.reserve(v.size());
        for (const QPointF &p : v) l.append(p);
        return l;
    };

    QVariantMap circles{ {QStringLiteral("xy"), toList(xy)},
                         {QStringLiteral("yz"), toList(yz)},
                         {QStringLiteral("zx"), toList(zx)} };
    QVariantMap radii{ {QStringLiteral("xy"), rXY},
                       {QStringLiteral("yz"), rYZ},
                       {QStringLiteral("zx"), rZX} };
    QVariantMap result{ {QStringLiteral("center"), center},
                        {QStringLiteral("circles"), circles},
                        {QStringLiteral("radii"), radii} };
    return result;
}

double RotationGeometryCalculator::calculateCameraFacingAngle(const QVector3D &targetPosition,
                                                              const QVector3D &planeNormal,
                                                              const QVector3D &referenceAxis,
                                                              const QJSValue &projector)
{
    QJSValue getCam = projector.property(QStringLiteral("getCameraPosition"));
    if (!getCam.isCallable())
        return 0.0;
    const QJSValue camV = getCam.callWithInstance(projector, QJSValueList{});
    const QVector3D cameraPos(camV.property(QStringLiteral("x")).toNumber(),
                              camV.property(QStringLiteral("y")).toNumber(),
                              camV.property(QStringLiteral("z")).toNumber());

    const QVector3D toCam = cameraPos - targetPosition;
    const double dot = QVector3D::dotProduct(toCam, planeNormal);
    QVector3D projDir = toCam - planeNormal * dot;
    const double len = projDir.length();
    if (len < 0.001)
        return 0.0;
    projDir /= len;

    const QVector3D perp = QVector3D::crossProduct(planeNormal, referenceAxis);
    const double cosA = QVector3D::dotProduct(projDir, referenceAxis);
    const double sinA = QVector3D::dotProduct(projDir, perp);
    double angle = std::atan2(sinA, cosA);
    while (angle < 0) angle += M_PI * 2.0;
    while (angle >= M_PI * 2.0) angle -= M_PI * 2.0;
    return angle;
}
