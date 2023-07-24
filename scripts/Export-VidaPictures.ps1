$path = Read-Host "Enter path to export to"

if(!$credential){
    $credential = Get-Credential
}  

$parameters = @{
    ServerInstance = '127.0.0.1'
    Credential = $credential 
    TrustServerCertificate = $true
    MaxBinaryLength = 10000000
}

$results = Invoke-Sqlcmd @parameters -Query "SELECT TOP (100000) * FROM [imagerepository].[dbo].[LocalizedGraphics]" 

foreach($row in $results){
    Write-Host "Working on $($row.path)"
    $file = "$($path)\$($row.path)"

    try{
        [System.IO.File]::WriteAllBytes($file, $row.imageData)
        Write-Host "File created: $file"
    } 
    catch{
        Write-Host "An error occurred: $_"
        throw;
    } 
}

# Use this script to export all images from vida (compressed) to local disk.