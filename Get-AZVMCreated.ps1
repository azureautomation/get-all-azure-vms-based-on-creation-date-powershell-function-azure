

Function Get-AZVMCreated { 
<# 
  .SYNOPSIS 
  Function "Get-AZVMCreated" will connect to a given tenant and parse through the subscriptions and output Azure VM details based on creation date. 
 
  .DESCRIPTION 
  Author: Pwd9000 (Pwd9000@hotmail.co.uk) 
  PSVersion: 5.1 
 
  The user must specify the TenantId when using this function. 
  The function will request access credentials and connect to the given Tenant. 
  Granted the identity used has the required access permisson the function will parse through all subscriptions  
  and gather data on Azure Vms based on the creation date. 
 
  .EXAMPLE 
  Get-AZVMCreated -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" 
   
 
  .PARAMETER TenantId 
  A valid Tenant Id object. e.g: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" <String> 
#> 
 
[CmdletBinding()] 
param( 
    [Parameter(Mandatory = $True, 
        ValueFromPipeline = $True, 
        HelpMessage = 'Please specify the tenant id? e.g: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"')] 
    [string]$TenantId 
) 
 
#------------------------------------------------Obtain Credentials for Session------------------------------------------------------------ 
$Credential = Get-Credential 
 
#---------------------------------------------Get all Subscription Ids for given Tenant---------------------------------------------------- 
$SubscriptionIds = (Get-AzureRmSubscription -TenantId $TenantId).Id 
 
#-------------------------------------------------Create Empty Table to capture data------------------------------------------------------- 
$Table = @() 
 
Foreach ($Subscription in $SubscriptionIds) { 
    Write-Host "Checking Subscription: $Subscription. for any Azure VMs and their creation date. This process may take a while. Please wait..." -ForegroundColor Green 
 
    $RMAccount = Add-AzureRmAccount -Credential $Credential -TenantId $TenantId -Subscription $subscription 
    Get-AzureRmDisk | Where-Object {$_.TimeCreated -le (Get-Date)} | 
            Select-Object Name, ManagedBy, Resourcegroupname, TimeCreated | 
            ForEach-Object { 
                Try { 
                    $ErrName = $_.Name 
                    $AzDiskManagedBy = $_.managedby | Split-path -leaf 
                    $AzDiskManagedByRG = $_.ResourceGroupName 
                    $CreationDate = $_.TimeCreated 
                    $OS = (Get-AzurermVM -name $AzDiskManagedBy -ResourceGroup $AzDiskManagedByRG).StorageProfile.ImageReference.Offer 
                    $SKU = (Get-AzurermVM -name $AzDiskManagedBy -ResourceGroup $AzDiskManagedByRG).StorageProfile.ImageReference.SKU 
                    $Table += [pscustomobject]@{VMName = $AzDiskManagedBy; Created = $CreationDate; ResourceGroup = $AzDiskManagedByRG; OperatingSystem = $OS; SKU = $SKU} 
                } 
                Catch { 
                    Write-Host "Cannot determine machine name associated with disk: [$ErrName]. Skipping drive-check for this item..." -ForegroundColor Yellow 
                    Write-Host "Continue Checking Subscription: $Subscription. for any Azure VMs and their creation date. This process may take a while. Please wait..." -ForegroundColor Green 
                } 
            } 
} 
$UniqueVMs = $Table | Sort -Unique -Property VMName 
$UniqueVMs 
Write-Host "" -ForegroundColor Green 
Write-Host "Number of disks associated with VMs: $($Table.Count)" -ForegroundColor Green 
Write-Host "Number of disks unable to associate with VMs: $($ErrName.Count)" -ForegroundColor Yellow 
Write-Host "Number of unique Azure VMs associated with disks: $($UniqueVMs.Count)" -ForegroundColor Green 
Write-Host "Script finished.." -ForegroundColor Green 
} 
 
<#---------------------------- Sample Script calling function------------------------------------ 
 
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" 
 
$AZVMsAll = Get-AZVMCreated -TenantId $TenantId | sort-object -property Created 
 
$Win10 = $AZVMsAll | Where-Object {$_.SKU -like "*Windows-10*"} | sort-object -property Created 
$Win8 = $AZVMsAll | Where-Object {$_.SKU -like "*Win81*"} | sort-object -property Created 
$Win7 = $AZVMsAll | Where-Object {$_.SKU -like "*Win7*"} | sort-object -property Created 
$Server2008R2 = $AZVMsAll | Where-Object {$_.SKU -like "*2008-R2*"} | sort-object -property Created 
$Server2012R2 = $AZVMsAll | Where-Object {$_.SKU -like "*2012-R2*"} | sort-object -property Created 
$Server2016 = $AZVMsAll | Where-Object {$_.SKU -like "*2016*"} | sort-object -property Created 
$RHEL = $AZVMsAll | Where-Object {$_.OperatingSystem -like "*RHEL*"} | sort-object -property Created 
$Ubuntu = $AZVMsAll | Where-Object {$_.OperatingSystem -like "*Ubuntu*"} | sort-object -property Created 
$Centos = $AZVMsAll | Where-Object {$_.OperatingSystem -like "*Centos*"} | sort-object -property Created 
 
$AZVMsAll #Display all VMs 
-----------------------------------------------------------------------------------------------#> 
 
 

