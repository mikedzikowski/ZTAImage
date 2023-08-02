# Zero Trust and Azure Imaging

# PRE-REQS

All resources are assumed to be within the same resource group. Resources required before deployment
*Virtual Network
*Storage Account
*Private Endpoint (on storage account)
*Private DNS Zone
*Azure Compute Gallery
*Managed Identity with RBAC Roles - Storage Blob Data Owner (scoped at the storage account) and Owner (scoped at the subscription)
*Any EXEs, scripts, etc. called during deployment uploaded to a storage account container

Examle powershell to run the solution:
```
.\New-VMImage.ps1 -VmName vm-image  -ResourceGroupName rg-image -aibGalleryName gallery -imageVersion 1.0.0 -imageName imageName -imagePublisher imagePub -imageOffer imageOffer -imageSku imageSku  -Verbose
```

How to view the status of runcommands:
```
PS C:\git\ztaimage> $x = Get-AzVMRunCommand -ResourceGroupName test2_group -VMName vm-image -RunCommandName office -Expand InstanceView
PS C:\git\ztaimage> $x.InstanceView


ExecutionState   : Running
ExecutionMessage :
ExitCode         : 0
Output           :
Error            :
StartTime        : 8/2/2023 2:14:27 PM
EndTime          :
Statuses         :
```

# ADDITIONAL DOCUMENTATION IN PROGRESS
