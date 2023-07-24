SELECT * FROM [carcom].[dbo].T100_EcuVariant ev 
INNER JOIN [carcom].[dbo].T144_BlockChild bc ON ev.id = bc.fkT100_EcuVariant 
INNER JOIN [carcom].[dbo].T141_Block b ON bc.fkT141_Block_Child = b.id
INNER JOIN [carcom].[dbo].t150_blockvalue bv on b.id = bv.fkT141_block 
INNER JOIN [carcom].[dbo].t141_block bparent on bc.fkT141_Block_Parent = bparent.id
INNER JOIN [carcom].[dbo].T142_BlockType bt on bt.id = bparent.fkT142_BlockType
INNER JOIN [carcom].[dbo].t150_blockvalue bvparent on bparent.id = bvparent.fkt141_block
WHERE ev.id = '1310' AND b.fkT190_Text = '4896' AND bvparent.CompareValue LIKE '%10CE'

/* This script will show a single result, containing the CAN parameter value (10CE) to retrieve Intake Air Temperature from ECU 7A (ECM) - C30 */