//! nocjass
library MiniMHMemory
    globals
        boolean MiniMH_MemoryBridgeReady = false
    endglobals

    function MiniMH_InitMemoryBridge takes nothing returns boolean
        // TODO: 只在确认读写桥的输入、输出和恢复行为后改为 true。
        set MiniMH_MemoryBridgeReady = false
        return false
    endfunction

    function MiniMH_ReadDword takes integer address returns integer
        // 安全失败：未完成内存桥时不返回伪造地址。
        return 0
    endfunction

    function MiniMH_WriteDword takes integer address, integer value returns boolean
        // TODO: 写入前登记旧值，失败时能够恢复。
        return false
    endfunction

    function MiniMH_ReadFloat takes integer address returns real
        return 0.0
    endfunction

    function MiniMH_WriteFloat takes integer address, real value returns boolean
        return false
    endfunction
endlibrary
//! endnocjass
