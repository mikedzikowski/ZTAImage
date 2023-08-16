targetScope = 'resourceGroup'

param containerName string
param installAccess bool
param installExcel bool
param installFsLogix bool
param installOneDriveForBusiness bool
param installOneNote bool
param installOutlook bool
param installPowerPoint bool
param installProject bool
param installPublisher bool
param installSkypeForBusiness bool
param installTeams bool
param installVirtualDesktopOptimizationTool bool
param installVisio bool
param installWord bool
param location string = resourceGroup().location
param storageAccountName string
param storageEndpoint string
param vmName string
@allowed([
  'Commercial'
  'DepartmentOfDefense'
  'GovernmentCommunityCloud'
  'GovernmentCommunityCloudHigh'
])
param TenantType string
param userAssignedIdentityObjectId string

var installAccessVar = '${installAccess}installAccess'
var installExcelVar = '${installExcel}installWord'
var installOneDriveForBusinessVar = '${installOneDriveForBusiness}installOneDrive'
var installOneNoteVar = '${installOneNote}installOneNote'
var installOutlookVar = '${installOutlook}installOutlook'
var installPowerPointVar = '${installPowerPoint}installPowerPoint'
var installProjectVar = '${installProject}installProject'
var installPublisherVar = '${installPublisher}installPublisher'
var installSkypeForBusinessVar = '${installSkypeForBusiness}installSkypeForBusiness'
var installVisioVar = '${installVisio}installVisio'
var installWordVar = '${installWord}installWord'

var exes = [
  {
    name: 'notepad'
    blobName: 'npp.8.2.1.Installer.exe'
    arguments: '/S'
  }
]

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vmName
}

resource applications 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [ for exe in exes: {
  name: 'app-${exe.name}'
  location: location
  parent: vm
  properties: {
    treatFailureAsDeploymentFailure: true
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageEndpoint'
        value: storageEndpoint
      }
      {
        name: 'Blobname'
        value: exe.blobName
      }
      {
        name: 'Arguments'
        value: exe.arguments
      }
    ]
    source: {
      script: '''
      param(
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName,
        [string]$Arguments
        )
        $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
        $StorageAccountName = $StorageAccountName
        $ContainerName = $ContainerName
        $BlobName = $BlobName
        $StorageAccountUrl = 'https://' + $StorageAccountName + $StorageEndpoint
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl/&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl/$ContainerName/$BlobName" -OutFile $env:windir\temp\$BlobName
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp
        Start-Process -FilePath $env:windir\temp\$BlobName -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
      '''
    }
  }
}]

