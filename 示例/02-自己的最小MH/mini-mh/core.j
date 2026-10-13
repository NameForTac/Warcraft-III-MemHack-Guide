//! nocjass
library MiniMHCore
    globals
        boolean MiniMH_Ready = false
        string MiniMH_LastError = "Not initialized"
        boolean MiniMH_Debug = true // 关闭后不输出诊断信息。
    endglobals
    function MiniMH_Log takes string message returns nothing
        if MiniMH_Debug then
            call BJDebugMsg("[MiniMH] " + message)
        endif
    endfunction
endlibrary
//! endnocjass
