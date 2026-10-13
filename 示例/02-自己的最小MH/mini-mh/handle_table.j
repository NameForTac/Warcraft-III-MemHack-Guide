//! nocjass
library MiniMHHandleTable requires MiniMHVersion127a, MiniMHMemory
    globals
        boolean MiniMH_HandleTableReady = false
    endglobals

    function MiniMH_InitHandleTable takes nothing returns boolean
        if not MiniMH_MemoryBridgeReady then
            return false
        endif

        // TODO: 在 1.27a 中验证 GameState 和 handle 表根节点。
        set MiniMH_HandleTableReady = false
        return false
    endfunction

    function MiniMH_ConvertEffect takes effect e returns integer
        local integer handleId = 0
        local integer gameState = 0
        local integer tableRoot = 0
        local integer entryAddress = 0

        if not MiniMH_HandleTableReady or e == null then
            return 0
        endif

        set handleId = GetHandleId(e)
        if handleId == 0 then
            return 0
        endif

        set gameState = MiniMH_ReadDword(MINIMH_GAME_STATE_ADDRESS)
        if gameState == 0 then
            return 0
        endif

        set tableRoot = MiniMH_ReadDword(gameState + MINIMH_HANDLE_TABLE_OFFSET)
        if tableRoot == 0 then
            return 0
        endif

        set entryAddress = tableRoot + handleId * MINIMH_HANDLE_ENTRY_STRIDE
        return MiniMH_ReadDword(entryAddress)
    endfunction
endlibrary
//! endnocjass
