//! nocjass
library MiniMHEffectAlpha requires MiniMHCore, MiniMHVersion127a, MiniMHMemory, MiniMHHandleTable, MiniMHCalls
    function MiniMH_SetEffectAlpha takes effect e, integer alpha returns boolean // 设置 0..255 透明度；返回调用流程结果，不回读透明度字段。
        local integer object = 0
        local integer sprite = 0
        if not MiniMH_Ready or e == null or alpha < 0 or alpha > 255 then
            set MiniMH_LastError = "Not ready / null effect / alpha outside 0..255"
            return false
        endif
        set object = MiniMH_ConvertEffect(e)
        if object == 0 then
            set MiniMH_LastError = "Effect object not found"
            return false
        endif
        set sprite = MiniMH_ReadDword(object + MINIMH_OBJECT_SPRITE_OFFSET)
        if sprite == 0 then
            set MiniMH_LastError = "Effect sprite not found"
            return false
        endif
        if not MiniMH_CallSetAlpha(sprite, alpha) then
            return false
        endif
        set MiniMH_LastError = "OK"
        return true
    endfunction
endlibrary
//! endnocjass
