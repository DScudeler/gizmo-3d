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

qt_add_qml_module(gizmo3d
    URI Gizmo3D
    VERSION 0.1
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
        drawing/ArrowPrimitive.qml
        drawing/CirclePrimitive.qml
        drawing/PlanePrimitive.qml
        drawing/SquareHandlePrimitive.qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/src/Gizmo3D
    NO_PLUGIN
)

target_link_libraries(gizmo3d PRIVATE
    Qt6::Quick
    Qt6::Quick3D
)
