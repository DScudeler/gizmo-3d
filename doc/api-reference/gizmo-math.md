# GizmoMath API Reference

Singleton utility library providing 3D math operations for gizmo implementation.

## Import

```qml
import Gizmo3D 1.0
```

## Overview

**GizmoMath** is a QML singleton providing utility functions for coordinate conversion, vector math, ray operations, geometric calculations, and quaternion manipulation. It is used internally by all gizmo components and can be used in custom gizmo implementations.

**Key Categories**:
- Coordinate space conversion (world ↔ screen)
- Vector mathematics (dot, cross, normalize, etc.)
- Camera ray construction and intersection
- 2D hit detection geometry
- Angle and rotation utilities
- Snap helpers

## Usage

Access GizmoMath functions directly as a singleton:

```qml
import Gizmo3D 1.0

Item {
    function example() {
        // Coordinate conversion
        var screenPos = GizmoMath.worldToScreen(view3d, Qt.vector3d(10, 20, 30))

        // Vector math
        var normalized = GizmoMath.normalize(Qt.vector3d(1, 2, 3))

        // Quaternion creation
        var quat = GizmoMath.quaternionFromAxisAngle(Qt.vector3d(0, 1, 0), 45.0)
    }
}
```

## Coordinate Space Conversion

### `worldToScreen(view3d, position) → point`

Convert 3D world position to 2D screen coordinates.

**Parameters**:
- `view3d` (View3D): The View3D component
- `position` (vector3d): 3D world-space position

**Returns**: `point` - Screen-space coordinates {x, y}

```qml
var worldPos = Qt.vector3d(10, 20, 30)
var screenPos = GizmoMath.worldToScreen(view3d, worldPos)
console.log("Screen:", screenPos.x, screenPos.y)
```

---

### `screenToWorld(view3d, screenPos) → vector3d`

Convert 2D screen coordinates to 3D world position.

**Parameters**:
- `view3d` (View3D): The View3D component
- `screenPos` (point or vector3d): Screen-space coordinates

**Returns**: `vector3d` - World-space position (on near plane)

**Note**: Returns position on the near clipping plane. Use `getCameraRay` for ray-based queries.

```qml
var screenPos = Qt.point(100, 200)
var worldPos = GizmoMath.screenToWorld(view3d, screenPos)
```

## Vector Mathematics

### `dotProduct(a, b) → real`

Calculate dot product of two vectors.

**Parameters**:
- `a` (vector3d): First vector
- `b` (vector3d): Second vector

**Returns**: `real` - Scalar dot product (a·b)

```qml
var a = Qt.vector3d(1, 0, 0)
var b = Qt.vector3d(0, 1, 0)
var dot = GizmoMath.dotProduct(a, b)  // 0.0 (perpendicular)
```

---

### `crossProduct(a, b) → vector3d`

Calculate cross product of two vectors.

**Parameters**:
- `a` (vector3d): First vector
- `b` (vector3d): Second vector

**Returns**: `vector3d` - Cross product vector (a × b), perpendicular to both inputs

```qml
var a = Qt.vector3d(1, 0, 0)
var b = Qt.vector3d(0, 1, 0)
var cross = GizmoMath.crossProduct(a, b)  // Qt.vector3d(0, 0, 1)
```

---

### `normalize(v) → vector3d`

Normalize vector to unit length.

**Parameters**:
- `v` (vector3d): Vector to normalize

**Returns**: `vector3d` - Unit vector in same direction, or (0, 0, 1) if length < 0.0001

```qml
var v = Qt.vector3d(3, 4, 0)
var unit = GizmoMath.normalize(v)  // Qt.vector3d(0.6, 0.8, 0.0)
```

---

### `vectorAdd(a, b) → vector3d`

Add two vectors.

**Parameters**:
- `a`, `b` (vector3d): Vectors to add

**Returns**: `vector3d` - Sum (a + b)

---

### `vectorSubtract(a, b) → vector3d`

Subtract two vectors.

**Parameters**:
- `a`, `b` (vector3d): Vectors to subtract

**Returns**: `vector3d` - Difference (a - b)

---

### `vectorScale(v, s) → vector3d`

Scale vector by scalar.

**Parameters**:
- `v` (vector3d): Vector to scale
- `s` (real): Scalar multiplier

**Returns**: `vector3d` - Scaled vector (v × s)

---

### `vectorLength(v) → real`

Calculate vector magnitude.

