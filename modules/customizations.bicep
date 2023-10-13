targetScope = 'resourceGroup'

param containerName string
param customizations array
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
param location string
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param storageAccountName string
param storageEndpoint string
param tags object
param teamsInstaller string
param userAssignedIdentityObjectId string
param vcRedistInstaller string
param vDotInstaller string
param virtualMachineName string

var installAccessVar = '${installAccess}installAccess'
var installers = customizations
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

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: virtualMachineName
}

@batchSize(1)
resource applications 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = [for installer in installers: {
  parent: virtualMachine
  name: 'app-${installer.name}'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
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
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
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
}]

resource office 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = if (installAccess || installExcel || installOneDriveForBusiness || installOneNote || installOutlook || installPowerPoint || installPublisher || installSkypeForBusiness || installWord || installVisio || installProject) {
  parent: virtualMachine
  name: 'office'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
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
      $ErrorActionPreference = 'Stop'
      $WarningPreference = 'SilentlyContinue'
      $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
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

resource vdot 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = if (installVirtualDesktopOptimizationTool) {
  parent: virtualMachine
  name: 'vdot'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
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
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        $ZIP = "$env:windir\temp\VDOT.zip"
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $ZIP
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp
        Unblock-File -Path $ZIP
        Expand-Archive -LiteralPath $ZIP -DestinationPath "$env:windir\temp" -Force
        $Path = (Get-ChildItem -Path "$env:windir\temp" -Recurse | Where-Object {$_.Name -eq "Windows_VDOT.ps1"}).FullName
        $Script = Get-Content -Path $Path
        $ScriptUpdate = $Script.Replace("Set-NetAdapterAdvancedProperty","#Set-NetAdapterAdvancedProperty")
        $ScriptUpdate | Set-Content -Path $Path
        & $Path -Optimizations @("AppxPackages","Autologgers","DefaultUserSettings","LGPO";"NetworkOptimizations","ScheduledTasks","Services","WindowsMediaPlayer") -AdvancedOptimizations "All" -AcceptEULA
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

// resource fslogix 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = if (installFsLogix) {
//   parent: virtualMachine
//   name: 'fslogix'
//   location: location
//   tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
//   properties: {
//     treatFailureAsDeploymentFailure: true
//     asyncExecution: false
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

resource teams 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = if (installTeams) {
  parent: virtualMachine
  name: 'teams'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
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
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName,
        [string]$BlobName2,
        [string]$BlobName3
      )
      $ErrorActionPreference = 'Stop'
      $WarningPreference = 'SilentlyContinue'
      $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
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
