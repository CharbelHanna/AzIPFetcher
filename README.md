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
- Exports results to CSV, JSON, and HTML reports.
- Automatically installs required Azure PowerShell modules if not present.
- Provides detailed error handling and user feedback.
- Ensures the user is logged in to Azure before script execution.
- Supports login methods for different platforms (e.g., device authentication for Unix-based systems).
- Allows selecting the destination folder for exported files.

## Prerequisites

- Azure PowerShell module installed.
- Read access permissions on the desired workscope.

## Parameters

| Parameter      | Type   | Mandatory | Description                                                                              |
| -------------- | ------ | --------- | ---------------------------------------------------------------------------------------- |
| `MgGroupIds`   | Array  | No        | One or more Management Group IDs separated by commas.                                    |
| `subIds`       | Array  | No        | One or more Subscription IDs separated by commas. Use `@all` for all.                    |
| `Subpattern`   | Array  | No        | One or more Subscription name patterns separated by commas.                              |
| `OutputFolder` | String | No        | The folder where the exported files will be saved. Defaults to the script's root folder. |
| `ExportCSV`    | Switch | No        | Exports the results to a CSV file.                                                       |
| `ExportJSON`   | Switch | No        | Exports the results to a JSON file.                                                      |
| `ExportHTML`   | Switch | No        | Exports the results to an HTML file.                                                     |

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

The script outputs the following details for each Virtual Network and its subnets

## Output

The script outputs the following details for each Virtual Network and its subnets:work Address Space

- Virtual Network Name
- Virtual Network Address Space
- Subnet Name
- Subnet Address Spaces
- Count of Used IPs- List of Available IPs
- List of Used IPs
- Count of Available IPs## Exported Reports
- List of Available IPs

## Exported Reports

- **HTML**: `<OutputFolder>\AvailableIPsInVNET.html`
- **CSV**: `<OutputFolder>\AvailableIPsInVNET_<timestamp>.csv`
- **JSON**: `<OutputFolder>\AvailableIPsInVNET_<timestamp>.json`
- **HTML**: `<OutputFolder>\AvailableIPsInVNET_<timestamp>.html`

## Change Log

### Version 1.2.1
- Added a banner display with script details and metadata.
- Renamed the script to `AzIPFetcher.ps1`.

### Version 1.2

- Added a login check to ensure the user is logged in to Azure before proceeding with the script execution.ort for multiple subscriptions and management groups.
- Added login methods for different platforms (e.g., device authentication for Unix-based systems).- Added filtering by subscription name patterns.
- Added support for selecting the export file destination folder.options for CSV, JSON, and HTML.
andling and user feedback.

### Version 1.1- Bug fixes

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
