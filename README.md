# 🪟 Rahul Admin Tools – Windows PowerShell

**A practical Windows system administration, diagnostics, troubleshooting, and health-check toolkit built with PowerShell.**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell\&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server-0078D4?logo=windows\&logoColor=white)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Rahul_Admin_Tools-black?logo=github)](https://github.com/rahulbhaicomtel-commits)

---

## 📌 Overview

**Rahul Admin Tools – Windows** is a PowerShell-based diagnostic and system administration toolkit designed to help IT administrators, system support engineers, desktop support teams, and Windows administrators quickly collect important system information and perform common health checks.

The goal is simple:

> **One PowerShell script to quickly understand what is happening on a Windows machine.**

It can be useful for:

* 🖥️ Windows system troubleshooting
* 💻 Hardware information collection
* 🧠 CPU and RAM diagnostics
* 💾 Disk and storage checks
* 🌐 Network troubleshooting
* 🔐 Security and system checks
* ⚙️ Windows configuration verification
* 📊 System health analysis
* 🛠️ IT support and server troubleshooting
* 📝 Quick diagnostic reporting

---

# ✨ Features

## 🖥️ System Information

Collect important Windows system details including:

* Computer name
* Windows edition
* Windows version
* OS build
* System architecture
* Manufacturer
* Model
* System information
* Uptime
* Boot information
* Power/system status

---

## 🧠 CPU Diagnostics

Check CPU-related information such as:

* CPU manufacturer
* CPU model
* Processor name
* Number of cores
* Logical processors
* CPU usage
* Processor information

Useful for identifying:

* High CPU utilization
* CPU configuration
* Hardware details
* Performance-related issues

---

## 🧮 RAM / Memory Diagnostics

Collect memory information including:

* Total physical RAM
* Available memory
* Used memory
* Memory utilization
* DIMM information where available
* Memory manufacturer
* Part number
* Serial number
* Memory capacity
* Memory speed

Useful for troubleshooting:

* High RAM usage
* Low available memory
* Memory configuration
* Hardware upgrade planning

---

## 💾 Disk & Storage Diagnostics

Check connected storage devices and collect information such as:

* Disk model
* Disk size
* Disk type
* Disk status
* Drive letters
* Free space
* Used space
* Storage utilization
* Partition information
* SSD/HDD information where exposed by Windows

Helps identify:

* Low disk space
* Disk configuration problems
* Storage capacity issues
* Drive availability

---

## 🌐 Network Diagnostics

Perform basic network troubleshooting and collect:

* Network adapters
* Adapter name
* Interface status
* MAC address
* IPv4 address
* IPv6 address
* Default gateway
* DNS configuration
* DHCP information
* Network connectivity
* Link information where available

Useful for troubleshooting:

* No network connectivity
* Incorrect IP configuration
* Gateway issues
* DNS problems
* Adapter problems

---

## 🔌 Connectivity Testing

The toolkit can be used to perform common connectivity checks such as:

```powershell
Test-Connection
```

and other Windows networking diagnostics.

Typical troubleshooting flow:

```text
Local Adapter
      ↓
IP Configuration
      ↓
Default Gateway
      ↓
DNS
      ↓
Remote Host
      ↓
Application/Port
```

---

## 🔐 Security & Windows Health Checks

The toolkit can collect useful security and Windows health information, including available Windows security configuration details.

It can help administrators investigate:

* Windows Defender status
* Firewall status
* Security configuration
* System protection information
* Important Windows services
* Administrative configuration

> **Note:** Security information depends on Windows edition, PowerShell version, permissions, and available system components.

---

## ⚙️ Windows Services

Check important Windows services and their current state.

Example information:

```text
Service Name
Display Name
Status
Start Type
```

This can help identify services that are:

* Running
* Stopped
* Disabled
* Not responding
* Unexpectedly unavailable

---

## 🔧 System Troubleshooting

The tool is designed to make first-level troubleshooting easier by collecting multiple diagnostic categories from one script.

Instead of manually running many commands such as:

```powershell
systeminfo
ipconfig /all
Get-ComputerInfo
Get-NetAdapter
Get-Volume
Get-Service
Get-CimInstance
```

you can use the administration toolkit as a centralized diagnostic starting point.

---

# 🚀 Getting Started

## Requirements

Recommended environment:

* Windows 10
* Windows 11
* Windows Server
* PowerShell 5.1+
* Administrator privileges recommended

Some diagnostic information may require elevated PowerShell permissions.

---

# 📥 Installation

Clone the repository:

```powershell
git clone https://github.com/rahulbhaicomtel-commits/Rahul_Admin_Tools_Windows.git
```

Move into the project directory:

```powershell
cd Rahul_Admin_Tools_Windows
```

Or download the PowerShell script directly from GitHub.

---

# ▶️ Running the Tool

Open **PowerShell as Administrator**.

If script execution is restricted, check the current policy:

```powershell
Get-ExecutionPolicy
```

For the current PowerShell session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Run the script:

```powershell
.\Rahul_Admin_Tools_Windows.ps1
```

---

# 🛡️ Running as Administrator

For complete hardware, network, service, and system information, it is recommended to run PowerShell with **Run as Administrator**.

Example:

```powershell
Start-Process powershell -Verb RunAs
```

Then run:

```powershell
.\Rahul_Admin_Tools_Windows.ps1
```

---

# 📊 Example Diagnostic Workflow

A typical support workflow can be:

```text
1. Run Rahul Admin Tools
        ↓
2. Check System Information
        ↓
3. Check CPU / RAM
        ↓
4. Check Disk Space
        ↓
5. Check Network Adapter
        ↓
6. Verify IP / Gateway / DNS
        ↓
7. Check Windows Services
        ↓
8. Review Security Status
        ↓
9. Identify warnings
        ↓
10. Perform required troubleshooting
```

---

# 🖥️ Example Output

Example:

```text
========================================================
          RAHUL ADMIN TOOLS - WINDOWS
========================================================

[ SYSTEM INFORMATION ]

Computer Name : hosname
OS            : Microsoft Windows
Architecture  : 64-bit
Manufacturer  : System Manufacturer
Model         : System Model

[ CPU ]

Processor     : Intel Processor
Cores         : 8
Logical CPU   : 16
Usage         : 18%

[ MEMORY ]

Total RAM     : 32 GB
Available     : 21 GB
Usage         : 34%

[ NETWORK ]

Adapter       : Ethernet
Status        : Up
IPv4          : 192.168.x.x
Gateway       : 192.168.x.x
DNS           : Configured

[ STORAGE ]

Drive         : C:
Capacity      : 476 GB
Free Space    : 212 GB
Status        : Healthy

[ SERVICES ]

Windows Update : Running
Windows Defender: Running

========================================================
                 SYSTEM CHECK COMPLETE
========================================================
```

> Output values above are examples only.

---

# 🎯 Use Cases

Rahul Admin Tools can be useful for:

### 👨‍💻 IT Support

Quickly collect system information before troubleshooting a user machine.

### 🖥️ System Administration

Check Windows configuration, hardware, storage, services, and networking.

### 🏢 Enterprise IT

Perform basic diagnostic checks across Windows endpoints and servers.

### 🌐 Network Troubleshooting

Check adapters, IP configuration, gateway, DNS, and connectivity.

### 🛠️ Desktop Support

Reduce the number of manual commands required during first-level troubleshooting.

### 📋 Incident Investigation

Collect technical information before escalating an issue to the next support level.

---

# 🔍 Why This Tool?

Windows troubleshooting often requires running many different commands.

For example:

```powershell
systeminfo
```

```powershell
ipconfig /all
```

```powershell
Get-ComputerInfo
```

```powershell
Get-NetAdapter
```

```powershell
Get-NetIPConfiguration
```

```powershell
Get-Volume
```

```powershell
Get-Service
```

Rahul Admin Tools brings many of these diagnostic checks together into a single PowerShell-based toolkit.

---

# 🧰 Technology

Built using:

* PowerShell
* Windows Management Instrumentation / CIM
* Windows networking commands
* Windows system information APIs
* Windows service management
* PowerShell diagnostic commands

---

# 📁 Project Structure

```text
Rahul_Admin_Tools_Windows/
│
├── Rahul_Admin_Tools_Windows.ps1
├── README.md
└── LICENSE
```

---

# 🔐 Permissions & Security

This tool is intended for legitimate system administration and troubleshooting.

Some checks may require administrative privileges.

The script should be reviewed before deployment in a production environment.

Always test administrative scripts in a controlled environment before using them across large numbers of systems.

---

# ⚠️ Limitations

Hardware and system information exposed by PowerShell/CIM can vary depending on:

* Windows version
* Windows Server version
* Hardware manufacturer
* BIOS/UEFI
* Device drivers
* PowerShell version
* Administrative permissions
* Available WMI/CIM providers

Therefore, some fields may not be available on every system.

---

# 🐛 Troubleshooting

## PowerShell says scripts are disabled

Check:

```powershell
Get-ExecutionPolicy -List
```

For a temporary current-session workaround:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run:

```powershell
.\Rahul_Admin_Tools_Windows.ps1
```

---

## Access denied

Run PowerShell as Administrator.

---

## Hardware information is missing

Some hardware information depends on what the BIOS, firmware, drivers, and Windows CIM/WMI providers expose.

---

## Network adapter information is incomplete

Check:

```powershell
Get-NetAdapter
```

and:

```powershell
Get-NetIPConfiguration
```

---

# 🗺️ Roadmap

Future versions may include:

* [ ] HTML diagnostic reports
* [ ] CSV export
* [ ] JSON export
* [ ] Automatic health scoring
* [ ] PASS / WARNING / ERROR / CRITICAL status
* [ ] Advanced disk health checks
* [ ] SMART information
* [ ] Event Log analysis
* [ ] Windows Update diagnostics
* [ ] Network port testing
* [ ] DNS diagnostics
* [ ] Service health recommendations
* [ ] Interactive menu
* [ ] Remote computer diagnostics
* [ ] Multi-computer support
* [ ] Centralized reporting
* [ ] Enterprise-friendly logging
* [ ] Web-based dashboard

---

# 🤝 Contributing

Contributions, suggestions, bug reports, and feature requests are welcome.

If you find an issue:

1. Open an **Issue**
2. Describe the problem
3. Include the Windows version
4. Include the PowerShell version
5. Provide relevant error messages
6. Explain how to reproduce the issue

Pull requests are welcome for improvements and new diagnostic capabilities.

---

# ⭐ Support the Project

If you find **Rahul Admin Tools – Windows** useful:

⭐ Star the repository
🍴 Fork the project
🐛 Report issues
💡 Suggest improvements
🔧 Contribute new features

Your feedback helps improve the project.

---

# 📜 License

This project is licensed under the **MIT License**.

See the [LICENSE](LICENSE) file for details.

---

# 👨‍💻 Author

## Rahul Sharma

**IT Administrator | System Support Engineer | Data Center & Network Specialist**

Interested in:

* Windows Administration
* Linux Administration
* Data Center Operations
* Server Administration
* Network Troubleshooting
* PowerShell Automation
* System Monitoring
* Infrastructure Automation

---

# 🔗 Project

**Rahul Admin Tools – Windows**

GitHub:

https://github.com/rahulbhaicomtel-commits/Rahul_Admin_Tools_Windows

---

## ⭐ If this project helped you, consider giving it a Star!

**Built with PowerShell for practical IT administration and troubleshooting.**

> **Rahul Admin Tools — Diagnose faster. Troubleshoot smarter. Automate better.**
