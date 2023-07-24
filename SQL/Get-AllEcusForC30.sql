SELECT ecu.identifier as EcuIdentifier, ecu.name as EcuName ,ecuv.identifier as EcuVariantIdentifier, et.identifier as EcuTypeIdentifier
    FROM [carcom].[dbo].t161_profile p
    INNER JOIN [carcom].[dbo].t160_defaultecuvariant dev on dev.fkt161_profile = p.id
    INNER JOIN [carcom].[dbo].t100_ecuvariant ecuv on ecuv.id = dev.fkt100_ecuvariant
    INNER JOIN [carcom].[dbo].t101_ecu ecu on ecu.id = ecuv.fkt101_ecu
    INNER JOIN [carcom].[dbo].T102_EcuType et on et.id = ecu.fkT102_EcuType
	WHERE p.identifier = '0b00c8af83aff6b3' /* C30 Identifier */
	ORDER BY et.identifier

/* This script will show all ECUs in a given vehicle */