qt_add_executable(tst_translationgizmo
    tst_translationgizmo.cpp
)

target_link_libraries(tst_translationgizmo PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
    gizmo3dplugin
)

# Add test to CTest
add_test(NAME TranslationGizmoTest COMMAND tst_translationgizmo)

# Set QML2_IMPORT_PATH environment variable for test
set_tests_properties(TranslationGizmoTest PROPERTIES
    ENVIRONMENT "QML2_IMPORT_PATH=${CMAKE_BINARY_DIR}/src"
)

# Set QML import path for tests
target_compile_definitions(tst_translationgizmo PRIVATE
    QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/src"
)

set_target_properties(tst_translationgizmo PROPERTIES
    AUTOMOC ON
)
