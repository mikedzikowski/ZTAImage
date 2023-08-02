param(
    [string]$UserAssignedIdentityObjectId,
    [string]$StorageAccountName,
    [string]$ContainerName
    )
try
{
    $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
    $StorageAccountName = $StorageAccountName
    $ContainerName = $ContainerName
    $BlobName = 'New-PepareVHDToUploadToAzure.ps1'
    $StorageAccountUrl = 'https://' + $StorageAccountName + '.blob.core.usgovcloudapi.net'
    $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl/&object_id=$UserAssignedIdentityObjectId"
    $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
    Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl/$ContainerName/$BlobName" -OutFile $env:windir\temp\$BlobName
    Start-Sleep -Seconds 60
    Set-Location -Path $env:windir\temp
    .\New-PepareVHDToUploadToAzure.ps1
}
catch
{
    Write-Host "An error occurred:"
    Write-Host $_
}

