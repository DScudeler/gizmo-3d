# Create a static library for the backing target
add_library(gizmo3d STATIC)

qt_add_qml_module(gizmo3d
    URI Gizmo3D
    VERSION 1.0
    QML_FILES
        TranslationGizmo.qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/src/Gizmo3D
)

target_link_libraries(gizmo3d PRIVATE
    Qt6::Quick
    Qt6::Quick3D
)
