//! nocjass
library MiniMHMemory requires MiniMHCore, MiniMHVersion127a, MiniMHTypecast // Use shared status, version constants, and local VM casts.
    globals // Begin memory-bridge globals.
        boolean MiniMH_MemoryBridgeReady = false // Mark whether the VM bridge passed its initialization check.
        integer Memory // Shadow global whose generated slot is used by the VM memory-read technique.
        integer array l__Memory // Shadow array overlaid on process memory by generated JASS bytecode.
    endglobals // End memory-bridge globals.
    function MiniMH_RawRead takes integer address returns integer // VM helper that reads a dword through the overlaid array.
        return l__Memory[address / 4] // Convert a byte address to the corresponding 4-byte array index.
    endfunction // End the raw read helper.
    function MiniMH_NewGlobal takes nothing returns integer // Provide a small function body used to expose a code address.
        return -0x005E0704 // Return the encoded address offset expected by this bootstrap technique.
    endfunction // End the code-address anchor.
    function MiniMH_SetGlobal takes nothing returns nothing // Provide a function with a local to locate the generated global slot.
        local integer i = 0x2114D008 // Seed the local slot with the bootstrap constant; the initializer is significant to generated code.
    endfunction // End the local-slot anchor.
    function MiniMH_ReadDword takes integer address returns integer // Guarded public dword read.
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then // Reject pre-init, low, or unaligned addresses.
            return 0 // Use zero as the current API's failure value.
        endif // Finish read validation.
        return MiniMH_RawRead(address) // Perform the VM-backed read.
    endfunction // End the public read helper.
    function MiniMH_WriteDword takes integer address, integer value returns boolean // Guarded public dword write with a readback check.
        if not MiniMH_MemoryBridgeReady or address < 0x500 or address / 4 * 4 != address then // Reject pre-init, low, or unaligned addresses.
            return false // Report that no write was attempted.
        endif // Finish write validation.
        set l__Memory[address / 4] = value // Store through the array overlay at the dword index.
        return MiniMH_RawRead(address) == value // Confirm the observed value equals the requested value.
    endfunction // End the public write helper.
    //# +nosemanticerror
    function MiniMH_InitMemoryBridge takes nothing returns boolean // Bootstrap the memory overlay; runtime correctness remains to be tested by the user.
        local integer array i // Scratch array used to inspect JASS array/vtable metadata during bootstrap.
        local integer vtable = 0 // Hold the array vtable address discovered from the scratch array.
        local integer variableId = 0 // Hold the generated variable identifier for MiniMH_RawRead's parameter.
        local integer fakeHeader = 0 // Hold the header address used by the crafted bytecode.
        if MiniMH_MemoryBridgeReady then // Make successful initialization idempotent.
            return true // Return the already-ready state.
        endif // Finish the repeated-call check.
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_NewGlobal) + 2)) // Trigger the code-pointer conversion primitive through a Blizzard native.
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(MiniMH_CodeAddress(function MiniMH_SetGlobal) + 8)) // Trigger the second bootstrap primitive at the local-slot code offset.
        call MiniMH_SetArrayHeader(0) // Prepare the shadow array metadata before reading its backing information.
        set vtable = i[MiniMH_ArrayAddress() / 4] // Read the array's vtable pointer using the casted array address.
        set MiniMH_VersionSignature = vtable - i[vtable / 4] // Derive the build signature from the vtable and a vtable-relative dword.
        if not MiniMH_CheckVersion127a() then // Stop if the observed signature differs from the configured build.
            set MiniMH_LastError = "Unsupported Game.dll (expected 1.27a)" // Explain that the target signature did not match.
            return false // Do not continue with version-specific offsets.
        endif // Finish the version gate.
        set MiniMH_GameBase = vtable - MINIMH_ARRAY_VTABLE_RVA // Convert the known array-vtable RVA into a Game.dll base.
        call MiniMH_SetArrayHeader(vtable) // Point the shadow array metadata at the discovered vtable.
        set l__Memory[10] = 0 // Initialize the shadow slot used by the generated memory bridge.
        set variableId = i[(MiniMH_CodeAddress(function MiniMH_RawRead) + 0x34) / 4] // Read the generated JASS variable ID at the assumed function offset.
        set fakeHeader = i[(MiniMH_ArrayAddress() + 0xC) / 4] + 4 // Derive a crafted array-header address from the VM array layout.
        set l__bytecode[0] = 0x0C010900 // Write bytecode word 0: opcode/header portion for the generated read sequence.
        set l__bytecode[1] = fakeHeader // Write bytecode word 1: address of the crafted array header.
        set l__bytecode[2] = 0x11010000 // Write bytecode word 2: opcode portion for the variable access.
        set l__bytecode[3] = variableId // Write bytecode word 3: target variable identifier.
        set l__bytecode[4] = 0x0C010400 // Write bytecode word 4: opcode portion for the follow-up operation.
        set l__bytecode[5] = 0 // Write bytecode word 5: zero operand used by this sequence.
        set l__bytecode[6] = 0x27000000 // Write bytecode word 6: sequence terminator/return opcode encoding.
        call ForForce(bj_FORCE_PLAYER[0], MiniMH_AddressCode(i[(MiniMH_BytecodeAddress() + 0xC) / 4])) // Execute the generated sequence through ForForce's code callback.
        set MiniMH_MemoryBridgeReady = true // Temporarily enable guarded access so the DOS header can be checked.
        if MiniMH_ReadDword(MiniMH_GameBase) != 0x00905A4D then // Verify the image begins with the DOS MZ signature.
            set MiniMH_MemoryBridgeReady = false // Disable reads again if the memory mapping check fails.
            set MiniMH_LastError = "Memory bridge: Game.dll DOS header mismatch" // Record the failed signature check.
            return false // Refuse to report the bridge ready.
        endif // Finish the Game.dll header check.
        return true // Report that the bootstrap's checks passed.
    endfunction // End memory-bridge initialization.
endlibrary // End the memory library.
//! endnocjass
