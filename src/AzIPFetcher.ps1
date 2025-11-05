<#
# ================================================
#  AzIPFetcher - Azure Virtual Network IP Fetcher
#  Author: Charbel Hanna
#  Version: 1.2.1
#  Last Updated: (auto-generated)
#  License: MIT License
# ==========================================

.SYNOPSIS
This script retrieves the used and available IP addresses in a specified Azure Virtual Network and its subnets.
.DESCRIPTION
This PowerShell script connects to Azure, retrieves the specified Virtual Network and its subnets, and calculates the used and available IP addresses within those subnets. It outputs the results in a structured format.  
.PARAMETER vnetname
The name of the Virtual Network to query.
.PARAMETER vnetrgname
The name of the Resource Group containing the Virtual Network.  
.EXAMPLE
Get-AvailableIPsInVNet -MgGroupIDs 'MymgGroupID1,MyMGroupID2'  -Subpattern 'prod*,test*' -ExportCSV
This example retrieves available IPs from all subscriptions under the specified management groups, filtering subscriptions based on provided patterns,
 and exports the results to a CSV file.
.NOTES
This script requires the Azure PowerShell module to be installed and the user to be authenticated to Azure.
CHANGELOG{
- Version 1.0 - Initial version
- Version 1.1 [
        * Added support for : 
            - Processing multiple subscriptions
            - Processing all subscriptions in a management group and nested management groups
            - Processing all Filtered subscriptions based on name patterns
        * Exporting results to CSV, JSON and HTML reports
        * Checking and installing required modules if not present
        * Improved error handling and user feedback
        * Bug fixes
          ]
- Version 1.2 [
 * Added login check to ensure user is logged in to Azure before proceeding with the script execution.
 * Added login method for different platforms (Device authentication for Unix-based systems).
 * Added support for selecting export file destination folder.
 ]
- Version 1.2.1 [
 * Added Banner Display 
 * renamed script to AzIPFetcher.ps1
  ]
 }
#>
[CmdletBinding()]
param (
    [Parameter( Mandatory = $false,
        HelpMessage = "Enter one or many Management Group ID separated by comma ','")]
    [Array] $MgGroupIds,
    [Parameter( Mandatory = $false,
        HelpMessage = "Enter one or many Subscriptions ID separated by commas ','. \n @all to get All Subscriptions")]
    [Array] $subIds,
    [Parameter( Mandatory = $false, 
        HelpMessage = "Enter one or many Subscriptions names or patterns to be separated by commas ','")]
    [Array] $Subpattern,
    [parameter( Mandatory = $false,
        HelpMessage = "select the desired location to store the extracted output")]
    [string]$OutputFolder,
    [Parameter(Mandatory = $false)]
    [switch]$ExportCSV,
    [Parameter(Mandatory = $false)]
    [switch]$ExportJSON,
    [Parameter(Mandatory = $false)]
    [switch]$ExportHTML
)
 
# Check if user is logged in to Azure
function Connect-azure {
    try {
        write-host "Checking Azure Login Status..." -ForegroundColor Cyan
        $context = Get-AzContext -ErrorAction Stop
        if ($null -eq $context) {
            throw "No Azure context found."
        }
        if (!(Get-AzAccessToken -ErrorAction SilentlyContinue)) {
            throw "Please authenticate to azure - Connect-AzAccount"
        }
        Write-Host "User is logged in to Azure with subscription: $($context.Subscription.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "You are not logged in to Azure. Please log in to continue." -ForegroundColor Red
        if ($PSVersionTable.Platform -eq 'Unix') {
            Connect-AzAccount -UseDeviceAuthentication
        }
        else {
            Connect-AzAccount
        }
        
   bn  }
}
# Ensure required modules are installed
function Install-RequiredModules {
    param (
        $InstallPSWriteHTML = $ExportHTML
    )
    if ($InstallPSWriteHTML) {
        write-host "ExportHTML is selected, therefore PSWriteHTML module will be installed" -ForegroundColor Yellow
        write-host "Checking the availability for the following modules 'Az.Accounts','Az.Network','Az.Resources', 'PSWriteHTML'" -ForegroundColor Cyan   
        $modules = @('Az.Accounts', 'Az.Network', 'Az.Resources', 'PSWriteHTML')
    }
    else {
        write-host "Checking the availability for the following modules 'Az.Accounts','Az.Network','Az.Resources'" -ForegroundColor Cyan 
        $modules = @('Az.Accounts', 'Az.Network', 'Az.Resources')
    }
    foreach ($module in $modules) {
        write-host "Checking for required modules..." -ForegroundColor Cyan
        if (-not (Get-Module -ListAvailable -Name $module)) {
            
            write-host "Module $module is not installed. Installing..." -ForegroundColor Yellow
            Write-Host "Installing module: $module" -ForegroundColor blue
            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
            import-module $module -Force
        }
        else {
            Write-Host "Module $module is already installed." -ForegroundColor Green
            import-module $module -Force
        }
    }
}
# Initialize arrays
[array]$ManagementGroupIds = @()
[array]$subscriptionIds = @()
[array]$Subscriptionpattern = @()
[array]$Script:results = @()

