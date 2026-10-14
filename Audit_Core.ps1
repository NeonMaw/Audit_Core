<#
.SYNOPSIS
    Audit_Core - High-Performance Hardware & System Topology Auditor
.DESCRIPTION
    Evaluates core system metrics for hardware optimization, compute infrastructure,
    and kernel tuning. Supports interactive console rendering, structured JSON output,
    and pipeline-friendly PSCustomObject export.
.PARAMETER AsJson
    Outputs the audit results as a formatted JSON document.
.PARAMETER PassThru
    Returns the audit telemetry as a PSCustomObject for downstream PowerShell pipelines.
.PARAMETER LogPath
    Appends the audit results to the specified log file path.
.EXAMPLE
    .\Audit_Core.ps1
.EXAMPLE
    .\Audit_Core.ps1 -AsJson
.EXAMPLE
    $audit = .\Audit_Core.ps1 -PassThru
#>
[CmdletBinding()]
param(
    [switch]$AsJson,
    [switch]$PassThru,
    [string]$LogPath
)

$ErrorActionPreference = 'SilentlyContinue'

# --- 1. Power Profile Evaluation ---
$powerName = "Unknown"
try {
    $powerCfgRaw = powercfg /getactivescheme 2>$null
    if ($powerCfgRaw -match '\((.+?)\)') {
        $powerName = $Matches[1].Trim()
    } else {
        $cimPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan -ErrorAction Stop | Where-Object { $_.IsActive }
        if ($cimPlan) { $powerName = $cimPlan.ElementName }
    }
} catch {
    $powerName = "Unavailable (Restricted Session)"
}

# --- 2. BIOS & Firmware Telemetry ---
$bios = Get-CimInstance -ClassName Win32_BIOS
$biosInfo = [ordered]@{
    Version      = $bios.SMBIOSBIOSVersion
    Manufacturer = $bios.Manufacturer
    ReleaseDate  = if ($bios.ReleaseDate) { (Get-Date $bios.ReleaseDate).ToString("yyyy-MM-dd") } else { "N/A" }
}

# --- 3. Processor Architecture & Topology ---
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$cpuInfo = [ordered]@{
    Name           = ($cpu.Name -replace '\s+', ' ').Trim()
    Cores          = [int]$cpu.NumberOfCores
    Threads        = [int]$cpu.NumberOfLogicalProcessors
    BaseClockMHz   = [int]$cpu.MaxClockSpeed
    CurrentClockMHz= [int]$cpu.CurrentClockSpeed
    Virtualization = [bool]$cpu.VirtualizationFirmwareEnabled
}

# --- 4. Physical Memory Topology ---
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRamGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRamGB  = [math]::Round($totalRamGB - $freeRamGB, 2)

$memInfo = [ordered]@{
    TotalGB = $totalRamGB
    UsedGB  = $usedRamGB
    FreeGB  = $freeRamGB
    UsagePct= [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)
}

# --- 5. GPU & Video Accelerators ---
$gpus = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic Render|Remote' } | ForEach-Object {
    [ordered]@{
        Name       = $_.Name
        DriverVer  = $_.DriverVersion
        VRAM_MB    = if ($_.AdapterRAM) { [math]::Round($_.AdapterRAM / 1MB) } else { 0 }
    }
}

# --- 6. Storage Topology ---
$disks = Get-PhysicalDisk | ForEach-Object {
    [ordered]@{
        Model        = $_.FriendlyName
        MediaType    = $_.MediaType
        BusType      = $_.BusType
        SizeGB       = [math]::Round($_.Size / 1GB, 1)
        Health       = $_.HealthStatus
        Status       = $_.OperationalStatus
    }
}

# --- Compile Telemetry Object ---
$AuditResult = [PSCustomObject]@{
    Timestamp   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    HostName    = $env:COMPUTERNAME
    AuditEngine = "Audit_Core v2.0 (Neon Maw LLC)"
    PowerPlan   = $powerName
    BIOS        = $biosInfo
    CPU         = $cpuInfo
    Memory      = $memInfo
    GPU         = $gpus
    Storage     = $disks
}

# --- Output Dispatcher ---
if ($AsJson) {
    $json = $AuditResult | ConvertTo-Json -Depth 5
    Write-Output $json
    if ($LogPath) { $json | Out-File -FilePath $LogPath -Append -Encoding utf8 }
} elseif ($PassThru) {
    if ($LogPath) { ($AuditResult | ConvertTo-Json -Depth 5) | Out-File -FilePath $LogPath -Append -Encoding utf8 }
    return $AuditResult
} else {
    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host "  AUDIT_CORE v2.0 - SYSTEM PERFORMANCE & HARDWARE TOPOLOGY AUDIT" -ForegroundColor Cyan
    Write-Host "  Neon Maw LLC // High-Efficiency Hardware Optimization & Hardening" -ForegroundColor DarkCyan
    Write-Host "==============================================================================" -ForegroundColor Cyan

    $pColor = if ($powerName -match 'High|Ultimate') { 'Green' } else { 'Yellow' }
    Write-Host "[+] Active Power Profile    : " -NoNewline
    Write-Host "$powerName" -ForegroundColor $pColor

    Write-Host "[+] BIOS / Firmware         : " -NoNewline
    Write-Host "$($biosInfo.Manufacturer) v$($biosInfo.Version) ($($biosInfo.ReleaseDate))" -ForegroundColor Yellow

    Write-Host "[+] Processor Architecture  : " -NoNewline
    Write-Host "$($cpuInfo.Name)" -ForegroundColor Yellow
    Write-Host "    Topology & Clocks       : $($cpuInfo.Cores) Physical Cores, $($cpuInfo.Threads) Threads @ $($cpuInfo.BaseClockMHz) MHz (VT: $($cpuInfo.Virtualization))" -ForegroundColor Gray

    Write-Host "[+] Physical RAM Footprint  : " -NoNewline
    Write-Host "$($memInfo.UsedGB) GB used / $($memInfo.TotalGB) GB total ($($memInfo.UsagePct)% load, $($memInfo.FreeGB) GB free)" -ForegroundColor Yellow

    if ($gpus) {
        Write-Host "[+] Graphics / GPU Islands  :" -ForegroundColor Yellow
        foreach ($g in $gpus) {
            Write-Host "    -> $($g.Name) (Driver: $($g.DriverVer))" -ForegroundColor Green
        }
    }

    if ($disks) {
        Write-Host "[+] Storage Subsystem       :" -ForegroundColor Yellow
        foreach ($d in $disks) {
            $hColor = if ($d.Health -eq 'Healthy' -or $d.Status -eq 'OK') { 'Green' } else { 'Red' }
            Write-Host "    -> $($d.Model) [$($d.MediaType) / $($d.BusType)] - $($d.SizeGB) GB ($($d.Status))" -ForegroundColor $hColor
        }
    }

    Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "[+] Audit 2.0 Complete. System Profile Evaluated Successfully." -ForegroundColor Green
    Write-Host "==============================================================================" -ForegroundColor Cyan

    if ($LogPath) {
        $logEntry = ($AuditResult | ConvertTo-Json -Depth 5)
        $logEntry | Out-File -FilePath $LogPath -Append -Encoding utf8
        Write-Host "[+] Telemetry appended to: $LogPath" -ForegroundColor DarkGray
    }
}
