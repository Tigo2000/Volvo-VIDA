Function Get-ValidCharacter($Path){ 
    $chars = "\\","\/","\?","\*","\:","\<","\>"
    foreach($char in $chars){
        $path = $path -replace "$char","_"
    }

    return $path
}

Function New-Folder($Path, $Name){
    $fullPath = $path+"\"+$name
    
    if(!(Test-Path $fullPath)){
        New-Item -Path $path -Name $name -ItemType Directory -Force
    }
}

$scriptsFolder = Read-Host "Enter path to export to" 

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
    WHERE folderLevel = '2'
    ORDER BY pr.title; 
"@

$car = Read-Host "Enter car model (example: C30)"
# C30 profile = 0b00c8af83aff6b3
$profiles = $profiles | Where-Object 'title' -Match $car
$profiles | Format-Table

Pause

foreach($selectedProfile in $profiles){
    $profileTitle = $selectedProfile.title.Trim()
    New-Folder -Path $scriptsFolder -Name $($profileTitle + " - $($selectedProfile.identifier)")
    $ScriptsFolderProfile = $scriptsFolder+"\"+$profileTitle+" - $($selectedProfile.identifier)"

    New-Folder -Path $ScriptsFolderProfile -Name "unzipped"
    New-Folder -Path $ScriptsFolderProfile -Name "zipped"

#     $ecuIdentifiers = Invoke-Sqlcmd @parameters -Query @"
#         SELECT ecuv.identifier as ECUVariantIdentifier, ecu.*, et.identifier as EcuID
#         FROM [carcom].[dbo].t161_profile p
#         INNER JOIN [carcom].[dbo].t160_defaultecuvariant dev on dev.fkt161_profile = p.id
#         INNER JOIN [carcom].[dbo].t100_ecuvariant ecuv on ecuv.id = dev.fkt100_ecuvariant
#         INNER JOIN [carcom].[dbo].t101_ecu ecu on ecu.id = ecuv.fkt101_ecu
#         INNER JOIN [carcom].[dbo].T102_EcuType et on et.id = ecu.fkT102_EcuType
#         WHERE p.identifier = '$($selectedProfile.identifier)'
#         ORDER BY ecu.identifier;
# "@

    $scripts = Invoke-Sqlcmd @parameters -Query @"
        SELECT fkScript
        FROM [DiagSwdlRepository].[dbo].[ScriptProfileMap]
        WHERE fkProfile = '$($selectedProfile.identifier)'
"@

    $scriptContent = @()
    $scriptContent = foreach($script in $scripts){
        Invoke-Sqlcmd @parameters -query @"
            SELECT scriptcontent.fkScript, DisplayText, XmlDataCompressed
            FROM [DiagSwdlRepository].[dbo].ScriptContent scriptcontent	
            INNER JOIN [DiagSwdlRepository].[dbo].Script s ON s.Id = scriptcontent.fkScript
            WHERE s.id = '$($script.fkScript)' AND scriptcontent.fkLanguage = 15
"@
    }

    $errors = @()
    foreach($entry in $scriptContent){    
        Write-Host "[$($profileTitle)]: Working on $($entry.fkScript)"
        if($entry.XmlDataCompressed){
            [System.IO.File]::WriteAllBytes($ScriptsFolderProfile+"\zipped\$($entry.fkScript).zip", $entry.XmlDataCompressed)
        }

        if(Test-Path -Path $($ScriptsFolderProfile+"\zipped\$($entry.fkScript).zip")){
            # Unzip archive
            try{Expand-Archive -Path $($ScriptsFolderProfile+"\zipped\$($entry.fkScript).zip") -DestinationPath $($ScriptsFolderProfile+"\unzipped") -Force -ErrorAction Stop}
            catch{
                $errors += [pscustomobject]@{
                    Profile = $selectedProfile.title
                    Action = "Unzipping archive"
                    Script = $entry.fkScript
                    Entry = $entry.DisplayText
                    "Error" = $Error[0]
                }
            }

            # Rename item
            Rename-Item -Path $($ScriptsFolderProfile+"\unzipped\$($entry.fkScript)") -NewName "$(Get-ValidCharacter -Path $entry.DisplayText) ($($entry.fkScript)).xml"
        }
    }

    # CleanUp
    #Remove-Item -path $($ScriptsFolderProfile+"\unzipped") -Recurse -Confirm:$true
}