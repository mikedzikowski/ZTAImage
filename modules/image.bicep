targetScope = 'resourceGroup'

param containerName string
param installAccess bool
param installExcel bool
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
param customizations array
param vDotInstaller string
param officeInstaller string
param teamsInstaller string
param vcRedistInstaller string
param msrdcwebrtcsvcInstaller string

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

// automatically add arguments element to any customization that doesn't have one from UI. Prevents error.
var installers = [for customization in customizations: {
  name: customization.name
  blobName: customization.blobName
  arguments: contains(customization, 'arguments') ? customization.arguments : ''
} ]

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: vmName
}

@batchSize(1)
resource applications 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [for installer in installers : {
  name: 'app-${installer.name}'
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
        value: installer.blobName
      }
      {
        name: 'Installer'
        value: installer.name
      }
      {
        name: 'Arguments'
        value: installer.arguments
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
        [string]$Installer,
        [string]$Arguments
        )
        $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
        $StorageAccountName = $StorageAccountName
        $ContainerName = $ContainerName
        $BlobName = $BlobName
        $StorageAccountUrl = $StorageEndpoint
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        New-Item -Path $env:windir\temp -Name $Installer -ItemType "directory" -Force
        New-Item -Path $env:windir\temp\$Installer -Name 'Files' -ItemType "directory" -Force
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $env:windir\temp\$Installer\Files\$Blobname
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp\$Installer
        if($Blobname -like ("*.exe"))
        {
          Start-Process -FilePath $env:windir\temp\$Installer\Files\$Blobname -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
          $status = Get-WmiObject -Class Win32_Product | Where-Object Name -like "*$($installer)*"
          if($status)
          {
            Write-Host $status.Name "is installed"
          }
          else
          {
            Write-host $Installer "did not install properly, please check arguments"
          }
        }
        if($Blobname -like ("*.msi"))
        {
          Set-Location -Path $env:windir\temp\$Installer\Files
          Start-Process -FilePath msiexec.exe -ArgumentList $Arguments -Wait
          $status = Get-WmiObject -Class Win32_Product | Where-Object Name -like "*$($installer)*"
          if($status)
          {
            Write-Host $status.Name "is installed"
          }
          else
          {
            Write-host $Installer "did not install properly, please check arguments"
          }
        }
        if($Blobname -like ("*.bat"))
        {
          Start-Process -FilePath cmd.exe -ArgumentList $env:windir\temp\$Installer\Files\$Arguments -Wait
        }
        if($Blobname -like ("*.ps1"))
        {
          Start-Process -FilePath PowerShell.exe -ArgumentList $env:windir\temp\$Installer\Files\$Arguments -Wait
        }
        if($Blobname -like ("*.zip"))
        {
          Set-Location -Path $env:windir\temp\$Installer\Files
          Expand-Archive -Path $env:windir\temp\$Installer\Files\$Blobname -DestinationPath $env:windir\temp\$Installer\Files -Force
          Remove-Item -Path .\$Blobname -Force -Recurse 
        }
      '''
    }
  }
  dependsOn:[]
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
        name: 'BlobName'
        value: officeInstaller
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
      [string]$InstallPowerPoint,
      [string]$UserAssignedIdentityObjectId,
      [string]$StorageAccountName,
      [string]$ContainerName,
      [string]$StorageEndpoint,
      [string]$BlobName
      )
      $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
      $StorageAccountName = $StorageAccountName
      $ContainerName = $ContainerName
      $BlobName = $BlobName
      $StorageAccountUrl = $StorageEndpoint
      $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
      $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
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
      #$DownloadLinks = Invoke-WebRequest -Uri "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117" -UseBasicParsing
      #$URL = $DownloadLinks.Links.href | Where-Object {$_ -like "https://download.microsoft.com/download/*officedeploymenttool*"} | Select-Object -First 1
      #Invoke-WebRequest -Uri $URL -OutFile $Installer -UseBasicParsing
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $Installer
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
        name: 'BlobName'
        value: vDotInstaller
      }
    ]
    source: {
      script: '''
      param(
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName
        )
        $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
        $StorageAccountName = $StorageAccountName
        $ContainerName = $ContainerName
        $BlobName = $BlobName
        $StorageAccountUrl = $StorageEndpoint
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        $ZIP = "$env:windir\temp\VDOT.zip"
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $ZIP
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp
        $ErrorActionPreference = "Stop"
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
    applications
    office
  ]
}

