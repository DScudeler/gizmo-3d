qt_add_library(gizmo3d SHARED)

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
    geometry/GeometryTemplates.qml
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
        geometry/GeometryTemplates.qml
        drawing/ArrowRenderer.qml
        drawing/ScaleArrowRenderer.qml
        drawing/CircleRenderer.qml
        drawing/PlaneRenderer.qml
        drawing/SquareHandleRenderer.qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/src/Gizmo3D
    PLUGIN_TARGET gizmo3d
)

target_link_libraries(gizmo3d PRIVATE
    Qt6::Quick
    Qt6::Quick3D
)

# Install targets
include(GNUInstallDirs)

install(TARGETS gizmo3d
    EXPORT gizmo3dTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

include(CMakePackageConfigHelpers)

install(EXPORT gizmo3dTargets
    FILE gizmo3dTargets.cmake
    NAMESPACE Gizmo3D::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/gizmo3d
)

configure_package_config_file(
    ${CMAKE_SOURCE_DIR}/cmake/gizmo3dConfig.cmake.in
    ${CMAKE_BINARY_DIR}/gizmo3dConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/gizmo3d
)

write_basic_package_version_file(
    ${CMAKE_BINARY_DIR}/gizmo3dConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_BINARY_DIR}/gizmo3dConfig.cmake
    ${CMAKE_BINARY_DIR}/gizmo3dConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/gizmo3d
)