# -------------------------------
# Banner Configuration
# -------------------------------
$ScriptVersion = "1.2.1"
$ScriptPath   = $MyInvocation.MyCommand.Definition
$LastUpdated  = (Get-Item $ScriptPath).LastWriteTime.ToString("yyyy-MM-dd")
$Author        = "Charbel Hanna"
$GitHubRepo    = "https://github.com/charbelhanna/AzIPFetcher"
$License       = "MIT License"

# Function to Print Banner
function Print-Banner {
   param (
    [string]$scriptVersion ,
    [string]$LastUpdated , 
    [string]$Author ,
    [string]$GitHubRepo   
   ) 
# -------------------------------
# ANSI Colors (RGB)
# -------------------------------
$Blue    = "`e[38;2;0;120;215m"   # Azure Blue
$White   = "`e[38;2;255;255;255m" # White
$Cyan    = "`e[38;2;0;200;255m"   # Accent Cyan
$Gray    = "`e[38;2;180;180;180m" # Divider Gray
$Reset   = "`e[0m"

# -------------------------------
# ASCII Banner - AzIPFetcher
# -------------------------------
Write-Host ""
Write-Host ("{0}     _     ________ ____  _____    _       _               {1}" -f $Blue, $Reset)
Write-Host ("{0}    / \   |__  /_ _|  _ \|  ___|__| |_ ___| |__   ___ _ __ {1}" -f $Blue, $Reset)
Write-Host ("{0}   / _ \    / / | || |_) | |_ / _ \ __/ __| '_ \ / _ \ '__|{1}" -f $Blue, $Reset)
Write-Host ("{0}  / ___ \  / /_ | ||  __/|  _|  __/ || (__| | | |  __/ |   {1}" -f $Blue, $Reset)
Write-Host ("{0} /_/   \_\/____|___|_|   |_|  \___|\__\___|_| |_|\___|_|   {1}" -f $Blue, $Reset)
Write-Host ("{0}                                                            {1}" -f $Blue, $Reset)
Write-Host ("{0}                          🌐  AzIPFetcher{1}" -f $White, $Reset)
Write-Host ("{0}         ☁️  Azure IP discovery made simple — fast, flexible, and export-ready{1}" -f $Cyan, $Reset)
Write-Host ""

# -------------------------------
# Dynamic Info Line
# -------------------------------
Write-Host ("{0}Version:{1} {2}   {0}Last Updated:{1} {3}" -f $Cyan, $Reset, $ScriptVersion, $LastUpdated)
Write-Host ("{0}Author:{1}  {2}" -f $Cyan, $Reset, $Author)
Write-Host ("{0}GitHub:{1}  {2}" -f $Cyan, $Reset, $GitHubRepo)
Write-Host ("{0}License:{1} {2}" -f $Cyan, $Reset, $License)
Write-Host ""
Write-Host ("{0}---------------------------------------------------------------{1}" -f $Gray, $Reset)
Write-Host ""
Start-Sleep -Milliseconds 300
}


