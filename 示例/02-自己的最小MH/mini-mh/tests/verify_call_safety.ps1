$ErrorActionPreference = 'Stop'

$callsPath = Join-Path $PSScriptRoot '..\calls.j'
$source = Get-Content -LiteralPath $callsPath -Raw

function Get-FunctionBody([string] $Text, [string] $Name) {
    $pattern = '(?s)function\s+' + [regex]::Escape($Name) + '\b.*?\n endfunction'
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        throw "Function not found: $Name"
    }
    return $match.Value
}

$init = Get-FunctionBody $source 'MiniMH_InitCalls'
$call = Get-FunctionBody $source 'MiniMH_CallSetAlpha'
$restore = Get-FunctionBody $source 'MiniMH_RestoreNativeSlot'

$setupWrites = [regex]::Matches($call, '(?m)^\s*if not MiniMH_WriteDword\(MiniMH_CallBuffer')
$checkedSetupWrites = [regex]::Matches($call, '(?m)^\s*if not MiniMH_WriteDword\(MiniMH_CallBuffer')
if ($setupWrites.Count -ne 9 -or $checkedSetupWrites.Count -ne 9) {
    throw "Expected all 9 alpha thunk writes to be checked; found $($setupWrites.Count) writes and $($checkedSetupWrites.Count) checks."
}

if ($call -notmatch 'if not MiniMH_WriteDword\(MiniMH_CallSlot, MiniMH_CallBuffer\) then(?s:.*?)MiniMH_RestoreNativeSlot\(MiniMH_CallSlot, saved\)') {
    throw 'Redirect failure must attempt to restore the native slot.'
}
if ($call -notmatch 'set result = IgnoredUnits\(0\)(?s:.*?)MiniMH_RestoreNativeSlot\(MiniMH_CallSlot, saved\)') {
    throw 'The native slot must be restored after dispatch.'
}
if ($call -notmatch 'MiniMH_CallSlotsSafe') {
    throw 'Native calls must be disabled after an unverified slot restoration.'
}
if ($restore -notmatch 'MiniMH_ReadDword\(slot\) == saved(?s:.*?)set MiniMH_CallSlotsSafe = false(?s:.*?)set MiniMH_Ready = false') {
    throw 'Unverified restoration must permanently mark the call slots unsafe and clear readiness.'
}
if ($call -notmatch 'set saved = MiniMH_ReadDword\(MiniMH_CallSlot\)(?s:.*?)if saved == 0 then') {
    throw 'The original native pointer must be validated before patching.'
}
if ($init -notmatch 'set saved = MiniMH_ReadDword\(allocSlot\)(?s:.*?)if saved == 0 then') {
    throw 'The allocator native pointer must be validated before patching.'
}

if ($init -notmatch 'if not MiniMH_WriteDword\(allocSlot, alloc\) then(?s:.*?)MiniMH_RestoreNativeSlot\(allocSlot, saved\)') {
    throw 'Allocation redirect failure must attempt to restore the native slot.'
}
if ($init -notmatch 'set MiniMH_CallBuffer = MiniMH_BooleanBits(?s:.*?)MiniMH_RestoreNativeSlot\(allocSlot, saved\)') {
    throw 'The allocation native slot must be restored after dispatch.'
}

Write-Output 'PASS: native-slot writes are checked and every redirect failure path attempts restoration.'
