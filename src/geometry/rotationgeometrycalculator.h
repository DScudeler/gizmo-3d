// rotationgeometrycalculator.h - C++ drop-in for the Gizmo3D rotation circle calculator.
//
// Registers as the QML singleton `RotationGeometryCalculator` in module Gizmo3D, replacing
// the former QML implementation with identical method signatures so RotationGizmo, the
// renderers, and the tests are unchanged. The hot path (calculateCircleGeometry) projects
// natively via View3D::mapFrom3DScene when the projector exposes a `view3d` QObject
// (production path), and falls back to calling the projector's JS projectWorldToScreen for
// mock/test projectors.
#pragma once

#include <QObject>
#include <QJSValue>
#include <QVariant>
#include <QVector3D>
#include <QPointF>
#include <QMetaMethod>
#include <vector>
#include <QtQml/qqmlregistration.h>

class RotationGeometryCalculator : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(RotationGeometryCalculator)
    QML_SINGLETON
public:
    explicit RotationGeometryCalculator(QObject *parent = nullptr);

    // config: { projector, targetPosition, axes:{x,y,z}, gizmoSize, maxScreenRadius,
    //           segments, previousRadii:{xy,yz,zx}|null, smoothingFactor }
    // returns: { center:point, circles:{xy:[point],yz:[point],zx:[point]}, radii:{xy,yz,zx} } | null
    Q_INVOKABLE QVariant calculateCircleGeometry(const QJSValue &config);

    Q_INVOKABLE double calculateCameraFacingAngle(const QVector3D &targetPosition,
                                                  const QVector3D &planeNormal,
                                                  const QVector3D &referenceAxis,
                                                  const QJSValue &projector);

private:
    // A projection callable resolved once per calculateCircleGeometry call.
    struct Projector {
        // native path
        QObject *viewport = nullptr;
        QMetaMethod mapMethod;
        // js fallback path
        QJSValue jsProjector;
        QJSValue jsFn;
        QJSEngine *engine = nullptr;
        bool valid = false;
        QPointF project(const QVector3D &world);
    };
    Projector resolveProjector(const QJSValue &projectorVal);

    void ensureTable(int segments);
    std::vector<double> m_cos, m_sin;   // cached unit-circle template
    int m_tableSegments = -1;
};
