//! nocjass
library MiniMHEntry requires MiniMHCore, MiniMHMemory, MiniMHHandleTable, MiniMHCalls, MiniMHEffectAlpha // Declare the initialization and public demo dependencies.
    function MiniMH_Init takes nothing returns boolean // Initialize all required MiniMH layers in order.
        if MiniMH_Ready then // Avoid repeating initialization after a successful run.
            return true // Report the already-ready state.
        endif // Finish the repeated-initialization check.
        if not MiniMH_InitMemoryBridge() then // First establish the memory bridge and perform its version check.
            return false // Stop when memory initialization reports failure.
        endif // Finish the memory-bridge step.
        if not MiniMH_InitHandleTable() then // Next confirm the handle-table root can be read.
            return false // Stop when handle-table initialization reports failure.
        endif // Finish the handle-table step.
        if not MiniMH_InitCalls() then // Prepare the temporary native-call buffer and dispatch slot.
            return false // Stop when call setup reports failure.
        endif // Finish the native-call setup step.
        set MiniMH_Ready = true // Publish readiness only after all initialization functions returned true.
        set MiniMH_LastError = "OK" // Clear the prior diagnostic with a success status.
        return true // Report initialization success to the caller.
    endfunction // End the main initialization function.
    function MiniMH_DemoSetAlpha takes effect e returns boolean // Provide a sample wrapper using a fixed alpha value.
        return MiniMH_SetEffectAlpha(e, 128) // Request 128/255 alpha through the public API.
    endfunction // End the demo wrapper.
endlibrary // End the entry-point library.
//! endnocjass
