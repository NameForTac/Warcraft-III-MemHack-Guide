//! nocjass
library MiniMHVersion127a
    globals
        constant string MINIMH_TARGET_VERSION = "1.27a"
        constant integer MINIMH_ARRAY_VTABLE_RVA = 0xA63B30 // 声明全局变量：数组虚函数表相对 Game.dll 基址的偏移，用于推算模块基址。
        constant integer MINIMH_VERSION_SIGNATURE = 0x277890 // 声明全局变量：目标版本预期的虚函数表特征值。
        constant integer MINIMH_GAME_STATE_RVA = 0xBE4238 // 声明全局变量：游戏状态指针相对模块基址的偏移。
        constant integer MINIMH_JASS_ENV_RVA = 0xBE3740 // 声明全局变量：JASS 环境指针相对模块基址的偏移。
        constant integer MINIMH_HANDLE_TABLE_OFFSET = 0x19C // 声明全局变量：句柄管理器到句柄表根指针的偏移。
        constant integer MINIMH_HANDLE_ENTRY_STRIDE = 0xC // 声明全局变量：每个句柄表条目的字节数。
        constant integer MINIMH_OBJECT_SPRITE_OFFSET = 0x28 // 声明全局变量：特效对象中精灵指针的偏移。
        constant integer MINIMH_SET_ALPHA_RVA = 0x186FA0 // 声明全局变量：内部精灵透明度函数相对模块基址的偏移。
        constant integer MINIMH_MERGE_UNITS_RVA = 0x891F20 // 声明全局变量：用于查找临时分配调用入口的 MergeUnits 函数偏移。
        constant integer MINIMH_IGNORED_UNITS_RVA = 0x890FB0 // 声明全局变量：用于查找透明度调用入口的 IgnoredUnits 函数偏移。
        constant integer MINIMH_VIRTUAL_ALLOC_IAT_RVA = 0x94E270 // 声明全局变量：VirtualAlloc 导入函数指针相对模块基址的偏移。
        integer MiniMH_GameBase = 0
        integer MiniMH_VersionSignature = 0
    endglobals
    function MiniMH_CheckVersion127a takes nothing returns boolean // 比较运行时版本特征值与配置的 1.27a 特征值。
        return MiniMH_VersionSignature == MINIMH_VERSION_SIGNATURE
    endfunction
endlibrary
//! endnocjass
