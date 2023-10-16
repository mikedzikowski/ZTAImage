[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $Environment,

    [parameter(Mandatory)]
    [string]
    $ResourceGroupName,

    [parameter(Mandatory)]
    [string]
    $RunCommands,

    [parameter(Mandatory)]
    [string]
    $SubscriptionId,

    [parameter(Mandatory)]
    [string]
    $TenantId,

    [parameter(Mandatory)]
    [string]
    $UserAssignedIdentityClientId,

    [parameter(Mandatory)]
    [string]
    $VirtualMachineName
)

function Write-Log
{
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [parameter(Mandatory)]
        [string]$Type
    )
    $Path = 'C:\cse.txt'
    if(!(Test-Path -Path $Path))
    {
        New-Item -Path 'C:\' -Name 'cse.txt' | Out-Null
    }
    $Timestamp = Get-Date -Format 'MM/dd/yyyy HH:mm:ss.ff'
    $Entry = '[' + $Timestamp + '] [' + $Type + '] ' + $Message
    $Entry | Out-File -FilePath $Path -Append
}

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try 
{
    Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
    Write-Log -Message "Connection to Azure Succeeded" -Type 'INFO'
    [array]$RunCommandNames = $RunCommands.Replace("'",'"') | ConvertFrom-Json
    Write-Log -Message "Run Command Names:" -Type 'INFO'
    $RunCommandNames | Add-Content -Path 'C:\cse.txt' -Force | Out-Null
    $StatusFolder =  (Get-ChildItem -Path 'C:\Packages\Plugins\Microsoft.CPlat.Core.RunCommandWindows' | Sort-Object -Descending)[0].FullName + '\Status\'
    foreach($RunCommandName in $RunCommandNames)
    {
        Remove-Item -Path ($StatusFolder + $RunCommandName + '.status') -Force
        # -ResourceGroupName $ResourceGroupName -VMName $VirtualMachineName -RunCommandName $RunCommandName
        Write-Log -Message "Remove status for '$RunCommandName' Run Command Succeeded" -Type 'INFO'
    }
    Disconnect-AzAccount | Out-Null
    Write-Log -Message "Disconnection to Azure Succeeded" -Type 'INFO'
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}