//! nocjass
native MergeUnits takes integer qty, integer a, integer b, integer make returns boolean
native IgnoredUnits takes integer unitid returns integer
library MiniMHCalls requires MiniMHMemory
    globals
        integer MiniMH_CallBuffer = 0
        integer MiniMH_CallSlot = 0
        boolean MiniMH_CallSlotsSafe = true
    endglobals
    function MiniMH_FindNativeSlot takes integer target returns integer // 遍历原生函数链表，查找目标函数指针所在的字段地址；未找到时返回 0。
        local integer env = MiniMH_ReadDword(MiniMH_GameBase + MINIMH_JASS_ENV_RVA)
        local integer table = 0
        local integer first = 0
        local integer node = 0
        local integer count = 0
        if env == 0 then
            return 0
        endif
        set table = MiniMH_ReadDword(env + 0x14)
        if table == 0 then
            return 0
        endif
        set first = MiniMH_ReadDword(table + 0x20)
        set node = first
        loop
            exitwhen node == 0 or count >= 4096
            if MiniMH_ReadDword(node + 0xC) == target then
                return node + 0xC
            endif
            set node = MiniMH_ReadDword(node)
            set count = count + 1
            exitwhen node == first
        endloop
        return 0
    endfunction
    function MiniMH_RestoreNativeSlot takes integer slot, integer saved returns boolean // 恢复原生函数的原始指针，并通过回读确认恢复结果。
        if MiniMH_WriteDword(slot, saved) then
            return true
        endif
        if MiniMH_ReadDword(slot) == saved then
            return true
        endif
        set MiniMH_CallSlotsSafe = false
        set MiniMH_Ready = false
        return false
    endfunction
    function MiniMH_InitCalls takes nothing returns boolean // 通过临时重定向 MergeUnits 调用 VirtualAlloc，分配机器码缓冲区。
        local integer allocSlot = MiniMH_FindNativeSlot(MiniMH_GameBase + MINIMH_MERGE_UNITS_RVA)
        local integer saved = 0
        local integer alloc = MiniMH_ReadDword(MiniMH_GameBase + MINIMH_VIRTUAL_ALLOC_IAT_RVA)
        if not MiniMH_CallSlotsSafe then
            set MiniMH_LastError = "Native slot restoration was not verified"
            return false
        endif
        if MiniMH_CallBuffer != 0 then
            return true
        endif
        set MiniMH_CallSlot = MiniMH_FindNativeSlot(MiniMH_GameBase + MINIMH_IGNORED_UNITS_RVA)
        if allocSlot == 0 or MiniMH_CallSlot == 0 or alloc == 0 then
            set MiniMH_LastError = "Native slots / VirtualAlloc not found"
            return false
        endif
        set saved = MiniMH_ReadDword(allocSlot)
        if saved == 0 then
            set MiniMH_LastError = "Cannot read original MergeUnits pointer"
            return false
        endif
        if not MiniMH_WriteDword(allocSlot, alloc) then
            if not MiniMH_RestoreNativeSlot(allocSlot, saved) then
                set MiniMH_LastError = "Cannot redirect or restore MergeUnits"
            else
                set MiniMH_LastError = "Cannot redirect MergeUnits; slot restored"
            endif
            return false
        endif
        set MiniMH_CallBuffer = MiniMH_BooleanBits(MergeUnits(0, 64, 0x3000, 0x40))
        if not MiniMH_RestoreNativeSlot(allocSlot, saved) then
            set MiniMH_LastError = "Cannot restore MergeUnits"
            return false
        endif
        if MiniMH_CallBuffer == 0 then
            set MiniMH_LastError = "VirtualAlloc failed"
            return false
        endif
        return true
    endfunction
    // 此处按 x86 fastcall 约定构造调用：ECX 放精灵指针，EDX 放透明度，其余参数由机器码安排；约定需目标版本实测确认。
    function MiniMH_CallSetAlpha takes integer sprite, integer alpha returns boolean // 写入并执行内部透明度调用的 x86 机器码，再恢复原生函数指针。
        local integer saved = 0
        local integer result = 0
        if MiniMH_CallBuffer == 0 or MiniMH_CallSlot == 0 then
            set MiniMH_LastError = "Call buffer / native slot is unavailable"
            return false
        endif
        if not MiniMH_CallSlotsSafe then
            set MiniMH_LastError = "Native slot restoration was not verified"
            return false
        endif
        set saved = MiniMH_ReadDword(MiniMH_CallSlot)
        if saved == 0 then
            set MiniMH_LastError = "Cannot read original IgnoredUnits pointer"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 0, 0x68909056) then // 写入 push esi、两个 nop 和 push imm32 的操作码字节，保存 ESI 并准备压入参数。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (0)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 4, 0) then // 写入 push imm32 的立即数 0，作为栈上的附加参数。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (4)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 8, 0xBA909090) then // 写入三个 nop 和 mov edx, imm32 的操作码。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (8)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 12, alpha) then // 写入透明度立即数，供 EDX 寄存器加载。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (12)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 16, 0xB9909090) then // 写入三个 nop 和 mov ecx, imm32 的操作码。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (16)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 20, sprite) then // 写入精灵指针立即数，供 ECX 寄存器加载。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (20)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 24, 0xBE909090) then // 写入三个 nop 和 mov esi, imm32 的操作码。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (24)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 28, MiniMH_GameBase + MINIMH_SET_ALPHA_RVA) then // 写入内部透明度函数的绝对地址，供 ESI 寄存器加载。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (28)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 32, 0xC35ED6FF) then // 写入 call esi、pop esi、ret 的字节，调用目标并恢复寄存器后返回。写入失败时进入错误分支。
            set MiniMH_LastError = "Cannot write alpha thunk (32)"
            return false
        endif
        if not MiniMH_WriteDword(MiniMH_CallSlot, MiniMH_CallBuffer) then
            if not MiniMH_RestoreNativeSlot(MiniMH_CallSlot, saved) then
                set MiniMH_LastError = "Cannot redirect or restore IgnoredUnits"
            else
                set MiniMH_LastError = "Cannot redirect IgnoredUnits; slot restored"
            endif
            return false
        endif
        set result = IgnoredUnits(0)
        if not MiniMH_RestoreNativeSlot(MiniMH_CallSlot, saved) then
            set MiniMH_LastError = "Cannot restore IgnoredUnits"
            return false
        endif
        return true
    endfunction
endlibrary
//! endnocjass
