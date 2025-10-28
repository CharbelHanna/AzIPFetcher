# Get-AvailableIPsInVNET.ps1

## Overview

This PowerShell script retrieves the used and available IP addresses in specified Azure Virtual Networks and their subnets. It supports processing multiple subscriptions, management groups, and subscription name patterns. The results can be exported in CSV, JSON, or HTML formats.

## Features

- Retrieves used and available IP addresses in Azure Virtual Networks and subnets.
- Supports multiple subscriptions and management groups.
- Filters subscriptions based on name patterns.
- Exports results to CSV, JSON, and HTML reports.
- Automatically installs required Azure PowerShell modules if not present.
- Provides detailed error handling and user feedback.

## Prerequisites

- Azure PowerShell module installed.
- User authenticated to Azure using `Connect-AzAccount`.

## Parameters

| Parameter         | Type    | Mandatory | Description                                                                 |
|-------------------|---------|-----------|-----------------------------------------------------------------------------|
| `MgGroupIds`      | Array   | No        | One or more Management Group IDs separated by commas.                      |
| `subIds`          | Array   | No        | One or more Subscription IDs separated by commas. Use `@all` for all.      |
| `Subpattern`      | Array   | No        | One or more Subscription name patterns separated by commas.                |
| `ExportCSV`       | Switch  | No        | Exports the results to a CSV file.                                         |
| `ExportJSON`      | Switch  | No        | Exports the results to a JSON file.                                        |
| `ExportHTML`      | Switch  | No        | Exports the results to an HTML file.                                       |

## Usage

### Example 1: Retrieve available IPs for specific management groups
```powershell
Get-AvailableIPsInVNet -MgGroupIds 'MymgGroupID1,MyMGroupID2' -Subpattern 'prod*,test*' -ExportCSV
```

### Example 2: Retrieve available IPs for all subscriptions
```powershell
Get-AvailableIPsInVNet -subIds '@all' -ExportJSON
```

### Example 3: Retrieve available IPs for specific subscriptions
```powershell
Get-AvailableIPsInVNet -subIds 'subscriptionId1,subscriptionId2' -ExportHTML
```

## Output

The script outputs the following details for each Virtual Network and its subnets:

- Virtual Network Name
- Virtual Network Address Space
- Subnet Name
- Subnet Address Space
- Count of Used IPs
- List of Used IPs
- Count of Available IPs
- List of Available IPs

## Exported Reports

- **CSV**: `AvailableIPsInVNET.csv`
- **JSON**: `AvailableIPsInVNET.json`
- **HTML**: `AvailableIPsInVNET.html`

## Change Log

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