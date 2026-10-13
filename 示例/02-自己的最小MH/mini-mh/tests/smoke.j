function MiniMH_Smoke takes nothing returns nothing
    local effect e = AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", 0, 0)
    if not MiniMH_Init() then
        call BJDebugMsg("FAIL: " + MiniMH_LastError)
    elseif not MiniMH_SetEffectAlpha(e, 128) then
        call BJDebugMsg("FAIL: SetEffectAlpha")
    else
        call BJDebugMsg("PASS: alpha call completed; inspect visual result")
    endif
    call DestroyEffect(e)
    set e = null
endfunction
