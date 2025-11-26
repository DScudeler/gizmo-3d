# Controller Pattern Guide

Learn how to implement the controller pattern to bridge gizmo signals to target node manipulation.

## Overview

The **Controller Pattern** is the recommended approach for integrating Gizmo3D components into your application. It decouples gizmo UI from scene manipulation logic by using signals to communicate transformation deltas instead of directly modifying target nodes.

**Benefits**:
- **Framework Integration**: Easy integration with external scene managers
- **Validation**: Controllers can reject or modify transformations before applying
- **Undo/Redo**: Natural support for command pattern (deltas from drag start)
- **Multi-Object**: Controllers can apply deltas to multiple objects simultaneously
- **Automatic Updates**: Gizmos automatically redraw when target node changes

## The Pattern

### 1. Gizmo Emits Signals

Gizmos emit three signals during manipulation:

```qml
signal translationStarted(int axis)
signal translationDelta(int axis, real delta, bool snapActive)
signal translationEnded(int axis)
```

### 2. Controller Handles Signals

The controller:
1. Stores initial state on `*Started` signals
2. Calculates new state on `*Delta` signals
3. Updates target node (which triggers automatic gizmo redraw)
4. Finalizes on `*Ended` signals (undo/redo, validation)

### 3. Automatic Visual Feedback

When the controller updates `targetNode.position` or `targetNode.rotation`, the gizmo automatically redraws via `Connections` to the target node's property changes.

## SimpleController Component

The library provides `SimpleController` - a reusable component implementing the pattern for both translation and rotation.

### Basic Usage

```qml
import Gizmo3D 1.0

TranslationGizmo {
    id: gizmo
    view3d: view3d
    targetNode: myCube
}

SimpleController {
    gizmo: gizmo
    targetNode: myCube
}
```

### Works with All Gizmos

```qml
// Translation
SimpleController { gizmo: translationGizmo; targetNode: cube }

// Rotation
SimpleController { gizmo: rotationGizmo; targetNode: cube }

// Global (both)
SimpleController { gizmo: globalGizmo; targetNode: cube }
```

### How It Works

SimpleController uses `ignoreUnknownSignals: true` to handle different gizmo types:

```qml
Connections {
    target: gizmo
    ignoreUnknownSignals: true  // Ignore missing signals

    function onAxisTranslationStarted(axis) {
        dragStartPos = targetNode.position
    }

    function onAxisTranslationDelta(axis, delta, snapActive) {
        // Apply delta to position...
    }
}

Connections {
    target: gizmo
    ignoreUnknownSignals: true  // Ignore missing signals

    function onRotationStarted(axis) {
        dragStartRot = targetNode.rotation
    }

    function onRotationDelta(axis, angleDegrees, snapActive) {
        // Apply angle delta to rotation...
    }
}
```

## Custom Controllers

Implement custom logic by creating your own controller.

### Translation Controller

```qml
Item {
    id: controller
    required property TranslationGizmo gizmo
    required property Node targetNode

    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    Connections {
        target: controller.gizmo

        function onAxisTranslationStarted(axis) {
            controller.dragStartPos = controller.targetNode.position
        }

        function onAxisTranslationDelta(axis, delta, snapActive) {
            var newPos = controller.dragStartPos
            if (axis === 1) newPos.x += delta
            else if (axis === 2) newPos.y += delta
            else if (axis === 3) newPos.z += delta

            controller.targetNode.position = newPos
        }
    }

    Connections {
        target: controller.gizmo

        function onPlaneTranslationStarted(plane) {
            controller.dragStartPos = controller.targetNode.position
        }

        function onPlaneTranslationDelta(plane, delta, snapActive) {
            controller.targetNode.position = Qt.vector3d(
                controller.dragStartPos.x + delta.x,
                controller.dragStartPos.y + delta.y,
                controller.dragStartPos.z + delta.z
            )
        }
    }
}
```

### Rotation Controller

