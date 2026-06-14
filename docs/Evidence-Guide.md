# Evidence Guide

This guide describes the artifacts collected by the SOC-Triage-Collector.

## Artifacts Collected

### System Info
- OS Details, Uptime, Timezone, Logged-on users
- Local Drives, CPU, RAM
- Installed Patches (`Get-HotFix`)
- Services (`Win32_Service`)
- Drivers (`Win32_SystemDriver`)
- BitLocker Status
- Installed Software

### Event Logs
The framework pulls key `.evtx` files and generates summary `.csv` files for the last 1000 events of each log:
- Security, System, Application
- PowerShell Operational
- Windows Defender
- Sysmon (if installed, or it will optionally download it)
- Task Scheduler, DNS, WMI Activity

### Processes
- Snapshots running processes using WMI
- Resolves file paths and checks code signing (Authenticode)
- Flags unsigned binaries or execution from Temp/AppData

### Network
- Active TCP/UDP connections (`netstat`, `Get-NetTCPConnection`)
- Routing tables, ARP tables
- DNS Cache
- Firewall rules and profiles

### Persistence Mechanisms
- Run/RunOnce Registry Keys
- Scheduled Tasks
- WMI Event Consumers
- IFEO (Image File Execution Options)
- Winlogon Shell/Userinit values
- Startup Folders (All Users + Local Profiles)

### Miscellaneous Forensics
- USBSTOR and MountedDevices keys for USB history
- Browser Metadata (Cookies, History, Downloads from Chrome, Edge, Firefox)
- Prefetch (`.pf`) files
- Recent `.lnk` files
- RDP Sessions
- SMB Connections and Shares

## Format
Most data is exported as `.csv` to allow easy ingestion into Excel, Timeline Explorer, or a SIEM. 
EVTX files are exported natively.
Files are hashed post-collection to ensure integrity.
