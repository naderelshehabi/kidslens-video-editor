<#
.SYNOPSIS
    Downloads ONNX Runtime binaries for Windows (KidsLens Video Editor)

.DESCRIPTION
    Downloads ONNX Runtime from official Microsoft GitHub releases
    and extracts them to native/onnxruntime/binaries/windows-{arch}/

.PARAMETER Version
    ONNX Runtime version (default: 1.20.1)

.PARAMETER Architecture
    Target architecture: x64 (default) or arm64

.PARAMETER Package
    ONNX Runtime package variant: gpu (default), directml, or cpu

.PARAMETER Force
    Force re-download even if binaries already exist

.PARAMETER OutputDir
    Custom output directory (default: native/onnxruntime/binaries)

.EXAMPLE
    .\download_onnxruntime.ps1
    Downloads ONNX Runtime 1.20.1 for Windows x64

.EXAMPLE
    .\download_onnxruntime.ps1 -Version 1.20.1 -Architecture arm64
    Downloads ONNX Runtime 1.20.1 for Windows ARM64

.EXAMPLE
    .\download_onnxruntime.ps1 -Force
    Force re-download ONNX Runtime binaries

.EXAMPLE
    .\download_onnxruntime.ps1 -Package directml
    Downloads ONNX Runtime DirectML package
#>

param(
    [string]$Version = "1.20.1",
    
    [ValidateSet("x64", "arm64")]
    [string]$Architecture = "x64",

    [ValidateSet("gpu", "directml", "cpu")]
    [string]$Package = "gpu",
    
    [switch]$Force,
    
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

# Determine script and project directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

if ([string]::IsNullOrEmpty($OutputDir)) {
    $OutputDir = Join-Path $ProjectDir "native\onnxruntime\binaries"
}

$TargetDir = Join-Path $OutputDir "windows-$Architecture"
$DllPath = Join-Path $TargetDir "onnxruntime.dll"

# Ensure target directory exists
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

if ($Package -eq "gpu") {
    if ($Architecture -ne "x64") {
        throw "GPU package is currently supported only for x64 in this script."
    }
}

# Check if already exists
if ((Test-Path $DllPath) -and -not $Force) {
    $sharedDll = Join-Path $TargetDir "onnxruntime_providers_shared.dll"
    $providerDll = switch ($Package) {
        "gpu" { Join-Path $TargetDir "onnxruntime_providers_cuda.dll" }
        "directml" { Join-Path $TargetDir "onnxruntime_providers_dml.dll" }
        default { $null }
    }

    $hasRequired = (Test-Path $sharedDll)
    if ($providerDll) {
        $hasRequired = $hasRequired -and (Test-Path $providerDll)
    }

    if ($hasRequired) {
        Write-Host "ONNX Runtime already exists at $TargetDir with required package files." -ForegroundColor Green
        Write-Host "Use -Force to re-download"
        exit 0
    }

    Write-Host "ONNX Runtime base files exist but package-specific DLLs are missing; continuing download..." -ForegroundColor Yellow
}

# Construct download URL
$ArchSuffix = if ($Architecture -eq "x64") { "x64" } else { "arm64" }
$ZipName = switch ($Package) {
    "gpu" { "onnxruntime-win-$ArchSuffix-gpu-$Version.zip" }
    "directml" { "onnxruntime-win-$ArchSuffix-directml-$Version.zip" }
    default { "onnxruntime-win-$ArchSuffix-$Version.zip" }
}
$DownloadUrl = "https://github.com/microsoft/onnxruntime/releases/download/v$Version/$ZipName"

Write-Host "Downloading ONNX Runtime $Version for Windows $Architecture ($Package package)..." -ForegroundColor Cyan
Write-Host "URL: $DownloadUrl"

$TempDir = Join-Path $env:TEMP ("onnxruntime_download_" + [Guid]::NewGuid().ToString('N'))
$ZipPath = Join-Path $TempDir $ZipName

# Create temp directory
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

try {
    # Download the zip file
    Write-Host "Downloading..." -ForegroundColor Yellow
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing
    $ProgressPreference = 'Continue'

    Write-Host "Download complete. Extracting..." -ForegroundColor Yellow

    # Extract to temp directory
    $ExtractDir = Join-Path $TempDir "extract"
    if (Test-Path $ExtractDir) {
        Remove-Item -Path $ExtractDir -Recurse -Force
    }
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

    # Find the extracted folder (should be onnxruntime-win-{arch}-{variant}-{version})
    $ExtractedFolder = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1

    if (-not $ExtractedFolder) {
        throw "Could not find extracted ONNX Runtime folder"
    }

    $LibDir = Join-Path $ExtractedFolder.FullName "lib"

    # Copy all ONNX Runtime DLLs to target directory
    $RuntimeDlls = Get-ChildItem -Path $LibDir -Filter "onnxruntime*.dll" -ErrorAction SilentlyContinue
    if (-not $RuntimeDlls) {
        throw "No onnxruntime*.dll files found in extracted package"
    }

    foreach ($Dll in $RuntimeDlls) {
        Copy-Item -Path $Dll.FullName -Destination $TargetDir -Force
        Write-Host "Copied $($Dll.Name)" -ForegroundColor Green
    }

    # Copy include headers if needed
    $IncludeDir = Join-Path $ExtractedFolder.FullName "include"
    $TargetIncludeDir = Join-Path $OutputDir "..\include"
    if ((Test-Path $IncludeDir) -and -not (Test-Path $TargetIncludeDir)) {
        Copy-Item -Path $IncludeDir -Destination $TargetIncludeDir -Recurse -Force
        Write-Host "Copied include headers" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "ONNX Runtime $Version ($Package) installed successfully to:" -ForegroundColor Green
    Write-Host "  $TargetDir" -ForegroundColor White

    # Verify DLL exists
    if (Test-Path $DllPath) {
        $FileInfo = Get-Item $DllPath
        Write-Host "  onnxruntime.dll: $([math]::Round($FileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
    }

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
