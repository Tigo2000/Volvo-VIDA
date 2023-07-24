SELECT * FROM [DiagSwdlRepository].[dbo].[IE] ie
  INNER JOIN [DiagSwdlRepository].[dbo].IEProfileMap ON IE.Id = IEProfileMap.fkIE
  INNER JOIN [DiagSwdlRepository].[dbo].IETitle ON IE.Id = IETitle.fkIE
  INNER JOIN [servicerep_en-US].[dbo].[Document] d on d.vccNumber = ie.VCCId
  WHERE ie.id = '0900c8af819336ae' AND fkLanguage = 15

  /* This script will show the Compressed XML data for the VCC document with ie.id as listed */