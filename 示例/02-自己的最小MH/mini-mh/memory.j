//! nocjass
library MiniMHMemory requires MiniMHCore, MiniMHVersion127a, MiniMHTypecast
    globals
        boolean MiniMH_MemoryBridgeReady = false
        integer Memory
        integer array l__Memory
    endglobals
    function MiniMH_RawRead takes integer address returns integer // 通过映射到进程内存的数组读取一个 32 位整数。
        return l__Memory[address / 4]
    endfunction
    //# +nosemanticerror
    function MiniMH_NewGlobal takes nothing returns integer // 提供内存桥启动过程使用的代码地址锚点。
        return -0x005E0704
        return 0x2700 // 内部跳转使用的返回指令编码，不能作为死代码删除。
    endfunction
    //# +nosemanticerror
    function MiniMH_SetGlobal takes nothing returns nothing // 提供带固定局部变量初值的启动代码锚点。
        local integer i = 0x2114D008
    endfunction
    function MiniMH_ReadDword takes integer address returns integer // 检查初始化状态和地址后读取 4 字节内存。
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then
            return 0
        endif
        return MiniMH_RawRead(address)
    endfunction
    function MiniMH_WriteDword takes integer address, integer value returns boolean // 检查地址后写入 4 字节内存，并回读确认写入值。
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then
            return false
        endif
        set l__Memory[address / 4] = value
        return MiniMH_RawRead(address) == value
    endfunction
    //# +nosemanticerror
    function MiniMH_InitMemoryBridge takes nothing returns boolean // 建立 JASS 虚拟机内存映射，并检查版本和模块头；运行结果由游戏实测确认。
        local integer array i
        local integer vtable = 0
        local integer variableId = 0
        local integer fakeHeader = 0
        if MiniMH_MemoryBridgeReady then
            return true
        endif
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_NewGlobal) + 2))
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_SetGlobal) + 8))
        call MiniMH_SetArrayHeader(0)
        set vtable = i[MiniMH_ArrayAddress() / 4]
        set MiniMH_VersionSignature = vtable - i[vtable / 4] // 用虚函数表地址与其首项的差值推算版本特征值。
        if not MiniMH_CheckVersion127a() then
            set MiniMH_LastError = "Unsupported Game.dll (expected 1.27a)"
            return false
        endif
        set MiniMH_GameBase = vtable - MINIMH_ARRAY_VTABLE_RVA // 用虚函数表地址减去版本偏移，推算 Game.dll 基址。
        call MiniMH_SetArrayHeader(vtable)
        set l__Memory[10] = 0
        set variableId = i[(MiniMH_CodeAddress(function MiniMH_RawRead) + 0x34) / 4] // 从原始读取函数生成代码的 0x34 偏移读取变量标识。
        set fakeHeader = i[(MiniMH_ArrayAddress() + 0xC) / 4] + 4 // 按虚拟机数组布局读取并调整伪数组头地址。
        call MiniMH_InitBytecode(variableId, fakeHeader)
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(i[(MiniMH_BytecodeAddress() + 0xC) / 4]))
        set MiniMH_MemoryBridgeReady = true
        if MiniMH_ReadDword(MiniMH_GameBase) != 0x00905A4D then
            set MiniMH_MemoryBridgeReady = false
            set MiniMH_LastError = "Memory bridge: Game.dll DOS header mismatch"
            return false
        endif
        return true
    endfunction
endlibrary
//! endnocjass
