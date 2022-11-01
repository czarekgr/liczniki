--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7 (Ubuntu 11.7-0ubuntu0.19.10.1)
-- Dumped by pg_dump version 11.7 (Ubuntu 11.7-0ubuntu0.19.10.1)

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

SET default_with_oids = false;

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
    uwagi character varying
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
-- Data for Name: kolejnosc_tmp; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.kolejnosc_tmp (kolejnosc, rodzaj, nr_fabryczny) FROM stdin;
10	Woda	1920543256
20	Ciepło	71876833
30	Ciepło	71888359
40	Chłód	71834619
50	Chłód	71649391
60	Ciepło	71649394
70	Woda	57783922
80	Ciepło	67887353
90	Ciepło	71670106
100	Ciepło	71595107
110	Woda	191061232A
120	Woda	191183429A
130	Energia	48503028H16492010696
140	Energia	48503026G16402010565
150	Energia	48503028H16492010700
160	Energia	2316326009
170	Chłód	71670180
180	Chłód	71595108
190	Chłód	71516192
200	Energia	2316362011
210	Woda	181235653A
220	Ciepło	71512149
230	Ciepło	71512150
240	Ciepło	71512151
250	Ciepło	71512152
260	Ciepło	71512153
270	Chłód	71512145
280	Chłód	71512144
290	Chłód	71512148
300	Chłód	71512147
310	Chłód	71512146
320	Energia	1818244023
330	Energia	1816332087
340	Energia	2316362007
350	Energia	2316371005
360	Energia	2316362003
370	Woda	190405578A
380	Ciepło	71522586
390	Chłód	71571363
400	Chłód	71571362
410	Energia	1818415001
420	Woda	58376979
430	Woda	58376978
440	Ciepło	71150833
450	Ciepło	71150834
460	Ciepło	71612821
470	Ciepło	67884165
480	Ciepło	67884164
490	Ciepło	71647821
500	Ciepło	71649395
510	Ciepło	67884167
520	Chłód	71612822
530	Chłód	71649390
540	Chłód	71644762
550	Chłód	71644763
560	Chłód	71644764
570	Energia	48503026G16402010541
580	Energia	48503026H16472010063
590	Energia	48503026H16502010252
600	Energia	48503026G16412011087
610	Energia	48503026H16502010237
620	Woda	180702718A
630	Ciepło	71476893
640	Ciepło	71705791
650	Ciepło	80255450
660	Chłód	71476894
670	Chłód	80255449
680	Energia	1818137046
690	Energia	2316311028
700	Energia	2316326003
710	Energia	2316371014
720	Woda	181195981A
730	Ciepło	71496751
740	Chłód	71497211
750	Chłód	71497210
760	Energia	2318355029
770	Energia	2318332002
780	Woda	181195090
790	Woda	181195096A
800	Woda	181072960A
810	Woda	181173780A
820	Woda	181174659A
830	Woda	181174655A
840	Ciepło	80272795
850	Ciepło	80108185
860	Ciepło	80138392
870	Ciepło	80272797
880	Ciepło	80272796
890	Ciepło	62065876
900	Chłód	80271297
910	Chłód	71259540
920	Chłód	80271298
930	Chłód	80271273
940	Chłód	62065884
950	Chłód	78251262
960	Energia	2316362002
970	Energia	2316362014
980	Energia	2318334011
990	Energia	1816331002
1000	Energia	2318334004
1010	Energia	2316354003
1020	Energia	2318352007
1030	Energia	2318341005
1040	Energia	2318341010
1050	Woda	181106629A
1060	Ciepło	71297057
1070	Chłód	71230687
1080	Energia	1816331007
1090	Woda	36254453
1100	Ciepło	78675879
1110	Chłód	78675971
1120	Chłód	78676883
1130	Energia	48503026H16502010245
1140	Energia	48503026H16502010251
1150	Woda	60882996
1160	Ciepło	78647937
1170	Ciepło	78647936
1180	Ciepło	78675880
1190	Chłód	78647935
1200	Chłód	78647934
1210	Chłód	78675881
1220	Energia	1816331023
1230	Ciepło	80096039
1240	Ciepło	80096038
1250	Ciepło	67219624
1260	Chłód	80032573
1270	Chłód	80032572
1280	Energia	48503026H16502010220
1290	Woda	18726655
1300	Ciepło	80091629
1310	Chłód	80091631
1320	Chłód	80091630
1330	Energia	2318245036
1340	Woda	57760157
1350	Ciepło	80087616
1360	Ciepło	80087615
1370	Ciepło	67676944
1380	Chłód	80120070
1390	Chłód	80120069
1400	Chłód	80137646
1410	Energia	48503028H16492010698
1420	Woda	60587375
1430	Ciepło	62065877
1440	Chłód	78251259
1450	Energia	272103494
1460	Energia	272103657
1470	Woda	60600683
1480	Woda	160559458
1490	Ciepło	78478336
1500	Ciepło	62065865
1510	Chłód	62065880
1520	Chłód	620665881
1530	Chłód	620665888
1540	Chłód	78478337
1550	Energia	1817261024
1560	Energia	2316326004
1570	Energia	2316371009
1580	Woda	77902822
1590	Woda	77902823
1600	Ciepło	62065868
1610	Ciepło	62065875
1620	Chłód	78251257
1630	Chłód	62065883
1640	Chłód	78251265
1650	Energia	1817261013
1660	Energia	1817174066
1670	Energia	1517162019
1680	Energia	1517311047
1690	Energia	2316325006
1700	Energia	2316354008
1710	Woda	I17FA358457T
1720	Woda	I17FA358454Q
1730	Woda	119EA020537
1740	Ciepło	62065866
1750	Ciepło	62065874
1760	Chłód	62065885
1770	Chłód	78251263
1780	Chłód	62065882
1790	Chłód	78251266
1800	Energia	2317445001
1810	Energia	2317445010
1820	Energia	2317384011
1830	Energia	2317445019
1840	Energia	2317441033
1850	Energia	2317441065
1860	Energia	2316362006
1870	Energia	2316371001
1880	Energia	2316362010
1890	Woda	161032832
1900	Energia	1816344019
1910	Energia	2316354002
1920	Woda	190037778A
1930	Ciepło	80443474
1940	Chłód	80446698
1950	Energia	2319334053
1960	Energia	48503026H16472010039
1970	Ciepło	72461135
1980	Ciepło	72461134
1990	Chłód	72497589
2000	Woda	21728054
2010	Energia	48503026H16502010235
2030	Energia	1816331030
2040	Energia	1816331016
2050	Energia	1816331005
2060	Energia	1816332105
2070	Woda	17803108
2100	Energia	2316354013
2110	Energia	2316326010
2120	Energia	2316362018
2130	Energia	2316326007
2140	Energia	2316371007
2150	Energia	2316354011
2160	Energia	2316371016
\.


--
-- Data for Name: liczniki; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.liczniki (adres, nr_fabryczny, opis, lokalizacja, rodzaj, kolejnosc_pdf, najemca, uwagi) FROM stdin;
LM_ELE_ADR007	2316325006	AHU 1.4 HOGAN LOVELLS (63325006)	\N	ELE	1830	15	\N
LM_WOD_ADR236	21728054	Wodomierz Heban L00 (21728054)	\N	WOD	2730	14	\N
LM_LC_ADR159	72461134	Licznik ciepła - Heban L00 (72461134)	\N	LC	2700	14	\N
LM_LH_ADR167	72497589	Licznik chłodu - Heban L00 (72497589)	\N	LH	2720	14	\N
LM_WOD_ADR146	17803108	Główny wodomierz (11036701)	\N	WOD	1660	\N	\N
LM_LC_ADR160	72461135	Licznik ciepła - Heban grzejniki (licznik na L-1) (72461135)	\N	LC	2710	14	\N
LM_LC_ADR185	71612821	Licznik ciepła - Fabiana Filippi L00 (71612821)	\N	LC	1310	\N	\N
LM_LH_ADR225	71612822	Licznik chłodu - Fabiana Filippi L00 (71612822)	\N	LH	1480	\N	\N
LM_LH_ADR200	78251258	Licznik chłodu FC L03 - obieg FO (HC05, HC08) (78251258)	\N	LH	370	\N	\N
LM_LH_ADR208	62065887	Licznik chłodu serwerownia najemcy L03 - S (HC05) (62065887)	\N	LH	400	\N	\N
LM_LC_ADR93	67884164	Licznik ciepła - grzejnik Fabiana (67884164)	\N	LC	1350	\N	\N
LM_LC_ADR_B22	71649394	Licznik ciepła - Fabiana L00 (71649394)	\N	LC	2460	\N	\N
LM_LC_ADR_B24	71649395	Licznik ciepła - Corneliani L01 (71649395)	\N	LC	2470	\N	\N
LM_WOD_ADR_B81	58376979	Wodomierz - Fabiana (58376979)	\N	WOD	2370	\N	\N
LM_ELE_ADR031	1816331002	Solution Tn-2.1 - TU3 (33331002)	\N	ELE	630	\N	\N
LM_ELE_ADR001	2316354011	AHU 3.4 EON (63354011)	\N	ELE	1790	\N	\N
LM_ELE_ADR117	2316362003	AHU R4KZ (63362003)	\N	ELE	1560	\N	\N
LM_LH_ADR_B36	62065883	Licznik chłodu serwerownia najemcy L04 Hogan serw - S (HC01) (62065883)	\N	LH	2550	15	\N
LM_LC_ADR_B32	62065875	Licznik ciepła FC najemcy L04 Hogan1- obieg FO (HC01) (62065875)	\N	LC	1080	15	\N
LM_LC_ADR209	71476893	Licznik ciepła  - Amaro L00 (71476893)	\N	LC	290	13	\N
LM_LH_ADR235	71476894	Licznik chłodu - Amaro L00 (71476894)	\N	LH	510	13	\N
LM_LH_ADR203	78251266	Licznik chłodu FC L02 - obieg FO IT ERGO (HC01) (78251266)	\N	LH	380	18	\N
LM_ELE_ADR095	2317384011	SP K2 - Tablica TNK 2.2 IT ERGO (64384011)	\N	ELE	870	18	\N
LM_LC_ADR182	71496751	Licznik ciepła - Leonardo (71496751)	\N	LC	1290	19	\N
LM_LH_ADR233	71497211	Licznik chłodu Leonardo L03 (71497211)	\N	LH	1530	19	\N
LM_LH_ADR234	71497210	Licznik chłodu Leonardo L03 (71497210)	\N	LH	500	19	\N
LM_ELE_ADR016	63326001	Centrala AHU 2 (63326001)	\N	ELE	1890	\N	\N
LM_WOD_ADR_B80	58376978	Wodomierz - Davide Lifestyle (58376978)	\N	WOD	2360	8	\N
LM_LC_ADR_B16	71150833	Licznik ciepła - Davide Lifestyle L00 (71150833)	\N	LC	2600	8	\N
LM_LH_ADR_B21	71644763	Licznik chłodu - Davide Lifestyle L01 (71644763)	\N	LH	1110	8	\N
LM_LH_ADR_B19	71644764	Licznik chłodu - Davide Lifestyle L01 (71644764)	\N	LH	1100	8	\N
LM_LC_ADR_B18	71647821	Licznik ciepła - Davide Lifestyle L01 (71647821)	\N	LC	2440	8	\N
LM_LC_ADR89	67884165	Licznik ciepła - grzejnik Davide (67884165)	\N	LC	1340	8	\N
zdemontowany600	48503026G16412011087	Davide zdemontowany	\N	ELE	\N	8	\N
LM_LH_ADR189	71512143	Licznik chłodu - Les Amis L01 (strefa 2B) (71512143)	\N	LH	330	9	\N
LM_LC_ADR184	71512150	Licznik ciepła - Les Amis (strefa 2B) (71512150)	\N	LC	260	9	\N
LM_LC_ADR149	71512149	Licznik ciepła - Les Amis (71512149)	\N	LC	1220	9	\N
LM_LH_ADR145	71512145	Licznik chłodu - Les Amis (71512145)	\N	LH	1360	9	\N
LM_LH_ADR190	71512144	Licznik chłodu - Les Amis L01 (strefa 2A) (71512144)	\N	LH	1380	9	\N
LM_LC_ADR186	71512152	Licznik ciepła - Les Amis (strefa 2A bliżej 1C) (71512152)	\N	LC	270	9	\N
LM_LC_ADR183	71512151	Licznik ciepła - Les Amis (strefa 2A) (71512151)	\N	LC	1300	9	\N
LM_LH_ADR191	71512148	Licznik chłodu - Les Amis L01 (strefa 2A bliżej 1C) (71512148)	\N	LH	1390	9	\N
LM_LC_ADR187	71512153	Licznik ciepła - Les Amis (strefa 3D) (71512153)	\N	LC	280	9	\N
LM_LH_ADR192	71512147	Licznik chłodu - Les Amis L01 (strefa 3D) (71512147)	\N	LH	1400	9	\N
LM_LH_ADR122	71595108	Licznik chłodu - Centrale CulinaryOn (71595108)	\N	LH	320	7	\N
LM_ELE_ADR078	48503028H16492010696	SP U4 - powierzchnia 0.06 CulinaryOn (16230375)	\N	ELE	50	7	\N
LM_LC_ADR123	71595107	Licznik ciepła - Centrale CulinaryOn (71595107)	\N	LC	120	7	\N
LM_WOD_ADR_B75	191183429A	Wodomierz- zimna woda - CulinaryOn (19726823)	\N	WOD	2340	7	\N
recznie1920	190037778A	Wodomierz PZDF	PZFD za recepcją z drabiną	WOD	\N	10	\N
LM_LH_ADR_B34	62065880	Licznik chłodu serwerownia najemcy L05 HBO serw - S (HC05) (62065880)	\N	LH	1120	2	\N
LM_ELE_ADR029	2319334053	Licznik elektryczny - PZFD L03 (66334053)	\N	ELE	620	10	\N
LM_ELE_ADR091	2316362011	P4 centrala telefoniczna Play (63362011)	\N	ELE	2350	\N	\N
LM_ELE_ADR086	2318334004	SP 2 - Tablica TN 2.4 - Space Solution L01 (65334004)	\N	ELE	840	\N	\N
LM_LH_ADR197	78251268	Licznik chłodu obiegu FC - FO L-2 (78251268)	\N	LH	1430	\N	\N
LM_LH_ADR_B23	71649391	Licznik chłodu - Fabiana L00 (71649391)	\N	LH	2510	\N	\N
LM_LH_ADR_B25	71649390	Licznik chłodu - Corneliani L01 (71649390)	\N	LH	2520	\N	\N
LM_ELE_ADR062	48503026G16402010541	SP U1 - Powierzchnia 0.04 - Fabiana Filippi L00 (16280856)	\N	ELE	750	\N	\N
LM_ELE_ADR065	BRAK	SP U1 - Powierzchnia 1.03	\N	ELE	760	\N	\N
LM_ELE_ADR070	16350646	SP U2 - Powierzchnia 0.12 (16350646)	\N	ELE	790	\N	\N
LM_ELE_ADR073	BRAK	SP U3 - Powierzchnia 0.10	\N	ELE	810	\N	\N
LM_ELE_ADR023	63326018	Tablice T-TOZ (63326018)	\N	ELE	1930	\N	\N
LM_ELE_ADR025	33344014	Tablice TA 2.-1, TA 2.2, TA 2.3, TA 2.4 (33344014)	\N	ELE	1940	\N	\N
LM_ELE_ADR034	63325002	T-TEL (63325002)	\N	ELE	1960	\N	\N
LM_ELE_ADR036	63326008	Rozdzielnica TWC2 (63326008)	\N	ELE	1970	\N	\N
LM_ELE_ADR040	63284001	Tablica T-OGS (rezerwa) (63284001)	\N	ELE	1990	\N	\N
LM_ELE_ADR042	63182019	Winda W1 (63182019)	\N	ELE	2000	\N	\N
LM_ELE_ADR044	63354012	Winda W3 (63354012)	\N	ELE	2010	\N	\N
LM_LC_ADR102	67219624	Licznik ciepła - grzejnik Almidecor (67219624)	\N	LC	1180	4	\N
LM_WOD_ADR238	180702718A	Wodomierz Amaro L00 (18740019)	\N	WOD	1700	13	\N
LM_LH_ADR218	78647935	Licznik chłodu FC L01 - AUDI (78647935)	\N	LH	440	11	\N
LM_WOD_ADR140	161032832	Wodomierz piano 1 W.Kruk (16803910)	\N	WOD	990	16	\N
LM_WOD_ADR_B74	190405578A	Wodomierz - EON (19700657)	\N	WOD	2250	17	\N
LM_ELE_ADR107	1818415001	EON L04 (35415001)	\N	ELE	2160	17	\N
LM_LH_ADR_B47	71571363	Licznik chłodu - EON (71571363)	\N	LH	2240	17	\N
LM_LH_ADR_B46	71571362	Licznik chłodu - EON serwerownia (71571362)	\N	LH	2230	17	\N
LM_ELE_ADR098	2317441033	SP K3 - Tablica TNK 3.2 IT ERGO (64441033)	\N	ELE	890	18	\N
LM_LH_ADR207	62065885	Licznik chłodu serwerownia IT ERGO (62065885)	\N	LH	1420	18	\N
LM_WOD_ADR239	181195981A	Wodomierz Leonardo L03 (18739958)	\N	WOD	1710	19	\N
LM_ELE_ADR101	2318332002	Leonardo L03 TNK 4.3 (65332002)	\N	ELE	920	19	\N
LM_ELE_ADR100	2318355029	Leonardo L03 TN4.3 (65355029)	\N	ELE	910	19	\N
LM_ELE_ADR048	63325012	Winda W8 (63325012)	\N	ELE	2020	\N	\N
LM_ELE_ADR051	63284036	Tablica TP 1.-2 (63284036)	\N	ELE	2030	\N	\N
LM_ELE_ADR053	63265005	Tablica TP 2.-1 (63265005)	\N	ELE	2040	\N	\N
LM_LC_ADR158	62065867	Licznik ciepła FC najemcy L03 - obieg FO (HC05, HC08) (62065867)	\N	LC	180	\N	\N
LM_WOD_MAIN_W	BRAK		\N	WOD	110	\N	\N
LM_ELE_ADR021	33344042	Tablice TA 3.0, TA 3.1, TA 3.2 (33344042)	\N	ELE	40	\N	\N
LM_ELE_ADR066	16380796	SP U1 - Powierzchnia 1.04 (16380796)	\N	ELE	60	\N	\N
LM_ELE_ADR017	63311012	Rozdzielnica RW3 (63311012)	\N	ELE	550	\N	\N
LM_LC_ADR156	62065878	Licznik ciepła FC - FR (62065878)	\N	LC	1230	\N	\N
LM_LC_ADR155	78251253	Licznik ciepła FC - FO (78251253)	\N	LC	160	\N	\N
LM_LC_ADR154	62065870	Licznik ciepła obiegu grzejników RAD (62065870)	\N	LC	150	\N	\N
LM_LC_ADR152	62065879	Licznik ciepła obiegu AHU - AR (62065879)	\N	LC	1210	\N	\N
LM_LC_ADR153	78251254	Licznik ciepła obiegu AO (78251254)	\N	LC	140	\N	\N
LM_LC_ADR82	67884167	Licznik ciepła - grzejnik Corneliani (67884167)	\N	LC	310	\N	\N
LM_ELE_ADR008	2316326010	AHU 3.3 NDI (63326010)	\N	ELE	530	\N	\N
LM_ELE_ADR064	BRAK	SP U1 - Powierzchnia 1.02	\N	ELE	2080	\N	\N
LM_ELE_ADR058	63284023	Tablica  T-UPS (63284023)	\N	ELE	2090	\N	\N
LM_ELE_ADR074	BRAK	SP U3 - Powierzchnia 0.11	\N	ELE	2110	\N	\N
LM_ELE_ADR076	15420085	SP U4 - powierzchnia 0.16 (15420085)	\N	ELE	2120	\N	\N
LM_ELE_ADR109	63371006	Magazyn U.02  (63371006)	\N	ELE	2180	\N	\N
LM_WOD_ADR240	00207182	Wodomierz toalety L01 (00207182)	\N	WOD	1720	\N	\N
LM_LH_ADR_B17	71644762	Licznik chłodu - Davide Lifestyle L00 (71644762)	\N	LH	2610	8	\N
LM_ELE_ADR014	2316362007	Centrala AHU R4 Les Amis (63362007)	\N	ELE	1870	9	\N
LM_LH_ADR219	78675971	Licznik chłodu L03 MBDA (78675971)	\N	LH	1450	5	\N
LM_LH_ADR220	78676883	Licznik chłodu L03 MBDA serwerownia (78676883)	\N	LH	1460	5	\N
LM_LC_ADR173	78675879	Licznik ciepła L03 MBDA (78675879)	\N	LC	210	5	\N
LM_WOD_ADR_B79	191061232A	Wodomierz - ciepła woda - CulinaryOn (19726824)	\N	WOD	2620	7	\N
LM_ELE_ADR077	48503026G402010565	SP U4 - powierzchnia 0.13 CulinaryOn (16350655)	\N	ELE	820	7	\N
LM_LC_ADR104	67887353	Licznik ciepła - grzejnik CulinaryOn (67887353)	\N	LC	1200	7	\N
LM_LC_ADR_B26	71670106	Licznik ciepła - CulinaryOn L00 (71670106)	\N	LC	1060	7	\N
LM_LC_ADR_B30	62065865	Licznik ciepła FC najemcy HBO L05 - obieg FO (HC01) (62065865)	\N	LC	1070	2	\N
LM_LH_ADR_B37	62065888	Licznik chłodu serwerownia najemcy L05  HBO serw- S (HC01) (62065888)	\N	LH	1130	2	\N
LM_LC_ADR_B41	78478336	Licznik ciepła - HBO L05 (78478336)	\N	LC	2490	2	\N
LM_LH_ADR_B42	78478337	Licznik chłodu - HBO L05 (78478337)	\N	LH	1160	2	\N
LM_LH_ADR221	71230687	Licznik chłodu L01 - ZEGNA (71230687)	\N	LH	450	21	\N
LM_LC_ADR163	71888359	Licznik ciepła - ZEGNA L00 (71888359)	\N	LC	590	21	\N
LM_LC_ADR164	71876833	Licznik ciepła - ZEGNA grzejniki L00 (71876833)	\N	LC	600	21	\N
LM_LC_ADR174	71297057	Licznik ciepła L01 - ZEGNA (71297057)	\N	LC	220	21	\N
LM_LH_ADR201	71834619	Licznik chłodu - ZEGNA L00 (71834619)	\N	LH	610	21	\N
LM_LC_ADR32	80443474	Licznik ciepła - PZFD L03 (80443474)	\N	LC	300	10	\N
LM_LC_ADR_B33	62065877	Licznik ciepła FC najemcy L05 Seewald - obieg FO (HC05, HC08) (62065877)	\N	LC	1090	3	\N
LM_LH_ADR_B39	78251259	Licznik chłodu FC L05 Seewald - obieg FO (HC05, HC08) (78251259) (MWh)	\N	LH	1140	3	\N
LM_LH_ADR227	80120069	Licznik chłodu L00 - GCN/Almidecor (80120069)	\N	LH	470	1	\N
LM_LC_ADR103	67676944	Licznik ciepła - grzejnik GCN (67676944)	\N	LC	1190	1	\N
LM_WOD_ADR241	00207171	Wodomierz toalety L00 (00207171)	\N	WOD	1730	\N	\N
LM_ELE_ADR128	08216809	po KSP (w szachcie L01 na solution) (08216809)	\N	ELE	1750	\N	\N
LM_ELE_ADR002	63354008	AHU 2.4 HOGAN LOVELS (63354008)	\N	ELE	1800	\N	\N
LM_WOD_ADR141	16838217	Wodomierz piano 2 (16838217)	\N	WOD	1630	\N	\N
LM_WOD_ADR142	16803909	Wodomierz TWC (16803909)	\N	WOD	1640	\N	\N
LM_ELE_ADR043	63354018	Winda W2 (63354018)	\N	ELE	2290	\N	\N
LM_ELE_ADR_B11	63284007	Licznik elektryczny Rozdzielnica RW2, RPCH- TRANE2(63284007)	\N	ELE	2300	\N	\N
LM_ELE_ADR019	63326006	Rozdzielnica T-TAR (63326006)	\N	ELE	560	\N	\N
LM_ELE_ADR024	63325014	Tablice TA 1.2, TA 1.3, TA 1.4, TA 1.5 (63325014)	\N	ELE	570	\N	\N
LM_ELE_ADR041	63325008	Tablica T-WC (63325008)	\N	ELE	650	\N	\N
LM_ELE_ADR045	63354004	Winda W4 (63354004)	\N	ELE	660	\N	\N
LM_ELE_ADR047	63354016	Winda W7 (63354016)	\N	ELE	670	\N	\N
LM_ELE_ADR052	63265003	Tablica TP 1.-1 (63265003)	\N	ELE	690	\N	\N
LM_ELE_ADR038	1816332105	Rozdzielnia RPCH (33332105)	\N	ELE	640	\N	\N
LM_ELE_ADR_B06	1816331030	Licznik elektryczny Chiller CHI1 (33331030)	\N	ELE	2260	\N	\N
LM_ELE_ADR071	48503026H16502010220	SP U2 - Almidecor (dawniej powierzchnia 1.07) (16410250)	\N	ELE	800	4	\N
LM_LH_ADR217	78647934	Licznik chłodu FC L00 - AUDI (78647934)	\N	LH	1500	11	\N
LM_LC_ADR171	78647936	Licznik ciepła L00 - AUDI (78647936)	\N	LC	1240	11	\N
LM_LH_ADR232	78675881	Licznik chłodu - AUDI serwerownia (78675881)	\N	LH	1520	11	\N
LM_LC_ADR178	78675880	Licznik ciepła L-1 - AUDI - grzejniki (78675880)	\N	LC	250	11	\N
LM_LC_ADR172	78647937	Licznik ciepła L01 - AUDI (78647937)	\N	LC	20	11	\N
LM_ELE_ADR114	1816331023	Licznik elektryczny AUDI - TU4 (33331023)	\N	ELE	1550	11	\N
LM_WOD_ADR150	60882996	Wodomierz AUDI (00228857)	\N	WOD	1680	11	\N
LM_ELE_ADR039	1816344019	Tablica T-Piano W.Kruk (33344019)	\N	ELE	1980	16	\N
LM_LC_ADR161	62065874	Licznik ciepła FC najemcy L02 - obieg FO (HC01) IT ERGO (62065874)	\N	LC	1320	18	\N
LM_ELE_ADR011	2316371001	AHU 2.2 IT ERGO (63371001)	\N	ELE	1850	18	\N
LM_ELE_ADR080	2317445010	SP 1 - Tablica TN 1.2 (64445010)	\N	ELE	70	18	\N
LM_ELE_ADR009	2316362010	AHU 3.2 IT ERGO (63362010)	\N	ELE	1840	18	\N
LM_WOD_ADR133	17FA358457T	Wodomierz ERGO - recepcja (17360039)	\N	WOD	1580	18	\N
LM_WOD_ADR132	17FA358454Q	Wodomierz ERGO - pomieszczenie(17360035)	\N	WOD	1570	18	\N
LM_WOD_ADR147	181022659A	Wodomierz NDI (18726655)	\N	WOD	1000	20	\N
LM_WOD_ADR143	161032822	Brama wjazdowa (16838122)	\N	WOD	1650	\N	\N
LM_ELE_ADR054	63265011	Tablica TP 1.1, TP 1.3, TP 1.5 (63265011)	\N	ELE	700	\N	\N
LM_ELE_ADR057	63284015	Tablica  TP-WIND (63284015)	\N	ELE	710	\N	\N
LM_ELE_ADR060	BRAK	SP U1 - Powierzchnia 0.02	\N	ELE	730	\N	\N
LM_ELE_ADR061	BRAK	SP U1 - Powierzchnia 0.03	\N	ELE	740	\N	\N
LM_ELE_ADR111	63371013	Magazyn U.04 FABIANA FILLIPPI (63371013)	\N	ELE	930	\N	\N
LM_ELE_ADR116	63371010	AHU R4K (63371010)	\N	ELE	940	\N	\N
LM_ELE_ADR118	63362009	AHU B1 (63362009)	\N	ELE	950	\N	\N
LM_ELE_ADR119	63362017	AHU T (63362017)	\N	ELE	960	\N	\N
LM_ELE_ADR_B01	16380762	Licznik elektryczny - Corneliani (16380762)	\N	ELE	2410	\N	\N
LM_ELE_ADR_B10	63284002	Licznik elektryczny - Rozdzielnica RW1 (63284002)	\N	ELE	2420	\N	\N
LM_WOD_ADR_B76	16838219	Wodomierz od strony ul. Książęcej L04 (16838219)	\N	WOD	2580	\N	\N
LM_WOD_ADR_B77	16838216	Wodomierz od Kruka L04 (16838216)	\N	WOD	2590	\N	\N
LM_ELE_ADR018	63326011	Rozdzielnica RM (63326011)	\N	ELE	1900	\N	\N
LM_ELE_ADR020	63311020	Tablice TA 3.3, TA 3.4, TA 3.5 (63311020)	\N	ELE	1910	\N	\N
LM_ELE_ADR022	33344025	Tablice TA 2.-1, TA 2.2, TA 2.3, TA 2.4 (33344025)	\N	ELE	1920	\N	\N
LM_ELE_ADR015	2316326007	AHU R1 ALMIDECOR (63326007)	\N	ELE	1880	\N	\N
LM_ELE_ADR_B05	1816331016	Licznik elektryczny Chiller CHI2 (33331016)	\N	ELE	2390	\N	\N
LM_LC_ADR_B31	62065868	Licznik ciepła FC najemcy L04 Hogan58 - obieg FO (HC05, HC08) (62065868)	\N	LC	2480	15	\N
LM_LH_ADR_B40	78251265	Licznik chłodu FC L04 Hogan - obieg FO (HC01) (78251265) (MWh)	\N	LH	1150	15	\N
LM_WOD_ADR135	77902822	Wodomierz Hogan Lovells L04 - od Książecej (77902822)	\N	WOD	1600	15	\N
LM_WOD_ADR136	77902823	Wodomierz Hogan Lovells L04 - od Placu Trzech Krzyży (77902823)	\N	WOD	1610	15	\N
LM_LH_ADR_B38	78251257	Licznik chłodu FC L04 Hogan - obieg FO (HC05, HC08) (78251257) (MWh)	\N	LH	2560	15	\N
LM_LH_ADR223	80032572	Licznik chłodu L01 - Almidecor (80032572)	\N	LH	1470	4	\N
LM_LC_ADR175	80096039	Licznik ciepła L00 - Almidecor (80096039)	\N	LC	230	4	\N
LM_LH_ADR222	80032573	Licznik chłodu L00 - Almidecor (80032573)	\N	LH	460	4	\N
LM_LC_ADR176	80096038	Licznik ciepła L01 - Almidecor (80096038)	\N	LC	240	4	\N
LM_ELE_ADR121	1818137046	Amaro L00 (35137046)	Amaro, we od recepcji Pl. 3 Krzyży, korytarzyk w lewo, po lewej tablica elektryczna	ELE	1740	13	\N
LM_ELE_ADR046	2316354008	Solution space TN 1.1 - TU5 (63325003)	\N	ELE	2270	6	\N
LM_ELE_ADR_B02	16380819	Licznik elektryczny - Davide Lifestyle (16380819)	\N	ELE	2430	8	\N
LM_WOD_ADR148	00214876	Wodomierz MBDA (00214876)	\N	WOD	1670	5	\N
LM_LH_ADR_B27	71670180	Licznik chłodu - CulinaryOn L00 (71670180)	\N	LH	2530	7	\N
LM_ELE_ADR003	2316354013	AHU 2.5 HBO (63354013)	\N	ELE	1810	2	\N
LM_WOD_ADR_B78	60600683	Wodomierz HBO (00129890)	\N	WOD	1170	2	\N
LM_ELE_ADR006	2316326004	AHU 1.5 HBO (63326004)	\N	ELE	1820	2	\N
LM_ELE_ADR124	1816331007	ZEGNA - TU 2 (RGNN) (33331007)	\N	ELE	2320	21	\N
LM_WOD_ADR30	19737052	Wodomierz PZFD L03 (19737052)	\N	WOD	1780	10	\N
LM_ELE_ADR_B12	272103494	Licznik elektryczny Seewald kuchnia 1 (11111111)	\N	ELE	2630	3	\N
LM_ELE_ADR_B13	272103657	Licznik elektryczny Seewald kuchnia 2 (22222222)	\N	ELE	2640	3	\N
LM_WOD_ADR139	57760157	Wodomierz GCN  (57760157)	\N	WOD	1620	1	\N
LM_LC_ADR168	80087616	Licznik ciepła L00 GCN (80087616)	\N	LC	200	1	\N
LM_LH_ADR226	80120070	Licznik chłodu FC L00 - GCN (80120070)	\N	LH	1490	1	\N
LM_LC_ADR_B46	80087615	Licznik ciepła GCN (80087615)	\N	LC	2650	1	\N
LM_LC_ADR224	71705791	Licznik ciepła - Amaro grzejniki  (licznik na L-1) (71505791)	\N	LC	1330	13	\N
LM_ELE_ADR027	2316311028	AHU R5 AMARO (63311028)	\N	ELE	580	13	\N
LM_ELE_ADR110	2316371014	Amaro - magazyn (63371014)	\N	ELE	2190	13	\N
LM_LH_ADR_B44	80255450	Licznik chłodu Centrala Amaro (80255450)	\N	LH	2570	13	\N
LM_LC_ADR_B43	80255449	Licznik ciepła  - Centrala Amaro (80255449)	\N	LC	2500	13	\N
LM_ELE_ADR049	2316354002	Winda Piano W.Kruk (63354002)	\N	ELE	680	16	\N
LM_LC_ADR_B45	71522586	Licznik ciepła EON (71522586)	\N	LC	2220	17	\N
LM_ELE_ADR087	2317441065	SP 3 - Tablica TN 3.2 IT ERGO (64441065)	\N	ELE	2210	18	\N
LM_WOD_ADR134	19EA020537/173600458	Wodomierz ERGO - sala kinowa (17360045)	\N	WOD	1590	18	\N
LM_ELE_ADR013	2316362006	AHU 1.2 IT ERGO (63362006)	\N	ELE	1860	18	\N
LM_LC_ADR157	62065866	Licznik ciepła FC najemcy L02 - obieg FO (HC05, HC08) IT ERGO (62065866)	\N	LC	170	18	\N
LM_LC_ADR151	78059564	Główny licznik ciepła budynku L-1 (78059564)	\N	LC	130	\N	\N
LM_LH_ADR198	78251269	Licznik chłodu obiegu FC - FR L-2 (78251269)	\N	LH	360	\N	\N
LM_LH_ADR194	78251261	Licznik chłodu obieg AHU - AO L-2 (78251261)	\N	LH	1410	\N	\N
LM_LH_ADR195	78251260	Licznik chłodu AHU - AR (78251260)	\N	LH	340	\N	\N
LM_LH_ADR196	78251264	Licznik chłodu obiegu serwerowni S - L-2 (78251264)	\N	LH	350	\N	\N
----	\N	---	\N	\N	\N	\N	\N
LM_LH_ADR199	78251263	Licznik chłodu FC L02 - obieg FO IT ERGO (HC05, HC08) (78251263)	\N	LH	80	18	\N
LM_LH_ADR211	62065882	Licznik chłodu serwerownia najemcy L02 - S (HC01) (62065882)	\N	LH	410	18	\N
LM_ELE_ADR055	63265006	Tablica TP 2.3 (63265006)	\N	ELE	2050	\N	\N
LM_ELE_ADR056	63284037	Tablica  TP 3.1, TP 3.3, TP 3.5 (63284037)	\N	ELE	2060	\N	\N
LM_ELE_ADR063	BRAK	SP U1 - Powierzchnia 0.05	\N	ELE	2070	\N	\N
LM_ELE_ADR_B08	1817261013	Licznik elektryczny SP 1 Hogan - Tablica TN 1.4 (34261013)	\N	ELE	1050	15	\N
LM_ELE_ADR_B07	1817174066	Licznik elektryczny SP 3 Hogan - Tablica TN 3.4 (34174066)	\N	ELE	1040	15	\N
LM_ELE_ADR_B03	1517162019	Licznik elektryczny SP K1 Hogan - Tablica TNK 1.4 (04162019)	\N	ELE	1030	15	\N
LM_ELE_ADR_B04	1816331005	Licznik elektryczny Chiller CHI3 (33331005)	\N	ELE	2380	\N	\N
LM_ELE_ADR112	2316362018	AHU R2 AUDI (63362018)	\N	ELE	2330	\N	\N
LM_ELE_ADR068	48503026H16472010039	SP U2 - Heban - Powierzchnia 0.07 (16390068)	\N	ELE	780	\N	\N
LM_ELE_ADR125	1517311047	Hogan - logo (04311047)	\N	ELE	2670	15	\N
LM_ELE_ADR120	2316326003	Centrala Amaro AHU N2 - RW4 (63326003)	\N	ELE	970	13	\N
LM_ELE_ADR059	2317445001	SP K1 - Tablica TNK 1.2 - IT ERGO (64445001)	\N	ELE	720	18	\N
LM_ELE_ADR084	2317445019	SP 2 - Tablica TN 2.2 IT ERGO (64445019)	\N	ELE	830	18	\N
LM_LC_ADR170	80091629	Licznik ciepła L03 NDI (80091629)	\N	LC	10	20	\N
LM_ELE_ADR088	2318245036	SP 3 - Tablica TN 3.3 - NDI (65245036)	\N	ELE	850	20	\N
LM_LH_ADR216	80091630	Licznik chłodu FC L03 - NDI Serwerownia (80091630)	\N	LH	430	20	\N
LM_LH_ADR215	80091631	Licznik chłodu FC L03 - NDI (80091631)	\N	LH	1440	20	\N
recznie70	57783922	Almidecor wodomierz	Almidecor +1, rewizja pod umywalką	WOD	\N	4	\N
recznie2010	48503026H16502010235	TPSA	Centrala telefoniczna -2	\N	\N	\N	\N
LM_ELE_ADR067	48503026H16502010235	SP U1 - Powierzchnia 1.05 (16380761)	Technogim szynotor	ELE	770	\N	\N
LM_ELE_ADR081	2316354003	SP 1 - Solution Space L01 TN 1.1 (TU5) (63354003)	\N	ELE	2130	6	nr fabryczny z pliku Wojtka
LM_LH_ADR204	78251262	Licznik chłodu Solution Space L03 szacht (78251262)	\N	LH	390	6	\N
LM_ELE_ADR090	2318334011	SP 3 - Tablica TN 3.5 - Solution Space L00 (65334011)	\N	ELE	2150	6	\N
LM_LC_ADR162	62065876	Licznik ciepła - Solution Space L03 (62065876)	\N	LC	190	6	\N
LM_WOD_ADR242	181195090	Wodomierz Solution Space L00 (18734962)	\N	WOD	2310	6	\N
LM_WOD_ADR249_Solution Space	181174659A	Wodomierz Solution Space kuchnia 1 (18733477)	\N	WOD	100	6	\N
LM_ELE_ADR028	2316362014	AHU R6 SOLUTION SPACE L01 (63362014)	\N	ELE	1950	6	\N
LM_ELE_ADR012	2316362002	AHU 1.3 SOLUTION SPACE L03 (63362002)	\N	ELE	540	6	\N
LM_WOD_ADR247_Solution Space	181072960A	Wodomierz Solution Space łazienki L01 (18734980)	\N	WOD	1760	6	\N
LM_WOD_ADR246_Solution Space	181195096A	Wodomierz Solution Space kuchnia L01 (18734955)	\N	WOD	1010	6	\N
LM_WOD_ADR250_Solution Space	181173780A	Wodomierz Solution Space łazienki L03 (18733482)	\N	WOD	1770	6	\N
LM_WOD_ADR248_Solution Space	181174655A	Wodomierz Solution Space kuchnia 2 (18733476)	\N	WOD	1020	6	\N
LM_ELE_ADR099	2318352007	SP K3 - Tablica TN 1.3 - Solution Space L03 (65352007)	\N	ELE	900	6	\N
LM_LH_ADR228	80271297	Licznik chłodu Solution Space L00 (80271297)	\N	LH	1510	6	\N
LM_LC_ADR165	80108185	Licznik ciepła - Solution Space grzejniki L-1 (80108185)	\N	LC	1250	6	\N
LM_LC_ADR_B20	71150834	Licznik ciepła - Davide Lifestyle L01 (71150834)	\N	LC	2450	8	\N
LM_ELE_ADR072	48503026H16502010251	SP U3 - MBDA tablica TNK (dawniej powierzchnia 0.09) (16380803)	\N	ELE	2100	5	\N
recznie1090	36254453	MBDA woda	MBDA kuchnia, sufit za 2 lampą 	WOD	\N	5	\N
recznie160	2316326009	CulinaryOn	Rozdzielnia szafa 14	ELE	\N	7	\N
recznie190	71516192	CulinaryOn	pokój 50 poziom1	LH	\N	7	\N
recznie150	48503028H16492010700	CulinaryOn z drabiną	CulinaryOn +1	ELE	\N	7	\N
LM_ELE_ADR_B09	1817261024	SP 1 - Główny licznik elektryczny HBO (34261024)	\N	ELE	2400	2	\N
recznie1480	160559458	HBO - Podlewanie dachu	HBO pokój kurierów	WOD	\N	2	\N
recznie1530	620665888	HBO	HBO od Książencej	LH	\N	2	\N
LM_WOD_ADR129	181106629A	Wodomierz ZEGNA L01 (18727749)	\N	WOD	980	21	\N
recznie1400	80137646	Green Cafe Nero WL klimakonwektory	poziom +1 Solutions duża kuchnia	LH	\N	1	\N
recznie330	1816332087	LesAmis	Rozdzielnia szafa 14	ELE	\N	9	\N
LM_LH_ADR33	80446698	Licznik chłodu - PZFD L03 (80446698)	\N	LH	520	10	\N
recznie10	1920543256	Wodomierz zieleń Seewald	Dach obok chillera	WOD	\N	3	\N
recznie1420	60587375	Wodomierz Seewald	Toalety obok szklanych drzwi, drabinka	WOD	\N	3	\N
LM_ELE_ADR069	48503028H16492010698	Green Cafe Nero GCN (15270553)	\N	ELE	2680	1	\N
LM_LC_ADR166	80138392	Licznik ciepła - Solution Space grzejniki L-1 (80138392)	\N	LC	1260	6	\N
LM_LC_ADR181	80272797	Licznik ciepła  - Solution Space L01 (80272797)	\N	LC	1280	6	\N
LM_LH_ADR230	80271298	Licznik chłodu Solution Space L01 (80271298)	\N	LH	1540	6	\N
LM_LC_ADR180	80272796	Licznik ciepła  - Solution Space L01 (80272796)	\N	LC	1270	6	\N
LM_LH_ADR229	80271273	Licznik chłodu Solution Space L01 (80271273)	\N	LH	480	6	\N
LM_LH_ADR212	62065884	Licznik chłodu Solution Space L03 serwerownia (62065884)	\N	LH	420	6	\N
LM_LH_ADR231	71259540	Licznik chłodu Solution Space L01 (71259540)	\N	LH	490	6	\N
LM_ELE_ADR085	65341010	SP K3 - Tablica TNK 3.2 - Solution Space L01 (65341010)	\N	ELE	2140	6	\N
LM_ELE_ADR097	65341005	SP K3 - Tablica TNK 3.2 - Solution Space L03 (65341005)	\N	ELE	880	6	\N
LM_LC_ADR179	80272795	Licznik ciepła  - Solution Space L00 (80272795)	\N	LC	30	6	\N
recznie590	48503026H16502010252	Davide ręcznie z dużą drabiną	Davide poziom 0	ELE	\N	8	\N
recznie610	48503026H16502010237	Davide ręcznie z dużą drabiną	Davide poziom 0	ELE	\N	8	\N
zdemontowany580	48503026H16472010063	Davide zdemontowany	\N	ELE	\N	8	\N
LM_LH_ADR188	71512146	Licznik chłodu - Les Amis L00 (strefa 4B) (71512146)	\N	LH	1370	9	\N
LM_LC_ADR193	67884166	Licznik ciepła - Les Amis (nad barem) (67884166)	\N	LC	2660	9	\N
LM_ELE_ADR115	2316371005	AHU R3KZ Les Amis (63371005)	\N	ELE	90	9	\N
LM_ELE_ADR113	2316371016	AHU R3 LES AMIS (63371016)	\N	ELE	2200	9	\N
LM_WOD_ADR237	181235653A	Wodomierz LES AMIS (18740005)	\N	WOD	1690	9	\N
LM_ELE_ADR094	1818244023	Licznik elektryczny - Les Amis L01 (35244023)	\N	ELE	860	9	\N
LM_ELE_ADR010	2316371007	AHU 2.3 MBDA (63371007)	\N	ELE	2280	5	\N
LM_ELE_ADR075	48503026H16502010245	SP U3 - MBDA tablica TN (16380798)	\N	ELE	2690	5	\N
LM_ELE_ADR108	2316371009	Magazyn U.01  HBO Magazyn (63371009)	\N	ELE	2170	2	\N
LM_LH_ADR_B35	620665881	Licznik chłodu najemcy FC L05 HBO serw - obieg FO (HC01) (62065881)	\N	LH	2540	2	\N
\.


--
-- Data for Name: najemcy; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.najemcy (id, nazwa, telefon) FROM stdin;
1	Green Cafe Nero	\N
2	HBO	\N
3	Seewald	\N
4	Almidecor	\N
5	MBDA	\N
6	Solution Space	\N
7	Culinary ON	\N
8	Davide	\N
9	Les Amis	\N
10	PZDF	\N
11	Audi	\N
12	Budynek Ethos	\N
13	Amaro	\N
14	Heban	\N
15	Hogan	\N
16	Kruk	\N
17	EON	\N
18	Ergo	\N
19	Leonardo	\N
20	NDI	\N
21	Zegna	\N
\.


--
-- Data for Name: odczyty; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.odczyty (data, adres, odczyt) FROM stdin;
2022-07-01	LM_LC_ADR170	57.3800000000000026
2022-07-01	LM_LC_ADR172	136.259999999999991
2022-07-01	LM_LC_ADR179	88.4399999999999977
2022-07-01	LM_ELE_ADR021	290944.909999999974
2022-07-01	LM_ELE_ADR078	57593
2022-07-01	LM_ELE_ADR066	0
2022-07-01	LM_ELE_ADR080	180056.630000000005
2022-07-01	LM_LH_ADR199	150.699999999999989
2022-07-01	LM_ELE_ADR115	27858.9700000000012
2022-07-01	LM_WOD_ADR249_Solution Space	117.159999999999997
2022-07-01	LM_WOD_MAIN_W	0
2022-07-01	LM_LC_ADR123	547.299999999999955
2022-07-01	LM_LC_ADR151	31384
2022-07-01	LM_LC_ADR153	10646
2022-07-01	LM_LC_ADR154	2756.69999999999982
2022-07-01	LM_LC_ADR155	7219.30000000000018
2022-07-01	LM_LC_ADR157	1136.09999999999991
2022-07-01	LM_LC_ADR158	371
2022-07-01	LM_LC_ADR162	812.899999999999977
2022-07-01	LM_LC_ADR168	120.799999999999997
2022-07-01	LM_LC_ADR173	103.379999999999995
2022-07-01	LM_LC_ADR174	224.199999999999989
2022-07-01	LM_LC_ADR175	0
2022-07-01	LM_LC_ADR176	85.9000000000000057
2022-07-01	LM_LC_ADR178	142.900000000000006
2022-07-01	LM_LC_ADR184	45.2299999999999969
2022-07-01	LM_LC_ADR186	19.2300000000000004
2022-07-01	LM_LC_ADR187	32.6899999999999977
2022-07-01	LM_LC_ADR209	0
2022-07-01	LM_LC_ADR32	0
2022-07-01	LM_LC_ADR82	30.9100000000000001
2022-07-01	LM_LH_ADR122	18.8999999999999986
2022-07-01	LM_LH_ADR189	65.2000000000000028
2022-07-01	LM_LH_ADR195	466.199999999999989
2022-07-01	LM_LH_ADR196	9
2022-07-01	LM_LH_ADR198	1328.09999999999991
2022-07-01	LM_LH_ADR200	50.7999999999999972
2022-07-01	LM_LH_ADR203	230.5
2022-07-01	LM_LH_ADR204	108.200000000000003
2022-07-01	LM_LH_ADR208	341.5
2022-07-01	LM_LH_ADR211	42.7999999999999972
2022-07-01	LM_LH_ADR212	220.5
2022-07-01	LM_LH_ADR216	37.5700000000000003
2022-07-01	LM_LH_ADR218	470.399999999999977
2022-07-01	LM_LH_ADR221	388
2022-07-01	LM_LH_ADR222	0
2022-07-01	LM_LH_ADR227	41.2000000000000028
2022-07-01	LM_LH_ADR229	0
2022-07-01	LM_LH_ADR231	0
2022-07-01	LM_LH_ADR234	0
2022-07-01	LM_LH_ADR235	93.7999999999999972
2022-07-01	LM_LH_ADR33	0
2022-07-01	LM_ELE_ADR008	107658.100000000006
2022-07-01	LM_ELE_ADR012	95750.3699999999953
2022-07-01	LM_ELE_ADR017	13458.3400000000001
2022-07-01	LM_ELE_ADR019	4038.61000000000013
2022-07-01	LM_ELE_ADR024	132698.829999999987
2022-07-01	LM_ELE_ADR027	36475.9100000000035
2022-07-01	LM_LC_ADR163	31.0599999999999987
2022-07-01	LM_LC_ADR164	0.0200000000000000004
2022-07-01	LM_LH_ADR201	108.299999999999997
2022-07-01	LM_ELE_ADR029	14653.0200000000004
2022-07-01	LM_ELE_ADR031	197992.109999999986
2022-07-01	LM_ELE_ADR038	387295.590000000026
2022-07-01	LM_ELE_ADR041	69146.0500000000029
2022-07-01	LM_ELE_ADR045	6263.0600000000004
2022-07-01	LM_ELE_ADR047	5546.5
2022-07-01	LM_ELE_ADR049	15252.1800000000003
2022-07-01	LM_ELE_ADR052	11577.8799999999992
2022-07-01	LM_ELE_ADR054	32078.8499999999985
2022-07-01	LM_ELE_ADR057	6386.4399999999996
2022-07-01	LM_ELE_ADR059	25007.7200000000012
2022-07-01	LM_ELE_ADR060	0
2022-07-01	LM_ELE_ADR061	0
2022-07-01	LM_ELE_ADR062	24203
2022-07-01	LM_ELE_ADR065	0
2022-07-01	LM_ELE_ADR067	336
2022-07-01	LM_ELE_ADR068	11055
2022-07-01	LM_ELE_ADR070	88
2022-07-01	LM_ELE_ADR071	84632
2022-07-01	LM_ELE_ADR073	88
2022-07-01	LM_ELE_ADR077	1063
2022-07-01	LM_ELE_ADR084	57216.7900000000009
2022-07-01	LM_ELE_ADR086	16308.7800000000007
2022-07-01	LM_ELE_ADR088	41588.6900000000023
2022-07-01	LM_ELE_ADR094	1495.75999999999999
2022-07-01	LM_ELE_ADR095	107784.380000000005
2022-07-01	LM_ELE_ADR097	35288.8799999999974
2022-07-01	LM_ELE_ADR098	3693.78999999999996
2022-07-01	LM_ELE_ADR099	90719.1499999999942
2022-07-01	LM_ELE_ADR100	20164.6500000000015
2022-07-01	LM_ELE_ADR101	8377.45000000000073
2022-07-01	LM_ELE_ADR111	362.620000000000005
2022-07-01	LM_ELE_ADR116	15151.0100000000002
2022-07-01	LM_ELE_ADR118	21845.7000000000007
2022-07-01	LM_ELE_ADR119	78925.7799999999988
2022-07-01	LM_ELE_ADR120	96175.7100000000064
2022-07-01	LM_WOD_ADR129	129.810000000000002
2022-07-01	LM_WOD_ADR140	123.599999999999994
2022-07-01	LM_WOD_ADR147	63.5600000000000023
2022-07-01	LM_WOD_ADR246_Solution Space	592.419999999999959
2022-07-01	LM_WOD_ADR248_Solution Space	51.9799999999999969
2022-07-01	LM_ELE_ADR_B03	133927.859999999986
2022-07-01	LM_ELE_ADR_B07	106398.839999999997
2022-07-01	LM_ELE_ADR_B08	158308.76999999999
2022-07-01	LM_LC_ADR_B26	171.159999999999997
2022-07-01	LM_LC_ADR_B30	451.800000000000011
2022-07-01	LM_LC_ADR_B32	994.100000000000023
2022-07-01	LM_LC_ADR_B33	898.799999999999955
2022-07-01	LM_LH_ADR_B19	108.400000000000006
2022-07-01	LM_LH_ADR_B21	207.5
2022-07-01	LM_LH_ADR_B34	0
2022-07-01	LM_LH_ADR_B37	0.400000000000000022
2022-07-01	LM_LH_ADR_B39	103.5
2022-07-01	LM_LH_ADR_B40	174.900000000000006
2022-07-01	LM_LH_ADR_B42	0
2022-07-01	LM_WOD_ADR_B78	197.930000000000007
2022-07-01	LM_LC_ADR102	56.009999999999998
2022-07-01	LM_LC_ADR103	61.7000000000000028
2022-07-01	LM_LC_ADR104	83.6099999999999994
2022-07-01	LM_LC_ADR152	5154.30000000000018
2022-07-01	LM_LC_ADR149	0.910000000000000031
2022-07-01	LM_LC_ADR156	3673.90000000000009
2022-07-01	LM_LC_ADR171	308.379999999999995
2022-07-01	LM_LC_ADR165	51.8200000000000003
2022-07-01	LM_LC_ADR166	40.6099999999999994
2022-07-01	LM_LC_ADR180	148
2022-07-01	LM_LC_ADR181	0.100000000000000006
2022-07-01	LM_LC_ADR182	93.4000000000000057
2022-07-01	LM_LC_ADR183	1.41999999999999993
2022-07-01	LM_LC_ADR185	19.25
2022-07-01	LM_LC_ADR161	1487.90000000000009
2022-07-01	LM_LC_ADR224	176.360000000000014
2022-07-01	LM_LC_ADR89	40.1000000000000014
2022-07-01	LM_LC_ADR93	39.6099999999999994
2022-07-01	LM_LH_ADR145	10.0700000000000003
2022-07-01	LM_LH_ADR188	32.1799999999999997
2022-07-01	LM_LH_ADR190	7.88999999999999968
2022-07-01	LM_LH_ADR191	18.8000000000000007
2022-07-01	LM_LH_ADR192	0
2022-07-01	LM_LH_ADR194	0
2022-07-01	LM_LH_ADR207	431.300000000000011
2022-07-01	LM_LH_ADR197	1328.70000000000005
2022-07-01	LM_LH_ADR215	0
2022-07-01	LM_LH_ADR219	0.0299999999999999989
2022-07-01	LM_LH_ADR220	112.200000000000003
2022-07-01	LM_LH_ADR223	209.699999999999989
2022-07-01	LM_LH_ADR225	73.5
2022-07-01	LM_LH_ADR226	83.7600000000000051
2022-07-01	LM_LH_ADR217	529.600000000000023
2022-07-01	LM_LH_ADR228	32.1000000000000014
2022-07-01	LM_LH_ADR232	63.1099999999999994
2022-07-01	LM_LH_ADR233	49.1000000000000014
2022-07-01	LM_LH_ADR230	1.69999999999999996
2022-07-01	LM_ELE_ADR114	27.8099999999999987
2022-07-01	LM_ELE_ADR117	22970.5699999999997
2022-07-01	LM_WOD_ADR132	311.920000000000016
2022-07-01	LM_WOD_ADR133	358.079999999999984
2022-07-01	LM_WOD_ADR134	19
2022-07-01	LM_WOD_ADR135	0
2022-07-01	LM_WOD_ADR136	72.4099999999999966
2022-07-01	LM_WOD_ADR139	1572.90000000000009
2022-07-01	LM_WOD_ADR141	17
2022-07-01	LM_WOD_ADR142	36
2022-07-01	LM_WOD_ADR143	582.860000000000014
2022-07-01	LM_WOD_ADR146	32184
2022-07-01	LM_WOD_ADR148	0.0400000000000000008
2022-07-01	LM_WOD_ADR150	44.0700000000000003
2022-07-01	LM_WOD_ADR237	924.629999999999995
2022-07-01	LM_WOD_ADR238	2543.96000000000004
2022-07-01	LM_WOD_ADR239	37.7199999999999989
2022-07-01	LM_WOD_ADR240	148.240000000000009
2022-07-01	LM_WOD_ADR241	283.560000000000002
2022-07-01	LM_ELE_ADR121	222733.059999999998
2022-07-01	LM_ELE_ADR128	0
2022-07-01	LM_WOD_ADR247_Solution Space	634.200000000000045
2022-07-01	LM_WOD_ADR250_Solution Space	219.77000000000001
2022-07-01	LM_WOD_ADR30	0
2022-07-01	LM_ELE_ADR001	72028.5599999999977
2022-07-01	LM_ELE_ADR002	93230.4799999999959
2022-07-01	LM_ELE_ADR003	125026.270000000004
2022-07-01	LM_ELE_ADR006	0
2022-07-01	LM_ELE_ADR007	144870.079999999987
2022-07-01	LM_ELE_ADR009	196862.670000000013
2022-07-01	LM_ELE_ADR011	178260.880000000005
2022-07-01	LM_ELE_ADR013	235891.630000000005
2022-07-01	LM_ELE_ADR014	15599.7099999999991
2022-07-01	LM_ELE_ADR015	138966.390000000014
2022-07-01	LM_ELE_ADR016	975281.939999999944
2022-07-01	LM_ELE_ADR018	13873.7399999999998
2022-07-01	LM_ELE_ADR020	142979.609999999986
2022-07-01	LM_ELE_ADR022	173347.950000000012
2022-07-01	LM_ELE_ADR023	37106.9700000000012
2022-07-01	LM_ELE_ADR025	601433.130000000005
2022-07-01	LM_ELE_ADR028	19956.119999999999
2022-07-01	LM_ELE_ADR034	31908.0600000000013
2022-07-01	LM_ELE_ADR036	93833.7799999999988
2022-07-01	LM_ELE_ADR039	386735.590000000026
2022-07-01	LM_ELE_ADR040	36656.9000000000015
2022-07-01	LM_ELE_ADR042	3663.69999999999982
2022-07-01	LM_ELE_ADR044	7087.77999999999975
2022-07-01	LM_ELE_ADR048	7455.55000000000018
2022-07-01	LM_ELE_ADR051	7149.27000000000044
2022-07-01	LM_ELE_ADR053	29548.0299999999988
2022-07-01	LM_ELE_ADR055	5903.21000000000004
2022-07-01	LM_ELE_ADR056	0
2022-07-01	LM_ELE_ADR063	190
2022-07-01	LM_ELE_ADR064	0
2022-07-01	LM_ELE_ADR058	86380.8999999999942
2022-07-01	LM_ELE_ADR072	28553
2022-07-01	LM_ELE_ADR074	84632
2022-07-01	LM_ELE_ADR076	0
2022-07-01	LM_ELE_ADR081	69447.6499999999942
2022-07-01	LM_ELE_ADR085	62098.6800000000003
2022-07-01	LM_ELE_ADR090	42335.0699999999997
2022-07-01	LM_ELE_ADR107	91734.3899999999994
2022-07-01	LM_ELE_ADR108	7133.65999999999985
2022-07-01	LM_ELE_ADR109	2038.88000000000011
2022-07-01	LM_ELE_ADR110	415.269999999999982
2022-07-01	LM_ELE_ADR113	57066.9599999999991
2022-07-01	LM_ELE_ADR087	92304.3999999999942
2022-07-01	LM_LC_ADR_B45	222.550000000000011
2022-07-01	LM_LH_ADR_B46	49.3500000000000014
2022-07-01	LM_LH_ADR_B47	132
2022-07-01	LM_WOD_ADR_B74	39.1099999999999994
2022-07-01	LM_ELE_ADR_B06	507190.530000000028
2022-07-01	LM_ELE_ADR046	0
2022-07-01	LM_ELE_ADR010	124094.369999999995
2022-07-01	LM_ELE_ADR043	2961.61999999999989
2022-07-01	LM_ELE_ADR_B11	35375.25
2022-07-01	LM_WOD_ADR242	45.0900000000000034
2022-07-01	LM_ELE_ADR124	120544.220000000001
2022-07-01	LM_ELE_ADR112	746744.880000000005
2022-07-01	LM_WOD_ADR_B75	186.199999999999989
2022-07-01	LM_ELE_ADR091	13055.0499999999993
2022-07-01	LM_WOD_ADR_B80	134.02000000000001
2022-07-01	LM_WOD_ADR_B81	46.5700000000000003
2022-07-01	LM_ELE_ADR_B04	288663.159999999974
2022-07-01	LM_ELE_ADR_B05	276909.940000000002
2022-07-01	LM_ELE_ADR_B09	309238.090000000026
2022-07-01	LM_ELE_ADR_B01	0
2022-07-01	LM_ELE_ADR_B10	31900.7999999999993
2022-07-01	LM_ELE_ADR_B02	0
2022-07-01	LM_LC_ADR_B18	18.8000000000000007
2022-07-01	LM_LC_ADR_B20	69.8199999999999932
2022-07-01	LM_LC_ADR_B22	56.3800000000000026
2022-07-01	LM_LC_ADR_B24	10.6899999999999995
2022-07-01	LM_LC_ADR_B31	465.199999999999989
2022-07-01	LM_LC_ADR_B41	529.700000000000045
2022-07-01	LM_LC_ADR_B43	9.19999999999999929
2022-07-01	LM_LH_ADR_B23	73.9000000000000057
2022-07-01	LM_LH_ADR_B25	77.7000000000000028
2022-07-01	LM_LH_ADR_B27	162.300000000000011
2022-07-01	LM_LH_ADR_B35	0
2022-07-01	LM_LH_ADR_B36	0
2022-07-01	LM_LH_ADR_B38	74.0999999999999943
2022-07-01	LM_LH_ADR_B44	4.59999999999999964
2022-07-01	LM_WOD_ADR_B76	1741.49000000000001
2022-07-01	LM_WOD_ADR_B77	9.0600000000000005
2022-07-01	LM_LC_ADR_B16	38.8200000000000003
2022-07-01	LM_LH_ADR_B17	56.7999999999999972
2022-07-01	LM_WOD_ADR_B79	360.110000000000014
2022-07-01	LM_ELE_ADR_B12	19276.7299999999996
2022-07-01	LM_ELE_ADR_B13	15053.1900000000005
2022-07-01	LM_LC_ADR_B46	58.8699999999999974
2022-07-01	LM_LC_ADR193	0
2022-07-01	LM_ELE_ADR125	5112.76000000000022
2022-07-01	LM_ELE_ADR069	317187
2021-06-01	LM_LC_ADR170	48.8900000000000006
2021-06-01	LM_LC_ADR172	90.1200000000000045
2021-06-01	LM_LC_ADR179	70.5999999999999943
2021-06-01	LM_ELE_ADR021	192566.339999999997
2021-06-01	LM_ELE_ADR078	35268
2021-06-01	LM_ELE_ADR066	0
2021-06-01	LM_ELE_ADR080	144294.799999999988
2021-06-01	LM_LH_ADR199	117.200000000000003
2021-06-01	LM_ELE_ADR115	20223.9300000000003
2021-06-01	LM_WOD_ADR249_Solution Space	68.0499999999999972
2021-06-01	LM_WOD_MAIN_W	0
2021-06-01	LM_LC_ADR123	363.399999999999977
2021-06-01	LM_LC_ADR151	25963
2021-06-01	LM_LC_ADR153	9212
2021-06-01	LM_LC_ADR154	2096.09999999999991
2021-06-01	LM_LC_ADR155	5619.69999999999982
2021-06-01	LM_LC_ADR157	903.399999999999977
2021-06-01	LM_LC_ADR158	282.5
2021-06-01	LM_LC_ADR162	656.600000000000023
2021-06-01	LM_LC_ADR168	69
2021-06-01	LM_LC_ADR173	79.3100000000000023
2021-06-01	LM_LC_ADR174	133.639999999999986
2021-06-01	LM_LC_ADR175	0
2021-06-01	LM_LC_ADR176	84.5999999999999943
2021-06-01	LM_LC_ADR178	95.2000000000000028
2021-06-01	LM_LC_ADR184	38.9600000000000009
2021-06-01	LM_LC_ADR186	15.5399999999999991
2021-06-01	LM_LC_ADR187	29.0399999999999991
2021-06-01	LM_LC_ADR209	84.1899999999999977
2021-06-01	LM_LC_ADR32	0
2021-06-01	LM_LC_ADR82	0
2021-06-01	LM_LH_ADR122	9.09999999999999964
2021-06-01	LM_LH_ADR189	40.5300000000000011
2021-06-01	LM_LH_ADR195	330.600000000000023
2021-06-01	LM_LH_ADR196	9
2021-06-01	LM_LH_ADR198	951.299999999999955
2021-06-01	LM_LH_ADR200	37.8999999999999986
2021-06-01	LM_LH_ADR203	194.800000000000011
2021-06-01	LM_LH_ADR204	76.4000000000000057
2021-06-01	LM_LH_ADR208	239.300000000000011
2021-06-01	LM_LH_ADR211	17.1000000000000014
2021-06-01	LM_LH_ADR212	94.5
2021-06-01	LM_LH_ADR216	26.1499999999999986
2021-06-01	LM_LH_ADR218	320.5
2021-06-01	LM_LH_ADR221	209.5
2021-06-01	LM_LH_ADR222	0
2021-06-01	LM_LH_ADR227	28
2021-06-01	LM_LH_ADR229	82.1599999999999966
2021-06-01	LM_LH_ADR231	0
2021-06-01	LM_LH_ADR234	0
2021-06-01	LM_LH_ADR235	78
2021-06-01	LM_LH_ADR33	0
2021-06-01	LM_ELE_ADR008	73981.5299999999988
2021-06-01	LM_ELE_ADR012	58983.2900000000009
2021-06-01	LM_ELE_ADR017	10418.6000000000004
2021-06-01	LM_ELE_ADR019	2439.5
2021-06-01	LM_ELE_ADR024	105229.130000000005
2021-06-01	LM_ELE_ADR027	33393.0400000000009
2021-06-01	LM_LC_ADR163	26.4400000000000013
2021-06-01	LM_LC_ADR164	0.0200000000000000004
2021-06-01	LM_LH_ADR201	49.5
2021-06-01	LM_ELE_ADR029	8793.51000000000022
2021-06-01	LM_ELE_ADR031	135128.660000000003
2021-06-01	LM_ELE_ADR038	245291.059999999998
2021-06-01	LM_ELE_ADR041	56748.989999999998
2021-06-01	LM_ELE_ADR045	4896.3100000000004
2021-06-01	LM_ELE_ADR047	4383.63000000000011
2021-06-01	LM_ELE_ADR049	12459.6000000000004
2021-06-01	LM_ELE_ADR052	9261.3700000000008
2021-06-01	LM_ELE_ADR054	25997.0299999999988
2021-06-01	LM_ELE_ADR057	5152.67000000000007
2021-06-01	LM_ELE_ADR059	18866.3499999999985
2021-06-01	LM_ELE_ADR060	0
2021-06-01	LM_ELE_ADR061	0
2021-06-01	LM_ELE_ADR062	15578
2021-06-01	LM_ELE_ADR065	0
2021-06-01	LM_ELE_ADR067	125
2021-06-01	LM_ELE_ADR068	385
2021-06-01	LM_ELE_ADR070	80
2021-06-01	LM_ELE_ADR071	60950
2021-06-01	LM_ELE_ADR073	80
2021-06-01	LM_ELE_ADR077	1063
2021-06-01	LM_ELE_ADR084	47209.1600000000035
2021-06-01	LM_ELE_ADR086	10480.7800000000007
2021-06-01	LM_ELE_ADR088	29262.2000000000007
2021-06-01	LM_ELE_ADR094	1238.70000000000005
2021-06-01	LM_ELE_ADR095	80342.5099999999948
2021-06-01	LM_ELE_ADR097	21701.4799999999996
2021-06-01	LM_ELE_ADR098	2909.9699999999998
2021-06-01	LM_ELE_ADR099	53031.1800000000003
2021-06-01	LM_ELE_ADR100	12352
2021-06-01	LM_ELE_ADR101	5822.81999999999971
2021-06-01	LM_ELE_ADR111	362.069999999999993
2021-06-01	LM_ELE_ADR116	7935.64000000000033
2021-06-01	LM_ELE_ADR118	17897.0900000000001
2021-06-01	LM_ELE_ADR119	61974.3700000000026
2021-06-01	LM_ELE_ADR120	72537.4700000000012
2021-06-01	LM_WOD_ADR129	85.7199999999999989
2021-06-01	LM_WOD_ADR140	120.030000000000001
2021-06-01	LM_WOD_ADR147	49.1300000000000026
2021-06-01	LM_WOD_ADR246_Solution Space	387.230000000000018
2021-06-01	LM_WOD_ADR248_Solution Space	27.9299999999999997
2021-06-01	LM_ELE_ADR_B03	107709.399999999994
2021-06-01	LM_ELE_ADR_B07	85880.5899999999965
2021-06-01	LM_ELE_ADR_B08	128213.570000000007
2021-06-01	LM_LC_ADR_B26	104.640000000000001
2021-06-01	LM_LC_ADR_B30	342.800000000000011
2021-06-01	LM_LC_ADR_B32	764.799999999999955
2021-06-01	LM_LC_ADR_B33	649.799999999999955
2021-06-01	LM_LH_ADR_B19	67.5999999999999943
2021-06-01	LM_LH_ADR_B21	142.400000000000006
2021-06-01	LM_LH_ADR_B34	0
2021-06-01	LM_LH_ADR_B37	0.400000000000000022
2021-06-01	LM_LH_ADR_B39	78.5999999999999943
2021-06-01	LM_LH_ADR_B40	136
2021-06-01	LM_LH_ADR_B42	0
2021-06-01	LM_WOD_ADR_B78	173.379999999999995
2021-06-01	LM_LC_ADR102	40.8400000000000034
2021-06-01	LM_LC_ADR103	44.8900000000000006
2021-06-01	LM_LC_ADR104	54.6899999999999977
2021-06-01	LM_LC_ADR152	4236
2021-06-01	LM_LC_ADR149	0.910000000000000031
2021-06-01	LM_LC_ADR156	2744.90000000000009
2021-06-01	LM_LC_ADR171	238.800000000000011
2021-06-01	LM_LC_ADR165	35.7700000000000031
2021-06-01	LM_LC_ADR166	28.9100000000000001
2021-06-01	LM_LC_ADR180	123.700000000000003
2021-06-01	LM_LC_ADR181	0.100000000000000006
2021-06-01	LM_LC_ADR182	73.2999999999999972
2021-06-01	LM_LC_ADR183	1.41999999999999993
2021-06-01	LM_LC_ADR185	16.129999999999999
2021-06-01	LM_LC_ADR161	1198.09999999999991
2021-06-01	LM_LC_ADR224	123.620000000000005
2021-06-01	LM_LC_ADR89	26.0100000000000016
2021-06-01	LM_LC_ADR93	25.5100000000000016
2021-06-01	LM_LH_ADR145	5.54000000000000004
2021-06-01	LM_LH_ADR188	19.4400000000000013
2021-06-01	LM_LH_ADR190	5.29000000000000004
2021-06-01	LM_LH_ADR191	13
2021-06-01	LM_LH_ADR192	0
2021-06-01	LM_LH_ADR194	670.299999999999955
2021-06-01	LM_LH_ADR207	378.199999999999989
2021-06-01	LM_LH_ADR197	1082.59999999999991
2021-06-01	LM_LH_ADR215	0
2021-06-01	LM_LH_ADR219	0.0200000000000000004
2021-06-01	LM_LH_ADR220	71.980000000000004
2021-06-01	LM_LH_ADR223	130.400000000000006
2021-06-01	LM_LH_ADR225	52
2021-06-01	LM_LH_ADR226	50.9699999999999989
2021-06-01	LM_LH_ADR217	424.699999999999989
2021-06-01	LM_LH_ADR228	26.5
2021-06-01	LM_LH_ADR232	45.0799999999999983
2021-06-01	LM_LH_ADR233	33.1000000000000014
2021-06-01	LM_LH_ADR230	1.5
2021-06-01	LM_ELE_ADR114	207899.48000000001
2021-06-01	LM_ELE_ADR117	20134.7700000000004
2021-06-01	LM_WOD_ADR132	254.460000000000008
2021-06-01	LM_WOD_ADR133	316.990000000000009
2021-06-01	LM_WOD_ADR134	18.0199999999999996
2021-06-01	LM_WOD_ADR135	0
2021-06-01	LM_WOD_ADR136	60.7700000000000031
2021-06-01	LM_WOD_ADR139	1032.98000000000002
2021-06-01	LM_WOD_ADR141	17
2021-06-01	LM_WOD_ADR142	36
2021-06-01	LM_WOD_ADR143	299.54000000000002
2021-06-01	LM_WOD_ADR146	24155.2999999999993
2021-06-01	LM_WOD_ADR148	0.0500000000000000028
2021-06-01	LM_WOD_ADR150	32.0200000000000031
2021-06-01	LM_WOD_ADR237	779.200000000000045
2021-06-01	LM_WOD_ADR238	2209.21000000000004
2021-06-01	LM_WOD_ADR239	25.7800000000000011
2021-06-01	LM_WOD_ADR240	88.6099999999999994
2021-06-01	LM_WOD_ADR241	880.080000000000041
2021-06-01	LM_ELE_ADR121	85.4399999999999977
2021-06-01	LM_ELE_ADR128	0
2021-06-01	LM_WOD_ADR247_Solution Space	350.95999999999998
2021-06-01	LM_WOD_ADR250_Solution Space	127.599999999999994
2021-06-01	LM_WOD_ADR30	0
2021-06-01	LM_ELE_ADR001	56427.9100000000035
2021-06-01	LM_ELE_ADR002	75395.0599999999977
2021-06-01	LM_ELE_ADR003	90935.4700000000012
2021-06-01	LM_ELE_ADR006	65550.2200000000012
2021-06-01	LM_ELE_ADR007	110943.970000000001
2021-06-01	LM_ELE_ADR009	152491.48000000001
2021-06-01	LM_ELE_ADR011	150191.859999999986
2021-06-01	LM_ELE_ADR013	191491.579999999987
2021-06-01	LM_ELE_ADR014	11440.8799999999992
2021-06-01	LM_ELE_ADR015	105475.880000000005
2021-06-01	LM_ELE_ADR016	821760.810000000056
2021-06-01	LM_ELE_ADR018	10877.5499999999993
2021-06-01	LM_ELE_ADR020	114805.679999999993
2021-06-01	LM_ELE_ADR022	109758.089999999997
2021-06-01	LM_ELE_ADR023	23986.5600000000013
2021-06-01	LM_ELE_ADR025	321945.440000000002
2021-06-01	LM_ELE_ADR028	15546.6700000000001
2021-06-01	LM_ELE_ADR034	17813.0099999999984
2021-06-01	LM_ELE_ADR036	77533.3099999999977
2021-06-01	LM_ELE_ADR039	262252.559999999998
2021-06-01	LM_ELE_ADR040	29531
2021-06-01	LM_ELE_ADR042	2900.5
2021-06-01	LM_ELE_ADR044	5800.4399999999996
2021-06-01	LM_ELE_ADR048	6095.31999999999971
2021-06-01	LM_ELE_ADR051	5774.03999999999996
2021-06-01	LM_ELE_ADR053	15347.9500000000007
2021-06-01	LM_ELE_ADR055	4731.25
2021-06-01	LM_ELE_ADR056	18394.7400000000016
2021-06-01	LM_ELE_ADR063	189
2021-06-01	LM_ELE_ADR064	0
2021-06-01	LM_ELE_ADR058	68719.6600000000035
2021-06-01	LM_ELE_ADR072	19575
2021-06-01	LM_ELE_ADR074	60950
2021-06-01	LM_ELE_ADR076	0
2021-06-01	LM_ELE_ADR081	35676.7699999999968
2021-06-01	LM_ELE_ADR085	34477.1399999999994
2021-06-01	LM_ELE_ADR090	31482.0600000000013
2021-06-01	LM_ELE_ADR107	60698.4599999999991
2021-06-01	LM_ELE_ADR108	5774.77999999999975
2021-06-01	LM_ELE_ADR109	2010.96000000000004
2021-06-01	LM_ELE_ADR110	406.220000000000027
2021-06-01	LM_ELE_ADR113	43660.8700000000026
2021-06-01	LM_ELE_ADR087	75488.8699999999953
2021-06-01	LM_LC_ADR_B45	146.870000000000005
2021-06-01	LM_LH_ADR_B46	49.3500000000000014
2021-06-01	LM_LH_ADR_B47	83.5
2021-06-01	LM_WOD_ADR_B74	25.5199999999999996
2021-06-01	LM_ELE_ADR_B06	356973.25
2021-06-01	LM_ELE_ADR046	0
2021-06-01	LM_ELE_ADR010	96480.2299999999959
2021-06-01	LM_ELE_ADR043	2298.65000000000009
2021-06-01	LM_ELE_ADR_B11	26790.119999999999
2021-06-01	LM_WOD_ADR242	40.240000000000002
2021-06-01	LM_ELE_ADR124	52028.989999999998
2021-06-01	LM_ELE_ADR112	645954.810000000056
2021-06-01	LM_WOD_ADR_B75	122.519999999999996
2021-06-01	LM_ELE_ADR091	8611.27000000000044
2021-06-01	LM_WOD_ADR_B80	87.5400000000000063
2021-06-01	LM_WOD_ADR_B81	35.6199999999999974
2021-06-01	LM_ELE_ADR_B04	211503.73000000001
2021-06-01	LM_ELE_ADR_B05	189549.970000000001
2021-06-01	LM_ELE_ADR_B09	246870.890000000014
2021-06-01	LM_ELE_ADR_B01	0
2021-06-01	LM_ELE_ADR_B10	25096.6699999999983
2021-06-01	LM_ELE_ADR_B02	0
2021-06-01	LM_LC_ADR_B18	14.4600000000000009
2021-06-01	LM_LC_ADR_B20	58.1099999999999994
2021-06-01	LM_LC_ADR_B22	30.3500000000000014
2021-06-01	LM_LC_ADR_B24	10
2021-06-01	LM_LC_ADR_B31	350
2021-06-01	LM_LC_ADR_B41	382.800000000000011
2021-06-01	LM_LC_ADR_B43	5.29999999999999982
2021-06-01	LM_LH_ADR_B23	44.3999999999999986
2021-06-01	LM_LH_ADR_B25	24
2021-06-01	LM_LH_ADR_B27	79.9000000000000057
2021-06-01	LM_LH_ADR_B35	0
2021-06-01	LM_LH_ADR_B36	0
2021-06-01	LM_LH_ADR_B38	61.7999999999999972
2021-06-01	LM_LH_ADR_B44	3.39999999999999991
2021-06-01	LM_WOD_ADR_B76	1242.50999999999999
2021-06-01	LM_WOD_ADR_B77	5.51999999999999957
2021-06-01	LM_LC_ADR_B16	32.4500000000000028
2021-06-01	LM_LH_ADR_B17	38.3999999999999986
2021-06-01	LM_WOD_ADR_B79	315.170000000000016
2021-06-01	LM_ELE_ADR_B12	13608.0900000000001
2021-06-01	LM_ELE_ADR_B13	13060.8799999999992
2021-06-01	LM_LC_ADR_B46	45.0700000000000003
2021-06-01	LM_LC_ADR193	0
2021-06-01	LM_ELE_ADR125	3967.09999999999991
2021-06-01	LM_ELE_ADR069	237816
2021-06-01	LM_ELE_ADR075	80
2022-07-01	LM_ELE_ADR075	11724
2022-07-01	LM_LC_ADR159	5030
2022-07-01	LM_LC_ADR160	13230
2022-07-01	LM_LH_ADR167	5720
2022-07-01	LM_WOD_ADR236	16.7699999999999996
2022-07-01	zdemontowany580	6
2022-07-01	zdemontowany600	3194
2022-08-01	LM_LC_ADR170	57.3999999999999986
2022-08-01	LM_LC_ADR172	136.389999999999986
2022-08-01	LM_LC_ADR179	88.4399999999999977
2022-08-01	LM_ELE_ADR021	293087.909999999974
2022-08-01	LM_ELE_ADR078	58053
2022-08-01	LM_ELE_ADR066	0
2022-08-01	LM_ELE_ADR080	181621.420000000013
2022-08-01	LM_LH_ADR199	153.400000000000006
2022-08-01	LM_ELE_ADR115	28235.1399999999994
2022-08-01	LM_WOD_ADR249_Solution Space	120.290000000000006
2022-08-01	LM_WOD_MAIN_W	0
2022-08-01	LM_LC_ADR123	547.799999999999955
2022-08-01	LM_LC_ADR151	31411
2022-08-01	LM_LC_ADR153	10652
2022-08-01	LM_LC_ADR154	2763.5
2022-08-01	LM_LC_ADR155	7226.39999999999964
2022-08-01	LM_LC_ADR157	1137.90000000000009
2022-08-01	LM_LC_ADR158	371.5
2022-08-01	LM_LC_ADR162	813.299999999999955
2022-08-01	LM_LC_ADR168	121
2022-08-01	LM_LC_ADR173	103.510000000000005
2022-08-01	LM_LC_ADR174	225.349999999999994
2022-08-01	LM_LC_ADR175	0
2022-08-01	LM_LC_ADR176	85.9000000000000057
2022-08-01	LM_LC_ADR178	143.340000000000003
2022-08-01	LM_LC_ADR184	45.2299999999999969
2022-08-01	LM_LC_ADR186	19.2300000000000004
2022-08-01	LM_LC_ADR187	32.6899999999999977
2022-08-01	LM_LC_ADR209	0
2022-08-01	LM_LC_ADR32	0
2022-08-01	LM_LC_ADR82	31.2100000000000009
2022-08-01	LM_LH_ADR122	19.6000000000000014
2022-08-01	LM_LH_ADR189	67.4699999999999989
2022-08-01	LM_LH_ADR195	479.699999999999989
2022-08-01	LM_LH_ADR196	9
2022-08-01	LM_LH_ADR198	1350.90000000000009
2022-08-01	LM_LH_ADR200	51.5
2022-08-01	LM_LH_ADR203	232.300000000000011
2022-08-01	LM_LH_ADR204	110.599999999999994
2022-08-01	LM_LH_ADR208	346.300000000000011
2022-08-01	LM_LH_ADR211	43.8999999999999986
2022-08-01	LM_LH_ADR212	226.900000000000006
2022-08-01	LM_LH_ADR216	38.4699999999999989
2022-08-01	LM_LH_ADR218	480.800000000000011
2022-08-01	LM_LH_ADR221	398.199999999999989
2022-08-01	LM_LH_ADR222	0
2022-08-01	LM_LH_ADR227	44
2022-08-01	LM_LH_ADR229	0
2022-08-01	LM_LH_ADR231	0
2022-08-01	LM_LH_ADR234	0
2022-08-01	LM_LH_ADR235	95.7999999999999972
2022-08-01	LM_LH_ADR33	0
2022-08-01	LM_ELE_ADR008	108768.020000000004
2022-08-01	LM_ELE_ADR012	96431.9600000000064
2022-08-01	LM_ELE_ADR017	13533.6100000000006
2022-08-01	LM_ELE_ADR019	4038.63000000000011
2022-08-01	LM_ELE_ADR024	134131.23000000001
2022-08-01	LM_ELE_ADR027	36475.9100000000035
2022-08-01	LM_LC_ADR163	31.0599999999999987
2022-08-01	LM_LC_ADR164	0.0200000000000000004
2022-08-01	LM_LH_ADR201	113.200000000000003
2022-08-01	LM_ELE_ADR029	14973.2399999999998
2022-08-01	LM_ELE_ADR031	199787.880000000005
2022-08-01	LM_ELE_ADR038	394251.909999999974
2022-08-01	LM_ELE_ADR041	69367.3699999999953
2022-08-01	LM_ELE_ADR045	6330.14999999999964
2022-08-01	LM_ELE_ADR047	5604.8100000000004
2022-08-01	LM_ELE_ADR049	15381.6800000000003
2022-08-01	LM_ELE_ADR052	11686.8299999999999
2022-08-01	LM_ELE_ADR054	32364.25
2022-08-01	LM_ELE_ADR057	6445.27000000000044
2022-08-01	LM_ELE_ADR059	25294.6800000000003
2022-08-01	LM_ELE_ADR060	0
2022-08-01	LM_ELE_ADR061	0
2022-08-01	LM_ELE_ADR062	24593
2022-08-01	LM_ELE_ADR065	0
2022-08-01	LM_ELE_ADR067	336
2022-08-01	LM_ELE_ADR068	11728
2022-08-01	LM_ELE_ADR070	88
2022-08-01	LM_ELE_ADR071	85753
2022-08-01	LM_ELE_ADR073	88
2022-08-01	LM_ELE_ADR077	1063
2022-08-01	LM_ELE_ADR084	57587.739999999998
2022-08-01	LM_ELE_ADR086	16615.1800000000003
2022-08-01	LM_ELE_ADR088	42106.510000000002
2022-08-01	LM_ELE_ADR094	1495.96000000000004
2022-08-01	LM_ELE_ADR095	109122.550000000003
2022-08-01	LM_ELE_ADR097	36023.8799999999974
2022-08-01	LM_ELE_ADR098	3734.84999999999991
2022-08-01	LM_ELE_ADR099	92508.7299999999959
2022-08-01	LM_ELE_ADR100	20457.2400000000016
2022-08-01	LM_ELE_ADR101	8503.86000000000058
2022-08-01	LM_ELE_ADR111	362.629999999999995
2022-08-01	LM_ELE_ADR116	15151.0100000000002
2022-08-01	LM_ELE_ADR118	22003.0999999999985
2022-08-01	LM_ELE_ADR119	79595.0500000000029
2022-08-01	LM_ELE_ADR120	97760.0399999999936
2022-08-01	LM_WOD_ADR129	131.710000000000008
2022-08-01	LM_WOD_ADR140	123.739999999999995
2022-08-01	LM_WOD_ADR147	64.2199999999999989
2022-08-01	LM_WOD_ADR246_Solution Space	602.200000000000045
2022-08-01	LM_WOD_ADR248_Solution Space	53.25
2022-08-01	LM_ELE_ADR_B03	135678.059999999998
2022-08-01	LM_ELE_ADR_B07	107862.080000000002
2022-08-01	LM_ELE_ADR_B08	160286.329999999987
2022-08-01	LM_LC_ADR_B26	171.180000000000007
2022-08-01	LM_LC_ADR_B30	452.5
2022-08-01	LM_LC_ADR_B32	994.600000000000023
2022-08-01	LM_LC_ADR_B33	899.700000000000045
2022-08-01	LM_LH_ADR_B19	109.599999999999994
2022-08-01	LM_LH_ADR_B21	210.300000000000011
2022-08-01	LM_LH_ADR_B34	0
2022-08-01	LM_LH_ADR_B37	0.400000000000000022
2022-08-01	LM_LH_ADR_B39	107.599999999999994
2022-08-01	LM_LH_ADR_B40	181.099999999999994
2022-08-01	LM_LH_ADR_B42	0
2022-08-01	LM_WOD_ADR_B78	200.090000000000003
2022-08-01	LM_LC_ADR102	56.1499999999999986
2022-08-01	LM_LC_ADR103	61.8599999999999994
2022-08-01	LM_LC_ADR104	83.8700000000000045
2022-08-01	LM_LC_ADR152	5158.5
2022-08-01	LM_LC_ADR149	0.910000000000000031
2022-08-01	LM_LC_ADR156	3678.69999999999982
2022-08-01	LM_LC_ADR171	308.949999999999989
2022-08-01	LM_LC_ADR165	51.990000000000002
2022-08-01	LM_LC_ADR166	40.7299999999999969
2022-08-01	LM_LC_ADR180	148
2022-08-01	LM_LC_ADR181	0.100000000000000006
2022-08-01	LM_LC_ADR182	93.4399999999999977
2022-08-01	LM_LC_ADR183	1.41999999999999993
2022-08-01	LM_LC_ADR185	19.25
2022-08-01	LM_LC_ADR161	1489
2022-08-01	LM_LC_ADR224	176.879999999999995
2022-08-01	LM_LC_ADR89	40.2299999999999969
2022-08-01	LM_LC_ADR93	39.740000000000002
2022-08-01	LM_LH_ADR145	10.0700000000000003
2022-08-01	LM_LH_ADR188	32.1799999999999997
2022-08-01	LM_LH_ADR190	7.88999999999999968
2022-08-01	LM_LH_ADR191	18.8000000000000007
2022-08-01	LM_LH_ADR192	0
2022-08-01	LM_LH_ADR194	0
2022-08-01	LM_LH_ADR207	433.699999999999989
2022-08-01	LM_LH_ADR197	1345
2022-08-01	LM_LH_ADR215	0
2022-08-01	LM_LH_ADR219	0.0299999999999999989
2022-08-01	LM_LH_ADR220	112.200000000000003
2022-08-01	LM_LH_ADR223	217
2022-08-01	LM_LH_ADR225	77.2000000000000028
2022-08-01	LM_LH_ADR226	83.7600000000000051
2022-08-01	LM_LH_ADR217	537.700000000000045
2022-08-01	LM_LH_ADR228	34
2022-08-01	LM_LH_ADR232	63.9399999999999977
2022-08-01	LM_LH_ADR233	50
2022-08-01	LM_LH_ADR230	1.80000000000000004
2022-08-01	LM_ELE_ADR114	301041.940000000002
2022-08-01	LM_ELE_ADR117	23072.5699999999997
2022-08-01	LM_WOD_ADR132	313.980000000000018
2022-08-01	LM_WOD_ADR133	360.100000000000023
2022-08-01	LM_WOD_ADR134	19.0100000000000016
2022-08-01	LM_WOD_ADR135	0
2022-08-01	LM_WOD_ADR136	72.9099999999999966
2022-08-01	LM_WOD_ADR139	1600.48000000000002
2022-08-01	LM_WOD_ADR141	17
2022-08-01	LM_WOD_ADR142	36
2022-08-01	LM_WOD_ADR143	582.860000000000014
2022-08-01	LM_WOD_ADR146	32583
2022-08-01	LM_WOD_ADR148	0.0400000000000000008
2022-08-01	LM_WOD_ADR150	44.5900000000000034
2022-08-01	LM_WOD_ADR237	924.639999999999986
2022-08-01	LM_WOD_ADR238	2543.96000000000004
2022-08-01	LM_WOD_ADR239	38.4799999999999969
2022-08-01	LM_WOD_ADR240	151.22999999999999
2022-08-01	LM_WOD_ADR241	328.410000000000025
2022-08-01	LM_ELE_ADR121	227845.25
2022-08-01	LM_ELE_ADR128	0
2022-08-01	LM_WOD_ADR247_Solution Space	644.720000000000027
2022-08-01	LM_WOD_ADR250_Solution Space	223.050000000000011
2022-08-01	LM_WOD_ADR30	0
2022-08-01	LM_ELE_ADR001	72979.9900000000052
2022-08-01	LM_ELE_ADR002	93956.6199999999953
2022-08-01	LM_ELE_ADR003	125330.029999999999
2022-08-01	LM_ELE_ADR006	0
2022-08-01	LM_ELE_ADR007	145559.049999999988
2022-08-01	LM_ELE_ADR009	197472.420000000013
2022-08-01	LM_ELE_ADR011	178793.26999999999
2022-08-01	LM_ELE_ADR013	236800.279999999999
2022-08-01	LM_ELE_ADR014	15771.5
2022-08-01	LM_ELE_ADR015	140218.450000000012
2022-08-01	LM_ELE_ADR016	980949.25
2022-08-01	LM_ELE_ADR018	14001.4500000000007
2022-08-01	LM_ELE_ADR020	143992.299999999988
2022-08-01	LM_ELE_ADR022	174643.359999999986
2022-08-01	LM_ELE_ADR023	37740.9700000000012
2022-08-01	LM_ELE_ADR025	616090.380000000005
2022-08-01	LM_ELE_ADR028	19982.9900000000016
2022-08-01	LM_ELE_ADR034	32556.3499999999985
2022-08-01	LM_ELE_ADR036	94115.6300000000047
2022-08-01	LM_ELE_ADR039	390408.159999999974
2022-08-01	LM_ELE_ADR040	36656.9000000000015
2022-08-01	LM_ELE_ADR042	3696.5300000000002
2022-08-01	LM_ELE_ADR044	7150.32999999999993
2022-08-01	LM_ELE_ADR048	7520.34000000000015
2022-08-01	LM_ELE_ADR051	7214.81999999999971
2022-08-01	LM_ELE_ADR053	30526.0200000000004
2022-08-01	LM_ELE_ADR055	5958.27999999999975
2022-08-01	LM_ELE_ADR056	0
2022-08-01	LM_ELE_ADR063	190
2022-08-01	LM_ELE_ADR064	0
2022-08-01	LM_ELE_ADR058	87206.4400000000023
2022-08-01	LM_ELE_ADR072	28982
2022-08-01	LM_ELE_ADR074	85753
2022-08-01	LM_ELE_ADR076	0
2022-08-01	LM_ELE_ADR081	70027.2200000000012
2022-08-01	LM_ELE_ADR085	63461.5400000000009
2022-08-01	LM_ELE_ADR090	43279.8799999999974
2022-08-01	LM_ELE_ADR107	92975.8999999999942
2022-08-01	LM_ELE_ADR108	7162.34000000000015
2022-08-01	LM_ELE_ADR109	2039.09999999999991
2022-08-01	LM_ELE_ADR110	419.310000000000002
2022-08-01	LM_ELE_ADR113	57753.7699999999968
2022-08-01	LM_ELE_ADR087	93027.6000000000058
2022-08-01	LM_LC_ADR_B45	222.629999999999995
2022-08-01	LM_LH_ADR_B46	49.3500000000000014
2022-08-01	LM_LH_ADR_B47	138.300000000000011
2022-08-01	LM_WOD_ADR_B74	40.1700000000000017
2022-08-01	LM_ELE_ADR_B06	520087.25
2022-08-01	LM_ELE_ADR046	0
2022-08-01	LM_ELE_ADR010	125176.610000000001
2022-08-01	LM_ELE_ADR043	2992.07999999999993
2022-08-01	LM_ELE_ADR_B11	36122.7200000000012
2022-08-01	LM_WOD_ADR242	45.8100000000000023
2022-08-01	LM_ELE_ADR124	123760.539999999994
2022-08-01	LM_ELE_ADR112	750394.5
2022-08-01	LM_WOD_ADR_B75	187.259999999999991
2022-08-01	LM_ELE_ADR091	13265.2099999999991
2022-08-01	LM_WOD_ADR_B80	137.900000000000006
2022-08-01	LM_WOD_ADR_B81	48.0399999999999991
2022-08-01	LM_ELE_ADR_B04	295630
2022-08-01	LM_ELE_ADR_B05	298740.590000000026
2022-08-01	LM_ELE_ADR_B09	313154.309999999998
2022-08-01	LM_ELE_ADR_B01	0
2022-08-01	LM_ELE_ADR_B10	32454.5
2022-08-01	LM_ELE_ADR_B02	0
2022-08-01	LM_LC_ADR_B18	18.8099999999999987
2022-08-01	LM_LC_ADR_B20	69.8299999999999983
2022-08-01	LM_LC_ADR_B22	56.3800000000000026
2022-08-01	LM_LC_ADR_B24	10.6899999999999995
2022-08-01	LM_LC_ADR_B31	465.300000000000011
2022-08-01	LM_LC_ADR_B41	530.399999999999977
2022-08-01	LM_LC_ADR_B43	9.30000000000000071
2022-08-01	LM_LH_ADR_B23	73.9000000000000057
2022-08-01	LM_LH_ADR_B25	77.7000000000000028
2022-08-01	LM_LH_ADR_B27	163.199999999999989
2022-08-01	LM_LH_ADR_B35	0
2022-08-01	LM_LH_ADR_B36	0
2022-08-01	LM_LH_ADR_B38	76.2999999999999972
2022-08-01	LM_LH_ADR_B44	4.59999999999999964
2022-08-01	LM_WOD_ADR_B76	1747.88000000000011
2022-08-01	LM_WOD_ADR_B77	9.07000000000000028
2022-08-01	LM_LC_ADR_B16	38.8200000000000003
2022-08-01	LM_LH_ADR_B17	58.7999999999999972
2022-08-01	LM_WOD_ADR_B79	360.110000000000014
2022-08-01	LM_ELE_ADR_B12	19604.4000000000015
2022-08-01	LM_ELE_ADR_B13	15053.1900000000005
2022-08-01	LM_LC_ADR_B46	58.8699999999999974
2022-08-01	LM_LC_ADR193	0
2022-08-01	LM_ELE_ADR125	5145.92000000000007
2022-08-01	LM_ELE_ADR069	320593
2022-08-01	LM_ELE_ADR075	11892
2022-08-01	LM_LC_ADR159	5030
2022-08-01	LM_LC_ADR160	13360
2022-08-01	LM_LH_ADR167	6760
2022-08-01	LM_WOD_ADR236	18.2800000000000011
2022-08-01	zdemontowany580	6
2022-08-01	zdemontowany600	3194
2022-09-01	LM_LC_ADR170	57.4099999999999966
2022-09-01	LM_LC_ADR172	136.490000000000009
2022-09-01	LM_LC_ADR179	88.5499999999999972
2022-09-01	LM_ELE_ADR021	297963.690000000002
2022-09-01	LM_ELE_ADR078	58985
2022-09-01	LM_ELE_ADR066	0
2022-09-01	LM_ELE_ADR080	185441.660000000003
2022-09-01	LM_LH_ADR199	160.699999999999989
2022-09-01	LM_ELE_ADR115	28729.75
2022-09-01	LM_WOD_ADR249_Solution Space	127.540000000000006
2022-09-01	LM_WOD_MAIN_W	0
2022-09-01	LM_LC_ADR123	548.299999999999955
2022-09-01	LM_LC_ADR151	31432
2022-09-01	LM_LC_ADR153	10657
2022-09-01	LM_LC_ADR154	2768.90000000000009
2022-09-01	LM_LC_ADR155	7231.80000000000018
2022-09-01	LM_LC_ADR157	1139.5
2022-09-01	LM_LC_ADR158	371.699999999999989
2022-09-01	LM_LC_ADR162	813.5
2022-09-01	LM_LC_ADR168	121.5
2022-09-01	LM_LC_ADR173	103.650000000000006
2022-09-01	LM_LC_ADR174	226.389999999999986
2022-09-01	LM_LC_ADR175	0
2022-09-01	LM_LC_ADR176	85.9000000000000057
2022-09-01	LM_LC_ADR178	143.689999999999998
2022-09-01	LM_LC_ADR184	45.2299999999999969
2022-09-01	LM_LC_ADR186	19.2300000000000004
2022-09-01	LM_LC_ADR187	32.6899999999999977
2022-09-01	LM_LC_ADR209	0
2022-09-01	LM_LC_ADR32	0
2022-09-01	LM_LC_ADR82	31.4400000000000013
2022-09-01	LM_LH_ADR122	20.6999999999999993
2022-09-01	LM_LH_ADR189	73.1899999999999977
2022-09-01	LM_LH_ADR195	526.899999999999977
2022-09-01	LM_LH_ADR196	9
2022-09-01	LM_LH_ADR198	1418.29999999999995
2022-09-01	LM_LH_ADR200	54.2999999999999972
2022-09-01	LM_LH_ADR203	239.599999999999994
2022-09-01	LM_LH_ADR204	117.5
2022-09-01	LM_LH_ADR208	359.100000000000023
2022-09-01	LM_LH_ADR211	46.6000000000000014
2022-09-01	LM_LH_ADR212	242.199999999999989
2022-09-01	LM_LH_ADR216	40.4699999999999989
2022-09-01	LM_LH_ADR218	512.899999999999977
2022-09-01	LM_LH_ADR221	424.600000000000023
2022-09-01	LM_LH_ADR222	0
2022-09-01	LM_LH_ADR227	47.3999999999999986
2022-09-01	LM_LH_ADR229	0
2022-09-01	LM_LH_ADR231	0
2022-09-01	LM_LH_ADR234	0
2022-09-01	LM_LH_ADR235	103.700000000000003
2022-09-01	LM_LH_ADR33	0
2022-09-01	LM_ELE_ADR008	111499.970000000001
2022-09-01	LM_ELE_ADR012	98050.7799999999988
2022-09-01	LM_ELE_ADR017	13827.6599999999999
2022-09-01	LM_ELE_ADR019	4038.65999999999985
2022-09-01	LM_ELE_ADR024	137357.640000000014
2022-09-01	LM_ELE_ADR027	36475.9100000000035
2022-09-01	LM_LC_ADR163	31.0599999999999987
2022-09-01	LM_LC_ADR164	0.0200000000000000004
2022-09-01	LM_LH_ADR201	127.900000000000006
2022-09-01	LM_ELE_ADR029	15681.8600000000006
2022-09-01	LM_ELE_ADR031	203961.950000000012
2022-09-01	LM_ELE_ADR038	412871.030000000028
2022-09-01	LM_ELE_ADR041	69653.4700000000012
2022-09-01	LM_ELE_ADR045	6458.27000000000044
2022-09-01	LM_ELE_ADR047	5766.19999999999982
2022-09-01	LM_ELE_ADR049	15684.3400000000001
2022-09-01	LM_ELE_ADR052	11941.5599999999995
2022-09-01	LM_ELE_ADR054	33041.1800000000003
2022-09-01	LM_ELE_ADR057	6595.97000000000025
2022-09-01	LM_ELE_ADR059	25994.9199999999983
2022-09-01	LM_ELE_ADR060	0
2022-09-01	LM_ELE_ADR061	0
2022-09-01	LM_ELE_ADR062	25612
2022-09-01	LM_ELE_ADR065	0
2022-09-01	LM_ELE_ADR067	336
2022-09-01	LM_ELE_ADR068	13294
2022-09-01	LM_ELE_ADR070	88
2022-09-01	LM_ELE_ADR071	88688
2022-09-01	LM_ELE_ADR073	88
2022-09-01	LM_ELE_ADR077	1063
2022-09-01	LM_ELE_ADR084	58609.7200000000012
2022-09-01	LM_ELE_ADR086	17335.2200000000012
2022-09-01	LM_ELE_ADR088	43371.8399999999965
2022-09-01	LM_ELE_ADR094	1496.31999999999994
2022-09-01	LM_ELE_ADR095	112256.600000000006
2022-09-01	LM_ELE_ADR097	37710.0599999999977
2022-09-01	LM_ELE_ADR098	3838.09000000000015
2022-09-01	LM_ELE_ADR099	96700.7299999999959
2022-09-01	LM_ELE_ADR100	21121.6599999999999
2022-09-01	LM_ELE_ADR101	8799.90999999999985
2022-09-01	LM_ELE_ADR111	362.639999999999986
2022-09-01	LM_ELE_ADR116	15151.0100000000002
2022-09-01	LM_ELE_ADR118	22352.0999999999985
2022-09-01	LM_ELE_ADR119	81419.8000000000029
2022-09-01	LM_ELE_ADR120	101491.25
2022-09-01	LM_WOD_ADR129	135.879999999999995
2022-09-01	LM_WOD_ADR140	124.090000000000003
2022-09-01	LM_WOD_ADR147	65.8900000000000006
2022-09-01	LM_WOD_ADR246_Solution Space	626.309999999999945
2022-09-01	LM_WOD_ADR248_Solution Space	56.1700000000000017
2022-09-01	LM_ELE_ADR_B03	137731.299999999988
2022-09-01	LM_ELE_ADR_B07	109651.580000000002
2022-09-01	LM_ELE_ADR_B08	162789.950000000012
2022-09-01	LM_LC_ADR_B26	171.240000000000009
2022-09-01	LM_LC_ADR_B30	452.699999999999989
2022-09-01	LM_LC_ADR_B32	994.899999999999977
2022-09-01	LM_LC_ADR_B33	900.200000000000045
2022-09-01	LM_LH_ADR_B19	111.799999999999997
2022-09-01	LM_LH_ADR_B21	218.199999999999989
2022-09-01	LM_LH_ADR_B34	0
2022-09-01	LM_LH_ADR_B37	0.400000000000000022
2022-09-01	LM_LH_ADR_B39	112.900000000000006
2022-09-01	LM_LH_ADR_B40	190.199999999999989
2022-09-01	LM_LH_ADR_B42	0
2022-09-01	LM_WOD_ADR_B78	202.5
2022-09-01	LM_LC_ADR102	56.2700000000000031
2022-09-01	LM_LC_ADR103	61.990000000000002
2022-09-01	LM_LC_ADR104	84.0699999999999932
2022-09-01	LM_LC_ADR152	5161.80000000000018
2022-09-01	LM_LC_ADR149	0.910000000000000031
2022-09-01	LM_LC_ADR156	3682.90000000000009
2022-09-01	LM_LC_ADR171	309.050000000000011
2022-09-01	LM_LC_ADR165	52.1099999999999994
2022-09-01	LM_LC_ADR166	40.8200000000000003
2022-09-01	LM_LC_ADR180	148
2022-09-01	LM_LC_ADR181	0.100000000000000006
2022-09-01	LM_LC_ADR182	93.4500000000000028
2022-09-01	LM_LC_ADR183	1.41999999999999993
2022-09-01	LM_LC_ADR185	19.25
2022-09-01	LM_LC_ADR161	1489.90000000000009
2022-09-01	LM_LC_ADR224	177.300000000000011
2022-09-01	LM_LC_ADR89	40.3299999999999983
2022-09-01	LM_LC_ADR93	39.8400000000000034
2022-09-01	LM_LH_ADR145	10.0700000000000003
2022-09-01	LM_LH_ADR188	32.1799999999999997
2022-09-01	LM_LH_ADR190	7.88999999999999968
2022-09-01	LM_LH_ADR191	18.8000000000000007
2022-09-01	LM_LH_ADR192	0
2022-09-01	LM_LH_ADR194	0
2022-09-01	LM_LH_ADR207	445.199999999999989
2022-09-01	LM_LH_ADR197	1404.20000000000005
2022-09-01	LM_LH_ADR215	0
2022-09-01	LM_LH_ADR219	0.0400000000000000008
2022-09-01	LM_LH_ADR220	112.200000000000003
2022-09-01	LM_LH_ADR223	239.5
2022-09-01	LM_LH_ADR225	78.7999999999999972
2022-09-01	LM_LH_ADR226	83.7600000000000051
2022-09-01	LM_LH_ADR217	562.5
2022-09-01	LM_LH_ADR228	37.8999999999999986
2022-09-01	LM_LH_ADR232	66.0499999999999972
2022-09-01	LM_LH_ADR233	54.2000000000000028
2022-09-01	LM_LH_ADR230	1.80000000000000004
2022-09-01	LM_ELE_ADR114	311584.159999999974
2022-09-01	LM_ELE_ADR117	23340.6800000000003
2022-09-01	LM_WOD_ADR132	320.699999999999989
2022-09-01	LM_WOD_ADR133	366.100000000000023
2022-09-01	LM_WOD_ADR134	19.0500000000000007
2022-09-01	LM_WOD_ADR135	0
2022-09-01	LM_WOD_ADR136	74.2999999999999972
2022-09-01	LM_WOD_ADR139	1670.8599999999999
2022-09-01	LM_WOD_ADR141	17
2022-09-01	LM_WOD_ADR142	36
2022-09-01	LM_WOD_ADR143	582.860000000000014
2022-09-01	LM_WOD_ADR146	33544.4000000000015
2022-09-01	LM_WOD_ADR148	0.0100000000000000002
2022-09-01	LM_WOD_ADR150	45.7899999999999991
2022-09-01	LM_WOD_ADR237	924.879999999999995
2022-09-01	LM_WOD_ADR238	2543.96000000000004
2022-09-01	LM_WOD_ADR239	39.7100000000000009
2022-09-01	LM_WOD_ADR240	158.27000000000001
2022-09-01	LM_WOD_ADR241	401
2022-09-01	LM_ELE_ADR121	237993.970000000001
2022-09-01	LM_ELE_ADR128	0
2022-09-01	LM_WOD_ADR247_Solution Space	665.82000000000005
2022-09-01	LM_WOD_ADR250_Solution Space	233.120000000000005
2022-09-01	LM_WOD_ADR30	0
2022-09-01	LM_ELE_ADR001	75093.1499999999942
2022-09-01	LM_ELE_ADR002	95679.7400000000052
2022-09-01	LM_ELE_ADR003	126341.919999999998
2022-09-01	LM_ELE_ADR006	0
2022-09-01	LM_ELE_ADR007	146721.220000000001
2022-09-01	LM_ELE_ADR009	198962.859999999986
2022-09-01	LM_ELE_ADR011	180004.890000000014
2022-09-01	LM_ELE_ADR013	238657.029999999999
2022-09-01	LM_ELE_ADR014	16206.4500000000007
2022-09-01	LM_ELE_ADR015	142370.440000000002
2022-09-01	LM_ELE_ADR016	993257.939999999944
2022-09-01	LM_ELE_ADR018	14343.2399999999998
2022-09-01	LM_ELE_ADR020	146320
2022-09-01	LM_ELE_ADR022	178604.609999999986
2022-09-01	LM_ELE_ADR023	39394.8700000000026
2022-09-01	LM_ELE_ADR025	650495.810000000056
2022-09-01	LM_ELE_ADR028	20004.3600000000006
2022-09-01	LM_ELE_ADR034	34074.8600000000006
2022-09-01	LM_ELE_ADR036	94479.820000000007
2022-09-01	LM_ELE_ADR039	400377.130000000005
2022-09-01	LM_ELE_ADR040	36656.9000000000015
2022-09-01	LM_ELE_ADR042	3773.59999999999991
2022-09-01	LM_ELE_ADR044	7302.42000000000007
2022-09-01	LM_ELE_ADR048	7679.92000000000007
2022-09-01	LM_ELE_ADR051	7365.46000000000004
2022-09-01	LM_ELE_ADR053	32708.3600000000006
2022-09-01	LM_ELE_ADR055	6086.18000000000029
2022-09-01	LM_ELE_ADR056	0
2022-09-01	LM_ELE_ADR063	190
2022-09-01	LM_ELE_ADR064	0
2022-09-01	LM_ELE_ADR058	89106.2700000000041
2022-09-01	LM_ELE_ADR072	29906
2022-09-01	LM_ELE_ADR074	88688
2022-09-01	LM_ELE_ADR076	0
2022-09-01	LM_ELE_ADR081	71422.8800000000047
2022-09-01	LM_ELE_ADR085	66471.3999999999942
2022-09-01	LM_ELE_ADR090	45412.3499999999985
2022-09-01	LM_ELE_ADR107	95975.6199999999953
2022-09-01	LM_ELE_ADR108	7260.10000000000036
2022-09-01	LM_ELE_ADR109	2040.56999999999994
2022-09-01	LM_ELE_ADR110	457.170000000000016
2022-09-01	LM_ELE_ADR113	59305.6900000000023
2022-09-01	LM_ELE_ADR087	94879.679999999993
2022-09-01	LM_LC_ADR_B45	222.77000000000001
2022-09-01	LM_LH_ADR_B46	49.3500000000000014
2022-09-01	LM_LH_ADR_B47	147.599999999999994
2022-09-01	LM_WOD_ADR_B74	41.2700000000000031
2022-09-01	LM_ELE_ADR_B06	539084.130000000005
2022-09-01	LM_ELE_ADR046	0
2022-09-01	LM_ELE_ADR010	127603.350000000006
2022-09-01	LM_ELE_ADR043	3061.71000000000004
2022-09-01	LM_ELE_ADR_B11	36978.4100000000035
2022-09-01	LM_WOD_ADR242	47.2800000000000011
2022-09-01	LM_ELE_ADR124	131811.579999999987
2022-09-01	LM_ELE_ADR112	758163.060000000056
2022-09-01	LM_WOD_ADR_B75	188.550000000000011
2022-09-01	LM_ELE_ADR091	13755.9699999999993
2022-09-01	LM_WOD_ADR_B80	140.97999999999999
2022-09-01	LM_WOD_ADR_B81	49.759999999999998
2022-09-01	LM_ELE_ADR_B04	311263.25
2022-09-01	LM_ELE_ADR_B05	314182.880000000005
2022-09-01	LM_ELE_ADR_B09	317637.219999999972
2022-09-01	LM_ELE_ADR_B01	0
2022-09-01	LM_ELE_ADR_B10	33092.6200000000026
2022-09-01	LM_ELE_ADR_B02	0
2022-09-01	LM_LC_ADR_B18	18.8200000000000003
2022-09-01	LM_LC_ADR_B20	69.8499999999999943
2022-09-01	LM_LC_ADR_B22	56.3800000000000026
2022-09-01	LM_LC_ADR_B24	10.6899999999999995
2022-09-01	LM_LC_ADR_B31	465.399999999999977
2022-09-01	LM_LC_ADR_B41	530.899999999999977
2022-09-01	LM_LC_ADR_B43	9.40000000000000036
2022-09-01	LM_LH_ADR_B23	73.9000000000000057
2022-09-01	LM_LH_ADR_B25	77.7000000000000028
2022-09-01	LM_LH_ADR_B27	164.199999999999989
2022-09-01	LM_LH_ADR_B35	0
2022-09-01	LM_LH_ADR_B36	0
2022-09-01	LM_LH_ADR_B38	79.5999999999999943
2022-09-01	LM_LH_ADR_B44	4.70000000000000018
2022-09-01	LM_WOD_ADR_B76	1843.25999999999999
2022-09-01	LM_WOD_ADR_B77	9.07000000000000028
2022-09-01	LM_LC_ADR_B16	38.8200000000000003
2022-09-01	LM_LH_ADR_B17	62.5
2022-09-01	LM_WOD_ADR_B79	360.110000000000014
2022-09-01	LM_ELE_ADR_B12	20020.2099999999991
2022-09-01	LM_ELE_ADR_B13	15053.1900000000005
2022-09-01	LM_LC_ADR_B46	58.8699999999999974
2022-09-01	LM_LC_ADR193	0
2022-09-01	LM_ELE_ADR125	5222.80000000000018
2022-09-01	LM_ELE_ADR069	327665
2022-09-01	LM_ELE_ADR075	12299
2022-09-01	LM_LC_ADR159	5030
2022-09-01	LM_LC_ADR160	13450
2022-09-01	LM_LH_ADR167	11550
2022-09-01	LM_WOD_ADR236	21.3399999999999999
2022-09-01	zdemontowany580	6
2022-09-01	zdemontowany600	3194
2022-10-01	LM_LC_ADR170	57.990000000000002
2022-10-01	LM_LC_ADR172	136.900000000000006
2022-10-01	LM_LC_ADR179	88.7399999999999949
2022-10-01	LM_ELE_ADR021	303024.880000000005
2022-10-01	LM_ELE_ADR078	59611
2022-10-01	LM_ELE_ADR066	0
2022-10-01	LM_ELE_ADR080	187882.73000000001
2022-10-01	LM_LH_ADR199	162.199999999999989
2022-10-01	LM_ELE_ADR115	29344.3400000000001
2022-10-01	LM_WOD_ADR249_Solution Space	132.180000000000007
2022-10-01	LM_WOD_MAIN_W	0
2022-10-01	LM_LC_ADR123	551
2022-10-01	LM_LC_ADR151	31647
2022-10-01	LM_LC_ADR153	10701
2022-10-01	LM_LC_ADR154	2811.30000000000018
2022-10-01	LM_LC_ADR155	7304.10000000000036
2022-10-01	LM_LC_ADR157	1155.09999999999991
2022-10-01	LM_LC_ADR158	376.399999999999977
2022-10-01	LM_LC_ADR162	820.200000000000045
2022-10-01	LM_LC_ADR168	129
2022-10-01	LM_LC_ADR173	104.730000000000004
2022-10-01	LM_LC_ADR174	233
2022-10-01	LM_LC_ADR175	0
2022-10-01	LM_LC_ADR176	85.9000000000000057
2022-10-01	LM_LC_ADR178	146.560000000000002
2022-10-01	LM_LC_ADR184	45.2299999999999969
2022-10-01	LM_LC_ADR186	19.2300000000000004
2022-10-01	LM_LC_ADR187	32.6899999999999977
2022-10-01	LM_LC_ADR209	0
2022-10-01	LM_LC_ADR32	0
2022-10-01	LM_LC_ADR82	33.4200000000000017
2022-10-01	LM_LH_ADR122	21.6000000000000014
2022-10-01	LM_LH_ADR189	75.1599999999999966
2022-10-01	LM_LH_ADR195	531.799999999999955
2022-10-01	LM_LH_ADR196	9
2022-10-01	LM_LH_ADR198	0
2022-10-01	LM_LH_ADR200	54.8999999999999986
2022-10-01	LM_LH_ADR203	241.400000000000006
2022-10-01	LM_LH_ADR204	118.599999999999994
2022-10-01	LM_LH_ADR208	365.899999999999977
2022-10-01	LM_LH_ADR211	48.3999999999999986
2022-10-01	LM_LH_ADR212	251.400000000000006
2022-10-01	LM_LH_ADR216	40.4699999999999989
2022-10-01	LM_LH_ADR218	527.700000000000045
2022-10-01	LM_LH_ADR221	437.100000000000023
2022-10-01	LM_LH_ADR222	0
2022-10-01	LM_LH_ADR227	51
2022-10-01	LM_LH_ADR229	0
2022-10-01	LM_LH_ADR231	0
2022-10-01	LM_LH_ADR234	0
2022-10-01	LM_LH_ADR235	104.5
2022-10-01	LM_LH_ADR33	0
2022-10-01	LM_ELE_ADR008	113298.619999999995
2022-10-01	LM_ELE_ADR012	99185.6199999999953
2022-10-01	LM_ELE_ADR017	14025.0400000000009
2022-10-01	LM_ELE_ADR019	4038.65999999999985
2022-10-01	LM_ELE_ADR024	139699.970000000001
2022-10-01	LM_ELE_ADR027	36475.9100000000035
2022-10-01	LM_LC_ADR163	31.0599999999999987
2022-10-01	LM_LC_ADR164	0.0200000000000000004
2022-10-01	LM_LH_ADR201	136.599999999999994
2022-10-01	LM_ELE_ADR029	16187.0599999999995
2022-10-01	LM_ELE_ADR031	206400.829999999987
2022-10-01	LM_ELE_ADR038	419798.880000000005
2022-10-01	LM_ELE_ADR041	70676.1600000000035
2022-10-01	LM_ELE_ADR045	6552.14000000000033
2022-10-01	LM_ELE_ADR047	5868.0600000000004
2022-10-01	LM_ELE_ADR049	15891.3700000000008
2022-10-01	LM_ELE_ADR052	12112.2999999999993
2022-10-01	LM_ELE_ADR054	33503.1500000000015
2022-10-01	LM_ELE_ADR057	6701.1899999999996
2022-10-01	LM_ELE_ADR059	26461.3400000000001
2022-10-01	LM_ELE_ADR060	0
2022-10-01	LM_ELE_ADR061	0
2022-10-01	LM_ELE_ADR062	26321
2022-10-01	LM_ELE_ADR065	0
2022-10-01	LM_ELE_ADR067	336
2022-10-01	LM_ELE_ADR068	14347
2022-10-01	LM_ELE_ADR070	88
2022-10-01	LM_ELE_ADR071	90619
2022-10-01	LM_ELE_ADR073	88
2022-10-01	LM_ELE_ADR077	1063
2022-10-01	LM_ELE_ADR084	59262.0199999999968
2022-10-01	LM_ELE_ADR086	17801.1100000000006
2022-10-01	LM_ELE_ADR088	44130.5199999999968
2022-10-01	LM_ELE_ADR094	1503.69000000000005
2022-10-01	LM_ELE_ADR095	114378.059999999998
2022-10-01	LM_ELE_ADR097	38940.7099999999991
2022-10-01	LM_ELE_ADR098	3917.63999999999987
2022-10-01	LM_ELE_ADR099	99075.7899999999936
2022-10-01	LM_ELE_ADR100	21488.2200000000012
2022-10-01	LM_ELE_ADR101	8994.46999999999935
2022-10-01	LM_ELE_ADR111	362.649999999999977
2022-10-01	LM_ELE_ADR116	15151.0100000000002
2022-10-01	LM_ELE_ADR118	22656.4799999999996
2022-10-01	LM_ELE_ADR119	82577.4100000000035
2022-10-01	LM_ELE_ADR120	104097.809999999998
2022-10-01	LM_WOD_ADR129	139.47999999999999
2022-10-01	LM_WOD_ADR140	124.370000000000005
2022-10-01	LM_WOD_ADR147	67
2022-10-01	LM_WOD_ADR246_Solution Space	639.669999999999959
2022-10-01	LM_WOD_ADR248_Solution Space	58.2100000000000009
2022-10-01	LM_ELE_ADR_B03	139460.73000000001
2022-10-01	LM_ELE_ADR_B07	111147.729999999996
2022-10-01	LM_ELE_ADR_B08	165089.579999999987
2022-10-01	LM_LC_ADR_B26	171.919999999999987
2022-10-01	LM_LC_ADR_B30	457
2022-10-01	LM_LC_ADR_B32	1004
2022-10-01	LM_LC_ADR_B33	909.299999999999955
2022-10-01	LM_LH_ADR_B19	114.400000000000006
2022-10-01	LM_LH_ADR_B21	221.599999999999994
2022-10-01	LM_LH_ADR_B34	0
2022-10-01	LM_LH_ADR_B37	0.400000000000000022
2022-10-01	LM_LH_ADR_B39	113.599999999999994
2022-10-01	LM_LH_ADR_B40	191.800000000000011
2022-10-01	LM_LH_ADR_B42	0
2022-10-01	LM_WOD_ADR_B78	204.97999999999999
2022-10-01	LM_LC_ADR102	57.240000000000002
2022-10-01	LM_LC_ADR103	63.0300000000000011
2022-10-01	LM_LC_ADR104	85.9200000000000017
2022-10-01	LM_LC_ADR152	5199.39999999999964
2022-10-01	LM_LC_ADR149	0.910000000000000031
2022-10-01	LM_LC_ADR156	3714.19999999999982
2022-10-01	LM_LC_ADR171	309.240000000000009
2022-10-01	LM_LC_ADR165	53.0900000000000034
2022-10-01	LM_LC_ADR166	41.5499999999999972
2022-10-01	LM_LC_ADR180	148.689999999999998
2022-10-01	LM_LC_ADR181	0.100000000000000006
2022-10-01	LM_LC_ADR182	94.0799999999999983
2022-10-01	LM_LC_ADR183	1.41999999999999993
2022-10-01	LM_LC_ADR185	19.25
2022-10-01	LM_LC_ADR161	1502.29999999999995
2022-10-01	LM_LC_ADR224	180.830000000000013
2022-10-01	LM_LC_ADR89	41.1599999999999966
2022-10-01	LM_LC_ADR93	40.6700000000000017
2022-10-01	LM_LH_ADR145	10.0700000000000003
2022-10-01	LM_LH_ADR188	32.1799999999999997
2022-10-01	LM_LH_ADR190	7.88999999999999968
2022-10-01	LM_LH_ADR191	18.8000000000000007
2022-10-01	LM_LH_ADR192	0
2022-10-01	LM_LH_ADR194	0
2022-10-01	LM_LH_ADR207	450.800000000000011
2022-10-01	LM_LH_ADR197	1414.59999999999991
2022-10-01	LM_LH_ADR215	0
2022-10-01	LM_LH_ADR219	0.0400000000000000008
2022-10-01	LM_LH_ADR220	112.200000000000003
2022-10-01	LM_LH_ADR223	251.900000000000006
2022-10-01	LM_LH_ADR225	82.7000000000000028
2022-10-01	LM_LH_ADR226	83.8100000000000023
2022-10-01	LM_LH_ADR217	571.700000000000045
2022-10-01	LM_LH_ADR228	38.1000000000000014
2022-10-01	LM_LH_ADR232	67.3799999999999955
2022-10-01	LM_LH_ADR233	54.2999999999999972
2022-10-01	LM_LH_ADR230	1.80000000000000004
2022-10-01	LM_ELE_ADR114	27.8099999999999987
2022-10-01	LM_ELE_ADR117	23588.2999999999993
2022-10-01	LM_WOD_ADR132	324.660000000000025
2022-10-01	LM_WOD_ADR133	370.199999999999989
2022-10-01	LM_WOD_ADR134	19.0799999999999983
2022-10-01	LM_WOD_ADR135	0
2022-10-01	LM_WOD_ADR136	75.1899999999999977
2022-10-01	LM_WOD_ADR139	1703.13000000000011
2022-10-01	LM_WOD_ADR141	17
2022-10-01	LM_WOD_ADR142	36
2022-10-01	LM_WOD_ADR143	582.860000000000014
2022-10-01	LM_WOD_ADR146	34101.3000000000029
2022-10-01	LM_WOD_ADR148	0.0299999999999999989
2022-10-01	LM_WOD_ADR150	46.7899999999999991
2022-10-01	LM_WOD_ADR237	926.110000000000014
2022-10-01	LM_WOD_ADR238	2543.96000000000004
2022-10-01	LM_WOD_ADR239	40.6000000000000014
2022-10-01	LM_WOD_ADR240	163.889999999999986
2022-10-01	LM_WOD_ADR241	445.660000000000025
2022-10-01	LM_ELE_ADR121	85.4399999999999977
2022-10-01	LM_ELE_ADR128	0
2022-10-01	LM_WOD_ADR247_Solution Space	681.809999999999945
2022-10-01	LM_WOD_ADR250_Solution Space	240.689999999999998
2022-10-01	LM_WOD_ADR30	0
2022-10-01	LM_ELE_ADR001	76404.3500000000058
2022-10-01	LM_ELE_ADR002	96846.3800000000047
2022-10-01	LM_ELE_ADR003	127689.080000000002
2022-10-01	LM_ELE_ADR006	0
2022-10-01	LM_ELE_ADR007	147721.220000000001
2022-10-01	LM_ELE_ADR009	199928.390000000014
2022-10-01	LM_ELE_ADR011	180794.910000000003
2022-10-01	LM_ELE_ADR013	241267.720000000001
2022-10-01	LM_ELE_ADR014	16504.2900000000009
2022-10-01	LM_ELE_ADR015	143689.160000000003
2022-10-01	LM_ELE_ADR016	1001217.43999999994
2022-10-01	LM_ELE_ADR018	14569.3999999999996
2022-10-01	LM_ELE_ADR020	148098.059999999998
2022-10-01	LM_ELE_ADR022	183444.029999999999
2022-10-01	LM_ELE_ADR023	40526.4400000000023
2022-10-01	LM_ELE_ADR025	675872.130000000005
2022-10-01	LM_ELE_ADR028	20025.2700000000004
2022-10-01	LM_ELE_ADR034	35099.3700000000026
2022-10-01	LM_ELE_ADR036	95701.0099999999948
2022-10-01	LM_ELE_ADR039	406712.909999999974
2022-10-01	LM_ELE_ADR040	36656.9000000000015
2022-10-01	LM_ELE_ADR042	3829.05999999999995
2022-10-01	LM_ELE_ADR044	7408.10000000000036
2022-10-01	LM_ELE_ADR048	7793.67000000000007
2022-10-01	LM_ELE_ADR051	7464.5600000000004
2022-10-01	LM_ELE_ADR053	34256.260000000002
2022-10-01	LM_ELE_ADR055	6175.22000000000025
2022-10-01	LM_ELE_ADR056	0
2022-10-01	LM_ELE_ADR063	190
2022-10-01	LM_ELE_ADR064	0
2022-10-01	LM_ELE_ADR058	90383.2700000000041
2022-10-01	LM_ELE_ADR072	30512
2022-10-01	LM_ELE_ADR074	90619
2022-10-01	LM_ELE_ADR076	0
2022-10-01	LM_ELE_ADR081	72671.7200000000012
2022-10-01	LM_ELE_ADR085	68240.6300000000047
2022-10-01	LM_ELE_ADR090	46360.3600000000006
2022-10-01	LM_ELE_ADR107	97896.8899999999994
2022-10-01	LM_ELE_ADR108	7492.5600000000004
2022-10-01	LM_ELE_ADR109	2041.46000000000004
2022-10-01	LM_ELE_ADR110	479.050000000000011
2022-10-01	LM_ELE_ADR113	60312.2900000000009
2022-10-01	LM_ELE_ADR087	96040.4400000000023
2022-10-01	LM_LC_ADR_B45	225.530000000000001
2022-10-01	LM_LH_ADR_B46	49.3500000000000014
2022-10-01	LM_LH_ADR_B47	148.800000000000011
2022-10-01	LM_WOD_ADR_B74	42.0399999999999991
2022-10-01	LM_ELE_ADR_B06	545348.939999999944
2022-10-01	LM_ELE_ADR046	0
2022-10-01	LM_ELE_ADR010	129307.770000000004
2022-10-01	LM_ELE_ADR043	3113.5300000000002
2022-10-01	LM_ELE_ADR_B11	37732.3399999999965
2022-10-01	LM_WOD_ADR242	48.240000000000002
2022-10-01	LM_ELE_ADR124	137109.380000000005
2022-10-01	LM_ELE_ADR112	762760.880000000005
2022-10-01	LM_WOD_ADR_B75	189.530000000000001
2022-10-01	LM_ELE_ADR091	14088.1800000000003
2022-10-01	LM_WOD_ADR_B80	144.689999999999998
2022-10-01	LM_WOD_ADR_B81	51.009999999999998
2022-10-01	LM_ELE_ADR_B04	314645.090000000026
2022-10-01	LM_ELE_ADR_B05	321904.75
2022-10-01	LM_ELE_ADR_B09	321712.940000000002
2022-10-01	LM_ELE_ADR_B01	0
2022-10-01	LM_ELE_ADR_B10	33647.010000000002
2022-10-01	LM_ELE_ADR_B02	0
2022-10-01	LM_LC_ADR_B18	18.9499999999999993
2022-10-01	LM_LC_ADR_B20	70.1299999999999955
2022-10-01	LM_LC_ADR_B22	56.3800000000000026
2022-10-01	LM_LC_ADR_B24	10.6899999999999995
2022-10-01	LM_LC_ADR_B31	469
2022-10-01	LM_LC_ADR_B41	539.299999999999955
2022-10-01	LM_LC_ADR_B43	9.59999999999999964
2022-10-01	LM_LH_ADR_B23	73.9000000000000057
2022-10-01	LM_LH_ADR_B25	77.7000000000000028
2022-10-01	LM_LH_ADR_B27	164.800000000000011
2022-10-01	LM_LH_ADR_B35	0
2022-10-01	LM_LH_ADR_B36	0
2022-10-01	LM_LH_ADR_B38	80.0999999999999943
2022-10-01	LM_LH_ADR_B44	4.79999999999999982
2022-10-01	LM_WOD_ADR_B76	1864.28999999999996
2022-10-01	LM_WOD_ADR_B77	9.10999999999999943
2022-10-01	LM_LC_ADR_B16	38.8200000000000003
2022-10-01	LM_LH_ADR_B17	65
2022-10-01	LM_WOD_ADR_B79	515.649999999999977
2022-10-01	LM_ELE_ADR_B12	20259.0200000000004
2022-10-01	LM_ELE_ADR_B13	15053.1900000000005
2022-10-01	LM_LC_ADR_B46	58.8699999999999974
2022-10-01	LM_LC_ADR193	0
2022-10-01	LM_ELE_ADR125	5273.38000000000011
2022-10-01	LM_ELE_ADR069	332514
2022-10-01	LM_ELE_ADR075	12550
2022-10-01	LM_LC_ADR159	5030
2022-10-01	LM_LC_ADR160	14260
2022-10-01	LM_LH_ADR167	13220
2022-10-01	LM_WOD_ADR236	25.379999999999999
2022-10-01	zdemontowany580	6
2022-10-01	zdemontowany600	3194
2022-01-01	LM_WOD_ADR148	0.0400000000000000008
2022-03-01	LM_LH_ADR194	0
2022-04-01	LM_LH_ADR167	1590
2022-04-01	LM_WOD_ADR236	10.1999999999999993
2022-02-01	zdemontowany580	6
2022-03-01	zdemontowany580	6
2022-05-01	LM_LC_ADR32	0
2021-07-01	LM_LC_ADR170	48.9500000000000028
2021-07-01	LM_LC_ADR172	90.2199999999999989
2021-07-01	LM_LC_ADR179	70.5999999999999943
2021-07-01	LM_ELE_ADR021	196075.660000000003
2021-07-01	LM_ELE_ADR078	36857
2021-07-01	LM_ELE_ADR066	0
2021-07-01	LM_ELE_ADR080	146553.950000000012
2021-07-01	LM_LH_ADR199	122.400000000000006
2021-07-01	LM_ELE_ADR115	20787.7900000000009
2021-07-01	LM_WOD_ADR249_Solution Space	70.2900000000000063
2021-07-01	LM_WOD_MAIN_W	0
2021-07-01	LM_LC_ADR123	369
2021-07-01	LM_LC_ADR151	25987
2021-07-01	LM_LC_ADR153	9220
2021-07-01	LM_LC_ADR154	2101.09999999999991
2021-07-01	LM_LC_ADR155	5624.39999999999964
2021-07-01	LM_LC_ADR157	903.600000000000023
2021-07-01	LM_LC_ADR158	282.699999999999989
2021-07-01	LM_LC_ADR162	657.200000000000045
2021-07-01	LM_LC_ADR168	69.2000000000000028
2021-07-01	LM_LC_ADR173	79.4000000000000057
2021-07-01	LM_LC_ADR174	135.090000000000003
2021-07-01	LM_LC_ADR175	0
2021-07-01	LM_LC_ADR176	84.5999999999999943
2021-07-01	LM_LC_ADR178	95.5499999999999972
2021-07-01	LM_LC_ADR184	38.9600000000000009
2021-07-01	LM_LC_ADR186	15.5399999999999991
2021-07-01	LM_LC_ADR187	29.0399999999999991
2021-07-01	LM_LC_ADR209	84.6800000000000068
2021-07-01	LM_LC_ADR32	0
2021-07-01	LM_LC_ADR82	0
2021-07-01	LM_LH_ADR122	10
2021-07-01	LM_LH_ADR189	43.8500000000000014
2021-07-01	LM_LH_ADR195	356
2021-07-01	LM_LH_ADR196	9
2021-07-01	LM_LH_ADR198	1004.5
2021-07-01	LM_LH_ADR200	40.2000000000000028
2021-07-01	LM_LH_ADR203	199.699999999999989
2021-07-01	LM_LH_ADR204	81.7999999999999972
2021-07-01	LM_LH_ADR208	247.699999999999989
2021-07-01	LM_LH_ADR211	19.3000000000000007
2021-07-01	LM_LH_ADR212	105
2021-07-01	LM_LH_ADR216	27.9699999999999989
2021-07-01	LM_LH_ADR218	332.600000000000023
2021-07-01	LM_LH_ADR221	229.800000000000011
2021-07-01	LM_LH_ADR222	0
2021-07-01	LM_LH_ADR227	29.5
2021-07-01	LM_LH_ADR229	83.8599999999999994
2021-07-01	LM_LH_ADR231	0
2021-07-01	LM_LH_ADR234	0
2021-07-01	LM_LH_ADR235	83.7999999999999972
2021-07-01	LM_LH_ADR33	0
2021-07-01	LM_ELE_ADR008	76030.4100000000035
2021-07-01	LM_ELE_ADR012	60508.989999999998
2021-07-01	LM_ELE_ADR017	10605.5699999999997
2021-07-01	LM_ELE_ADR019	2439.51999999999998
2021-07-01	LM_ELE_ADR024	106947.699999999997
2021-07-01	LM_ELE_ADR027	33502.3600000000006
2021-07-01	LM_LC_ADR163	26.4400000000000013
2021-07-01	LM_LC_ADR164	0.0200000000000000004
2021-07-01	LM_LH_ADR201	56.5
2021-07-01	LM_ELE_ADR029	9132.79000000000087
2021-07-01	LM_ELE_ADR031	141139.25
2021-07-01	LM_ELE_ADR038	254048.579999999987
2021-07-01	LM_ELE_ADR041	56975.1299999999974
2021-07-01	LM_ELE_ADR045	4993.68000000000029
2021-07-01	LM_ELE_ADR047	4475.68000000000029
2021-07-01	LM_ELE_ADR049	12684.9200000000001
2021-07-01	LM_ELE_ADR052	9439.95000000000073
2021-07-01	LM_ELE_ADR054	26478.9399999999987
2021-07-01	LM_ELE_ADR057	5234.48999999999978
2021-07-01	LM_ELE_ADR059	19332.3899999999994
2021-07-01	LM_ELE_ADR060	0
2021-07-01	LM_ELE_ADR061	0
2021-07-01	LM_ELE_ADR062	16182
2021-07-01	LM_ELE_ADR065	0
2021-07-01	LM_ELE_ADR067	125
2021-07-01	LM_ELE_ADR068	390
2021-07-01	LM_ELE_ADR070	80
2021-07-01	LM_ELE_ADR071	62922
2021-07-01	LM_ELE_ADR073	80
2021-07-01	LM_ELE_ADR077	1063
2021-07-01	LM_ELE_ADR084	47836.6699999999983
2021-07-01	LM_ELE_ADR086	10860.5300000000007
2021-07-01	LM_ELE_ADR088	30209.1800000000003
2021-07-01	LM_ELE_ADR094	1335.76999999999998
2021-07-01	LM_ELE_ADR095	82457.0200000000041
2021-07-01	LM_ELE_ADR097	22452.25
2021-07-01	LM_ELE_ADR098	2970.2199999999998
2021-07-01	LM_ELE_ADR099	55189.3199999999997
2021-07-01	LM_ELE_ADR100	12895.3999999999996
2021-07-01	LM_ELE_ADR101	6012.68000000000029
2021-07-01	LM_ELE_ADR111	362.079999999999984
2021-07-01	LM_ELE_ADR116	8819.64999999999964
2021-07-01	LM_ELE_ADR118	18129.8499999999985
2021-07-01	LM_ELE_ADR119	63259.1299999999974
2021-07-01	LM_ELE_ADR120	72597.1000000000058
2021-07-01	LM_WOD_ADR129	89.0999999999999943
2021-07-01	LM_WOD_ADR140	120.189999999999998
2021-07-01	LM_WOD_ADR147	50.4600000000000009
2021-07-01	LM_WOD_ADR246_Solution Space	404.810000000000002
2021-07-01	LM_WOD_ADR248_Solution Space	29.6499999999999986
2021-07-01	LM_ELE_ADR_B03	109787.110000000001
2021-07-01	LM_ELE_ADR_B07	87212.6199999999953
2021-07-01	LM_ELE_ADR_B08	130174.899999999994
2021-07-01	LM_LC_ADR_B26	104.730000000000004
2021-07-01	LM_LC_ADR_B30	342.899999999999977
2021-07-01	LM_LC_ADR_B32	765.799999999999955
2021-07-01	LM_LC_ADR_B33	650.299999999999955
2021-07-01	LM_LH_ADR_B19	70.7000000000000028
2021-07-01	LM_LH_ADR_B21	150.5
2021-07-01	LM_LH_ADR_B34	0
2021-07-01	LM_LH_ADR_B37	0.400000000000000022
2021-07-01	LM_LH_ADR_B39	85.5999999999999943
2021-07-01	LM_LH_ADR_B40	143.199999999999989
2021-07-01	LM_LH_ADR_B42	0
2021-07-01	LM_WOD_ADR_B78	173.990000000000009
2021-07-01	LM_LC_ADR102	40.9500000000000028
2021-07-01	LM_LC_ADR103	45.009999999999998
2021-07-01	LM_LC_ADR104	54.8999999999999986
2021-07-01	LM_LC_ADR152	4239.10000000000036
2021-07-01	LM_LC_ADR149	0.910000000000000031
2021-07-01	LM_LC_ADR156	2750.19999999999982
2021-07-01	LM_LC_ADR171	239.050000000000011
2021-07-01	LM_LC_ADR165	35.8999999999999986
2021-07-01	LM_LC_ADR166	29
2021-07-01	LM_LC_ADR180	123.879999999999995
2021-07-01	LM_LC_ADR181	0.100000000000000006
2021-07-01	LM_LC_ADR182	73.3100000000000023
2021-07-01	LM_LC_ADR183	1.41999999999999993
2021-07-01	LM_LC_ADR185	16.129999999999999
2021-07-01	LM_LC_ADR161	1199.40000000000009
2021-07-01	LM_LC_ADR224	124.010000000000005
2021-07-01	LM_LC_ADR89	26.1099999999999994
2021-07-01	LM_LC_ADR93	25.6099999999999994
2021-07-01	LM_LH_ADR145	7.37999999999999989
2021-07-01	LM_LH_ADR188	24.0599999999999987
2021-07-01	LM_LH_ADR190	6.42999999999999972
2021-07-01	LM_LH_ADR191	15.1999999999999993
2021-07-01	LM_LH_ADR192	0
2021-07-01	LM_LH_ADR194	700.5
2021-07-01	LM_LH_ADR207	381.300000000000011
2021-07-01	LM_LH_ADR197	1127.20000000000005
2021-07-01	LM_LH_ADR215	0
2021-07-01	LM_LH_ADR219	0.0200000000000000004
2021-07-01	LM_LH_ADR220	71.980000000000004
2021-07-01	LM_LH_ADR223	141.599999999999994
2021-07-01	LM_LH_ADR225	54.2999999999999972
2021-07-01	LM_LH_ADR226	50.9699999999999989
2021-07-01	LM_LH_ADR217	442.300000000000011
2021-07-01	LM_LH_ADR228	26.8000000000000007
2021-07-01	LM_LH_ADR232	46.5799999999999983
2021-07-01	LM_LH_ADR233	38
2021-07-01	LM_LH_ADR230	1.5
2021-07-01	LM_ELE_ADR114	213759.079999999987
2021-07-01	LM_ELE_ADR117	20477.3400000000001
2021-07-01	LM_WOD_ADR132	259.850000000000023
2021-07-01	LM_WOD_ADR133	320.069999999999993
2021-07-01	LM_WOD_ADR134	18.1000000000000014
2021-07-01	LM_WOD_ADR135	0
2021-07-01	LM_WOD_ADR136	61.7700000000000031
2021-07-01	LM_WOD_ADR139	1081.3599999999999
2021-07-01	LM_WOD_ADR141	17
2021-07-01	LM_WOD_ADR142	36
2021-07-01	LM_WOD_ADR143	361.069999999999993
2021-07-01	LM_WOD_ADR146	25269.2999999999993
2021-07-01	LM_WOD_ADR148	0.0500000000000000028
2021-07-01	LM_WOD_ADR150	32.8999999999999986
2021-07-01	LM_WOD_ADR237	860.950000000000045
2021-07-01	LM_WOD_ADR238	2210.0300000000002
2021-07-01	LM_WOD_ADR239	26.4100000000000001
2021-07-01	LM_WOD_ADR240	91.5400000000000063
2021-07-01	LM_WOD_ADR241	899.350000000000023
2021-07-01	LM_ELE_ADR121	158906.410000000003
2021-07-01	LM_ELE_ADR128	0
2021-07-01	LM_WOD_ADR247_Solution Space	369.569999999999993
2021-07-01	LM_WOD_ADR250_Solution Space	133.569999999999993
2021-07-01	LM_WOD_ADR30	0
2021-07-01	LM_ELE_ADR001	57763.2699999999968
2021-07-01	LM_ELE_ADR002	76678.0299999999988
2021-07-01	LM_ELE_ADR003	92503.4400000000023
2021-07-01	LM_ELE_ADR006	66431.4600000000064
2021-07-01	LM_ELE_ADR007	112584.559999999998
2021-07-01	LM_ELE_ADR009	153932.029999999999
2021-07-01	LM_ELE_ADR011	151400.549999999988
2021-07-01	LM_ELE_ADR013	191805.73000000001
2021-07-01	LM_ELE_ADR014	11718.2999999999993
2021-07-01	LM_ELE_ADR015	107978.889999999999
2021-07-01	LM_ELE_ADR016	835718.310000000056
2021-07-01	LM_ELE_ADR018	11105.9400000000005
2021-07-01	LM_ELE_ADR020	116572.419999999998
2021-07-01	LM_ELE_ADR022	112688.869999999995
2021-07-01	LM_ELE_ADR023	24779.3300000000017
2021-07-01	LM_ELE_ADR025	333624.309999999998
2021-07-01	LM_ELE_ADR028	15919.2700000000004
2021-07-01	LM_ELE_ADR034	18925
2021-07-01	LM_ELE_ADR036	77843.4199999999983
2021-07-01	LM_ELE_ADR039	270321.130000000005
2021-07-01	LM_ELE_ADR040	29531
2021-07-01	LM_ELE_ADR042	2962.26999999999998
2021-07-01	LM_ELE_ADR044	5891.28999999999996
2021-07-01	LM_ELE_ADR048	6186.78999999999996
2021-07-01	LM_ELE_ADR051	5881.92000000000007
2021-07-01	LM_ELE_ADR053	16437.0200000000004
2021-07-01	LM_ELE_ADR055	4823.35000000000036
2021-07-01	LM_ELE_ADR056	18756.7400000000016
2021-07-01	LM_ELE_ADR063	189
2021-07-01	LM_ELE_ADR064	0
2021-07-01	LM_ELE_ADR058	70101.9100000000035
2021-07-01	LM_ELE_ADR072	20274
2021-07-01	LM_ELE_ADR074	62922
2021-07-01	LM_ELE_ADR076	0
2021-07-01	LM_ELE_ADR081	36841.6900000000023
2021-07-01	LM_ELE_ADR085	36149.3300000000017
2021-07-01	LM_ELE_ADR090	32102.880000000001
2021-07-01	LM_ELE_ADR107	63073.4100000000035
2021-07-01	LM_ELE_ADR108	5889.39000000000033
2021-07-01	LM_ELE_ADR109	2011.28999999999996
2021-07-01	LM_ELE_ADR110	406.220000000000027
2021-07-01	LM_ELE_ADR113	44751.1100000000006
2021-07-01	LM_ELE_ADR087	76703.6999999999971
2021-07-01	LM_LC_ADR_B45	147.02000000000001
2021-07-01	LM_LH_ADR_B46	49.3500000000000014
2021-07-01	LM_LH_ADR_B47	94.5
2021-07-01	LM_WOD_ADR_B74	26.4800000000000004
2021-07-01	LM_ELE_ADR_B06	378002.340000000026
2021-07-01	LM_ELE_ADR046	0
2021-07-01	LM_ELE_ADR010	99055.9100000000035
2021-07-01	LM_ELE_ADR043	2352.51000000000022
2021-07-01	LM_ELE_ADR_B11	27260.2299999999996
2021-07-01	LM_WOD_ADR242	40.240000000000002
2021-07-01	LM_ELE_ADR124	57138.1299999999974
2021-07-01	LM_ELE_ADR112	655449.060000000056
2021-07-01	LM_WOD_ADR_B75	127.069999999999993
2021-07-01	LM_ELE_ADR091	8948.38999999999942
2021-07-01	LM_WOD_ADR_B80	90.4599999999999937
2021-07-01	LM_WOD_ADR_B81	36.4299999999999997
2021-07-01	LM_ELE_ADR_B04	225975.130000000005
2021-07-01	LM_ELE_ADR_B05	202525.880000000005
2021-07-01	LM_ELE_ADR_B09	251422.559999999998
2021-07-01	LM_ELE_ADR_B01	0
2021-07-01	LM_ELE_ADR_B10	25237.0600000000013
2021-07-01	LM_ELE_ADR_B02	0
2021-07-01	LM_LC_ADR_B18	14.4700000000000006
2021-07-01	LM_LC_ADR_B20	58.1400000000000006
2021-07-01	LM_LC_ADR_B22	30.379999999999999
2021-07-01	LM_LC_ADR_B24	10
2021-07-01	LM_LC_ADR_B31	350.100000000000023
2021-07-01	LM_LC_ADR_B41	383
2021-07-01	LM_LC_ADR_B43	5.5
2021-07-01	LM_LH_ADR_B23	50
2021-07-01	LM_LH_ADR_B25	31.1000000000000014
2021-07-01	LM_LH_ADR_B27	94.7999999999999972
2021-07-01	LM_LH_ADR_B35	0
2021-07-01	LM_LH_ADR_B36	0
2021-07-01	LM_LH_ADR_B38	65.5
2021-07-01	LM_LH_ADR_B44	3.39999999999999991
2021-07-01	LM_WOD_ADR_B76	1658.8900000000001
2021-07-01	LM_WOD_ADR_B77	8.57000000000000028
2021-07-01	LM_LC_ADR_B16	32.4500000000000028
2021-07-01	LM_LH_ADR_B17	40.7999999999999972
2021-07-01	LM_WOD_ADR_B79	326.420000000000016
2021-07-01	LM_ELE_ADR_B12	14061.9899999999998
2021-07-01	LM_ELE_ADR_B13	13382.25
2021-07-01	LM_LC_ADR_B46	45.0700000000000003
2021-07-01	LM_LC_ADR193	0
2021-07-01	LM_ELE_ADR125	4098.10000000000036
2021-07-01	LM_ELE_ADR069	243151
2021-07-01	LM_ELE_ADR075	80
2021-08-01	LM_LC_ADR170	48.9600000000000009
2021-08-01	LM_LC_ADR172	90.230000000000004
2021-08-01	LM_LC_ADR179	70.5999999999999943
2021-08-01	LM_ELE_ADR021	199225.73000000001
2021-08-01	LM_ELE_ADR078	38202
2021-08-01	LM_ELE_ADR066	0
2021-08-01	LM_ELE_ADR080	149258.529999999999
2021-08-01	LM_LH_ADR199	128.699999999999989
2021-08-01	LM_ELE_ADR115	21314.6399999999994
2021-08-01	LM_WOD_ADR249_Solution Space	73.6299999999999955
2021-08-01	LM_WOD_MAIN_W	0
2021-08-01	LM_LC_ADR123	371.5
2021-08-01	LM_LC_ADR151	25990
2021-08-01	LM_LC_ADR153	9222
2021-08-01	LM_LC_ADR154	2101.59999999999991
2021-08-01	LM_LC_ADR155	5624.80000000000018
2021-08-01	LM_LC_ADR157	903.700000000000045
2021-08-01	LM_LC_ADR158	282.699999999999989
2021-08-01	LM_LC_ADR162	657.200000000000045
2021-08-01	LM_LC_ADR168	69.5
2021-08-01	LM_LC_ADR173	79.4000000000000057
2021-08-01	LM_LC_ADR174	135.319999999999993
2021-08-01	LM_LC_ADR175	0
2021-08-01	LM_LC_ADR176	84.7000000000000028
2021-08-01	LM_LC_ADR178	95.5799999999999983
2021-08-01	LM_LC_ADR184	38.9600000000000009
2021-08-01	LM_LC_ADR186	15.5399999999999991
2021-08-01	LM_LC_ADR187	29.0399999999999991
2021-08-01	LM_LC_ADR209	84.6800000000000068
2021-08-01	LM_LC_ADR32	0
2021-08-01	LM_LC_ADR82	0
2021-08-01	LM_LH_ADR122	10.8000000000000007
2021-08-01	LM_LH_ADR189	49.2800000000000011
2021-08-01	LM_LH_ADR195	390.100000000000023
2021-08-01	LM_LH_ADR196	9
2021-08-01	LM_LH_ADR198	1054.79999999999995
2021-08-01	LM_LH_ADR200	42.3999999999999986
2021-08-01	LM_LH_ADR203	205.599999999999994
2021-08-01	LM_LH_ADR204	86.2000000000000028
2021-08-01	LM_LH_ADR208	256.800000000000011
2021-08-01	LM_LH_ADR211	21.6000000000000014
2021-08-01	LM_LH_ADR212	115
2021-08-01	LM_LH_ADR216	27.9699999999999989
2021-08-01	LM_LH_ADR218	346.100000000000023
2021-08-01	LM_LH_ADR221	247.300000000000011
2021-08-01	LM_LH_ADR222	0
2021-08-01	LM_LH_ADR227	34.3999999999999986
2021-08-01	LM_LH_ADR229	83.8599999999999994
2021-08-01	LM_LH_ADR231	0
2021-08-01	LM_LH_ADR234	0
2021-08-01	LM_LH_ADR235	84.0999999999999943
2021-08-01	LM_LH_ADR33	0
2021-08-01	LM_ELE_ADR008	77991.25
2021-08-01	LM_ELE_ADR012	61467.3099999999977
2021-08-01	LM_ELE_ADR017	10777.3600000000006
2021-08-01	LM_ELE_ADR019	2439.5300000000002
2021-08-01	LM_ELE_ADR024	108638.589999999997
2021-08-01	LM_ELE_ADR027	33675.5599999999977
2021-08-01	LM_LC_ADR163	26.4400000000000013
2021-08-01	LM_LC_ADR164	0.0200000000000000004
2021-08-01	LM_LH_ADR201	65.7000000000000028
2021-08-01	LM_ELE_ADR029	9532.79000000000087
2021-08-01	LM_ELE_ADR031	143999.839999999997
2021-08-01	LM_ELE_ADR038	262812.630000000005
2021-08-01	LM_ELE_ADR041	57072.8899999999994
2021-08-01	LM_ELE_ADR045	5091.30000000000018
2021-08-01	LM_ELE_ADR047	4569.56999999999971
2021-08-01	LM_ELE_ADR049	12897.1200000000008
2021-08-01	LM_ELE_ADR052	9609.51000000000022
2021-08-01	LM_ELE_ADR054	26931.7700000000004
2021-08-01	LM_ELE_ADR057	5320.8100000000004
2021-08-01	LM_ELE_ADR059	19784.1399999999994
2021-08-01	LM_ELE_ADR060	0
2021-08-01	LM_ELE_ADR061	0
2021-08-01	LM_ELE_ADR062	16746
2021-08-01	LM_ELE_ADR065	0
2021-08-01	LM_ELE_ADR067	125
2021-08-01	LM_ELE_ADR068	473
2021-08-01	LM_ELE_ADR070	80
2021-08-01	LM_ELE_ADR071	64861
2021-08-01	LM_ELE_ADR073	80
2021-08-01	LM_ELE_ADR077	1063
2021-08-01	LM_ELE_ADR084	48649.0999999999985
2021-08-01	LM_ELE_ADR086	11215.6900000000005
2021-08-01	LM_ELE_ADR088	31259.5099999999984
2021-08-01	LM_ELE_ADR094	1414.51999999999998
2021-08-01	LM_ELE_ADR095	84463.25
2021-08-01	LM_ELE_ADR097	23214.7900000000009
2021-08-01	LM_ELE_ADR098	3036.38999999999987
2021-08-01	LM_ELE_ADR099	57513.9400000000023
2021-08-01	LM_ELE_ADR100	13375.6200000000008
2021-08-01	LM_ELE_ADR101	6199.88000000000011
2021-08-01	LM_ELE_ADR111	362.079999999999984
2021-08-01	LM_ELE_ADR116	9988.40999999999985
2021-08-01	LM_ELE_ADR118	18346.2200000000012
2021-08-01	LM_ELE_ADR119	64472.7900000000009
2021-08-01	LM_ELE_ADR120	72649.2899999999936
2021-08-01	LM_WOD_ADR129	92.1500000000000057
2021-08-01	LM_WOD_ADR140	120.390000000000001
2021-08-01	LM_WOD_ADR147	51.5499999999999972
2021-08-01	LM_WOD_ADR246_Solution Space	419.689999999999998
2021-08-01	LM_WOD_ADR248_Solution Space	31.3999999999999986
2021-08-01	LM_ELE_ADR_B03	111810.770000000004
2021-08-01	LM_ELE_ADR_B07	88525.8399999999965
2021-08-01	LM_ELE_ADR_B08	132174.779999999999
2021-08-01	LM_LC_ADR_B26	104.760000000000005
2021-08-01	LM_LC_ADR_B30	342.899999999999977
2021-08-01	LM_LC_ADR_B32	765.799999999999955
2021-08-01	LM_LC_ADR_B33	650.299999999999955
2021-08-01	LM_LH_ADR_B19	72.7999999999999972
2021-08-01	LM_LH_ADR_B21	156.099999999999994
2021-08-01	LM_LH_ADR_B34	0
2021-08-01	LM_LH_ADR_B37	0.400000000000000022
2021-08-01	LM_LH_ADR_B39	91.7999999999999972
2021-08-01	LM_LH_ADR_B40	151.099999999999994
2021-08-01	LM_LH_ADR_B42	0
2021-08-01	LM_WOD_ADR_B78	175.02000000000001
2021-08-01	LM_LC_ADR102	40.9600000000000009
2021-08-01	LM_LC_ADR103	45.0200000000000031
2021-08-01	LM_LC_ADR104	54.9200000000000017
2021-08-01	LM_LC_ADR152	4239.39999999999964
2021-08-01	LM_LC_ADR149	0.910000000000000031
2021-08-01	LM_LC_ADR156	2750.80000000000018
2021-08-01	LM_LC_ADR171	239.090000000000003
2021-08-01	LM_LC_ADR165	35.9099999999999966
2021-08-01	LM_LC_ADR166	29
2021-08-01	LM_LC_ADR180	123.879999999999995
2021-08-01	LM_LC_ADR181	0.100000000000000006
2021-08-01	LM_LC_ADR182	73.3100000000000023
2021-08-01	LM_LC_ADR183	1.41999999999999993
2021-08-01	LM_LC_ADR185	16.129999999999999
2021-08-01	LM_LC_ADR161	1199.59999999999991
2021-08-01	LM_LC_ADR224	124.040000000000006
2021-08-01	LM_LC_ADR89	26.120000000000001
2021-08-01	LM_LC_ADR93	25.620000000000001
2021-08-01	LM_LH_ADR145	9.48000000000000043
2021-08-01	LM_LH_ADR188	30.9899999999999984
2021-08-01	LM_LH_ADR190	7.62000000000000011
2021-08-01	LM_LH_ADR191	18.6000000000000014
2021-08-01	LM_LH_ADR192	0
2021-08-01	LM_LH_ADR194	745.600000000000023
2021-08-01	LM_LH_ADR207	384.399999999999977
2021-08-01	LM_LH_ADR197	1173.40000000000009
2021-08-01	LM_LH_ADR215	0
2021-08-01	LM_LH_ADR219	0.0299999999999999989
2021-08-01	LM_LH_ADR220	71.980000000000004
2021-08-01	LM_LH_ADR223	155.400000000000006
2021-08-01	LM_LH_ADR225	58.5
2021-08-01	LM_LH_ADR226	50.9699999999999989
2021-08-01	LM_LH_ADR217	458.399999999999977
2021-08-01	LM_LH_ADR228	26.8000000000000007
2021-08-01	LM_LH_ADR232	47.990000000000002
2021-08-01	LM_LH_ADR233	42.8999999999999986
2021-08-01	LM_LH_ADR230	1.5
2021-08-01	LM_ELE_ADR114	8.22000000000000064
2021-08-01	LM_ELE_ADR117	20751.7799999999988
2021-08-01	LM_WOD_ADR132	265.850000000000023
2021-08-01	LM_WOD_ADR133	323.45999999999998
2021-08-01	LM_WOD_ADR134	18.1900000000000013
2021-08-01	LM_WOD_ADR135	0
2021-08-01	LM_WOD_ADR136	62.5600000000000023
2021-08-01	LM_WOD_ADR139	1135.66000000000008
2021-08-01	LM_WOD_ADR141	17
2021-08-01	LM_WOD_ADR142	36
2021-08-01	LM_WOD_ADR143	410.990000000000009
2021-08-01	LM_WOD_ADR146	26031.0999999999985
2021-08-01	LM_WOD_ADR148	0.0500000000000000028
2021-08-01	LM_WOD_ADR150	33.8400000000000034
2021-08-01	LM_WOD_ADR237	911.100000000000023
2021-08-01	LM_WOD_ADR238	2210.82999999999993
2021-08-01	LM_WOD_ADR239	27.2899999999999991
2021-08-01	LM_WOD_ADR240	95.8499999999999943
2021-08-01	LM_WOD_ADR241	918.889999999999986
2021-08-01	LM_ELE_ADR121	85.4399999999999977
2021-08-01	LM_ELE_ADR128	0
2021-08-01	LM_WOD_ADR247_Solution Space	385.100000000000023
2021-08-01	LM_WOD_ADR250_Solution Space	141.47999999999999
2021-08-01	LM_WOD_ADR30	0
2021-08-01	LM_ELE_ADR001	58874.6299999999974
2021-08-01	LM_ELE_ADR002	77871.9100000000035
2021-08-01	LM_ELE_ADR003	94020.4900000000052
2021-08-01	LM_ELE_ADR006	67161.5800000000017
2021-08-01	LM_ELE_ADR007	113735.449999999997
2021-08-01	LM_ELE_ADR009	154667.529999999999
2021-08-01	LM_ELE_ADR011	152282.5
2021-08-01	LM_ELE_ADR013	192124.029999999999
2021-08-01	LM_ELE_ADR014	11997.5799999999999
2021-08-01	LM_ELE_ADR015	110355.660000000003
2021-08-01	LM_ELE_ADR016	849366.189999999944
2021-08-01	LM_ELE_ADR018	11321.5900000000001
2021-08-01	LM_ELE_ADR020	118231.039999999994
2021-08-01	LM_ELE_ADR022	115261.860000000001
2021-08-01	LM_ELE_ADR023	25488.130000000001
2021-08-01	LM_ELE_ADR025	344389
2021-08-01	LM_ELE_ADR028	16577.7400000000016
2021-08-01	LM_ELE_ADR034	19986.1800000000003
2021-08-01	LM_ELE_ADR036	78001.3399999999965
2021-08-01	LM_ELE_ADR039	278047.409999999974
2021-08-01	LM_ELE_ADR040	29531
2021-08-01	LM_ELE_ADR042	3020.34000000000015
2021-08-01	LM_ELE_ADR044	5981.10000000000036
2021-08-01	LM_ELE_ADR048	6282.09000000000015
2021-08-01	LM_ELE_ADR051	5976.98999999999978
2021-08-01	LM_ELE_ADR053	17375.7599999999984
2021-08-01	LM_ELE_ADR055	4909.10999999999967
2021-08-01	LM_ELE_ADR056	19092.0699999999997
2021-08-01	LM_ELE_ADR063	189
2021-08-01	LM_ELE_ADR064	0
2021-08-01	LM_ELE_ADR058	71415.9400000000023
2021-08-01	LM_ELE_ADR072	20934
2021-08-01	LM_ELE_ADR074	64861
2021-08-01	LM_ELE_ADR076	0
2021-08-01	LM_ELE_ADR081	37751.0999999999985
2021-08-01	LM_ELE_ADR085	38020.1900000000023
2021-08-01	LM_ELE_ADR090	32589.7000000000007
2021-08-01	LM_ELE_ADR107	65332.7099999999991
2021-08-01	LM_ELE_ADR108	5984.64000000000033
2021-08-01	LM_ELE_ADR109	2011.43000000000006
2021-08-01	LM_ELE_ADR110	406.220000000000027
2021-08-01	LM_ELE_ADR113	45796.6900000000023
2021-08-01	LM_ELE_ADR087	78117.5099999999948
2021-08-01	LM_LC_ADR_B45	147.02000000000001
2021-08-01	LM_LH_ADR_B46	49.3500000000000014
2021-08-01	LM_LH_ADR_B47	106.299999999999997
2021-08-01	LM_WOD_ADR_B74	27.4800000000000004
2021-08-01	LM_ELE_ADR_B06	393270.280000000028
2021-08-01	LM_ELE_ADR046	0
2021-08-01	LM_ELE_ADR010	100958.259999999995
2021-08-01	LM_ELE_ADR043	2402.05999999999995
2021-08-01	LM_ELE_ADR_B11	27748.4399999999987
2021-08-01	LM_WOD_ADR242	40.3299999999999983
2021-08-01	LM_ELE_ADR124	62021.0400000000009
2021-08-01	LM_ELE_ADR112	664588.689999999944
2021-08-01	LM_WOD_ADR_B75	129.590000000000003
2021-08-01	LM_ELE_ADR091	9276.47999999999956
2021-08-01	LM_WOD_ADR_B80	93.0400000000000063
2021-08-01	LM_WOD_ADR_B81	37.0799999999999983
2021-08-01	LM_ELE_ADR_B04	253045.059999999998
2021-08-01	LM_ELE_ADR_B05	209713.359999999986
2021-08-01	LM_ELE_ADR_B09	256001.170000000013
2021-08-01	LM_ELE_ADR_B01	0
2021-08-01	LM_ELE_ADR_B10	25476.2999999999993
2021-08-01	LM_ELE_ADR_B02	0
2021-08-01	LM_LC_ADR_B18	14.4700000000000006
2021-08-01	LM_LC_ADR_B20	58.1400000000000006
2021-08-01	LM_LC_ADR_B22	30.379999999999999
2021-08-01	LM_LC_ADR_B24	10
2021-08-01	LM_LC_ADR_B31	350.100000000000023
2021-08-01	LM_LC_ADR_B41	383
2021-08-01	LM_LC_ADR_B43	5.79999999999999982
2021-08-01	LM_LH_ADR_B23	55.7999999999999972
2021-08-01	LM_LH_ADR_B25	38.6000000000000014
2021-08-01	LM_LH_ADR_B27	99.2999999999999972
2021-08-01	LM_LH_ADR_B35	0
2021-08-01	LM_LH_ADR_B36	0
2021-08-01	LM_LH_ADR_B38	69.2000000000000028
2021-08-01	LM_LH_ADR_B44	3.5
2021-08-01	LM_WOD_ADR_B76	1736.03999999999996
2021-08-01	LM_WOD_ADR_B77	8.71000000000000085
2021-08-01	LM_LC_ADR_B16	32.4500000000000028
2021-08-01	LM_LH_ADR_B17	42.6000000000000014
2021-08-01	LM_WOD_ADR_B79	333.79000000000002
2021-08-01	LM_ELE_ADR_B12	14472.5100000000002
2021-08-01	LM_ELE_ADR_B13	13666.5499999999993
2021-08-01	LM_LC_ADR_B46	45.0700000000000003
2021-08-01	LM_LC_ADR193	0
2021-08-01	LM_ELE_ADR125	4221.80000000000018
2021-08-01	LM_ELE_ADR069	248273
2021-08-01	LM_ELE_ADR075	80
2021-09-01	LM_LC_ADR170	49.2199999999999989
2021-09-01	LM_LC_ADR172	90.230000000000004
2021-09-01	LM_LC_ADR179	70.5999999999999943
2021-09-01	LM_ELE_ADR021	202861.76999999999
2021-09-01	LM_ELE_ADR078	39808
2021-09-01	LM_ELE_ADR066	0
2021-09-01	LM_ELE_ADR080	152355.839999999997
2021-09-01	LM_LH_ADR199	132.900000000000006
2021-09-01	LM_ELE_ADR115	22000.9599999999991
2021-09-01	LM_WOD_ADR249_Solution Space	77.0799999999999983
2021-09-01	LM_WOD_MAIN_W	0
2021-09-01	LM_LC_ADR123	378
2021-09-01	LM_LC_ADR151	26063
2021-09-01	LM_LC_ADR153	9242
2021-09-01	LM_LC_ADR154	2117
2021-09-01	LM_LC_ADR155	5653
2021-09-01	LM_LC_ADR157	912.399999999999977
2021-09-01	LM_LC_ADR158	284
2021-09-01	LM_LC_ADR162	658.799999999999955
2021-09-01	LM_LC_ADR168	70.7000000000000028
2021-09-01	LM_LC_ADR173	80.0900000000000034
2021-09-01	LM_LC_ADR174	138.75
2021-09-01	LM_LC_ADR175	0
2021-09-01	LM_LC_ADR176	84.7000000000000028
2021-09-01	LM_LC_ADR178	96.6899999999999977
2021-09-01	LM_LC_ADR184	38.9600000000000009
2021-09-01	LM_LC_ADR186	15.5399999999999991
2021-09-01	LM_LC_ADR187	29.0399999999999991
2021-09-01	LM_LC_ADR209	84.6800000000000068
2021-09-01	LM_LC_ADR32	0
2021-09-01	LM_LC_ADR82	0
2021-09-01	LM_LH_ADR122	12.1999999999999993
2021-09-01	LM_LH_ADR189	53.7199999999999989
2021-09-01	LM_LH_ADR195	402.300000000000011
2021-09-01	LM_LH_ADR196	9
2021-09-01	LM_LH_ADR198	1092.29999999999995
2021-09-01	LM_LH_ADR200	43.5
2021-09-01	LM_LH_ADR203	210.199999999999989
2021-09-01	LM_LH_ADR204	90.0999999999999943
2021-09-01	LM_LH_ADR208	265.100000000000023
2021-09-01	LM_LH_ADR211	24.1000000000000014
2021-09-01	LM_LH_ADR212	125.200000000000003
2021-09-01	LM_LH_ADR216	30.0899999999999999
2021-09-01	LM_LH_ADR218	360.600000000000023
2021-09-01	LM_LH_ADR221	263.5
2021-09-01	LM_LH_ADR222	0
2021-09-01	LM_LH_ADR227	40
2021-09-01	LM_LH_ADR229	84.8100000000000023
2021-09-01	LM_LH_ADR231	0
2021-09-01	LM_LH_ADR234	0
2021-09-01	LM_LH_ADR235	84.0999999999999943
2021-09-01	LM_LH_ADR33	0
2021-09-01	LM_ELE_ADR008	80200.3800000000047
2021-09-01	LM_ELE_ADR012	61981.3199999999997
2021-09-01	LM_ELE_ADR017	10980.8099999999995
2021-09-01	LM_ELE_ADR019	2439.5300000000002
2021-09-01	LM_ELE_ADR024	110566.529999999999
2021-09-01	LM_ELE_ADR027	33968.5199999999968
2021-09-01	LM_LC_ADR163	26.4499999999999993
2021-09-01	LM_LC_ADR164	0.0200000000000000004
2021-09-01	LM_LH_ADR201	72.7999999999999972
2021-09-01	LM_ELE_ADR029	9979.25
2021-09-01	LM_ELE_ADR031	148047.170000000013
2021-09-01	LM_ELE_ADR038	273782.659999999974
2021-09-01	LM_ELE_ADR041	57700.8799999999974
2021-09-01	LM_ELE_ADR045	5196.68000000000029
2021-09-01	LM_ELE_ADR047	4670.90999999999985
2021-09-01	LM_ELE_ADR049	13137.2900000000009
2021-09-01	LM_ELE_ADR052	9802.20000000000073
2021-09-01	LM_ELE_ADR054	27444.630000000001
2021-09-01	LM_ELE_ADR057	5416.5
2021-09-01	LM_ELE_ADR059	20294.8400000000001
2021-09-01	LM_ELE_ADR060	0
2021-09-01	LM_ELE_ADR061	0
2021-09-01	LM_ELE_ADR062	17338
2021-09-01	LM_ELE_ADR065	0
2021-09-01	LM_ELE_ADR067	126
2021-09-01	LM_ELE_ADR068	554
2021-09-01	LM_ELE_ADR070	80
2021-09-01	LM_ELE_ADR071	66971
2021-09-01	LM_ELE_ADR073	80
2021-09-01	LM_ELE_ADR077	1063
2021-09-01	LM_ELE_ADR084	49669.8199999999997
2021-09-01	LM_ELE_ADR086	11612.1200000000008
2021-09-01	LM_ELE_ADR088	32222.8400000000001
2021-09-01	LM_ELE_ADR094	1432.65000000000009
2021-09-01	LM_ELE_ADR095	86779.0899999999965
2021-09-01	LM_ELE_ADR097	24151.3199999999997
2021-09-01	LM_ELE_ADR098	3108.80999999999995
2021-09-01	LM_ELE_ADR099	60490.8300000000017
2021-09-01	LM_ELE_ADR100	13787.1200000000008
2021-09-01	LM_ELE_ADR101	6408.36999999999989
2021-09-01	LM_ELE_ADR111	362.230000000000018
2021-09-01	LM_ELE_ADR116	11303.9599999999991
2021-09-01	LM_ELE_ADR118	18628.8899999999994
2021-09-01	LM_ELE_ADR119	65852.0200000000041
2021-09-01	LM_ELE_ADR120	72716.6699999999983
2021-09-01	LM_WOD_ADR129	95.5300000000000011
2021-09-01	LM_WOD_ADR140	120.620000000000005
2021-09-01	LM_WOD_ADR147	52.8699999999999974
2021-09-01	LM_WOD_ADR246_Solution Space	436.829999999999984
2021-09-01	LM_WOD_ADR248_Solution Space	32.9699999999999989
2021-09-01	LM_ELE_ADR_B03	114001.119999999995
2021-09-01	LM_ELE_ADR_B07	89911.1699999999983
2021-09-01	LM_ELE_ADR_B08	134226.339999999997
2021-09-01	LM_LC_ADR_B26	105.069999999999993
2021-09-01	LM_LC_ADR_B30	343.699999999999989
2021-09-01	LM_LC_ADR_B32	767.200000000000045
2021-09-01	LM_LC_ADR_B33	652.299999999999955
2021-09-01	LM_LH_ADR_B19	73.7999999999999972
2021-09-01	LM_LH_ADR_B21	161.099999999999994
2021-09-01	LM_LH_ADR_B34	0
2021-09-01	LM_LH_ADR_B37	0.400000000000000022
2021-09-01	LM_LH_ADR_B39	93.9000000000000057
2021-09-01	LM_LH_ADR_B40	155.400000000000006
2021-09-01	LM_LH_ADR_B42	0
2021-09-01	LM_WOD_ADR_B78	176.419999999999987
2021-09-01	LM_LC_ADR102	41.3699999999999974
2021-09-01	LM_LC_ADR103	45.4299999999999997
2021-09-01	LM_LC_ADR104	55.5700000000000003
2021-09-01	LM_LC_ADR152	4244.10000000000036
2021-09-01	LM_LC_ADR149	0.910000000000000031
2021-09-01	LM_LC_ADR156	2765.69999999999982
2021-09-01	LM_LC_ADR171	239.199999999999989
2021-09-01	LM_LC_ADR165	36.3200000000000003
2021-09-01	LM_LC_ADR166	29.3000000000000007
2021-09-01	LM_LC_ADR180	124.439999999999998
2021-09-01	LM_LC_ADR181	0.100000000000000006
2021-09-01	LM_LC_ADR182	73.3599999999999994
2021-09-01	LM_LC_ADR183	1.41999999999999993
2021-09-01	LM_LC_ADR185	16.129999999999999
2021-09-01	LM_LC_ADR161	1207.90000000000009
2021-09-01	LM_LC_ADR224	125.260000000000005
2021-09-01	LM_LC_ADR89	26.4499999999999993
2021-09-01	LM_LC_ADR93	25.9499999999999993
2021-09-01	LM_LH_ADR145	9.80000000000000071
2021-09-01	LM_LH_ADR188	32.1799999999999997
2021-09-01	LM_LH_ADR190	7.79000000000000004
2021-09-01	LM_LH_ADR191	18.8000000000000007
2021-09-01	LM_LH_ADR192	0
2021-09-01	LM_LH_ADR194	771
2021-09-01	LM_LH_ADR207	387.699999999999989
2021-09-01	LM_LH_ADR197	1202.5
2021-09-01	LM_LH_ADR215	0
2021-09-01	LM_LH_ADR219	0.0299999999999999989
2021-09-01	LM_LH_ADR220	71.980000000000004
2021-09-01	LM_LH_ADR223	169.599999999999994
2021-09-01	LM_LH_ADR225	62.6000000000000014
2021-09-01	LM_LH_ADR226	51.4200000000000017
2021-09-01	LM_LH_ADR217	470
2021-09-01	LM_LH_ADR228	26.8000000000000007
2021-09-01	LM_LH_ADR232	49.3999999999999986
2021-09-01	LM_LH_ADR233	44.6000000000000014
2021-09-01	LM_LH_ADR230	1.5
2021-09-01	LM_ELE_ADR114	27.8099999999999987
2021-09-01	LM_ELE_ADR117	21109.1100000000006
2021-09-01	LM_WOD_ADR132	272.879999999999995
2021-09-01	LM_WOD_ADR133	327.269999999999982
2021-09-01	LM_WOD_ADR134	18.2699999999999996
2021-09-01	LM_WOD_ADR135	0
2021-09-01	LM_WOD_ADR136	63.5
2021-09-01	LM_WOD_ADR139	1190.77999999999997
2021-09-01	LM_WOD_ADR141	17
2021-09-01	LM_WOD_ADR142	36
2021-09-01	LM_WOD_ADR143	461.95999999999998
2021-09-01	LM_WOD_ADR146	26660.2000000000007
2021-09-01	LM_WOD_ADR148	0.0500000000000000028
2021-09-01	LM_WOD_ADR150	34.8699999999999974
2021-09-01	LM_WOD_ADR237	921.960000000000036
2021-09-01	LM_WOD_ADR238	2211.65999999999985
2021-09-01	LM_WOD_ADR239	27.7199999999999989
2021-09-01	LM_WOD_ADR240	99.9200000000000017
2021-09-01	LM_WOD_ADR241	942.090000000000032
2021-09-01	LM_ELE_ADR121	159197.109999999986
2021-09-01	LM_ELE_ADR128	0
2021-09-01	LM_WOD_ADR247_Solution Space	403.629999999999995
2021-09-01	LM_WOD_ADR250_Solution Space	150.710000000000008
2021-09-01	LM_WOD_ADR30	0
2021-09-01	LM_ELE_ADR001	60136.4700000000012
2021-09-01	LM_ELE_ADR002	79330.1499999999942
2021-09-01	LM_ELE_ADR003	95754.9499999999971
2021-09-01	LM_ELE_ADR006	67984.5200000000041
2021-09-01	LM_ELE_ADR007	115028.410000000003
2021-09-01	LM_ELE_ADR009	155515.970000000001
2021-09-01	LM_ELE_ADR011	153288.190000000002
2021-09-01	LM_ELE_ADR013	192436.98000000001
2021-09-01	LM_ELE_ADR014	12320.3400000000001
2021-09-01	LM_ELE_ADR015	113091.75
2021-09-01	LM_ELE_ADR016	864589.630000000005
2021-09-01	LM_ELE_ADR018	11572.2800000000007
2021-09-01	LM_ELE_ADR020	120383.419999999998
2021-09-01	LM_ELE_ADR022	118320.970000000001
2021-09-01	LM_ELE_ADR023	26475.5099999999984
2021-09-01	LM_ELE_ADR025	356782.559999999998
2021-09-01	LM_ELE_ADR028	17203.9700000000012
2021-09-01	LM_ELE_ADR034	21184.1599999999999
2021-09-01	LM_ELE_ADR036	78816.0800000000017
2021-09-01	LM_ELE_ADR039	284463.219999999972
2021-09-01	LM_ELE_ADR040	29531
2021-09-01	LM_ELE_ADR042	3086.23999999999978
2021-09-01	LM_ELE_ADR044	6083.53999999999996
2021-09-01	LM_ELE_ADR048	6389.78999999999996
2021-09-01	LM_ELE_ADR051	6086.89000000000033
2021-09-01	LM_ELE_ADR053	17451.1599999999999
2021-09-01	LM_ELE_ADR055	5007.90999999999985
2021-09-01	LM_ELE_ADR056	19470.4799999999996
2021-09-01	LM_ELE_ADR063	189
2021-09-01	LM_ELE_ADR064	0
2021-09-01	LM_ELE_ADR058	72905.4100000000035
2021-09-01	LM_ELE_ADR072	21684
2021-09-01	LM_ELE_ADR074	66971
2021-09-01	LM_ELE_ADR076	0
2021-09-01	LM_ELE_ADR081	38846.9499999999971
2021-09-01	LM_ELE_ADR085	40309.3399999999965
2021-09-01	LM_ELE_ADR090	33148.1900000000023
2021-09-01	LM_ELE_ADR107	67646.1300000000047
2021-09-01	LM_ELE_ADR108	6060.86999999999989
2021-09-01	LM_ELE_ADR109	2011.73000000000002
2021-09-01	LM_ELE_ADR110	406.220000000000027
2021-09-01	LM_ELE_ADR113	46624.0599999999977
2021-09-01	LM_ELE_ADR087	79767.3099999999977
2021-09-01	LM_LC_ADR_B45	147.189999999999998
2021-09-01	LM_LH_ADR_B46	49.3500000000000014
2021-09-01	LM_LH_ADR_B47	113
2021-09-01	LM_WOD_ADR_B74	28.4600000000000009
2021-09-01	LM_ELE_ADR_B06	402729.090000000026
2021-09-01	LM_ELE_ADR046	0
2021-09-01	LM_ELE_ADR010	102811.699999999997
2021-09-01	LM_ELE_ADR043	2456.57999999999993
2021-09-01	LM_ELE_ADR_B11	28238.5499999999993
2021-09-01	LM_WOD_ADR242	40.4600000000000009
2021-09-01	LM_ELE_ADR124	67253.3000000000029
2021-09-01	LM_ELE_ADR112	674885.689999999944
2021-09-01	LM_WOD_ADR_B75	134.009999999999991
2021-09-01	LM_ELE_ADR091	9650.80999999999949
2021-09-01	LM_WOD_ADR_B80	95.8599999999999994
2021-09-01	LM_WOD_ADR_B81	38
2021-09-01	LM_ELE_ADR_B04	262766.25
2021-09-01	LM_ELE_ADR_B05	220849.410000000003
2021-09-01	LM_ELE_ADR_B09	261323.309999999998
2021-09-01	LM_ELE_ADR_B01	0
2021-09-01	LM_ELE_ADR_B10	26075.4500000000007
2021-09-01	LM_ELE_ADR_B02	0
2021-09-01	LM_LC_ADR_B18	14.5299999999999994
2021-09-01	LM_LC_ADR_B20	58.1899999999999977
2021-09-01	LM_LC_ADR_B22	30.5599999999999987
2021-09-01	LM_LC_ADR_B24	10
2021-09-01	LM_LC_ADR_B31	350.300000000000011
2021-09-01	LM_LC_ADR_B41	383.699999999999989
2021-09-01	LM_LC_ADR_B43	6.09999999999999964
2021-09-01	LM_LH_ADR_B23	59
2021-09-01	LM_LH_ADR_B25	45
2021-09-01	LM_LH_ADR_B27	102.599999999999994
2021-09-01	LM_LH_ADR_B35	0
2021-09-01	LM_LH_ADR_B36	0
2021-09-01	LM_LH_ADR_B38	70.2999999999999972
2021-09-01	LM_LH_ADR_B44	3.79999999999999982
2021-09-01	LM_WOD_ADR_B76	1736.56999999999994
2021-09-01	LM_WOD_ADR_B77	8.75
2021-09-01	LM_LC_ADR_B16	32.4500000000000028
2021-09-01	LM_LH_ADR_B17	43.7000000000000028
2021-09-01	LM_WOD_ADR_B79	344.29000000000002
2021-09-01	LM_ELE_ADR_B12	14876.2099999999991
2021-09-01	LM_ELE_ADR_B13	14013.8600000000006
2021-09-01	LM_LC_ADR_B46	45.0700000000000003
2021-09-01	LM_LC_ADR193	0
2021-09-01	LM_ELE_ADR125	4364.85000000000036
2021-09-01	LM_ELE_ADR069	254150
2021-09-01	LM_ELE_ADR075	80
2021-10-01	LM_LC_ADR170	49.4699999999999989
2021-10-01	LM_LC_ADR172	90.3400000000000034
2021-10-01	LM_LC_ADR179	70.6299999999999955
2021-10-01	LM_ELE_ADR021	207188.98000000001
2021-10-01	LM_ELE_ADR078	41999
2021-10-01	LM_ELE_ADR066	0
2021-10-01	LM_ELE_ADR080	155066.559999999998
2021-10-01	LM_LH_ADR199	135.400000000000006
2021-10-01	LM_ELE_ADR115	22689.9000000000015
2021-10-01	LM_WOD_ADR249_Solution Space	81.1899999999999977
2021-10-01	LM_WOD_MAIN_W	0
2021-10-01	LM_LC_ADR123	391.800000000000011
2021-10-01	LM_LC_ADR151	26237.0020000000004
2021-10-01	LM_LC_ADR153	9285
2021-10-01	LM_LC_ADR154	2148.09999999999991
2021-10-01	LM_LC_ADR155	5712
2021-10-01	LM_LC_ADR157	924.5
2021-10-01	LM_LC_ADR158	287.399999999999977
2021-10-01	LM_LC_ADR162	662.700000000000045
2021-10-01	LM_LC_ADR168	73.7000000000000028
2021-10-01	LM_LC_ADR173	81.9699999999999989
2021-10-01	LM_LC_ADR174	146.610000000000014
2021-10-01	LM_LC_ADR175	0
2021-10-01	LM_LC_ADR176	84.7000000000000028
2021-10-01	LM_LC_ADR178	98.9099999999999966
2021-10-01	LM_LC_ADR184	39.1700000000000017
2021-10-01	LM_LC_ADR186	15.5399999999999991
2021-10-01	LM_LC_ADR187	29.0399999999999991
2021-10-01	LM_LC_ADR209	84.7199999999999989
2021-10-01	LM_LC_ADR32	0
2021-10-01	LM_LC_ADR82	0.770000000000000018
2021-10-01	LM_LH_ADR122	13.3000000000000007
2021-10-01	LM_LH_ADR189	55.4200000000000017
2021-10-01	LM_LH_ADR195	408.399999999999977
2021-10-01	LM_LH_ADR196	9
2021-10-01	LM_LH_ADR198	1122
2021-10-01	LM_LH_ADR200	44.3999999999999986
2021-10-01	LM_LH_ADR203	212.699999999999989
2021-10-01	LM_LH_ADR204	92.5
2021-10-01	LM_LH_ADR208	271.800000000000011
2021-10-01	LM_LH_ADR211	26.1999999999999993
2021-10-01	LM_LH_ADR212	134.800000000000011
2021-10-01	LM_LH_ADR216	30.0899999999999999
2021-10-01	LM_LH_ADR218	372.5
2021-10-01	LM_LH_ADR221	279.699999999999989
2021-10-01	LM_LH_ADR222	0
2021-10-01	LM_LH_ADR227	40.8999999999999986
2021-10-01	LM_LH_ADR229	84.8100000000000023
2021-10-01	LM_LH_ADR231	0
2021-10-01	LM_LH_ADR234	0
2021-10-01	LM_LH_ADR235	84.4000000000000057
2021-10-01	LM_LH_ADR33	0
2021-10-01	LM_ELE_ADR008	82018.4799999999959
2021-10-01	LM_ELE_ADR012	63353
2021-10-01	LM_ELE_ADR017	11189.9500000000007
2021-10-01	LM_ELE_ADR019	2439.5300000000002
2021-10-01	LM_ELE_ADR024	112330.979999999996
2021-10-01	LM_ELE_ADR027	34233.5400000000009
2021-10-01	LM_LC_ADR163	26.4600000000000009
2021-10-01	LM_LC_ADR164	0.0200000000000000004
2021-10-01	LM_LH_ADR201	80.4000000000000057
2021-10-01	LM_ELE_ADR029	10393.1399999999994
2021-10-01	LM_ELE_ADR031	155303.339999999997
2021-10-01	LM_ELE_ADR038	282444.969999999972
2021-10-01	LM_ELE_ADR041	58626.1800000000003
2021-10-01	LM_ELE_ADR045	5304.21000000000004
2021-10-01	LM_ELE_ADR047	4774.65999999999985
2021-10-01	LM_ELE_ADR049	13358.75
2021-10-01	LM_ELE_ADR052	9973.67000000000007
2021-10-01	LM_ELE_ADR054	27897.9599999999991
2021-10-01	LM_ELE_ADR057	5513.07999999999993
2021-10-01	LM_ELE_ADR059	20733.9399999999987
2021-10-01	LM_ELE_ADR060	0
2021-10-01	LM_ELE_ADR061	0
2021-10-01	LM_ELE_ADR062	17897
2021-10-01	LM_ELE_ADR065	0
2021-10-01	LM_ELE_ADR067	127
2021-10-01	LM_ELE_ADR068	691
2021-10-01	LM_ELE_ADR070	88
2021-10-01	LM_ELE_ADR071	68685
2021-10-01	LM_ELE_ADR073	88
2021-10-01	LM_ELE_ADR077	1063
2021-10-01	LM_ELE_ADR084	50500.2200000000012
2021-10-01	LM_ELE_ADR086	11968.0300000000007
2021-10-01	LM_ELE_ADR088	33125.7699999999968
2021-10-01	LM_ELE_ADR094	1436.8900000000001
2021-10-01	LM_ELE_ADR095	88822.0299999999988
2021-10-01	LM_ELE_ADR097	25116.9099999999999
2021-10-01	LM_ELE_ADR098	3118.36000000000013
2021-10-01	LM_ELE_ADR099	63245.6600000000035
2021-10-01	LM_ELE_ADR100	14378.3899999999994
2021-10-01	LM_ELE_ADR101	6596.67000000000007
2021-10-01	LM_ELE_ADR111	362.449999999999989
2021-10-01	LM_ELE_ADR116	12475.4899999999998
2021-10-01	LM_ELE_ADR118	18737.5600000000013
2021-10-01	LM_ELE_ADR119	67089.5899999999965
2021-10-01	LM_ELE_ADR120	72774.929999999993
2021-10-01	LM_WOD_ADR129	99.269999999999996
2021-10-01	LM_WOD_ADR140	120.870000000000005
2021-10-01	LM_WOD_ADR147	53.8800000000000026
2021-10-01	LM_WOD_ADR246_Solution Space	456.019999999999982
2021-10-01	LM_WOD_ADR248_Solution Space	34.7299999999999969
2021-10-01	LM_ELE_ADR_B03	116011.190000000002
2021-10-01	LM_ELE_ADR_B07	91297.0800000000017
2021-10-01	LM_ELE_ADR_B08	136360.48000000001
2021-10-01	LM_LC_ADR_B26	106.140000000000001
2021-10-01	LM_LC_ADR_B30	348
2021-10-01	LM_LC_ADR_B32	773.299999999999955
2021-10-01	LM_LC_ADR_B33	658.899999999999977
2021-10-01	LM_LH_ADR_B19	77
2021-10-01	LM_LH_ADR_B21	165.900000000000006
2021-10-01	LM_LH_ADR_B34	0
2021-10-01	LM_LH_ADR_B37	0.400000000000000022
2021-10-01	LM_LH_ADR_B39	94.9000000000000057
2021-10-01	LM_LH_ADR_B40	158.099999999999994
2021-10-01	LM_LH_ADR_B42	0
2021-10-01	LM_WOD_ADR_B78	177.620000000000005
2021-10-01	LM_LC_ADR102	42.1499999999999986
2021-10-01	LM_LC_ADR103	46.2199999999999989
2021-10-01	LM_LC_ADR104	56.9600000000000009
2021-10-01	LM_LC_ADR152	4267.89999999999964
2021-10-01	LM_LC_ADR149	0.910000000000000031
2021-10-01	LM_LC_ADR156	2796.90000000000009
2021-10-01	LM_LC_ADR171	239.539999999999992
2021-10-01	LM_LC_ADR165	37.1400000000000006
2021-10-01	LM_LC_ADR166	29.879999999999999
2021-10-01	LM_LC_ADR180	125.390000000000001
2021-10-01	LM_LC_ADR181	0.100000000000000006
2021-10-01	LM_LC_ADR182	73.6700000000000017
2021-10-01	LM_LC_ADR183	1.41999999999999993
2021-10-01	LM_LC_ADR185	16.129999999999999
2021-10-01	LM_LC_ADR161	1221
2021-10-01	LM_LC_ADR224	127.769999999999996
2021-10-01	LM_LC_ADR89	27.129999999999999
2021-10-01	LM_LC_ADR93	26.629999999999999
2021-10-01	LM_LH_ADR145	9.80000000000000071
2021-10-01	LM_LH_ADR188	32.1799999999999997
2021-10-01	LM_LH_ADR190	7.79000000000000004
2021-10-01	LM_LH_ADR191	18.8000000000000007
2021-10-01	LM_LH_ADR192	0
2021-10-01	LM_LH_ADR194	780
2021-10-01	LM_LH_ADR207	390.100000000000023
2021-10-01	LM_LH_ADR197	1220.29999999999995
2021-10-01	LM_LH_ADR215	0
2021-10-01	LM_LH_ADR219	0.0299999999999999989
2021-10-01	LM_LH_ADR220	71.980000000000004
2021-10-01	LM_LH_ADR223	176.599999999999994
2021-10-01	LM_LH_ADR225	65.7999999999999972
2021-10-01	LM_LH_ADR226	52.6799999999999997
2021-10-01	LM_LH_ADR217	478.100000000000023
2021-10-01	LM_LH_ADR228	26.8000000000000007
2021-10-01	LM_LH_ADR232	50.7299999999999969
2021-10-01	LM_LH_ADR233	45
2021-10-01	LM_LH_ADR230	1.60000000000000009
2021-10-01	LM_ELE_ADR114	234686.390000000014
2021-10-01	LM_ELE_ADR117	21530.5
2021-10-01	LM_WOD_ADR132	278.819999999999993
2021-10-01	LM_WOD_ADR133	330.899999999999977
2021-10-01	LM_WOD_ADR134	18.3200000000000003
2021-10-01	LM_WOD_ADR135	0
2021-10-01	LM_WOD_ADR136	64.4200000000000017
2021-10-01	LM_WOD_ADR139	1229.00999999999999
2021-10-01	LM_WOD_ADR141	17
2021-10-01	LM_WOD_ADR142	36
2021-10-01	LM_WOD_ADR143	536.379999999999995
2021-10-01	LM_WOD_ADR146	27358.2000000000007
2021-10-01	LM_WOD_ADR148	0.0500000000000000028
2021-10-01	LM_WOD_ADR150	35.8999999999999986
2021-10-01	LM_WOD_ADR237	922.440000000000055
2021-10-01	LM_WOD_ADR238	2212.19999999999982
2021-10-01	LM_WOD_ADR239	28.4100000000000001
2021-10-01	LM_WOD_ADR240	104.379999999999995
2021-10-01	LM_WOD_ADR241	966.509999999999991
2021-10-01	LM_ELE_ADR121	159337.589999999997
2021-10-01	LM_ELE_ADR128	0
2021-10-01	LM_WOD_ADR247_Solution Space	432.410000000000025
2021-10-01	LM_WOD_ADR250_Solution Space	158.949999999999989
2021-10-01	LM_WOD_ADR30	0
2021-10-01	LM_ELE_ADR001	61353.5800000000017
2021-10-01	LM_ELE_ADR002	80798.0899999999965
2021-10-01	LM_ELE_ADR003	97450.3399999999965
2021-10-01	LM_ELE_ADR006	69242.6399999999994
2021-10-01	LM_ELE_ADR007	116377.610000000001
2021-10-01	LM_ELE_ADR009	156773.48000000001
2021-10-01	LM_ELE_ADR011	154770.299999999988
2021-10-01	LM_ELE_ADR013	194130.380000000005
2021-10-01	LM_ELE_ADR014	12619.0599999999995
2021-10-01	LM_ELE_ADR015	115660.300000000003
2021-10-01	LM_ELE_ADR016	878135.439999999944
2021-10-01	LM_ELE_ADR018	11797.6900000000005
2021-10-01	LM_ELE_ADR020	122399.729999999996
2021-10-01	LM_ELE_ADR022	121126.850000000006
2021-10-01	LM_ELE_ADR023	27435.619999999999
2021-10-01	LM_ELE_ADR025	368265.219999999972
2021-10-01	LM_ELE_ADR028	17225
2021-10-01	LM_ELE_ADR034	22241.619999999999
2021-10-01	LM_ELE_ADR036	80053
2021-10-01	LM_ELE_ADR039	291323.940000000002
2021-10-01	LM_ELE_ADR040	29531
2021-10-01	LM_ELE_ADR042	3145.55000000000018
2021-10-01	LM_ELE_ADR044	6182.72999999999956
2021-10-01	LM_ELE_ADR048	6495.32999999999993
2021-10-01	LM_ELE_ADR051	6186.86999999999989
2021-10-01	LM_ELE_ADR053	17518.6100000000006
2021-10-01	LM_ELE_ADR055	5096.30000000000018
2021-10-01	LM_ELE_ADR056	19810.5800000000017
2021-10-01	LM_ELE_ADR063	189
2021-10-01	LM_ELE_ADR064	0
2021-10-01	LM_ELE_ADR058	74235.7400000000052
2021-10-01	LM_ELE_ADR072	22363
2021-10-01	LM_ELE_ADR074	68685
2021-10-01	LM_ELE_ADR076	0
2021-10-01	LM_ELE_ADR081	40065.1399999999994
2021-10-01	LM_ELE_ADR085	42413.9499999999971
2021-10-01	LM_ELE_ADR090	33862.2099999999991
2021-10-01	LM_ELE_ADR107	69925.5399999999936
2021-10-01	LM_ELE_ADR108	6121.07999999999993
2021-10-01	LM_ELE_ADR109	2012.8900000000001
2021-10-01	LM_ELE_ADR110	406.220000000000027
2021-10-01	LM_ELE_ADR113	47648.3700000000026
2021-10-01	LM_ELE_ADR087	81020.8399999999965
2021-10-01	LM_LC_ADR_B45	149.219999999999999
2021-10-01	LM_LH_ADR_B46	49.3500000000000014
2021-10-01	LM_LH_ADR_B47	115.5
2021-10-01	LM_WOD_ADR_B74	29.6799999999999997
2021-10-01	LM_ELE_ADR_B06	407569
2021-10-01	LM_ELE_ADR046	0
2021-10-01	LM_ELE_ADR010	105187.399999999994
2021-10-01	LM_ELE_ADR043	2504.09999999999991
2021-10-01	LM_ELE_ADR_B11	28783.630000000001
2021-10-01	LM_WOD_ADR242	41.4799999999999969
2021-10-01	LM_ELE_ADR124	72250.1600000000035
2021-10-01	LM_ELE_ADR112	683710.060000000056
2021-10-01	LM_WOD_ADR_B75	141.490000000000009
2021-10-01	LM_ELE_ADR091	9985.06999999999971
2021-10-01	LM_WOD_ADR_B80	101.040000000000006
2021-10-01	LM_WOD_ADR_B81	38.9399999999999977
2021-10-01	LM_ELE_ADR_B04	269433.630000000005
2021-10-01	LM_ELE_ADR_B05	230654.339999999997
2021-10-01	LM_ELE_ADR_B09	266403.130000000005
2021-10-01	LM_ELE_ADR_B01	0
2021-10-01	LM_ELE_ADR_B10	26616.4500000000007
2021-10-01	LM_ELE_ADR_B02	0
2021-10-01	LM_LC_ADR_B18	14.7100000000000009
2021-10-01	LM_LC_ADR_B20	58.3699999999999974
2021-10-01	LM_LC_ADR_B22	30.8999999999999986
2021-10-01	LM_LC_ADR_B24	10.0199999999999996
2021-10-01	LM_LC_ADR_B31	352.600000000000023
2021-10-01	LM_LC_ADR_B41	387
2021-10-01	LM_LC_ADR_B43	6.29999999999999982
2021-10-01	LM_LH_ADR_B23	62.5
2021-10-01	LM_LH_ADR_B25	48
2021-10-01	LM_LH_ADR_B27	108.799999999999997
2021-10-01	LM_LH_ADR_B35	0
2021-10-01	LM_LH_ADR_B36	0
2021-10-01	LM_LH_ADR_B38	71.2999999999999972
2021-10-01	LM_LH_ADR_B44	4.09999999999999964
2021-10-01	LM_WOD_ADR_B76	1736.56999999999994
2021-10-01	LM_WOD_ADR_B77	8.8100000000000005
2021-10-01	LM_LC_ADR_B16	32.4500000000000028
2021-10-01	LM_LH_ADR_B17	46
2021-10-01	LM_WOD_ADR_B79	360.110000000000014
2021-10-01	LM_ELE_ADR_B12	15296.3199999999997
2021-10-01	LM_ELE_ADR_B13	14309.25
2021-10-01	LM_LC_ADR_B46	45.0700000000000003
2021-10-01	LM_LC_ADR193	0
2021-10-01	LM_ELE_ADR125	4493.1899999999996
2021-10-01	LM_ELE_ADR069	259359
2021-10-01	LM_ELE_ADR075	88
2022-02-01	LM_LC_ADR179	84.0300000000000011
2022-02-01	LM_ELE_ADR021	251549.01999999999
2022-02-01	LM_ELE_ADR078	51470
2022-02-01	LM_ELE_ADR066	0
2022-02-01	LM_LH_ADR199	143.599999999999994
2022-02-01	LM_WOD_ADR249_Solution Space	97.4000000000000057
2022-02-01	LM_LC_ADR151	29352
2022-02-01	LM_LC_ADR153	10127.9989999999998
2022-02-01	LM_LC_ADR154	2484.30000000000018
2022-02-01	LM_LC_ADR157	1048.09999999999991
2022-02-01	LM_LC_ADR158	339.699999999999989
2022-02-01	LM_LC_ADR162	756.600000000000023
2022-02-01	LM_LC_ADR168	104.700000000000003
2022-02-01	LM_LC_ADR173	96.8199999999999932
2022-02-01	LM_LC_ADR174	185.110000000000014
2022-02-01	LM_LC_ADR175	0
2022-02-01	LM_LC_ADR178	123.980000000000004
2022-02-01	LM_LC_ADR184	42.2100000000000009
2022-02-01	LM_LC_ADR186	19.2300000000000004
2022-02-01	LM_LC_ADR187	32.6899999999999977
2022-02-01	LM_LC_ADR209	93.9099999999999966
2022-02-01	LM_LC_ADR32	0
2022-02-01	LM_LC_ADR82	17.7300000000000004
2022-02-01	LM_LH_ADR189	59.8900000000000006
2022-02-01	LM_LH_ADR195	421.199999999999989
2022-02-01	LM_LH_ADR196	9
2022-02-01	LM_LH_ADR198	1202.70000000000005
2022-02-01	LM_LH_ADR200	46.2000000000000028
2022-02-01	LM_LH_ADR203	219.199999999999989
2022-02-01	LM_LH_ADR204	97
2022-02-01	LM_LH_ADR211	34
2022-02-01	LM_LH_ADR212	172.599999999999994
2022-02-01	LM_LH_ADR216	34.1199999999999974
2022-02-01	LM_LH_ADR218	413.199999999999989
2022-02-01	LM_LH_ADR221	320
2022-02-01	LM_LH_ADR227	41.2000000000000028
2022-02-01	LM_LH_ADR229	84.8900000000000006
2022-02-01	LM_LH_ADR231	0
2022-02-01	LM_LH_ADR234	0
2022-02-01	LM_LH_ADR235	86.5
2022-02-01	LM_LH_ADR33	0
2022-02-01	LM_ELE_ADR008	97831.6499999999942
2022-02-01	LM_ELE_ADR012	87149.570000000007
2022-02-01	LM_ELE_ADR017	12257.1100000000006
2022-02-01	LM_ELE_ADR024	121066.399999999994
2022-02-01	LM_ELE_ADR027	35402.4599999999991
2022-02-01	LM_LC_ADR163	29.0899999999999999
2022-02-01	LM_LC_ADR164	0.0200000000000000004
2022-02-01	LM_ELE_ADR029	12371.3400000000001
2022-02-01	LM_ELE_ADR031	181418.470000000001
2022-02-01	LM_ELE_ADR038	334335
2022-02-01	LM_ELE_ADR041	64496.9100000000035
2022-02-01	LM_ELE_ADR045	5726.02999999999975
2022-02-01	LM_ELE_ADR047	5176.02000000000044
2022-02-01	LM_ELE_ADR049	14222.8099999999995
2022-02-01	LM_ELE_ADR052	10706.1100000000006
2022-02-01	LM_ELE_ADR054	29812.869999999999
2022-02-01	LM_ELE_ADR057	5904.71000000000004
2022-02-01	LM_ELE_ADR060	0
2022-02-01	LM_ELE_ADR061	0
2022-02-01	LM_ELE_ADR062	20565
2022-02-01	LM_ELE_ADR067	263
2022-02-01	LM_ELE_ADR068	4985
2022-02-01	LM_ELE_ADR070	88
2022-02-01	LM_ELE_ADR071	75233
2022-02-01	LM_ELE_ADR073	88
2022-02-01	LM_ELE_ADR077	1063
2022-02-01	LM_ELE_ADR084	53847.2699999999968
2022-02-01	LM_ELE_ADR086	13821.6000000000004
2022-02-01	LM_ELE_ADR088	36948.6999999999971
2022-02-01	LM_ELE_ADR094	1462.51999999999998
2022-02-01	LM_ELE_ADR095	97442.0399999999936
2022-02-01	LM_ELE_ADR098	3400.38000000000011
2022-02-01	LM_ELE_ADR099	76247.5500000000029
2022-02-01	LM_ELE_ADR101	7398.10000000000036
2022-02-01	LM_ELE_ADR111	362.569999999999993
2022-02-01	LM_ELE_ADR116	15037.6499999999996
2022-02-01	LM_ELE_ADR118	20349.7400000000016
2022-02-01	LM_ELE_ADR119	72391.6300000000047
2022-02-01	LM_ELE_ADR120	81033.6900000000023
2022-02-01	LM_WOD_ADR129	112.400000000000006
2022-02-01	LM_WOD_ADR140	122.180000000000007
2022-02-01	LM_WOD_ADR147	58.490000000000002
2022-02-01	LM_ELE_ADR_B03	124573.649999999994
2022-02-01	LM_ELE_ADR_B07	98367.929999999993
2022-02-01	LM_ELE_ADR_B08	146734.160000000003
2022-02-01	LM_LC_ADR_B26	145.930000000000007
2022-02-01	LM_LC_ADR_B30	411.399999999999977
2022-02-01	LM_LC_ADR_B32	913.5
2022-02-01	LM_LC_ADR_B33	815.600000000000023
2022-02-01	LM_LH_ADR_B19	100.400000000000006
2022-02-01	LM_LH_ADR_B21	194.800000000000011
2022-02-01	LM_LH_ADR_B34	0
2022-02-01	LM_LH_ADR_B37	0.400000000000000022
2022-02-01	LM_LH_ADR_B39	95.9000000000000057
2022-02-01	LM_LH_ADR_B40	161.099999999999994
2022-02-01	LM_LH_ADR_B42	0
2022-02-01	LM_WOD_ADR_B78	185.419999999999987
2022-02-01	LM_LC_ADR102	49.7999999999999972
2022-02-01	LM_LC_ADR103	54.8999999999999986
2022-02-01	LM_LC_ADR104	72.3799999999999955
2022-02-01	LM_LC_ADR152	4794.19999999999982
2022-02-01	LM_LC_ADR149	0.910000000000000031
2022-02-01	LM_LC_ADR156	3338.09999999999991
2022-02-01	LM_LC_ADR166	35.9699999999999989
2022-02-01	LM_LC_ADR180	140.150000000000006
2022-02-01	LM_LC_ADR181	0.100000000000000006
2022-02-01	LM_LC_ADR182	86.4200000000000017
2022-02-01	LM_LC_ADR183	1.41999999999999993
2022-02-01	LM_LC_ADR185	18.9400000000000013
2022-02-01	LM_LC_ADR161	1382.20000000000005
2022-02-01	LM_LC_ADR224	154.870000000000005
2022-02-01	LM_LC_ADR89	34.4799999999999969
2022-02-01	LM_LC_ADR93	33.990000000000002
2022-02-01	LM_LH_ADR145	10.0700000000000003
2022-02-01	LM_LH_ADR188	32.1799999999999997
2022-02-01	LM_LH_ADR190	7.88999999999999968
2022-02-01	LM_LH_ADR191	18.8000000000000007
2022-02-01	LM_LH_ADR207	404
2022-02-01	LM_LH_ADR197	1255
2022-02-01	LM_LH_ADR215	0
2022-02-01	LM_LH_ADR219	0.0299999999999999989
2022-02-01	LM_LH_ADR220	112.200000000000003
2022-02-01	LM_LH_ADR226	74.2600000000000051
2022-02-01	LM_LH_ADR217	500.600000000000023
2022-02-01	LM_LH_ADR228	28.8000000000000007
2022-02-01	LM_LH_ADR232	56.0799999999999983
2022-02-01	LM_LH_ADR233	45.1000000000000014
2022-02-01	LM_LH_ADR230	1.69999999999999996
2022-02-01	LM_ELE_ADR114	27.8099999999999987
2022-02-01	LM_ELE_ADR117	22575.1899999999987
2022-02-01	LM_WOD_ADR132	295.060000000000002
2022-02-01	LM_WOD_ADR134	18.6799999999999997
2022-02-01	LM_WOD_ADR135	0
2021-11-01	LM_LC_ADR170	49.5399999999999991
2021-11-01	LM_LC_ADR172	94.9399999999999977
2021-11-01	LM_LC_ADR179	71.3900000000000006
2021-11-01	LM_ELE_ADR021	213901.73000000001
2021-11-01	LM_ELE_ADR078	44522
2021-11-01	LM_ELE_ADR066	0
2021-11-01	LM_ELE_ADR080	158258.48000000001
2021-11-01	LM_LH_ADR199	138.599999999999994
2022-02-01	LM_ELE_ADR080	166806.130000000005
2022-02-01	LM_WOD_MAIN_W	0
2022-02-01	LM_LC_ADR155	6635.39999999999964
2022-02-01	LM_LH_ADR122	14.5999999999999996
2022-02-01	LM_LH_ADR222	0
2022-02-01	LM_ELE_ADR065	0
2022-02-01	LM_ELE_ADR100	16913.3499999999985
2022-02-01	LM_WOD_ADR248_Solution Space	42.8699999999999974
2022-02-01	LM_LC_ADR165	45.2700000000000031
2022-02-01	LM_LH_ADR192	0
2022-02-01	LM_LH_ADR223	176.599999999999994
2022-02-01	LM_LH_ADR225	70.7999999999999972
2022-02-01	LM_WOD_ADR136	67.9500000000000028
2022-02-01	LM_WOD_ADR139	1373.72000000000003
2022-02-01	LM_WOD_ADR141	17
2022-02-01	LM_WOD_ADR142	36
2022-02-01	LM_WOD_ADR143	557.389999999999986
2022-02-01	LM_WOD_ADR146	29509.9000000000015
2022-02-01	LM_WOD_ADR148	0.0299999999999999989
2022-02-01	LM_WOD_ADR237	923.480000000000018
2022-02-01	LM_WOD_ADR238	2339.71000000000004
2022-02-01	LM_WOD_ADR239	32.5799999999999983
2022-02-01	LM_WOD_ADR240	123.180000000000007
2022-02-01	LM_WOD_ADR241	75.019999999999996
2022-02-01	LM_ELE_ADR121	175365.190000000002
2022-02-01	LM_ELE_ADR128	0
2022-02-01	LM_WOD_ADR247_Solution Space	529.710000000000036
2022-02-01	LM_WOD_ADR250_Solution Space	189.300000000000011
2022-02-01	LM_WOD_ADR30	0
2022-02-01	LM_ELE_ADR001	66007.0500000000029
2022-02-01	LM_ELE_ADR002	86535.9400000000023
2022-02-01	LM_ELE_ADR003	113987.089999999997
2022-02-01	LM_ELE_ADR006	74879.5899999999965
2022-02-01	LM_ELE_ADR009	171144.140000000014
2022-02-01	LM_ELE_ADR011	159997.029999999999
2022-02-01	LM_ELE_ADR013	210673.160000000003
2022-02-01	LM_ELE_ADR014	13952.7600000000002
2022-02-01	LM_ELE_ADR015	126920.100000000006
2022-02-01	LM_ELE_ADR016	923599.810000000056
2022-02-01	LM_ELE_ADR018	12752.7299999999996
2022-02-01	LM_ELE_ADR020	132678.549999999988
2022-02-01	LM_ELE_ADR022	142617.029999999999
2022-02-01	LM_ELE_ADR023	31583.8100000000013
2022-02-01	LM_ELE_ADR025	472703.309999999998
2022-02-01	LM_ELE_ADR028	18901.9000000000015
2022-02-01	LM_ELE_ADR034	26667.9399999999987
2022-02-01	LM_ELE_ADR036	87695.7899999999936
2022-02-01	LM_ELE_ADR040	35362.1100000000006
2022-02-01	LM_ELE_ADR042	3386.53999999999996
2022-02-01	LM_ELE_ADR044	6584.32999999999993
2022-02-01	LM_ELE_ADR048	6929.77000000000044
2022-02-01	LM_ELE_ADR051	6629.05000000000018
2022-02-01	LM_ELE_ADR053	20754.2200000000012
2022-02-01	LM_ELE_ADR055	5466.68000000000029
2022-02-01	LM_ELE_ADR056	21274.119999999999
2022-02-01	LM_ELE_ADR063	190
2022-02-01	LM_ELE_ADR064	0
2022-02-01	LM_ELE_ADR058	79819.2700000000041
2022-02-01	LM_ELE_ADR072	25104
2022-02-01	LM_ELE_ADR074	75233
2022-02-01	LM_ELE_ADR076	0
2022-02-01	LM_ELE_ADR085	51580.8399999999965
2022-02-01	LM_ELE_ADR090	36665.8899999999994
2022-02-01	LM_ELE_ADR107	80298.6999999999971
2022-02-01	LM_ELE_ADR108	6415.71000000000004
2022-02-01	LM_ELE_ADR109	2014.96000000000004
2022-02-01	LM_ELE_ADR110	410.990000000000009
2022-02-01	LM_ELE_ADR113	52000.5500000000029
2022-02-01	LM_ELE_ADR087	86546.5200000000041
2022-02-01	LM_LC_ADR_B45	195.430000000000007
2022-02-01	LM_LH_ADR_B46	49.3500000000000014
2022-02-01	LM_LH_ADR_B47	116.900000000000006
2022-02-01	LM_WOD_ADR_B74	33.7199999999999989
2022-02-01	LM_ELE_ADR_B06	443934.75
2022-02-01	LM_ELE_ADR046	0
2022-02-01	LM_ELE_ADR043	2712.82000000000016
2022-02-01	LM_ELE_ADR_B11	31498.8600000000006
2022-02-01	LM_WOD_ADR242	42.3599999999999994
2022-02-01	LM_ELE_ADR124	94003.3000000000029
2022-02-01	LM_ELE_ADR112	712140.310000000056
2022-02-01	LM_WOD_ADR_B75	178.469999999999999
2022-02-01	LM_ELE_ADR091	11382.4899999999998
2022-02-01	LM_WOD_ADR_B80	115.739999999999995
2022-02-01	LM_WOD_ADR_B81	41.9699999999999989
2022-02-01	LM_ELE_ADR_B04	277274.690000000002
2022-02-01	LM_ELE_ADR_B05	241527.450000000012
2022-02-01	LM_ELE_ADR_B09	287958.409999999974
2022-02-01	LM_ELE_ADR_B01	0
2022-02-01	LM_ELE_ADR_B10	29013.7099999999991
2022-02-01	LM_LC_ADR_B18	18
2022-02-01	LM_LC_ADR_B20	69.0900000000000034
2022-02-01	LM_LC_ADR_B22	50.7299999999999969
2022-02-01	LM_LC_ADR_B24	10.0199999999999996
2022-02-01	LM_LC_ADR_B31	415.399999999999977
2022-02-01	LM_LC_ADR_B41	474
2022-02-01	LM_LC_ADR_B43	7.79999999999999982
2022-02-01	LM_LH_ADR_B23	64.2999999999999972
2022-02-01	LM_LH_ADR_B25	57.1000000000000014
2022-02-01	LM_LH_ADR_B27	134.900000000000006
2022-02-01	LM_LH_ADR_B35	0
2022-02-01	LM_LH_ADR_B36	0
2022-02-01	LM_LH_ADR_B38	72
2022-02-01	LM_LH_ADR_B44	4.5
2022-02-01	LM_WOD_ADR_B77	8.96000000000000085
2022-02-01	LM_LC_ADR_B16	38.8200000000000003
2022-02-01	LM_LH_ADR_B17	49.7000000000000028
2022-02-01	LM_WOD_ADR_B79	360.110000000000014
2022-02-01	LM_ELE_ADR_B12	17378.8199999999997
2022-02-01	LM_ELE_ADR_B13	15053.1900000000005
2022-02-01	LM_LC_ADR_B46	50.5300000000000011
2022-02-01	LM_LC_ADR193	0
2022-02-01	LM_ELE_ADR125	4839.43000000000029
2022-02-01	LM_ELE_ADR069	284569
2022-02-01	LM_ELE_ADR075	10457
2022-02-01	LM_LC_ADR159	4420
2022-02-01	LM_LC_ADR160	7870
2022-02-01	LM_LH_ADR167	1350
2021-11-01	LM_ELE_ADR115	22939.2000000000007
2021-11-01	LM_WOD_ADR249_Solution Space	85.7399999999999949
2021-11-01	LM_WOD_MAIN_W	0
2021-11-01	LM_LC_ADR123	416.199999999999989
2021-11-01	LM_LC_ADR151	26574
2021-11-01	LM_LC_ADR153	9363
2021-11-01	LM_LC_ADR154	2207.40000000000009
2021-11-01	LM_LC_ADR155	5813.39999999999964
2021-11-01	LM_LC_ADR157	940.299999999999955
2021-11-01	LM_LC_ADR158	291.600000000000023
2021-11-01	LM_LC_ADR162	668.5
2021-11-01	LM_LC_ADR168	76.4000000000000057
2021-11-01	LM_LC_ADR173	83.2000000000000028
2021-11-01	LM_LC_ADR174	159.409999999999997
2021-11-01	LM_LC_ADR175	0
2021-11-01	LM_LC_ADR176	84.7000000000000028
2021-11-01	LM_LC_ADR178	103.230000000000004
2021-11-01	LM_LC_ADR184	39.7199999999999989
2021-11-01	LM_LC_ADR186	15.5399999999999991
2021-11-01	LM_LC_ADR187	29.0399999999999991
2021-11-01	LM_LC_ADR209	85.3400000000000034
2021-11-01	LM_LC_ADR32	0
2021-11-01	LM_LC_ADR82	3.75999999999999979
2021-11-01	LM_LH_ADR122	14.0999999999999996
2021-11-01	LM_LH_ADR189	56.4500000000000028
2021-11-01	LM_LH_ADR195	408.600000000000023
2021-11-01	LM_LH_ADR196	9
2021-11-01	LM_LH_ADR198	1147
2021-11-01	LM_LH_ADR200	44.8999999999999986
2021-11-01	LM_LH_ADR203	215.099999999999994
2021-11-01	LM_LH_ADR204	93.7999999999999972
2021-11-01	LM_LH_ADR208	271.800000000000011
2021-11-01	LM_LH_ADR211	28.1999999999999993
2021-11-01	LM_LH_ADR212	144.699999999999989
2021-11-01	LM_LH_ADR216	31.7899999999999991
2021-11-01	LM_LH_ADR218	384.5
2021-11-01	LM_LH_ADR221	296.5
2021-11-01	LM_LH_ADR222	0
2021-11-01	LM_LH_ADR227	41.2000000000000028
2021-11-01	LM_LH_ADR229	84.8199999999999932
2021-11-01	LM_LH_ADR231	0
2021-11-01	LM_LH_ADR234	0
2021-11-01	LM_LH_ADR235	86.2000000000000028
2021-11-01	LM_LH_ADR33	0
2021-11-01	LM_ELE_ADR008	84389.8699999999953
2021-11-01	LM_ELE_ADR012	65753.7299999999959
2021-11-01	LM_ELE_ADR017	11461.1100000000006
2021-11-01	LM_ELE_ADR019	2439.5300000000002
2021-11-01	LM_ELE_ADR024	114290.449999999997
2021-11-01	LM_ELE_ADR027	34534.4400000000023
2021-11-01	LM_LC_ADR163	26.5799999999999983
2021-11-01	LM_LC_ADR164	0.0200000000000000004
2021-11-01	LM_LH_ADR201	85.0999999999999943
2021-11-01	LM_ELE_ADR029	10848.2900000000009
2021-11-01	LM_ELE_ADR031	155303.339999999997
2021-11-01	LM_ELE_ADR038	290953.880000000005
2021-11-01	LM_ELE_ADR041	59927.1100000000006
2021-11-01	LM_ELE_ADR045	5418.25
2021-11-01	LM_ELE_ADR047	4885.86999999999989
2021-11-01	LM_ELE_ADR049	13586.1399999999994
2021-11-01	LM_ELE_ADR052	10158.3199999999997
2021-11-01	LM_ELE_ADR054	28384.8100000000013
2021-11-01	LM_ELE_ADR057	5622.19999999999982
2021-11-01	LM_ELE_ADR059	21204.0600000000013
2021-11-01	LM_ELE_ADR060	0
2021-11-01	LM_ELE_ADR061	0
2021-11-01	LM_ELE_ADR062	18489
2021-11-01	LM_ELE_ADR065	0
2021-11-01	LM_ELE_ADR067	159
2021-11-01	LM_ELE_ADR068	937
2021-11-01	LM_ELE_ADR070	88
2021-11-01	LM_ELE_ADR071	70367
2021-11-01	LM_ELE_ADR073	88
2021-11-01	LM_ELE_ADR077	1063
2021-11-01	LM_ELE_ADR084	51441.4599999999991
2021-11-01	LM_ELE_ADR086	12364.1399999999994
2021-11-01	LM_ELE_ADR088	34059.2699999999968
2021-11-01	LM_ELE_ADR094	1439.15000000000009
2021-11-01	LM_ELE_ADR095	91050.1300000000047
2021-11-01	LM_ELE_ADR097	26106.75
2021-11-01	LM_ELE_ADR098	3118.36000000000013
2021-11-01	LM_ELE_ADR099	66215.5599999999977
2021-11-01	LM_ELE_ADR100	14952.3299999999999
2021-11-01	LM_ELE_ADR101	6798.02000000000044
2021-11-01	LM_ELE_ADR111	362.569999999999993
2021-11-01	LM_ELE_ADR116	13736.2199999999993
2021-11-01	LM_ELE_ADR118	19120.2799999999988
2021-11-01	LM_ELE_ADR119	68396.6300000000047
2021-11-01	LM_ELE_ADR120	72856.3800000000047
2021-11-01	LM_WOD_ADR129	102.700000000000003
2021-11-01	LM_WOD_ADR140	121.400000000000006
2021-11-01	LM_WOD_ADR147	55.1300000000000026
2021-11-01	LM_WOD_ADR246_Solution Space	475.319999999999993
2021-11-01	LM_WOD_ADR248_Solution Space	36.8299999999999983
2021-11-01	LM_ELE_ADR_B03	118130.75
2021-11-01	LM_ELE_ADR_B07	92810.2599999999948
2021-11-01	LM_ELE_ADR_B08	138671.160000000003
2021-11-01	LM_LC_ADR_B26	108.280000000000001
2021-11-01	LM_LC_ADR_B30	356
2021-11-01	LM_LC_ADR_B32	784.200000000000045
2021-11-01	LM_LC_ADR_B33	675.700000000000045
2021-11-01	LM_LH_ADR_B19	81.0999999999999943
2021-11-01	LM_LH_ADR_B21	171.900000000000006
2021-11-01	LM_LH_ADR_B34	0
2021-11-01	LM_LH_ADR_B37	0.400000000000000022
2021-11-01	LM_LH_ADR_B39	95.4000000000000057
2021-11-01	LM_LH_ADR_B40	159.199999999999989
2021-11-01	LM_LH_ADR_B42	0
2021-11-01	LM_WOD_ADR_B78	179.52000000000001
2021-11-01	LM_LC_ADR102	43.490000000000002
2021-11-01	LM_LC_ADR103	47.7100000000000009
2021-11-01	LM_LC_ADR104	59.6599999999999966
2021-11-01	LM_LC_ADR152	4320.80000000000018
2021-11-01	LM_LC_ADR149	0.910000000000000031
2021-11-01	LM_LC_ADR156	2861.5
2021-11-01	LM_LC_ADR171	245.030000000000001
2021-11-01	LM_LC_ADR165	38.6599999999999966
2021-11-01	LM_LC_ADR166	31
2021-11-01	LM_LC_ADR180	127
2021-11-01	LM_LC_ADR181	0.100000000000000006
2021-11-01	LM_LC_ADR182	74.3400000000000034
2021-11-01	LM_LC_ADR183	1.41999999999999993
2021-11-01	LM_LC_ADR185	16.129999999999999
2021-11-01	LM_LC_ADR161	1244.20000000000005
2021-11-01	LM_LC_ADR224	132.550000000000011
2021-11-01	LM_LC_ADR89	28.4100000000000001
2021-11-01	LM_LC_ADR93	27.9100000000000001
2021-11-01	LM_LH_ADR145	9.80000000000000071
2021-11-01	LM_LH_ADR188	32.1799999999999997
2021-11-01	LM_LH_ADR190	7.79000000000000004
2021-11-01	LM_LH_ADR191	18.8000000000000007
2021-11-01	LM_LH_ADR192	0
2021-11-01	LM_LH_ADR194	786.5
2021-11-01	LM_LH_ADR207	392.800000000000011
2021-11-01	LM_LH_ADR197	1232.70000000000005
2021-11-01	LM_LH_ADR215	0
2021-11-01	LM_LH_ADR219	0.0299999999999999989
2021-11-01	LM_LH_ADR220	71.980000000000004
2021-11-01	LM_LH_ADR223	176.599999999999994
2021-11-01	LM_LH_ADR225	70.4000000000000057
2021-11-01	LM_LH_ADR226	54.0399999999999991
2021-11-01	LM_LH_ADR217	486.199999999999989
2021-11-01	LM_LH_ADR228	27.8000000000000007
2021-11-01	LM_LH_ADR232	52.1000000000000014
2021-11-01	LM_LH_ADR233	45.1000000000000014
2021-11-01	LM_LH_ADR230	1.60000000000000009
2021-11-01	LM_ELE_ADR114	241310.660000000003
2021-11-01	LM_ELE_ADR117	22082.2999999999993
2021-11-01	LM_WOD_ADR132	284.899999999999977
2021-11-01	LM_WOD_ADR133	334.730000000000018
2021-11-01	LM_WOD_ADR134	18.3200000000000003
2021-11-01	LM_WOD_ADR135	0
2021-11-01	LM_WOD_ADR136	65.3700000000000045
2021-11-01	LM_WOD_ADR139	1270.98000000000002
2021-11-01	LM_WOD_ADR141	17
2021-11-01	LM_WOD_ADR142	36
2021-11-01	LM_WOD_ADR143	557.389999999999986
2021-11-01	LM_WOD_ADR146	28035.4000000000015
2021-11-01	LM_WOD_ADR148	0.0500000000000000028
2021-11-01	LM_WOD_ADR150	36.7800000000000011
2021-11-01	LM_WOD_ADR237	922.809999999999945
2021-11-01	LM_WOD_ADR238	2212.76000000000022
2021-11-01	LM_WOD_ADR239	29.3299999999999983
2021-11-01	LM_WOD_ADR240	110.019999999999996
2021-11-01	LM_WOD_ADR241	995.57000000000005
2021-11-01	LM_ELE_ADR121	85.4399999999999977
2021-11-01	LM_ELE_ADR128	0
2021-11-01	LM_WOD_ADR247_Solution Space	467.930000000000007
2021-11-01	LM_WOD_ADR250_Solution Space	168.580000000000013
2021-11-01	LM_WOD_ADR30	0
2021-11-01	LM_ELE_ADR001	62406.4599999999991
2021-11-01	LM_ELE_ADR002	82267.1300000000047
2021-11-01	LM_ELE_ADR003	100545.699999999997
2021-11-01	LM_ELE_ADR006	72619.5099999999948
2021-11-01	LM_ELE_ADR007	118932.880000000005
2021-11-01	LM_ELE_ADR009	159571.609999999986
2021-11-01	LM_ELE_ADR011	156200.339999999997
2021-11-01	LM_ELE_ADR013	197507.049999999988
2021-11-01	LM_ELE_ADR014	12937.4099999999999
2021-11-01	LM_ELE_ADR015	118610.770000000004
2021-11-01	LM_ELE_ADR016	892473.130000000005
2021-11-01	LM_ELE_ADR018	12046.3999999999996
2021-11-01	LM_ELE_ADR020	124256.970000000001
2021-11-01	LM_ELE_ADR022	124642.660000000003
2021-11-01	LM_ELE_ADR023	28479.3199999999997
2021-11-01	LM_ELE_ADR025	381943.75
2021-11-01	LM_ELE_ADR028	17755.8100000000013
2021-11-01	LM_ELE_ADR034	23374.369999999999
2021-11-01	LM_ELE_ADR036	81774.6300000000047
2021-11-01	LM_ELE_ADR039	301225.469999999972
2021-11-01	LM_ELE_ADR040	29531
2021-11-01	LM_ELE_ADR042	3207.42000000000007
2021-11-01	LM_ELE_ADR044	6292.3100000000004
2021-11-01	LM_ELE_ADR048	6612.93000000000029
2021-11-01	LM_ELE_ADR051	6299.90999999999985
2021-11-01	LM_ELE_ADR053	17590.9599999999991
2021-11-01	LM_ELE_ADR055	5191.88000000000011
2021-11-01	LM_ELE_ADR056	20173.2700000000004
2021-11-01	LM_ELE_ADR063	189
2021-11-01	LM_ELE_ADR064	0
2021-11-01	LM_ELE_ADR058	75657.1600000000035
2021-11-01	LM_ELE_ADR072	23013
2021-11-01	LM_ELE_ADR074	70367
2021-11-01	LM_ELE_ADR076	0
2021-11-01	LM_ELE_ADR081	42130.1100000000006
2021-11-01	LM_ELE_ADR085	44662.0599999999977
2021-11-01	LM_ELE_ADR090	34610.9700000000012
2021-11-01	LM_ELE_ADR107	72506.3099999999977
2021-11-01	LM_ELE_ADR108	6208.56999999999971
2021-11-01	LM_ELE_ADR109	2013.65000000000009
2021-11-01	LM_ELE_ADR110	406.220000000000027
2021-11-01	LM_ELE_ADR113	48651.1399999999994
2021-11-01	LM_ELE_ADR087	82530.2400000000052
2021-11-01	LM_LC_ADR_B45	151.409999999999997
2021-11-01	LM_LH_ADR_B46	49.3500000000000014
2021-11-01	LM_LH_ADR_B47	116.299999999999997
2021-11-01	LM_WOD_ADR_B74	30.8399999999999999
2021-11-01	LM_ELE_ADR_B06	416481.909999999974
2021-11-01	LM_ELE_ADR046	0
2021-11-01	LM_ELE_ADR010	108857.470000000001
2021-11-01	LM_ELE_ADR043	2557.2199999999998
2021-11-01	LM_ELE_ADR_B11	29399.3300000000017
2021-11-01	LM_WOD_ADR242	41.6700000000000017
2021-11-01	LM_ELE_ADR124	77755.8800000000047
2021-11-01	LM_ELE_ADR112	693226.560000000056
2021-11-01	LM_WOD_ADR_B75	153.169999999999987
2021-11-01	LM_ELE_ADR091	10344.7900000000009
2021-11-01	LM_WOD_ADR_B80	104.819999999999993
2021-11-01	LM_WOD_ADR_B81	39.8400000000000034
2021-11-01	LM_ELE_ADR_B04	272130.159999999974
2021-11-01	LM_ELE_ADR_B05	235930.5
2021-11-01	LM_ELE_ADR_B09	272122.809999999998
2021-11-01	LM_ELE_ADR_B01	0
2021-11-01	LM_ELE_ADR_B10	27224.630000000001
2021-11-01	LM_ELE_ADR_B02	0
2021-11-01	LM_LC_ADR_B18	15.2200000000000006
2021-11-01	LM_LC_ADR_B20	58.9799999999999969
2021-11-01	LM_LC_ADR_B22	31.3099999999999987
2021-11-01	LM_LC_ADR_B24	10.0199999999999996
2021-11-01	LM_LC_ADR_B31	357.100000000000023
2021-11-01	LM_LC_ADR_B41	396.199999999999989
2021-11-01	LM_LC_ADR_B43	6.70000000000000018
2021-11-01	LM_LH_ADR_B23	64.0999999999999943
2021-11-01	LM_LH_ADR_B25	49.6000000000000014
2021-11-01	LM_LH_ADR_B27	117
2021-11-01	LM_LH_ADR_B35	0
2021-11-01	LM_LH_ADR_B36	0
2021-11-01	LM_LH_ADR_B38	71.7000000000000028
2021-11-01	LM_LH_ADR_B44	4.29999999999999982
2021-11-01	LM_WOD_ADR_B76	1736.78999999999996
2021-11-01	LM_WOD_ADR_B77	8.96000000000000085
2021-11-01	LM_LC_ADR_B16	32.5
2021-11-01	LM_LH_ADR_B17	47.3999999999999986
2021-11-01	LM_WOD_ADR_B79	360.110000000000014
2021-11-01	LM_ELE_ADR_B12	15764.4699999999993
2021-11-01	LM_ELE_ADR_B13	14656.9899999999998
2021-11-01	LM_LC_ADR_B46	45.0900000000000034
2021-11-01	LM_LC_ADR193	0
2021-11-01	LM_ELE_ADR125	4633.61999999999989
2021-11-01	LM_ELE_ADR069	264405
2021-11-01	LM_ELE_ADR075	88
2021-12-01	LM_LC_ADR170	50.009999999999998
2021-12-01	LM_LC_ADR172	98.2800000000000011
2021-12-01	LM_LC_ADR179	74.8599999999999994
2021-12-01	LM_ELE_ADR021	221886.380000000005
2021-12-01	LM_ELE_ADR078	46879
2021-12-01	LM_ELE_ADR066	0
2021-12-01	LM_ELE_ADR080	161290.130000000005
2021-12-01	LM_LH_ADR199	139.599999999999994
2021-12-01	LM_ELE_ADR115	23010.2599999999984
2021-12-01	LM_WOD_ADR249_Solution Space	89.8799999999999955
2021-12-01	LM_WOD_MAIN_W	0
2021-12-01	LM_LC_ADR123	445
2021-12-01	LM_LC_ADR151	27145.9979999999996
2021-12-01	LM_LC_ADR153	9492
2021-12-01	LM_LC_ADR154	2283.5
2021-12-01	LM_LC_ADR155	6001.19999999999982
2021-12-01	LM_LC_ADR157	963.799999999999955
2021-12-01	LM_LC_ADR158	301.600000000000023
2021-12-01	LM_LC_ADR162	687.700000000000045
2021-12-01	LM_LC_ADR168	84.2999999999999972
2021-12-01	LM_LC_ADR173	86.0100000000000051
2021-12-01	LM_LC_ADR174	168.360000000000014
2021-12-01	LM_LC_ADR175	0
2021-12-01	LM_LC_ADR176	84.7000000000000028
2021-12-01	LM_LC_ADR178	108.980000000000004
2021-12-01	LM_LC_ADR184	40.5600000000000023
2021-12-01	LM_LC_ADR186	16.9299999999999997
2021-12-01	LM_LC_ADR187	29.0399999999999991
2021-12-01	LM_LC_ADR209	86.5499999999999972
2021-12-01	LM_LC_ADR32	0
2021-12-01	LM_LC_ADR82	7.62999999999999989
2021-12-01	LM_LH_ADR122	14.5
2021-12-01	LM_LH_ADR189	57.1400000000000006
2021-12-01	LM_LH_ADR195	408.699999999999989
2021-12-01	LM_LH_ADR196	9
2021-12-01	LM_LH_ADR198	1162.70000000000005
2021-12-01	LM_LH_ADR200	45.2999999999999972
2021-12-01	LM_LH_ADR203	217
2021-12-01	LM_LH_ADR204	94.7000000000000028
2021-12-01	LM_LH_ADR208	285.399999999999977
2021-12-01	LM_LH_ADR211	30.1000000000000014
2021-12-01	LM_LH_ADR212	153.800000000000011
2021-12-01	LM_LH_ADR216	32.5300000000000011
2021-12-01	LM_LH_ADR218	390.399999999999977
2021-12-01	LM_LH_ADR221	305.699999999999989
2021-12-01	LM_LH_ADR222	0
2021-12-01	LM_LH_ADR227	41.2000000000000028
2021-12-01	LM_LH_ADR229	84.8199999999999932
2021-12-01	LM_LH_ADR231	0
2021-12-01	LM_LH_ADR234	0
2021-12-01	LM_LH_ADR235	86.2000000000000028
2021-12-01	LM_LH_ADR33	0
2021-12-01	LM_ELE_ADR008	87657.1199999999953
2021-12-01	LM_ELE_ADR012	68968.7899999999936
2021-12-01	LM_ELE_ADR017	11719.3799999999992
2021-12-01	LM_ELE_ADR019	2439.5300000000002
2021-12-01	LM_ELE_ADR024	116178.589999999997
2021-12-01	LM_ELE_ADR027	34825.3700000000026
2021-12-01	LM_LC_ADR163	27.6099999999999994
2021-12-01	LM_LC_ADR164	0.0200000000000000004
2021-12-01	LM_LH_ADR201	86.9000000000000057
2021-12-01	LM_ELE_ADR029	11311.5100000000002
2021-12-01	LM_ELE_ADR031	174115.200000000012
2021-12-01	LM_ELE_ADR038	304032.090000000026
2021-12-01	LM_ELE_ADR041	61263.0400000000009
2021-12-01	LM_ELE_ADR045	5523.22999999999956
2021-12-01	LM_ELE_ADR047	4983.10000000000036
2021-12-01	LM_ELE_ADR049	13793.9099999999999
2021-12-01	LM_ELE_ADR052	10335.2999999999993
2021-12-01	LM_ELE_ADR054	28842.25
2021-12-01	LM_ELE_ADR057	5723.59000000000015
2021-12-01	LM_ELE_ADR059	21649.5900000000001
2021-12-01	LM_ELE_ADR060	0
2021-12-01	LM_ELE_ADR061	0
2021-12-01	LM_ELE_ADR062	19120
2021-12-01	LM_ELE_ADR065	0
2021-12-01	LM_ELE_ADR067	189
2021-12-01	LM_ELE_ADR068	1605
2021-12-01	LM_ELE_ADR070	88
2021-12-01	LM_ELE_ADR071	71956
2021-12-01	LM_ELE_ADR073	88
2021-12-01	LM_ELE_ADR077	1063
2021-12-01	LM_ELE_ADR084	52398.760000000002
2021-12-01	LM_ELE_ADR086	12826.3099999999995
2021-12-01	LM_ELE_ADR088	35020.3300000000017
2021-12-01	LM_ELE_ADR094	1445.02999999999997
2021-12-01	LM_ELE_ADR095	93095.7400000000052
2021-12-01	LM_ELE_ADR097	27063.0299999999988
2021-12-01	LM_ELE_ADR098	3307.73999999999978
2021-12-01	LM_ELE_ADR099	69555.8000000000029
2021-12-01	LM_ELE_ADR100	15682.8500000000004
2021-12-01	LM_ELE_ADR101	6991.28999999999996
2021-12-01	LM_ELE_ADR111	362.569999999999993
2021-12-01	LM_ELE_ADR116	14916.2000000000007
2021-12-01	LM_ELE_ADR118	19546.5299999999988
2021-12-01	LM_ELE_ADR119	69677.3800000000047
2021-12-01	LM_ELE_ADR120	73410.2599999999948
2021-12-01	LM_WOD_ADR129	106.159999999999997
2021-12-01	LM_WOD_ADR140	121.75
2021-12-01	LM_WOD_ADR147	56.2700000000000031
2021-12-01	LM_WOD_ADR246_Solution Space	489.389999999999986
2021-12-01	LM_WOD_ADR248_Solution Space	39.009999999999998
2021-12-01	LM_ELE_ADR_B03	120211.429999999993
2021-12-01	LM_ELE_ADR_B07	94537.4199999999983
2021-12-01	LM_ELE_ADR_B08	141309.809999999998
2021-12-01	LM_LC_ADR_B26	113.459999999999994
2021-12-01	LM_LC_ADR_B30	368.300000000000011
2021-12-01	LM_LC_ADR_B32	813
2021-12-01	LM_LC_ADR_B33	710.5
2021-12-01	LM_LH_ADR_B19	85.0999999999999943
2021-12-01	LM_LH_ADR_B21	177.199999999999989
2021-12-01	LM_LH_ADR_B34	0
2021-12-01	LM_LH_ADR_B37	0.400000000000000022
2021-12-01	LM_LH_ADR_B39	95.5
2021-12-01	LM_LH_ADR_B40	159.800000000000011
2021-12-01	LM_LH_ADR_B42	0
2021-12-01	LM_WOD_ADR_B78	181.860000000000014
2021-12-01	LM_LC_ADR102	45.2800000000000011
2021-12-01	LM_LC_ADR103	49.7000000000000028
2021-12-01	LM_LC_ADR104	63.2700000000000031
2021-12-01	LM_LC_ADR152	4411.5
2021-12-01	LM_LC_ADR149	0.910000000000000031
2021-12-01	LM_LC_ADR156	2964.80000000000018
2021-12-01	LM_LC_ADR171	249.199999999999989
2021-12-01	LM_LC_ADR165	40.5600000000000023
2021-12-01	LM_LC_ADR166	32.4099999999999966
2021-12-01	LM_LC_ADR180	129.569999999999993
2021-12-01	LM_LC_ADR181	0.100000000000000006
2021-12-01	LM_LC_ADR182	76.9399999999999977
2021-12-01	LM_LC_ADR183	1.41999999999999993
2021-12-01	LM_LC_ADR185	16.620000000000001
2021-12-01	LM_LC_ADR161	1277
2021-12-01	LM_LC_ADR224	138.52000000000001
2021-12-01	LM_LC_ADR89	30.0899999999999999
2021-12-01	LM_LC_ADR93	29.6099999999999994
2021-12-01	LM_LH_ADR145	9.80000000000000071
2021-12-01	LM_LH_ADR188	32.1799999999999997
2021-12-01	LM_LH_ADR190	7.79000000000000004
2021-12-01	LM_LH_ADR191	18.8000000000000007
2021-12-01	LM_LH_ADR192	0
2021-12-01	LM_LH_ADR194	795.200000000000045
2021-12-01	LM_LH_ADR207	395.199999999999989
2021-12-01	LM_LH_ADR197	1239.70000000000005
2021-12-01	LM_LH_ADR215	0
2021-12-01	LM_LH_ADR219	0.0299999999999999989
2021-12-01	LM_LH_ADR220	71.980000000000004
2021-12-01	LM_LH_ADR223	176.599999999999994
2021-12-01	LM_LH_ADR225	70.4000000000000057
2021-12-01	LM_LH_ADR226	58.1799999999999997
2021-12-01	LM_LH_ADR217	489.699999999999989
2021-12-01	LM_LH_ADR228	28.8000000000000007
2021-12-01	LM_LH_ADR232	53.25
2021-12-01	LM_LH_ADR233	45.1000000000000014
2021-12-01	LM_LH_ADR230	1.69999999999999996
2021-12-01	LM_ELE_ADR114	247634.910000000003
2021-12-01	LM_ELE_ADR117	22371.3600000000006
2021-12-01	LM_WOD_ADR132	290.100000000000023
2021-12-01	LM_WOD_ADR133	337.75
2021-12-01	LM_WOD_ADR134	18.5500000000000007
2021-12-01	LM_WOD_ADR135	0
2021-12-01	LM_WOD_ADR136	66.1599999999999966
2021-12-01	LM_WOD_ADR139	1305.8599999999999
2021-12-01	LM_WOD_ADR141	17
2021-12-01	LM_WOD_ADR142	36
2021-12-01	LM_WOD_ADR143	557.389999999999986
2021-12-01	LM_WOD_ADR146	28433.7999999999993
2021-12-01	LM_WOD_ADR148	0.0500000000000000028
2021-12-01	LM_WOD_ADR150	37.8200000000000003
2021-12-01	LM_WOD_ADR237	923.159999999999968
2021-12-01	LM_WOD_ADR238	2217.82999999999993
2021-12-01	LM_WOD_ADR239	30.4299999999999997
2021-12-01	LM_WOD_ADR240	114.890000000000001
2021-12-01	LM_WOD_ADR241	21.6600000000000001
2021-12-01	LM_ELE_ADR121	160482.23000000001
2021-12-01	LM_ELE_ADR128	0
2021-12-01	LM_WOD_ADR247_Solution Space	484.180000000000007
2021-12-01	LM_WOD_ADR250_Solution Space	176.159999999999997
2021-12-01	LM_WOD_ADR30	0
2021-12-01	LM_ELE_ADR001	62817.6500000000015
2021-12-01	LM_ELE_ADR002	83687.9199999999983
2021-12-01	LM_ELE_ADR003	104475.009999999995
2021-12-01	LM_ELE_ADR006	73468.9100000000035
2021-12-01	LM_ELE_ADR007	122108.380000000005
2021-12-01	LM_ELE_ADR009	161795.309999999998
2021-12-01	LM_ELE_ADR011	157710.079999999987
2021-12-01	LM_ELE_ADR013	200293.130000000005
2021-12-01	LM_ELE_ADR014	13264.1399999999994
2021-12-01	LM_ELE_ADR015	121732.380000000005
2021-12-01	LM_ELE_ADR016	906453
2021-12-01	LM_ELE_ADR018	12278.5200000000004
2021-12-01	LM_ELE_ADR020	126629.520000000004
2021-12-01	LM_ELE_ADR022	130675.539999999994
2021-12-01	LM_ELE_ADR023	29456.9099999999999
2021-12-01	LM_ELE_ADR025	404558.780000000028
2021-12-01	LM_ELE_ADR028	17925.3300000000017
2021-12-01	LM_ELE_ADR034	0
2021-12-01	LM_ELE_ADR036	83523.4700000000012
2021-12-01	LM_ELE_ADR039	312062.590000000026
2021-12-01	LM_ELE_ADR040	30078.5900000000001
2021-12-01	LM_ELE_ADR042	3266.05999999999995
2021-12-01	LM_ELE_ADR044	6393.11999999999989
2021-12-01	LM_ELE_ADR048	6726.0600000000004
2021-12-01	LM_ELE_ADR051	6406.67000000000007
2021-12-01	LM_ELE_ADR053	17972.9099999999999
2021-12-01	LM_ELE_ADR055	5281.77999999999975
2021-12-01	LM_ELE_ADR056	20527.4099999999999
2021-12-01	LM_ELE_ADR063	190
2021-12-01	LM_ELE_ADR064	0
2021-12-01	LM_ELE_ADR058	77006.3800000000047
2021-12-01	LM_ELE_ADR072	23652
2021-12-01	LM_ELE_ADR074	71956
2021-12-01	LM_ELE_ADR076	0
2021-12-01	LM_ELE_ADR081	43258.4000000000015
2021-12-01	LM_ELE_ADR085	46950.3700000000026
2021-12-01	LM_ELE_ADR090	35266.6699999999983
2021-12-01	LM_ELE_ADR107	75135.8000000000029
2021-12-01	LM_ELE_ADR108	6263.10999999999967
2021-12-01	LM_ELE_ADR109	2014.3900000000001
2021-12-01	LM_ELE_ADR110	407.04000000000002
2021-12-01	LM_ELE_ADR113	49715.8899999999994
2021-12-01	LM_ELE_ADR087	83817.6999999999971
2021-12-01	LM_LC_ADR_B45	158.780000000000001
2021-12-01	LM_LH_ADR_B46	49.3500000000000014
2021-12-01	LM_LH_ADR_B47	116.599999999999994
2021-12-01	LM_WOD_ADR_B74	31.8000000000000007
2021-12-01	LM_ELE_ADR_B06	425251.5
2021-12-01	LM_ELE_ADR046	0
2021-12-01	LM_ELE_ADR010	111399.960000000006
2021-12-01	LM_ELE_ADR043	2607.36000000000013
2021-12-01	LM_ELE_ADR_B11	29981.4000000000015
2021-12-01	LM_WOD_ADR242	41.7999999999999972
2021-12-01	LM_ELE_ADR124	82924.0399999999936
2021-12-01	LM_ELE_ADR112	702843.560000000056
2021-12-01	LM_WOD_ADR_B75	161.939999999999998
2021-12-01	LM_ELE_ADR091	10684.7900000000009
2021-12-01	LM_WOD_ADR_B80	108.299999999999997
2021-12-01	LM_WOD_ADR_B81	40.5700000000000003
2021-12-01	LM_ELE_ADR_B04	274142.25
2021-12-01	LM_ELE_ADR_B05	237516.690000000002
2021-12-01	LM_ELE_ADR_B09	277900.25
2021-12-01	LM_ELE_ADR_B01	0
2021-12-01	LM_ELE_ADR_B10	27797.9399999999987
2021-12-01	LM_ELE_ADR_B02	0
2021-12-01	LM_LC_ADR_B18	16.120000000000001
2021-12-01	LM_LC_ADR_B20	62.240000000000002
2021-12-01	LM_LC_ADR_B22	35.9500000000000028
2021-12-01	LM_LC_ADR_B24	10.0199999999999996
2021-12-01	LM_LC_ADR_B31	367.300000000000011
2021-12-01	LM_LC_ADR_B41	415.5
2021-12-01	LM_LC_ADR_B43	7
2021-12-01	LM_LH_ADR_B23	64.0999999999999943
2021-12-01	LM_LH_ADR_B25	49.8999999999999986
2021-12-01	LM_LH_ADR_B27	123.099999999999994
2021-12-01	LM_LH_ADR_B35	0
2021-12-01	LM_LH_ADR_B36	0
2021-12-01	LM_LH_ADR_B38	71.7999999999999972
2021-12-01	LM_LH_ADR_B44	4.5
2021-12-01	LM_WOD_ADR_B76	1736.78999999999996
2021-12-01	LM_WOD_ADR_B77	8.96000000000000085
2021-12-01	LM_LC_ADR_B16	34.75
2021-12-01	LM_LH_ADR_B17	48.2999999999999972
2021-12-01	LM_WOD_ADR_B79	360.110000000000014
2021-12-01	LM_ELE_ADR_B12	16269.7199999999993
2021-12-01	LM_ELE_ADR_B13	15053.1900000000005
2021-12-01	LM_LC_ADR_B46	45.1400000000000006
2021-12-01	LM_LC_ADR193	0
2021-12-01	LM_ELE_ADR125	4717.57999999999993
2021-12-01	LM_ELE_ADR069	269329
2021-12-01	LM_ELE_ADR075	9989
2021-12-01	LM_LC_ADR159	1290
2021-12-01	LM_LC_ADR160	3490
2021-12-01	LM_LH_ADR167	450
2021-12-01	LM_WOD_ADR236	1.96999999999999997
2022-01-01	LM_LC_ADR170	51.8400000000000034
2022-01-01	LM_LC_ADR172	108.629999999999995
2022-01-01	LM_LC_ADR179	79.3499999999999943
2022-01-01	LM_ELE_ADR021	236525.529999999999
2022-01-01	LM_ELE_ADR078	49498
2022-01-01	LM_ELE_ADR066	0
2022-01-01	LM_ELE_ADR080	163986.410000000003
2022-01-01	LM_LH_ADR199	141.400000000000006
2022-01-01	LM_ELE_ADR115	23772.8499999999985
2022-01-01	LM_WOD_ADR249_Solution Space	93.7099999999999937
2022-01-01	LM_WOD_MAIN_W	0
2022-01-01	LM_LC_ADR123	474
2022-01-01	LM_LC_ADR151	28209
2022-01-01	LM_LC_ADR153	9785
2022-01-01	LM_LC_ADR154	2378.69999999999982
2022-01-01	LM_LC_ADR155	6315.89999999999964
2022-01-01	LM_LC_ADR157	1003.5
2022-01-01	LM_LC_ADR158	320.199999999999989
2022-01-01	LM_LC_ADR162	722.600000000000023
2022-01-01	LM_LC_ADR168	93.7999999999999972
2022-01-01	LM_LC_ADR173	91.25
2022-01-01	LM_LC_ADR174	176.560000000000002
2022-01-01	LM_LC_ADR175	0
2022-01-01	LM_LC_ADR176	84.7000000000000028
2022-01-01	LM_LC_ADR178	116.420000000000002
2022-01-01	LM_LC_ADR184	41.7100000000000009
2022-01-01	LM_LC_ADR186	19.2300000000000004
2022-01-01	LM_LC_ADR187	32.509999999999998
2022-01-01	LM_LC_ADR209	86.5499999999999972
2022-01-01	LM_LC_ADR32	0
2022-01-01	LM_LC_ADR82	12.4800000000000004
2022-01-01	LM_LH_ADR122	14.5
2022-01-01	LM_LH_ADR189	57.7299999999999969
2022-01-01	LM_LH_ADR195	414.399999999999977
2022-01-01	LM_LH_ADR196	9
2022-01-01	LM_LH_ADR198	1179.40000000000009
2022-01-01	LM_LH_ADR200	45.7999999999999972
2022-01-01	LM_LH_ADR203	218.199999999999989
2022-01-01	LM_LH_ADR204	95.5999999999999943
2022-01-01	LM_LH_ADR208	292.699999999999989
2022-01-01	LM_LH_ADR211	32
2022-01-01	LM_LH_ADR212	162.300000000000011
2022-01-01	LM_LH_ADR216	32.5300000000000011
2022-01-01	LM_LH_ADR218	400.5
2022-01-01	LM_LH_ADR221	312.5
2022-01-01	LM_LH_ADR222	0
2022-01-01	LM_LH_ADR227	41.2000000000000028
2022-01-01	LM_LH_ADR229	84.8199999999999932
2022-01-01	LM_LH_ADR231	0
2022-01-01	LM_LH_ADR234	0
2022-01-01	LM_LH_ADR235	86.4000000000000057
2022-01-01	LM_LH_ADR33	0
2022-01-01	LM_ELE_ADR008	92839.1499999999942
2022-01-01	LM_ELE_ADR012	77785.5200000000041
2022-01-01	LM_ELE_ADR017	11969.0400000000009
2022-01-01	LM_ELE_ADR019	2568.88000000000011
2022-01-01	LM_ELE_ADR024	118400.539999999994
2022-01-01	LM_ELE_ADR027	35094.6699999999983
2022-01-01	LM_LC_ADR163	29
2022-01-01	LM_LC_ADR164	0.0200000000000000004
2022-01-01	LM_LH_ADR201	87.9000000000000057
2022-01-01	LM_ELE_ADR029	11808.9899999999998
2022-01-01	LM_ELE_ADR031	177510.549999999988
2022-01-01	LM_ELE_ADR038	319410.909999999974
2022-01-01	LM_ELE_ADR041	62763.8700000000026
2022-01-01	LM_ELE_ADR045	5622.14999999999964
2022-01-01	LM_ELE_ADR047	5075.38000000000011
2022-01-01	LM_ELE_ADR049	13993.9799999999996
2022-01-01	LM_ELE_ADR052	10508.3299999999999
2022-01-01	LM_ELE_ADR054	29301.0400000000009
2022-01-01	LM_ELE_ADR057	5817.09000000000015
2022-01-01	LM_ELE_ADR059	22110.3100000000013
2022-01-01	LM_ELE_ADR060	0
2022-01-01	LM_ELE_ADR061	0
2022-01-01	LM_ELE_ADR062	19766
2022-01-01	LM_ELE_ADR065	0
2022-01-01	LM_ELE_ADR067	262
2022-01-01	LM_ELE_ADR068	3284
2022-01-01	LM_ELE_ADR070	88
2022-01-01	LM_ELE_ADR071	73505
2022-01-01	LM_ELE_ADR073	88
2022-01-01	LM_ELE_ADR077	1063
2022-01-01	LM_ELE_ADR084	53243.1100000000006
2022-01-01	LM_ELE_ADR086	13280.8899999999994
2022-01-01	LM_ELE_ADR088	35881.0299999999988
2022-01-01	LM_ELE_ADR094	1453.44000000000005
2022-01-01	LM_ELE_ADR095	95113.3899999999994
2022-01-01	LM_ELE_ADR097	28016.3400000000001
2022-01-01	LM_ELE_ADR098	3356.2199999999998
2022-01-01	LM_ELE_ADR099	72670.1999999999971
2022-01-01	LM_ELE_ADR100	16213.0300000000007
2022-01-01	LM_ELE_ADR101	7179.72999999999956
2022-01-01	LM_ELE_ADR111	362.569999999999993
2022-01-01	LM_ELE_ADR116	15001.3600000000006
2022-01-01	LM_ELE_ADR118	19930.9799999999996
2022-01-01	LM_ELE_ADR119	70936.1999999999971
2022-01-01	LM_ELE_ADR120	76621.320000000007
2022-01-01	LM_WOD_ADR129	109.400000000000006
2022-01-01	LM_WOD_ADR140	121.969999999999999
2022-01-01	LM_WOD_ADR147	57.3599999999999994
2022-01-01	LM_WOD_ADR246_Solution Space	502.529999999999973
2022-01-01	LM_WOD_ADR248_Solution Space	41.0399999999999991
2022-01-01	LM_ELE_ADR_B03	122213.410000000003
2022-01-01	LM_ELE_ADR_B07	96226.1300000000047
2022-01-01	LM_ELE_ADR_B08	143926.660000000003
2022-01-01	LM_LC_ADR_B26	129.569999999999993
2022-01-01	LM_LC_ADR_B30	389.699999999999989
2022-01-01	LM_LC_ADR_B32	862.399999999999977
2022-01-01	LM_LC_ADR_B33	762.799999999999955
2022-01-01	LM_LH_ADR_B19	89.4000000000000057
2022-01-01	LM_LH_ADR_B21	183.300000000000011
2022-01-01	LM_LH_ADR_B34	0
2022-01-01	LM_LH_ADR_B37	0.400000000000000022
2022-01-01	LM_LH_ADR_B39	95.7000000000000028
2022-01-01	LM_LH_ADR_B40	160.400000000000006
2022-01-01	LM_LH_ADR_B42	0
2022-01-01	LM_WOD_ADR_B78	183.439999999999998
2022-01-01	LM_LC_ADR102	47.4200000000000017
2022-01-01	LM_LC_ADR103	52.1899999999999977
2022-01-01	LM_LC_ADR104	67.6899999999999977
2022-01-01	LM_LC_ADR152	4597.5
2022-01-01	LM_LC_ADR149	0.910000000000000031
2022-01-01	LM_LC_ADR156	3146.59999999999991
2022-01-01	LM_LC_ADR171	267.509999999999991
2022-01-01	LM_LC_ADR165	42.8400000000000034
2022-01-01	LM_LC_ADR166	34.1400000000000006
2022-01-01	LM_LC_ADR180	134.030000000000001
2022-01-01	LM_LC_ADR181	0.100000000000000006
2022-01-01	LM_LC_ADR182	81.5900000000000034
2022-01-01	LM_LC_ADR183	1.41999999999999993
2022-01-01	LM_LC_ADR185	18.8200000000000003
2022-01-01	LM_LC_ADR161	1334.09999999999991
2022-01-01	LM_LC_ADR224	146.449999999999989
2022-01-01	LM_LC_ADR89	32.2100000000000009
2022-01-01	LM_LC_ADR93	31.7600000000000016
2022-01-01	LM_LH_ADR145	10.0700000000000003
2022-01-01	LM_LH_ADR188	32.1799999999999997
2022-01-01	LM_LH_ADR190	7.88999999999999968
2022-01-01	LM_LH_ADR191	18.8000000000000007
2022-01-01	LM_LH_ADR192	0
2022-01-01	LM_LH_ADR194	0
2022-01-01	LM_LH_ADR207	398.199999999999989
2022-01-01	LM_LH_ADR197	1246.70000000000005
2022-01-01	LM_LH_ADR215	0
2022-01-01	LM_LH_ADR219	0.0299999999999999989
2022-01-01	LM_LH_ADR220	71.980000000000004
2022-01-01	LM_LH_ADR223	176.599999999999994
2022-01-01	LM_LH_ADR225	70.4000000000000057
2022-01-01	LM_LH_ADR226	66.4500000000000028
2022-01-01	LM_LH_ADR217	494.100000000000023
2022-01-01	LM_LH_ADR228	28.8000000000000007
2022-01-01	LM_LH_ADR232	54.4799999999999969
2022-01-01	LM_LH_ADR233	45.1000000000000014
2022-01-01	LM_LH_ADR230	1.69999999999999996
2022-01-01	LM_ELE_ADR114	254182.160000000003
2022-01-01	LM_ELE_ADR117	22560.4599999999991
2022-01-01	LM_WOD_ADR132	292.850000000000023
2022-01-01	LM_WOD_ADR133	339.79000000000002
2022-01-01	LM_WOD_ADR134	18.5899999999999999
2022-01-01	LM_WOD_ADR135	0
2022-01-01	LM_WOD_ADR136	67.1800000000000068
2022-01-01	LM_WOD_ADR139	1338.72000000000003
2022-01-01	LM_WOD_ADR141	17
2022-01-01	LM_WOD_ADR142	36
2022-01-01	LM_WOD_ADR143	557.389999999999986
2022-01-01	LM_WOD_ADR146	28874
2022-01-01	LM_WOD_ADR150	38.7899999999999991
2022-01-01	LM_WOD_ADR237	923.350000000000023
2022-01-01	LM_WOD_ADR238	2277.40000000000009
2022-01-01	LM_WOD_ADR239	31.3999999999999986
2022-01-01	LM_WOD_ADR240	119.129999999999995
2022-01-01	LM_WOD_ADR241	45.3200000000000003
2022-01-01	LM_ELE_ADR121	85.4399999999999977
2022-01-01	LM_ELE_ADR128	0
2022-01-01	LM_WOD_ADR247_Solution Space	505.490000000000009
2022-01-01	LM_WOD_ADR250_Solution Space	182.530000000000001
2022-01-01	LM_WOD_ADR30	0
2022-01-01	LM_ELE_ADR001	64962.3300000000017
2022-01-01	LM_ELE_ADR002	85021.4499999999971
2022-01-01	LM_ELE_ADR003	110804.380000000005
2022-01-01	LM_ELE_ADR006	74055.7599999999948
2022-01-01	LM_ELE_ADR007	126956.690000000002
2022-01-01	LM_ELE_ADR009	166633.059999999998
2022-01-01	LM_ELE_ADR011	159020.130000000005
2022-01-01	LM_ELE_ADR013	206741.160000000003
2022-01-01	LM_ELE_ADR014	13583.2600000000002
2022-01-01	LM_ELE_ADR015	124156.660000000003
2022-01-01	LM_ELE_ADR016	914650.060000000056
2022-01-01	LM_ELE_ADR018	12501.5699999999997
2022-01-01	LM_ELE_ADR020	129521.889999999999
2022-01-01	LM_ELE_ADR022	136147.75
2022-01-01	LM_ELE_ADR023	30457.2999999999993
2022-01-01	LM_ELE_ADR025	436062.219999999972
2022-01-01	LM_ELE_ADR028	18611.5299999999988
2022-01-01	LM_ELE_ADR034	25480.7700000000004
2022-01-01	LM_ELE_ADR036	85486.1000000000058
2022-01-01	LM_ELE_ADR039	327294.559999999998
2022-01-01	LM_ELE_ADR040	33078.7200000000012
2022-01-01	LM_ELE_ADR042	3321.98999999999978
2022-01-01	LM_ELE_ADR044	6485.85000000000036
2022-01-01	LM_ELE_ADR048	6826.89000000000033
2022-01-01	LM_ELE_ADR051	6510
2022-01-01	LM_ELE_ADR053	19195.9399999999987
2022-01-01	LM_ELE_ADR055	5367.61999999999989
2022-01-01	LM_ELE_ADR056	20874.4000000000015
2022-01-01	LM_ELE_ADR063	190
2022-01-01	LM_ELE_ADR064	0
2022-01-01	LM_ELE_ADR058	78316.0800000000017
2022-01-01	LM_ELE_ADR072	24321
2022-01-01	LM_ELE_ADR074	73505
2022-01-01	LM_ELE_ADR076	0
2022-01-01	LM_ELE_ADR081	47140.2900000000009
2022-01-01	LM_ELE_ADR085	49034.0599999999977
2022-01-01	LM_ELE_ADR090	35908.3199999999997
2022-01-01	LM_ELE_ADR107	77556.3399999999965
2022-01-01	LM_ELE_ADR108	6319.57999999999993
2022-01-01	LM_ELE_ADR109	2014.63000000000011
2022-01-01	LM_ELE_ADR110	410.79000000000002
2022-01-01	LM_ELE_ADR113	50768.6999999999971
2022-01-01	LM_ELE_ADR087	85085.4600000000064
2022-01-01	LM_LC_ADR_B45	177.110000000000014
2022-01-01	LM_LH_ADR_B46	49.3500000000000014
2022-01-01	LM_LH_ADR_B47	116.700000000000003
2022-01-01	LM_WOD_ADR_B74	32.6799999999999997
2022-01-01	LM_ELE_ADR_B06	433482.75
2022-01-01	LM_ELE_ADR046	0
2022-01-01	LM_ELE_ADR010	113322.880000000005
2022-01-01	LM_ELE_ADR043	2658.11000000000013
2022-01-01	LM_ELE_ADR_B11	30629.9700000000012
2022-01-01	LM_WOD_ADR242	42.0600000000000023
2022-01-01	LM_ELE_ADR124	88215.2700000000041
2022-01-01	LM_ELE_ADR112	707275.75
2022-01-01	LM_WOD_ADR_B75	174.460000000000008
2022-01-01	LM_ELE_ADR091	11008.2700000000004
2022-01-01	LM_WOD_ADR_B80	111.569999999999993
2022-01-01	LM_WOD_ADR_B81	41.0499999999999972
2022-01-01	LM_ELE_ADR_B04	275595.090000000026
2022-01-01	LM_ELE_ADR_B05	239370.660000000003
2022-01-01	LM_ELE_ADR_B09	282907.280000000028
2022-01-01	LM_ELE_ADR_B01	0
2022-01-01	LM_ELE_ADR_B10	28369.1599999999999
2022-01-01	LM_ELE_ADR_B02	0
2022-01-01	LM_LC_ADR_B18	16.8900000000000006
2022-01-01	LM_LC_ADR_B20	64.0999999999999943
2022-01-01	LM_LC_ADR_B22	44.7199999999999989
2022-01-01	LM_LC_ADR_B24	10.0199999999999996
2022-01-01	LM_LC_ADR_B31	389.899999999999977
2022-01-01	LM_LC_ADR_B41	443.699999999999989
2022-01-01	LM_LC_ADR_B43	7.40000000000000036
2022-01-01	LM_LH_ADR_B23	64.0999999999999943
2022-01-01	LM_LH_ADR_B25	52.6000000000000014
2022-01-01	LM_LH_ADR_B27	129.699999999999989
2022-01-01	LM_LH_ADR_B35	0
2022-01-01	LM_LH_ADR_B36	0
2022-01-01	LM_LH_ADR_B38	71.9000000000000057
2022-01-01	LM_LH_ADR_B44	4.5
2022-01-01	LM_WOD_ADR_B76	1736.78999999999996
2022-01-01	LM_WOD_ADR_B77	8.96000000000000085
2022-01-01	LM_LC_ADR_B16	35.75
2022-01-01	LM_LH_ADR_B17	48.7999999999999972
2022-01-01	LM_WOD_ADR_B79	360.110000000000014
2022-01-01	LM_ELE_ADR_B12	16811.1899999999987
2022-01-01	LM_ELE_ADR_B13	15053.1900000000005
2022-01-01	LM_LC_ADR_B46	47.3100000000000023
2022-01-01	LM_LC_ADR193	0
2022-01-01	LM_ELE_ADR125	4775.07999999999993
2022-01-01	LM_ELE_ADR069	275813
2022-01-01	LM_ELE_ADR075	10193
2022-01-01	LM_LC_ADR159	4010
2022-01-01	LM_LC_ADR160	5620
2022-01-01	LM_LH_ADR167	780
2022-01-01	LM_WOD_ADR236	3.52000000000000002
2022-02-01	LM_LC_ADR170	54.0200000000000031
2022-02-01	LM_LC_ADR172	119.109999999999999
2022-02-01	LM_ELE_ADR115	24653.3100000000013
2022-02-01	LM_LC_ADR123	495.800000000000011
2022-02-01	LM_LC_ADR176	84.7000000000000028
2022-02-01	LM_LH_ADR208	301.699999999999989
2022-02-01	LM_ELE_ADR019	3435.55999999999995
2022-02-01	LM_LH_ADR201	89.0999999999999943
2022-02-01	LM_ELE_ADR059	22648.1899999999987
2022-02-01	LM_ELE_ADR097	29310.5299999999988
2022-02-01	LM_WOD_ADR246_Solution Space	516.549999999999955
2022-02-01	LM_LC_ADR171	292.379999999999995
2022-02-01	LM_LH_ADR194	0
2022-02-01	LM_WOD_ADR133	341.319999999999993
2022-02-01	LM_WOD_ADR150	39.759999999999998
2022-02-01	LM_ELE_ADR007	132043.48000000001
2022-02-01	LM_ELE_ADR039	344429.309999999998
2022-02-01	LM_ELE_ADR081	52698.5500000000029
2022-02-01	LM_ELE_ADR010	115438.130000000005
2022-02-01	LM_ELE_ADR_B02	0
2022-02-01	LM_WOD_ADR_B76	1736.78999999999996
2022-02-01	LM_WOD_ADR236	5.59999999999999964
2022-03-01	LM_LC_ADR170	55.2700000000000031
2022-03-01	LM_LC_ADR172	124.870000000000005
2022-03-01	LM_LC_ADR179	85.5799999999999983
2022-03-01	LM_ELE_ADR021	264735.340000000026
2022-02-01	zdemontowany600	3194
2022-03-01	LM_ELE_ADR078	52811
2022-03-01	LM_ELE_ADR066	0
2022-03-01	LM_ELE_ADR080	169140
2022-03-01	LM_LH_ADR199	145.400000000000006
2022-03-01	LM_ELE_ADR115	25335.0800000000017
2022-03-01	LM_WOD_ADR249_Solution Space	100.75
2022-03-01	LM_WOD_MAIN_W	0
2022-03-01	LM_LC_ADR123	516
2022-03-01	LM_LC_ADR151	30093
2022-03-01	LM_LC_ADR153	10320
2022-03-01	LM_LC_ADR154	2568.19999999999982
2022-03-01	LM_LC_ADR155	6859.60000000000036
2022-03-01	LM_LC_ADR157	1083.40000000000009
2022-03-01	LM_LC_ADR158	351.399999999999977
2022-03-01	LM_LC_ADR162	779.100000000000023
2022-03-01	LM_LC_ADR168	110.900000000000006
2022-03-01	LM_LC_ADR173	99.2999999999999972
2022-03-01	LM_LC_ADR174	196.419999999999987
2022-03-01	LM_LC_ADR175	0
2022-03-01	LM_LC_ADR176	84.7000000000000028
2022-03-01	LM_LC_ADR178	129.889999999999986
2022-03-01	LM_LC_ADR184	42.8299999999999983
2022-03-01	LM_LC_ADR186	19.2300000000000004
2022-03-01	LM_LC_ADR187	32.6899999999999977
2022-03-01	LM_LC_ADR209	95.730000000000004
2022-03-01	LM_LC_ADR32	0
2022-03-01	LM_LC_ADR82	21.8399999999999999
2022-03-01	LM_LH_ADR122	14.8000000000000007
2022-03-01	LM_LH_ADR189	60.0900000000000034
2022-03-01	LM_LH_ADR195	426.899999999999977
2022-03-01	LM_LH_ADR196	9
2022-03-01	LM_LH_ADR198	1218.09999999999991
2022-03-01	LM_LH_ADR200	46.6000000000000014
2022-03-01	LM_LH_ADR203	220
2022-03-01	LM_LH_ADR204	98.2999999999999972
2022-03-01	LM_LH_ADR208	309.100000000000023
2022-03-01	LM_LH_ADR211	35.7000000000000028
2022-03-01	LM_LH_ADR212	181.300000000000011
2022-03-01	LM_LH_ADR216	34.8699999999999974
2022-03-01	LM_LH_ADR218	420.300000000000011
2022-03-01	LM_LH_ADR221	330.5
2022-03-01	LM_LH_ADR222	0
2022-03-01	LM_LH_ADR227	41.2000000000000028
2022-03-01	LM_LH_ADR229	84.8900000000000006
2022-03-01	LM_LH_ADR231	0
2022-03-01	LM_LH_ADR234	0
2022-03-01	LM_LH_ADR235	86.7999999999999972
2022-03-01	LM_LH_ADR33	0
2022-03-01	LM_ELE_ADR008	100582.660000000003
2022-03-01	LM_ELE_ADR012	91251.6300000000047
2022-03-01	LM_ELE_ADR017	12498.3500000000004
2022-03-01	LM_ELE_ADR019	3913.96000000000004
2022-03-01	LM_ELE_ADR024	123242.229999999996
2022-03-01	LM_ELE_ADR027	35663.1100000000006
2022-03-01	LM_LC_ADR163	29.2699999999999996
2022-03-01	LM_LC_ADR164	0.0200000000000000004
2022-03-01	LM_LH_ADR201	90.5
2022-03-01	LM_ELE_ADR029	12802.3500000000004
2022-03-01	LM_ELE_ADR031	184708.700000000012
2022-03-01	LM_ELE_ADR038	346919.880000000005
2022-03-01	LM_ELE_ADR041	65758.1000000000058
2022-03-01	LM_ELE_ADR045	5815.94999999999982
2022-03-01	LM_ELE_ADR047	5258.94999999999982
2022-03-01	LM_ELE_ADR049	14411.5100000000002
2022-03-01	LM_ELE_ADR052	10869.9699999999993
2022-03-01	LM_ELE_ADR054	30235.7099999999991
2022-03-01	LM_ELE_ADR057	5984.44999999999982
2022-03-01	LM_ELE_ADR059	23096.9000000000015
2022-03-01	LM_ELE_ADR060	0
2022-03-01	LM_ELE_ADR061	0
2022-03-01	LM_ELE_ADR062	21285
2022-03-01	LM_ELE_ADR065	0
2022-03-01	LM_ELE_ADR067	264
2022-03-01	LM_ELE_ADR068	6409
2022-03-01	LM_ELE_ADR070	88
2022-03-01	LM_ELE_ADR071	76851
2022-03-01	LM_ELE_ADR073	88
2022-03-01	LM_ELE_ADR077	1063
2022-03-01	LM_ELE_ADR084	54394.7099999999991
2022-03-01	LM_ELE_ADR086	14286.6000000000004
2022-03-01	LM_ELE_ADR088	37864.1500000000015
2022-03-01	LM_ELE_ADR094	1470.8900000000001
2022-03-01	LM_ELE_ADR095	99386.1000000000058
2022-03-01	LM_ELE_ADR097	30406.630000000001
2022-03-01	LM_ELE_ADR098	3438.05000000000018
2022-03-01	LM_ELE_ADR099	79358.5399999999936
2022-03-01	LM_ELE_ADR100	17622.7700000000004
2022-03-01	LM_ELE_ADR101	7582.9399999999996
2022-03-01	LM_ELE_ADR111	362.600000000000023
2022-03-01	LM_ELE_ADR116	15066.0300000000007
2022-03-01	LM_ELE_ADR118	20442.5699999999997
2022-03-01	LM_ELE_ADR119	73607.4199999999983
2022-03-01	LM_ELE_ADR120	84726.4100000000035
2022-03-01	LM_WOD_ADR129	115.420000000000002
2022-03-01	LM_WOD_ADR140	122.340000000000003
2022-03-01	LM_WOD_ADR147	59.5
2022-03-01	LM_WOD_ADR246_Solution Space	529.870000000000005
2022-03-01	LM_WOD_ADR248_Solution Space	44.3400000000000034
2022-03-01	LM_ELE_ADR_B03	126484.050000000003
2022-03-01	LM_ELE_ADR_B07	100077.979999999996
2022-03-01	LM_ELE_ADR_B08	149098
2022-03-01	LM_LC_ADR_B26	155.210000000000008
2022-03-01	LM_LC_ADR_B30	426.100000000000023
2022-03-01	LM_LC_ADR_B32	947.100000000000023
2022-03-01	LM_LC_ADR_B33	852.200000000000045
2022-03-01	LM_LH_ADR_B19	100.799999999999997
2022-03-01	LM_LH_ADR_B21	195.800000000000011
2022-03-01	LM_LH_ADR_B34	0
2022-03-01	LM_LH_ADR_B37	0.400000000000000022
2022-03-01	LM_LH_ADR_B39	96.0999999999999943
2022-03-01	LM_LH_ADR_B40	161.800000000000011
2022-03-01	LM_LH_ADR_B42	0
2022-03-01	LM_WOD_ADR_B78	187.409999999999997
2022-03-01	LM_LC_ADR102	51.7100000000000009
2022-03-01	LM_LC_ADR103	57.0200000000000031
2022-03-01	LM_LC_ADR104	75.9200000000000017
2022-03-01	LM_LC_ADR152	4924
2022-03-01	LM_LC_ADR149	0.910000000000000031
2022-03-01	LM_LC_ADR156	3455.30000000000018
2022-03-01	LM_LC_ADR171	303.490000000000009
2022-03-01	LM_LC_ADR165	47.1799999999999997
2022-03-01	LM_LC_ADR166	37.3900000000000006
2022-03-01	LM_LC_ADR180	144.129999999999995
2022-03-01	LM_LC_ADR181	0.100000000000000006
2022-03-01	LM_LC_ADR182	89.2900000000000063
2022-03-01	LM_LC_ADR183	1.41999999999999993
2022-03-01	LM_LC_ADR185	18.9400000000000013
2022-03-01	LM_LC_ADR161	1418.20000000000005
2022-03-01	LM_LC_ADR224	161.210000000000008
2022-03-01	LM_LC_ADR89	36.240000000000002
2022-03-01	LM_LC_ADR93	35.759999999999998
2022-03-01	LM_LH_ADR145	10.0700000000000003
2022-03-01	LM_LH_ADR188	32.1799999999999997
2022-03-01	LM_LH_ADR190	7.88999999999999968
2022-03-01	LM_LH_ADR191	18.8000000000000007
2022-03-01	LM_LH_ADR192	0
2022-03-01	LM_LH_ADR207	409
2022-03-01	LM_LH_ADR197	1262.5
2022-03-01	LM_LH_ADR215	0
2022-03-01	LM_LH_ADR219	0.0299999999999999989
2022-03-01	LM_LH_ADR220	112.200000000000003
2022-03-01	LM_LH_ADR223	180.099999999999994
2022-03-01	LM_LH_ADR225	70.9000000000000057
2022-03-01	LM_LH_ADR226	77.769999999999996
2022-03-01	LM_LH_ADR217	504.399999999999977
2022-03-01	LM_LH_ADR228	29.1999999999999993
2022-03-01	LM_LH_ADR232	57.3900000000000006
2022-03-01	LM_LH_ADR233	45.2000000000000028
2022-03-01	LM_LH_ADR230	1.69999999999999996
2022-03-01	LM_ELE_ADR114	27.8099999999999987
2022-03-01	LM_ELE_ADR117	22587.4099999999999
2022-03-01	LM_WOD_ADR132	297.129999999999995
2022-03-01	LM_WOD_ADR133	343.269999999999982
2022-03-01	LM_WOD_ADR134	18.6799999999999997
2022-03-01	LM_WOD_ADR135	0
2022-03-01	LM_WOD_ADR136	68.769999999999996
2022-03-01	LM_WOD_ADR139	1400.06999999999994
2022-03-01	LM_WOD_ADR141	17
2022-03-01	LM_WOD_ADR142	36
2022-03-01	LM_WOD_ADR143	557.389999999999986
2022-03-01	LM_WOD_ADR146	29910.5999999999985
2022-03-01	LM_WOD_ADR148	0.0100000000000000002
2022-03-01	LM_WOD_ADR150	40.6599999999999966
2022-03-01	LM_WOD_ADR237	923.649999999999977
2022-03-01	LM_WOD_ADR238	2425.17000000000007
2022-03-01	LM_WOD_ADR239	33.4799999999999969
2022-03-01	LM_WOD_ADR240	127.75
2022-03-01	LM_WOD_ADR241	98.5600000000000023
2022-03-01	LM_ELE_ADR121	185092.890000000014
2022-03-01	LM_ELE_ADR128	0
2022-03-01	LM_WOD_ADR247_Solution Space	552.039999999999964
2022-03-01	LM_WOD_ADR250_Solution Space	195.050000000000011
2022-03-01	LM_WOD_ADR30	0
2022-03-01	LM_ELE_ADR001	66393.0800000000017
2022-03-01	LM_ELE_ADR002	87824.4600000000064
2022-03-01	LM_ELE_ADR003	115854.339999999997
2022-03-01	LM_ELE_ADR006	0
2022-03-01	LM_ELE_ADR007	136337.089999999997
2022-03-01	LM_ELE_ADR009	174986.859999999986
2022-03-01	LM_ELE_ADR011	162767.809999999998
2022-03-01	LM_ELE_ADR013	214703.75
2022-03-01	LM_ELE_ADR014	14267.4200000000001
2022-03-01	LM_ELE_ADR015	129229.889999999999
2022-03-01	LM_ELE_ADR016	930790.560000000056
2022-03-01	LM_ELE_ADR018	12963.0499999999993
2022-03-01	LM_ELE_ADR020	135180.029999999999
2022-03-01	LM_ELE_ADR022	149547.109999999986
2022-03-01	LM_ELE_ADR023	32657.7599999999984
2022-03-01	LM_ELE_ADR025	499290.940000000002
2022-03-01	LM_ELE_ADR028	19004.5
2022-03-01	LM_ELE_ADR034	27653.8300000000017
2022-03-01	LM_ELE_ADR036	89326.5899999999965
2022-03-01	LM_ELE_ADR039	356898.469999999972
2022-03-01	LM_ELE_ADR040	36084.4599999999991
2022-03-01	LM_ELE_ADR042	3439.36999999999989
2022-03-01	LM_ELE_ADR044	6665.97000000000025
2022-03-01	LM_ELE_ADR048	7017.48999999999978
2022-03-01	LM_ELE_ADR051	6727.22000000000025
2022-03-01	LM_ELE_ADR053	22354.7999999999993
2022-03-01	LM_ELE_ADR055	5549.35000000000036
2022-03-01	LM_ELE_ADR056	21604.8499999999985
2022-03-01	LM_ELE_ADR063	190
2022-03-01	LM_ELE_ADR064	0
2022-03-01	LM_ELE_ADR058	81051.4700000000012
2022-03-01	LM_ELE_ADR072	25747
2022-03-01	LM_ELE_ADR074	76851
2022-03-01	LM_ELE_ADR076	0
2022-03-01	LM_ELE_ADR081	57250.6100000000006
2022-03-01	LM_ELE_ADR085	53664.7900000000009
2022-03-01	LM_ELE_ADR090	37275.4800000000032
2022-03-01	LM_ELE_ADR107	82612.5500000000029
2022-03-01	LM_ELE_ADR108	6462.26000000000022
2022-03-01	LM_ELE_ADR109	2015.63000000000011
2022-03-01	LM_ELE_ADR110	411.509999999999991
2022-03-01	LM_ELE_ADR113	53021.6100000000006
2022-03-01	LM_ELE_ADR087	87801.4799999999959
2022-03-01	LM_LC_ADR_B45	207.050000000000011
2022-03-01	LM_LH_ADR_B46	49.3500000000000014
2022-03-01	LM_LH_ADR_B47	117.400000000000006
2022-03-01	LM_WOD_ADR_B74	34.7100000000000009
2022-03-01	LM_ELE_ADR_B06	453654.469999999972
2022-03-01	LM_ELE_ADR046	0
2022-03-01	LM_ELE_ADR010	117036.630000000005
2022-03-01	LM_ELE_ADR043	2759.5
2022-03-01	LM_ELE_ADR_B11	32227.0999999999985
2022-03-01	LM_WOD_ADR242	42.4600000000000009
2022-03-01	LM_ELE_ADR124	99040.3999999999942
2022-03-01	LM_ELE_ADR112	716228.810000000056
2022-03-01	LM_WOD_ADR_B75	179.960000000000008
2022-03-01	LM_ELE_ADR091	11695.1499999999996
2022-03-01	LM_WOD_ADR_B80	119.680000000000007
2022-03-01	LM_WOD_ADR_B81	42.6899999999999977
2022-03-01	LM_ELE_ADR_B04	278856.909999999974
2022-03-01	LM_ELE_ADR_B05	243363.950000000012
2022-03-01	LM_ELE_ADR_B09	292142.659999999974
2022-03-01	LM_ELE_ADR_B01	0
2022-03-01	LM_ELE_ADR_B10	29549
2022-03-01	LM_ELE_ADR_B02	0
2022-03-01	LM_LC_ADR_B18	18.2199999999999989
2022-03-01	LM_LC_ADR_B20	69.3100000000000023
2022-03-01	LM_LC_ADR_B22	54.9099999999999966
2022-03-01	LM_LC_ADR_B24	10.6600000000000001
2022-03-01	LM_LC_ADR_B31	432.699999999999989
2022-03-01	LM_LC_ADR_B41	495.600000000000023
2022-03-01	LM_LC_ADR_B43	8.09999999999999964
2022-03-01	LM_LH_ADR_B23	66.2999999999999972
2022-03-01	LM_LH_ADR_B25	58.2999999999999972
2022-03-01	LM_LH_ADR_B27	139.099999999999994
2022-03-01	LM_LH_ADR_B35	0
2022-03-01	LM_LH_ADR_B36	0
2022-03-01	LM_LH_ADR_B38	72
2022-03-01	LM_LH_ADR_B44	4.5
2022-03-01	LM_WOD_ADR_B76	1736.78999999999996
2022-03-01	LM_WOD_ADR_B77	8.96000000000000085
2022-03-01	LM_LC_ADR_B16	38.8200000000000003
2022-03-01	LM_LH_ADR_B17	50
2022-03-01	LM_WOD_ADR_B79	360.110000000000014
2022-03-01	LM_ELE_ADR_B12	17833.3899999999994
2022-03-01	LM_ELE_ADR_B13	15053.1900000000005
2022-03-01	LM_LC_ADR_B46	53.490000000000002
2022-03-01	LM_LC_ADR193	0
2022-03-01	LM_ELE_ADR125	4892.60999999999967
2022-03-01	LM_ELE_ADR069	292197
2022-03-01	LM_ELE_ADR075	10654
2022-03-01	LM_LC_ADR159	5030
2022-03-01	LM_LC_ADR160	9590
2022-03-01	LM_LH_ADR167	1420
2022-03-01	LM_WOD_ADR236	7.71999999999999975
2022-03-01	zdemontowany600	3194
2022-04-01	LM_LC_ADR170	56.1000000000000014
2022-04-01	LM_LC_ADR172	129.259999999999991
2022-04-01	LM_LC_ADR179	86.0400000000000063
2022-04-01	LM_ELE_ADR021	274907.25
2022-04-01	LM_ELE_ADR078	54151
2022-04-01	LM_ELE_ADR066	0
2022-04-01	LM_ELE_ADR080	171785.920000000013
2022-04-01	LM_LH_ADR199	146.300000000000011
2022-04-01	LM_ELE_ADR115	26034.4399999999987
2022-04-01	LM_WOD_ADR249_Solution Space	105.140000000000001
2022-04-01	LM_WOD_MAIN_W	0
2022-04-01	LM_LC_ADR123	535.600000000000023
2022-04-01	LM_LC_ADR151	30737
2022-04-01	LM_LC_ADR153	10495
2022-04-01	LM_LC_ADR154	2648.19999999999982
2022-04-01	LM_LC_ADR155	7025.30000000000018
2022-04-01	LM_LC_ADR157	1108.5
2022-04-01	LM_LC_ADR158	360.5
2022-04-01	LM_LC_ADR162	796.700000000000045
2022-04-01	LM_LC_ADR168	115.700000000000003
2022-04-01	LM_LC_ADR173	100.730000000000004
2022-04-01	LM_LC_ADR174	211.560000000000002
2022-04-01	LM_LC_ADR175	0
2022-04-01	LM_LC_ADR176	85.7000000000000028
2022-04-01	LM_LC_ADR178	135.539999999999992
2022-04-01	LM_LC_ADR184	44.0399999999999991
2022-04-01	LM_LC_ADR186	19.2300000000000004
2022-04-01	LM_LC_ADR187	32.6899999999999977
2022-04-01	LM_LC_ADR209	95.730000000000004
2022-04-01	LM_LC_ADR32	0
2022-04-01	LM_LC_ADR82	25.8000000000000007
2022-04-01	LM_LH_ADR122	15.0999999999999996
2022-04-01	LM_LH_ADR189	60.3100000000000023
2022-04-01	LM_LH_ADR195	432.399999999999977
2022-04-01	LM_LH_ADR196	9
2022-04-01	LM_LH_ADR198	1238.09999999999991
2022-04-01	LM_LH_ADR200	47.2000000000000028
2022-04-01	LM_LH_ADR203	221.699999999999989
2022-04-01	LM_LH_ADR204	100.400000000000006
2022-04-01	LM_LH_ADR208	318.100000000000023
2022-04-01	LM_LH_ADR211	37.5
2022-04-01	LM_LH_ADR212	190.599999999999994
2022-04-01	LM_LH_ADR216	34.8699999999999974
2022-04-01	LM_LH_ADR218	431.600000000000023
2022-04-01	LM_LH_ADR221	346.100000000000023
2022-04-01	LM_LH_ADR222	0
2022-04-01	LM_LH_ADR227	41.2000000000000028
2022-04-01	LM_LH_ADR231	0
2022-04-01	LM_LH_ADR234	0
2022-04-01	LM_LH_ADR235	86.9000000000000057
2022-04-01	LM_LH_ADR33	0
2022-04-01	LM_ELE_ADR008	102291.110000000001
2022-04-01	LM_ELE_ADR012	92346.7899999999936
2022-04-01	LM_ELE_ADR017	12757.9899999999998
2022-04-01	LM_ELE_ADR019	4038.55999999999995
2022-04-01	LM_ELE_ADR024	125577.139999999999
2022-04-01	LM_ELE_ADR027	35941.9599999999991
2022-04-01	LM_LC_ADR163	30.1000000000000014
2022-04-01	LM_LC_ADR164	0.0200000000000000004
2022-04-01	LM_LH_ADR201	94.0999999999999943
2022-04-01	LM_ELE_ADR029	13331
2022-04-01	LM_ELE_ADR031	188273.640000000014
2022-04-01	LM_ELE_ADR038	358703.309999999998
2022-04-01	LM_ELE_ADR041	66973.3000000000029
2022-04-01	LM_ELE_ADR045	5914.60999999999967
2022-04-01	LM_ELE_ADR047	5357.25
2022-04-01	LM_ELE_ADR049	14618.4799999999996
2022-04-01	LM_ELE_ADR052	11045.3099999999995
2022-04-01	LM_ELE_ADR054	30687.9099999999999
2022-04-01	LM_ELE_ADR057	6080.56999999999971
2022-04-01	LM_ELE_ADR059	23574.6399999999994
2022-04-01	LM_ELE_ADR060	0
2022-04-01	LM_ELE_ADR061	0
2022-04-01	LM_ELE_ADR062	22038
2022-04-01	LM_ELE_ADR065	0
2022-04-01	LM_ELE_ADR067	266
2022-04-01	LM_ELE_ADR068	7740
2022-04-01	LM_ELE_ADR070	88
2022-04-01	LM_ELE_ADR071	78744
2022-04-01	LM_ELE_ADR073	88
2022-04-01	LM_ELE_ADR077	1063
2022-04-01	LM_ELE_ADR084	55071.6200000000026
2022-04-01	LM_ELE_ADR086	14782.2800000000007
2022-04-01	LM_ELE_ADR088	38918.8000000000029
2022-04-01	LM_ELE_ADR094	1479.88000000000011
2022-04-01	LM_ELE_ADR095	101468.179999999993
2022-04-01	LM_ELE_ADR097	31638.7400000000016
2022-04-01	LM_ELE_ADR098	3490.13999999999987
2022-04-01	LM_ELE_ADR099	82524.7100000000064
2022-04-01	LM_ELE_ADR100	18419.0800000000017
2022-04-01	LM_ELE_ADR101	7778.43000000000029
2022-04-01	LM_ELE_ADR111	362.600000000000023
2022-04-01	LM_ELE_ADR116	15087.1900000000005
2022-04-01	LM_ELE_ADR118	20882.4700000000012
2022-04-01	LM_ELE_ADR119	74945.3600000000006
2022-04-01	LM_ELE_ADR120	88401.6499999999942
2022-04-01	LM_WOD_ADR129	119.25
2022-04-01	LM_WOD_ADR140	122.670000000000002
2022-04-01	LM_WOD_ADR147	60.6899999999999977
2022-04-01	LM_WOD_ADR246_Solution Space	545.17999999999995
2022-04-01	LM_WOD_ADR248_Solution Space	46.2199999999999989
2022-04-01	LM_ELE_ADR_B03	128346.270000000004
2022-04-01	LM_ELE_ADR_B07	101725.520000000004
2022-04-01	LM_ELE_ADR_B08	151519.529999999999
2022-04-01	LM_LC_ADR_B26	163.629999999999995
2022-04-01	LM_LC_ADR_B30	439.5
2022-04-01	LM_LC_ADR_B32	968.700000000000045
2022-04-01	LM_LC_ADR_B33	873.899999999999977
2022-04-01	LM_LH_ADR_B19	101.799999999999997
2022-04-01	LM_LH_ADR_B21	197.5
2022-04-01	LM_LH_ADR_B34	0
2022-04-01	LM_LH_ADR_B37	0.400000000000000022
2022-04-01	LM_LH_ADR_B39	97.0999999999999943
2022-04-01	LM_LH_ADR_B40	163.300000000000011
2022-04-01	LM_LH_ADR_B42	0
2022-04-01	LM_WOD_ADR_B78	190.189999999999998
2022-04-01	LM_LC_ADR102	53.5499999999999972
2022-04-01	LM_LC_ADR103	59.0799999999999983
2022-04-01	LM_LC_ADR104	79.3299999999999983
2022-04-01	LM_LC_ADR152	5053.89999999999964
2022-04-01	LM_LC_ADR149	0.910000000000000031
2022-04-01	LM_LC_ADR156	3555.09999999999991
2022-04-01	LM_LC_ADR171	305.810000000000002
2022-04-01	LM_LC_ADR165	49.1400000000000006
2022-04-01	LM_LC_ADR166	38.7700000000000031
2022-04-01	LM_LC_ADR180	144.710000000000008
2022-04-01	LM_LC_ADR181	0.100000000000000006
2022-04-01	LM_LC_ADR182	91.4599999999999937
2022-04-01	LM_LC_ADR183	1.41999999999999993
2022-04-01	LM_LC_ADR185	18.9400000000000013
2022-04-01	LM_LC_ADR161	1449.70000000000005
2022-04-01	LM_LC_ADR224	167.580000000000013
2022-04-01	LM_LC_ADR89	37.9200000000000017
2022-04-01	LM_LC_ADR93	37.4299999999999997
2022-04-01	LM_LH_ADR145	10.0700000000000003
2022-04-01	LM_LH_ADR188	32.1799999999999997
2022-04-01	LM_LH_ADR190	7.88999999999999968
2022-04-01	LM_LH_ADR191	18.8000000000000007
2022-04-01	LM_LH_ADR192	0
2022-04-01	LM_LH_ADR194	0
2022-04-01	LM_LH_ADR207	414.399999999999977
2022-04-01	LM_LH_ADR197	1272.59999999999991
2022-04-01	LM_LH_ADR215	0
2022-04-01	LM_LH_ADR219	0.0299999999999999989
2022-04-01	LM_LH_ADR220	112.200000000000003
2022-04-01	LM_LH_ADR223	184.699999999999989
2022-04-01	LM_LH_ADR225	70.9000000000000057
2022-04-01	LM_LH_ADR226	81.4399999999999977
2022-04-01	LM_LH_ADR217	505.5
2022-04-01	LM_LH_ADR228	29.6000000000000014
2022-04-01	LM_LH_ADR232	58.8100000000000023
2022-04-01	LM_LH_ADR233	45.6000000000000014
2022-04-01	LM_LH_ADR230	1.69999999999999996
2022-04-01	LM_ELE_ADR114	27.8099999999999987
2022-04-01	LM_ELE_ADR117	22600.5800000000017
2022-04-01	LM_WOD_ADR132	300.100000000000023
2022-04-01	LM_WOD_ADR133	345.990000000000009
2022-04-01	LM_WOD_ADR134	18.6900000000000013
2022-04-01	LM_WOD_ADR135	0
2022-04-01	LM_WOD_ADR136	69.7800000000000011
2022-04-01	LM_WOD_ADR139	1436.00999999999999
2022-04-01	LM_WOD_ADR141	17
2022-04-01	LM_WOD_ADR142	36
2022-04-01	LM_WOD_ADR143	557.389999999999986
2022-04-01	LM_WOD_ADR146	30399.5999999999985
2022-04-01	LM_WOD_ADR148	0.0500000000000000028
2022-04-01	LM_WOD_ADR150	41.6899999999999977
2022-04-01	LM_WOD_ADR237	924.009999999999991
2022-04-01	LM_WOD_ADR238	2523.19000000000005
2022-04-01	LM_WOD_ADR239	34.7100000000000009
2022-04-01	LM_WOD_ADR240	132.77000000000001
2022-04-01	LM_WOD_ADR241	129.159999999999997
2022-04-01	LM_ELE_ADR121	195389.76999999999
2022-04-01	LM_ELE_ADR128	0
2022-04-01	LM_WOD_ADR247_Solution Space	575.25
2022-04-01	LM_WOD_ADR250_Solution Space	201.800000000000011
2022-04-01	LM_WOD_ADR30	0
2022-04-01	LM_ELE_ADR001	67985.070000000007
2022-04-01	LM_ELE_ADR002	89203.3899999999994
2022-04-01	LM_ELE_ADR003	121408.699999999997
2022-04-01	LM_ELE_ADR006	0
2022-04-01	LM_ELE_ADR007	141611.140000000014
2022-04-01	LM_ELE_ADR009	183606.160000000003
2022-04-01	LM_ELE_ADR011	167799.079999999987
2022-04-01	LM_ELE_ADR013	223925.5
2022-04-01	LM_ELE_ADR014	14614.8400000000001
2022-04-01	LM_ELE_ADR015	131713.359999999986
2022-04-01	LM_ELE_ADR016	939551.75
2022-04-01	LM_ELE_ADR018	13189.9300000000003
2022-04-01	LM_ELE_ADR020	137552.640000000014
2022-04-01	LM_ELE_ADR022	156802.690000000002
2022-04-01	LM_ELE_ADR023	33777.3899999999994
2022-04-01	LM_ELE_ADR025	525948.560000000056
2022-04-01	LM_ELE_ADR028	19343.5999999999985
2022-04-01	LM_ELE_ADR034	28718.5200000000004
2022-04-01	LM_ELE_ADR036	90925.5500000000029
2022-04-01	LM_ELE_ADR039	367002.130000000005
2022-04-01	LM_ELE_ADR040	36311.3700000000026
2022-04-01	LM_ELE_ADR042	3495.40999999999985
2022-04-01	LM_ELE_ADR044	6766.3100000000004
2022-04-01	LM_ELE_ADR048	7122.82999999999993
2022-04-01	LM_ELE_ADR051	6833.0600000000004
2022-04-01	LM_ELE_ADR053	24089.0900000000001
2022-04-01	LM_ELE_ADR055	5636.67000000000007
2022-04-01	LM_ELE_ADR056	21963.1699999999983
2022-04-01	LM_ELE_ADR063	190
2022-04-01	LM_ELE_ADR064	0
2022-04-01	LM_ELE_ADR058	82381.25
2022-04-01	LM_ELE_ADR072	26434
2022-04-01	LM_ELE_ADR074	78744
2022-04-01	LM_ELE_ADR076	0
2022-04-01	LM_ELE_ADR081	62465.9100000000035
2022-04-01	LM_ELE_ADR085	55790.0400000000009
2022-04-01	LM_ELE_ADR090	38053.1600000000035
2022-04-01	LM_ELE_ADR107	84886.6499999999942
2022-04-01	LM_ELE_ADR108	6508.10000000000036
2022-04-01	LM_ELE_ADR109	2015.90000000000009
2022-04-01	LM_ELE_ADR110	412.819999999999993
2022-04-01	LM_ELE_ADR113	53932.9700000000012
2022-04-01	LM_ELE_ADR087	88907.1999999999971
2022-04-01	LM_LC_ADR_B45	213.849999999999994
2022-04-01	LM_LH_ADR_B46	49.3500000000000014
2022-04-01	LM_LH_ADR_B47	118.799999999999997
2022-04-01	LM_WOD_ADR_B74	35.8100000000000023
2022-04-01	LM_ELE_ADR_B06	464107.690000000002
2022-04-01	LM_ELE_ADR046	0
2022-04-01	LM_ELE_ADR010	118763.169999999998
2022-04-01	LM_ELE_ADR043	2808.80000000000018
2022-04-01	LM_ELE_ADR_B11	33012.0599999999977
2022-04-01	LM_WOD_ADR242	42.7100000000000009
2022-04-01	LM_ELE_ADR124	104475.610000000001
2022-04-01	LM_ELE_ADR112	721506.810000000056
2022-04-01	LM_WOD_ADR_B75	181.240000000000009
2022-04-01	LM_ELE_ADR091	12029.8600000000006
2022-04-01	LM_WOD_ADR_B80	123.459999999999994
2022-04-01	LM_WOD_ADR_B81	43.509999999999998
2022-04-01	LM_ELE_ADR_B04	280562.190000000002
2022-04-01	LM_ELE_ADR_B05	245753.109999999986
2022-04-01	LM_ELE_ADR_B09	296830.090000000026
2022-04-01	LM_ELE_ADR_B01	0
2022-04-01	LM_ELE_ADR_B10	30132.7299999999996
2022-04-01	LM_ELE_ADR_B02	0
2022-04-01	LM_LC_ADR_B18	18.4299999999999997
2022-04-01	LM_LC_ADR_B20	69.5100000000000051
2022-04-01	LM_LC_ADR_B22	55.3699999999999974
2022-04-01	LM_LC_ADR_B24	10.6600000000000001
2022-04-01	LM_LC_ADR_B31	445.100000000000023
2022-04-01	LM_LC_ADR_B41	509.899999999999977
2022-04-01	LM_LC_ADR_B43	8.40000000000000036
2022-04-01	LM_LH_ADR_B23	68.2999999999999972
2022-04-01	LM_LH_ADR_B25	61.1000000000000014
2022-04-01	LM_LH_ADR_B27	146.699999999999989
2022-04-01	LM_LH_ADR_B35	0
2022-04-01	LM_LH_ADR_B36	0
2022-04-01	LM_LH_ADR_B38	72.2999999999999972
2022-04-01	LM_LH_ADR_B44	4.5
2022-04-01	LM_WOD_ADR_B76	1736.78999999999996
2022-04-01	LM_WOD_ADR_B77	8.96000000000000085
2022-04-01	LM_LC_ADR_B16	38.8200000000000003
2022-04-01	LM_LH_ADR_B17	50.2999999999999972
2022-04-01	LM_WOD_ADR_B79	360.110000000000014
2022-04-01	LM_ELE_ADR_B12	18207.5099999999984
2022-04-01	LM_ELE_ADR_B13	15053.1900000000005
2022-04-01	LM_LC_ADR_B46	56.3999999999999986
2022-04-01	LM_LC_ADR193	0
2022-04-01	LM_ELE_ADR125	4948.60000000000036
2022-04-01	LM_ELE_ADR069	299740
2022-04-01	LM_ELE_ADR075	10852
2022-04-01	LM_LC_ADR159	5030
2022-04-01	LM_LC_ADR160	11180
2022-04-01	zdemontowany580	6
2022-04-01	zdemontowany600	3194
2022-04-01	LM_LH_ADR229	84.9000000000000057
2022-05-01	LM_LC_ADR170	57.3599999999999994
2022-05-01	LM_LC_ADR172	134.960000000000008
2022-05-01	LM_LC_ADR179	88.0999999999999943
2022-05-01	LM_ELE_ADR021	284290.440000000002
2022-05-01	LM_ELE_ADR078	55609
2022-05-01	LM_ELE_ADR066	0
2022-05-01	LM_ELE_ADR080	175085.220000000001
2022-05-01	LM_LH_ADR199	146.699999999999989
2022-05-01	LM_ELE_ADR115	27049.5299999999988
2022-05-01	LM_WOD_ADR249_Solution Space	109.939999999999998
2022-05-01	LM_WOD_MAIN_W	0
2022-05-01	LM_LC_ADR123	544.700000000000045
2022-05-01	LM_LC_ADR151	31238
2022-05-01	LM_LC_ADR153	10605
2022-05-01	LM_LC_ADR154	2724.40000000000009
2022-05-01	LM_LC_ADR155	7184.80000000000018
2022-05-01	LM_LC_ADR157	1130.90000000000009
2022-05-01	LM_LC_ADR158	369.699999999999989
2022-05-01	LM_LC_ADR162	811.399999999999977
2022-05-01	LM_LC_ADR168	120.400000000000006
2022-05-01	LM_LC_ADR173	102.730000000000004
2022-05-01	LM_LC_ADR174	218.740000000000009
2022-05-01	LM_LC_ADR175	0
2022-05-01	LM_LC_ADR176	85.7000000000000028
2022-05-01	LM_LC_ADR178	140.75
2022-05-01	LM_LC_ADR184	45.0600000000000023
2022-05-01	LM_LC_ADR186	19.2300000000000004
2022-05-01	LM_LC_ADR187	32.6899999999999977
2022-05-01	LM_LC_ADR209	96.9500000000000028
2022-05-01	LM_LC_ADR82	29.3900000000000006
2022-05-01	LM_LH_ADR122	16.5
2022-05-01	LM_LH_ADR189	60.8999999999999986
2022-05-01	LM_LH_ADR195	437.699999999999989
2022-05-01	LM_LH_ADR196	9
2022-05-01	LM_LH_ADR198	1261.5
2022-05-01	LM_LH_ADR200	48.1000000000000014
2022-05-01	LM_LH_ADR203	224.400000000000006
2022-05-01	LM_LH_ADR204	102.5
2022-05-01	LM_LH_ADR208	327.5
2022-05-01	LM_LH_ADR211	39.7000000000000028
2022-05-01	LM_LH_ADR212	202
2022-05-01	LM_LH_ADR216	36.6799999999999997
2022-05-01	LM_LH_ADR218	442
2022-05-01	LM_LH_ADR221	359.800000000000011
2022-05-01	LM_LH_ADR222	0
2022-05-01	LM_LH_ADR227	41.2000000000000028
2022-05-01	LM_LH_ADR229	0
2022-05-01	LM_LH_ADR231	0
2022-05-01	LM_LH_ADR234	0
2022-05-01	LM_LH_ADR235	87.5
2022-05-01	LM_LH_ADR33	0
2022-05-01	LM_ELE_ADR008	104387.919999999998
2022-05-01	LM_ELE_ADR012	93689.1000000000058
2022-05-01	LM_ELE_ADR017	13060.9300000000003
2022-05-01	LM_ELE_ADR019	4038.55999999999995
2022-05-01	LM_ELE_ADR024	128487.449999999997
2022-05-01	LM_ELE_ADR027	36284.1900000000023
2022-05-01	LM_LC_ADR163	31.0599999999999987
2022-05-01	LM_LC_ADR164	0.0200000000000000004
2022-05-01	LM_LH_ADR201	96
2022-05-01	LM_ELE_ADR029	13886.4099999999999
2022-05-01	LM_ELE_ADR031	192171.01999999999
2022-05-01	LM_ELE_ADR038	371132.25
2022-05-01	LM_ELE_ADR041	68303.0200000000041
2022-05-01	LM_ELE_ADR045	6028.42000000000007
2022-05-01	LM_ELE_ADR047	5469.65999999999985
2022-05-01	LM_ELE_ADR049	14863.1200000000008
2022-05-01	LM_ELE_ADR052	11254.7900000000009
2022-05-01	LM_ELE_ADR054	31233.3100000000013
2022-05-01	LM_ELE_ADR057	6197.40999999999985
2022-05-01	LM_ELE_ADR059	24139.2000000000007
2022-05-01	LM_ELE_ADR060	0
2022-05-01	LM_ELE_ADR061	0
2022-05-01	LM_ELE_ADR062	22939
2022-05-01	LM_ELE_ADR065	0
2022-05-01	LM_ELE_ADR067	266
2022-05-01	LM_ELE_ADR068	9044
2022-05-01	LM_ELE_ADR070	88
2022-05-01	LM_ELE_ADR071	81075
2022-05-01	LM_ELE_ADR073	88
2022-05-01	LM_ELE_ADR077	1063
2022-05-01	LM_ELE_ADR084	56037.260000000002
2022-05-01	LM_ELE_ADR086	15372.2600000000002
2022-05-01	LM_ELE_ADR088	40069.1500000000015
2022-05-01	LM_ELE_ADR094	1491.13000000000011
2022-05-01	LM_ELE_ADR095	103949.589999999997
2022-05-01	LM_ELE_ADR097	33045.0599999999977
2022-05-01	LM_ELE_ADR098	3568.5
2022-05-01	LM_ELE_ADR099	86102.5200000000041
2022-05-01	LM_ELE_ADR100	19275.9300000000003
2022-05-01	LM_ELE_ADR101	8009.68000000000029
2022-05-01	LM_ELE_ADR111	362.620000000000005
2022-05-01	LM_ELE_ADR116	15111.4699999999993
2022-05-01	LM_ELE_ADR118	21344.0600000000013
2022-05-01	LM_ELE_ADR119	76554.3600000000006
2022-05-01	LM_ELE_ADR120	91540.929999999993
2022-05-01	LM_WOD_ADR129	123.090000000000003
2022-05-01	LM_WOD_ADR140	123.010000000000005
2022-05-01	LM_WOD_ADR147	61.8699999999999974
2022-05-01	LM_WOD_ADR246_Solution Space	562.389999999999986
2022-05-01	LM_WOD_ADR248_Solution Space	48.2700000000000031
2022-05-01	LM_ELE_ADR_B03	130512.449999999997
2022-05-01	LM_ELE_ADR_B07	103733.949999999997
2022-05-01	LM_ELE_ADR_B08	154235.859999999986
2022-05-01	LM_LC_ADR_B26	170.990000000000009
2022-05-01	LM_LC_ADR_B30	449.5
2022-05-01	LM_LC_ADR_B32	989.799999999999955
2022-05-01	LM_LC_ADR_B33	894.299999999999955
2022-05-01	LM_LH_ADR_B19	103.200000000000003
2022-05-01	LM_LH_ADR_B21	199.5
2022-05-01	LM_LH_ADR_B34	0
2022-05-01	LM_LH_ADR_B37	0.400000000000000022
2022-05-01	LM_LH_ADR_B39	98
2022-05-01	LM_LH_ADR_B40	165.099999999999994
2022-05-01	LM_LH_ADR_B42	0
2022-05-01	LM_WOD_ADR_B78	192.830000000000013
2022-05-01	LM_LC_ADR102	55.2999999999999972
2022-05-01	LM_LC_ADR103	60.9399999999999977
2022-05-01	LM_LC_ADR104	82.3799999999999955
2022-05-01	LM_LC_ADR152	5133
2022-05-01	LM_LC_ADR149	0.910000000000000031
2022-05-01	LM_LC_ADR156	3645.09999999999991
2022-05-01	LM_LC_ADR171	306.519999999999982
2022-05-01	LM_LC_ADR165	51.0399999999999991
2022-05-01	LM_LC_ADR166	40.0600000000000023
2022-05-01	LM_LC_ADR180	147.990000000000009
2022-05-01	LM_LC_ADR181	0.100000000000000006
2022-05-01	LM_LC_ADR182	93.3900000000000006
2022-05-01	LM_LC_ADR183	1.41999999999999993
2022-05-01	LM_LC_ADR185	19.25
2022-05-01	LM_LC_ADR161	1480.90000000000009
2022-05-01	LM_LC_ADR224	173.849999999999994
2022-05-01	LM_LC_ADR89	39.4500000000000028
2022-05-01	LM_LC_ADR93	38.9699999999999989
2022-05-01	LM_LH_ADR145	10.0700000000000003
2022-05-01	LM_LH_ADR188	32.1799999999999997
2022-05-01	LM_LH_ADR190	7.88999999999999968
2022-05-01	LM_LH_ADR191	18.8000000000000007
2022-05-01	LM_LH_ADR192	0
2022-05-01	LM_LH_ADR194	0
2022-05-01	LM_LH_ADR207	421
2022-05-01	LM_LH_ADR197	1284.40000000000009
2022-05-01	LM_LH_ADR215	0
2022-05-01	LM_LH_ADR219	0.0299999999999999989
2022-05-01	LM_LH_ADR220	112.200000000000003
2022-05-01	LM_LH_ADR223	190.900000000000006
2022-05-01	LM_LH_ADR225	71.5999999999999943
2022-05-01	LM_LH_ADR226	83.6899999999999977
2022-05-01	LM_LH_ADR217	510.199999999999989
2022-05-01	LM_LH_ADR228	29.8999999999999986
2022-05-01	LM_LH_ADR232	60.4799999999999969
2022-05-01	LM_LH_ADR233	46
2022-05-01	LM_LH_ADR230	1.69999999999999996
2022-05-01	LM_ELE_ADR114	284250.809999999998
2022-05-01	LM_ELE_ADR117	22617.5600000000013
2022-05-01	LM_WOD_ADR132	304.20999999999998
2022-05-01	LM_WOD_ADR133	350.54000000000002
2022-05-01	LM_WOD_ADR134	18.870000000000001
2022-05-01	LM_WOD_ADR135	0
2022-05-01	LM_WOD_ADR136	70.8799999999999955
2022-05-01	LM_WOD_ADR139	1483.48000000000002
2022-05-01	LM_WOD_ADR141	17
2022-05-01	LM_WOD_ADR142	36
2022-05-01	LM_WOD_ADR143	557.389999999999986
2022-05-01	LM_WOD_ADR146	30945.5999999999985
2022-05-01	LM_WOD_ADR148	0.0200000000000000004
2022-05-01	LM_WOD_ADR150	42.5700000000000003
2022-05-01	LM_WOD_ADR237	924.279999999999973
2022-05-01	LM_WOD_ADR238	2543.96000000000004
2022-05-01	LM_WOD_ADR239	36.1899999999999977
2022-05-01	LM_WOD_ADR240	139.030000000000001
2022-05-01	LM_WOD_ADR241	168.180000000000007
2022-05-01	LM_ELE_ADR121	206125.859999999986
2022-05-01	LM_ELE_ADR128	0
2022-05-01	LM_WOD_ADR247_Solution Space	600.830000000000041
2022-05-01	LM_WOD_ADR250_Solution Space	208.110000000000014
2022-05-01	LM_WOD_ADR30	0
2022-05-01	LM_ELE_ADR001	69794.8899999999994
2022-05-01	LM_ELE_ADR002	90834.2700000000041
2022-05-01	LM_ELE_ADR003	122790.720000000001
2022-05-01	LM_ELE_ADR006	0
2022-05-01	LM_ELE_ADR007	143000.380000000005
2022-05-01	LM_ELE_ADR009	191555.799999999988
2022-05-01	LM_ELE_ADR011	174874.690000000002
2022-05-01	LM_ELE_ADR013	230167.98000000001
2022-05-01	LM_ELE_ADR014	15032.8199999999997
2022-05-01	LM_ELE_ADR015	134669.660000000003
2022-05-01	LM_ELE_ADR016	957208.439999999944
2022-05-01	LM_ELE_ADR018	13461.6800000000003
2022-05-01	LM_ELE_ADR020	139931.410000000003
2022-05-01	LM_ELE_ADR022	164685.339999999997
2022-05-01	LM_ELE_ADR023	35150.3300000000017
2022-05-01	LM_ELE_ADR025	557444.75
2022-05-01	LM_ELE_ADR028	19603.880000000001
2022-05-01	LM_ELE_ADR034	29979.9900000000016
2022-05-01	LM_ELE_ADR036	92688.0200000000041
2022-05-01	LM_ELE_ADR039	376073.909999999974
2022-05-01	LM_ELE_ADR040	36656.9000000000015
2022-05-01	LM_ELE_ADR042	3562.76999999999998
2022-05-01	LM_ELE_ADR044	6887.9399999999996
2022-05-01	LM_ELE_ADR048	7248.93000000000029
2022-05-01	LM_ELE_ADR051	6957.28999999999996
2022-05-01	LM_ELE_ADR053	26274.2400000000016
2022-05-01	LM_ELE_ADR055	5742.39000000000033
2022-05-01	LM_ELE_ADR056	0
2022-05-01	LM_ELE_ADR063	190
2022-05-01	LM_ELE_ADR064	0
2022-05-01	LM_ELE_ADR058	83960.3699999999953
2022-05-01	LM_ELE_ADR072	27267
2022-05-01	LM_ELE_ADR074	81075
2022-05-01	LM_ELE_ADR076	0
2022-05-01	LM_ELE_ADR081	66878.6600000000035
2022-05-01	LM_ELE_ADR085	58201.6100000000006
2022-05-01	LM_ELE_ADR090	39702.8399999999965
2022-05-01	LM_ELE_ADR107	87654.1900000000023
2022-05-01	LM_ELE_ADR108	6649.51000000000022
2022-05-01	LM_ELE_ADR109	2016.21000000000004
2022-05-01	LM_ELE_ADR110	414.139999999999986
2022-05-01	LM_ELE_ADR113	55051.6600000000035
2022-05-01	LM_ELE_ADR087	90269.4900000000052
2022-05-01	LM_LC_ADR_B45	220.879999999999995
2022-05-01	LM_LH_ADR_B46	49.3500000000000014
2022-05-01	LM_LH_ADR_B47	120
2022-05-01	LM_WOD_ADR_B74	36.9600000000000009
2022-05-01	LM_ELE_ADR_B06	476119.75
2022-05-01	LM_ELE_ADR046	0
2022-05-01	LM_ELE_ADR010	120885.589999999997
2022-05-01	LM_ELE_ADR043	2869.09999999999991
2022-05-01	LM_ELE_ADR_B11	33946.3000000000029
2022-05-01	LM_WOD_ADR242	43.4699999999999989
2022-05-01	LM_ELE_ADR124	110786.199999999997
2022-05-01	LM_ELE_ADR112	734826
2022-05-01	LM_WOD_ADR_B75	182.97999999999999
2022-05-01	LM_ELE_ADR091	12433.9099999999999
2022-05-01	LM_WOD_ADR_B80	127.510000000000005
2022-05-01	LM_WOD_ADR_B81	44.6799999999999997
2022-05-01	LM_ELE_ADR_B04	283434.059999999998
2022-05-01	LM_ELE_ADR_B05	251748.329999999987
2022-05-01	LM_ELE_ADR_B09	301870.780000000028
2022-05-01	LM_ELE_ADR_B01	0
2022-05-01	LM_ELE_ADR_B10	30829.0699999999997
2022-05-01	LM_ELE_ADR_B02	0
2022-05-01	LM_LC_ADR_B18	18.6900000000000013
2022-05-01	LM_LC_ADR_B20	69.7399999999999949
2022-05-01	LM_LC_ADR_B22	56.3800000000000026
2022-05-01	LM_LC_ADR_B24	10.6600000000000001
2022-05-01	LM_LC_ADR_B31	461.899999999999977
2022-05-01	LM_LC_ADR_B41	525.100000000000023
2022-05-01	LM_LC_ADR_B43	8.80000000000000071
2022-05-01	LM_LH_ADR_B23	69.9000000000000057
2022-05-01	LM_LH_ADR_B25	65.5999999999999943
2022-05-01	LM_LH_ADR_B27	160.900000000000006
2022-05-01	LM_LH_ADR_B35	0
2022-05-01	LM_LH_ADR_B36	0
2022-05-01	LM_LH_ADR_B38	72.5
2022-05-01	LM_LH_ADR_B44	4.5
2022-05-01	LM_WOD_ADR_B76	1736.78999999999996
2022-05-01	LM_WOD_ADR_B77	8.96000000000000085
2022-05-01	LM_LC_ADR_B16	38.8200000000000003
2022-05-01	LM_LH_ADR_B17	51.1000000000000014
2022-05-01	LM_WOD_ADR_B79	360.110000000000014
2022-05-01	LM_ELE_ADR_B12	18656.4000000000015
2022-05-01	LM_ELE_ADR_B13	15053.1900000000005
2022-05-01	LM_LC_ADR_B46	58.6199999999999974
2022-05-01	LM_LC_ADR193	0
2022-05-01	LM_ELE_ADR125	5015.06999999999971
2022-05-01	LM_ELE_ADR069	306807
2022-05-01	LM_ELE_ADR075	11167
2022-05-01	LM_LC_ADR159	5030
2022-05-01	LM_LC_ADR160	12630
2022-05-01	LM_LH_ADR167	2050
2022-05-01	LM_WOD_ADR236	12.9100000000000001
2022-05-01	zdemontowany580	6
2022-05-01	zdemontowany600	3194
2022-06-01	LM_LC_ADR170	57.3800000000000026
2022-06-01	LM_LC_ADR172	136.069999999999993
2022-06-01	LM_LC_ADR179	88.4000000000000057
2022-06-01	LM_ELE_ADR021	287369.659999999974
2022-06-01	LM_ELE_ADR078	56598
2022-06-01	LM_ELE_ADR066	0
2022-06-01	LM_ELE_ADR080	177349.309999999998
2022-06-01	LM_LH_ADR199	147.400000000000006
2022-06-01	LM_ELE_ADR115	27662.3499999999985
2022-06-01	LM_WOD_ADR249_Solution Space	113.019999999999996
2022-06-01	LM_WOD_MAIN_W	0
2022-06-01	LM_LC_ADR123	546.600000000000023
2022-06-01	LM_LC_ADR151	31348
2022-06-01	LM_LC_ADR153	10636
2022-06-01	LM_LC_ADR154	2748.5
2022-06-01	LM_LC_ADR155	7211.5
2022-06-01	LM_LC_ADR157	1135
2022-06-01	LM_LC_ADR158	370.699999999999989
2022-06-01	LM_LC_ADR162	812.700000000000045
2022-06-01	LM_LC_ADR168	120.5
2022-06-01	LM_LC_ADR173	103.209999999999994
2022-06-01	LM_LC_ADR174	222.819999999999993
2022-06-01	LM_LC_ADR175	0
2022-06-01	LM_LC_ADR176	85.9000000000000057
2022-06-01	LM_LC_ADR178	142.360000000000014
2022-06-01	LM_LC_ADR184	45.2299999999999969
2022-06-01	LM_LC_ADR186	19.2300000000000004
2022-06-01	LM_LC_ADR187	32.6899999999999977
2022-06-01	LM_LC_ADR209	96.9500000000000028
2022-06-01	LM_LC_ADR32	0
2022-06-01	LM_LC_ADR82	30.5199999999999996
2022-06-01	LM_LH_ADR122	17.8999999999999986
2022-06-01	LM_LH_ADR189	61.7100000000000009
2022-06-01	LM_LH_ADR195	442.100000000000023
2022-06-01	LM_LH_ADR196	9
2022-06-01	LM_LH_ADR198	1285.29999999999995
2022-06-01	LM_LH_ADR200	49.1000000000000014
2022-06-01	LM_LH_ADR203	226.300000000000011
2022-06-01	LM_LH_ADR204	104.200000000000003
2022-06-01	LM_LH_ADR208	333.5
2022-06-01	LM_LH_ADR211	41.1000000000000014
2022-06-01	LM_LH_ADR212	210.099999999999994
2022-06-01	LM_LH_ADR216	36.6799999999999997
2022-06-01	LM_LH_ADR218	452.199999999999989
2022-06-01	LM_LH_ADR221	372.300000000000011
2022-06-01	LM_LH_ADR222	0
2022-06-01	LM_LH_ADR227	41.2000000000000028
2022-06-01	LM_LH_ADR229	0
2022-06-01	LM_LH_ADR231	0
2022-06-01	LM_LH_ADR234	0
2022-06-01	LM_LH_ADR235	88.9000000000000057
2022-06-01	LM_LH_ADR33	0
2022-06-01	LM_ELE_ADR008	105849.910000000003
2022-06-01	LM_ELE_ADR012	94597.8099999999977
2022-06-01	LM_ELE_ADR017	13267.1299999999992
2022-06-01	LM_ELE_ADR019	4038.55999999999995
2022-06-01	LM_ELE_ADR024	130399.059999999998
2022-06-01	LM_ELE_ADR027	36475.9100000000035
2022-06-01	LM_LC_ADR163	31.0599999999999987
2022-06-01	LM_LC_ADR164	0.0200000000000000004
2022-06-01	LM_LH_ADR201	100.700000000000003
2022-06-01	LM_ELE_ADR029	14262.2000000000007
2022-06-01	LM_ELE_ADR031	194718.309999999998
2022-06-01	LM_ELE_ADR038	377873.159999999974
2022-06-01	LM_ELE_ADR041	68877.9499999999971
2022-06-01	LM_ELE_ADR045	6134.90999999999985
2022-06-01	LM_ELE_ADR047	5503.57999999999993
2022-06-01	LM_ELE_ADR049	15040.7399999999998
2022-06-01	LM_ELE_ADR052	11401.4599999999991
2022-06-01	LM_ELE_ADR054	31616.3199999999997
2022-06-01	LM_ELE_ADR057	6281.51000000000022
2022-06-01	LM_ELE_ADR059	24532.3400000000001
2022-06-01	LM_ELE_ADR060	0
2022-06-01	LM_ELE_ADR061	0
2022-06-01	LM_ELE_ADR062	23518
2022-06-01	LM_ELE_ADR065	0
2022-06-01	LM_ELE_ADR067	266
2022-06-01	LM_ELE_ADR068	9957
2022-06-01	LM_ELE_ADR070	88
2022-06-01	LM_ELE_ADR071	82597
2022-06-01	LM_ELE_ADR073	88
2022-06-01	LM_ELE_ADR077	1063
2022-06-01	LM_ELE_ADR084	56602.4100000000035
2022-06-01	LM_ELE_ADR086	15778.7399999999998
2022-06-01	LM_ELE_ADR088	40777.6399999999994
2022-06-01	LM_ELE_ADR094	1493.8900000000001
2022-06-01	LM_ELE_ADR095	105679.880000000005
2022-06-01	LM_ELE_ADR097	33997.25
2022-06-01	LM_ELE_ADR098	3626.88000000000011
2022-06-01	LM_ELE_ADR099	88164.1999999999971
2022-06-01	LM_ELE_ADR100	19656.1899999999987
2022-06-01	LM_ELE_ADR101	8167.63000000000011
2022-06-01	LM_ELE_ADR111	362.620000000000005
2022-06-01	LM_ELE_ADR116	15133.6399999999994
2022-06-01	LM_ELE_ADR118	21585.5099999999984
2022-06-01	LM_ELE_ADR119	77653.1600000000035
2022-06-01	LM_ELE_ADR120	93691.6900000000023
2022-06-01	LM_WOD_ADR129	126.060000000000002
2022-06-01	LM_WOD_ADR140	123.310000000000002
2022-06-01	LM_WOD_ADR147	62.6000000000000014
2022-06-01	LM_WOD_ADR246_Solution Space	576.409999999999968
2022-06-01	LM_WOD_ADR248_Solution Space	49.990000000000002
2022-06-01	LM_ELE_ADR_B03	132042.220000000001
2022-06-01	LM_ELE_ADR_B07	105023.559999999998
2022-06-01	LM_ELE_ADR_B08	156166.809999999998
2022-06-01	LM_LC_ADR_B26	171.129999999999995
2022-06-01	LM_LC_ADR_B30	451.100000000000023
2022-06-01	LM_LC_ADR_B32	993.100000000000023
2022-06-01	LM_LC_ADR_B33	897.700000000000045
2022-06-01	LM_LH_ADR_B19	104.900000000000006
2022-06-01	LM_LH_ADR_B21	202.400000000000006
2022-06-01	LM_LH_ADR_B34	0
2022-06-01	LM_LH_ADR_B37	0.400000000000000022
2022-06-01	LM_LH_ADR_B39	99.5999999999999943
2022-06-01	LM_LH_ADR_B40	167.900000000000006
2022-06-01	LM_LH_ADR_B42	0
2022-06-01	LM_WOD_ADR_B78	194.810000000000002
2022-06-01	LM_LC_ADR102	55.8299999999999983
2022-06-01	LM_LC_ADR103	61.509999999999998
2022-06-01	LM_LC_ADR104	83.2999999999999972
2022-06-01	LM_LC_ADR152	5148.19999999999982
2022-06-01	LM_LC_ADR149	0.910000000000000031
2022-06-01	LM_LC_ADR156	3666.59999999999991
2022-06-01	LM_LC_ADR171	307.819999999999993
2022-06-01	LM_LC_ADR165	51.6199999999999974
2022-06-01	LM_LC_ADR166	40.4699999999999989
2022-06-01	LM_LC_ADR180	147.990000000000009
2022-06-01	LM_LC_ADR181	0.100000000000000006
2022-06-01	LM_LC_ADR182	93.4000000000000057
2022-06-01	LM_LC_ADR183	1.41999999999999993
2022-06-01	LM_LC_ADR185	19.25
2022-06-01	LM_LC_ADR161	1486.59999999999991
2022-06-01	LM_LC_ADR224	175.719999999999999
2022-06-01	LM_LC_ADR89	39.9299999999999997
2022-06-01	LM_LC_ADR93	39.4500000000000028
2022-06-01	LM_LH_ADR145	10.0700000000000003
2022-06-01	LM_LH_ADR188	32.1799999999999997
2022-06-01	LM_LH_ADR190	7.88999999999999968
2022-06-01	LM_LH_ADR191	18.8000000000000007
2022-06-01	LM_LH_ADR192	0
2022-06-01	LM_LH_ADR194	0
2022-06-01	LM_LH_ADR207	424.199999999999989
2022-06-01	LM_LH_ADR197	1297
2022-06-01	LM_LH_ADR215	0
2022-06-01	LM_LH_ADR219	0.0299999999999999989
2022-06-01	LM_LH_ADR220	112.200000000000003
2022-06-01	LM_LH_ADR223	196.300000000000011
2022-06-01	LM_LH_ADR225	71.5999999999999943
2022-06-01	LM_LH_ADR226	83.7600000000000051
2022-06-01	LM_LH_ADR217	517.399999999999977
2022-06-01	LM_LH_ADR228	30.6999999999999993
2022-06-01	LM_LH_ADR232	61.6799999999999997
2022-06-01	LM_LH_ADR233	46.6000000000000014
2022-06-01	LM_LH_ADR230	1.69999999999999996
2022-06-01	LM_ELE_ADR114	289638.25
2022-06-01	LM_ELE_ADR117	22632.7099999999991
2022-06-01	LM_WOD_ADR132	308.089999999999975
2022-06-01	LM_WOD_ADR133	353.889999999999986
2022-06-01	LM_WOD_ADR134	18.9499999999999993
2022-06-01	LM_WOD_ADR135	0
2022-06-01	LM_WOD_ADR136	71.5600000000000023
2022-06-01	LM_WOD_ADR139	1522.07999999999993
2022-06-01	LM_WOD_ADR141	17
2022-06-01	LM_WOD_ADR142	36
2022-06-01	LM_WOD_ADR143	580.049999999999955
2022-06-01	LM_WOD_ADR146	31510.4000000000015
2022-06-01	LM_WOD_ADR148	0.0299999999999999989
2022-06-01	LM_WOD_ADR150	43.2700000000000031
2022-06-01	LM_WOD_ADR237	924.460000000000036
2022-06-01	LM_WOD_ADR238	2543.96000000000004
2022-06-01	LM_WOD_ADR239	36.7999999999999972
2022-06-01	LM_WOD_ADR240	143.849999999999994
2022-06-01	LM_WOD_ADR241	233.289999999999992
2022-06-01	LM_ELE_ADR121	213389.630000000005
2022-06-01	LM_ELE_ADR128	0
2022-06-01	LM_WOD_ADR247_Solution Space	617.779999999999973
2022-06-01	LM_WOD_ADR250_Solution Space	213.189999999999998
2022-06-01	LM_WOD_ADR30	0
2022-06-01	LM_ELE_ADR001	70882.25
2022-06-01	LM_ELE_ADR002	91919.2899999999936
2022-06-01	LM_ELE_ADR003	124008.520000000004
2022-06-01	LM_ELE_ADR006	0
2022-06-01	LM_ELE_ADR007	143716.089999999997
2022-06-01	LM_ELE_ADR009	195924.26999999999
2022-06-01	LM_ELE_ADR011	177425.910000000003
2022-06-01	LM_ELE_ADR013	234331.380000000005
2022-06-01	LM_ELE_ADR014	15295.7099999999991
2022-06-01	LM_ELE_ADR015	136655.910000000003
2022-06-01	LM_ELE_ADR016	966111.380000000005
2022-06-01	LM_ELE_ADR018	13649.8899999999994
2022-06-01	LM_ELE_ADR020	141309.420000000013
2022-06-01	LM_ELE_ADR022	169589.160000000003
2022-06-01	LM_ELE_ADR023	36072.6500000000015
2022-06-01	LM_ELE_ADR025	577498.189999999944
2022-06-01	LM_ELE_ADR028	19785.3300000000017
2022-06-01	LM_ELE_ADR034	30853.1899999999987
2022-06-01	LM_ELE_ADR036	93461.2200000000012
2022-06-01	LM_ELE_ADR039	380373
2022-06-01	LM_ELE_ADR040	36656.9000000000015
2022-06-01	LM_ELE_ADR042	3609.07000000000016
2022-06-01	LM_ELE_ADR044	6975.30000000000018
2022-06-01	LM_ELE_ADR048	7341.32999999999993
2022-06-01	LM_ELE_ADR051	7043.82999999999993
2022-06-01	LM_ELE_ADR053	27811.2299999999996
2022-06-01	LM_ELE_ADR055	5816.13000000000011
2022-06-01	LM_ELE_ADR056	0
2022-06-01	LM_ELE_ADR063	190
2022-06-01	LM_ELE_ADR064	0
2022-06-01	LM_ELE_ADR058	85061.0200000000041
2022-06-01	LM_ELE_ADR072	27851
2022-06-01	LM_ELE_ADR074	82597
2022-06-01	LM_ELE_ADR076	0
2022-06-01	LM_ELE_ADR081	68469.75
2022-06-01	LM_ELE_ADR085	59896.4400000000023
2022-06-01	LM_ELE_ADR090	40898.8600000000006
2022-06-01	LM_ELE_ADR107	89415.070000000007
2022-06-01	LM_ELE_ADR108	6939.9399999999996
2022-06-01	LM_ELE_ADR109	2016.78999999999996
2022-06-01	LM_ELE_ADR110	414.45999999999998
2022-06-01	LM_ELE_ADR113	55983.8399999999965
2022-06-01	LM_ELE_ADR087	91239.6199999999953
2022-06-01	LM_LC_ADR_B45	222.199999999999989
2022-06-01	LM_LH_ADR_B46	49.3500000000000014
2022-06-01	LM_LH_ADR_B47	122
2022-06-01	LM_WOD_ADR_B74	37.8500000000000014
2022-06-01	LM_ELE_ADR_B06	488731.340000000026
2022-06-01	LM_ELE_ADR046	0
2022-06-01	LM_ELE_ADR010	122330.970000000001
2022-06-01	LM_ELE_ADR043	2910.7800000000002
2022-06-01	LM_ELE_ADR_B11	34595.7200000000012
2022-06-01	LM_WOD_ADR242	44.2199999999999989
2022-06-01	LM_ELE_ADR124	115237.589999999997
2022-06-01	LM_ELE_ADR112	740775
2022-06-01	LM_WOD_ADR_B75	184.580000000000013
2022-06-01	LM_ELE_ADR091	12715.0499999999993
2022-06-01	LM_WOD_ADR_B80	130.560000000000002
2022-06-01	LM_WOD_ADR_B81	45.6400000000000006
2022-06-01	LM_ELE_ADR_B04	283892.090000000026
2022-06-01	LM_ELE_ADR_B05	258105.329999999987
2022-06-01	LM_ELE_ADR_B09	304934.659999999974
2022-06-01	LM_ELE_ADR_B01	0
2022-06-01	LM_ELE_ADR_B10	31313.130000000001
2022-06-01	LM_ELE_ADR_B02	0
2022-06-01	LM_LC_ADR_B18	18.7800000000000011
2022-06-01	LM_LC_ADR_B20	69.8100000000000023
2022-06-01	LM_LC_ADR_B22	56.3800000000000026
2022-06-01	LM_LC_ADR_B24	10.6899999999999995
2022-06-01	LM_LC_ADR_B31	464.5
2022-06-01	LM_LC_ADR_B41	528.600000000000023
2022-06-01	LM_LC_ADR_B43	9
2022-06-01	LM_LH_ADR_B23	71.7999999999999972
2022-06-01	LM_LH_ADR_B25	71.0999999999999943
2022-06-01	LM_LH_ADR_B27	161.5
2022-06-01	LM_LH_ADR_B35	0
2022-06-01	LM_LH_ADR_B36	0
2022-06-01	LM_LH_ADR_B38	72.7000000000000028
2022-06-01	LM_LH_ADR_B44	4.5
2022-06-01	LM_WOD_ADR_B76	1739.8599999999999
2022-06-01	LM_WOD_ADR_B77	8.97000000000000064
2022-06-01	LM_LC_ADR_B16	38.8200000000000003
2022-06-01	LM_LH_ADR_B17	53.1000000000000014
2022-06-01	LM_WOD_ADR_B79	360.110000000000014
2022-06-01	LM_ELE_ADR_B12	18935.2000000000007
2022-06-01	LM_ELE_ADR_B13	15053.1900000000005
2022-06-01	LM_LC_ADR_B46	58.8699999999999974
2022-06-01	LM_LC_ADR193	0
2022-06-01	LM_ELE_ADR125	5060.14999999999964
2022-06-01	LM_ELE_ADR069	311232
2022-06-01	LM_ELE_ADR075	11416
2022-06-01	LM_LC_ADR159	5030
2022-06-01	LM_LC_ADR160	13080
2022-06-01	LM_LH_ADR167	3420
2022-06-01	LM_WOD_ADR236	14.5299999999999994
2022-06-01	zdemontowany580	6
2022-06-01	zdemontowany600	3194
2022-11-01	LM_LC_ADR170	58.6799999999999997
2022-11-01	LM_LC_ADR172	138.639999999999986
2022-11-01	LM_LC_ADR179	90.5600000000000023
2022-11-01	LM_ELE_ADR021	309934.719999999972
2022-11-01	LM_ELE_ADR078	60263
2022-11-01	LM_ELE_ADR066	0
2022-11-01	LM_ELE_ADR080	190751.529999999999
2022-11-01	LM_LH_ADR199	162.800000000000011
2022-11-01	LM_ELE_ADR115	29473.1399999999994
2022-11-01	LM_WOD_ADR249_Solution Space	136.580000000000013
2022-11-01	LM_WOD_MAIN_W	0
2022-11-01	LM_LC_ADR123	553.899999999999977
2022-11-01	LM_LC_ADR151	31921
2022-11-01	LM_LC_ADR153	10749
2022-11-01	LM_LC_ADR154	2862.30000000000018
2022-11-01	LM_LC_ADR155	7394.60000000000036
2022-11-01	LM_LC_ADR157	1168.59999999999991
2022-11-01	LM_LC_ADR158	381
2022-11-01	LM_LC_ADR162	830
2022-11-01	LM_LC_ADR168	129.099999999999994
2022-11-01	LM_LC_ADR173	106.109999999999999
2022-11-01	LM_LC_ADR174	239.97999999999999
2022-11-01	LM_LC_ADR175	0
2022-11-01	LM_LC_ADR176	85.9000000000000057
2022-11-01	LM_LC_ADR178	150.060000000000002
2022-11-01	LM_LC_ADR184	45.2299999999999969
2022-11-01	LM_LC_ADR186	19.2300000000000004
2022-11-01	LM_LC_ADR187	32.6899999999999977
2022-11-01	LM_LC_ADR209	0
2022-11-01	LM_LC_ADR32	0
2022-11-01	LM_LC_ADR82	36.0200000000000031
2022-11-01	LM_LH_ADR122	22.3000000000000007
2022-11-01	LM_LH_ADR189	76.4699999999999989
2022-11-01	LM_LH_ADR195	532.100000000000023
2022-11-01	LM_LH_ADR196	9
2022-11-01	LM_LH_ADR198	0
2022-11-01	LM_LH_ADR200	55.3999999999999986
2022-11-01	LM_LH_ADR203	242.5
2022-11-01	LM_LH_ADR204	119.900000000000006
2022-11-01	LM_LH_ADR208	372.199999999999989
2022-11-01	LM_LH_ADR211	50.2999999999999972
2022-11-01	LM_LH_ADR212	260.399999999999977
2022-11-01	LM_LH_ADR216	41.3100000000000023
2022-11-01	LM_LH_ADR218	540.100000000000023
2022-11-01	LM_LH_ADR221	449.300000000000011
2022-11-01	LM_LH_ADR222	0
2022-11-01	LM_LH_ADR227	53.7999999999999972
2022-11-01	LM_LH_ADR229	0
2022-11-01	LM_LH_ADR231	0
2022-11-01	LM_LH_ADR234	0
2022-11-01	LM_LH_ADR235	104.599999999999994
2022-11-01	LM_LH_ADR33	0
2022-11-01	LM_ELE_ADR008	115282.660000000003
2022-11-01	LM_ELE_ADR012	100419.940000000002
2022-11-01	LM_ELE_ADR017	14244.8400000000001
2022-11-01	LM_ELE_ADR019	4038.65999999999985
2022-11-01	LM_ELE_ADR024	142129.390000000014
2022-11-01	LM_ELE_ADR027	36475.9100000000035
2022-11-01	LM_LC_ADR163	31.0599999999999987
2022-11-01	LM_LC_ADR164	0.0200000000000000004
2022-11-01	LM_LH_ADR201	142.199999999999989
2022-11-01	LM_ELE_ADR029	16602.7599999999984
2022-11-01	LM_ELE_ADR031	209284.160000000003
2022-11-01	LM_ELE_ADR038	426621.809999999998
2022-11-01	LM_ELE_ADR041	71852.5500000000029
2022-11-01	LM_ELE_ADR045	6655.17000000000007
2022-11-01	LM_ELE_ADR047	5966.5
2022-11-01	LM_ELE_ADR049	16095.9799999999996
2022-11-01	LM_ELE_ADR052	12289.8099999999995
2022-11-01	LM_ELE_ADR054	34010.8399999999965
2022-11-01	LM_ELE_ADR057	6811.27999999999975
2022-11-01	LM_ELE_ADR059	26962.7599999999984
2022-11-01	LM_ELE_ADR060	0
2022-11-01	LM_ELE_ADR061	0
2022-11-01	LM_ELE_ADR062	27078
2022-11-01	LM_ELE_ADR065	0
2022-11-01	LM_ELE_ADR067	336
2022-11-01	LM_ELE_ADR068	15456
2022-11-01	LM_ELE_ADR070	88
2022-11-01	LM_ELE_ADR071	92739
2022-11-01	LM_ELE_ADR073	88
2022-11-01	LM_ELE_ADR077	1063
2022-11-01	LM_ELE_ADR084	59926.8000000000029
2022-11-01	LM_ELE_ADR086	18305.5499999999993
2022-11-01	LM_ELE_ADR088	45016.2099999999991
2022-11-01	LM_ELE_ADR094	1505.25999999999999
2022-11-01	LM_ELE_ADR095	116725.740000000005
2022-11-01	LM_ELE_ADR097	40072.0999999999985
2022-11-01	LM_ELE_ADR098	3989.48999999999978
2022-11-01	LM_ELE_ADR099	101647.320000000007
2022-11-01	LM_ELE_ADR100	21969.2799999999988
2022-11-01	LM_ELE_ADR101	9196.26000000000022
2022-11-01	LM_ELE_ADR111	362.649999999999977
2022-11-01	LM_ELE_ADR116	15151.0100000000002
2022-11-01	LM_ELE_ADR118	23070.9900000000016
2022-11-01	LM_ELE_ADR119	83890.929999999993
2022-11-01	LM_ELE_ADR120	106938.089999999997
2022-11-01	LM_WOD_ADR129	142.620000000000005
2022-11-01	LM_WOD_ADR140	124.709999999999994
2022-11-01	LM_WOD_ADR147	68.0699999999999932
2022-11-01	LM_WOD_ADR246_Solution Space	654.580000000000041
2022-11-01	LM_WOD_ADR248_Solution Space	60.2199999999999989
2022-11-01	LM_ELE_ADR_B03	141325.73000000001
2022-11-01	LM_ELE_ADR_B07	112719.259999999995
2022-11-01	LM_ELE_ADR_B08	167365.51999999999
2022-11-01	LM_LC_ADR_B26	172.780000000000001
2022-11-01	LM_LC_ADR_B30	463.899999999999977
2022-11-01	LM_LC_ADR_B32	1018.89999999999998
2022-11-01	LM_LC_ADR_B33	922.600000000000023
2022-11-01	LM_LH_ADR_B19	115.900000000000006
2022-11-01	LM_LH_ADR_B21	223.300000000000011
2022-11-01	LM_LH_ADR_B34	0
2022-11-01	LM_LH_ADR_B37	0.400000000000000022
2022-11-01	LM_LH_ADR_B39	113.900000000000006
2022-11-01	LM_LH_ADR_B40	193.099999999999994
2022-11-01	LM_LH_ADR_B42	0
2022-11-01	LM_WOD_ADR_B78	207.090000000000003
2022-11-01	LM_LC_ADR102	58.490000000000002
2022-11-01	LM_LC_ADR103	64.3700000000000045
2022-11-01	LM_LC_ADR104	88.2800000000000011
2022-11-01	LM_LC_ADR152	5246.30000000000018
2022-11-01	LM_LC_ADR149	0.910000000000000031
2022-11-01	LM_LC_ADR156	3765.59999999999991
2022-11-01	LM_LC_ADR171	313.350000000000023
2022-11-01	LM_LC_ADR165	54.2999999999999972
2022-11-01	LM_LC_ADR166	42.4500000000000028
2022-11-01	LM_LC_ADR180	149.830000000000013
2022-11-01	LM_LC_ADR181	0.100000000000000006
2022-11-01	LM_LC_ADR182	95.7099999999999937
2022-11-01	LM_LC_ADR183	1.41999999999999993
2022-11-01	LM_LC_ADR185	19.25
2022-11-01	LM_LC_ADR161	1514.90000000000009
2022-11-01	LM_LC_ADR224	185.22999999999999
2022-11-01	LM_LC_ADR89	42.2100000000000009
2022-11-01	LM_LC_ADR93	41.7100000000000009
2022-11-01	LM_LH_ADR145	10.0700000000000003
2022-11-01	LM_LH_ADR188	32.1799999999999997
2022-11-01	LM_LH_ADR190	7.88999999999999968
2022-11-01	LM_LH_ADR191	18.8000000000000007
2022-11-01	LM_LH_ADR192	0
2022-11-01	LM_LH_ADR194	0
2022-11-01	LM_LH_ADR207	460.100000000000023
2022-11-01	LM_LH_ADR197	1422
2022-11-01	LM_LH_ADR215	0
2022-11-01	LM_LH_ADR219	0.0400000000000000008
2022-11-01	LM_LH_ADR220	112.200000000000003
2022-11-01	LM_LH_ADR223	262.699999999999989
2022-11-01	LM_LH_ADR225	84.7999999999999972
2022-11-01	LM_LH_ADR226	83.8100000000000023
2022-11-01	LM_LH_ADR217	580.5
2022-11-01	LM_LH_ADR228	38.6000000000000014
2022-11-01	LM_LH_ADR232	68.7800000000000011
2022-11-01	LM_LH_ADR233	54.2999999999999972
2022-11-01	LM_LH_ADR230	1.80000000000000004
2022-11-01	LM_ELE_ADR114	328143.409999999974
2022-11-01	LM_ELE_ADR117	24018.2900000000009
2022-11-01	LM_WOD_ADR132	328.889999999999986
2022-11-01	LM_WOD_ADR133	374.600000000000023
2022-11-01	LM_WOD_ADR134	19.1400000000000006
2022-11-01	LM_WOD_ADR135	0
2022-11-01	LM_WOD_ADR136	75.9699999999999989
2022-11-01	LM_WOD_ADR139	1735.17000000000007
2022-11-01	LM_WOD_ADR141	17
2022-11-01	LM_WOD_ADR142	36
2022-11-01	LM_WOD_ADR143	582.860000000000014
2022-11-01	LM_WOD_ADR146	34631
2022-11-01	LM_WOD_ADR148	0.0200000000000000004
2022-11-01	LM_WOD_ADR150	47.5600000000000023
2022-11-01	LM_WOD_ADR237	926.259999999999991
2022-11-01	LM_WOD_ADR238	3154.34000000000015
2022-11-01	LM_WOD_ADR239	41.6400000000000006
2022-11-01	LM_WOD_ADR240	170.740000000000009
2022-11-01	LM_WOD_ADR241	495.569999999999993
2022-11-01	LM_ELE_ADR121	255737.200000000012
2022-11-01	LM_ELE_ADR128	0
2022-11-01	LM_WOD_ADR247_Solution Space	698.629999999999995
2022-11-01	LM_WOD_ADR250_Solution Space	247.469999999999999
2022-11-01	LM_WOD_ADR30	0
2022-11-01	LM_ELE_ADR001	77956.9499999999971
2022-11-01	LM_ELE_ADR002	98109.8699999999953
2022-11-01	LM_ELE_ADR003	129234.059999999998
2022-11-01	LM_ELE_ADR006	0
2022-11-01	LM_ELE_ADR007	148872.51999999999
2022-11-01	LM_ELE_ADR009	201068.299999999988
2022-11-01	LM_ELE_ADR011	181717.410000000003
2022-11-01	LM_ELE_ADR013	243142.890000000014
2022-11-01	LM_ELE_ADR014	16831.0800000000017
2022-11-01	LM_ELE_ADR015	145178.859999999986
2022-11-01	LM_ELE_ADR016	1009437.31000000006
2022-11-01	LM_ELE_ADR018	14806.3199999999997
2022-11-01	LM_ELE_ADR020	150184.76999999999
2022-11-01	LM_ELE_ADR022	189039.940000000002
2022-11-01	LM_ELE_ADR023	41706.1699999999983
2022-11-01	LM_ELE_ADR025	701734
2022-11-01	LM_ELE_ADR028	20048.8400000000001
2022-11-01	LM_ELE_ADR034	36158.8199999999997
2022-11-01	LM_ELE_ADR036	97130.7400000000052
2022-11-01	LM_ELE_ADR039	412827.659999999974
2022-11-01	LM_ELE_ADR040	36656.9000000000015
2022-11-01	LM_ELE_ADR042	3888.88999999999987
2022-11-01	LM_ELE_ADR044	7517.02000000000044
2022-11-01	LM_ELE_ADR048	7911.85000000000036
2022-11-01	LM_ELE_ADR051	7569.02999999999975
2022-11-01	LM_ELE_ADR053	35894.4499999999971
2022-11-01	LM_ELE_ADR055	6267.97000000000025
2022-11-01	LM_ELE_ADR056	0
2022-11-01	LM_ELE_ADR063	190
2022-11-01	LM_ELE_ADR064	0
2022-11-01	LM_ELE_ADR058	91723.5200000000041
2022-11-01	LM_ELE_ADR072	31151
2022-11-01	LM_ELE_ADR074	92739
2022-11-01	LM_ELE_ADR076	0
2022-11-01	LM_ELE_ADR081	73855.1999999999971
2022-11-01	LM_ELE_ADR085	70000.1300000000047
2022-11-01	LM_ELE_ADR090	47763.6800000000003
2022-11-01	LM_ELE_ADR107	99982.5899999999965
2022-11-01	LM_ELE_ADR108	7577.27000000000044
2022-11-01	LM_ELE_ADR109	2041.95000000000005
2022-11-01	LM_ELE_ADR110	501.560000000000002
2022-11-01	LM_ELE_ADR113	61471.5699999999997
2022-11-01	LM_ELE_ADR087	97168.2599999999948
2022-11-01	LM_LC_ADR_B45	229.849999999999994
2022-11-01	LM_LH_ADR_B46	49.3500000000000014
2022-11-01	LM_LH_ADR_B47	149.5
2022-11-01	LM_WOD_ADR_B74	42.8200000000000003
2022-11-01	LM_ELE_ADR_B06	550474.5
2022-11-01	LM_ELE_ADR046	0
2022-11-01	LM_ELE_ADR010	131145.160000000003
2022-11-01	LM_ELE_ADR043	3167.26999999999998
2022-11-01	LM_ELE_ADR_B11	38165.4100000000035
2022-11-01	LM_WOD_ADR242	49.5300000000000011
2022-11-01	LM_ELE_ADR124	142215.470000000001
2022-11-01	LM_ELE_ADR112	767511.439999999944
2022-11-01	LM_WOD_ADR_B75	190.689999999999998
2022-11-01	LM_ELE_ADR091	14425.7600000000002
2022-11-01	LM_WOD_ADR_B80	148.810000000000002
2022-11-01	LM_WOD_ADR_B81	52.1899999999999977
2022-11-01	LM_ELE_ADR_B04	320261.659999999974
2022-11-01	LM_ELE_ADR_B05	326449.75
2022-11-01	LM_ELE_ADR_B09	326041.159999999974
2022-11-01	LM_ELE_ADR_B01	0
2022-11-01	LM_ELE_ADR_B10	34241.6600000000035
2022-11-01	LM_ELE_ADR_B02	0
2022-11-01	LM_LC_ADR_B18	19.120000000000001
2022-11-01	LM_LC_ADR_B20	70.6299999999999955
2022-11-01	LM_LC_ADR_B22	56.3800000000000026
2022-11-01	LM_LC_ADR_B24	10.6899999999999995
2022-11-01	LM_LC_ADR_B31	476.100000000000023
2022-11-01	LM_LC_ADR_B41	552
2022-11-01	LM_LC_ADR_B43	9.80000000000000071
2022-11-01	LM_LH_ADR_B23	73.9000000000000057
2022-11-01	LM_LH_ADR_B25	77.7000000000000028
2022-11-01	LM_LH_ADR_B27	165.300000000000011
2022-11-01	LM_LH_ADR_B35	0
2022-11-01	LM_LH_ADR_B36	0
2022-11-01	LM_LH_ADR_B38	80.5
2022-11-01	LM_LH_ADR_B44	4.79999999999999982
2022-11-01	LM_WOD_ADR_B76	1896.40000000000009
2022-11-01	LM_WOD_ADR_B77	9.10999999999999943
2022-11-01	LM_LC_ADR_B16	38.8200000000000003
2022-11-01	LM_LH_ADR_B17	65.5999999999999943
2022-11-01	LM_WOD_ADR_B79	515.649999999999977
2022-11-01	LM_ELE_ADR_B12	20501.119999999999
2022-11-01	LM_ELE_ADR_B13	15053.1900000000005
2022-11-01	LM_LC_ADR_B46	58.8699999999999974
2022-11-01	LM_LC_ADR193	0
2022-11-01	LM_ELE_ADR125	5329.84000000000015
2022-11-01	LM_ELE_ADR069	337570
2022-11-01	LM_ELE_ADR075	12792
2022-11-01	LM_LC_ADR159	5030
2022-11-01	LM_LC_ADR160	15210
2022-11-01	LM_LH_ADR167	14570
2022-11-01	LM_WOD_ADR236	28.4100000000000001
2022-11-01	zdemontowany580	6
2022-11-01	zdemontowany600	3194
\.


--
-- Data for Name: ordung; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.ordung (adres, kolejnosc, kolejnosc_wojtek) FROM stdin;
----	1160	\N
----	1170	\N
LM_LC_ADR_B33	1190	1430
LM_LH_ADR_B39	1200	1440
----	1210	\N
LM_ELE_ADR_B12	1230	1450
----	20	\N
----	30	\N
----	40	\N
----	60	\N
----	70	\N
----	80	\N
----	90	\N
----	110	\N
----	220	\N
----	230	\N
----	240	\N
----	250	\N
----	260	\N
----	270	\N
----	290	\N
----	300	\N
----	310	\N
----	320	\N
----	340	\N
----	440	\N
----	740	\N
----	760	\N
LM_ELE_ADR039	950	1900
LM_WOD_ADR_B78	990	1470
----	1000	\N
LM_LC_ADR_B41	1020	1490
LM_LH_ADR_B42	1030	1540
LM_ELE_ADR_B10	\N	\N
LM_ELE_ADR_B02	\N	\N
LM_WOD_ADR_B76	\N	\N
LM_WOD_ADR_B77	\N	\N
LM_ELE_ADR016	\N	\N
LM_ELE_ADR018	\N	\N
LM_ELE_ADR020	\N	\N
LM_ELE_ADR022	\N	\N
LM_ELE_ADR073	\N	\N
LM_ELE_ADR070	\N	\N
LM_ELE_ADR024	\N	\N
LM_LH_ADR_B37	\N	\N
LM_ELE_ADR065	\N	\N
LM_ELE_ADR019	\N	\N
LM_ELE_ADR_B11	\N	\N
LM_ELE_ADR017	\N	\N
LM_WOD_ADR142	\N	\N
LM_WOD_ADR141	\N	\N
LM_ELE_ADR002	\N	\N
LM_ELE_ADR_B13	1240	1460
LM_ELE_ADR_B06	1250	2030
LM_ELE_ADR_B05	1260	2040
LM_ELE_ADR_B04	1270	2050
LM_WOD_ADR150	1310	1150
LM_LC_ADR172	1330	1160
LM_LH_ADR218	1340	1190
LM_LH_ADR217	1350	1200
LM_LC_ADR171	1360	1170
LM_LH_ADR232	1370	1210
LM_LC_ADR178	1380	1180
LM_ELE_ADR114	1400	1220
LM_ELE_ADR112	1410	2120
----	280	\N
----	350	\N
----	360	\N
----	370	\N
----	390	\N
----	460	\N
----	480	\N
----	490	\N
----	500	\N
----	540	\N
----	610	\N
----	710	\N
----	720	\N
----	730	\N
----	770	\N
----	830	\N
----	900	\N
----	910	\N
----	920	\N
----	960	\N
----	970	\N
----	980	\N
----	1010	\N
----	1080	\N
----	1130	\N
----	1140	\N
----	1150	\N
----	1180	\N
----	1220	\N
----	1280	\N
----	1290	\N
----	1300	\N
----	1320	\N
----	1390	\N
----	1420	\N
----	1430	\N
----	1440	\N
----	1450	\N
----	1460	\N
LM_LC_ADR175	1470	1230
LM_LH_ADR222	1480	1260
LM_LH_ADR223	1490	1270
LM_LC_ADR176	1500	1240
LM_LC_ADR102	1510	1250
----	1520	\N
LM_ELE_ADR071	1530	1280
LM_ELE_ADR015	1540	2130
----	1560	\N
----	1570	\N
----	1580	\N
----	1600	\N
LM_LC_ADR170	1610	1300
LM_LH_ADR215	1620	1310
LM_ELE_ADR028	2270	970
LM_LH_ADR216	1630	1320
LM_ELE_ADR081	\N	1010
----	2280	\N
----	2290	\N
LM_WOD_ADR250_Solution Space	2300	810
LM_WOD_ADR249_Solution Space	2310	820
LM_WOD_ADR248_Solution Space	2320	830
----	2330	\N
LM_LH_ADR212	2340	940
LM_LC_ADR162	2350	890
LM_LH_ADR204	2360	950
----	2370	\N
LM_ELE_ADR099	2380	1020
LM_ELE_ADR012	2410	960
----	2440	\N
----	2450	\N
----	2460	\N
LM_WOD_ADR239	2470	720
----	2480	\N
LM_LC_ADR182	2490	730
LM_LH_ADR233	2500	740
LM_LH_ADR234	2510	750
----	2520	\N
LM_ELE_ADR100	2530	760
LM_ELE_ADR101	2540	770
----	2550	\N
----	2560	\N
----	2570	\N
----	2580	\N
LM_WOD_ADR238	2590	620
----	2600	\N
LM_LC_ADR209	2610	630
LM_LH_ADR235	2620	660
LM_LC_ADR224	2630	640
LM_LH_ADR_B44	2640	650
LM_LC_ADR_B43	2650	670
----	2660	\N
LM_ELE_ADR121	2670	680
----	1640	\N
LM_ELE_ADR088	1650	1330
----	1670	\N
----	1680	\N
----	1690	\N
----	1700	\N
----	1710	\N
LM_LC_ADR173	1720	1100
LM_LH_ADR219	1730	1110
LM_LH_ADR220	1740	1120
----	1750	\N
----	1760	\N
----	1790	\N
----	1800	\N
----	1810	\N
----	1830	\N
LM_LC_ADR174	1840	1060
LM_LH_ADR221	1850	1070
LM_LC_ADR163	1860	30
LM_LH_ADR201	1870	40
LM_LC_ADR164	1880	20
----	1890	\N
LM_ELE_ADR124	1900	1080
----	1910	\N
----	1920	\N
----	1930	\N
LM_WOD_ADR236	1940	2000
----	1950	\N
LM_LC_ADR159	1960	1980
LM_LH_ADR167	1970	1990
LM_LC_ADR160	1980	1970
----	1990	\N
LM_ELE_ADR068	2000	1960
----	2010	\N
----	2020	\N
----	2030	\N
LM_WOD_ADR242	2040	780
----	2050	\N
LM_LC_ADR179	2060	840
LM_LH_ADR228	2070	900
LM_LC_ADR165	2080	850
LM_LC_ADR166	2090	860
----	2100	\N
LM_ELE_ADR090	2110	980
----	2120	\N
----	2130	\N
----	2140	\N
LM_WOD_ADR247_Solution Space	2150	800
LM_WOD_ADR246_Solution Space	2160	790
----	2170	\N
LM_LH_ADR231	2180	910
----	2230	\N
LM_ELE_ADR027	2680	690
LM_ELE_ADR120	2690	700
LM_ELE_ADR110	2700	710
----	2710	\N
----	2720	\N
----	2730	\N
LM_WOD_ADR_B79	2740	110
LM_WOD_ADR_B75	2750	120
----	2760	\N
----	2770	\N
LM_ELE_ADR078	2780	130
----	2800	\N
----	2810	\N
LM_LC_ADR104	2820	80
LM_LC_ADR_B26	2830	90
LM_LH_ADR_B27	2840	170
LM_LC_ADR123	2850	100
LM_LH_ADR122	2860	180
----	2870	\N
LM_LH_ADR227	2880	1390
----	2900	\N
----	2910	\N
----	2920	\N
LM_WOD_ADR_B74	2930	370
----	2940	\N
LM_LC_ADR_B45	2950	380
LM_LH_ADR_B47	2960	390
LM_LH_ADR_B46	2970	400
----	2980	\N
LM_ELE_ADR107	2990	410
LM_ELE_ADR001	3000	2150
----	3010	\N
----	3020	\N
----	3030	\N
LM_WOD_ADR_B81	3040	420
----	3050	\N
LM_LC_ADR185	3060	460
LM_LH_ADR225	3070	520
LM_LC_ADR93	3080	480
LM_LH_ADR_B23	3090	50
LM_LC_ADR_B22	3100	60
----	3110	\N
LM_ELE_ADR062	3120	570
----	3130	\N
----	3140	\N
----	3150	\N
----	3160	\N
LM_WOD_ADR_B80	3170	430
----	3180	\N
----	3190	\N
----	3200	\N
LM_LC_ADR_B16	3210	440
LM_LH_ADR_B17	3220	540
LM_LC_ADR_B20	3230	450
LM_LC_ADR181	2190	870
LM_LH_ADR230	2200	920
LM_LC_ADR180	2210	880
LM_LH_ADR229	2220	930
LM_ELE_ADR031	2240	990
LM_WOD_ADR146	10	2070
LM_WOD_ADR143	50	\N
LM_LC_ADR151	100	\N
LM_LH_ADR198	120	\N
LM_LH_ADR197	130	\N
LM_LH_ADR194	140	\N
LM_LH_ADR195	150	\N
LM_LH_ADR196	160	\N
LM_LC_ADR156	170	\N
LM_ELE_ADR008	2430	2110
LM_ELE_ADR010	2420	2140
LM_LC_ADR155	180	\N
LM_LC_ADR154	190	\N
LM_LC_ADR153	200	\N
LM_LC_ADR152	210	\N
LM_ELE_ADR038	330	2060
LM_WOD_ADR139	380	1340
LM_LC_ADR168	400	1350
LM_LH_ADR226	410	1380
LM_LC_ADR103	450	1370
LM_ELE_ADR069	470	1410
LM_LH_ADR207	550	1760
LM_LC_ADR157	560	1740
LM_LH_ADR199	570	1770
LM_LH_ADR211	580	1780
LM_LH_ADR203	590	1790
LM_LC_ADR161	600	1750
LM_ELE_ADR059	620	1800
LM_ELE_ADR080	630	1810
LM_ELE_ADR095	640	1820
LM_ELE_ADR084	650	1830
LM_ELE_ADR098	660	1840
LM_ELE_ADR087	670	1850
LM_ELE_ADR013	680	1860
LM_ELE_ADR011	690	1870
LM_ELE_ADR009	700	1880
LM_WOD_ADR136	750	1590
LM_LC_ADR_B31	780	1600
LM_LH_ADR_B38	790	1620
LM_LH_ADR_B40	810	1640
LM_LC_ADR_B32	820	1610
LM_ELE_ADR_B08	840	1650
LM_ELE_ADR_B07	850	1660
LM_ELE_ADR_B03	860	1670
LM_ELE_ADR007	870	1690
LM_ELE_ADR046	880	1700
LM_ELE_ADR125	890	1680
LM_WOD_ADR140	930	1890
LM_ELE_ADR128	\N	\N
LM_WOD_ADR148	\N	\N
LM_WOD_ADR30	\N	\N
LM_WOD_ADR241	\N	\N
LM_WOD_ADR240	\N	\N
LM_ELE_ADR086	2250	1000
----	2260	\N
LM_LH_ADR_B21	3240	550
LM_ELE_ADR097	2390	1030
LM_ELE_ADR085	2400	1040
LM_WOD_ADR129	1820	1050
LM_ELE_ADR109	\N	\N
LM_ELE_ADR076	\N	\N
LM_ELE_ADR074	\N	\N
LM_ELE_ADR058	\N	\N
LM_ELE_ADR064	\N	\N
LM_LH_ADR208	\N	\N
LM_LH_ADR200	\N	\N
LM_ELE_ADR043	\N	\N
LM_ELE_ADR066	\N	\N
LM_ELE_ADR055	\N	\N
LM_ELE_ADR056	\N	\N
LM_ELE_ADR063	\N	\N
LM_ELE_ADR021	\N	\N
LM_WOD_MAIN_W	\N	\N
LM_LC_ADR158	\N	\N
LM_ELE_ADR053	\N	\N
LM_ELE_ADR051	\N	\N
LM_ELE_ADR048	\N	\N
LM_ELE_ADR044	\N	\N
LM_ELE_ADR042	\N	\N
LM_ELE_ADR052	\N	\N
LM_ELE_ADR040	\N	\N
LM_ELE_ADR036	\N	\N
LM_ELE_ADR047	\N	\N
LM_ELE_ADR045	\N	\N
LM_ELE_ADR041	\N	\N
LM_ELE_ADR034	\N	\N
LM_ELE_ADR025	\N	\N
LM_ELE_ADR023	\N	\N
LM_ELE_ADR054	\N	\N
LM_ELE_ADR057	\N	\N
LM_ELE_ADR060	\N	\N
LM_ELE_ADR061	\N	\N
LM_ELE_ADR111	\N	\N
LM_ELE_ADR116	\N	\N
LM_ELE_ADR118	\N	\N
LM_ELE_ADR119	\N	\N
LM_ELE_ADR_B01	\N	\N
----	1040	\N
----	1050	\N
LM_LC_ADR_B30	1060	1500
----	1070	\N
LM_ELE_ADR_B09	1090	1550
LM_ELE_ADR108	1100	1570
LM_ELE_ADR006	1110	1560
LM_ELE_ADR003	1120	2100
LM_LC_ADR_B18	3250	490
LM_ELE_ADR077	2790	140
LM_ELE_ADR002	\N	1695
LM_WOD_ADR147	1590	1290
recznie1400	\N	1400
recznie1420	\N	1420
LM_LH_ADR_B35	\N	1520
LM_WOD_ADR132	\N	1720
----	\N	2020
LM_ELE_ADR067	\N	2010
----	\N	2080
----	\N	2090
LM_LH_ADR_B19	3260	560
LM_LC_ADR89	3270	470
----	3280	\N
----	3290	\N
----	3300	\N
LM_LC_ADR_B24	3310	500
LM_LH_ADR_B25	3320	530
LM_LC_ADR82	3330	510
----	3340	\N
----	3350	\N
----	3360	\N
----	3370	\N
----	3380	\N
LM_WOD_ADR237	3390	210
----	3400	\N
LM_LC_ADR184	3410	230
LM_LH_ADR189	3420	\N
LM_LC_ADR149	3430	220
LM_LH_ADR145	3440	270
LM_LC_ADR183	3450	240
LM_LH_ADR190	3460	280
LM_LC_ADR186	3470	250
LM_LH_ADR191	3480	290
LM_LC_ADR187	3490	260
LM_LH_ADR192	3500	300
LM_LC_ADR193	3510	\N
LM_LH_ADR188	3520	310
----	3530	\N
LM_ELE_ADR094	3540	320
----	3550	\N
LM_ELE_ADR113	3560	2160
LM_ELE_ADR115	3570	350
LM_ELE_ADR014	3580	340
LM_ELE_ADR117	3590	360
----	3600	\N
----	3610	\N
----	3620	\N
----	3630	\N
----	3640	\N
LM_LC_ADR32	3650	1930
LM_LH_ADR33	3660	1940
----	3670	\N
LM_ELE_ADR029	3680	1950
----	3690	\N
----	3700	\N
----	3710	\N
LM_ELE_ADR091	3720	200
----	3730	\N
----	3740	\N
----	3750	\N
----	3760	\N
LM_WOD_ADR135	3770	1580
LM_LH_ADR_B34	3790	1510
LM_LC_ADR_B46	2890	1360
LM_LH_ADR_B36	3780	1630
LM_ELE_ADR075	\N	1130
LM_ELE_ADR072	1770	1140
LM_ELE_ADR049	940	1910
----	\N	\N
----	\N	\N
recznie70	\N	70
recznie10	\N	10
recznie150	\N	150
recznie160	\N	160
recznie190	\N	190
recznie330	\N	330
recznie590	\N	590
recznie610	\N	610
recznie1090	\N	1090
recznie1480	\N	1480
recznie1530	\N	1530
recznie1920	\N	1920
zdemontowany580	\N	580
zdemontowany600	\N	600
LM_WOD_ADR133	510	1710
LM_WOD_ADR134	530	1730
\.


--
-- Data for Name: plik_wojtek; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.plik_wojtek (adres, nr_fabryczny, kolejnosc) FROM stdin;
recznie1580	190037778A	1920
recznie1700	1920543256	10
recznie1710	60587375	1420
LM_ELE_ADR007	2316325006	1690
LM_ELE_ADR081	2316354003	1010
LM_WOD_ADR236	21728054	2000
LM_LC_ADR159	72461134	1980
LM_LH_ADR167	72497589	1990
LM_WOD_ADR146	17803108	2070
LM_LC_ADR160	72461135	1970
LM_LH_ADR204	78251262	950
LM_LH_ADR122	71595108	180
LM_WOD_ADR_B80	58376978	430
LM_ELE_ADR090	2318334011	980
LM_LC_ADR162	62065876	890
LM_LC_ADR185	71612821	460
LM_LH_ADR225	71612822	520
LM_LC_ADR_B16	71150833	440
LM_LH_ADR_B21	71644763	550
LM_LH_ADR_B19	71644764	560
LM_LC_ADR184	71512150	230
LM_LC_ADR149	71512149	220
LM_LH_ADR145	71512145	270
LM_LH_ADR190	71512144	280
LM_LC_ADR186	71512152	250
LM_LC_ADR93	67884164	480
LM_LC_ADR_B22	71649394	60
zdemontowany510	48503026G16412011087	600
LM_LC_ADR_B18	71647821	490
LM_LC_ADR89	67884165	470
LM_LC_ADR_B24	71649395	500
LM_LC_ADR183	71512151	240
LM_WOD_ADR242	181195090	780
LM_WOD_ADR249_Solution Space	181174659A	820
LM_LH_ADR191	71512148	290
LM_LC_ADR187	71512153	260
LM_LH_ADR192	71512147	300
LM_LH_ADR188	71512146	310
LM_LH_ADR_B34	62065880	1510
LM_ELE_ADR115	2316371005	350
LM_ELE_ADR028	2316362014	970
LM_ELE_ADR012	2316362002	960
LM_ELE_ADR078	48503028H16492010696	130
LM_LC_ADR123	71595107	100
LM_WOD_ADR_B81	58376979	420
LM_ELE_ADR031	1816331002	990
LM_ELE_ADR001	2316354011	2150
LM_ELE_ADR113	2316371016	2160
LM_ELE_ADR117	2316362003	360
LM_LH_ADR_B36	62065883	1630
LM_LC_ADR_B32	62065875	1610
LM_LC_ADR209	71476893	630
LM_LH_ADR235	71476894	660
LM_LH_ADR203	78251266	1790
LM_ELE_ADR095	2317384011	1820
LM_LC_ADR182	71496751	730
LM_LH_ADR233	71497211	740
LM_LH_ADR234	71497210	750
LM_WOD_ADR247_Solution Space	181072960A	800
LM_WOD_ADR246_Solution Space	181195096A	790
LM_WOD_ADR250_Solution Space	181173780A	810
LM_WOD_ADR248_Solution Space	181174655A	830
LM_WOD_ADR_B75	191183429A	120
LM_ELE_ADR099	2318352007	1020
LM_WOD_ADR237	181235653A	210
LM_ELE_ADR094	1818244023	320
LM_ELE_ADR029	2319334053	1950
LM_LH_ADR228	80271297	900
LM_LC_ADR165	80108185	850
LM_LC_ADR166	80138392	860
LM_LC_ADR181	80272797	870
LM_LH_ADR230	80271298	920
LM_LC_ADR180	80272796	880
LM_LH_ADR229	80271273	930
LM_LH_ADR219	78675971	1110
LM_LH_ADR220	78676883	1120
LM_LH_ADR227	80120069	1390
LM_LH_ADR_B17	71644762	540
LM_ELE_ADR014	2316362007	340
LM_ELE_ADR091	2316362011	200
LM_WOD_ADR_B79	191061232A	110
LM_LC_ADR32	80443474	1930
LM_ELE_ADR086	2318334004	1000
LM_LC_ADR103	67676944	1370
LM_LC_ADR_B33	62065877	1430
LM_LH_ADR221	71230687	1070
LM_LC_ADR163	71888359	30
LM_LC_ADR164	71876833	20
LM_LC_ADR_B30	62065865	1500
LM_LH_ADR212	62065884	940
LM_LC_ADR104	67887353	80
LM_LC_ADR_B26	71670106	90
LM_LH_ADR_B23	71649391	50
LM_LH_ADR_B25	71649390	530
LM_ELE_ADR062	48503026G16402010541	570
LM_LH_ADR231	71259540	910
LM_LC_ADR102	67219624	1250
LM_WOD_ADR238	180702718A	620
LM_LH_ADR218	78647935	1190
LM_WOD_ADR140	161032832	1890
LM_WOD_ADR_B74	190405578A	370
LM_ELE_ADR107	1818415001	410
LM_LH_ADR_B47	71571363	390
LM_LH_ADR_B46	71571362	400
LM_ELE_ADR098	2317441033	1840
LM_LH_ADR207	62065885	1760
LM_WOD_ADR239	181195981A	720
LM_ELE_ADR101	2318332002	770
LM_ELE_ADR100	2318355029	760
LM_LC_ADR_B41	78478336	1490
LM_LC_ADR173	78675879	1100
LM_LH_ADR_B39	78251259	1440
LM_LC_ADR82	67884167	510
LM_LC_ADR174	71297057	1060
LM_LH_ADR201	71834619	40
LM_ELE_ADR008	2316326010	2110
LM_LH_ADR_B42	78478337	1540
LM_ELE_ADR038	1816332105	2060
LM_ELE_ADR003	2316354013	2100
LM_ELE_ADR_B06	1816331030	2030
LM_ELE_ADR010	2316371007	2140
LM_WOD_ADR_B78	60600683	1470
LM_ELE_ADR071	48503026H16502010220	1280
LM_LH_ADR217	78647934	1200
LM_LC_ADR171	78647936	1170
LM_LH_ADR232	78675881	1210
LM_LC_ADR178	78675880	1180
LM_LC_ADR172	78647937	1160
LM_ELE_ADR114	1816331023	1220
LM_WOD_ADR150	60882996	1150
LM_ELE_ADR039	1816344019	1900
LM_LC_ADR161	62065874	1750
LM_ELE_ADR011	2316371001	1870
LM_ELE_ADR080	2317445010	1810
LM_ELE_ADR009	2316362010	1880
LM_ELE_ADR006	2316326004	1560
LM_ELE_ADR108	2316371009	1570
LM_LH_ADR_B27	71670180	170
LM_WOD_ADR139	57760157	1340
LM_LC_ADR168	80087616	1350
LM_LH_ADR226	80120070	1380
LM_ELE_ADR015	2316326007	2130
LM_ELE_ADR124	1816331007	1080
LM_ELE_ADR_B05	1816331016	2040
LM_LC_ADR_B46	80087615	1360
LM_ELE_ADR_B12	272103494	1450
LM_ELE_ADR_B13	272103657	1460
recznie1420	1816332087	330
recznie1460	36254453	1090
LM_ELE_ADR075	48503026H16502010245	1130
LM_LC_ADR_B31	62065868	1600
LM_LH_ADR_B40	78251265	1640
LM_WOD_ADR135	77902822	1580
LM_WOD_ADR136	77902823	1590
LM_LH_ADR_B38	78251257	1620
LM_ELE_ADR046	2316354008	1700
LM_LH_ADR223	80032572	1270
LM_LC_ADR175	80096039	1230
LM_LH_ADR222	80032573	1260
LM_LC_ADR176	80096038	1240
LM_ELE_ADR121	1818137046	680
LM_LC_ADR224	71705791	640
LM_ELE_ADR027	2316311028	690
LM_ELE_ADR110	2316371014	710
LM_LH_ADR_B44	80255450	650
LM_LC_ADR_B43	80255449	670
LM_ELE_ADR049	2316354002	1910
LM_LC_ADR_B45	71522586	380
LM_ELE_ADR087	2317441065	1850
LM_ELE_ADR013	2316362006	1860
LM_LC_ADR157	62065866	1740
LM_LH_ADR199	78251263	1770
LM_LH_ADR211	62065882	1780
LM_LC_ADR_B20	71150834	450
LM_ELE_ADR_B08	1817261013	1650
LM_ELE_ADR_B07	1817174066	1660
LM_ELE_ADR_B03	1517162019	1670
LM_ELE_ADR_B04	1816331005	2050
LM_ELE_ADR112	2316362018	2120
LM_ELE_ADR_B09	1817261024	1550
LM_ELE_ADR069	48503028H16492010698	1410
LM_LC_ADR179	80272795	840
LM_LH_ADR33	80446698	1940
recznie360	48503028H16492010700	150
recznie370	2316326009	160
recznie400	71516192	190
zdemontowany490	48503026H16472010063	580
LM_ELE_ADR072	48503026H16502010251	1140
recznie500	48503026H16502010252	590
recznie560	48503026H16502010237	610
recznie810	620665888	1530
recznie860	160559458	1480
LM_ELE_ADR068	48503026H16472010039	1960
LM_ELE_ADR125	1517311047	1680
recznie10	57783922	70
LM_ELE_ADR120	2316326003	700
LM_ELE_ADR059	2317445001	1800
LM_ELE_ADR084	2317445019	1830
LM_LC_ADR170	80091629	1300
LM_ELE_ADR088	2318245036	1330
LM_LH_ADR216	80091630	1320
LM_LH_ADR215	80091631	1310
\.


--
-- Data for Name: rodzaje_licz; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.rodzaje_licz (rodzaj, rodzaj_licznika, jednostka) FROM stdin;
ELE	elektryczny	kWh
LC	ciepła	MJ
LH	chłodu	MJ
WOD	wody	m^3
\.


--
-- Data for Name: wojtek; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.wojtek (kolejnosc, najemca, nr_fabryczny, lokalizacja) FROM stdin;
10	AlmiDecor	57783922	1
20	AlmiDecor	80096039	0
30	AlmiDecor	80096038	1
40	AlmiDecor	67219624	-1
50	AlmiDecor	80032573	0 WL
60	AlmiDecor	80032572	+1 WL
70	AlmiDecor	48503026H16502010220	+1 TL
80	Atelier Amaro 	180702718A	0
90	Atelier Amaro 	71476893	-1
100	Atelier Amaro 	71705791	0
110	Atelier Amaro 	80255450	5
120	Atelier Amaro 	71476894	0 WL klimakonwektory
130	Atelier Amaro 	80255449	+5 WL AHU N2
140	Atelier Amaro 	1818137046	0
150	Atelier Amaro 	2316311028	0 AHU R5
160	Atelier Amaro 	2316326003	0 RW4
170	Atelier Amaro 	2316371014	Magazyn -1.5
180	Audi	60882996	1
190	Audi	78647937	1
200	Audi	78647936	0
210	Audi	78675880	-1
220	Audi	78647935	+1 WL
230	Audi	78647934	0 WL
240	Audi	78675881	+1 WL Serwerownia
250	Audi	1816331023	-2 RGNN  2Q3
260	CH-1 (pom. seewald)	1816331030	5
270	CH-2 (pom. seewald)	1816331016	5
280	CH-3 (pom. seewald)	1816331005	5
290	Culinaryon	67887353	CT
300	Culinaryon	71670106	CT klimakonwektory
310	Culinaryon	71595107	\N
320	Culinaryon	191061232A	5
330	Culinaryon	191183429A	5
340	Culinaryon	48503028H16492010696	Pow. 0.06
350	Culinaryon	48503026G16402010565	Pow. 0.13
360	Culinaryon	48503028H16492010700	Pow. 1.06
370	Culinaryon	2316326009	\N
380	Culinaryon	71670180	0 WL
390	Culinaryon	71595108	0 WL
400	Culinaryon	71516192	0 WL
410	Davide	58376978	\N
420	Davide	71150833	CT klimakonwektory
430	Davide	71150834	CT klimakonwektory
440	Davide	67884165	CT
450	Davide	71647821	CT klimakonwektory
460	Davide	71644762	0
470	Davide	71644763	1
480	Davide	71644764	1
490	Davide	48503026H16472010063	Pow. 1.03
500	Davide	48503026H16502010252	Pow. 0.03
510	Davide	48503026G16412011087	Pow. 1.02
520	Davide - Corneliani	71649391	0, rewizja w szafie
530	Davide - Corneliani	71649394	0, rewizja w szafie
540	Davide - Corneliani	71649395	\N
550	Davide - Corneliani	67884167	CT
560	Davide - Corneliani	48503026H16502010237	Pow. 0.02
570	Davide - Fabiana Filippi	58376979	0
580	Davide - Fabiana Filippi	71612821	0 CT klimakonwektory
590	Davide - Fabiana Filippi	67884164	CT
600	Davide - Fabiana Filippi	71612822	0 WL
610	Davide - fabiana Fillipi	48503026G16402010541	Pow. 0.04
620	Davide -Corneliani	71649390	1
630	E.ON	190405578A	4
640	E.ON	71522586	+4 CT klimakonwektory
650	E.ON	71571363	+4 WL klimakonwektory
660	E.ON	71571362	+4 WL Serwerownia
670	E.ON	1818415001	4
680	Green Caffe Nero	57760157	0
690	Green Caffe Nero	80087616	0
700	Green Caffe Nero	80087615	0
710	Green Caffe Nero	67676944	-1
720	Green Caffe Nero	80120070	0 WL
730	Green Caffe Nero	80120069	0 WL
740	Green Caffe Nero	80137646	+1 WL
750	Green Caffe Nero	48503028H16492010698	0 TL 0.08
760	HBO	60600683	5
770	HBO	78478336	5
780	HBO	62065865	5
790	HBO	62065880	+5 WL Serwerownia
800	HBO	620665881	+5 WL Serwerownia
810	HBO	620665888	+5 WL 
820	HBO	78478337	+5 WL 
830	HBO	1817261024	+5 pom. 5.6
840	HBO	2316326004	+5 AHU1_5
850	HBO	2316371009	-1 Magazyn HBO
860	HBO - podlewanie dachu	160559458	5
870	Heban	48503026H16472010039	0
880	Heban	72461135	-1
890	Heban	72461134	0
900	Heban	72497589	0
910	Heban	21728054	0
920	Hogan Lovells	77902822	4
930	Hogan Lovells	77902823	4
940	Hogan Lovells	62065868	4
950	Hogan Lovells	62065875	4
960	Hogan Lovells	78251257	+4 WL 
970	Hogan Lovells	62065883	+4 WL Serwerownia
980	Hogan Lovells	78251265	+4 WL 
990	Hogan Lovells	1817261013	+4 TN-1.4
1000	Hogan Lovells	1817174066	+4 TN-3.4
1010	Hogan Lovells	1517162019	+4 TNK-1.4
1020	Hogan Lovells	1517311047	+4 Licznik LOGO
1030	Hogan Lovells	2316325006	+4 AHU 1_4
1040	Hogan Lovells	2316354008	+4 AHU 2_4
1050	IT Ergo	I17FA358457 T	2
1060	IT Ergo	I17FA358454 Q	2
1070	IT Ergo	119EA020537	2
1080	IT Ergo	62065866	2
1090	IT Ergo	62065874	2
1100	IT Ergo	62065885	+2 WL Serwerownia
1110	IT Ergo	78251263	+2 WL 
1120	IT Ergo	62065882	+2 WL Serwerownia
1130	IT Ergo	78251266	+2 WL 
1140	IT Ergo	2317445001	+2 TNK-1.2
1150	IT Ergo	2317445010	+2 TN-1.2
1160	IT Ergo	2317384011	+2 TNK-2.2
1170	IT Ergo	2317445019	+2 TN-2.2
1180	IT Ergo	2317441033	+2 TNK-3.2
1190	IT Ergo	2317441065	+2 TN-3.2
1200	IT Ergo	2316362006	+2 AHU 1_2
1210	IT Ergo	2316371001	+2 AHU 2_2
1220	IT Ergo	2316362010	+2 AHU 3_2
1230	ITP S.A.	48503026H16502010235	0
1240	Leonardo	181195981A	3
1250	Leonardo	71496751	3
1260	Leonardo	71497211	+3 WL 
1270	Leonardo	71497210	+3 WL Serwerownia
1280	Leonardo	2318355029	+ 3TN 4.3
1290	Leonardo	2318332002	+3 TNK 4.3
1300	Les Amis	181235653A	0
1310	Les Amis	71512149	0
1320	Les Amis	71512150	0
1330	Les Amis	71512151	0
1340	Les Amis	71512152	0
1350	Les Amis	71512153	0
1360	Les Amis	71512145	0 WL
1370	Les Amis	71512144	0 WL
1380	Les Amis	71512148	0 WL
1390	Les Amis	71512147	0 WL
1400	Les Amis	71512146	0 WL
1410	Les Amis	1818244023	RR
1420	Les Amis	1816332087	RZ
1430	Les Amis	2316362007	R4
1440	Les Amis	2316371005	R3KZ
1450	Les Amis	2316362003	R4KZ
1460	MBDA	36254453	3
1470	MBDA	78675879	3
1480	MBDA	78675971	+3 WL
1490	MBDA	78676883	+3 WL
1500	MBDA	48503026H16502010245	+3 TN
1510	MBDA	48503026H16502010251	+3 TNK
1520	NDI	18726655	3
1530	NDI	80091629	3
1540	NDI	80091631	+3 WL
1550	NDI	80091630	+3 WL
1560	NDI	2318245036	+3 TB-L3
1570	P4	2316362011	-2 T-TEL
1580	PZFD	190037778A	4
1590	PZFD	80443474	4
1600	PZFD	80446698	4
1610	PZFD	2319334053	4
1620	Redford&Grant	71876833	0
1630	Redford&Grant	71888359	0
1640	Redford&Grant	71834619	0
1650	Redford&Grant	181106629A	1
1660	Redford&Grant	71297057	1
1670	Redford&Grant	71230687	+1 WL
1680	Redford&Grant	1816331007	-2 RGNN
1690	RPCH\nPompy	1816332105	-2
1700	Seewald	1920543256	5
1710	Seewald	60587375	5
1720	Seewald	62065877	5
1730	Seewald	78251259	+5 WL 
1740	Seewald	272103494	+5 RN
1750	Seewald	272103657	+5 RNK
1760	Solutions Rent	181195090	0
1770	Solutions Rent	181195096A	1
1780	Solutions Rent	181072960A	1
1790	Solutions Rent	181173780A	3
1800	Solutions Rent	181174659A	3
1810	Solutions Rent	181174655A	3
1820	Solutions Rent	80272795	0
1830	Solutions Rent	80108185	0
1840	Solutions Rent	80138392	0
1850	Solutions Rent	80272797	1
1860	Solutions Rent	80272796	1
1870	Solutions Rent	62065876	3
1880	Solutions Rent	80271297	0 WL
1890	Solutions Rent	71259540	+1 WL Serwerownia
1900	Solutions Rent	80271298	+1 WL
1910	Solutions Rent	80271273	+1 WL
1920	Solutions Rent	62065884	+3 WL Serwerownia
1930	Solutions Rent	78251262	+3 WL
1940	Solutions Rent	2316362002	AHU 1_3
1950	Solutions Rent	2316362014	AHU R6
1960	Solutions Rent	2318334011	0 TN-1.0
1970	Solutions Rent	1816331002	+1 TN-2.1 (TU3)
1980	Solutions Rent	2318334004	+1 TNK-2.1
1990	Solutions Rent	2316354003	+1 TN-1.1 (TU5)
2000	Solutions Rent	2318352007	+3 TN-1.3
2010	Solutions Rent	2318341005	+3 TNK-2.3
2020	Solutions Rent	2318341010	+3 TN-2.3
2030	W.Kruk	161032832	-1
2040	W.Kruk	1816344019	-2
2050	W.Kruk	2316354002 - winda	-2
2060	Wodomierz główny	17803108	-1
2070	\N	\N	\N
2080	Centrale wentylacyjne	NR LICZNIKA	LOKALIZACJA
2090	AHU 2_5 (pom HBO)	2316354013	5
2100	AHU 3_3 (pom NDI)	2316326010	3
2110	AHU R2 (pom AUDI)	2316362018	0
2120	AHU R1 (pom Almi Decor)	2316326007	1
2130	AHU 2_3 (pom MBDA)	2316371007	3
2140	AHU 3_4 (pom EON)	2316354011	4
2150	AHU R3 (pom Les Amis)	2316371016	0
\.


--
-- Name: najemcy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: czarek
--

SELECT pg_catalog.setval('public.najemcy_id_seq', 21, true);


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