```qml
Item {
    id: controller
    required property RotationGizmo gizmo
    required property Node targetNode

    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    Connections {
        target: controller.gizmo

        function onRotationStarted(axis) {
            controller.dragStartRot = controller.targetNode.rotation
        }

        function onRotationDelta(axis, angleDegrees, snapActive) {
            var axisVec = axis === 1 ? Qt.vector3d(1, 0, 0)
                        : axis === 2 ? Qt.vector3d(0, 1, 0)
                        : Qt.vector3d(0, 0, 1)

            var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
            controller.targetNode.rotation = deltaQuat.times(controller.dragStartRot)
        }
    }
}
```

## Advanced Patterns

### Transform Validation

Reject transformations that violate constraints:

```qml
Item {
    property TranslationGizmo gizmo
    property Node targetNode
    property vector3d dragStartPos

    // Bounds constraints
    readonly property real minX: -100
    readonly property real maxX: 100
    readonly property real minY: 0
    readonly property real maxY: 200

    Connections {
        target: gizmo

        function onAxisTranslationDelta(axis, delta, snapActive) {
            var newPos = dragStartPos
            if (axis === 1) newPos.x += delta
            else if (axis === 2) newPos.y += delta
            else if (axis === 3) newPos.z += delta

            // Clamp to bounds
            newPos.x = Math.max(minX, Math.min(maxX, newPos.x))
            newPos.y = Math.max(minY, Math.min(maxY, newPos.y))

            targetNode.position = newPos
        }
    }
}
```

### Multi-Object Manipulation

Apply transformations to multiple objects:

```qml
Item {
    property TranslationGizmo gizmo
    property var selectedObjects: [cube1, cube2, cube3]
    property var dragStartPositions: []

    Connections {
        target: gizmo

        function onAxisTranslationStarted(axis) {
            dragStartPositions = selectedObjects.map(obj => obj.position)
        }

        function onAxisTranslationDelta(axis, delta, snapActive) {
            for (var i = 0; i < selectedObjects.length; i++) {
                var startPos = dragStartPositions[i]
                var newPos = startPos

                if (axis === 1) newPos.x += delta
                else if (axis === 2) newPos.y += delta
                else if (axis === 3) newPos.z += delta

                selectedObjects[i].position = newPos
            }
        }
    }
}
```

### Undo/Redo Integration

Create undo commands from transformation deltas:

```qml
Item {
    property TranslationGizmo gizmo
    property Node targetNode
    property vector3d dragStartPos
    property UndoStack undoStack

    Connections {
        target: gizmo

        function onAxisTranslationStarted(axis) {
            dragStartPos = targetNode.position
        }

        function onAxisTranslationDelta(axis, delta, snapActive) {
            var newPos = dragStartPos
            if (axis === 1) newPos.x += delta
            else if (axis === 2) newPos.y += delta
            else if (axis === 3) newPos.z += delta

            targetNode.position = newPos
        }

        function onAxisTranslationEnded(axis) {
            var command = translationCommandFactory.create(
                targetNode,
                dragStartPos,
                targetNode.position
            )
            undoStack.push(command)
        }
    }
}
```

### External Scene Manager Integration

Use controllers to bridge gizmos with external frameworks:

```qml
Item {
    property TranslationGizmo gizmo
    property var externalSceneManager  // Custom scene manager
    property var selectedEntity

    Connections {
        target: gizmo

        function onAxisTranslationDelta(axis, delta, snapActive) {
            // Use external API instead of direct Qt Quick 3D manipulation
            externalSceneManager.translateEntity(selectedEntity, axis, delta)

            // Update visual-only Qt Quick 3D node for gizmo rendering
            visualNode.position = externalSceneManager.getPosition(selectedEntity)
        }
    }
}
```

### Transform Logging

Log transformations for debugging or analytics:

```qml
Connections {
    target: gizmo

    function onAxisTranslationDelta(axis, delta, snapActive) {
        console.log("Translation:", {
            axis: axis,
            delta: delta,
            snapped: snapActive,
            timestamp: Date.now()
        })

        // Apply transformation...
    }
}
```

