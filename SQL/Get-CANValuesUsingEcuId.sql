SELECT ev.id as EcuID,
	ev.identifier as EcuIdentifier,
	b.name as BlockName,b.offset,
	b.length,bvparent.CompareValue as HexValue,
	s.definition as Conversion,
	b.fkT190_Text as TextID,
	bt.identifier as RequestType,
	td.data as Text,
	td2.data as Unit
FROM [carcom].[dbo].T100_EcuVariant ev 
	INNER JOIN [carcom].[dbo].T144_BlockChild bc ON ev.id = bc.fkT100_EcuVariant 
	INNER JOIN [carcom].[dbo].T141_Block b ON bc.fkT141_Block_Child = b.id
	INNER JOIN [carcom].[dbo].T150_blockvalue bv on b.id = bv.fkT141_block 
	INNER JOIN [carcom].[dbo].T141_block bparent on bc.fkT141_Block_Parent = bparent.id
	INNER JOIN [carcom].[dbo].T150_blockvalue bvparent on bparent.id = bvparent.fkt141_block
	INNER JOIN [carcom].[dbo].T142_BlockType bt on bt.id = bparent.fkT142_BlockType
	INNER JOIN [carcom].[dbo].T155_Scaling s on s.id = bv.fkT155_Scaling
	INNER JOIN [carcom].[dbo].T191_TextData td on td.fkT190_Text = b.fkT190_Text AND td.fkT193_Language = 19
	INNER JOIN [carcom].[dbo].T191_TextData td2 on td2.fkT190_Text = bv.fkT190_Text_ppeUnit AND td2.fkT193_Language = 19
WHERE ev.id = '1310' AND NOT td.data = '' AND NOT b.name = 'As usage only' AND NOT bvparent.CompareValue = ''
ORDER BY td.data

/* This script will show all parameters for a given ECU (ev.id), containing CAN parameter values */