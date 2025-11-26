# Gizmo3D Documentation

**Gizmo3D** is a Qt Quick 3D transformation gizmo library providing interactive manipulation handles for 3D objects. The library uses Canvas-based 2D rendering to draw 3D manipulation handles, translating 3D world positions to screen space using View3D's coordinate mapping system.

## Getting Started

New to Gizmo3D? Start here:

- [Quick Start Guide](getting-started/quick-start.md) - 5-minute integration tutorial
- [Installation](getting-started/installation.md) - Build and installation instructions

## User Guide

Learn how to use Gizmo3D components:

- [Controller Pattern](user-guide/controller-pattern.md) - Implement manipulation logic
- [Snapping](user-guide/snapping.md) - Configure grid and angle snapping
- [Transform Modes](user-guide/transform-modes.md) - World vs local coordinate modes

## API Reference

Complete API documentation for all components:

- [TranslationGizmo](api-reference/translation-gizmo.md) - Axis and planar translation
- [RotationGizmo](api-reference/rotation-gizmo.md) - Circular rotation handles
- [ScaleGizmo](api-reference/scale-gizmo.md) - Axis and uniform scaling
- [GlobalGizmo](api-reference/global-gizmo.md) - Combined transformation gizmo
- [GizmoMath](api-reference/gizmo-math.md) - Math utilities singleton

## Architecture

Understand the internal design:

- [Overview](architecture/overview.md) - System architecture and design goals
- [Rendering Pipeline](architecture/rendering.md) - Canvas 2D/3D hybrid rendering
- [Coordinate Mapping](architecture/coordinate-mapping.md) - World/screen space conversions
- [Signal Pattern](architecture/signal-pattern.md) - Signal-based manipulation design

## Developer Guide

Contributing to Gizmo3D:

- [Code Organization](developer-guide/code-organization.md) - Codebase structure
- [Building](developer-guide/building.md) - Build system details
- [Testing](developer-guide/testing.md) - Testing guide and best practices
- [Adding Gizmos](developer-guide/adding-gizmos.md) - Creating new gizmo types
- [Contributing](developer-guide/contributing.md) - How to contribute

## Troubleshooting

Solutions to common issues:

- [Common Issues](troubleshooting/common-issues.md) - FAQ and problem resolution

## Examples

Code examples and tutorials:

- [Basic Usage](examples/basic-usage.md) - Simple usage examples

## Quick Links

- [GitHub Repository](https://github.com/yourusername/gizmo-3d)
- [Qt Quick 3D Documentation](https://doc.qt.io/qt-6/qtquick3d-index.html)

## License

Gizmo3D is released under the MIT License. See the LICENSE file for details.