**Parameters**:
- `v` (vector3d): Vector

**Returns**: `real` - Length |v|

## Camera Ray Operations

### `getCameraRay(view3d, screenPos) → {origin, direction}`

Construct a camera ray through a screen point.

**Parameters**:
- `view3d` (View3D): The View3D component
- `screenPos` (point): Screen-space coordinates

**Returns**: Object with:
- `origin` (vector3d): Ray origin in world space
- `direction` (vector3d): Normalized ray direction in world space

**Usage**: Essential for 3D picking and interaction.

```qml
var ray = GizmoMath.getCameraRay(view3d, Qt.point(mouse.x, mouse.y))
console.log("Ray origin:", ray.origin)
console.log("Ray direction:", ray.direction)
```

---

### `closestPointOnAxisToRay(rayOrigin, rayDir, axisOrigin, axisDir) → real`

Find closest point parameter on an axis to a ray.

**Parameters**:
- `rayOrigin` (vector3d): Ray start point
- `rayDir` (vector3d): Ray direction (should be normalized)
- `axisOrigin` (vector3d): Axis origin point
- `axisDir` (vector3d): Axis direction (should be normalized)

**Returns**: `real` - Scalar t such that `axisOrigin + t × axisDir` is closest to ray

**Usage**: Used for axis translation (sliding along an axis).

```qml
var ray = GizmoMath.getCameraRay(view3d, Qt.point(mouse.x, mouse.y))
var t = GizmoMath.closestPointOnAxisToRay(
    ray.origin, ray.direction,
    Qt.vector3d(0, 0, 0), Qt.vector3d(1, 0, 0)  // X-axis
)
var closestPoint = Qt.vector3d(t, 0, 0)
```

---

### `intersectRayPlane(rayOrigin, rayDir, planeOrigin, planeNormal) → vector3d | null`

Intersect ray with plane.

**Parameters**:
- `rayOrigin` (vector3d): Ray start point
- `rayDir` (vector3d): Ray direction
- `planeOrigin` (vector3d): Any point on the plane
- `planeNormal` (vector3d): Plane normal (should be normalized)

**Returns**: `vector3d` - Intersection point in world space, or `null` if ray is parallel to plane

**Usage**: Used for planar translation and rotation angle calculation.

```qml
var ray = GizmoMath.getCameraRay(view3d, Qt.point(mouse.x, mouse.y))
var intersection = GizmoMath.intersectRayPlane(
    ray.origin, ray.direction,
    Qt.vector3d(0, 0, 0),  // Plane origin
    Qt.vector3d(0, 0, 1)   // Plane normal (XY plane)
)

if (intersection) {
    console.log("Hit plane at:", intersection)
}
```

## Snap Utilities

### `snapValue(value, increment) → real`

Snap value to nearest grid increment.

**Parameters**:
- `value` (real): Value to snap
- `increment` (real): Grid spacing

**Returns**: `real` - Snapped value

```qml
var snapped = GizmoMath.snapValue(12.7, 5.0)  // 15.0
var snapped2 = GizmoMath.snapValue(-3.2, 1.0)  // -3.0
```

## Angle Utilities

### `normalizeAngleDelta(delta) → real`

Normalize angle delta to [-π, π] range.

**Parameters**:
- `delta` (real): Angle delta in radians

**Returns**: `real` - Normalized delta in [-π, π]

**Usage**: Prevents angle wrapping issues when calculating rotation deltas.

```qml
var delta = 7.0  // > 2π
var normalized = GizmoMath.normalizeAngleDelta(delta)  // ~0.716 radians
```

---

### `calculatePlaneAngle(point, center, planeNormal, referenceAxis) → real`

Calculate angle of a point in a plane relative to a reference axis.

**Parameters**:
- `point` (vector3d): Point in 3D space
- `center` (vector3d): Center of rotation
- `planeNormal` (vector3d): Plane normal
- `referenceAxis` (vector3d): Reference axis for 0° angle

**Returns**: `real` - Angle in radians [-π, π]

**Usage**: Calculate rotation angle during circular drag operations.

```qml
var angle = GizmoMath.calculatePlaneAngle(
    intersection,                  // Where mouse ray hits plane
    targetNode.position,           // Center of rotation
    Qt.vector3d(0, 0, 1),         // XY plane normal
    Qt.vector3d(1, 0, 0)          // X-axis as 0°
)
```

## Quaternion Operations

