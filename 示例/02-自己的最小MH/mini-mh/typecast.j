//! nocjass
// 这些转换沿用 MemHackAPI 的虚拟机表示技术，不是普通的类型安全 JASS 转换。
// 写入函数必须放在同名影子声明之前，以保留所需的生成代码布局。
// 保留局部和全局变量名称，并关闭编译优化；这里的偏移依赖生成代码。
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
    function MiniMH_StoreCode takes code c returns nothing // 把代码值保存到类型重解释使用的影子变量。
        set l__Code = c
        return
    endfunction
    //# +nosemanticerror
    function MiniMH_StoreInteger takes integer n returns nothing // 把整数位模式保存到代码转换使用的影子变量。
        set l__Int = n
        return
    endfunction
    //# +nosemanticerror
    function MiniMH_StoreBoolean takes boolean b returns nothing // 把布尔值保存到位模式读取使用的影子变量。
        set l__Bool = b
        return
    endfunction
    //# +nosemanticerror
    function MiniMH_SetArrayHeader takes integer vtable returns nothing // 填写伪数组头中此转换技术需要的字段。
        set l__Array[4] = 0
        set l__Array[1] = vtable
        set l__Array[2] = -1
        set l__Array[3] = -1
    endfunction
    //# +nosemanticerror
    function MiniMH_CodeCastDeclaration takes nothing returns nothing // 保留 Code 和 Int 的同名局部声明，维持生成代码布局。
        local integer Code
        local code Int
    endfunction
    //# +nosemanticerror
    function MiniMH_CodeAddress takes code c returns integer // 将代码值的虚拟机表示读取为整数地址。
        call MiniMH_StoreCode(c)
        loop
            return l__Code
        endloop
        return 0
    endfunction
    //# +nosemanticerror
    function MiniMH_AddressCode takes integer n returns code // 将整数地址的位模式重解释为代码值。
        call MiniMH_StoreInteger(n)
        loop
            return l__Int
        endloop
        return null
    endfunction
    //# +nosemanticerror
    function MiniMH_BooleanCastDeclaration takes nothing returns nothing // 保留与布尔全局变量同名的整数局部声明。
        local integer Bool
    endfunction
    //# +nosemanticerror
    function MiniMH_BooleanBits takes boolean b returns integer // 将布尔值的虚拟机位模式读取为整数。
        call MiniMH_StoreBoolean(b)
        loop
            return l__Bool
        endloop
        return 0
    endfunction
    //# +nosemanticerror
    function MiniMH_ArrayCastDeclaration takes nothing returns nothing // 保留与数组影子变量同名的整数局部声明。
        local integer Array
    endfunction
    //# +nosemanticerror
    function MiniMH_ArrayAddress takes nothing returns integer // 读取影子数组的地址表示。
        loop
            return l__Array
        endloop
        return 0
    endfunction
    //# +nosemanticerror
    function MiniMH_InitBytecode takes integer variableId, integer fakeHeader returns nothing // 数组写入必须放在下面的同名整数声明之前。
        set l__bytecode[0] = 0x0C010900
        set l__bytecode[1] = fakeHeader
        set l__bytecode[2] = 0x11010000
        set l__bytecode[3] = variableId
        set l__bytecode[4] = 0x0C010400
        set l__bytecode[5] = 0
        set l__bytecode[6] = 0x27000000
    endfunction
    //# +nosemanticerror
    function MiniMH_BytecodeCastDeclaration takes nothing returns nothing // 保留与字节码影子变量同名的整数局部声明。
        local integer bytecode
    endfunction
    //# +nosemanticerror
    function MiniMH_BytecodeAddress takes nothing returns integer // 读取字节码数组的地址表示。
        loop
            return l__bytecode
        endloop
        return 0
    endfunction
endlibrary
//! endnocjass
