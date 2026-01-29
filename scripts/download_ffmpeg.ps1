<#
.SYNOPSIS
    Downloads FFmpeg binaries for Windows (KidsLens Video Editor)

.DESCRIPTION
    Downloads FFmpeg LGPL shared builds from BtbN/FFmpeg-Builds GitHub releases
    and extracts them to native/ffmpeg/binaries/windows-{arch}/

.PARAMETER Architecture
    Target architecture: x64 (default) or arm64

.PARAMETER Force
    Force re-download even if binaries already exist

.PARAMETER OutputDir
    Custom output directory (default: native/ffmpeg/binaries)

.EXAMPLE
    .\download_ffmpeg.ps1
    Downloads FFmpeg for Windows x64

.EXAMPLE
    .\download_ffmpeg.ps1 -Architecture arm64
    Downloads FFmpeg for Windows ARM64

.EXAMPLE
    .\download_ffmpeg.ps1 -Force
    Force re-download FFmpeg binaries
#>

param(
    [ValidateSet("x64", "arm64")]
    [string]$Architecture = "x64",
    
    [switch]$Force,
    
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$GitHubRepo = "BtbN/FFmpeg-Builds"
$BuildType = "lgpl-shared"

# Determine script and project directories
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

if ([string]::IsNullOrEmpty($OutputDir)) {
    $OutputDir = Join-Path $ProjectDir "native\ffmpeg\binaries"
}

$PlatformDir = Join-Path $OutputDir "windows-$Architecture"
$TempDir = Join-Path $env:TEMP "ffmpeg_download_$(Get-Random)"

function Write-Header {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       FFmpeg Downloader for KidsLens Video Editor          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Platform: windows-$Architecture" -ForegroundColor White
    Write-Host "Output: $PlatformDir" -ForegroundColor White
    Write-Host ""
}

function Get-LatestReleaseUrl {
    Write-Host "Fetching latest FFmpeg release from GitHub..." -ForegroundColor Yellow
    
    $ApiUrl = "https://api.github.com/repos/$GitHubRepo/releases/latest"
    
    try {
        $Headers = @{
            "User-Agent" = "KidsLens-Video-Editor"
        }
        
        $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Get
        
        # Map architecture to build naming
        $ArchName = switch ($Architecture) {
            "x64" { "win64" }
            "arm64" { "winarm64" }
        }
        
        # Find LGPL shared build asset
        $Pattern = "ffmpeg-.*-$ArchName-$BuildType\.zip"
        
        foreach ($Asset in $Response.assets) {
            if ($Asset.name -match $Pattern) {
                Write-Host "Found: $($Asset.name)" -ForegroundColor Green
                return $Asset.browser_download_url
            }
        }
        
        throw "No matching FFmpeg build found for windows-$Architecture"
    }
    catch {
        Write-Host "Warning: Failed to fetch latest release, using fallback URL" -ForegroundColor Yellow
        
        $ArchName = switch ($Architecture) {
            "x64" { "win64" }
            "arm64" { "winarm64" }
        }
        
        return "https://github.com/$GitHubRepo/releases/download/latest/ffmpeg-master-latest-$ArchName-$BuildType.zip"
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$DestPath
    )
    
    Write-Host "Downloading from: $Url" -ForegroundColor White
    
    $WebClient = New-Object System.Net.WebClient
    $WebClient.Headers.Add("User-Agent", "KidsLens-Video-Editor")
    
    # Progress handler
    $LastPercent = 0
    $ProgressHandler = {
        param($sender, $e)
        if ($e.ProgressPercentage -gt $LastPercent) {
            $Script:LastPercent = $e.ProgressPercentage
            Write-Progress -Activity "Downloading FFmpeg" -Status "$($e.ProgressPercentage)% Complete" -PercentComplete $e.ProgressPercentage
        }
    }
    
    Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -Action $ProgressHandler | Out-Null
    
    try {
        $WebClient.DownloadFile($Url, $DestPath)
        Write-Progress -Activity "Downloading FFmpeg" -Completed
        
        $FileSize = (Get-Item $DestPath).Length / 1MB
        Write-Host "Downloaded: $([math]::Round($FileSize, 1)) MB" -ForegroundColor Green
    }
    finally {
        $WebClient.Dispose()
        Get-EventSubscriber | Unregister-Event
    }
}

function Extract-Archive {
    param(
        [string]$ArchivePath,
        [string]$DestDir
    )
    
    Write-Host "Extracting archive..." -ForegroundColor Yellow
    
    if (!(Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    
    Expand-Archive -Path $ArchivePath -DestinationPath $DestDir -Force
    
    Write-Host "Extracted successfully" -ForegroundColor Green
}

function Copy-Binaries {
    param(
        [string]$SourceDir,
        [string]$DestDir
    )
    
    Write-Host "Copying binaries to: $DestDir" -ForegroundColor Yellow
    
    if (!(Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    
    # Find the bin directory in extracted files
    $BinDir = Get-ChildItem -Path $SourceDir -Recurse -Directory | Where-Object { $_.Name -eq "bin" } | Select-Object -First 1
    
    if ($null -eq $BinDir) {
        throw "Could not find bin directory in extracted files"
    }
    
    # Copy executables
    $Binaries = @("ffmpeg.exe", "ffprobe.exe")
    foreach ($Binary in $Binaries) {
        $SourceFile = Join-Path $BinDir.FullName $Binary
        if (Test-Path $SourceFile) {
            Copy-Item -Path $SourceFile -Destination $DestDir -Force
            Write-Host "  Copied: $Binary" -ForegroundColor White
        }
        else {
            Write-Host "  Warning: $Binary not found" -ForegroundColor Yellow
        }
    }
    
    # Copy DLLs (for shared builds)
    $DllFiles = Get-ChildItem -Path $BinDir.FullName -Filter "*.dll"
    foreach ($Dll in $DllFiles) {
        Copy-Item -Path $Dll.FullName -Destination $DestDir -Force
    }
    
    if ($DllFiles.Count -gt 0) {
        Write-Host "  Copied: $($DllFiles.Count) DLL files" -ForegroundColor White
    }
}

function Verify-Installation {
    param(
        [string]$Dir
    )
    
    $FFmpegPath = Join-Path $Dir "ffmpeg.exe"
    
    if (Test-Path $FFmpegPath) {
        try {
            $Output = & $FFmpegPath -version 2>&1
            $VersionMatch = [regex]::Match($Output, "ffmpeg version (\S+)")
            if ($VersionMatch.Success) {
                Write-Host "  Verified: FFmpeg $($VersionMatch.Groups[1].Value)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  Warning: Could not verify installation" -ForegroundColor Yellow
        }
    }
}

function Main {
    Write-Header
    
    # Check if binaries already exist
    $FFmpegPath = Join-Path $PlatformDir "ffmpeg.exe"
    if ((Test-Path $FFmpegPath) -and !$Force) {
        Write-Host "FFmpeg binaries already exist at: $PlatformDir" -ForegroundColor Yellow
        Write-Host "Use -Force to re-download" -ForegroundColor Yellow
        Verify-Installation -Dir $PlatformDir
        return
    }
    
    # Create temp directory
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    try {
        # Get download URL
        $DownloadUrl = Get-LatestReleaseUrl
        
        # Download archive
        $ArchivePath = Join-Path $TempDir "ffmpeg.zip"
        Download-File -Url $DownloadUrl -DestPath $ArchivePath
        
        # Extract archive
        $ExtractDir = Join-Path $TempDir "extracted"
        Extract-Archive -ArchivePath $ArchivePath -DestDir $ExtractDir
        
        # Copy binaries to destination
        Copy-Binaries -SourceDir $ExtractDir -DestDir $PlatformDir
        
        Write-Host ""
        Write-Host "✓ FFmpeg binaries installed to: $PlatformDir" -ForegroundColor Green
        
        # Verify installation
        Verify-Installation -Dir $PlatformDir
    }
    finally {
        # Cleanup
        if (Test-Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Run main function
Main
