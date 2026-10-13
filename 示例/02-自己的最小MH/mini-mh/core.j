//! nocjass
library MiniMHCore // Declare shared state used by the other MiniMH libraries.
    globals // Begin globals visible to the rest of the map script.
        boolean MiniMH_Ready = false // Becomes true after all initialization steps report success.
        string MiniMH_LastError = "Not initialized" // Store the latest diagnostic text for callers.
    endglobals // End the shared global declarations.
endlibrary // End the MiniMHCore library.
//! endnocjass
