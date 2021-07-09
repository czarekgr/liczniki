--
-- PostgreSQL database dump
--

-- Dumped from database version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)

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
    kolejnosc integer
);


ALTER TABLE public.liczniki OWNER TO czarek;

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
-- Name: odczyty; Type: TABLE; Schema: public; Owner: czarek
--

CREATE TABLE public.odczyty (
    data date NOT NULL,
    adres character varying NOT NULL,
    odczyt double precision
);


ALTER TABLE public.odczyty OWNER TO czarek;

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
    ADD CONSTRAINT odczyty_adres_fkey FOREIGN KEY (adres) REFERENCES public.liczniki(adres);


--
-- PostgreSQL database dump complete
--