resource office 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = if (installAccess || installExcel || installOneDriveForBusiness || installOneNote || installOutlook || installPowerPoint || installPublisher || installSkypeForBusiness || installWord || installVisio || installProject) {
  name: 'office'
  location: location
  parent: vm
  properties: {
    parameters: [
      {
        name: 'InstallAccess'
        value: installAccessVar
      }
      {
        name: 'InstallWord'
        value: installWordVar
      }
      {
        name: 'InstallExcel'
        value: installExcelVar
      }
      {
        name: 'InstallOneDriveForBusiness'
        value: installOneDriveForBusinessVar
      }
      {
        name: 'InstallOneNote'
        value: installOneNoteVar
      }
      {
        name: 'InstallOutlook'
        value: installOutlookVar
      }
      {
        name: 'InstallPowerPoint'
        value: installPowerPointVar
      }
      {
        name: 'InstallProject'
        value: installProjectVar
      }
      {
        name: 'InstallPublisher'
        value: installPublisherVar
      }
      {
        name: 'InstallSkypeForBusiness'
        value: installSkypeForBusinessVar
      }
      {
        name: 'InstallVisio'
        value: installVisioVar
      }
    ]
    source: {
      script: '''
      param(
      [string]$InstallAccess,
      [string]$InstallExcel,
      [string]$InstallOneDriveForBusiness,
      [string]$InstallOutlook,
      [string]$InstallProject,
      [string]$InstallPublisher,
      [string]$InstallSkypeForBusiness,
      [string]$InstallVisio,
      [string]$InstallWord,
      [string]$InstallOneNote,
      [string]$InstallPowerPoint
      )
      $sku = (Get-ComputerInfo).OsName
      $o365ConfigHeader = Set-Content "$env:windir\temp\office365x64.xml" '<Configuration><Add OfficeClientEdition="64" Channel="Current">'
      $o365OfficeHeader = Add-Content "$env:windir\temp\office365x64.xml" '<Product ID="O365ProPlusRetail"><Language ID="en-us" /><ExcludeApp ID="Teams"/>'
      if($InstallAccess -notlike '*true*'){
          $excludeAccess = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Access" />'
      }
      if($InstallExcel -notlike '*true*'){
          $excludeExcel = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Excel" />'
      }
      if($InstallOneDriveForBusiness -notlike '*true*'){
          $excludeOneDriveForBusiness = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Groove" />'
      }
      if($InstallOneNote -notlike '*true*'){
          $excludeOneNote = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="OneNote" />'
      }
      if($InstallOutlook -notlike '*true*'){
          $excludeOutlook = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Outlook" />'
      }
      if($InstallPowerPoint -notlike '*true*'){
          $excludePowerPoint = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="PowerPoint" />'
      }
      if($InstallPublisher -notlike '*true*'){
          $excludePublisher = Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Publisher" />'
      }
      if($InstallSkypeForBusiness -notlike '*true*'){
          $excludeSkypeForBusiness= Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Lync" />'
      }
      if($InstallWord -notlike '*true*'){
          $excludeSkypeForBusiness= Add-Content "$env:windir\temp\office365x64.xml" '<ExcludeApp ID="Word" />'
      }
      $addOfficefooter = Add-Content "$env:windir\temp\office365x64.xml" '</Product>'
      if($InstallProject -like '*true*'){
        Add-Content "$env:windir\temp\office365x64.xml" '<Product ID="ProjectProRetail"><Language ID="en-us" /></Product>'
      }
      if($InstallVisio -like '*true*'){
        Add-Content "$env:windir\temp\office365x64.xml" '<Product ID="VisioProRetail"><Language ID="en-us" /></Product>'
      }
      $o365Settings = Add-Content "$env:windir\temp\office365x64.xml" '</Add><Updates Enabled="FALSE" /><Display Level="None" AcceptEULA="TRUE" /><Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>'
      $PerMachineConfiguration = if(($Sku).Contains("multi") -eq "true"){
          $o365SharedActivation = Add-Content "$env:windir\temp\office365x64.xml" '<Property Name="SharedComputerLicensing" Value="1"/>'
      }
      $o365Configfooter = Add-Content "$env:windir\temp\office365x64.xml" '</Configuration>'
      $ErrorActionPreference = "Stop"
      $Installer = "$env:windir\temp\office.exe"
      $DownloadLinks = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117" -UseBasicParsing
      $URL = $DownloadLinks.Links.href | Where-Object {$_ -like "https://download.microsoft.com/download/*officedeploymenttool*"} | Select-Object -First 1
      Invoke-WebRequest -Uri $URL -OutFile $Installer -UseBasicParsing
      Start-Process -FilePath $Installer -ArgumentList "/extract:$env:windir\temp /quiet /passive /norestart" -Wait -PassThru | Out-Null
      Write-Host "Downloaded & extracted the Office 365 Deployment Toolkit"
      Start-Process -FilePath "$env:windir\temp\setup.exe" -ArgumentList "/configure $env:windir\temp\office365x64.xml" -Wait -PassThru -ErrorAction "Stop" | Out-Null
      Write-Host "Installed the selected Office365 applications"
      '''
    }
  }
  dependsOn: [
    applications
  ]
}

resource vdot 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = if (installVirtualDesktopOptimizationTool) {
  name: 'vdot'
  location: location
  parent: vm
  properties: {
    source: {
      script: '''
      $ErrorActionPreference = "Stop"
      $ZIP = "$env:windir\temp\fslogix.zip\VDOT.zip"
      Invoke-WebRequest -Uri "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip" -OutFile $ZIP
      Unblock-File -Path $ZIP
      Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp" -Force
      $Path = (Get-ChildItem -Path "$env:windir\temp" -Recurse | Where-Object {$_.Name -eq "Windows_VDOT.ps1"}).FullName
      $Script = Get-Content -Path $Path
      $ScriptUpdate = $Script.Replace("Set-NetAdapterAdvancedProperty","#Set-NetAdapterAdvancedProperty")
      $ScriptUpdate | Set-Content -Path $Path
      & $Path -Optimizations @("AppxPackages","Autologgers","DefaultUserSettings","LGPO";"NetworkOptimizations","ScheduledTasks","Services","WindowsMediaPlayer") -AdvancedOptimizations "All" -AcceptEULA
      Write-Host "Optimized the operating system using the Virtual Desktop Optimization Tool"
      '''
    }
    timeoutInSeconds: 640
  }
  dependsOn: [
    teams
    fslogix
    applications
    office
  ]
}

