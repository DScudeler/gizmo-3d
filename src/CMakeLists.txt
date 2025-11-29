# Create a static library for the backing target
add_library(gizmo3d STATIC)

# Mark singletons for Qt6
set_source_files_properties(
    GizmoMath.qml
    GizmoProjection.qml
    GizmoEnums.qml
    View3DProjectionAdapter.qml
    MockProjection.qml
    geometry/TranslationGeometryCalculator.qml
    geometry/RotationGeometryCalculator.qml
    geometry/ScaleGeometryCalculator.qml
    geometry/HitTester.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# Skip type compiler for files with enum conflicts (None in both Axis and Plane)
set_source_files_properties(
    GizmoEnums.qml
    PROPERTIES QT_QML_SKIP_TYPE_COMPILER TRUE)

qt_add_qml_module(gizmo3d
    URI Gizmo3D
    VERSION 0.1
    ENABLE_TYPE_COMPILER  # Requires: sudo apt install qt6-declarative-private-dev qt6-quick3d-private-dev
    QML_FILES
        TranslationGizmo.qml
        RotationGizmo.qml
        ScaleGizmo.qml
        GlobalGizmo.qml
        GizmoMath.qml
        GizmoEnums.qml
        GizmoProjection.qml
        View3DProjectionAdapter.qml
        MockProjection.qml
        geometry/TranslationGeometryCalculator.qml
        geometry/RotationGeometryCalculator.qml
        geometry/ScaleGeometryCalculator.qml
        geometry/HitTester.qml
        drawing/ArrowRenderer.qml
        drawing/ScaleArrowRenderer.qml
        drawing/CircleRenderer.qml
        drawing/PlaneRenderer.qml
        drawing/SquareHandleRenderer.qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/src/Gizmo3D
    NO_PLUGIN
)

target_link_libraries(gizmo3d PRIVATE
    Qt6::Quick
    Qt6::Quick3D
    Qt6::QmlPrivate         # Required for ENABLE_TYPE_COMPILER
    Qt6::QuickPrivate       # Required for ENABLE_TYPE_COMPILER (qquickevents_p_p.h)
    Qt6::QuickShapesPrivate # Required for ENABLE_TYPE_COMPILER (qquickshape_p.h)
    Qt6::Quick3DPrivate     # Required for ENABLE_TYPE_COMPILER (qquick3dviewport_p.h)
)