### `quaternionFromAxisAngle(axis, angleDegrees) → quaternion`

Create quaternion from axis-angle representation.

**Parameters**:
- `axis` (vector3d): Rotation axis (should be normalized)
- `angleDegrees` (real): Rotation angle in degrees

**Returns**: `quaternion` - Quaternion representing the rotation

**Usage**: Convert rotation deltas to quaternions for composition.

```qml
var quat = GizmoMath.quaternionFromAxisAngle(Qt.vector3d(0, 1, 0), 90.0)
targetNode.rotation = quat.times(dragStartRotation)
```

## 2D Hit Detection Geometry

### `distanceToLineSegment2D(point, lineStart, lineEnd) → real`

Calculate distance from point to line segment in 2D.

**Parameters**:
- `point` (point): Test point {x, y}
- `lineStart` (point): Segment start {x, y}
- `lineEnd` (point): Segment end {x, y}

**Returns**: `real` - Distance in pixels

**Usage**: Axis hit detection in screen space.

```qml
var dist = GizmoMath.distanceToLineSegment2D(
    Qt.point(mouse.x, mouse.y),
    geometry.center,
    geometry.xEnd
)
if (dist < 10) {
    console.log("Hit X axis")
}
```

---

### `pointInQuad2D(point, corners) → bool`

Test if point is inside a 2D quadrilateral.

**Parameters**:
- `point` (point): Test point {x, y}
- `corners` (array): Four corner points [{x, y}, {x, y}, {x, y}, {x, y}]

**Returns**: `bool` - True if point is inside quad

**Algorithm**: Ray-crossing (odd number of edge crossings = inside)

**Usage**: Plane handle hit detection.

```qml
var inside = GizmoMath.pointInQuad2D(
    Qt.point(mouse.x, mouse.y),
    [corner1, corner2, corner3, corner4]
)
if (inside) {
    console.log("Hit plane handle")
}
```

---

### `distanceToPolyline2D(point, polylinePoints) → real`

Calculate minimum distance from point to a polyline.

**Parameters**:
- `point` (point): Test point {x, y}
- `polylinePoints` (array): Array of points forming connected segments

**Returns**: `real` - Minimum distance in pixels

**Usage**: Circle hit detection for rotation gizmo.

```qml
var dist = GizmoMath.distanceToPolyline2D(
    Qt.point(mouse.x, mouse.y),
    circlePoints  // Array of 64 points forming circle
)
if (dist < 8) {
    console.log("Hit rotation circle")
}
```

## Coordinate System

All functions use Qt Quick 3D's **right-handed coordinate system**:
- **X-axis**: Right (red)
- **Y-axis**: Up (green)
- **Z-axis**: Forward toward camera (blue)

## Numerical Precision

- Vector normalization: Threshold 0.0001 for zero-length check
- Ray-plane intersection: Threshold 0.0001 for parallel ray detection
- Axis-ray closest point: Threshold 0.001 for parallel line detection
- Snap: Uses `Math.round()` for grid alignment

## Performance Considerations

- All functions are implemented in JavaScript (QML)
- No C++ dependencies for maximum portability
- Functions are pure (no side effects) and can be called freely
- No caching - results should be cached by caller if used multiple times per frame

## Custom Gizmo Example

Using GizmoMath to implement a custom scale gizmo:

```qml
import Gizmo3D 1.0

Item {
    property View3D view3d: null
    property Node targetNode: null

    MouseArea {
        anchors.fill: parent

        onPressed: (mouse) => {
            var ray = GizmoMath.getCameraRay(view3d, Qt.point(mouse.x, mouse.y))
            var plane = Qt.vector3d(0, 1, 0)  // XZ plane
            var hit = GizmoMath.intersectRayPlane(
                ray.origin, ray.direction,
                targetNode.position, plane
            )

            if (hit) {
                var dist = GizmoMath.vectorLength(
                    GizmoMath.vectorSubtract(hit, targetNode.position)
                )
                // Use distance for scaling...
            }
        }
    }
}
```

## See Also

- [TranslationGizmo Implementation](translation-gizmo.md) - Usage in axis/plane translation
- [RotationGizmo Implementation](rotation-gizmo.md) - Usage in rotation calculations
- [Custom Gizmos Guide](../advanced/custom-gizmos.md) - Building custom gizmos
- [Architecture: Coordinate Mapping](../architecture/coordinate-mapping.md) - Coordinate system details
