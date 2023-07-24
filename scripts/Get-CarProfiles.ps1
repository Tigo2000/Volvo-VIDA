if(!$credential){
    $credential = Get-Credential
} 

$parameters = @{
    ServerInstance = '127.0.0.1'
    Credential = $credential 
    TrustServerCertificate = $true
    MaxBinaryLength = 10000000
}

$profiles = Invoke-Sqlcmd @parameters -Query @"
SELECT pr.id, pr.title, pv.description as year, pr.identifier
FROM [carcom].[dbo].T161_Profile pr
INNER JOIN [carcom].[dbo].T162_ProfileValue pv on pv.id = pr.fkT162_ProfileValue_Year
WHERE folderLevel = '2' /* AND pv.description = '2008' */
ORDER BY pr.title; 
"@

$profiles | Format-Table
$profiles | Where-Object year -eq '2008' |  Format-Table

# This script shows all identifiers for all the vehicles in VIDA. 
