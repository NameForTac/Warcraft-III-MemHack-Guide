//! nocjass
library MiniMHEffectAlpha requires MiniMHCore, MiniMHVersion127a, MiniMHMemory, MiniMHHandleTable, MiniMHCalls // Load the state, offsets, memory, handle, and native-call dependencies first.
    function MiniMH_SetEffectAlpha takes effect e, integer alpha returns boolean // Set an effect's alpha; return whether the call path reports success.
        local integer object = 0 // Hold the game object address associated with the effect handle.
        local integer sprite = 0 // Hold the sprite address read from the game object.
        if not MiniMH_Ready or e == null or alpha < 0 or alpha > 255 then // Reject uninitialized use, null handles, and values outside byte range.
            set MiniMH_LastError = "Not ready / null effect / alpha outside 0..255" // Explain why argument validation failed.
            return false // Stop before reading game memory.
        endif // Finish the readiness and input check.
        set object = MiniMH_ConvertEffect(e) // Resolve the JASS effect handle to a game object address.
        if object == 0 then // Check whether handle lookup returned a usable address.
            set MiniMH_LastError = "Effect object not found" // Record the lookup failure.
            return false // Do not dereference a missing object.
        endif // Finish the object-address check.
        set sprite = MiniMH_ReadDword(object + MINIMH_OBJECT_SPRITE_OFFSET) // Read the sprite pointer at the version-specific object offset.
        if sprite == 0 then // Check whether the object contains a nonzero sprite pointer.
            set MiniMH_LastError = "Effect sprite not found" // Record the missing sprite condition.
            return false // Do not call the internal function with a null sprite.
        endif // Finish the sprite-address check.
        if not MiniMH_CallSetAlpha(sprite, alpha) then // Dispatch the internal alpha call through the temporary call thunk.
            return false // Preserve the lower-level error and report failure.
        endif // Finish the internal-call result check.
        set MiniMH_LastError = "OK" // Record that each layer reported success.
        return true // Report success to the map caller; this is not independent runtime verification.
    endfunction // End the public alpha-setting function.
endlibrary // End the effect-alpha library.
//! endnocjass
