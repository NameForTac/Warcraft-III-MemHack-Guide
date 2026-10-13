//! nocjass
native MergeUnits takes integer qty, integer a, integer b, integer make returns boolean // Declare the target native used here as a temporary VirtualAlloc dispatch route.
native IgnoredUnits takes integer unitid returns integer // Declare the target native whose dispatch slot is temporarily redirected to the alpha thunk.
library MiniMHCalls requires MiniMHMemory // Depend on guarded memory reads and writes.
    globals // Begin native-call state.
        integer MiniMH_CallBuffer = 0 // Executable memory buffer used to hold the generated x86 thunk.
        integer MiniMH_CallSlot = 0 // Address of the IgnoredUnits native's dispatch pointer.
        boolean MiniMH_CallSlotsSafe = true // Latch indicating whether modified native slots were restored/read back.
    endglobals // End native-call state.
    // Search the native table for the entry whose function pointer equals target; do not mutate it here.
    function MiniMH_FindNativeSlot takes integer target returns integer // Return the address of a matching function-pointer field, or zero.
        local integer env = MiniMH_ReadDword(MiniMH_GameBase + MINIMH_JASS_ENV_RVA) // Read the JASS environment pointer from its version-specific RVA.
        local integer table = 0 // Hold the native-table pointer.
        local integer first = 0 // Remember the first list node to detect a circular-list wrap.
        local integer node = 0 // Hold the current native entry node.
        local integer count = 0 // Bound traversal in case the list is corrupt or layout differs.
        if env == 0 then // Reject a missing JASS environment.
            return 0 // Report that no slot was found.
        endif // Finish environment validation.
        set table = MiniMH_ReadDword(env + 0x14) // Read the native table pointer from the environment structure.
        if table == 0 then // Reject a missing native table.
            return 0 // Report that no slot was found.
        endif // Finish native-table validation.
        set first = MiniMH_ReadDword(table + 0x20) // Read the first entry pointer from the table.
        set node = first // Begin traversal at the list head.
        loop // Walk the native-entry list until found, empty, wrapped, or capped.
            exitwhen node == 0 or count >= 4096 // Stop for a null entry or after the defensive iteration bound.
            if MiniMH_ReadDword(node + 0xC) == target then // Compare this entry's function pointer to the requested address.
                return node + 0xC // Return the address of the pointer field itself for temporary replacement.
            endif // Finish this entry's comparison.
            set node = MiniMH_ReadDword(node) // Follow the linked-list next pointer.
            set count = count + 1 // Count this visited node toward the safety cap.
            exitwhen node == first // Stop if traversal has wrapped back to the head.
        endloop // End native-list traversal.
        return 0 // Report no matching function-pointer field.
    endfunction // End native-slot lookup.
    function MiniMH_RestoreNativeSlot takes integer slot, integer saved returns boolean // Restore a modified dispatch pointer and verify the result.
        if MiniMH_WriteDword(slot, saved) then // Attempt to write the saved original pointer back.
            return true // Report success when the write helper confirms readback.
        endif // Finish the first restoration attempt.
        if MiniMH_ReadDword(slot) == saved then // Check whether the slot already has the saved value despite a failed write result.
            return true // Treat matching readback as restored.
        endif // Finish the fallback verification.
        set MiniMH_CallSlotsSafe = false // Permanently block further native calls after unverified restoration.
        set MiniMH_Ready = false // Clear global readiness because a dispatch pointer may remain changed.
        return false // Report that restoration could not be confirmed.
    endfunction // End slot restoration.
    function MiniMH_InitCalls takes nothing returns boolean // Allocate executable thunk storage using the configured native-call route.
        local integer allocSlot = MiniMH_FindNativeSlot(MiniMH_GameBase + MINIMH_MERGE_UNITS_RVA) // Locate the MergeUnits entry used as the temporary allocation dispatch slot.
        local integer saved = 0 // Preserve the current MergeUnits pointer before redirecting it.
        local integer alloc = MiniMH_ReadDword(MiniMH_GameBase + MINIMH_VIRTUAL_ALLOC_IAT_RVA) // Read the imported VirtualAlloc address from Game.dll.
        if not MiniMH_CallSlotsSafe then // Refuse setup if any prior dispatch restoration was uncertain.
            set MiniMH_LastError = "Native slot restoration was not verified" // Explain why native-call setup is disabled.
            return false // Stop without touching another native slot.
        endif // Finish safety-latch check.
        if MiniMH_CallBuffer != 0 then // Detect an already allocated call buffer.
            return true // Treat the existing buffer as initialized.
        endif // Finish idempotence check.
        set MiniMH_CallSlot = MiniMH_FindNativeSlot(MiniMH_GameBase + MINIMH_IGNORED_UNITS_RVA) // Locate the native entry to be used for later thunk invocation.
        if allocSlot == 0 or MiniMH_CallSlot == 0 or alloc == 0 then // Ensure all addresses required for allocation and dispatch were found.
            set MiniMH_LastError = "Native slots / VirtualAlloc not found" // Record which setup prerequisites were unavailable.
            return false // Abort before any pointer mutation.
        endif // Finish address validation.
        set saved = MiniMH_ReadDword(allocSlot) // Save the original MergeUnits function pointer.
        if saved == 0 then // Reject an unreadable or null original pointer.
            set MiniMH_LastError = "Cannot read original MergeUnits pointer" // Record the failed save step.
            return false // Abort before redirecting the slot.
        endif // Finish original-pointer validation.
        if not MiniMH_WriteDword(allocSlot, alloc) then // Temporarily route MergeUnits through the VirtualAlloc import.
            if not MiniMH_RestoreNativeSlot(allocSlot, saved) then // Try to restore the original pointer after a failed redirect.
                set MiniMH_LastError = "Cannot redirect or restore MergeUnits" // Report both redirect and recovery failure.
            else // The original pointer was recovered successfully.
                set MiniMH_LastError = "Cannot redirect MergeUnits; slot restored" // Report that the redirect failed but cleanup succeeded.
            endif // Finish redirect-failure recovery.
            return false // Stop because the allocation dispatch was not installed.
        endif // Finish temporary allocation-slot redirect.
        set MiniMH_CallBuffer = MiniMH_BooleanBits(MergeUnits(0, 64, 0x3000, 0x40)) // Invoke the redirected route with allocation-like arguments and capture its returned pointer bits.
        if not MiniMH_RestoreNativeSlot(allocSlot, saved) then // Restore MergeUnits immediately after the allocation request.
            set MiniMH_LastError = "Cannot restore MergeUnits" // Record that the original dispatch pointer was not recovered.
            return false // Stop because the native table may be left modified.
        endif // Finish restoration of the allocation slot.
        if MiniMH_CallBuffer == 0 then // Check whether the allocation route returned a null pointer.
            set MiniMH_LastError = "VirtualAlloc failed" // Report a null allocation result.
            return false // Do not proceed without executable buffer storage.
        endif // Finish allocation-result check.
        return true // Report call-buffer setup success.
    endfunction // End native-call initialization.
    // x86 fastcall assumption: ECX=sprite and EDX=alpha; the remaining synthetic argument frame is handled by the thunk.
    function MiniMH_CallSetAlpha takes integer sprite, integer alpha returns boolean // Build and invoke the internal alpha-call thunk.
        local integer saved = 0 // Preserve the current IgnoredUnits function pointer before redirecting it.
        local integer result = 0 // Receive the IgnoredUnits return value; currently retained only as a local.
        if MiniMH_CallBuffer == 0 or MiniMH_CallSlot == 0 then // Require both the allocated thunk buffer and dispatch pointer field.
            set MiniMH_LastError = "Call buffer / native slot is unavailable" // Explain the missing call setup.
            return false // Stop before writing code or modifying dispatch.
        endif // Finish resource checks.
        if not MiniMH_CallSlotsSafe then // Refuse calls after any unverified prior slot restoration.
            set MiniMH_LastError = "Native slot restoration was not verified" // Report the latched safety failure.
            return false // Do not perform another native dispatch mutation.
        endif // Finish safety-latch check.
        set saved = MiniMH_ReadDword(MiniMH_CallSlot) // Save the current IgnoredUnits function pointer.
        if saved == 0 then // Reject a missing original pointer.
            set MiniMH_LastError = "Cannot read original IgnoredUnits pointer" // Record the save failure.
            return false // Abort before redirecting the slot.
        endif // Finish pointer validation.
        // These writes place x86 instruction bytes at the thunk offsets; their encoding and ABI require target-build verification.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 0, 0x68909056) then // Write push esi plus NOP/immediate setup bytes at offset 0.
            set MiniMH_LastError = "Cannot write alpha thunk (0)" // Identify the failed buffer write.
            return false // Stop when the first instruction word cannot be written.
        endif // Finish offset-0 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 4, 0) then // Reserve/clear the immediate word consumed by the instruction sequence.
            set MiniMH_LastError = "Cannot write alpha thunk (4)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-4 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 8, 0xBA909090) then // Write NOP padding followed by the x86 mov edx, imm32 opcode.
            set MiniMH_LastError = "Cannot write alpha thunk (8)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-8 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 12, alpha) then // Store alpha as the immediate operand loaded into EDX.
            set MiniMH_LastError = "Cannot write alpha thunk (12)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-12 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 16, 0xB9909090) then // Write NOP padding followed by the x86 mov ecx, imm32 opcode.
            set MiniMH_LastError = "Cannot write alpha thunk (16)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-16 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 20, sprite) then // Store the sprite pointer as the immediate operand loaded into ECX.
            set MiniMH_LastError = "Cannot write alpha thunk (20)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-20 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 24, 0xBE909090) then // Write NOP padding followed by the x86 mov esi, imm32 opcode.
            set MiniMH_LastError = "Cannot write alpha thunk (24)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-24 write.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 28, MiniMH_GameBase + MINIMH_SET_ALPHA_RVA) then // Store the absolute target address as the ESI immediate operand.
            set MiniMH_LastError = "Cannot write alpha thunk (28)" // Identify the failed buffer write.
            return false // Stop on write failure.
        endif // Finish offset-28 write.
        // Final opcode bytes encode call esi; pop esi; ret, preserving the caller's saved ESI register.
        if not MiniMH_WriteDword(MiniMH_CallBuffer + 32, 0xC35ED6FF) then // Write the call/restore/return instruction word.
            set MiniMH_LastError = "Cannot write alpha thunk (32)" // Identify the failed buffer write.
            return false // Stop when the final instruction word cannot be written.
        endif // Finish offset-32 write.
        if not MiniMH_WriteDword(MiniMH_CallSlot, MiniMH_CallBuffer) then // Redirect IgnoredUnits to execute the thunk on the next call.
            if not MiniMH_RestoreNativeSlot(MiniMH_CallSlot, saved) then // Attempt recovery in case the redirect partially took effect.
                set MiniMH_LastError = "Cannot redirect or restore IgnoredUnits" // Report redirect and restoration failure.
            else // Restoration succeeded after the failed redirect.
                set MiniMH_LastError = "Cannot redirect IgnoredUnits; slot restored" // Report a clean redirect failure.
            endif // Finish redirect-failure handling.
            return false // Do not invoke a slot that did not redirect successfully.
        endif // Finish temporary alpha-slot redirect.
        set result = IgnoredUnits(0) // Call the redirected native entry, which should enter the generated thunk.
        if not MiniMH_RestoreNativeSlot(MiniMH_CallSlot, saved) then // Restore the original native pointer immediately after dispatch.
            set MiniMH_LastError = "Cannot restore IgnoredUnits" // Record that recovery could not be confirmed.
            return false // Report failure because the process dispatch table may remain changed.
        endif // Finish alpha-slot restoration.
        return true // Report successful dispatch and pointer restoration; the alpha effect itself is not read back here.
    endfunction // End the alpha-call helper.
endlibrary // End the native-call library.
//! endnocjass
