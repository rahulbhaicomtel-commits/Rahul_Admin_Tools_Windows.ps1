# ==============================================================
# Rahul Admin Tools - Windows
# Version 1.0
# Windows 10 / 11 / Windows Server
# System + Hardware + Application Health Diagnostics
# ==============================================================

$ErrorActionPreference = "SilentlyContinue"

# ---------------- COLORS ----------------
$Cyan   = "Cyan"
$Green  = "Green"
$Yellow = "Yellow"
$Red    = "Red"
$Magenta = "Magenta"
$White  = "White"
$Gray   = "Gray"

# ---------------- REPORT LOCATION ----------------
if ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $ReportDir = "$env:ProgramData\RahulAdminTools"
}
else {
    $ReportDir = "$HOME\RahulAdminReports"
}

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

$ReportFile = Join-Path $ReportDir ("Rahul_Admin_Report_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# ---------------- STATUS COUNTERS ----------------
$Global:PASS = 0
$Global:WARNING = 0
$Global:ERRORS = 0
$Global:FAIL = 0
$Global:CRITICAL = 0

function Reset-Status {
    $Global:PASS = 0
    $Global:WARNING = 0
    $Global:ERRORS = 0
    $Global:FAIL = 0
    $Global:CRITICAL = 0
}

function Write-Report {
    param([string]$Text)

    $Text | Out-File -FilePath $ReportFile -Append -Encoding UTF8
}

function Write-Line {
    param(
        [string]$Text = "",
        [string]$Color = "White"
    )

    Write-Host $Text -ForegroundColor $Color
    Write-Report $Text
}

function Status {
    param(
        [string]$Level,
        [string]$Message,
        [string]$Advice = ""
    )

    switch ($Level.ToUpper()) {
        "PASS" {
            $Global:PASS++
            $Color = $Green
            $Icon = "🟢"
        }
        "WARNING" {
            $Global:WARNING++
            $Color = $Yellow
            $Icon = "🟡"
        }
        "ERROR" {
            $Global:ERRORS++
            $Color = $Magenta
            $Icon = "🟠"
        }
        "FAIL" {
            $Global:FAIL++
            $Color = $Red
            $Icon = "🔴"
        }
        "CRITICAL" {
            $Global:CRITICAL++
            $Color = $Red
            $Icon = "🚨"
        }
        default {
            $Color = $White
            $Icon = "ℹ️"
        }
    }

    Write-Line "$Icon [$Level] $Message" $Color

    if ($Advice) {
        Write-Line "    Advice: $Advice" $Yellow
    }
}

function Section {
    param([string]$Title)

    Write-Line ""
    Write-Line "============================================================" $Cyan
    Write-Line " $Title" $Cyan
    Write-Line "============================================================" $Cyan
}

function Safe-Run {
    param(
        [scriptblock]$Code
    )

    try {
        & $Code
    }
    catch {
        return $null
    }
}

function Cmd-Exists {
    param([string]$Name)

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ==============================================================
# SYSTEM DIAGNOSTIC
# ==============================================================

function System-Diagnostic {

    Section "1. SYSTEM DIAGNOSTIC"

    $cs  = Get-CimInstance Win32_ComputerSystem
    $os  = Get-CimInstance Win32_OperatingSystem
    $bios = Get-CimInstance Win32_BIOS
    $board = Get-CimInstance Win32_BaseBoard

    Write-Line "Hostname       : $env:COMPUTERNAME"
    Write-Line "Manufacturer   : $($cs.Manufacturer)"
    Write-Line "Model          : $($cs.Model)"
    Write-Line "OS             : $($os.Caption)"
    Write-Line "Version        : $($os.Version)"
    Write-Line "Build          : $($os.BuildNumber)"
    Write-Line "Architecture   : $($os.OSArchitecture)"
    Write-Line "BIOS           : $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"
    Write-Line "BIOS Serial    : $($bios.SerialNumber)"
    Write-Line "Motherboard    : $($board.Manufacturer) $($board.Product)"
    Write-Line "RAM Total      : $([math]::Round($cs.TotalPhysicalMemory / 1GB,2)) GB"
    Write-Line "Boot Time      : $($os.LastBootUpTime)"
    Write-Line "Power State    : $($cs.PowerState)"

    $uptime = (Get-Date) - $os.LastBootUpTime

    Write-Line ("Uptime         : {0}d {1}h {2}m" -f `
        $uptime.Days,$uptime.Hours,$uptime.Minutes)

    Status "PASS" "System information collected." `
        "Review hardware, OS and BIOS information if troubleshooting."
}

# ==============================================================
# STORAGE CHECK
# ==============================================================

function Storage-Check {

    Section "2. STORAGE CHECK"

    $volumes = Get-Volume | Where-Object {
        $_.DriveLetter -and $_.Size -gt 0
    }

    foreach ($v in $volumes) {

        $freeGB = [math]::Round($v.SizeRemaining / 1GB,2)
        $sizeGB = [math]::Round($v.Size / 1GB,2)
        $used = [math]::Round((1 - ($v.SizeRemaining / $v.Size)) * 100,1)

        Write-Line "$($v.DriveLetter):  Size=$sizeGB GB  Free=$freeGB GB  Used=$used%  FS=$($v.FileSystem)"

        if ($used -ge 95) {
            Status "CRITICAL" "$($v.DriveLetter): drive usage $used%" `
                "Immediately free disk space."
        }
        elseif ($used -ge 90) {
            Status "FAIL" "$($v.DriveLetter): drive usage $used%" `
                "Remove unnecessary files or extend the volume."
        }
        elseif ($used -ge 80) {
            Status "WARNING" "$($v.DriveLetter): drive usage $used%" `
                "Plan cleanup before the volume reaches critical usage."
        }
        else {
            Status "PASS" "$($v.DriveLetter): storage usage normal."
        }
    }

    Write-Line ""
    Write-Line "Disk Partitions:" $Cyan

    Get-Disk | Format-Table Number,FriendlyName,BusType,OperationalStatus,HealthStatus,Size -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Write-Line ""
    Write-Line "Physical Disks:" $Cyan

    Get-PhysicalDisk | Format-Table FriendlyName,MediaType,BusType,HealthStatus,OperationalStatus,Size -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }
}

# ==============================================================
# NETWORK CHECK
# ==============================================================

function Network-Check {

    Section "3. NETWORK CHECK"

    $adapters = Get-NetAdapter |
        Where-Object {$_.Status -eq "Up"}

    if (-not $adapters) {
        Status "CRITICAL" "No active network adapter found." `
            "Check NIC, cable, switch port and driver."
    }
    else {
        foreach ($nic in $adapters) {
            Write-Line "Interface: $($nic.Name)"
            Write-Line "  Status : $($nic.Status)"
            Write-Line "  Speed  : $($nic.LinkSpeed)"
            Write-Line "  MAC    : $($nic.MacAddress)"

            Status "PASS" "$($nic.Name) network interface is UP."
        }
    }

    Write-Line ""
    Write-Line "IP Configuration:" $Cyan

    Get-NetIPConfiguration |
        Format-List InterfaceAlias,InterfaceIndex,IPv4Address,IPv4DefaultGateway,DNSServer |
        Out-String | ForEach-Object { Write-Line $_ }

    $configs = Get-NetIPConfiguration

    foreach ($cfg in $configs) {

        if ($cfg.IPv4DefaultGateway) {

            $gateway = $cfg.IPv4DefaultGateway.NextHop

            Write-Line "Testing Gateway $gateway ..."

            if (Test-Connection -ComputerName $gateway -Count 2 -Quiet) {
                Status "PASS" "Gateway $gateway reachable."
            }
            else {
                Status "FAIL" "Gateway $gateway unreachable." `
                    "Check IP configuration, VLAN, switch port and gateway."
            }
        }
    }

    Write-Line ""
    Write-Line "DNS Test:" $Cyan

    if (Resolve-DnsName google.com -ErrorAction SilentlyContinue) {
        Status "PASS" "DNS resolution working."
    }
    else {
        Status "WARNING" "DNS resolution failed." `
            "Check DNS server configuration."
    }

    Write-Line ""
    Write-Line "Network Adapter Statistics:" $Cyan

    Get-NetAdapterStatistics |
        Format-Table Name,ReceivedBytes,SentBytes,ReceivedPacketErrors,OutboundPacketErrors -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }
}

# ==============================================================
# CPU CHECK
# ==============================================================

function CPU-Check {

    Section "4. CPU CHECK"

    $cpu = Get-CimInstance Win32_Processor

    foreach ($c in $cpu) {

        Write-Line "CPU                : $($c.Name)"
        Write-Line "Manufacturer       : $($c.Manufacturer)"
        Write-Line "Physical Cores     : $($c.NumberOfCores)"
        Write-Line "Logical Processors : $($c.NumberOfLogicalProcessors)"
        Write-Line "Max Clock          : $($c.MaxClockSpeed) MHz"
        Write-Line "Current Load       : $($c.LoadPercentage)%"
        Write-Line ""

        $load = [int]$c.LoadPercentage

        if ($load -ge 95) {
            Status "CRITICAL" "CPU load $load%." `
                "Check runaway applications and processes immediately."
        }
        elseif ($load -ge 85) {
            Status "WARNING" "CPU load $load%." `
                "Check top CPU-consuming processes."
        }
        else {
            Status "PASS" "CPU load $load% is normal."
        }
    }

    Write-Line ""
    Write-Line "Top CPU Processes:" $Cyan

    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 10 Name,Id,CPU |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }
}

# ==============================================================
# RAM CHECK
# ==============================================================

function RAM-Check {

    Section "5. RAM CHECK"

    $os = Get-CimInstance Win32_OperatingSystem

    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB,2)
    $free  = [math]::Round($os.FreePhysicalMemory / 1MB,2)
    $used  = [math]::Round((($total-$free)/$total)*100,1)

    Write-Line "Total RAM : $total GB"
    Write-Line "Free RAM  : $free GB"
    Write-Line "Used RAM  : $used%"

    if ($used -ge 95) {
        Status "CRITICAL" "RAM usage $used%." `
            "Check memory-consuming processes and possible memory leak."
    }
    elseif ($used -ge 85) {
        Status "WARNING" "RAM usage $used%." `
            "Review top memory-consuming applications."
    }
    else {
        Status "PASS" "RAM usage $used% is normal."
    }

    Write-Line ""
    Write-Line "Physical DIMM Information:" $Cyan

    Get-CimInstance Win32_PhysicalMemory |
        Select-Object DeviceLocator,Manufacturer,PartNumber,
        @{N="CapacityGB";E={[math]::Round($_.Capacity/1GB,2)}},
        Speed,SerialNumber |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }
}

# ==============================================================
# DISK / SMART CHECK
# ==============================================================

function Disk-SMART-Check {

    Section "6. DISK / SMART CHECK"

    $physical = Get-PhysicalDisk

    if (-not $physical) {
        Status "ERROR" "Physical disk information unavailable." `
            "Run PowerShell as Administrator."
        return
    }

    foreach ($disk in $physical) {

        Write-Line "Disk          : $($disk.FriendlyName)"
        Write-Line "HealthStatus  : $($disk.HealthStatus)"
        Write-Line "Operational   : $($disk.OperationalStatus)"
        Write-Line "MediaType     : $($disk.MediaType)"
        Write-Line "BusType       : $($disk.BusType)"
        Write-Line "Size          : $([math]::Round($disk.Size/1GB,2)) GB"
        Write-Line ""

        if ($disk.HealthStatus -eq "Healthy") {
            Status "PASS" "$($disk.FriendlyName) health = Healthy."
        }
        elseif ($disk.HealthStatus) {
            Status "FAIL" "$($disk.FriendlyName) health = $($disk.HealthStatus)." `
                "Check disk SMART/vendor diagnostics and prepare backup."
        }
    }

    Write-Line ""
    Write-Line "SMART Prediction Status:" $Cyan

    try {

        $smart = Get-CimInstance `
            -Namespace root\wmi `
            -ClassName MSStorageDriver_FailurePredictStatus

        foreach ($s in $smart) {

            if ($s.PredictFailure -eq $true) {
                Status "CRITICAL" "SMART predicts disk failure." `
                    "Backup data immediately and replace the affected disk."
            }
            else {
                Status "PASS" "SMART failure prediction not detected."
            }
        }
    }
    catch {
        Status "WARNING" "SMART detailed data unavailable." `
            "Use OEM/NVMe vendor diagnostics for deeper disk health."
    }
}

# ==============================================================
# TEMPERATURE CHECK
# ==============================================================

function Temperature-Check {

    Section "7. TEMPERATURE / FAN CHECK"

    $thermal = Get-CimInstance `
        -Namespace root/wmi `
        -ClassName MSAcpi_ThermalZoneTemperature

    if ($thermal) {

        foreach ($t in $thermal) {

            $temp = [math]::Round(($t.CurrentTemperature / 10) - 273.15,1)

            Write-Line "Thermal Zone Temperature: $temp °C"

            if ($temp -ge 90) {
                Status "CRITICAL" "Temperature $temp °C." `
                    "Check cooling, fan, heatsink and airflow immediately."
            }
            elseif ($temp -ge 80) {
                Status "WARNING" "High temperature $temp °C." `
                    "Check cooling and system airflow."
            }
            else {
                Status "PASS" "Temperature $temp °C."
            }
        }
    }
    else {
        Status "WARNING" "Windows did not expose temperature sensor data." `
            "Use OEM hardware monitoring tools for CPU/NVMe/fan temperatures."
    }

    Write-Line ""
    Write-Line "Fan Information:" $Cyan

    $fans = Get-CimInstance `
        -Namespace root/cimv2 `
        -ClassName Win32_Fan

    if ($fans) {
        $fans | Format-Table Name,Status,DesiredSpeed,VariableSpeed -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }
    }
    else {
        Write-Line "Fan sensor data is not exposed by this system."
    }
}

# ==============================================================
# SERVICES CHECK
# ==============================================================

function Services-Check {

    Section "8. SERVICES CHECK"

    $important = @(
        "EventLog",
        "Dhcp",
        "Dnscache",
        "LanmanServer",
        "LanmanWorkstation",
        "Winmgmt",
        "BITS",
        "wuauserv",
        "MpsSvc",
        "WinDefend",
        "Spooler",
        "TermService"
    )

    foreach ($name in $important) {

        $svc = Get-Service -Name $name

        if ($svc) {

            Write-Line "$($svc.Name) : $($svc.Status)"

            if ($svc.Status -eq "Running") {
                Status "PASS" "$name service is running."
            }
            elseif ($svc.StartType -eq "Disabled") {
                Write-Line "    Disabled by configuration."
            }
            else {
                Status "WARNING" "$name service is not running." `
                    "Verify whether the service is required on this server."
            }
        }
    }

    Write-Line ""
    Write-Line "Failed Services:" $Cyan

    $failed = Get-Service |
        Where-Object {$_.Status -eq "Stopped" -and $_.StartType -eq "Automatic"}

    if ($failed) {

        $failed |
            Select-Object Name,DisplayName,Status,StartType |
            Format-Table -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }

        Status "WARNING" "Automatic services are stopped." `
            "Review service dependencies and Event Viewer."
    }
    else {
        Status "PASS" "No stopped automatic services detected."
    }
}

# ==============================================================
# SECURITY CHECK
# ==============================================================

function Security-Check {

    Section "9. SECURITY CHECK"

    Write-Line "Windows Firewall:" $Cyan

    $fw = Get-NetFirewallProfile

    foreach ($profile in $fw) {

        Write-Line "$($profile.Name) : Enabled=$($profile.Enabled)"

        if ($profile.Enabled) {
            Status "PASS" "$($profile.Name) Firewall enabled."
        }
        else {
            Status "WARNING" "$($profile.Name) Firewall disabled." `
                "Verify security policy before enabling/disabling."
        }
    }

    Write-Line ""
    Write-Line "Microsoft Defender:" $Cyan

    if (Cmd-Exists "Get-MpComputerStatus") {

        $def = Get-MpComputerStatus

        Write-Line "Antivirus Enabled : $($def.AntivirusEnabled)"
        Write-Line "Real-Time Monitor : $($def.RealTimeProtectionEnabled)"
        Write-Line "AM Service        : $($def.AMServiceEnabled)"

        if ($def.RealTimeProtectionEnabled) {
            Status "PASS" "Defender real-time protection enabled."
        }
        else {
            Status "WARNING" "Defender real-time protection disabled." `
                "Verify endpoint security policy."
        }
    }
    else {
        Write-Line "Microsoft Defender cmdlet unavailable."
    }

    Write-Line ""
    Write-Line "BitLocker:" $Cyan

    if (Cmd-Exists "Get-BitLockerVolume") {

        Get-BitLockerVolume |
            Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionMethod |
            Format-Table -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }
    }
    else {
        Write-Line "BitLocker information unavailable."
    }

    Write-Line ""
    Write-Line "Windows Security Services:" $Cyan

    Get-Service |
        Where-Object {$_.Name -match "WinDefend|SecurityHealth|MpsSvc"} |
        Format-Table Name,Status,StartType -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }
}

# ==============================================================
# WINDOWS / KERNEL CHECK
# ==============================================================

function Kernel-Health-Check {

    Section "10. WINDOWS / KERNEL HEALTH CHECK"

    $os = Get-CimInstance Win32_OperatingSystem

    Write-Line "Windows Version : $($os.Caption)"
    Write-Line "Version         : $($os.Version)"
    Write-Line "Build           : $($os.BuildNumber)"
    Write-Line "Architecture    : $($os.OSArchitecture)"
    Write-Line "Boot Time       : $($os.LastBootUpTime)"

    Write-Line ""
    Write-Line "Recent Critical System Events:" $Cyan

    $events = Get-WinEvent -FilterHashtable @{
        LogName = "System"
        Level = 1,2
        StartTime = (Get-Date).AddDays(-3)
    } -MaxEvents 30

    if ($events) {

        foreach ($e in $events) {

            Write-Line "$($e.TimeCreated) | ID=$($e.Id) | $($e.ProviderName)" $Red
        }

        Status "WARNING" "Critical/Error System events detected." `
            "Review Event Viewer System log for exact hardware/driver cause."
    }
    else {
        Status "PASS" "No recent critical/error System events detected."
    }

    Write-Line ""
    Write-Line "WHEA Hardware Errors:" $Cyan

    $whea = Get-WinEvent -FilterHashtable @{
        LogName = "System"
        ProviderName = "Microsoft-Windows-WHEA-Logger"
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 20

    if ($whea) {

        foreach ($e in $whea) {
            Write-Line "$($e.TimeCreated) | ID=$($e.Id) | WHEA error" $Red
        }

        Status "CRITICAL" "WHEA hardware errors found." `
            "Check CPU, RAM, PCIe, motherboard, PSU and hardware logs."
    }
    else {
        Status "PASS" "No WHEA errors detected in the last 7 days."
    }

    Write-Line ""
    Write-Line "Kernel-Power / BugCheck Events:" $Cyan

    $bug = Get-WinEvent -FilterHashtable @{
        LogName = "System"
        Id = 41,1001
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 20

    if ($bug) {

        foreach ($e in $bug) {
            Write-Line "$($e.TimeCreated) | ID=$($e.Id) | $($e.ProviderName)" $Yellow
        }

        Status "WARNING" "Unexpected shutdown / BugCheck events found." `
            "Check BSOD dumps, power, drivers and hardware."
    }
    else {
        Status "PASS" "No recent Kernel-Power/BugCheck events found."
    }

    Write-Line ""
    Write-Line "Secure Boot:" $Cyan

    if (Cmd-Exists "Confirm-SecureBootUEFI") {

        try {
            $secure = Confirm-SecureBootUEFI

            if ($secure) {
                Status "PASS" "Secure Boot enabled."
            }
            else {
                Status "WARNING" "Secure Boot disabled." `
                    "Verify whether this matches your security requirement."
            }
        }
        catch {
            Write-Line "Secure Boot state could not be queried."
        }
    }
}

# ==============================================================
# HARDWARE INVENTORY
# ==============================================================

function Hardware-Inventory {

    Section "17. HARDWARE INVENTORY"

    $cs = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $board = Get-CimInstance Win32_BaseBoard

    Write-Line "Manufacturer : $($cs.Manufacturer)"
    Write-Line "Model        : $($cs.Model)"
    Write-Line "Serial       : $($bios.SerialNumber)"
    Write-Line "BIOS         : $($bios.SMBIOSBIOSVersion)"
    Write-Line "BIOS Date    : $($bios.ReleaseDate)"
    Write-Line "Motherboard  : $($board.Manufacturer) $($board.Product)"
    Write-Line "Board Serial : $($board.SerialNumber)"

    Write-Line ""
    Write-Line "Video Hardware:" $Cyan

    Get-CimInstance Win32_VideoController |
        Select-Object Name,DriverVersion,VideoMemoryType,AdapterRAM |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Status "PASS" "Hardware inventory collected."
}

# ==============================================================
# CPU HARDWARE
# ==============================================================

function CPU-Hardware {

    Section "18. CPU HARDWARE"

    Get-CimInstance Win32_Processor |
        Select-Object Name,Manufacturer,
        NumberOfCores,NumberOfLogicalProcessors,
        MaxClockSpeed,CurrentClockSpeed,L2CacheSize,L3CacheSize |
        Format-List |
        Out-String | ForEach-Object { Write-Line $_ }

    Status "PASS" "CPU hardware information collected."
}

# ==============================================================
# RAM HARDWARE
# ==============================================================

function RAM-Hardware {

    Section "19. RAM / DIMM HARDWARE"

    $ram = Get-CimInstance Win32_PhysicalMemory

    foreach ($r in $ram) {

        Write-Line "Slot         : $($r.DeviceLocator)"
        Write-Line "Manufacturer : $($r.Manufacturer)"
        Write-Line "Part Number  : $($r.PartNumber)"
        Write-Line "Serial       : $($r.SerialNumber)"
        Write-Line "Capacity     : $([math]::Round($r.Capacity/1GB,2)) GB"
        Write-Line "Speed        : $($r.Speed) MHz"
        Write-Line "Configured   : $($r.ConfiguredClockSpeed) MHz"
        Write-Line ""
    }

    Status "PASS" "DIMM hardware information collected."
}

# ==============================================================
# DISK HARDWARE
# ==============================================================

function Disk-Hardware {

    Section "20. DISK HARDWARE"

    Get-CimInstance Win32_DiskDrive |
        Select-Object Model,Manufacturer,InterfaceType,
        MediaType,SerialNumber,
        @{N="SizeGB";E={[math]::Round($_.Size/1GB,2)}} |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Status "PASS" "Disk hardware inventory collected."
}

# ==============================================================
# NETWORK HARDWARE
# ==============================================================

function Network-Hardware {

    Section "21. NETWORK HARDWARE"

    Get-NetAdapter |
        Select-Object Name,InterfaceDescription,Status,
        MacAddress,LinkSpeed,DriverInformation |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Write-Line ""
    Write-Line "NIC Hardware:" $Cyan

    Get-CimInstance Win32_NetworkAdapter |
        Where-Object {$_.PhysicalAdapter -eq $true} |
        Select-Object Name,Manufacturer,MACAddress,
        Speed,AdapterType,NetEnabled |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Status "PASS" "Network hardware information collected."
}

# ==============================================================
# PCI / DEVICE HARDWARE
# ==============================================================

function PCI-Hardware {

    Section "22. PCI / DEVICE HARDWARE"

    $devices = Get-CimInstance Win32_PnPEntity

    $problem = $devices | Where-Object {
        $_.ConfigManagerErrorCode -and
        $_.ConfigManagerErrorCode -ne 0
    }

    if ($problem) {

        $problem |
            Select-Object Name,PNPClass,Status,ConfigManagerErrorCode |
            Format-Table -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }

        Status "FAIL" "Hardware devices with configuration errors detected." `
            "Check Device Manager and reinstall/update affected drivers."
    }
    else {
        Status "PASS" "No PnP hardware configuration errors detected."
    }

    Write-Line ""
    Write-Line "PCI/Device Count: $($devices.Count)"
}

# ==============================================================
# FAN / TEMPERATURE HARDWARE
# ==============================================================

function Fan-Temperature-Hardware {

    Section "23. FAN / TEMPERATURE HARDWARE"

    $fans = Get-CimInstance Win32_Fan

    if ($fans) {

        $fans |
            Format-Table Name,Status,DesiredSpeed,VariableSpeed -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }
    }
    else {
        Write-Line "Standard Windows WMI fan data unavailable."
    }

    $zones = Get-CimInstance -Namespace root/wmi `
        -ClassName MSAcpi_ThermalZoneTemperature

    if ($zones) {

        foreach ($z in $zones) {

            $temp = [math]::Round(($z.CurrentTemperature/10)-273.15,1)

            Write-Line "Temperature : $temp °C"

            if ($temp -ge 90) {
                Status "CRITICAL" "Thermal zone $temp °C." `
                    "Check cooling immediately."
            }
            elseif ($temp -ge 80) {
                Status "WARNING" "Thermal zone $temp °C." `
                    "Inspect cooling and airflow."
            }
            else {
                Status "PASS" "Thermal zone temperature $temp °C."
            }
        }
    }
    else {
        Write-Line "Temperature sensors not exposed through standard Windows WMI."
    }
}

# ==============================================================
# POWER / BATTERY
# ==============================================================

function Power-Battery {

    Section "24. POWER / BATTERY"

    $batteries = Get-CimInstance Win32_Battery

    if ($batteries) {

        foreach ($b in $batteries) {

            Write-Line "Battery : $($b.Name)"
            Write-Line "Status  : $($b.Status)"
            Write-Line "Charge  : $($b.EstimatedChargeRemaining)%"

            if ($b.EstimatedChargeRemaining -le 15) {
                Status "WARNING" "Battery charge $($b.EstimatedChargeRemaining)%." `
                    "Connect AC power."
            }
            else {
                Status "PASS" "Battery charge normal."
            }
        }
    }
    else {
        Write-Line "No battery detected. System may be desktop/server."
    }

    Write-Line ""
    Write-Line "Power Plan:" $Cyan

    powercfg /getactivescheme 2>$null |
        ForEach-Object { Write-Line $_ }
}

