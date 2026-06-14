<div align="center">

# 🛡️ SOC-Triage-Collector

**A Production-Ready Windows DFIR Evidence Collection Framework**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server-blue.svg)]()
[![Status](https://img.shields.io/badge/Status-Production--Ready-success.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

---

## 📖 Overview

Humans invented SIEMs because staring at 40 tabs of logs while drinking cold coffee apparently counts as a career path. **SOC-Triage-Collector** is built for analysts who actually want to get things done.

This framework rapidly collects forensic artifacts, persistence mechanisms, and event logs from suspected compromised Windows endpoints. It operates purely on PowerShell, ensuring minimal impact, strict chain-of-custody, and zero modifications to the original artifacts.

> **Note:** This is strictly a defensive evidence collection framework similar to KAPE or Velociraptor's offline collector. It performs zero offensive actions, exfiltrates no data automatically, and does not crack credentials.

---

## ✨ Features

- **⚡ Zero Dependencies**: Runs entirely natively using PowerShell (5.1 or 7+).
- **🕵️‍♂️ Non-Destructive**: Collects evidence without modifying the system state or altering timestamps of the original artifacts.
- **📦 Automated Packaging**: Automatically hashes (`SHA256`) all collected files and compresses everything into a portable ZIP archive.
- **📊 Executive Reporting**: Generates a visually clean HTML report highlighting immediate critical findings (e.g., disabled Defender, unsigned kernel drivers, suspicious parent-child process chains).
- **⚙️ Highly Configurable**: Use the JSON configuration file to toggle over 20+ different forensic modules.

---

## 🛠️ Collection Modules

| Category | Modules & Artifacts Collected |
|---|---|
| **System** | OS Info, Uptime, Memory, Drives, Installed Software, BitLocker Status |
| **Event Logs** | Security, System, Application, PowerShell, Defender, Task Scheduler, Sysmon |
| **Processes** | Memory usage, Parent-child relationships, Path validation, Code Signing validation |
| **Network** | Active TCP/UDP Connections, DNS Cache, ARP, Routing Tables, Firewall Rules |
| **Persistence** | Run/RunOnce Keys, WMI Event Consumers, Scheduled Tasks, IFEO, Winlogon |
| **Artifacts** | Browser Metadata (History, Cookies), Prefetch (`.pf`), Recent Files, USB History (`USBSTOR`) |

---

## 🚀 Quick Start

### Prerequisites
- Windows 10, Windows 11, or Windows Server 2016+
- **Administrator Privileges** (Required for accessing deep event logs and raw registry hives)

### Execution

1. Transfer the `SOC-Triage-Collector` directory to the target machine via a secure medium (e.g., dedicated DFIR USB drive).
2. Open PowerShell as **Administrator**.
3. Navigate to the directory:
   ```powershell
   cd "D:\SOC-Triage-Collector"
   ```
4. Run the master script:
   ```powershell
   .\Start-Triage.ps1
   ```
5. Grab your coffee. The script will output a `.zip` archive alongside a `.sha256` hash file upon completion.

---

## ⚙️ Configuration

The framework is controlled via `config/collector-config.json`. You can selectively disable modules if you need a faster, targeted collection.

```json
{
  "Settings": {
    "OutputDirectory": "output",
    "CompressOutput": true,
    "GenerateHTMLReport": true,
    "InstallSysmonIfMissing": false
  },
  "Modules": {
    "CollectEventLogs": true,
    "CollectBrowserArtifacts": false
  }
}
```

---

## 📂 Output Structure

Once completed, the output folder is organized for rapid timeline ingestion:

```text
CASE-<HOSTNAME>-<TIMESTAMP>/
├── Browser/         # Metadata from Chrome, Edge, Firefox
├── EventLogs/       # Raw .EVTX and parsed CSV summaries
├── Misc/            # USB History, Prefetch, RDP, SMB
├── Network/         # Active connections, DNS cache
├── Persistence/     # Autoruns, Scheduled Tasks, WMI
├── Processes/       # Running processes, parent-child mappings
├── SystemInfo/      # OS details, Services, Drivers
└── Reports/         # Executive HTML Report
```

---

## ⚖️ Legal Disclaimer

This software is provided **"as is"** without warranty of any kind. It is intended strictly for authorized Incident Response and Security Operations tasks. The authors are not responsible for any misuse or damage caused by the use of this tool. Use in authorized environments only.
