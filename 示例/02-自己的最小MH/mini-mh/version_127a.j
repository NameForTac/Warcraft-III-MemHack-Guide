//! nocjass
library MiniMHVersion127a
    // 仅允许一个目标版本。0 和空字符串表示“尚未验证”。
    globals
        constant string MINIMH_TARGET_VERSION = "1.27a"
        constant integer MINIMH_GAME_STATE_ADDRESS = 0
        constant integer MINIMH_HANDLE_TABLE_OFFSET = 0
        constant integer MINIMH_HANDLE_ENTRY_STRIDE = 0
        constant integer MINIMH_OBJECT_SPRITE_OFFSET = 0
        constant integer MINIMH_ALPHA_OFFSET = 0
    endglobals

    function MiniMH_CheckVersion127a takes nothing returns boolean
        // TODO: 用你在离线 1.27a 环境中验证的稳定特征替换此占位逻辑。
        return false
    endfunction
endlibrary
//! endnocjass
