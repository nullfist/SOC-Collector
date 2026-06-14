# Analyst Usage Guide

## Execution

1. Transfer the `SOC-Triage-Collector` folder to the target machine via a secure medium (e.g., dedicated USB drive, secure file transfer).
2. Open an **Administrator** PowerShell prompt.
3. CD into the directory.
4. Run `.\Start-Triage.ps1`

## Configuration

You can tailor the collection by editing `config/collector-config.json` before execution.
For example, to skip `CollectBrowserArtifacts`, set it to `false`.
To attempt a Sysmon installation if missing, set `InstallSysmonIfMissing` to `true`.

## Output

The script generates an output directory in the format `output/CASE-<HOSTNAME>-<TIMESTAMP>`.
Inside, you'll find categorized folders:
- `Browser/`
- `EventLogs/`
- `Misc/`
- `Network/`
- `Persistence/`
- `Processes/`
- `Reports/`
- `SystemInfo/`

If compression is enabled, a `.zip` file is produced alongside the output folder, named `CASE-<HOSTNAME>-<TIMESTAMP>.zip`.
A sidecar `.sha256` hash of the ZIP is also created.

## Reporting

Check the `Reports/` directory for the `ExecutiveReport.html`. This report provides a quick overview of highly suspicious findings (like disabled Defender, unsigned kernel drivers, or suspicious process parent-child relationships) and allows analysts to prioritize their deep dive into the CSVs.
