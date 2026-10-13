//! nocjass
library MiniMHVersion127a // Keep all version-specific addresses in one library.
    globals // Begin the constants and runtime-discovered values.
        constant string MINIMH_TARGET_VERSION = "1.27a" // Human-readable target game version.
        constant integer MINIMH_ARRAY_VTABLE_RVA = 0xA63B30 // RVA used to derive the Game.dll image base from the array vtable.
        constant integer MINIMH_VERSION_SIGNATURE = 0x277890 // Expected vtable signature for the target build.
        constant integer MINIMH_GAME_STATE_RVA = 0xBE4238 // RVA of the game-state pointer.
        constant integer MINIMH_JASS_ENV_RVA = 0xBE3740 // RVA of the JASS environment pointer.
        constant integer MINIMH_HANDLE_TABLE_OFFSET = 0x19C // Offset from the handle manager to its table root.
        constant integer MINIMH_HANDLE_ENTRY_STRIDE = 0xC // Size of one handle-table entry in bytes.
        constant integer MINIMH_OBJECT_SPRITE_OFFSET = 0x28 // Offset from an effect object to its sprite pointer.
        constant integer MINIMH_SET_ALPHA_RVA = 0x186FA0 // RVA of the internal sprite-alpha routine.
        constant integer MINIMH_MERGE_UNITS_RVA = 0x891F20 // RVA used to locate the temporary allocation dispatch slot.
        constant integer MINIMH_IGNORED_UNITS_RVA = 0x890FB0 // RVA used to locate the temporary alpha-call dispatch slot.
        constant integer MINIMH_VIRTUAL_ALLOC_IAT_RVA = 0x94E270 // RVA of the VirtualAlloc import pointer.
        integer MiniMH_GameBase = 0 // Runtime Game.dll base address discovered during initialization.
        integer MiniMH_VersionSignature = 0 // Runtime signature read from the target process.
    endglobals // End version constants and runtime state.
    function MiniMH_CheckVersion127a takes nothing returns boolean // Compare the observed signature with the expected 1.27a value.
        return MiniMH_VersionSignature == MINIMH_VERSION_SIGNATURE // Accept only the configured target signature.
    endfunction // End the version check.
endlibrary // End the version library.
//! endnocjass
