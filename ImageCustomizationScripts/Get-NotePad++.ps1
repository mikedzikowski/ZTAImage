try
{
    Start-Sleep -Seconds 120
    $UserAssignedIdentityObjectId = '258d3674-d759-4fe1-bddf-13413e16a6a7'
    $StorageAccountName = 'saimageartifacts'
    $ContainerName = 'artifacts'
    $BlobName = 'npp.8.2.1.Installer.exe'
    $StorageAccountUrl = 'https://' + $StorageAccountName + '.blob.core.usgovcloudapi.net'
    $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl/&object_id=$UserAssignedIdentityObjectId"
    $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
    Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl/$ContainerName/$BlobName" -OutFile $env:windir\temp\$BlobName
    Start-Sleep -Seconds 30
    Set-Location -Path $env:windir\temp
    Start-Process -FilePath 'C:\windows\temp\npp.8.2.1.Installer.exe' /S -NoNewWindow -Wait -PassThru
}
catch
{
    Write-Host $_
}
