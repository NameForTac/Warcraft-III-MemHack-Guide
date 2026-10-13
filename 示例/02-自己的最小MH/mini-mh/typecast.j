//! nocjass
// Minimal VM typecasts, adapted from UnryzeC/MemHackAPI APITypecast.
// Setters must precede shadow declarations; readers must follow them.
// Keep the local/global names and disable JassHelper optimization.
library MiniMHTypecast
    globals
        code Code
        code l__Code
        integer Int
        integer l__Int
        boolean Bool
        boolean l__Bool
        integer Array
        integer array l__Array
        integer bytecode
        integer array l__bytecode
    endglobals

    //# +nosemanticerror
    function MiniMH_StoreCode takes code c returns nothing
        set l__Code = c
        return
    endfunction
    //# +nosemanticerror
    function MiniMH_StoreInteger takes integer n returns nothing
        set l__Int = n
        return
    endfunction
    //# +nosemanticerror
    function MiniMH_StoreBoolean takes boolean b returns nothing
        set l__Bool = b
        return
    endfunction
    //# +nosemanticerror
    function MiniMH_SetArrayHeader takes integer vtable returns nothing
        set l__Array[4] = 0
        set l__Array[1] = vtable
        set l__Array[2] = -1
        set l__Array[3] = -1
    endfunction
    //# +nosemanticerror
    function MiniMH_CodeCastDeclaration takes nothing returns nothing
        local integer Code
        local code Int
    endfunction
    //# +nosemanticerror
    function MiniMH_CodeAddress takes code c returns integer
        call MiniMH_StoreCode(c)
        loop
            return l__Code
        endloop
        return 0
    endfunction
    //# +nosemanticerror
    function MiniMH_AddressCode takes integer n returns code
        call MiniMH_StoreInteger(n)
        loop
            return l__Int
        endloop
        return null
    endfunction
    //# +nosemanticerror
    function MiniMH_BooleanCastDeclaration takes nothing returns nothing
        local integer Bool
    endfunction
    //# +nosemanticerror
    function MiniMH_BooleanBits takes boolean b returns integer
        call MiniMH_StoreBoolean(b)
        loop
            return l__Bool
        endloop
        return 0
    endfunction
    //# +nosemanticerror
    function MiniMH_ArrayCastDeclaration takes nothing returns nothing
        local integer Array
    endfunction
    //# +nosemanticerror
    function MiniMH_ArrayAddress takes nothing returns integer
        loop
            return l__Array
        endloop
        return 0
    endfunction
    //# +nosemanticerror
    function MiniMH_BytecodeCastDeclaration takes nothing returns nothing
        local integer bytecode
    endfunction
    //# +nosemanticerror
    function MiniMH_BytecodeAddress takes nothing returns integer
        loop
            return l__bytecode
        endloop
        return 0
    endfunction
endlibrary
//! endnocjass
