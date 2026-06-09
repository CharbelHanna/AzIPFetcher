# Copilot Instructions for IPFetcher

## Overview

IPFetcher is a PowerShell-based tool for auditing IP address usage in Azure Virtual Networks. It retrieves used and available IPs across multiple subscriptions, management groups, and supports querying specific IP addresses to determine their status and location.

## Prerequisites & Dependencies

**Required:**
- PowerShell 5.1+ (7.0+ recommended for cross-platform support)
- Azure PowerShell modules:
  - `Az.Accounts` (authentication)
  - `Az.Network` (VNET/subnet operations)
  - `Az.Resources` (management group traversal)
- Valid Azure credentials with read access to target subscriptions/management groups

**Optional:**
- `PSWriteHTML` (for HTML report export; script gracefully continues without it)

**Installation:**
```powershell
# Azure modules install automatically on first run
# To pre-install manually:
Install-Module -Name Az.Accounts, Az.Network, Az.Resources -Scope CurrentUser -Force

# Optional HTML export support:
Install-Module -Name PSWriteHTML -Scope CurrentUser -Force
```

## Azure Authentication Requirements

Users need **Reader-level access** or equivalent to:
- Read Azure subscriptions
- Read Virtual Networks and subnets
- Read Network Interfaces and IP configurations

**Authentication Methods:**
- Interactive: `Connect-AzAccount` (default)
- Automation: Service Principal with certificate or secret
- Unix/Linux: `Connect-AzAccount -UseDeviceAuthentication` (auto-detected)

## Architecture

### Main Script: `Get-AvailableIpsInVNET.ps1`

The script is organized around these core functions:

1. **Initialization & Validation**
   - `Connect-Azure`: Verifies Azure authentication with platform-specific login support (device auth for Unix)
   - `Install-RequiredModules`: Auto-installs required Azure PowerShell modules (Az.Accounts, Az.Network, Az.Resources, PSWriteHTML)
   - `Initialize-FileName`: Sets up output file paths with timestamp-based naming

2. **Subscription Processing**
   - `Get-workingcontext`: Resolves subscription scope (by ID, management group, or name pattern)
   - `Get-SubscriptionVariables`: Creates subscription metadata objects
   - Uses a Queue-based BFS algorithm to traverse nested management groups recursively

3. **IP Analysis**
   - `Get-AvailableIPsInVNet`: Core function that processes each subnet:
     - Converts CIDR notation to IP ranges using bitwise operations
     - Retrieves in-use IPs from network interfaces
     - Calculates available IPs by comparing all vs. used
     - Handles special Azure-managed subnets (GatewaySubnet, AzureBastionSubnet, etc.)
   - Stores results in `$Script:results` (array of PSCustomObjects)

4. **IP Query Functionality**
   - `Test-IPAddressFormat`: Validates IP format
   - `Test-IPInSubnet`: Checks if IP belongs to a subnet using subnet mask math
   - `Find-IPAddressInResults`: Queries results to determine IP status (IN USE/AVAILABLE/RESERVED)
   - `Display-QueryResult`: Formats query results with color-coded output
   - `Export-QueryResults`: Exports query results to CSV/JSON/HTML

5. **Export Functions**
   - Export results to CSV, JSON, or HTML using PSWriteHTML module
   - Supports both full reports and query result exports
   - Uses script-scoped `$FilePath` variable for consistent naming

## Key Conventions

### Variable Naming
- Script-scoped variables: `$Script:results`, `$Script:subscriptions`, `$Script:FilePath`
- Local variables: lowercase with clear intent (e.g., `$vnet`, `$subnet`, `$UsedIps`)
- Arrays: explicit `[array]` type declaration (e.g., `[array]$results = @()`)

### Function Structure
- All functions use `[CmdletBinding()]` for advanced function capabilities
- Functions accept parameters via `param()` block with detailed help messages
- Error handling: try-catch blocks at script entry points, immediate returns for validation failures

### IP Address Processing
- Uses `System.Net.IPAddress` class for IP parsing and manipulation
- Bitwise operations for subnet mask calculations
- Arrays used for IP collections; compare-object for set operations
- Special subnet handling: GatewaySubnet, AzureBastionSubnet, AzureFirewallSubnet, RouteServerSubnet return "N/A" for availability counts

### User Feedback
- Write-Host with ForegroundColor for status messages:
  - Green: Success
  - Yellow: Warnings/informational
  - Red: Errors
  - Cyan: Section headers
