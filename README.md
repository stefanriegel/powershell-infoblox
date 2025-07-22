# Infoblox Universal DDI: Extract Empty Subnets

This PowerShell script finds all empty subnets (no assigned hosts, only network/broadcast addresses used) across all IPAM spaces in your Infoblox Universal DDI (EU tenant) and exports them to a CSV file.

## Quick Start

1. **Install PowerShell 7+** and the [ibPS module](https://github.com/TehMuffinMoo/ibPS):
   ```powershell
   Install-Module -Name ibPS -Scope CurrentUser
   ```
2. **Save your API key** in a file named `.b1apikey` in the script directory (no quotes, no extra lines).
3. **Run the script:**
   ```powershell
   pwsh ./extract-empty-subnets.ps1
   ```

## Output
- Results are saved as `empty_subnets-YYYYMMDD-HHmmss.csv`.
- Columns: Name, Address, CIDR, Location, Cloud Provider, Subnet Creation Date, First Seen, Last Seen (sortable in Excel).

---

**Note:** Requires access to the Infoblox Universal DDI EU tenant and a valid API key. 