--
-- PostgreSQL database dump
--

-- Dumped from database version 14.6 (Ubuntu 14.6-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.5 (Ubuntu 14.5-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: srednia(character varying, date, integer); Type: FUNCTION; Schema: public; Owner: czarek
--

CREATE FUNCTION public.srednia(adr character varying, dt date, okres integer DEFAULT 12) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
	wynik decimal(10,3);
	dt_start date;

BEGIN

	dt_start = dt-(concat(okres,' month')::interval);
	wynik := ((SELECT odczyt FROM odczyty WHERE data = dt AND adres=adr)
       		 - (SELECT odczyt FROM odczyty WHERE data =dt_start  AND adres=adr))/okres;	
	RETURN wynik;
END;
$$;


ALTER FUNCTION public.srednia(adr character varying, dt date, okres integer) OWNER TO czarek;

--
-- Name: zuzycie(character varying, date); Type: FUNCTION; Schema: public; Owner: czarek
--

CREATE FUNCTION public.zuzycie(adr character varying, dt date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
	wynik decimal(10,3);

BEGIN
	wynik := (SELECT odczyt FROM odczyty WHERE data = dt AND adres=adr)
       		 - (SELECT odczyt FROM odczyty WHERE data =dt-interval '1 month'  AND adres=adr);	
	RETURN wynik;
END;
$$;


ALTER FUNCTION public.zuzycie(adr character varying, dt date) OWNER TO czarek;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: liczniki; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.liczniki (
    adres character varying NOT NULL,
    nr_fabryczny character varying,
    opis character varying,
    lokalizacja character varying,
    rodzaj character varying(3),
    kolejnosc_pdf integer,
    najemca integer,
    uwagi character varying,
    nr_fabryczny_old2023 character varying,
    podlaczenie character varying
);


ALTER TABLE public.liczniki OWNER TO czarek;

--
-- Name: odczyty; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.odczyty (
    data date NOT NULL,
    adres character varying NOT NULL,
    odczyt double precision
);


ALTER TABLE public.odczyty OWNER TO czarek;

--
-- Name: ordung; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.ordung (
    adres character varying,
    kolejnosc integer,
    kolejnosc_wojtek integer
);


ALTER TABLE public.ordung OWNER TO czarek;

--
-- Name: rodzaje_licz; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.rodzaje_licz (
    rodzaj character varying(3) NOT NULL,
    rodzaj_licznika character varying,
    jednostka character varying
);


ALTER TABLE public.rodzaje_licz OWNER TO czarek;

--
-- Name: wyniki; Type: VIEW; Schema: public; Owner: czarek
--

CREATE VIEW public.wyniki AS
 SELECT ordung.kolejnosc,
    odczyty.data,
    liczniki.adres,
    liczniki.nr_fabryczny,
    odczyty.odczyt,
    rodzaje_licz.jednostka,
    public.srednia(odczyty.adres, odczyty.data, 3) AS srednia,
    public.zuzycie(odczyty.adres, odczyty.data) AS zuzycie,
    (
        CASE
            WHEN (public.srednia(odczyty.adres, odczyty.data, 3) = (0)::numeric) THEN (0)::numeric
            ELSE (((public.zuzycie(odczyty.adres, odczyty.data) - public.srednia(odczyty.adres, odczyty.data, 3)) * (100)::numeric) / public.srednia(odczyty.adres, odczyty.data, 3))
        END)::numeric(10,2) AS wzrost_procent_wzgledem_sredniej
   FROM (((public.odczyty
     RIGHT JOIN public.liczniki USING (adres))
     JOIN public.ordung ON (((liczniki.adres)::text = (ordung.adres)::text)))
     LEFT JOIN public.rodzaje_licz USING (rodzaj))
  ORDER BY odczyty.data DESC, ordung.kolejnosc;


ALTER TABLE public.wyniki OWNER TO czarek;

--
-- Name: gotowe_na_01; Type: VIEW; Schema: public; Owner: czarek
--

CREATE VIEW public.gotowe_na_01 AS
 SELECT wyniki.kolejnosc,
    wyniki.adres,
    wyniki.nr_fabryczny,
    wyniki.odczyt,
    wyniki.zuzycie
   FROM public.wyniki
  WHERE ((wyniki.kolejnosc IS NOT NULL) AND ((wyniki.data = (( SELECT (((date_part('year'::text, ((now())::date + 7)) || '-'::text) || date_part('month'::text, ((now())::date + 7))) || '-01'::text)))::date) OR (wyniki.data IS NULL)))
  ORDER BY wyniki.kolejnosc;


ALTER TABLE public.gotowe_na_01 OWNER TO czarek;

--
-- Name: kolejnosc_tmp; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.kolejnosc_tmp (
    kolejnosc integer,
    rodzaj character varying,
    nr_fabryczny character varying
);


ALTER TABLE public.kolejnosc_tmp OWNER TO czarek;

--
-- Name: najemcy; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.najemcy (
    id integer NOT NULL,
    nazwa character varying,
    telefon character varying
);


ALTER TABLE public.najemcy OWNER TO czarek;

--
-- Name: najemcy_id_seq; Type: SEQUENCE; Schema: public; Owner: czarek
--

CREATE SEQUENCE public.najemcy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.najemcy_id_seq OWNER TO czarek;

--
-- Name: najemcy_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: czarek
--

ALTER SEQUENCE public.najemcy_id_seq OWNED BY public.najemcy.id;


--
-- Name: plik_wojtek; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.plik_wojtek (
    adres character varying,
    nr_fabryczny character varying,
    kolejnosc integer
);


ALTER TABLE public.plik_wojtek OWNER TO czarek;

--
-- Name: wojtek; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.wojtek (
    kolejnosc integer,
    najemca character varying,
    nr_fabryczny character varying,
    lokalizacja character varying
);


ALTER TABLE public.wojtek OWNER TO czarek;

--
-- Name: wyniki_wojtek; Type: VIEW; Schema: public; Owner: czarek
--

CREATE VIEW public.wyniki_wojtek AS
 SELECT ordung.kolejnosc_wojtek,
    odczyty.data,
    liczniki.adres,
    liczniki.nr_fabryczny,
    odczyty.odczyt,
    rodzaje_licz.jednostka,
    public.srednia(odczyty.adres, odczyty.data, 12) AS srednia,
    public.zuzycie(odczyty.adres, odczyty.data) AS zuzycie,
    (
        CASE
            WHEN (public.srednia(odczyty.adres, odczyty.data, 12) = (0)::numeric) THEN (0)::numeric
            ELSE (((public.zuzycie(odczyty.adres, odczyty.data) - public.srednia(odczyty.adres, odczyty.data, 12)) * (100)::numeric) / public.srednia(odczyty.adres, odczyty.data, 12))
        END)::numeric(10,2) AS wzrost_procent_wzgledem_sredniej
   FROM (((public.odczyty
     RIGHT JOIN public.liczniki USING (adres))
     JOIN public.ordung ON (((liczniki.adres)::text = (ordung.adres)::text)))
     LEFT JOIN public.rodzaje_licz USING (rodzaj))
  ORDER BY odczyty.data DESC, ordung.kolejnosc_wojtek;


ALTER TABLE public.wyniki_wojtek OWNER TO czarek;

--
-- Name: wyniki_na_01_wojtek; Type: VIEW; Schema: public; Owner: czarek
--

CREATE VIEW public.wyniki_na_01_wojtek AS
 SELECT wyniki_wojtek.kolejnosc_wojtek,
    wyniki_wojtek.adres,
    wyniki_wojtek.nr_fabryczny,
    wyniki_wojtek.odczyt,
    wyniki_wojtek.zuzycie,
    wyniki_wojtek.wzrost_procent_wzgledem_sredniej AS skok
   FROM public.wyniki_wojtek
  WHERE ((wyniki_wojtek.kolejnosc_wojtek IS NOT NULL) AND ((wyniki_wojtek.data = (( SELECT (((date_part('year'::text, ((now())::date + 7)) || '-'::text) || date_part('month'::text, ((now())::date + 7))) || '-01'::text)))::date) OR (wyniki_wojtek.data IS NULL)))
  ORDER BY wyniki_wojtek.kolejnosc_wojtek;


ALTER TABLE public.wyniki_na_01_wojtek OWNER TO czarek;

--
-- Name: najemcy id; Type: DEFAULT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.najemcy ALTER COLUMN id SET DEFAULT nextval('public.najemcy_id_seq'::regclass);


--
-- Name: liczniki liczniki_kolejnosc_key; Type: CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.liczniki
    ADD CONSTRAINT liczniki_kolejnosc_key UNIQUE (kolejnosc_pdf);


--
-- Name: liczniki liczniki_pkey; Type: CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.liczniki
    ADD CONSTRAINT liczniki_pkey PRIMARY KEY (adres);


--
-- Name: najemcy najemcy_pkey; Type: CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.najemcy
    ADD CONSTRAINT najemcy_pkey PRIMARY KEY (id);


--
-- Name: odczyty odczyty_pkey; Type: CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.odczyty
    ADD CONSTRAINT odczyty_pkey PRIMARY KEY (data, adres);


--
-- Name: rodzaje_licz rodzaje_licz_pkey; Type: CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.rodzaje_licz
    ADD CONSTRAINT rodzaje_licz_pkey PRIMARY KEY (rodzaj);


--
-- Name: liczniki liczniki_najemca_fkey; Type: FK CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.liczniki
    ADD CONSTRAINT liczniki_najemca_fkey FOREIGN KEY (najemca) REFERENCES public.najemcy(id);


--
-- Name: liczniki liczniki_rodzaj_fkey; Type: FK CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.liczniki
    ADD CONSTRAINT liczniki_rodzaj_fkey FOREIGN KEY (rodzaj) REFERENCES public.rodzaje_licz(rodzaj);


--
-- Name: odczyty odczyty_adres_fkey; Type: FK CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.odczyty
    ADD CONSTRAINT odczyty_adres_fkey FOREIGN KEY (adres) REFERENCES public.liczniki(adres) DEFERRABLE;


--
-- Name: ordung ordung_adres_fkey; Type: FK CONSTRAINT; Schema: public; Owner: czarek
--

ALTER TABLE ONLY public.ordung
    ADD CONSTRAINT ordung_adres_fkey FOREIGN KEY (adres) REFERENCES public.liczniki(adres) DEFERRABLE;


--
-- PostgreSQL database dump complete
--

