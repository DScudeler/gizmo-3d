pragma Singleton
import QtQuick

QtObject {
    // Axis identifiers for gizmo manipulation
    enum Axis {
        None = 0,
        X = 1,
        Y = 2,
        Z = 3,
        Uniform = 4  // ScaleGizmo only
    }

    // Plane identifiers for planar manipulation
    enum Plane {
        None = 0,
        XY = 1,
        XZ = 2,
        YZ = 3
    }

    // Transform mode for gizmo operations
    enum TransformMode {
        World = 0,
        Local = 1
    }

    // GlobalGizmo mode for selecting active gizmo type
    enum Mode {
        Translate = 0,
        Rotate = 1,
        Scale = 2,
        Both = 3,      // Translation + Rotation
        All = 4        // Translation + Rotation + Scale (composite mode)
    }
}
