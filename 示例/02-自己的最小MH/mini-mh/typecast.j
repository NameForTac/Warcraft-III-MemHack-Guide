//! nocjass
// These casts adapt the VM representation technique used by MemHackAPI; they are not ordinary type-safe JASS conversions.
// Setter functions must stay before their shadow declarations so generated code keeps the required layout.
// Keep the local/global names and compile with optimization disabled because offsets depend on generated code.
library MiniMHTypecast // Group the local representation bridges in one dependency-free library.
    globals // Begin shadow variables used to reinterpret VM values.
        code Code // Global code-typed shadow used by the code-to-integer bridge.
        code l__Code // Generated/global shadow slot read as an integer by the VM trick.
        integer Int // Global integer shadow used by the integer-to-code bridge.
        integer l__Int // Generated/global integer slot returned through a code-typed declaration.
        boolean Bool // Global boolean shadow used by the boolean-to-integer bridge.
        boolean l__Bool // Generated/global boolean slot read as an integer bit pattern.
        integer Array // Shadow scalar declaration used to obtain array metadata.
        integer array l__Array // Shadow array whose header and backing address are inspected.
        integer bytecode // Shadow scalar declaration used to obtain bytecode storage metadata.
        integer array l__bytecode // Array containing crafted VM bytecode words.
    endglobals // End shadow declarations.

    //# +nosemanticerror
    function MiniMH_StoreCode takes code c returns nothing // Store a code value in the shadow slot.
        set l__Code = c // Assign the code representation to the generated shadow global.
        return // Explicitly keep the setter body and prevent unwanted simplification.
    endfunction // End code storage.
    //# +nosemanticerror
    function MiniMH_StoreInteger takes integer n returns nothing // Store an integer in the code-cast shadow slot.
        set l__Int = n // Assign the integer bits to the shadow global.
        return // Preserve the setter as a separate generated function.
    endfunction // End integer storage.
    //# +nosemanticerror
    function MiniMH_StoreBoolean takes boolean b returns nothing // Store a boolean in the boolean shadow slot.
        set l__Bool = b // Assign the boolean value before reading its VM bits.
        return // Preserve the setter body.
    endfunction // End boolean storage.
    //# +nosemanticerror
    function MiniMH_SetArrayHeader takes integer vtable returns nothing // Populate the minimum header fields required by the array-address trick.
        set l__Array[4] = 0 // Clear the header's element/size-related slot used by this layout.
        set l__Array[1] = vtable // Install the selected array vtable pointer.
        set l__Array[2] = -1 // Mark the lower bound/header field with the expected sentinel.
        set l__Array[3] = -1 // Mark the upper bound/header field with the expected sentinel.
    endfunction // End synthetic array-header setup.
    //# +nosemanticerror
    function MiniMH_CodeCastDeclaration takes nothing returns nothing // Keep the Code/Int local declarations in generated output.
        local integer Code // Integer local deliberately colliding with the global code name.
        local code Int // Code local deliberately colliding with the global integer name.
    endfunction // End declaration-only layout anchor.
    //# +nosemanticerror
    function MiniMH_CodeAddress takes code c returns integer // Return the VM address/bit representation of a code value.
        call MiniMH_StoreCode(c) // Place the input code in the shadow slot first.
        loop // Use a loop return to preserve the generated read path.
            return l__Code // Read the code shadow as an integer representation.
        endloop // End the single-iteration layout-preserving loop.
        return 0 // Unreachable fallback required by some checkers.
    endfunction // End code-to-address conversion.
    //# +nosemanticerror
    function MiniMH_AddressCode takes integer n returns code // Reinterpret an integer address as a code value.
        call MiniMH_StoreInteger(n) // Place the integer bits in the shadow slot.
        loop // Preserve the generated conversion path with a non-inlined loop.
            return l__Int // Read the integer shadow through the code return type.
        endloop // End the single-iteration loop.
        return null // Unreachable fallback required by some checkers.
    endfunction // End address-to-code conversion.
    //# +nosemanticerror
    function MiniMH_BooleanCastDeclaration takes nothing returns nothing // Keep the boolean/integer local layout anchor.
        local integer Bool // Integer local deliberately colliding with the global boolean name.
    endfunction // End boolean declaration anchor.
    //# +nosemanticerror
    function MiniMH_BooleanBits takes boolean b returns integer // Return the VM bit representation of a boolean.
        call MiniMH_StoreBoolean(b) // Store the boolean before reading its shadow bits.
        loop // Preserve the generated read path.
            return l__Bool // Read the boolean slot as an integer representation.
        endloop // End the single-iteration loop.
        return 0 // Unreachable fallback required by some checkers.
    endfunction // End boolean conversion.
    //# +nosemanticerror
    function MiniMH_ArrayCastDeclaration takes nothing returns nothing // Keep the array/integer local layout anchor.
        local integer Array // Integer local deliberately colliding with the array name.
    endfunction // End array declaration anchor.
    //# +nosemanticerror
    function MiniMH_ArrayAddress takes nothing returns integer // Return the backing address/representation of l__Array.
        loop // Preserve the generated array access path.
            return l__Array // Read the array representation as an integer address.
        endloop // End the single-iteration loop.
        return 0 // Unreachable fallback required by some checkers.
    endfunction // End array-address conversion.
    //# +nosemanticerror
    function MiniMH_BytecodeCastDeclaration takes nothing returns nothing // Keep the bytecode/integer local layout anchor.
        local integer bytecode // Integer local deliberately colliding with the bytecode name.
    endfunction // End bytecode declaration anchor.
    //# +nosemanticerror
    function MiniMH_BytecodeAddress takes nothing returns integer // Return the backing address/representation of l__bytecode.
        loop // Preserve the generated array access path.
            return l__bytecode // Read the bytecode array representation as an integer address.
        endloop // End the single-iteration loop.
        return 0 // Unreachable fallback required by some checkers.
    endfunction // End bytecode-address conversion.
endlibrary // End the typecast library.
//! endnocjass
