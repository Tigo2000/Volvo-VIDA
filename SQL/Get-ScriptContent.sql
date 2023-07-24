SELECT * FROM [DiagSwdlRepository].[dbo].ScriptContent scriptcontent
INNER JOIN [DiagSwdlRepository].[dbo].Script s ON s.Id = scriptcontent.fkScript
INNER JOIN [DiagSwdlRepository].[dbo].scriptProfileMap spm ON spm.fkScript = s.id 
INNER JOIN [DiagSwdlRepository].[dbo].ScriptType st on s.fkScriptType = st.Id
INNER JOIN [carcom].[dbo].[T161_Profile] p on p.identifier = spm.fkProfile
WHERE fkLanguage = 15 AND fkProfile = '0b00c8af83aff6b3'
ORDER BY DisplayText