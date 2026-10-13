// 单实例教学示例：创建一个特效、调整外观，三秒后销毁。
// 本文件使用标准 JASS 语法，但依赖 MemHackAPI 提供的 SetEffectAlpha/SetEffectScale。
globals
    effect Demo_Effect = null
    timer Demo_Timer = null
endglobals

function Demo_DestroyEffect takes nothing returns nothing
    if Demo_Effect != null then
        call DestroyEffect(Demo_Effect)
        set Demo_Effect = null
    endif

    if Demo_Timer != null then
        call DestroyTimer(Demo_Timer)
        set Demo_Timer = null
    endif
endfunction

function Demo_Start takes nothing returns nothing
    local real x = GetRectCenterX(bj_mapInitialPlayableArea)
    local real y = GetRectCenterY(bj_mapInitialPlayableArea)

    // 先清理上一次运行留下的对象，保证本例始终只有一个特效和一个计时器。
    call Demo_DestroyEffect()

    set Demo_Effect = AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", x, y)
    if Demo_Effect == null then
        return
    endif

    // 下列两个函数由 MemHackAPI 提供，不是标准 Warcraft III JASS native。
    call SetEffectAlpha(Demo_Effect, 128)
    call SetEffectScale(Demo_Effect, 1.50)

    set Demo_Timer = CreateTimer()
    call TimerStart(Demo_Timer, 3.00, false, function Demo_DestroyEffect)
endfunction
