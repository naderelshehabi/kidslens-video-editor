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
#>

param(
    [string]$Version = "1.20.1",
    
    [ValidateSet("x64", "arm64")]
    [string]$Architecture = "x64",
    
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

# Check if already exists
if ((Test-Path $DllPath) -and -not $Force) {
    Write-Host "ONNX Runtime already exists at $DllPath" -ForegroundColor Green
    Write-Host "Use -Force to re-download"
    exit 0
}

# Create target directory
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# Construct download URL
# Format: https://github.com/microsoft/onnxruntime/releases/download/v{version}/onnxruntime-win-{arch}-{version}.zip
$ArchSuffix = if ($Architecture -eq "x64") { "x64" } else { "arm64" }
$ZipName = "onnxruntime-win-$ArchSuffix-$Version.zip"
$DownloadUrl = "https://github.com/microsoft/onnxruntime/releases/download/v$Version/$ZipName"

Write-Host "Downloading ONNX Runtime $Version for Windows $Architecture..." -ForegroundColor Cyan
Write-Host "URL: $DownloadUrl"

$TempDir = Join-Path $env:TEMP "onnxruntime_download"
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
    
    # Find the extracted folder (should be onnxruntime-win-{arch}-{version})
    $ExtractedFolder = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1
    
    if (-not $ExtractedFolder) {
        throw "Could not find extracted ONNX Runtime folder"
    }
    
    $LibDir = Join-Path $ExtractedFolder.FullName "lib"
    
    # Copy DLLs to target directory
    $FilesToCopy = @(
        "onnxruntime.dll",
        "onnxruntime_providers_shared.dll"
    )
    
    foreach ($File in $FilesToCopy) {
        $SourcePath = Join-Path $LibDir $File
        if (Test-Path $SourcePath) {
            Copy-Item -Path $SourcePath -Destination $TargetDir -Force
            Write-Host "Copied $File" -ForegroundColor Green
        }
    }
    
    # Also copy any additional provider DLLs if present
    $ProviderDlls = Get-ChildItem -Path $LibDir -Filter "onnxruntime_providers_*.dll" -ErrorAction SilentlyContinue
    foreach ($Dll in $ProviderDlls) {
        if ($Dll.Name -ne "onnxruntime_providers_shared.dll") {
            Copy-Item -Path $Dll.FullName -Destination $TargetDir -Force
            Write-Host "Copied $($Dll.Name)" -ForegroundColor Green
        }
    }
    
    # Copy include headers if needed
    $IncludeDir = Join-Path $ExtractedFolder.FullName "include"
    $TargetIncludeDir = Join-Path $OutputDir "..\include"
    if ((Test-Path $IncludeDir) -and -not (Test-Path $TargetIncludeDir)) {
        Copy-Item -Path $IncludeDir -Destination $TargetIncludeDir -Recurse -Force
        Write-Host "Copied include headers" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "ONNX Runtime $Version installed successfully to:" -ForegroundColor Green
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