# ==============================================================
# COOLING / THERMAL
# ==============================================================

function Cooling-Thermal {

    Section "25. COOLING / THERMAL"

    Write-Line "Thermal Zones:" $Cyan

    $zones = Get-CimInstance `
        -Namespace root/wmi `
        -ClassName MSAcpi_ThermalZoneTemperature

    if ($zones) {

        foreach ($z in $zones) {

            $temp = [math]::Round(($z.CurrentTemperature/10)-273.15,1)

            Write-Line "Zone=$($z.InstanceName) Temperature=$temp °C"

            if ($temp -ge 90) {
                Status "CRITICAL" "High thermal temperature $temp °C." `
                    "Inspect fan, heatsink, thermal paste and airflow."
            }
            elseif ($temp -ge 80) {
                Status "WARNING" "Elevated temperature $temp °C." `
                    "Inspect system cooling."
            }
            else {
                Status "PASS" "Thermal reading $temp °C."
            }
        }
    }
    else {
        Status "WARNING" "Thermal sensors unavailable through Windows WMI." `
            "Use OEM monitoring software."
    }
}

# ==============================================================
# USB HARDWARE
# ==============================================================

function USB-Hardware {

    Section "26. USB HARDWARE"

    $usb = Get-CimInstance Win32_USBController

    if ($usb) {

        $usb |
            Select-Object Name,Manufacturer,Status,PNPDeviceID |
            Format-Table -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }

        Status "PASS" "USB controllers detected."
    }
    else {
        Status "WARNING" "USB controller information unavailable."
    }
}

# ==============================================================
# HARDWARE ERROR LOGS
# ==============================================================

function Hardware-Error-Logs {

    Section "27. HARDWARE ERROR LOGS"

    Write-Line "WHEA Errors:" $Cyan

    $whea = Get-WinEvent -FilterHashtable @{
        LogName = "System"
        ProviderName = "Microsoft-Windows-WHEA-Logger"
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 30

    if ($whea) {

        foreach ($e in $whea) {
            Write-Line "$($e.TimeCreated) | ID=$($e.Id)" $Red
        }

        Status "CRITICAL" "WHEA hardware errors detected." `
            "Investigate CPU/RAM/PCIe/motherboard/PSU."
    }
    else {
        Status "PASS" "No WHEA hardware errors found."
    }

    Write-Line ""
    Write-Line "Disk / NTFS Errors:" $Cyan

    $diskErrors = Get-WinEvent -FilterHashtable @{
        LogName = "System"
        Id = 7,51,55,57,98
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 30

    if ($diskErrors) {

        foreach ($e in $diskErrors) {
            Write-Line "$($e.TimeCreated) | ID=$($e.Id) | $($e.ProviderName)" $Red
        }

        Status "FAIL" "Disk/filesystem-related events detected." `
            "Check SMART, filesystem and storage controller."
    }
    else {
        Status "PASS" "No recent disk/filesystem error events found."
    }

    Write-Line ""
    Write-Line "Display Driver Errors:" $Cyan

    $display = Get-WinEvent -FilterHashtable @{
        LogName = "System"
        Id = 4101
        StartTime = (Get-Date).AddDays(-7)
    } -MaxEvents 20

    if ($display) {
        Status "WARNING" "Display driver recovery events detected." `
            "Check GPU driver and graphics hardware."
    }
    else {
        Status "PASS" "No recent display driver recovery events."
    }
}

# ==============================================================
# APPLICATION / PROCESS
# ==============================================================

function Application-Process-Check {

    Section "28. APPLICATION / PROCESS CHECK"

    Write-Line "Top CPU Processes:" $Cyan

    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 10 Name,Id,CPU |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Write-Line ""
    Write-Line "Top Memory Processes:" $Cyan

    Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 10 Name,Id,
        @{N="RAM_MB";E={[math]::Round($_.WorkingSet64/1MB,1)}} |
        Format-Table -AutoSize |
        Out-String | ForEach-Object { Write-Line $_ }

    Write-Line ""
    Write-Line "Zombie-like / Not Responding Processes:" $Cyan

    $notResponding = Get-Process |
        Where-Object {$_.Responding -eq $false}

    if ($notResponding) {

        $notResponding |
            Select-Object Name,Id,Responding |
            Format-Table -AutoSize |
            Out-String | ForEach-Object { Write-Line $_ }

        Status "WARNING" "Non-responding processes detected." `
            "Check application logs and resource usage."
    }
    else {
        Status "PASS" "No non-responding processes detected."
    }

    Write-Line ""
    Write-Line "Recent Application Errors:" $Cyan

    $appErrors = Get-WinEvent -FilterHashtable @{
        LogName = "Application"
        Level = 2
        StartTime = (Get-Date).AddDays(-3)
    } -MaxEvents 20

    if ($appErrors) {

        foreach ($e in $appErrors) {
            Write-Line "$($e.TimeCreated) | ID=$($e.Id) | $($e.ProviderName)" $Yellow
        }

        Status "WARNING" "Recent Application errors detected." `
            "Review application Event Viewer details."
    }
    else {
        Status "PASS" "No recent Application error events detected."
    }
}

# ==============================================================
# FULL HARDWARE CHECK
# ==============================================================

function Full-Hardware-Check {

    Section "29. FULL HARDWARE CHECK"

    Hardware-Inventory
    CPU-Hardware
    RAM-Hardware
    Disk-Hardware
    Network-Hardware
    PCI-Hardware
    Fan-Temperature-Hardware
    Power-Battery
    Cooling-Thermal
    USB-Hardware
    Hardware-Error-Logs
}

# ==============================================================
# FULL SYSTEM + HARDWARE
# ==============================================================

function Full-System-Health {

    Section "30. FULL SYSTEM + HARDWARE HEALTH CHECK"

    System-Diagnostic
    Storage-Check
    Network-Check
    CPU-Check
    RAM-Check
    Disk-SMART-Check
    Temperature-Check
    Services-Check
    Security-Check
    Kernel-Health-Check
    Full-Hardware-Check
    Application-Process-Check
}

# ==============================================================
# SUMMARY
# ==============================================================

function Health-Summary {

    Section "OVERALL HEALTH STATUS"

    Write-Line "🟢 PASS     : $Global:PASS" $Green
    Write-Line "🟡 WARNING  : $Global:WARNING" $Yellow
    Write-Line "🟠 ERROR    : $Global:ERRORS" $Magenta
    Write-Line "🔴 FAIL     : $Global:FAIL" $Red
    Write-Line "🚨 CRITICAL : $Global:CRITICAL" $Red

    if ($Global:CRITICAL -gt 0) {

        Write-Line ""
        Write-Line "OVERALL STATUS : 🚨 CRITICAL" $Red
        Write-Line "Recommended Action: Immediate investigation required." $Yellow

    }
    elseif ($Global:FAIL -gt 0) {

        Write-Line ""
        Write-Line "OVERALL STATUS : 🔴 FAIL" $Red
        Write-Line "Recommended Action: Fix failed hardware/system checks."

    }
    elseif ($Global:ERRORS -gt 0) {

        Write-Line ""
        Write-Line "OVERALL STATUS : 🟠 ERROR" $Magenta
        Write-Line "Recommended Action: Investigate reported errors."

    }
    elseif ($Global:WARNING -gt 0) {

        Write-Line ""
        Write-Line "OVERALL STATUS : 🟡 WARNING" $Yellow
        Write-Line "Recommended Action: Review warnings and plan corrective action."

    }
    else {

        Write-Line ""
        Write-Line "OVERALL STATUS : 🟢 PASS" $Green
        Write-Line "Recommended Action: No major issue detected by this check."
    }

    Write-Line ""
    Write-Line "Report File:"
    Write-Line $ReportFile $Cyan
}

# ==============================================================
# RUN CHECK
# ==============================================================

function Run-Check {
    param([int]$Number)

    Reset-Status

    $Global:ReportFile = Join-Path $ReportDir `
        ("Rahul_Admin_Report_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

    $script:ReportFile = $Global:ReportFile

    Write-Line ""
    Write-Line "Rahul Admin Tools - Windows" $Cyan
    Write-Line "Started: $(Get-Date)" $Gray
    Write-Line "Computer: $env:COMPUTERNAME" $Gray

    switch ($Number) {

        1  { System-Diagnostic }
        2  { Storage-Check }
        3  { Network-Check }
        4  { CPU-Check }
        5  { RAM-Check }
        6  { Disk-SMART-Check }
        7  { Temperature-Check }
        8  { Services-Check }
        9  { Security-Check }
        10 { Kernel-Health-Check }

        17 { Hardware-Inventory }
        18 { CPU-Hardware }
        19 { RAM-Hardware }
        20 { Disk-Hardware }
        21 { Network-Hardware }
        22 { PCI-Hardware }
        23 { Fan-Temperature-Hardware }
        24 { Power-Battery }
        25 { Cooling-Thermal }
        26 { USB-Hardware }
        27 { Hardware-Error-Logs }
        28 { Application-Process-Check }
        29 { Full-Hardware-Check }

        30 { Full-System-Health }

        default {
            Write-Line "Invalid option." $Red
            return
        }
    }

    Health-Summary
}

# ==============================================================
# VIEW REPORT
# ==============================================================

function View-Latest-Report {

    Section "31. LATEST REPORT"

    $latest = Get-ChildItem $ReportDir -Filter "*.txt" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latest) {

        Write-Line "Latest Report: $($latest.FullName)" $Cyan
        Write-Line ""

        Get-Content $latest.FullName |
            ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Line "No report found." $Yellow
    }
}

# ==============================================================
# COPY REPORT
# ==============================================================

function Copy-Latest-Report {

    Section "32. COPY LATEST REPORT"

    $latest = Get-ChildItem $ReportDir -Filter "*.txt" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latest) {

        try {

            $content = Get-Content $latest.FullName -Raw

            Set-Clipboard -Value $content

            Status "PASS" "Latest report copied to Windows clipboard." `
                "Paste it into Notepad, email, Teams or your ticketing system."
        }
        catch {

            Status "ERROR" "Clipboard operation failed." `
                "Open the report manually from the report directory."
        }
    }
    else {
        Status "ERROR" "No report available to copy."
    }
}

# ==============================================================
# MENU
# ==============================================================

function Show-Menu {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "          RAHUL ADMIN TOOLS - WINDOWS" -ForegroundColor Cyan
    Write-Host "     System + Hardware + Application Health Monitor" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host " 1. 🔍 System Diagnostic"
    Write-Host " 2. 💾 Storage Check"
    Write-Host " 3. 🌐 Network Check"
    Write-Host " 4. 🧠 CPU Check"
    Write-Host " 5. 🧮 RAM Check"
    Write-Host " 6. 💽 Disk / SMART Check"
    Write-Host " 7. 🌡️ Temperature / Fan Check"
    Write-Host " 8. ⚙️ Services Check"
    Write-Host " 9. 🔐 Security Check"
    Write-Host "10. 🪟 Windows / Kernel Check"
    Write-Host ""
    Write-Host "17. 🖥️ Hardware Inventory"
    Write-Host "18. 🧠 CPU Hardware"
    Write-Host "19. 🧮 RAM / DIMM Hardware"
    Write-Host "20. 💽 Disk Hardware"
    Write-Host "21. 🌐 Network Hardware"
    Write-Host "22. 🔌 PCI / Device Hardware"
    Write-Host "23. 🌡️ Fan / Temperature Hardware"
    Write-Host "24. 🔋 Power / Battery"
    Write-Host "25. ❄️ Cooling / Thermal"
    Write-Host "26. 🔌 USB Hardware"
    Write-Host "27. ⚠️ Hardware Error Logs"
    Write-Host "28. ⚙️ Application / Process Check"
    Write-Host ""
    Write-Host "29. 🧰 Full Hardware Check"
    Write-Host "30. 🚀 FULL SYSTEM + HARDWARE HEALTH CHECK"
    Write-Host ""
    Write-Host "31. 📋 View Latest Report"
    Write-Host "32. 📋 Copy Latest Report"
    Write-Host ""
    Write-Host " 0. ❌ Exit"
    Write-Host ""

    Write-Host "------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "Report Location: $ReportDir" -ForegroundColor Gray
    Write-Host "------------------------------------------------------------" -ForegroundColor Gray
}

# ==============================================================
# MAIN LOOP
# ==============================================================

while ($true) {

    Show-Menu

    $choice = Read-Host "Enter option number"

    if ($choice -eq "0") {
        Write-Host ""
        Write-Host "Rahul Admin Tools closed." -ForegroundColor Cyan
        break
    }

    if ($choice -eq "31") {
        Clear-Host
        View-Latest-Report
    }
    elseif ($choice -eq "32") {
        Clear-Host
        Copy-Latest-Report
    }
    elseif ($choice -match "^(1|2|3|4|5|6|7|8|9|10|17|18|19|20|21|22|23|24|25|26|27|28|29|30)$") {

        Clear-Host
        Run-Check ([int]$choice)
    }
    else {

        Write-Host ""
        Write-Host "Invalid option. Please enter a valid menu number." -ForegroundColor Red
    }

    Write-Host ""
    Read-Host "Press ENTER to return to menu"
}

