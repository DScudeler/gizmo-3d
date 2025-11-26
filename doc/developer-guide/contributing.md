# Contributing to Gizmo3D

Guidelines for contributing code, documentation, and improvements to Gizmo3D.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your feature: `git checkout -b feature/my-feature`
4. **Make your changes** following the guidelines below
5. **Test thoroughly** with the test suite
6. **Submit a pull request** to the main repository

## Development Setup

### Prerequisites

- Qt 6.x with Quick3D
- CMake 3.21+
- C++20 compiler
- Ninja build system

### Build for Development

```bash
# Configure with debug symbols
cmake --preset debug

# Build
cmake --build --preset debug

# Run tests
ctest --preset debug --verbose

# Run example
./build/debug/examples/gizmo3d_example
```

## Code Style Guidelines

### QML Style

**Indentation**: 4 spaces (no tabs)

**Property Order**:
1. id
2. Required properties
3. Optional properties
4. Read-only properties
5. Signals
6. Functions
7. Child components

**Naming Conventions**:
- Components: PascalCase (`TranslationGizmo`)
- Properties: camelCase (`gizmoSize`)
- Functions: camelCase (`calculateGizmoGeometry`)
- Signals: camelCase with action suffix (`axisTranslationStarted`)
- Private properties: camelCase with underscore prefix (`_internalState`)

**Example**:

```qml
Item {
    id: root

    // Required properties
    required property View3D view3d
    required property Node targetNode

    // Optional properties
    property real gizmoSize: 100.0
    property bool snapEnabled: false

    // Read-only properties
    readonly property int activeAxis: _activeAxis

    // Signals
    signal translationStarted(int axis)

    // Functions
    function calculateGeometry() {
        // ...
    }

    // Child components
    Canvas {
        id: canvas
        // ...
    }
}
```

### JavaScript Style

- Use `const` and `let`, avoid `var`
- Prefer arrow functions for callbacks
- Use strict equality (`===`, `!==`)
- Add comments for complex algorithms

### C++ Style (if contributing C++ helpers)

- Follow Qt code style
- Use Qt types (QString, QVector3D, etc.)
- Document public APIs with /** */ comments

## Testing Requirements

### Writing Tests

Tests use Qt Quick Test framework. Create test files in `tests/`:

```qml
import QtQuick
import QtTest
import QtQuick3D
import Gizmo3D 1.0

TestCase {
    name: "TranslationGizmoTests"

    function test_axisTranslationDelta() {
        // Arrange
        var gizmo = createTranslationGizmo()

        // Act
        gizmo.simulateAxisDrag(1, 10.0)

        // Assert
        compare(targetNode.position.x, 10.0)
    }
}
```

### Running Tests

```bash
# All tests
ctest --preset debug

# Specific test
./build/debug/tests/tst_translationgizmo

# With verbose output
ctest --preset debug --verbose
```

### Test Coverage

- Add tests for new features
- Add tests for bug fixes
- Maintain existing test coverage
- Test edge cases and error conditions

## Documentation Requirements

### Code Documentation

Document all public APIs:

```qml
/**
 * Calculate gizmo geometry in screen space
 * @returns {object} Geometry object with center, endpoints, and plane corners
 * @returns {null} If view3d or targetNode is not set
 */
function calculateGizmoGeometry() {
    // ...
}
```

### User Documentation

When adding features, update:

- API reference in `doc/api-reference/`
- User guides in `doc/user-guide/`
- Examples in `doc/examples/`
- README.md if changing core functionality

### Changelog

Add entry to CHANGELOG.md (if it exists) or PR description:

```markdown
## [Unreleased]

### Added
- New scale gizmo component for uniform/non-uniform scaling

### Fixed
- Rotation drift issue when composing quaternions

### Changed
- Improved hit detection precision for circle handles
```

## Pull Request Process

### Before Submitting

1. **Test thoroughly**: Run full test suite
2. **Check code style**: Follow style guidelines
3. **Update documentation**: Add/update relevant docs
4. **Commit properly**: Use clear, descriptive commit messages

### Commit Message Format

```
type: Short description (50 chars)

Longer explanation if needed (wrap at 72 characters).
Explain the problem, why this change is needed, and
what the change does.

Fixes #123
```

**Types**: feat, fix, docs, refactor, test, perf, style, chore

**Examples**:
```
feat: Add planar translation gizmo handles

Implement plane squares between axis arrows for XY, XZ, and YZ
planar translations. Uses ray-plane intersection for smooth
dragging in constrained planes.

Closes #45

---

fix: Prevent rotation quaternion drift

Compose rotation deltas with drag start rotation instead of
current rotation to prevent accumulated errors.

Fixes #67
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Motivation
Why is this change needed?

## Changes
- List of specific changes
- Made in this PR

## Testing
How was this tested?

## Checklist
- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Commit messages are clear
```

## Areas for Contribution

### Features

- Scale gizmo (uniform and non-uniform)
- Custom handle visual styles
- Touch/gesture support
- Pivot point control
- Multi-axis constraints

### Improvements

- Performance optimizations
- Enhanced hit detection
- Better visual feedback
- Accessibility improvements

### Documentation

- More code examples
- Tutorial videos (links)
- Architecture diagrams
- API clarifications

### Testing

- Increase test coverage
- Add integration tests
- Performance benchmarks
- Cross-platform testing

## Community Guidelines

- Be respectful and inclusive
- Help others learn
- Provide constructive feedback
- Focus on technical merit
- Credit contributors appropriately

## Questions?

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and community support
- **Pull Requests**: Code contributions

## License

By contributing to Gizmo3D, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors are recognized in:
- GitHub contributors list
- CONTRIBUTORS.md file (if created)
- Release notes for significant contributions

Thank you for contributing to Gizmo3D!
