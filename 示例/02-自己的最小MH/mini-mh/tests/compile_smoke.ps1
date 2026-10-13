param(
    [Parameter(Mandatory = $true)]
    [string] $OutputDirectory
)

$ErrorActionPreference = 'Stop'
$sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ydweRoot = 'D:\YDWE_XZ\Release'
$jassHelper = Join-Path $ydweRoot 'compiler\jasshelper\jasshelper.exe'
$common = Join-Path $ydweRoot 'compiler\jass\24\common.j'
$blizzard = Join-Path $ydweRoot 'compiler\jass\24\blizzard.j'
# Upstream's pjass understands per-function //# +nosemanticerror directives.
# YDWE's stock checker rejects the intentional VM casts in this project.
$pjass = Join-Path (Split-Path (Split-Path (Split-Path (Split-Path $sourceRoot)))) 'MemHackAPI\JassHelper\pjass.exe'

foreach ($required in @($jassHelper, $common, $blizzard, $pjass)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required compiler file is missing: $required"
    }
}
if (Test-Path -LiteralPath $OutputDirectory) {
    if (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -ne 0) {
        throw "Output directory must be empty: $OutputDirectory"
    }
} else {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$stage = Join-Path ([IO.Path]::GetTempPath()) ('minimh-compile-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -LiteralPath $sourceRoot -Destination (Join-Path $stage 'mini-mh') -Recurse
Copy-Item -LiteralPath $jassHelper -Destination (Join-Path $stage 'jasshelper.exe')
$jassHelper = Join-Path $stage 'jasshelper.exe'
$mainScript = @'
//! import "mini-mh/core.j"
//! import "mini-mh/version_127a.j"
//! import "mini-mh/typecast.j"
//! import "mini-mh/memory.j"
//! import "mini-mh/handle_table.j"
//! import "mini-mh/calls.j"
//! import "mini-mh/effect_alpha.j"
//! import "mini-mh/entry.j"
//! import "mini-mh/tests/smoke.j"
function config takes nothing returns nothing
endfunction
function main takes nothing returns nothing
    call InitBlizzard()
    call MiniMH_Smoke()
endfunction
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $stage 'war3map.j'), $mainScript, $utf8)

$configPath = Join-Path $stage 'jasshelper.conf'
# Keep the compiler and checker together in this task's staging directory.
Copy-Item -LiteralPath $pjass -Destination (Join-Path $stage 'pjass.exe')
$checker = @'
@echo off
"%~dp0pjass.exe" %* > "%~dp0pjass-raw.txt" 2>&1
set "checker_exit=%errorlevel%"
if not "%checker_exit%"=="0" (
    type "%~dp0pjass-raw.txt"
    exit /b %checker_exit%
)
rem JassHelper interprets the successful "N errors ignored" summary as failure.
rem Keep the complete report on disk; remove only that summary from its input.
%SystemRoot%\System32\findstr.exe /v /r /c:"^[0-9][0-9]* errors ignored$" "%~dp0pjass-raw.txt"
exit /b 0
'@
[IO.File]::WriteAllText((Join-Path $stage 'check.cmd'), $checker, [Text.Encoding]::ASCII)
$cmdExe = (Join-Path $env:SystemRoot 'System32\cmd.exe').Replace('\', '/')
$configText = "[jasscompiler]`r`n`"$cmdExe`"`r`n`"/d /c check.cmd `$COMMONJ `$BLIZZARDJ `$WAR3MAPJ`"`r`n"
[IO.File]::WriteAllText($configPath, $configText, $utf8)
$compiled = Join-Path $stage 'compiled.j'
$stdoutPath = Join-Path $OutputDirectory 'jasshelper.stdout.txt'
$stderrPath = Join-Path $OutputDirectory 'jasshelper.stderr.txt'
$arguments = @('--nooptimize', '--scriptonly', $common, $blizzard, (Join-Path $stage 'war3map.j'), $compiled)
$previousPath = $env:PATH
try {
    $env:PATH = "$ydweRoot\bin;$ydweRoot\compiler\jasshelper;$ydweRoot\compiler\pjass;$previousPath"
    $process = Start-Process -FilePath $jassHelper -ArgumentList $arguments -WorkingDirectory $stage -Wait -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
} finally {
    $env:PATH = $previousPath
    Copy-Item -LiteralPath $stage -Destination (Join-Path $OutputDirectory 'stage') -Recurse
}
if ($process.ExitCode -ne 0) {
    $stdout = if (Test-Path -LiteralPath $stdoutPath) { [IO.File]::ReadAllText($stdoutPath) } else { '' }
    $stderr = if (Test-Path -LiteralPath $stderrPath) { [IO.File]::ReadAllText($stderrPath) } else { '' }
    $compilerLog = Join-Path $stage 'logs\compileerrors.txt'
    $diagnostic = if (Test-Path -LiteralPath $compilerLog) { [IO.File]::ReadAllText($compilerLog) } else { '' }
    throw "JassHelper failed with exit code $($process.ExitCode). stdout: $stdout stderr: $stderr diagnostics: $diagnostic. Input stage retained at $stage"
}
if (-not (Test-Path -LiteralPath $compiled -PathType Leaf)) {
    throw 'JassHelper returned success without producing the compiled script.'
}
$text = [IO.File]::ReadAllText($compiled)
foreach ($symbol in @('MiniMH_Init', 'MiniMH_SetEffectAlpha', 'MiniMH_CallSetAlpha', 'MiniMH_RestoreNativeSlot')) {
    if ($text -notmatch [regex]::Escape($symbol)) {
        throw "Compiled output is missing expected symbol: $symbol"
    }
}
$hash = (Get-FileHash -LiteralPath $compiled -Algorithm SHA256).Hash
Copy-Item -LiteralPath $compiled -Destination (Join-Path $OutputDirectory 'war3map.j')
[pscustomobject]@{Output=$compiled;SHA256=$hash;Bytes=(Get-Item -LiteralPath $compiled).Length;ExitCode=$process.ExitCode} | Format-List
