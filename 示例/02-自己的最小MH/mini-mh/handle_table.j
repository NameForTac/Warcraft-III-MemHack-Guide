//! nocjass
library MiniMHHandleTable requires MiniMHVersion127a, MiniMHMemory
    globals
        boolean MiniMH_HandleTableReady = false
    endglobals
    function MiniMH_HandleRoot takes nothing returns integer
        local integer state = MiniMH_ReadDword(MiniMH_GameBase + MINIMH_GAME_STATE_RVA)
        local integer manager = 0
        if state == 0 then
            return 0
        endif
        set manager = MiniMH_ReadDword(state + 0x1C)
        if manager == 0 then
            return 0
        endif
        return MiniMH_ReadDword(manager + MINIMH_HANDLE_TABLE_OFFSET)
    endfunction
    function MiniMH_InitHandleTable takes nothing returns boolean
        set MiniMH_HandleTableReady = MiniMH_MemoryBridgeReady and MiniMH_HandleRoot() != 0
        if not MiniMH_HandleTableReady then
            set MiniMH_LastError = "GameState / handle table not ready"
        endif
        return MiniMH_HandleTableReady
    endfunction
    function MiniMH_ConvertEffect takes effect e returns integer
        local integer root = 0
        if not MiniMH_HandleTableReady or e == null then
            return 0
        endif
        set root = MiniMH_HandleRoot()
        if root == 0 then
            return 0
        endif
        return MiniMH_ReadDword(root + GetHandleId(e) * MINIMH_HANDLE_ENTRY_STRIDE - 0x2FFFFF * 4)
    endfunction
endlibrary
//! endnocjass
