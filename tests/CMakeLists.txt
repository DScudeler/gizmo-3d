qt_add_executable(tst_translationgizmo
    tst_translationgizmo.cpp
)

target_link_libraries(tst_translationgizmo PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)

# Add test to CTest
add_test(NAME TranslationGizmoTest COMMAND tst_translationgizmo)

set_target_properties(tst_translationgizmo PROPERTIES
    AUTOMOC ON
)

# RotationGizmo Test
qt_add_executable(tst_rotationgizmo
    tst_rotationgizmo.cpp
)

target_link_libraries(tst_rotationgizmo PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)

# Add test to CTest
add_test(NAME RotationGizmoTest COMMAND tst_rotationgizmo)

set_target_properties(tst_rotationgizmo PROPERTIES
    AUTOMOC ON
)

# TranslationGizmo Snap Test
qt_add_executable(tst_translationgizmo_snap
    tst_translationgizmo_snap.cpp
)

target_link_libraries(tst_translationgizmo_snap PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)

# Add test to CTest
add_test(NAME TranslationGizmoSnapTest COMMAND tst_translationgizmo_snap)

set_target_properties(tst_translationgizmo_snap PROPERTIES
    AUTOMOC ON
)

# RotationGizmo Snap Test
qt_add_executable(tst_rotationgizmo_snap
    tst_rotationgizmo_snap.cpp
)

target_link_libraries(tst_rotationgizmo_snap PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)

# Add test to CTest
add_test(NAME RotationGizmoSnapTest COMMAND tst_rotationgizmo_snap)

set_target_properties(tst_rotationgizmo_snap PROPERTIES
    AUTOMOC ON
)

# ScaleGizmo Test
qt_add_executable(tst_scalegizmo
    tst_scalegizmo.cpp
)

target_link_libraries(tst_scalegizmo PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)

# Add test to CTest
add_test(NAME ScaleGizmoTest COMMAND tst_scalegizmo)

set_target_properties(tst_scalegizmo PROPERTIES
    AUTOMOC ON
)

# QML TestCase Tests
qt_add_executable(tst_qml_gizmo
    tst_qml_main.cpp
)

target_link_libraries(tst_qml_gizmo PRIVATE
    Qt6::QuickTest
    Qt6::Qml
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)

# Define test source directory for Qt Quick Test
target_compile_definitions(tst_qml_gizmo PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)

# Add QML tests to CTest
add_test(NAME QmlGizmoTests COMMAND tst_qml_gizmo)

# Set environment for QML tests
# Use xcb (X11) platform for proper 3D rendering support
# Set LD_LIBRARY_PATH to avoid Snap VSCode library contamination (see CLAUDE.md)
set_tests_properties(QmlGizmoTests PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=xcb;LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu"
)

set_target_properties(tst_qml_gizmo PROPERTIES
    AUTOMOC ON
)

# Drawing Primitive Tests
# ArrowPrimitive Test
qt_add_executable(tst_arrowprimitive
    drawing/tst_arrowprimitive.cpp
)

target_link_libraries(tst_arrowprimitive PRIVATE
    Qt6::Test
    Qt6::Quick
    gizmo3d
)

add_test(NAME ArrowPrimitiveTest COMMAND tst_arrowprimitive)

set_target_properties(tst_arrowprimitive PROPERTIES
    AUTOMOC ON
)

# CirclePrimitive Test
qt_add_executable(tst_circleprimitive
    drawing/tst_circleprimitive.cpp
)

target_link_libraries(tst_circleprimitive PRIVATE
    Qt6::Test
    Qt6::Quick
    gizmo3d
)

add_test(NAME CirclePrimitiveTest COMMAND tst_circleprimitive)

set_target_properties(tst_circleprimitive PROPERTIES
    AUTOMOC ON
)

# PlanePrimitive Test
qt_add_executable(tst_planeprimitive
    drawing/tst_planeprimitive.cpp
)

target_link_libraries(tst_planeprimitive PRIVATE
    Qt6::Test
    Qt6::Quick
    gizmo3d
)

add_test(NAME PlanePrimitiveTest COMMAND tst_planeprimitive)

set_target_properties(tst_planeprimitive PROPERTIES
    AUTOMOC ON
)

# SquareHandlePrimitive Test
qt_add_executable(tst_squarehandleprimitive
    drawing/tst_squarehandleprimitive.cpp
)

target_link_libraries(tst_squarehandleprimitive PRIVATE
    Qt6::Test
    Qt6::Quick
    gizmo3d
)

add_test(NAME SquareHandlePrimitiveTest COMMAND tst_squarehandleprimitive)

set_target_properties(tst_squarehandleprimitive PROPERTIES
    AUTOMOC ON
)
