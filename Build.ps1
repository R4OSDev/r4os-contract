param()
$BuildArguments=@($args)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$workspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$compiler=Join-Path $workspace $(if($IsWindows){'DevKit/Toolchains/Zig/zig.exe'}else{'DevKit/Toolchains/Zig/zig'})
if(!(Test-Path -LiteralPath $compiler -PathType Leaf)){
    $installed=Get-Command zig -ErrorAction SilentlyContinue
    if(!$installed){throw 'Zig is missing; initialize the workspace toolchain or add Zig to PATH.'}
    $compiler=$installed.Source
}
Push-Location $PSScriptRoot
try{& $compiler build @BuildArguments;$result=$LASTEXITCODE}finally{Pop-Location}
exit $result
