# Rahul Admin Tools – Windows 🪟

**All-in-One Windows System, Hardware, Network & Security Diagnostic Toolkit**

Rahul Admin Tools for Windows is a PowerShell-based diagnostic toolkit designed for IT administrators, system administrators, data-center engineers, and technical support teams.

It provides a centralized way to inspect Windows system health, hardware, storage, network connectivity, CPU, RAM, services, security configuration, event logs, and system information.

## 🚀 Features

* 🔍 Windows System Diagnostic
* 🧠 CPU Check
* 🧮 RAM Check
* 💾 Storage Check
* 💽 Disk Health Information
* 🌐 Network Check
* 📡 Network Adapter Information
* ⚙️ Windows Services Check
* 🔐 Security Information
* 🛡️ Windows Defender Information
* 🖥️ Hardware Inventory
* 📋 Windows Event Log Check
* 💻 Operating System Information
* 🔧 System Configuration
* 📊 Performance Information
* ⚠️ Hardware / System Error Detection
* 📄 Diagnostic Report Generation

## 🛠️ Requirements

* Windows 10 / Windows 11
* Windows Server
* PowerShell 5.1 or newer
* Administrator privileges recommended

## 📥 Download

Clone the repository:

```powershell
git clone https://github.com/rahulbhaicomtel-commits/Rahul_Admin_Tools_Windows.ps1.git
cd Rahul_Admin_Tools_Windows.ps1
```

## ▶️ Run

Open PowerShell as **Administrator**.

If required, allow local scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Run the tool:

```powershell
.\Rahul_Admin_Tools_Windows.ps1
```

If Windows blocks script execution for the current session:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Then run:

```powershell
.\Rahul_Admin_Tools_Windows.ps1
```

## 🔐 Administrator Privileges

Some hardware, security, service, event-log, and system-level checks require PowerShell to be opened with **Run as Administrator**.

## 📊 Diagnostic Reports

The toolkit can generate diagnostic information/reports that can be used for:

* Server troubleshooting
* Desktop troubleshooting
* Hardware verification
* Network troubleshooting
* System health checks
* IT support documentation
* Data-center maintenance

## ⚠️ Important

Available information can vary depending on:

* Windows version
* PowerShell version
* Hardware manufacturer
* Installed drivers
* Administrator permissions
* Available Windows management interfaces

## 📜 License

MIT License

## 👨‍💻 Author

**Rahul Sharma**

IT Administrator | Data Center & Network Specialist

GitHub:
https://github.com/rahulbhaicomtel-commits

---
