//! nocjass
library MiniMHEntry
    globals
        boolean MiniMH_Ready = false
    endglobals

    function MiniMH_Init takes nothing returns boolean
        set MiniMH_Ready = false

        if not MiniMH_CheckVersion127a() then
            return false
        endif

        if not MiniMH_InitMemoryBridge() then
            return false
        endif

        if not MiniMH_InitHandleTable() then
            return false
        endif

        set MiniMH_Ready = true
        return true
    endfunction

    function MiniMH_DemoSetAlpha takes effect e returns boolean
        if not MiniMH_Ready then
            return false
        endif

        return MiniMH_SetEffectAlpha(e, 128)
    endfunction
endlibrary
//! endnocjass
