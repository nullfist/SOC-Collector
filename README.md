# SOC-Triage-Collector

A production-ready incident response and SOC evidence collection framework designed for Windows endpoints.

## Purpose

The objective of this toolkit is to rapidly collect forensic artifacts and logs from a suspected compromised Windows machine for triage and analysis. 
This is **NOT** malware or offensive tooling. It is a defensive evidence collection framework similar to KAPE and Velociraptor collection modules.

## Features

- Runs entirely using PowerShell.
- Requires Administrator privileges.
- Works on Windows 10 and Windows 11.
- Supports PowerShell 5.1 and PowerShell 7.
- Collects evidence without modifying original artifacts.
- Minimizes system impact.
- Timestamps all outputs.
- Maintains chain-of-custody principles (files are hashed).
- Stores all outputs in organized folders.
- Compresses collected artifacts automatically into a ZIP.
- Generates an analyst-friendly HTML report.

## Folder Structure

```
SOC-Triage-Collector/
│
├── Start-Triage.ps1
├── README.md
├── config/
│   └── collector-config.json
│
├── modules/
│   ├── Collect-SystemInfo.ps1
│   ├── Collect-EventLogs.ps1
│   └── ... (other collection modules)
│
├── output/   (Generated during run)
├── logs/     (Generated during run)
├── reports/  (Generated during run)
└── docs/
    ├── Evidence-Guide.md
    └── Analyst-Usage.md
```

## Usage

1. Open PowerShell as **Administrator**.
2. Navigate to the `SOC-Triage-Collector` directory.
3. Run the master script:
   ```powershell
   .\Start-Triage.ps1
   ```

To customize which modules run, edit `config/collector-config.json`.

## Limitations
- Deep parsing of some artifacts (like Prefetch) relies on PowerShell availability or third-party tools if added later. Currently relies on built-in OS utilities.
- Browser artifact collection only grabs metadata (history, cookies, downloads) to preserve user privacy. Credentials are not decrypted.
- If Sysmon is not installed, Sysmon event logs will not be collected. (An option exists in config to attempt download/installation, but defaults to false).

## Legal Disclaimer
This software is provided "as is" without warranty of any kind. Use at your own risk in authorized environments only.
