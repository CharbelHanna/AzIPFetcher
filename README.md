<!-- Banner -->
<pre align="center">
<code>
<pre align="center">
<code>
     _     ________ ____  _____    _       _               
    / \   |__  /_ _|  _ \|  ___|__| |_ ___| |__   ___ _ __ 
   / _ \    / / | || |_) | |_ / _ \ __/ __| '_ \ / _ \ '__|
  / ___ \  / /_ | ||  __/|  _|  __/ || (__| | | |  __/ |   
 /_/   \_\/____|___|_|   |_|  \___|\__\___|_| |_|\___|_|   
                                                           
                                                                    
     > AZIPFetcher — Azure IP discovery made simple — fast, flexible, and export-ready 
</code>
</pre>

</code>
</pre>

## Overview

This PowerShell script retrieves the used and available IP addresses in specified Azure Virtual Networks and their subnets. It supports processing multiple subscriptions, management groups, and subscription name patterns. The results can be exported in CSV, JSON, or HTML formats.

## Features

- Retrieves used and available IP addresses in Azure Virtual Networks and subnets.
- Supports multiple subscriptions and management groups.
- Filters subscriptions based on name patterns.
- Queries a specific IP address to determine its status and location.
- Interactive query mode for searching multiple IP addresses in a single session.
- Exports results to CSV, JSON, and HTML reports.
- Exports query results to CSV, JSON, and HTML formats.
- Automatically installs required Azure PowerShell modules if not present.
- Provides detailed error handling and user feedback.
- Ensures the user is logged in to Azure before script execution.
- Supports login methods for different platforms (e.g., device authentication for Unix-based systems).
- Allows selecting the destination folder for exported files.

## Prerequisites

- Azure PowerShell module installed.
- Read access permissions on the desired workscope.

## Parameters

| Parameter            | Type   | Mandatory | Description                                                                              |
| -------------------- | ------ | --------- | ---------------------------------------------------------------------------------------- |
| `MgGroupIds`         | Array  | No        | One or more Management Group IDs separated by commas.                                    |
| `subIds`             | Array  | No        | One or more Subscription IDs separated by commas. Use `@all` for all.                    |
| `Subpattern`         | Array  | No        | One or more Subscription name patterns separated by commas.                              |
| `OutputFolder`       | String | No        | The folder where the exported files will be saved. Defaults to the script's root folder. |
| `ExportCSV`          | Switch | No        | Exports the results to a CSV file.                                                       |
| `ExportJSON`         | Switch | No        | Exports the results to a JSON file.                                                      |
| `ExportHTML`         | Switch | No        | Exports the results to an HTML file.                                                     |
| `QueryIP`            | String | No        | IP address to query for availability and location.                                       |
| `QueryIPInteractive` | Switch | No        | Enables interactive query mode. Prompts for IP addresses after data collection; type `quit` to exit. |
| `QueryExportCSV`     | Switch | No        | Exports query results to a CSV file.                                                     |
| `QueryExportJSON`    | Switch | No        | Exports query results to a JSON file.                                                    |
| `QueryExportHTML`    | Switch | No        | Exports query results to an HTML file (requires the PSWriteHTML module).                 |

## Usage

### Example 1: Retrieve available IPs from virtual networks under specific management groups

```powershell
AzIPFetcher.ps1 -MgGroupIds 'MymgGroupID1,MyMGroupID2' -Subpattern 'prod*,test*' -ExportCSV -OutputFolder "C:\Reports"
```

### Example 2: Retrieve available IPs from virtual networks in all subscriptions

```powershell
AzIPFetcher.ps1 -subIds '@all' -ExportJSON 
```

### Example 3: Retrieve available IPs from virtual networks inside a specific subscriptions

```powershell
AzIPFetcher.ps1 -subIds 'subscriptionId1,subscriptionId2' -ExportHTML -OutputFolder "D:\Exports"
```

### Example 4: Query a specific IP address

```powershell
AzIPFetcher.ps1 -MgGroupIds 'MyMgID' -QueryIP "10.0.1.5" -QueryExportHTML -OutputFolder "D:\Reports"
```

Retrieves all IPs from subscriptions in the specified management group and queries for `10.0.1.5`. The query result — status and location details — is exported to an HTML report.

### Example 5: Interactive IP query mode

```powershell
AzIPFetcher.ps1 -subIds '@all' -QueryIPInteractive
```

Retrieves all IPs from all subscriptions, then prompts for IP addresses to search. Query as many addresses as needed in one session; type `quit` to exit.

## Output

The script outputs the following details for each Virtual Network and its subnets:

- Subscription Name
- Subscription ID
- Resource Group Name
- Virtual Network Name
- Virtual Network Address Space
- Subnet Name
- Subnet Address Space (CIDR)
- Count of Used IPs
- List of Used IPs
- Count of Available IPs
- List of Available IPs

### Query Results

When using `-QueryIP` or `-QueryIPInteractive`, the script returns:

- **Query IP Address**: the IP address that was queried
- **Status**: one of the following:
  - `IN USE` — the IP is currently assigned to a resource (NIC, VM, etc.)
  - `AVAILABLE` — the IP is free for use in the subnet
  - `RESERVED` — the IP is reserved by Azure (network, gateway, broadcast)
  - `NOT FOUND` — the IP does not fall within any scanned subnet
- **Subscription**: the Azure subscription containing the IP
- **Resource Group**: the resource group containing the VNET
- **Virtual Network**: the VNET name and address space
- **Subnet**: the subnet name and CIDR address space

## Exported Reports

### Full IP report

- **CSV**: `<OutputFolder>\AzIPFetcher_<timestamp>.csv`
- **JSON**: `<OutputFolder>\AzIPFetcher_<timestamp>.json`
- **HTML**: `<OutputFolder>\AzIPFetcher_<timestamp>.html`

### Query results

- **CSV**: `<OutputFolder>\AzIPFetcher_<timestamp>_Query.csv`
- **JSON**: `<OutputFolder>\AzIPFetcher_<timestamp>_Query.json`
- **HTML**: `<OutputFolder>\AzIPFetcher_<timestamp>_Query.html`

In interactive mode, each query writes its own file with the queried address in the name (for example `_10_0_1_5_Query.csv`).

## Change Log

### Version 1.3.1

- Renamed exported report files from `AvailableIPsInVNET_` to `AzIPFetcher_`.
- Query mode (`-QueryIP` / `-QueryIPInteractive`) no longer prints the full IP table to the console; only the query result is shown.
- Fixed subnet address space rendering as a .NET type name in HTML exports.
- Subnets with multiple address prefixes are now matched correctly during queries.

### Version 1.3.0

- Added an IP query feature (`-QueryIP`) to search for a specific IP address.
- Added interactive query mode (`-QueryIPInteractive`) for multiple lookups in one session.
- Added query result exports (`-QueryExportCSV`, `-QueryExportJSON`, `-QueryExportHTML`).
- Restored subscription and resource group details in the report output.
- Fixed a stray token that caused a runtime error in the Azure login fallback path.

### Version 1.2.1

- Added a banner display with script details and metadata.
- Renamed the script to `AzIPFetcher.ps1`.

### Version 1.2

- Added a login check to ensure the user is logged in to Azure before proceeding with script execution.
- Added login methods for different platforms (e.g., device authentication for Unix-based systems).
- Added support for selecting the export file destination folder.
- Improved error handling and user feedback.

### Version 1.1

- Added support for multiple subscriptions and management groups.
- Added filtering by subscription name patterns.
- Added export options for CSV, JSON, and HTML.
- Improved error handling and user feedback.
- Bug fixes.

### Version 1.0

- Initial version.

## Author

Charbel Hanna
charbel_hanna@hotmail.com
