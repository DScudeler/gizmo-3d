qt_add_executable(gizmo3d_example
    main.cpp
)

qt_add_qml_module(gizmo3d_example
    URI Example
    VERSION 1.0
    QML_FILES
        main.qml
        SimpleController.qml
)

target_compile_definitions(gizmo3d_example PRIVATE QT_QML_DEBUG)

target_link_libraries(gizmo3d_example PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)