# Function to Get Subscriptions Variables
function Get-SubscriptionVariables {
    param(
        [string] $Id,
        [string] $Name,
        [string] $State 
    )
        
    @{
        'Subscription.Id'    = $Id
        'Subscription.Name'  = $Name
        'Subscription.State' = $State
    }
}
# Function to construct The working context
function Get-workingcontext {
    [CmdletBinding()]
    param ([Parameter( Mandatory = $false,
            HelpMessage = "Enter one or many Management Group ID separated by comma ','")]
        [Array] $ManagementGroupIds,
        [Parameter( Mandatory = $false,
            HelpMessage = "Enter one or many Subscriptions ID separated by commas ','. \n @all to get All Subscriptions")]
        [Array] $subscriptionIds,
        [Parameter( Mandatory = $false, 
            HelpMessage = "Enter one or many Subscriptions names or patterns to be separated by commas ','")]
        [Array] $Subscriptionpattern
    )
    $Script:subscriptions = @()
    #  - Processing based on Supplied subscription Ids
    if ($subscriptionIds -ne '@all' -and -not ([string]::IsNullOrEmpty($subscriptionIds))) {
        $subscriptionIds = $subscriptionIds.Trim().ToLowerInvariant()
        Write-Host "Fetching Subscriptions : '$($subscriptionIds)'"
        $subscriptionIds.Split(',') | Where-Object { $_ } | ForEach-Object {
            $s = Get-AzSubscription -SubscriptionId $_.Trim() 
            Write-Host "Processing Subscription $($s)"     
            $Script:subscriptions += Get-SubscriptionVariables -Id $_.Trim().ToLowerInvariant() -Name $s.Name.ToLowerInvariant() -State $s.State.ToLowerInvariant()
            #write-host "these are the $Script:subscriptions"
        }
    }
    # - Processing based on Supplied Management Group Ids
    if ($ManagementGroupIds -ne '@all' -and -not ([string]::IsNullOrEmpty($ManagementGroupIds))) {
        $ManagementGroupIds = $ManagementGroupIds.Trim().ToLowerInvariant()
        Write-Host "Fetching Subscriptions from Management Groups : '$($ManagementGroupIds)'"
        $queue = New-Object System.Collections.Queue
            
        if ($null -ne $ManagementGroupIds) {
            $ManagementGroupIds.Split(',') | Where-Object { $_ } | ForEach-Object {
                $mg = Get-AzManagementGroup -GroupName $_.trim() -Expand -Recurse -warningAction silentlyContinue
                $queue.Enqueue($mg)
            }
        }    
        while ($queue.Count -ne 0) {
            $node = $queue.Dequeue()
            if ($node.Type -eq '/subscriptions') {
                $Script:subscriptions += Get-SubscriptionVariables -Id $node.Name.ToLowerInvariant() -Name $node.DisplayName #-state $node.State.ToLowerInvariant()
            }
            
            $node.Children | Where-Object { $_ } | ForEach-Object {
                $queue.Enqueue($_)
            }
        }
    }
    # removing Disabled Subscriptions
    $subs = $Script:subscriptions
    $subs = $subs | foreach-object { Get-AzSubscription -SubscriptionId $_.'Subscription.Id' | Where-Object { $_.state -eq 'Enabled' } }`
    | ForEach-Object { Get-SubscriptionVariables -Id $_.SubscriptionId.ToLowerInvariant() -Name $_.Name.ToLowerInvariant() -State $_.State.ToLowerInvariant() }
    write-host "Total Enabled Subscriptions found: $($subs.count)"
    $subs = $Subs | Sort-Object 'Subscription.Name' 
    if ($null -ne $subscriptionpattern) {
        $SubscriptionPattern = $Subscriptionpattern.Trim().ToLowerInvariant()
        Write-Host "Filtering Subscriptions with '$($subscriptionPattern)' Name pattern `n "
        $SubscriptionPattern = $SubscriptionPattern.Split(',')
        # construct a regex filter from the subscription patterns
        $RegExFilter = ($SubscriptionPattern | Foreach-Object { [regex]::escape($_) }) -join '|'
        $Script:subscriptions = $subscriptions | Where-Object { ($_['Subscription.Name'] -match $RegExFilter) }
        if ( -not $Script:subscriptions) {
            Write-Host "No subscriptions found matching the pattern '$($SubscriptionPattern)'"
            exit
        }
        else {
            write-host "Found the following subscriptions"
            return $Script:subscriptions.'Subscription.Name' | Format-Table -AutoSize
        }
    }
    else {
        Write-output "No Subscription pattern provided, returning all subscriptions `n " 
        return $Script:subscriptions.'Subscription.Name' | Format-Table -AutoSize
    }
}
# Function to get available IPs in a Virtual Network
function Get-AvailableIPsInVNet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$subscriptionId
    )
    Set-AzContext -SubscriptionId $subscriptionId | Out-Null   #required default subscription context to fetch additional resources
    $vnet = Get-AzVirtualNetwork  # Get all Virtual Networks in the subscription
    $subName = (Get-AzSubscription -SubscriptionId $subscriptionId).Name # Get the subscription name
    if (-not $vnet) {
        Write-host "no Virtual Network  found in $subName."
    }
    else {
        Write-host "Found $($vnet.count) Virtual Network(s) in $subName."
        $results = @()
        $vnet | foreach-object {
            # run through each Virtual Network
            $vnet = $_ # Assign the current Virtual Network to a variable
            $vnetname = $_.Name
            $vnetrgname = $_.ResourceGroupName
            Write-Host "Processing Virtual Network: $vnetname in Resource Group: $vnetrgname" -Separator '|'
            # run through each subnet in the Virtual Network
            $vnet.Subnets | ForEach-object { 
                # Fecth each subnet in the Virtual Network
                $IpAddressSpace = $null
                $Prefixlength = $null
                [array]$UsedIps = @()
                [array]$AllUsedIps = @()
                [array]$AvailableIps = @()
                [array]$AllIps = @()
                [array]$NextIp = @()
                [array]$IpRange = @()
                [array]$Ips = @()
                $subnet = $_
                $subnetConfig = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet.Name # Get the subnet configuration
                $IpAddressSpace = [system.Net.IpAddress]::Parse($subnet.AddressPrefix.Split('/')[0]) # Parse the IP address from the subnet prefix and convert it to an IPAddress object
                $Prefixlength = [Convert]::ToInt32($subnet.AddressPrefix.Split('/')[1]) # Get the prefix length from the subnet prefix
                $IpRange = 1..([Math]::Pow(2, (32 - $prefixlength)) - 1) # Calculate the available range of IP addresses in the subnet
                $Ipconfigurations = $subnetConfig.IpConfigurations.Id # Get the IP configurations associated with the subnet
                if ($ipconfigurations) {
                    $netWorkInterfaceIds = $ipconfigurations | ForEach-Object { $_.split('/ipConfigurations/')[0] } # Extract the Network Interface IDs from the IP configurations
                    # Remove duplicate Network Interface IDs
                    $networkInterfaceIds = $netWorkInterfaceIds | select-object -unique
                    # Fetch all used IPs in the subnet
                    #$_ -notlike "*ARMRG*" -and $_ -notlike "*PANW*" -and $_ -notlike "*MDP*"
                    $networkInterfaceIds | Where-Object { $_ -like "*/NetworkInterfaces/*" -and $_ -like "*/$($subscriptionid)/*" }`
                    | ForEach-object { 
                        $UsedIps = (Get-AzNetworkInterface -ResourceId $_).IpConfigurations  | select-object -Expandproperty PrivateIpAddress
                        $AllUsedIps += $UsedIps
                    }
                    if ($AllUsedIps) { $AllUsedIps = ([IpAddress[]]($AllUsedIps -split ' ').trim() | sort-object Address) }
                    # Calculate Ips that are part of the subnet
                    $IpAddressSpaceBytes = $ipAddressSpace.GetAddressBytes()
                    [Array]::Reverse($ipAddressSpaceBytes) # Reverse for little-endian format
                    $NetID = [BitConverter]::ToUInt32($ipAddressSpaceBytes, 0) 
                    $Ips = $ipRange | ForEach-Object { 
                        $NetID++
                        $nextIpBytes = [BitConverter]::GetBytes($NetID)
                        [Array]::Reverse($nextIpBytes) # Reverse back to big-endian format
                        $NextIp = [System.Net.IPAddress]::new($nextIpBytes)
                        $AllIps += $NextIp # Generate all IPs in the subnet
                    }
                    # detect special subnets
                    if (($subnet.Name -eq "GatewaySubnet")`
                            -OR ($subnet.Name -eq "AzureBastionSubnet")`
                            -OR ($subnet.Name -eq "AzureFirewallSubnet")`
                            -OR ($subnet.Name -eq "AzureFirewallManagementSubnet")`
                            -OR ($subnet.Name -eq "RouteServerSubnet")) {
                        $AllUsedIps = "Managed IP assignments `non reserved subnets"
                        $AvailableIps = "Undefined"
                        $UsedIpsCount = "N/A"
                        $AvailableIpsCount = "N/A"
                    }
                    else {
                        # Getting Available IPs by comparing all IPs in the subnet with the used IPs
                        $AvailableIps = Compare-Object -ReferenceObject $AllIps -DifferenceObject $AllUsedIps -PassThru #| Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
                        $AvailableIps = $AvailableIps[3..$AvailableIps.count] # Exclude Azrure reserved IPs
                        $UsedIpsCount = $AllUsedIps.Count
                        $AvailableIpsCount = $AvailableIps.Count
                    }
             
                    # apply IP address transformation
                }
                Else {
                    $ipAddressSpaceBytes = $ipAddressSpace.GetAddressBytes()
                    [Array]::Reverse($ipAddressSpaceBytes) # Reverse for little-endian format
                    $NetID = [BitConverter]::ToUInt32($ipAddressSpaceBytes, 0)
                    #Generate all IPs in the subnet  
                    $Ips = $ipRange | ForEach-Object { 
                        $NetID++
                        $nextIpBytes = [BitConverter]::GetBytes($NetID)
                        [Array]::Reverse($nextIpBytes) # Reverse back to big-endian format
                        $NextIp = [System.Net.IPAddress]::new($nextIpBytes)
                        $AllIps += $NextIp
                    }
                    $AllUsedIps = "No IPs in use"
                    $AvailableIps = $AllIps # All IPs are available
                    $AvailableIps = $AvailableIps[3..$AvailableIps.count] # Exclude Azrure reserved IPs
                    $UsedIpsCount = 0
                    $AvailableIpsCount = $AvailableIps.Count
                }
                #write-host "AvailableIps are $AvailableIps"
                $Script:results += [PSCustomObject]@{
                    #"SubscriptionName"   = $subName
                    #"SubscriptionId"     = $subscriptionId
                    #"ResourceGroupName" = $vnetrgname
                    "VNetName"           = $vnet.Name
                    "VNetAddressSpace"   = ($vnet.AddressSpace.AddressPrefixes -join "`r`n")
                    "SubnetName"         = $subnet.Name
                    "SubnetAddressSpace" = ($subnet.AddressPrefix).split('{,}')
                    "UsedIPsCount"       = $UsedIpsCount
                    "UsedIPs"            = ($AllUsedIPs -join "`r`n")
                    "AvailableIPsCount"  = $AvailableIpsCount
                    "AvailableIPs"       = ($AvailableIps -join "`r`n")
                }    
            }
            
        }
        # send results to output
        return  $Script:results  >$null
        
    }
} 
function Initialize-FileName {
    $Today = Get-Date
    $FileName = "AvailableIPsInVNET_$($Today.ToString("ddMMyyyy_HHmmss"))"
    if ( -not $OutputFolder) {
        $OutputFolder = $PSScriptRoot
        write-host "No output folder provided. Using script root folder: $OutputFolder" -ForegroundColor Yellow
    }
    Else {
        write-host "Using provided output folder: $OutputFolder" -ForegroundColor Green
    }
    if (-not (Test-Path -Path $OutputFolder)) {
        Write-Host "Output folder $OutputFolder does not exist. Creating it now..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }
    $script:FilePath = Join-Path -Path $OutputFolder -ChildPath $FileName
    write-host "The following output config will be used: $script:FilePath" -ForegroundColor Green
}

# Main script execution
try {
    # Print Banner
    Print-Banner -ScriptVersion $ScriptVersion -LastUpdated $LastUpdated -Author $Author -GitHubRepo $GitHubRepo
    #verfy and install required modules
    Install-RequiredModules 
    # Check Azure Login
    Connect-Azure 
    # Initialize File Name
    Initialize-FileName
    # Displaying selecting parameters
    # Set working context
    Get-workingcontext -ManagementGroupIds $MgGroupIds -subscriptionIds $subIds -Subscriptionpattern $Subpattern
    # Process each subscription
    $Script:subscriptions | ForEach-Object {
        write-host `n'Processing Subscription' $_.'Subscription.Name' 'with Id' $_.'Subscription.Id'
        Get-AvailableIPsInVNet -subscriptionId $_.'Subscription.Id' | Format-Table -AutoSize #formatting the output as a table
    }
    # Export options based on input switches
    switch ($ExportCSV) {
        $true {
            Write-Host "Exporting report as CSV" -ForegroundColor Yellow 
            $Script:results | Export-Csv -Path "$script:FilePath.csv" -NoTypeInformation -Encoding UTF8
            Write-Host "CSV report exported to $script:FilePath.csv" -ForegroundColor Green
        }
    }
    switch ($ExportJSON) {
        $true {
            Write-Host "Exporting report as JSON" -ForegroundColor Yellow 
            $Script:results | ConvertTo-Json -Depth 10 | Out-File -FilePath "$script:FilePath.json"
            Write-Host "JSON report exported to $script:FilePath.json" -ForegroundColor Green
        }
    }
    switch ($ExportHTML) {
        $true {
            Write-Host "Exporting report as HTML" -ForegroundColor Yellow 
            New-HTML -Title "Available IPs in VNET Report" -FilePath "$script:FilePath.html" {
                New-HTMLSection -HeaderText "Available IPs in VNET Report" {
                    New-HTMLTable -DataTable $Script:results
                }
            }
            Write-Host "HTML report exported to $script:FilePath.html" -ForegroundColor Green
        }
    }
    # Always show results in table
    Write-Host "`n Printing to Console Final Results:" -ForegroundColor Cyan
    $Script:results | Sort-Object SubnetName | Format-table -wrap -AutoSize

}
catch {
    Write-Error "An error occurred: $_"
}
# End of script