resource fslogix 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = if (installFsLogix) {
  name: 'fslogix'
  location: location
  parent: vm
  properties: {
    source: {
      script: '''
      $ErrorActionPreference = "Stop"
      $ZIP = "$env:windir\temp\fslogix.zip"
      Invoke-WebRequest -Uri "https://aka.ms/fslogix_download" -OutFile $ZIP
      Unblock-File -Path $ZIP
      Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp\fslogix" -Force
      Write-Host "Downloaded the latest version of FSLogix"
      $ErrorActionPreference = "Stop"
      Start-Process -FilePath "$env:windir\temp\fslogix\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru | Out-Null
      Write-Host "Installed the latest version of FSLogix"
      '''
    }
    timeoutInSeconds: 640
  }
  dependsOn: [
    applications
    teams
    office
  ]
}

resource teams 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = if (installTeams) {
  name: 'teams'
  location: location
  parent: vm
  properties: {
    parameters: [
      {
        name: 'TenantType'
        value: TenantType
      }
    ]
    source: {
      script: '''
      param(
        [string]$TenantType
        )
      If($TenantType -eq "Commercial")
      {
        $TeamsUrl = "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true"
      }
      If($TenantType -eq "DepartmentOfDefense")
      {
        $TeamsUrl = "https://dod.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true"
      }
      If($TenantType -eq "GovernmentCommunityCloud")
      {
        $TeamsUrl = "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&ring=general_gcc&download=true"
      }
      If($TenantType -eq "GovernmentCommunityCloudHigh")
      {
        $TeamsUrl = "https://gov.teams.microsoft.us/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true"
      }
      Write-Host $($TeamsUrl)
      # Enable media optimizations for Team
      Start-Process "reg" -ArgumentList "add HKLM\SOFTWARE\Microsoft\Teams /v IsWVDEnvironment /t REG_DWORD /d 1 /f" -Wait -PassThru -ErrorAction "Stop"
      Write-Host "Enabled media optimizations for Teams"
      # Download & install the latest version of Microsoft Visual C++ Redistributable
      $ErrorActionPreference = "Stop"
      $File = "$env:windir\temp\vc_redist.x64.exe"
      Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile $File
      Start-Process -FilePath $File -Args "/install /quiet /norestart /log vcdist.log" -Wait -PassThru | Out-Null
      Write-Host "Installed the latest version of Microsoft Visual C++ Redistributable"
      # Download & install the Remote Desktop WebRTC Redirector Service
      $ErrorActionPreference = "Stop"
      $File = "$env:windir\temp\webSocketSvc.msi"
      Invoke-WebRequest -Uri "https://aka.ms/msrdcwebrtcsvc/msi" -OutFile $File
      Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log webSocket.log" -Wait -PassThru | Out-Null
      Write-Host "Installed the Remote Desktop WebRTC Redirector Service"
      # Install Teams
      $ErrorActionPreference = "Stop"
      $File = "$env:windir\temp\teams.msi"
      Write-host $($TeamsUrl)
      Invoke-WebRequest -Uri "$TeamsUrl" -OutFile $File
      $sku = (Get-ComputerInfo).OsName
      $PerMachineConfiguration = if(($Sku).Contains("multi") -eq "true"){"ALLUSER=1"}else{""}
      Start-Process -FilePath msiexec.exe -Args "/i $File /quiet /qn /norestart /passive /log teams.log $PerMachineConfiguration ALLUSERS=1" -Wait -PassThru | Out-Null
      Write-Host "Installed Teams"
      '''
    }
  }
  dependsOn: [
    applications
    office
  ]
}

resource sysprep 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: 'sysprep'
  location: location
  parent: vm
  properties: {
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageEndpoint'
        value: storageEndpoint
      }
    ]
    source: {
      script: '''
    param(
      [string]$UserAssignedIdentityObjectId,
      [string]$StorageAccountName,
      [string]$ContainerName,
      [string]$StorageEndpoint
      )
      $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
      $StorageAccountName = $StorageAccountName
      $ContainerName = $ContainerName
      $BlobName = 'New-PepareVHDToUploadToAzure.ps1'
      $StorageAccountUrl = 'https://' + $StorageAccountName + $StorageEndpoint
      $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl/&object_id=$UserAssignedIdentityObjectId"
      $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl/$ContainerName/$BlobName" -OutFile $env:windir\temp\$BlobName
      Start-Sleep -Seconds 60
      Set-Location -Path $env:windir\temp
      .\New-PepareVHDToUploadToAzure.ps1
      '''
    }
    timeoutInSeconds: 120
  }
  dependsOn: [
    applications
    teams
    vdot
    fslogix
    office
  ]
}

output TenantType string = TenantType
