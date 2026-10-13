//! nocjass
library MiniMHMemory requires MiniMHCore, MiniMHVersion127a, MiniMHTypecast
    globals
        boolean MiniMH_MemoryBridgeReady = false
        integer Memory
        integer array l__Memory
    endglobals
    function MiniMH_RawRead takes integer address returns integer
        return l__Memory[address / 4]
    endfunction
    function MiniMH_NewGlobal takes nothing returns integer
        return -0x005E0704
    endfunction
    function MiniMH_SetGlobal takes nothing returns nothing
        local integer i = 0x2114D008
    endfunction
    function MiniMH_ReadDword takes integer address returns integer
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then
            return 0
        endif
        return MiniMH_RawRead(address)
    endfunction
    function MiniMH_WriteDword takes integer address, integer value returns boolean
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then
            return false
        endif
        set l__Memory[address / 4] = value
        return MiniMH_RawRead(address) == value
    endfunction
    //# +nosemanticerror
    function MiniMH_InitMemoryBridge takes nothing returns boolean
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
        set MiniMH_VersionSignature = vtable - i[vtable / 4]
        if not MiniMH_CheckVersion127a() then
            set MiniMH_LastError = "Unsupported Game.dll (expected 1.27a)"
            return false
        endif
        set MiniMH_GameBase = vtable - MINIMH_ARRAY_VTABLE_RVA
        call MiniMH_SetArrayHeader(vtable)
        set l__Memory[10] = 0
        set variableId = i[(MiniMH_CodeAddress(function MiniMH_RawRead) + 0x34) / 4]
        set fakeHeader = i[(MiniMH_ArrayAddress() + 0xC) / 4] + 4
        set l__bytecode[0] = 0x0C010900
        set l__bytecode[1] = fakeHeader
        set l__bytecode[2] = 0x11010000
        set l__bytecode[3] = variableId
        set l__bytecode[4] = 0x0C010400
        set l__bytecode[5] = 0
        set l__bytecode[6] = 0x27000000
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
