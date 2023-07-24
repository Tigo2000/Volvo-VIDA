SELECT ev.id as EcuVariantID,
	ev.identifier as EcuVariantIdentifier,
	e.identifier as EcuId,
	e.name as EcuName,
	et.identifier as EcuTypeIdentifier,
	et.description as EcuTypeDescription
FROM [carcom].[dbo].T100_EcuVariant ev 
	INNER JOIN [carcom].[dbo].T101_Ecu e on e.id = fkT101_Ecu
	INNER JOIN [carcom].[dbo].T102_EcuType et on et.id = e.fkT102_EcuType

	