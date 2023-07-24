$path = Read-Host "Enter path to unzipped XML files"

$files = Get-ChildItem -Path $path -Recurse -Filter "*.xml"

$output = foreach($file in $files){
    Write-Host "Working on $($file.FullName)"
    
    # Read XML file
    [xml]$xmlContent = Get-Content -Path $file.FullName

    if($xmlContent){
        foreach($node in $xmlcontent.script.content.nodes.node){
            if($node.class -eq 'Components.IdentifierComponent'){
                foreach($parameter in $node.extension.identifier.parameter){
                    [PSCustomObject]@{
                        Ecu = $node.extension.identifier.ecu
                        EcuType = $node.extension.identifier.ecuMode
                        Read = $node.extension.identifier.read
                        RequestType = $node.extension.identifier.type
                        Value = $node.extension.identifier.value
                        ParameterName = $parameter.name 
                        ExtensionID = $node.extension.Id
                        ScriptName = $file.FullName
                    }
                }
            }
        }
    }
}   

# Get amount of unique ecu scripts
$result = @{}
$output | foreach-object{ $result["$($_.ecu)"] += 1}
$result.GetEnumerator() | sort-object value -Descending

# Show all scripts for ECM C30 T5
$output | where-object Ecu -eq '284101' | Sort-Object ParameterName -Unique | Sort-Object ParameterName | Format-Table