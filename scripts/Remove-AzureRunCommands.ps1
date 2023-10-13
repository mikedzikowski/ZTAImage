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
    [array]$RunCommandNames = $RunCommands.Replace("'",'"') | ConvertFrom-Json
    Write-Log -Message "Run Command Names:" -Type 'INFO'
    $RunCommandNames | Add-Content -Path 'C:\cse.txt' -Force | Out-Null
    foreach($RunCommandName in $RunCommandNames)
    {
        Remove-AzVMRunCommand -ResourceGroupName $ResourceGroupName -VMName $VirtualMachineName -RunCommandName $RunCommandName -ErrorAction Stop
    }
    Write-Log -Message 'Remove Run Commands Succeeded' -Type 'INFO'
    Disconnect-AzAccount | Out-Null
}
catch 
{
    Write-Log -Message $_ -Type 'ERROR'
    throw
}