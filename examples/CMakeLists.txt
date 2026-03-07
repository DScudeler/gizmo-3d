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

# Stress test example
qt_add_executable(gizmo3d_stress_test
    stress_test/main.cpp
)

set_source_files_properties(stress_test/main.qml PROPERTIES
    QT_RESOURCE_ALIAS main.qml
)
set_source_files_properties(stress_test/SimpleController.qml PROPERTIES
    QT_RESOURCE_ALIAS SimpleController.qml
)

qt_add_qml_module(gizmo3d_stress_test
    URI StressTest
    VERSION 1.0
    QML_FILES
        stress_test/main.qml
        stress_test/SimpleController.qml
)

target_compile_definitions(gizmo3d_stress_test PRIVATE QT_QML_DEBUG)

target_link_libraries(gizmo3d_stress_test PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)
