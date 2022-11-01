SELECT 	data,
	wyniki.adres,
	odczyt,
	zuzycie,
	opis,
	nazwa AS najemca
FROM 	wyniki
JOIN	liczniki
ON 	(wyniki.adres=liczniki.adres)
LEFT JOIN najemcy on najemca=id
WHERE data='2022-11-01'
ORDER BY nazwa;