// resource fslogix 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = if (installFsLogix) {
//   name: 'fslogix'
//   location: location
//   parent: vm
//   properties: {
//     source: {
//       script: '''
//       $ErrorActionPreference = "Stop"
//       $ZIP = "$env:windir\temp\fslogix.zip"
//       Invoke-WebRequest -Uri "https://aka.ms/fslogix_download" -OutFile $ZIP
//       Unblock-File -Path $ZIP
//       Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp\fslogix" -Force
//       Write-Host "Downloaded the latest version of FSLogix"
//       $ErrorActionPreference = "Stop"
//       Start-Process -FilePath "$env:windir\temp\fslogix\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait -PassThru | Out-Null
//       Write-Host "Installed the latest version of FSLogix"
//       '''
//     }
//     timeoutInSeconds: 640
//   }
//   dependsOn: [
//     applications
//     teams
//     office
//   ]
// }

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
        name: 'BlobName'
        value: teamsInstaller
      }
      {
        name: 'BlobName2'
        value: vcRedistInstaller
      }
      {
        name: 'BlobName3'
        value: msrdcwebrtcsvcInstaller
      }
    ]
    source: {
      script: '''
      param(
        [string]$TenantType,
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName,
        [string]$BlobName2,
        [string]$BlobName3
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
      $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
      $StorageAccountName = $StorageAccountName
      $ContainerName = $ContainerName
      $BlobName = $BlobName
      $StorageAccountUrl = $StorageEndpoint
      $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
      $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
      $vcRedistFile = "$env:windir\temp\vc_redist.x64.exe"
      $webSocketFile = "$env:windir\temp\webSocketSvc.msi"
      $teamsFile = "$env:windir\temp\teams.msi"
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $teamsFile
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName2" -OutFile $vcRedistFile
      Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName3" -OutFile  $webSocketFile

      # Enable media optimizations for Team
      Start-Process "reg" -ArgumentList "add HKLM\SOFTWARE\Microsoft\Teams /v IsWVDEnvironment /t REG_DWORD /d 1 /f" -Wait -PassThru -ErrorAction "Stop"
      Write-Host "Enabled media optimizations for Teams"
      # Download & install the latest version of Microsoft Visual C++ Redistributable
      $ErrorActionPreference = "Stop"
      #$File = "$env:windir\temp\vc_redist.x64.exe"
      #Invoke-WebRequest -Uri "https://aka.ms/vs/16/release/vc_redist.x64.exe" -OutFile $File
      Start-Process -FilePath  $vcRedistFile -Args "/install /quiet /norestart /log vcdist.log" -Wait -PassThru | Out-Null
      Write-Host "Installed the latest version of Microsoft Visual C++ Redistributable"
      # Download & install the Remote Desktop WebRTC Redirector Service
      $ErrorActionPreference = "Stop"
      #$File = "$env:windir\temp\webSocketSvc.msi"
      #Invoke-WebRequest -Uri "https://aka.ms/msrdcwebrtcsvc/msi" -OutFile $File
      Start-Process -FilePath msiexec.exe -Args "/i  $webSocketFile /quiet /qn /norestart /passive /log webSocket.log" -Wait -PassThru | Out-Null
      Write-Host "Installed the Remote Desktop WebRTC Redirector Service"
      # Install Teams
      $ErrorActionPreference = "Stop"
      #$File = "$env:windir\temp\teams.msi"
      #Write-host $($TeamsUrl)
      #Invoke-WebRequest -Uri "$TeamsUrl" -OutFile $File
      $sku = (Get-ComputerInfo).OsName
      $PerMachineConfiguration = if(($Sku).Contains("multi") -eq "true"){"ALLUSER=1"}else{""}
      Start-Process -FilePath msiexec.exe -Args "/i $teamsFile /quiet /qn /norestart /passive /log teams.log $PerMachineConfiguration ALLUSERS=1" -Wait -PassThru | Out-Null
      Write-Host "Installed Teams"
      '''
    }
  }
  dependsOn: [
    applications
    office
  ]
}

