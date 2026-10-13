//! nocjass
library MiniMHEntry requires MiniMHCore, MiniMHMemory, MiniMHHandleTable, MiniMHCalls, MiniMHEffectAlpha
    function MiniMH_Init takes nothing returns boolean
        if MiniMH_Ready then
            return true
        endif
        if not MiniMH_InitMemoryBridge() then
            return false
        endif
        if not MiniMH_InitHandleTable() then
            return false
        endif
        if not MiniMH_InitCalls() then
            return false
        endif
        set MiniMH_Ready = true
        set MiniMH_LastError = "OK"
        return true
    endfunction
    function MiniMH_DemoSetAlpha takes effect e returns boolean
        return MiniMH_SetEffectAlpha(e, 128)
    endfunction
endlibrary
//! endnocjass
