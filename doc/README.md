# Gizmo3D Documentation

Comprehensive documentation for the Gizmo3D Qt Quick 3D transformation gizmo library.

## Quick Navigation

- **New to Gizmo3D?** Start with the [Quick Start Guide](getting-started/quick-start.md)
- **Need API details?** See the [API Reference](#api-reference)
- **Having issues?** Check [Common Issues](troubleshooting/common-issues.md)
- **Want to contribute?** Read the [Contributing Guide](developer-guide/contributing.md)

## Documentation Structure

### Getting Started

Essential guides for new users:

- [Quick Start Guide](getting-started/quick-start.md) - 5-minute integration tutorial
- [Installation](getting-started/installation.md) - Build and installation instructions

### User Guide

Learn how to use Gizmo3D components:

- [Controller Pattern](user-guide/controller-pattern.md) - Signal-based manipulation pattern
- [Snapping](user-guide/snapping.md) - Grid and angle snapping configuration

### API Reference

Complete API documentation for all components:

- [TranslationGizmo](api-reference/translation-gizmo.md) - Axis and planar translation
- [RotationGizmo](api-reference/rotation-gizmo.md) - Circular rotation handles
- [GlobalGizmo](api-reference/global-gizmo.md) - Combined translation/rotation with mode switching
- [GizmoMath](api-reference/gizmo-math.md) - Singleton utility library for 3D math

### Architecture

Understand the internal design:

- [Overview](architecture/overview.md) - System architecture and design decisions
- [Rendering](architecture/rendering.md) - Canvas 2D/3D hybrid rendering (coming soon)
- [Coordinate Mapping](architecture/coordinate-mapping.md) - World/screen space conversions (coming soon)
- [Signal Pattern](architecture/signal-pattern.md) - Signal-based manipulation design (coming soon)

### Developer Guide

Contributing to Gizmo3D:

- [Contributing](developer-guide/contributing.md) - Contribution guidelines and process
- [Building](developer-guide/building.md) - Build system details (coming soon)
- [Testing](developer-guide/testing.md) - Testing guide (see tests/UI_TESTS_README.md)
- [Code Organization](developer-guide/code-organization.md) - Codebase structure (coming soon)

### Advanced Topics

Advanced usage patterns:

- [Multi-Object Manipulation](advanced/multi-object.md) - Multiple object manipulation (coming soon)
- [Undo/Redo Integration](advanced/undo-redo.md) - Command pattern integration (coming soon)
- [Custom Gizmos](advanced/custom-gizmos.md) - Create custom gizmo types (coming soon)
- [Performance](advanced/performance.md) - Performance optimization (coming soon)

### Troubleshooting

Solutions to common problems:

- [Common Issues](troubleshooting/common-issues.md) - FAQ and problem resolution
- [Platform-Specific](troubleshooting/platform-specific.md) - Platform-specific quirks (coming soon)
- [Debugging](troubleshooting/debugging.md) - Debugging techniques (coming soon)

### Examples

Code examples and tutorials:

- [Basic Usage](examples/basic-usage.md) - Simple usage examples
- [Validation](examples/validation.md) - Transform validation patterns (coming soon)
- [Multi-Gizmo](examples/multi-gizmo.md) - Multiple gizmos example (coming soon)

## Documentation Standards

This documentation follows professional English style with:

- **Clear hierarchical structure** with section headers
- **Code examples** with syntax highlighting
- **Cross-references** between related documentation
- **Consistent terminology** throughout all documents
- **Technical precision** assuming Qt/QML knowledge

## Contributing to Documentation

Documentation improvements are welcome! When contributing:

1. Follow the existing style and structure
2. Use professional English
3. Include code examples where helpful
4. Add cross-references to related sections
5. Test all code examples

See [Contributing Guide](developer-guide/contributing.md) for details.

## Documentation Coverage

**Completed**: ✅
**In Progress**: 🚧
**Planned**: 📋

### Current Status

- ✅ Getting Started (Quick Start, Installation)
- ✅ API Reference (All components)
- ✅ User Guide (Controller Pattern, Snapping)
- ✅ Architecture (Overview)
- ✅ Troubleshooting (Common Issues)
- ✅ Developer Guide (Contributing)
- ✅ Examples (Basic Usage)
- 📋 Advanced Topics
- 📋 Additional Architecture Details
- 📋 Additional Examples

## Quick Links

- [Main README](../README.md) - Project overview
- [CLAUDE.md](../CLAUDE.md) - AI assistant guidance
- [GitHub Repository](https://github.com/urholaukkarinen/gizmo-3d)
- [Qt Quick 3D Documentation](https://doc.qt.io/qt-6/qtquick3d-index.html)

## Version

Documentation for Gizmo3D version 1.0

Last updated: 2025-01-14
