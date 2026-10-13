//! nocjass
library MiniMHEffectAlpha requires MiniMHCore, MiniMHVersion127a, MiniMHMemory, MiniMHHandleTable
    function MiniMH_SetEffectAlpha takes effect e, integer alpha returns boolean
        local integer pObject = 0
        local integer pSprite = 0

        if not MiniMH_Ready then
            return false
        endif

        if alpha < 0 or alpha > 255 then
            return false
        endif

        set pObject = MiniMH_ConvertEffect(e)
        if pObject == 0 then
            return false
        endif

        set pSprite = MiniMH_ReadDword(pObject + MINIMH_OBJECT_SPRITE_OFFSET)
        if pSprite == 0 then
            return false
        endif

        return MiniMH_WriteDword(pSprite + MINIMH_ALPHA_OFFSET, alpha)
    endfunction
endlibrary
//! endnocjass
