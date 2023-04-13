
\copy (
SELECT  adres,
        nr_fabryczny,
        nr_fabryczny_old2023,
        opis,
        uwagi,
        lokalizacja,
        substring(opis FROM '\((.*)\)') AS nakladka

FROM liczniki
WHERE nr_fabryczny <> nr_fabryczny_old2023

OR
        uwagi like 'Niewymieniony%' 
ORDER BY uwagi,najemca )

TO '/home/czarek/Ethos/liczniki/robutka/Wymiana/wynik.csv' WITH CSV;

