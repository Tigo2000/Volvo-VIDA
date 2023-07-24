$exportPath = Read-Host "Enter path to export to" 

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

# Select profile
$selectedProfile = $profiles | Where-Object Title -like 'C30 2008 '

$ecuIdentifiers = Invoke-Sqlcmd @parameters -Query @"
    SELECT p.title, e.identifier as EcuIdentifier, e.name as EcuName, ev.identifier as EcuVariantIdentifier, et.identifier as EcuTypeIdentifier
    FROM [carcom].[dbo].t161_profile p
    INNER JOIN [carcom].[dbo].t160_defaultecuvariant dev on dev.fkt161_profile = p.id
    INNER JOIN [carcom].[dbo].t100_ecuvariant ev on ev.id = dev.fkt100_ecuvariant
    INNER JOIN [carcom].[dbo].t101_ecu e on e.id = ev.fkt101_ecu
    INNER JOIN [carcom].[dbo].T102_EcuType et on et.id = e.fkT102_EcuType
    WHERE p.identifier = '$($selectedProfile.identifier)'
    ORDER BY e.identifier;
"@

foreach($ecu in $ecuIdentifiers){
    $output = $null
    $output = Invoke-Sqlcmd @parameters -Query @"
    SELECT ev.id as EcuID, ev.identifier as EcuIdentifier,b.name as BlockName,b.offset, b.length,bvparent.CompareValue as HexValue,s.definition as Conversion,b.fkT190_Text as TextID,td.data as Text, td2.data as Unit
	FROM [carcom].[dbo].T100_EcuVariant ev 
	INNER JOIN [carcom].[dbo].T144_BlockChild bc ON ev.id = bc.fkT100_EcuVariant 
	INNER JOIN [carcom].[dbo].T141_Block b ON bc.fkT141_Block_Child = b.id
	INNER JOIN [carcom].[dbo].T150_blockvalue bv on b.id = bv.fkT141_block 
	INNER JOIN [carcom].[dbo].T141_block bparent on bc.fkT141_Block_Parent = bparent.id
	INNER JOIN [carcom].[dbo].T150_blockvalue bvparent on bparent.id = bvparent.fkt141_block
	INNER JOIN [carcom].[dbo].T155_Scaling s on s.id = bv.fkT155_Scaling
	INNER JOIN [carcom].[dbo].T191_TextData td on td.fkT190_Text = b.fkT190_Text AND td.fkT193_Language = 19
	INNER JOIN [carcom].[dbo].T191_TextData td2 on td2.fkT190_Text = bv.fkT190_Text_ppeUnit AND td2.fkT193_Language = 19
	WHERE ev.identifier = '$($ecu.EcuVariantIdentifier)' AND NOT td.data = '' AND NOT b.name = 'As usage only' AND NOT bvparent.CompareValue = ''
	Order by td.data
"@

    if($output){
        $output | Export-Csv -path $($exportPath+"\"+$ecu.EcuIdentifier + " - " + $ecu.EcuVariantIdentifier + ".csv") -NoTypeInformation -Encoding UTF8
    }
}

# Use this script to get all (CAN values) parameters for a specific car. This script will create a seperate CSV file for every ECU.