$scriptsFolder = Read-Host "Enter path to unzipped XML files" 

if(!$credential){
    $credential = Get-Credential
} 

$parameters = @{
    ServerInstance = '127.0.0.1'
    Credential = $credential 
    TrustServerCertificate = $true
    MaxBinaryLength = 10000000
}

$selectedProfile = ($scriptsfolder -split '\\' | Select-Object -SkipLast 1 | Select-Object -Last 1) -split ' - ' | Select-Object -Last 1 

$ecuIdentifiers = Invoke-Sqlcmd @parameters -Query @"
    SELECT ecu.identifier as EcuIdentifier, ecu.name as EcuName ,ecuv.identifier as EcuVariantIdentifier, et.identifier as EcuTypeIdentifier
    FROM [carcom].[dbo].t161_profile p
    INNER JOIN [carcom].[dbo].t160_defaultecuvariant dev on dev.fkt161_profile = p.id
    INNER JOIN [carcom].[dbo].t100_ecuvariant ecuv on ecuv.id = dev.fkt100_ecuvariant
    INNER JOIN [carcom].[dbo].t101_ecu ecu on ecu.id = ecuv.fkt101_ecu
    INNER JOIN [carcom].[dbo].T102_EcuType et on et.id = ecu.fkT102_EcuType
    WHERE p.identifier = '$($selectedProfile)'
    ORDER BY ecu.identifier;
"@

if(Test-Path -Path $scriptsFolder){
    $xmlScripts = Get-ChildItem -Path $scriptsFolder -Filter "*.xml"

    $xmlScriptsOutput = @()
    $xmlScriptsOutput = foreach($xmlScript in $xmlScripts){
        [xml]$xmlContent = Get-Content -Path $xmlScript.FullName

        if($xmlContent){
            foreach($node in $xmlcontent.script.content.nodes.node){
                if($node.class -eq 'Components.IdentifierComponent'){
                    foreach($parameter in $node.extension.identifier.parameter){
                        [PSCustomObject]@{
                            XmlScript = $xmlScript.Name
                            ExtensionID = $node.extension.Id
                            Ecu = $node.extension.identifier.ecu
                            EcuIdentifier = $ecuIdentifiers | Where-Object EcuTypeIdentifier -eq $node.extension.identifier.ecu | Select-Object -ExpandProperty EcuIdentifier 
                            #EcuName = $ecuIdentifiers | Where-Object EcuTypeIdentifier -eq $node.extension.identifier.ecu | Select-Object -ExpandProperty EcuName
                            EcuType = $node.extension.identifier.ecuMode
                            Read = $node.extension.identifier.read
                            Type = $node.extension.identifier.type
                            Value = $node.extension.identifier.value
                            ParameterName = $parameter.name 
                        }
                    }
                }
            }
        }
    }
}
$xmlScriptsoutput | sort-object ParameterName | sort-object ecuidentifier | Format-Table

$export = Read-Host "Export to CSV? (y/n)"

if($export -eq 'y' -or $export -eq 'Y'){
    $xmlScriptsOutput | Export-Csv -Path $($scriptsFolder+"\_Output.csv") -NoTypeInformation -Encoding UTF8 
    Write-Host "Exported to $($scriptsFolder+"\_Output.csv")"
    Start-Process "$($scriptsFolder+"\_Output.csv")"
}