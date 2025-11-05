#!/bin/bash
# Launcher script for gizmo3d example application
# This fixes snap VSCode environment contamination

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Unset snap environment variables that contaminate library loading
# VSCode snap sets these, causing apps to load incompatible snap libraries
unset GTK_PATH
unset GIO_MODULE_DIR

# Set library path to avoid snap conflicts
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

# Set QML import path
export QML2_IMPORT_PATH="${SCRIPT_DIR}/build/debug/src"

# Launch the application
exec "${SCRIPT_DIR}/build/debug/examples/gizmo3d_example" "$@"
