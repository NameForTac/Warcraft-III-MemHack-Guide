//! nocjass
library MiniMHHandleTable requires MiniMHVersion127a, MiniMHMemory // Depend on version offsets and the memory reader.
    globals // Begin handle-table state.
        boolean MiniMH_HandleTableReady = false // Records whether a nonzero handle-table root was observed.
    endglobals // End handle-table globals.
    function MiniMH_HandleRoot takes nothing returns integer // Walk the game-state pointers to the handle-table root.
        local integer state = MiniMH_ReadDword(MiniMH_GameBase + MINIMH_GAME_STATE_RVA) // Read the game-state pointer from its version-specific RVA.
        local integer manager = 0 // Reserve storage for the handle manager pointer.
        if state == 0 then // Reject a missing game-state pointer.
            return 0 // Return a null root address.
        endif // Finish the state-pointer check.
        set manager = MiniMH_ReadDword(state + 0x1C) // Read the manager pointer from the game-state structure.
        if manager == 0 then // Reject a missing manager pointer.
            return 0 // Return a null root address.
        endif // Finish the manager-pointer check.
        return MiniMH_ReadDword(manager + MINIMH_HANDLE_TABLE_OFFSET) // Read and return the table root pointer.
    endfunction // End the root lookup.
    function MiniMH_InitHandleTable takes nothing returns boolean // Validate that memory and the handle root are available.
        set MiniMH_HandleTableReady = MiniMH_MemoryBridgeReady and MiniMH_HandleRoot() != 0 // Publish readiness only when both checks pass.
        if not MiniMH_HandleTableReady then // Detect an unavailable root.
            set MiniMH_LastError = "GameState / handle table not ready" // Explain the failed prerequisite.
        endif // Finish the readiness check.
        return MiniMH_HandleTableReady // Return the recorded result.
    endfunction // End handle-table initialization.
    function MiniMH_ConvertEffect takes effect e returns integer // Convert a JASS effect handle to its game object address.
        local integer root = 0 // Reserve storage for the current table root.
        if not MiniMH_HandleTableReady or e == null then // Reject calls before initialization and null effects.
            return 0 // Return a null object address.
        endif // Finish input validation.
        set root = MiniMH_HandleRoot() // Refresh the table root for this lookup.
        if root == 0 then // Reject a root that disappeared or cannot be read.
            return 0 // Return a null object address.
        endif // Finish root validation.
        return MiniMH_ReadDword(root + GetHandleId(e) * MINIMH_HANDLE_ENTRY_STRIDE - 0x2FFFFF * 4) // Index the table using the handle ID and the known handle-base adjustment.
    endfunction // End effect-handle conversion.
endlibrary // End the handle-table library.
//! endnocjass
