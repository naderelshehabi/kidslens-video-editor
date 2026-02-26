param(
    [ValidateSet('Debug', 'Profile', 'Release')]
    [string]$Configuration = 'Debug'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$vs2022CMake = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
if (-not (Test-Path $vs2022CMake)) {
    throw "VS2022 CMake not found: $vs2022CMake"
}

$buildDir = Join-Path $repoRoot 'build/windows/x64-vs17'

Write-Host "[1/4] Validating CUDA compiler availability..."
$nvcc = Get-Command nvcc -ErrorAction SilentlyContinue
if (-not $nvcc) {
    Write-Warning 'nvcc not found in PATH. Build may fall back to Vulkan/CPU.'
}

Write-Host "[2/4] Updating Flutter Windows configuration (config-only)..."
flutter build windows --$($Configuration.ToLowerInvariant()) --config-only

Write-Host "[3/4] Configuring CMake with Visual Studio 2022 generator..."
& $vs2022CMake -S windows -B $buildDir -G 'Visual Studio 17 2022' -A x64 -DFLUTTER_TARGET_PLATFORM=windows-x64

Write-Host "[4/4] Building and installing app artifacts..."
& $vs2022CMake --build $buildDir --config $Configuration --target INSTALL

Write-Host "Build complete. Output: build/windows/x64-vs17/runner/$Configuration"