## Design Rationale

### Why Not Direct Manipulation?

**Alternative (Direct Manipulation)**:
```qml
// ❌ Gizmo directly modifies target node
onMouseMoved: {
    targetNode.position = calculateNewPosition()
}
```

**Problems**:
- Tight coupling between UI and scene management
- No validation or rejection possible
- Difficult undo/redo (no delta information)
- Hard to integrate with external frameworks
- Multi-object manipulation requires complex gizmo logic

**Solution (Signal Pattern)**:
```qml
// ✅ Gizmo emits signal with delta
onMouseMoved: {
    var delta = calculateDelta()
    translationDelta(axis, delta, snapActive)
}

// Controller applies delta
Connections {
    function onTranslationDelta(axis, delta, snapActive) {
        targetNode.position = dragStartPos + delta
    }
}
```

**Advantages**:
- Loose coupling enables framework integration
- Validation/rejection at controller level
- Natural undo/redo support (deltas from known start state)
- Simple multi-object support in controller
- Gizmo complexity stays low

### Why Store dragStart State?

Deltas are **cumulative from drag start**, not **incremental per frame**:

```qml
// ✅ CORRECT: Compose with drag start position
onTranslationDelta: function(axis, delta, snapActive) {
    targetNode.position = dragStartPos + delta
}

// ❌ INCORRECT: Accumulates errors, drifts over time
onTranslationDelta: function(axis, delta, snapActive) {
    targetNode.position = targetNode.position + delta  // Wrong!
}
```

This ensures the visual feedback matches the actual transformation exactly, preventing drift and accumulated errors.

## Best Practices

1. **Always Store Drag Start State**: On `*Started` signals, store initial position/rotation
2. **Use Cumulative Deltas**: Deltas are from drag start, not incremental
3. **Update Target Node**: Let gizmo redraws happen automatically via Connections
4. **Validate in Controller**: Keep gizmos simple, validation in controllers
5. **Use SimpleController**: Start with SimpleController, customize only when needed
6. **Handle All Signals**: Connect to Started/Delta/Ended for complete lifecycle

## Common Mistakes

### Mistake 1: Incremental Deltas

```qml
// ❌ WRONG: Treats delta as incremental
onTranslationDelta: function(axis, delta, snapActive) {
    targetNode.position.x += delta  // Accumulates errors!
}

// ✅ CORRECT: Delta is cumulative from start
onTranslationDelta: function(axis, delta, snapActive) {
    targetNode.position = Qt.vector3d(
        dragStartPos.x + delta,
        dragStartPos.y,
        dragStartPos.z
    )
}
```

### Mistake 2: Forgetting Drag Start

```qml
// ❌ WRONG: No drag start stored
onTranslationDelta: function(axis, delta, snapActive) {
    targetNode.position.x = delta  // Jumps to delta value!
}

// ✅ CORRECT: Store and use drag start
property vector3d dragStartPos

onTranslationStarted: function(axis) {
    dragStartPos = targetNode.position
}

onTranslationDelta: function(axis, delta, snapActive) {
    targetNode.position.x = dragStartPos.x + delta
}
```

### Mistake 3: Composing with Current Rotation

```qml
// ❌ WRONG: Composes with current rotation (drifts)
onRotationDelta: function(axis, angleDegrees, snapActive) {
    var delta = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
    targetNode.rotation = delta.times(targetNode.rotation)  // Drifts!
}

// ✅ CORRECT: Compose with drag start rotation
onRotationDelta: function(axis, angleDegrees, snapActive) {
    var delta = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
    targetNode.rotation = delta.times(dragStartRot)
}
```

## See Also

- [TranslationGizmo API](../api-reference/translation-gizmo.md) - Translation signals
- [RotationGizmo API](../api-reference/rotation-gizmo.md) - Rotation signals
- [Multi-Object Example](../examples/multi-object.md) - Multi-object manipulation
- [Undo/Redo Guide](../advanced/undo-redo.md) - Command pattern integration