resource microsoftUpdate 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'microsoftUpdate'
  location: location
  parent: vm
  properties: {
      asyncExecution: false
      parameters: []
      source: {
          script: '''
              param (
                  # The App Name to pass to the WUA API as the calling application.
                  [Parameter()]
                  [String]$AppName = "Windows Update API Script",
                  # The search criteria to be used.
                  [Parameter()]
                  [String]$Criteria = "IsInstalled=0 and Type='Software' and IsHidden=0",
                  [Parameter()]
                  [bool]$ExcludePreviewUpdates = $true,
                  # Default service (WSUS if machine is configured to use it, or MU if opted in, or WU otherwise.)
                  [Parameter()]
                  [ValidateSet("WU","MU","WSUS","DCAT","STORE","OTHER")]
                  [string]$Service = 'MU',
                  # The http/https fqdn for the Windows Server Update Server
                  [Parameter()]
                  [string]$WSUSServer
              )
              
              Function ConvertFrom-InstallationResult {
              [CmdletBinding()]
                  param (
                      [Parameter()]
                      [int]$Result
                  )
              
                  switch ($Result) {
                      2 { $Text = 'Succeeded' }
                      3 { $Text = 'Succeeded with errors' }
                      4 { $Text = 'Failed' }
                      5 { $Text = 'Cancelled' }
                      Default { $Text = "Unexpected ($Result)"}
                  }
              
                  Return $Text
              }
              
              $ExitCode = 0
              
              Switch ($Service.ToUpper()) {
                  'WU' { $ServerSelection = 2 }
                  'MU' { $ServerSelection = 3; $ServiceId = "7971f918-a847-4430-9279-4a52d1efe18d" }
                  'WSUS' { $ServerSelection = 1 }
                  'DCAT' { $ServerSelection = 3; $ServiceId = "855E8A7C-ECB4-4CA3-B045-1DFA50104289" }
                  'STORE' { $serverSelection = 3; $ServiceId = "117cab2d-82b1-4b5a-a08c-4d62dbee7782" }
                  'OTHER' { $ServerSelection = 3; $ServiceId = $Service }
              }
              
              If ($Service -eq 'MU') {
                  $UpdateServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
                  $UpdateServiceManager.ClientApplicationID = $AppName
                  $UpdateServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")
                  $null = cmd /c reg.exe ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AllowMUUpdateService /t REG_DWORD /d 1 /f '2>&1'
                  Write-Output "Added Registry entry to configure Microsoft Update. Exit Code: [$LastExitCode]"
              } Elseif ($Service -eq 'WSUS' -and $WSUSServer) {
                  $null = cmd /c reg.exe ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUServer /t REG_SZ /d $WSUSServer /f '2>&1'
                  $null = cmd /c reg.exe ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUStatusServer /t REG_SZ /d $WSUSServer /f '2>&1'
                  Write-Output "Added Registry entry to configure WSUS Server. Exit Code: [$LastExitCode]"
              }
              
              $UpdateSession = New-Object -ComObject Microsoft.Update.Session
              $updateSession.ClientApplicationID = $AppName
                  
              $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
              $UpdateSearcher.ServerSelection = $ServerSelection
              If ($ServerSelection -eq 3) {
                  $UpdateSearcher.ServiceId = $ServiceId
              }
              
              Write-Output "Searching for Updates..."
              
              $SearchResult = $UpdateSearcher.Search($Criteria)
              If ($SearchResult.Updates.Count -eq 0) {
                  Write-Output "There are no applicable updates."
                  Write-Output "Now Exiting"
                  Exit $ExitCode
              }
              
              Write-Output "List of applicable items found for this computer:"
              
              For ($i = 0; $i -lt $SearchResult.Updates.Count; $i++) {
                  $Update = $SearchResult.Updates[$i]
                  Write-Output "$($i + 1) > $($update.Title)"
              }
              
              $AtLeastOneAdded = $false
              $ExclusiveAdded = $false   
              $UpdatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
              Write-Output "Checking search results:"
              For ($i = 0; $i -lt $SearchResult.Updates.Count; $i++) {
                  $Update = $SearchResult.Updates[$i]
                  $AddThisUpdate = $false
              
                  If ($ExclusiveAdded) {
                      Write-Output "$($i + 1) > skipping: '$($update.Title)' because an exclusive update has already been selected."
                  } Else {
                      $AddThisUpdate = $true
                  }
              
                  if ($ExcludePreviewUpdates -and $update.Title -like '*Preview*') {
                      Write-Output "$($i + 1) > Skipping: '$($update.Title)' because it is a preview update."
                      $AddThisUpdate = $false
                  }
              
                  If ($AddThisUpdate) {
                      $PropertyTest = 0
                      $ErrorActionPreference = 'SilentlyContinue'
                      $PropertyTest = $Update.InstallationBehavior.Impact
                      $ErrorActionPreference = 'Stop'
                      If ($PropertyTest -eq 2) {
                          If ($AtLeastOneAdded) {
                              Write-Output "$($i + 1) > skipping: '$($update.Title)' because it is exclusive and other updates are being installed first."
                              $AddThisUpdate = $false
                          }
                      }
                  }
              
                  If ($AddThisUpdate) {
                      Write-Output "$($i + 1) > adding: '$($update.Title)'"
                      $UpdatesToDownload.Add($Update) | out-null
                      $AtLeastOneAdded = $true
                      $ErrorActionPreference = 'SilentlyContinue'
                      $PropertyTest = $Update.InstallationBehavior.Impact
                      $ErrorActionPreference = 'Stop'
                      If ($PropertyTest -eq 2) {
                          Write-Output "This update is exclusive; skipping remaining updates"
                          $ExclusiveAdded = $true
                      }
                  }
              }
              
              $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
              Write-Output "Downloading updates..."
              $Downloader = $UpdateSession.CreateUpdateDownloader()
              $Downloader.Updates = $UpdatesToDownload
              $Downloader.Download()
              Write-Output "Successfully downloaded updates:"
              
              For ($i = 0; $i -lt $UpdatesToDownload.Count; $i++) {
                  $Update = $UpdatesToDownload[$i]
                  If ($Update.IsDownloaded -eq $true) {
                      Write-Output "$($i + 1) > $($update.title)"
                      $UpdatesToInstall.Add($Update) | out-null
                  }
              }
              
              If ($UpdatesToInstall.Count -gt 0) {
                  $Installer = $UpdateSession.CreateUpdateInstaller()
                  $Installer.Updates = $UpdatesToInstall
                  $InstallationResult = $Installer.Install()
                  $Text = ConvertFrom-InstallationResult -Result $InstallationResult.ResultCode
                  Switch ($InstallationResult.ResultCode) {
                      2 { $Code = 0 }
                      3 { $Code = 3 }
                      4 { $Code = 4 }
                      5 { $Code = 5}
                      Else { $Code = 99 }
                  } 
                  Write-Output "Installation Result: $($Text)"
              
                  If ($InstallationResult.RebootRequired) {
                      $ExitCode = 1641
                      Write-Output "Atleast one update requires a reboot to complete the installation."
                  }
              
                  If ($ExitCode -ne 1641 -and $ExitCode -ne 4) {
                      $ExitCode = $Code
                  }
              }
              If ($service -eq 'MU') {
                  Reg.exe DELETE "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AllowMUUpdateService /f
              } Elseif ($Service -eq 'WSUS' -and $WSUSServer) {
                  reg.exe DELETE "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUServer /f
                  reg.exe DELETE "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v WUStatusServer /f
              }
              Exit $ExitCode    
          '''
      }
  }
  dependsOn: [
    applications
    office
    teams
    vdot
  ]
}

output TenantType string = TenantType
