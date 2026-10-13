//! nocjass
library MiniMHVersion127a
    globals
        constant string MINIMH_TARGET_VERSION = "1.27a"
        constant integer MINIMH_ARRAY_VTABLE_RVA = 0xA63B30
        constant integer MINIMH_VERSION_SIGNATURE = 0x277890
        constant integer MINIMH_GAME_STATE_RVA = 0xBE4238
        constant integer MINIMH_JASS_ENV_RVA = 0xBE3740
        constant integer MINIMH_HANDLE_TABLE_OFFSET = 0x19C
        constant integer MINIMH_HANDLE_ENTRY_STRIDE = 0xC
        constant integer MINIMH_OBJECT_SPRITE_OFFSET = 0x28
        constant integer MINIMH_SET_ALPHA_RVA = 0x186FA0
        constant integer MINIMH_MERGE_UNITS_RVA = 0x891F20
        constant integer MINIMH_IGNORED_UNITS_RVA = 0x890FB0
        constant integer MINIMH_VIRTUAL_ALLOC_IAT_RVA = 0x94E270
        integer MiniMH_GameBase = 0
        integer MiniMH_VersionSignature = 0
    endglobals
    function MiniMH_CheckVersion127a takes nothing returns boolean
        return MiniMH_VersionSignature == MINIMH_VERSION_SIGNATURE
    endfunction
endlibrary
//! endnocjass
