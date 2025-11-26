# UI Interaction Tests for Gizmo3D

## Overview

This directory contains comprehensive UI interaction tests for the TranslationGizmo and RotationGizmo components. These tests validate mouse and keyboard interactions, signal emissions, controller patterns, and visual feedback.

## Test Files

### Core Interaction Tests
- **tst_translationgizmo_interaction.qml** - Mouse interaction tests for TranslationGizmo
  - Axis click detection (X, Y, Z)
  - Plane click detection (XY, XZ, YZ)
  - Drag operations with signal verification
  - Snap integration during interactions
  
- **tst_rotationgizmo_interaction.qml** - Mouse interaction tests for RotationGizmo
  - Circle hit detection
  - Rotation drag operations
  - Angle calculation accuracy
  - Snap integration with various angles

### Integration Tests
- **tst_gizmo_controller_integration.qml** - Controller pattern validation
  - Trivial controller implementation tests
  - Position/rotation updates during drag
  - Multi-object manipulation
  - Validation and rejection of invalid deltas

### Edge Case Tests
- **tst_gizmo_edge_cases.qml** - Boundary conditions and error scenarios
  - Null/invalid states (no crash tests)
  - Rapid interaction sequences
  - Camera movement during drag
  - Extreme target positions
  - Invalid snap values

### Coordinate Transform Tests
- **tst_gizmo_coordinate_transform.qml** - Projection and ray-casting accuracy
  - World-to-screen projection
  - Ray-plane intersection
  - Ray-axis closest point calculation
  - View3D integration
  - Perspective correctness

### Visual Feedback Tests
- **tst_gizmo_visual_feedback.qml** - Visual state and rendering validation
  - Active state color changes
  - Canvas repaint triggers
  - Visual arc rendering (rotation gizmo)
  - Geometry updates

## Important: Canvas Rendering Requirements

⚠️ **Many UI interaction tests require actual canvas rendering and will fail or be skipped in offscreen mode.**

The gizmos use pixel-perfect hit detection via Canvas `getImageData()` which requires actual rendering. Tests that depend on mouse click hit detection will not work properly in offscreen rendering mode (`QT_QPA_PLATFORM=offscreen`).

### Running Tests with Full Rendering

To run all tests with proper hit detection:

```bash
# Linux with X11
export QT_QPA_PLATFORM=xcb
./build/debug/tests/tst_qml_gizmo

# Linux with Wayland
export QT_QPA_PLATFORM=wayland
./build/debug/tests/tst_qml_gizmo

# macOS
export QT_QPA_PLATFORM=cocoa
./build/debug/tests/tst_qml_gizmo

# Windows
set QT_QPA_PLATFORM=windows
build\debug\tests\tst_qml_gizmo.exe
```

### CI/CD Considerations

For headless CI/CD environments, you have two options:

1. **Use Xvfb (X Virtual Frame Buffer)** on Linux:
   ```bash
   xvfb-run -a ./build/debug/tests/tst_qml_gizmo
   ```

2. **Accept that interaction tests will be skipped** in offscreen mode and rely on:
   - Basic property tests (these work in offscreen mode)
   - Manual testing on development machines
   - Integration tests in environments with actual displays

## Test Coverage

### What Works in Offscreen Mode ✅
- Component creation and property tests
- Signal existence verification
- Snap value calculations (GizmoMath functions)
- Geometry calculations
- Basic controller pattern structure

### What Requires Actual Rendering ⚠️
- Mouse click hit detection
- Drag operation signal emissions
- Interactive state changes (activeAxis, activePlane)
- Visual feedback validation
- Canvas-based pixel picking

## Test Statistics

- **Total test cases**: ~65-70 tests across 6 files
- **Tests requiring rendering**: ~40-45 (interaction tests)
- **Tests working in offscreen mode**: ~20-25 (property and calculation tests)

## Running Individual Test Files

```bash
# Run only edge case tests
./build/debug/tests/tst_qml_gizmo -input tests/tst_gizmo_edge_cases.qml

# Run only coordinate transform tests
./build/debug/tests/tst_qml_gizmo -input tests/tst_gizmo_coordinate_transform.qml
```

## Development Workflow

1. **During Development**: Run tests with actual rendering (xcb/wayland/cocoa)
2. **Before Commits**: Verify all tests pass with rendering enabled
3. **In CI/CD**: Accept offscreen limitations or use Xvfb
4. **For Coverage**: Focus on tests that work in offscreen mode for automated coverage

## Future Improvements

Potential enhancements to improve testability:

1. **Mock Hit Detection**: Implement a test-only mode that bypasses canvas pixel detection
2. **Synthetic Events**: Create a test helper that directly sets activeAxis/activePlane
3. **Headless Rendering**: Investigate Qt Quick's OffscreenSurface for pixel operations
4. **Test Isolation**: Split tests into "offscreen-safe" and "rendering-required" suites

## Contributing

When adding new UI interaction tests:

- Mark tests that require rendering with appropriate comments
- Use `skip()` when canvas operations aren't available
- Test both with and without rendering to ensure graceful degradation
- Document any platform-specific behaviors

## See Also

- [TranslationGizmo.qml](../src/TranslationGizmo.qml) - Component implementation
- [RotationGizmo.qml](../src/RotationGizmo.qml) - Component implementation
- [GizmoMath.qml](../src/GizmoMath.qml) - Math utilities
- [CLAUDE.md](../CLAUDE.md) - Project architecture and build instructions
