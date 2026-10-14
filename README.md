# ⚡ Audit_Core v2.0

> **High-Performance Hardware & System Topology Auditor**  
> *Developed by [Neon Maw LLC](https://github.com/NeonMaw) — Systems Architecture & Localized Engines.*

`Audit_Core` is a zero-dependency, lightweight PowerShell utility designed to evaluate core system metrics, compute accelerators, and hardware topologies for low-latency workloads, kernel hardening, and server provisioning.

---

## 🚀 Features

- **Non-Elevated Active Power Profile Detection:** Safely extracts active Windows power schemes via native Win32 APIs without requiring administrative elevation or triggering remote session CIM errors.
- **Firmware & BIOS Telemetry:** Reports SMBIOS versions, motherboard/firmware manufacturer, and release timestamps.
- **CPU Topology & Virtualization:** Queries physical cores, logical thread counts, baseline/maximum clock speeds, and hardware-assisted virtualization flags.
- **Physical Memory Accounting:** Accurately measures total visible RAM, real-time memory pressure, and free headroom.
- **Hardware GPU Accelerators:** Enumerate discrete and integrated GPU islands, driver revisions, and hardware VRAM pools.
- **Storage Subsystem Profiling:** Discovers physical storage devices, media types (NVMe, SSD, HDD), bus types, and operational health status.
- **Pipeline & Automation Ready:** Emits formatted ANSI console output, structured JSON (`-AsJson`), or strongly-typed PowerShell objects (`-PassThru`).

---

## 💻 Usage

### 1. Interactive Console Audit
```powershell
.\Audit_Core.ps1
```

### 2. Export Structured JSON (CI/CD & Monitoring Pipelines)
```powershell
.\Audit_Core.ps1 -AsJson
```

### 3. Pipeline Integration (`PSCustomObject`)
```powershell
$audit = .\Audit_Core.ps1 -PassThru
$audit.GPU | Format-Table Name, DriverVer
```

### 4. Continuous Logging
```powershell
.\Audit_Core.ps1 -LogPath "C:\logs\system_audit.json"
```

---

## 📊 Sample Output

```text
==============================================================================
  AUDIT_CORE v2.0 - SYSTEM PERFORMANCE & HARDWARE TOPOLOGY AUDIT
  Neon Maw LLC // High-Efficiency Hardware Optimization & Hardening
==============================================================================
[+] Active Power Profile    : Balanced
[+] BIOS / Firmware         : American Megatrends International, LLC. v1.27 (2025-04-02)
[+] Processor Architecture  : 13th Gen Intel(R) Core(TM) i9-13900H
    Topology & Clocks       : 14 Physical Cores, 20 Threads @ 2600 MHz (VT: True)
[+] Physical RAM Footprint  : 5.21 GB used / 31.74 GB total (16.4% load, 26.53 GB free)
[+] Graphics / GPU Islands  :
    -> NVIDIA RTX 2000E Ada Generation (Driver: 32.0.15.9716)
    -> Intel(R) UHD Graphics (Driver: 32.0.101.7088)
[+] Storage Subsystem       :
    -> WDS500G1XHE-00AFY0 [SSD / NVMe] - 465.8 GB (OK)
    -> YMTC PC41Q-1TB-B [SSD / NVMe] - 953.9 GB (OK)
    -> Sandisk Optimus 5100 500GB [SSD / NVMe] - 465.8 GB (OK)
------------------------------------------------------------------------------
[+] Audit 2.0 Complete. System Profile Evaluated Successfully.
==============================================================================
```

---

## 📜 License

Distributed under the [MIT License](LICENSE).  
Copyright (c) 2026 **Neon Maw LLC**.
