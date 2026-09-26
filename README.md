# Windows Network & Streaming Latency Optimizer

A PowerShell script to eliminate video buffering, DNS congestion, and NIC throughput throttling on Windows.

### What it does:
- **Auto-elevates** to Administrator permissions.
- **Switches DNS** on the active adapter to Anycast public DNS (Google DNS or Cloudflare).
- **Disables NIC Green/Energy Efficient Ethernet** that throttles real-time throughput on Realtek/Intel controllers.
- **Sets TCP Auto-Tuning** to `normal` to remove single-connection download ceilings.
- **Flushes the local DNS cache** and ARP table.

### Quick Run via PowerShell:
Run PowerShell as Administrator and execute:

```powershell
irm [https://raw.githubusercontent.com/](https://raw.githubusercontent.com/)<username>/<repo>/main/Optimize-Network.ps1 | iex