- Colorized output for IP query results (IN USE = Red, available = Green)

### Parameter Design
- All main parameters are optional (Mandatory = $false)
- Uses switch parameters for export flags: `-ExportCSV`, `-ExportJSON`, `-ExportHTML`
- Supports wildcard patterns for subscription filtering (e.g., `prod*,test*`)

## Common Tasks

### Running the Script
```powershell
# Retrieve all IPs from specific subscriptions and export as CSV
.\Get-AvailableIpsInVNET.ps1 -subIds 'sub1,sub2' -ExportCSV -OutputFolder "C:\Reports"

# Query specific IP across all subscriptions
.\Get-AvailableIpsInVNET.ps1 -subIds '@all' -QueryIP "10.0.1.5" -QueryExportHTML

# Interactive query mode (search multiple IPs in one session)
.\Get-AvailableIpsInVNET.ps1 -MgGroupIds 'MyMgID' -QueryIPInteractive
```

### Modifying IP Query Logic
When adding new IP status checks, update:
1. `Find-IPAddressInResults` function: Add new status conditions
2. `Display-QueryResult` function: Add color coding if needed
3. Result object properties (line 505-515): Include new fields

### Adding Export Formats
To add a new export format (e.g., XML):
1. Add new parameter (e.g., `-ExportXML` switch)
2. Create export function following the pattern of `Export-QueryResults`
3. Add switch case in main script (around line 669-676)

## Testing Guidance

**Manual Testing Scenarios:**
- Subscription with no VNETs (should display message, continue)
- Subnet with no IPs in use (all should be available except reserved)
- Special subnets (verify "N/A" output)
- Invalid IP address in query mode (should show validation error)
- Interactive mode multiple queries (type 'quit' to exit)

**Module Dependencies:**
- Test with and without PSWriteHTML installed (HTML export should fail gracefully)
- Test on Unix-based systems (device authentication flow)

## Performance Considerations

- **Processing Time**: Scales with number of subscriptions and VNETs. Expect 1-5 minutes for large environments
- **First Run**: Adds 2-3 minutes for module download and installation
- **Interactive Query Mode**: Recommended for searching large result sets (don't re-run full script)
- **Memory Usage**: Results stored entirely in memory; large environments (100+ VNETs) may need optimization
- **Caching**: No caching implemented; each run queries Azure fresh (ensures accuracy)

## Troubleshooting

**"Connect-AzAccount failed / No Azure context found"**
- Ensure user is logged in: `Get-AzContext`
- On Unix/Linux: Script auto-uses device authentication
- Check subscription is enabled: `Get-AzSubscription -SubscriptionId <id>`

**"PSWriteHTML module not found" when using `-ExportHTML`**
- Module fails gracefully; CSV/JSON export still works
- Install manually: `Install-Module -Name PSWriteHTML -Scope CurrentUser -Force`
- Script will attempt auto-install on next run with `-ExportHTML` flag

**"Permission denied" accessing VNETs/subnets**
- Verify user has Reader role: `Get-AzRoleAssignment`
- Check subscription context: `Get-AzContext`
- Ensure resource group/VNET is accessible in selected subscription

**"No subscriptions found" when using `-MgGroupIds`**
- Verify management group ID is correct and user has access
- Check for disabled subscriptions (script filters these automatically, line 249)
- Test with `-subIds '@all'` to verify Azure connectivity

**Script hangs during Azure module installation**
- Kill process and retry; network connectivity may be interrupted
- Modules install to `C:\Users\<user>\Documents\PowerShell\Modules` (Windows)
- Check disk space and internet connectivity

**Large environments timeout or run out of memory**
- Use `-Subpattern` to filter subscriptions
- Use `-QueryIPInteractive` instead of full report for large datasets
- Consider splitting by management group: separate runs per group

## Important Notes

- **Script is not modularized**: All functions are in a single 676-line file. When making changes, verify the entire flow from parameter processing through export.
- **Results object structure**: Each result includes both string representations (for display) and array representations (`*Array` properties) of IPs for query functionality.
- **Azure module state**: Script auto-installs modules but doesn't uninstall—this is intentional for idempotency.
- **Reserved IPs**: First 3 and last IPs in subnet are always reserved by Azure (excluded from available count, line 351/372).
- **Special subnets**: GatewaySubnet, AzureBastionSubnet, AzureFirewallSubnet, RouteServerSubnet, and AzureFirewallManagementSubnet return "N/A" for IP counts (line 343).
