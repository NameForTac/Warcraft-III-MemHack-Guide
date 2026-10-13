//! nocjass
library MiniMHEntry requires MiniMHCore, MiniMHMemory, MiniMHHandleTable, MiniMHCalls, MiniMHEffectAlpha
    function MiniMH_Init takes nothing returns boolean // 依次初始化内存桥、句柄表和内部函数调用支持。
        if MiniMH_Ready then
            call MiniMH_Log("已初始化，跳过重复初始化。")
            return true
        endif
        call MiniMH_Log("开始初始化内存桥。")
        if not MiniMH_InitMemoryBridge() then
            call MiniMH_Log("内存桥失败：" + MiniMH_LastError)
            return false
        endif
        call MiniMH_Log("内存桥检查通过：Game.dll 基址=" + I2S(MiniMH_GameBase) + "，版本特征=" + I2S(MiniMH_VersionSignature))
        call MiniMH_Log("开始检查句柄表。")
        if not MiniMH_InitHandleTable() then
            call MiniMH_Log("句柄表失败：" + MiniMH_LastError)
            return false
        endif
        call MiniMH_Log("句柄表检查通过，开始分配调用缓冲区。")
        if not MiniMH_InitCalls() then
            call MiniMH_Log("调用准备失败：" + MiniMH_LastError)
            return false
        endif
        set MiniMH_Ready = true
        set MiniMH_LastError = "OK"
        call MiniMH_Log("初始化完成：调用缓冲区=" + I2S(MiniMH_CallBuffer) + "，原生指针槽=" + I2S(MiniMH_CallSlot))
        return true
    endfunction
    function MiniMH_DemoSetAlpha takes effect e returns boolean // 提供固定透明度为 128 的示例调用入口。
        call MiniMH_Log("开始透明度示例，目标值=128。")
        if not MiniMH_SetEffectAlpha(e, 128) then
            call MiniMH_Log("透明度示例失败：" + MiniMH_LastError)
            return false
        endif
        call MiniMH_Log("透明度调用已返回，原生指针已恢复；请观察特效，当前未回读对象的透明度字段。")
        return true
    endfunction
endlibrary
//! endnocjass
