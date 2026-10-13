function MiniMH_Smoke takes nothing returns nothing
    local effect e = AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", 0, 0)
    if not MiniMH_Init() then
        call BJDebugMsg("[MiniMH 示例] 初始化失败：" + MiniMH_LastError)
    elseif not MiniMH_DemoSetAlpha(e) then
        call BJDebugMsg("[MiniMH 示例] 透明度调用失败：" + MiniMH_LastError)
    else
        call BJDebugMsg("[MiniMH 示例] 写入回读和调用流程通过；透明度视觉效果需另行观察。")
    endif
    call DestroyEffect(e)
    set e = null
endfunction
