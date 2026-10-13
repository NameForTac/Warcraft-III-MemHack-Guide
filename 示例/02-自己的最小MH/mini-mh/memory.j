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
        local integer observed = 0
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then
            call MiniMH_Log("拒绝写入：内存桥未就绪或地址无效，地址=" + I2S(address))
            return false
        endif
        set l__Memory[address / 4] = value
        set observed = MiniMH_RawRead(address)
        if observed != value then
            call MiniMH_Log("4 字节写入回读失败：地址=" + I2S(address) + "，期望=" + I2S(value) + "，实际=" + I2S(observed))
            return false
        endif
        call MiniMH_Log("4 字节写入回读一致：地址=" + I2S(address) + "，值=" + I2S(observed))
        return true
    endfunction
    //# +nosemanticerror
    function MiniMH_BootstrapMemory takes nothing returns nothing // 由代码地址 +8 进入，跳过局部数组声明。
        local integer array i
        local integer vtable = 0
        local integer variableId = 0
        local integer fakeHeader = 0
        if MiniMH_MemoryBridgeReady then
            return
        endif
        call MiniMH_Log("启动锚点：NewGlobal=" + I2S(MiniMH_CodeAddress(function MiniMH_NewGlobal)) + "，SetGlobal=" + I2S(MiniMH_CodeAddress(function MiniMH_SetGlobal)))
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_NewGlobal) + 2))
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_SetGlobal) + 8))
        call MiniMH_SetArrayHeader(0)
        call MiniMH_Log("启动后数组地址=" + I2S(MiniMH_ArrayAddress()))
        set vtable = i[MiniMH_ArrayAddress() / 4]
        if vtable == 0 then
            set MiniMH_LastError = "启动桥未取得虚函数表，尚未进入版本检查；请检查编译后脚本和优化设置。"
            return
        endif
        set MiniMH_VersionSignature = vtable - i[vtable / 4] // 用虚函数表地址与其首项的差值推算版本特征值。
        if not MiniMH_CheckVersion127a() then
            set MiniMH_LastError = "版本特征不匹配：实际=" + I2S(MiniMH_VersionSignature) + "，预期=" + I2S(MINIMH_VERSION_SIGNATURE) + "，虚函数表=" + I2S(vtable)
            return
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
            return
        endif
        return
    endfunction
    function MiniMH_InitMemoryBridge takes nothing returns boolean // 使用非空 force 执行原版启动入口方式。
        local force runner = null
        if MiniMH_MemoryBridgeReady then
            return true
        endif
        set runner = CreateForce()
        call ForceAddPlayer(runner, Player(0))
        call ForForce(runner, MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_BootstrapMemory) + 0x8))
        call DestroyForce(runner)
        set runner = null
        return MiniMH_MemoryBridgeReady
    endfunction
endlibrary
//! endnocjass
