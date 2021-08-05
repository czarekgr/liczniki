
-- Funkcja oblicza zużycie miesięczne dla konkretnego licznika i daty

CREATE OR REPLACE FUNCTION zuzycie(adr varchar, dt date) RETURNS decimal(10,3) AS $$
DECLARE
	wynik decimal(10,3);

BEGIN
	wynik := (SELECT odczyt FROM odczyty WHERE data = dt AND adres=adr)
       		 - (SELECT odczyt FROM odczyty WHERE data =dt-interval '1 month'  AND adres=adr);	
	RETURN wynik;
END;
$$ LANGUAGE plpgsql;






CREATE OR REPLACE FUNCTION srednia(adr varchar, dt date, okres int default 12) RETURNS decimal(10,3) AS $$
DECLARE
	wynik decimal(10,3);
	dt_start date;

BEGIN

	dt_start = dt-(concat(okres,' month')::interval);
	wynik := ((SELECT odczyt FROM odczyty WHERE data = dt AND adres=adr)
       		 - (SELECT odczyt FROM odczyty WHERE data =dt_start  AND adres=adr))/okres;	
	RETURN wynik;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE VIEW wyniki AS 
 SELECT kolejnosc,
	data,
	adres,
	nr_fabryczny,
	odczyt,
	jednostka,
	srednia(adres, data, 1) AS srednia,
	zuzycie(adres, data) AS zuzycie,
	CASE WHEN srednia(adres, data, 1) = 0 THEN 0 
	ELSE 
		(zuzycie(adres, data)-srednia(adres, data, 1))*100/srednia(adres, data, 1)  
	END :: numeric(10,2) AS "wzrost % wzgl. średniej"
	-- Dzielenie przez 0, poprawić
 FROM odczyty
 NATURAL JOIN liczniki
 NATURAL JOIN rodzaje_licz
 ORDER BY data DESC, kolejnosc;








