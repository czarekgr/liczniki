--
-- PostgreSQL database dump
--

-- Dumped from database version 14.7 (Ubuntu 14.7-0ubuntu0.22.04.1)
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
    odczyt double precision,
    status character varying(20)
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

COPY public.liczniki (adres, nr_fabryczny, opis, lokalizacja, rodzaj, kolejnosc_pdf, najemca, uwagi, nr_fabryczny_old2023, podlaczenie) FROM stdin;
LM_WOD_ADR246_Solution Space	77435241	Wodomierz Solution Space kuchnia L01 (18734955)	Duża kuchnia, nad lustrem, poziom 1	WOD	1010	6	\N	181195096A	1/2
recznie1920	77436057	Wodomierz PZDF	PZFD za recepcją z drabiną	WOD	\N	10	\N	190037778A	1/2
LM_WOD_ADR_B79	77581183	Wodomierz - ciepła woda - CulinaryOn (19726824)	Przed mroźnią	WOD	2620	7	Duża drabina	191061232A	3/4
LM_WOD_ADR140	77581166	Wodomierz piano 1 W.Kruk (16803910)	Tunel - przy wyjściu	WOD	990	16	\N	161032832	3/4
LM_WOD_ADR242	77435242	Wodomierz Solution Space L00 (18734962)	Na końcu, nad plakatami	WOD	2310	6	\N	181195090	1/2
LM_WOD_ADR139	57760157	Wodomierz GCN  (57760157)	\N	WOD	1620	1	Niewymieniony	57760157	\N
LM_WOD_ADR134	19EA020537/173600458	Wodomierz ERGO - sala kinowa (17360045)	\N	WOD	1590	18	Niewymieniony - jeden zawór, za mała rewizja	19EA020537/173600458	\N
LM_WOD_ADR249_Solution Space	77435231	Wodomierz Solution Space kuchnia 1 (18733477)	Duża kuchnia 3 piętro	WOD	100	6	\N	181174659A	1/2
LM_WOD_ADR239	77435261	Wodomierz Leonardo L03 (18739958)	Recepcja, panel z sygnalizatorem czujki	WOD	1710	19	\N	181195981A	1/2
LM_WOD_ADR147	77435202	Wodomierz NDI (18726655)	Przy drzwiach wejściowych wewnątrz	WOD	1000	20	\N	181022659A	1/2
LM_WOD_ADR136	77436035	Wodomierz Hogan Lovells L04 - od Placu Trzech Krzyży (77902823)	Przy WC męskim	WOD	1610	15	Ultradźwiekowy, brak kabli, licznik kuchni od Kruka	77902823	1/2
LM_WOD_MAIN_W	BRAK		\N	WOD	110	\N	\N	BRAK	\N
----	\N	---	\N	\N	\N	\N	\N	\N	\N
LM_ELE_ADR007	2316325006	AHU 1.4 HOGAN LOVELLS (63325006)	\N	ELE	1830	15	\N	2316325006	\N
LM_WOD_ADR236	21728054	Wodomierz Heban L00 (21728054)	\N	WOD	2730	14	\N	21728054	\N
LM_LC_ADR159	72461134	Licznik ciepła - Heban L00 (72461134)	\N	LC	2700	14	\N	72461134	\N
LM_LH_ADR167	72497589	Licznik chłodu - Heban L00 (72497589)	\N	LH	2720	14	\N	72497589	\N
LM_WOD_ADR146	17803108	Główny wodomierz (11036701)	\N	WOD	1660	\N	\N	17803108	\N
LM_LC_ADR160	72461135	Licznik ciepła - Heban grzejniki (licznik na L-1) (72461135)	\N	LC	2710	14	\N	72461135	\N
LM_LC_ADR185	71612821	Licznik ciepła - Fabiana Filippi L00 (71612821)	\N	LC	1310	\N	\N	71612821	\N
LM_LH_ADR225	71612822	Licznik chłodu - Fabiana Filippi L00 (71612822)	\N	LH	1480	\N	\N	71612822	\N
LM_LH_ADR200	78251258	Licznik chłodu FC L03 - obieg FO (HC05, HC08) (78251258)	\N	LH	370	\N	\N	78251258	\N
LM_LH_ADR208	62065887	Licznik chłodu serwerownia najemcy L03 - S (HC05) (62065887)	\N	LH	400	\N	\N	62065887	\N
LM_LC_ADR93	67884164	Licznik ciepła - grzejnik Fabiana (67884164)	\N	LC	1350	\N	\N	67884164	\N
LM_LC_ADR_B22	71649394	Licznik ciepła - Fabiana L00 (71649394)	\N	LC	2460	\N	\N	71649394	\N
LM_LC_ADR_B24	71649395	Licznik ciepła - Corneliani L01 (71649395)	\N	LC	2470	\N	\N	71649395	\N
LM_ELE_ADR031	1816331002	Solution Tn-2.1 - TU3 (33331002)	\N	ELE	630	\N	\N	1816331002	\N
LM_ELE_ADR001	2316354011	AHU 3.4 EON (63354011)	\N	ELE	1790	\N	\N	2316354011	\N
LM_ELE_ADR117	2316362003	AHU R4KZ (63362003)	\N	ELE	1560	\N	\N	2316362003	\N
LM_LH_ADR_B36	62065883	Licznik chłodu serwerownia najemcy L04 Hogan serw - S (HC01) (62065883)	\N	LH	2550	15	\N	62065883	\N
LM_LC_ADR_B32	62065875	Licznik ciepła FC najemcy L04 Hogan1- obieg FO (HC01) (62065875)	\N	LC	1080	15	\N	62065875	\N
LM_LC_ADR209	71476893	Licznik ciepła  - Amaro L00 (71476893)	\N	LC	290	13	\N	71476893	\N
LM_LH_ADR235	71476894	Licznik chłodu - Amaro L00 (71476894)	\N	LH	510	13	\N	71476894	\N
LM_LH_ADR203	78251266	Licznik chłodu FC L02 - obieg FO IT ERGO (HC01) (78251266)	\N	LH	380	18	\N	78251266	\N
LM_ELE_ADR095	2317384011	SP K2 - Tablica TNK 2.2 IT ERGO (64384011)	\N	ELE	870	18	\N	2317384011	\N
LM_LC_ADR182	71496751	Licznik ciepła - Leonardo (71496751)	\N	LC	1290	19	\N	71496751	\N
LM_LH_ADR233	71497211	Licznik chłodu Leonardo L03 (71497211)	\N	LH	1530	19	\N	71497211	\N
LM_LH_ADR234	71497210	Licznik chłodu Leonardo L03 (71497210)	\N	LH	500	19	\N	71497210	\N
LM_ELE_ADR016	63326001	Centrala AHU 2 (63326001)	\N	ELE	1890	\N	\N	63326001	\N
LM_LC_ADR_B16	71150833	Licznik ciepła - Davide Lifestyle L00 (71150833)	\N	LC	2600	8	\N	71150833	\N
LM_LH_ADR_B21	71644763	Licznik chłodu - Davide Lifestyle L01 (71644763)	\N	LH	1110	8	\N	71644763	\N
LM_LH_ADR_B19	71644764	Licznik chłodu - Davide Lifestyle L01 (71644764)	\N	LH	1100	8	\N	71644764	\N
LM_LC_ADR_B18	71647821	Licznik ciepła - Davide Lifestyle L01 (71647821)	\N	LC	2440	8	\N	71647821	\N
LM_LC_ADR89	67884165	Licznik ciepła - grzejnik Davide (67884165)	\N	LC	1340	8	\N	67884165	\N
zdemontowany600	48503026G16412011087	Davide zdemontowany	\N	ELE	\N	8	\N	48503026G16412011087	\N
LM_LH_ADR189	71512143	Licznik chłodu - Les Amis L01 (strefa 2B) (71512143)	\N	LH	330	9	\N	71512143	\N
LM_LC_ADR184	71512150	Licznik ciepła - Les Amis (strefa 2B) (71512150)	\N	LC	260	9	\N	71512150	\N
LM_LC_ADR149	71512149	Licznik ciepła - Les Amis (71512149)	\N	LC	1220	9	\N	71512149	\N
LM_LH_ADR145	71512145	Licznik chłodu - Les Amis (71512145)	\N	LH	1360	9	\N	71512145	\N
LM_LH_ADR190	71512144	Licznik chłodu - Les Amis L01 (strefa 2A) (71512144)	\N	LH	1380	9	\N	71512144	\N
LM_LC_ADR186	71512152	Licznik ciepła - Les Amis (strefa 2A bliżej 1C) (71512152)	\N	LC	270	9	\N	71512152	\N
LM_LC_ADR183	71512151	Licznik ciepła - Les Amis (strefa 2A) (71512151)	\N	LC	1300	9	\N	71512151	\N
LM_LH_ADR191	71512148	Licznik chłodu - Les Amis L01 (strefa 2A bliżej 1C) (71512148)	\N	LH	1390	9	\N	71512148	\N
LM_LC_ADR187	71512153	Licznik ciepła - Les Amis (strefa 3D) (71512153)	\N	LC	280	9	\N	71512153	\N
LM_LH_ADR192	71512147	Licznik chłodu - Les Amis L01 (strefa 3D) (71512147)	\N	LH	1400	9	\N	71512147	\N
LM_LH_ADR122	71595108	Licznik chłodu - Centrale CulinaryOn (71595108)	\N	LH	320	7	\N	71595108	\N
LM_ELE_ADR078	48503028H16492010696	SP U4 - powierzchnia 0.06 CulinaryOn (16230375)	\N	ELE	50	7	\N	48503028H16492010696	\N
LM_LC_ADR123	71595107	Licznik ciepła - Centrale CulinaryOn (71595107)	\N	LC	120	7	\N	71595107	\N
LM_LH_ADR_B34	62065880	Licznik chłodu serwerownia najemcy L05 HBO serw - S (HC05) (62065880)	\N	LH	1120	2	\N	62065880	\N
LM_ELE_ADR029	2319334053	Licznik elektryczny - PZFD L03 (66334053)	\N	ELE	620	10	\N	2319334053	\N
LM_ELE_ADR091	2316362011	P4 centrala telefoniczna Play (63362011)	\N	ELE	2350	\N	\N	2316362011	\N
LM_ELE_ADR086	2318334004	SP 2 - Tablica TN 2.4 - Space Solution L01 (65334004)	\N	ELE	840	\N	\N	2318334004	\N
LM_LH_ADR197	78251268	Licznik chłodu obiegu FC - FO L-2 (78251268)	\N	LH	1430	\N	\N	78251268	\N
LM_LH_ADR_B23	71649391	Licznik chłodu - Fabiana L00 (71649391)	\N	LH	2510	\N	\N	71649391	\N
LM_LH_ADR_B25	71649390	Licznik chłodu - Corneliani L01 (71649390)	\N	LH	2520	\N	\N	71649390	\N
LM_ELE_ADR062	48503026G16402010541	SP U1 - Powierzchnia 0.04 - Fabiana Filippi L00 (16280856)	\N	ELE	750	\N	\N	48503026G16402010541	\N
LM_ELE_ADR065	BRAK	SP U1 - Powierzchnia 1.03	\N	ELE	760	\N	\N	BRAK	\N
LM_ELE_ADR070	16350646	SP U2 - Powierzchnia 0.12 (16350646)	\N	ELE	790	\N	\N	16350646	\N
LM_ELE_ADR073	BRAK	SP U3 - Powierzchnia 0.10	\N	ELE	810	\N	\N	BRAK	\N
LM_ELE_ADR023	63326018	Tablice T-TOZ (63326018)	\N	ELE	1930	\N	\N	63326018	\N
LM_ELE_ADR025	33344014	Tablice TA 2.-1, TA 2.2, TA 2.3, TA 2.4 (33344014)	\N	ELE	1940	\N	\N	33344014	\N
LM_ELE_ADR034	63325002	T-TEL (63325002)	\N	ELE	1960	\N	\N	63325002	\N
LM_ELE_ADR036	63326008	Rozdzielnica TWC2 (63326008)	\N	ELE	1970	\N	\N	63326008	\N
LM_ELE_ADR040	63284001	Tablica T-OGS (rezerwa) (63284001)	\N	ELE	1990	\N	\N	63284001	\N
LM_ELE_ADR042	63182019	Winda W1 (63182019)	\N	ELE	2000	\N	\N	63182019	\N
LM_ELE_ADR044	63354012	Winda W3 (63354012)	\N	ELE	2010	\N	\N	63354012	\N
LM_LC_ADR102	67219624	Licznik ciepła - grzejnik Almidecor (67219624)	\N	LC	1180	4	\N	67219624	\N
LM_LH_ADR218	78647935	Licznik chłodu FC L01 - AUDI (78647935)	\N	LH	440	11	\N	78647935	\N
LM_ELE_ADR107	1818415001	EON L04 (35415001)	\N	ELE	2160	17	\N	1818415001	\N
LM_LH_ADR_B47	71571363	Licznik chłodu - EON (71571363)	\N	LH	2240	17	\N	71571363	\N
LM_WOD_ADR_B75	73305841	Wodomierz- zimna woda - CulinaryOn (19726823)	Przed mroźnią	WOD	2340	7	Duża drabina	191183429A	1/2
LM_WOD_ADR238	77581163	Wodomierz Amaro L00 (18740019)	Nuta, korytarz, rewizja nisko	WOD	1700	13	\N	180702718A	3/4
LM_WOD_ADR_B81	58376979	Wodomierz - Fabiana (58376979)	\N	WOD	2370	\N	Niewymieniony - brak dostępu	58376979	\N
LM_WOD_ADR_B80	58376978	Wodomierz - Davide Lifestyle (58376978)	\N	WOD	2360	8	Niewymieniony - nie znaleziony	58376978	\N
LM_WOD_ADR_B74	77436045	Wodomierz - EON (19700657)	Przed kuchnią, przy szafach	WOD	2250	17	\N	190405578A	1/2
LM_LH_ADR_B46	71571362	Licznik chłodu - EON serwerownia (71571362)	\N	LH	2230	17	\N	71571362	\N
LM_ELE_ADR098	2317441033	SP K3 - Tablica TNK 3.2 IT ERGO (64441033)	\N	ELE	890	18	\N	2317441033	\N
LM_LH_ADR207	62065885	Licznik chłodu serwerownia IT ERGO (62065885)	\N	LH	1420	18	\N	62065885	\N
LM_ELE_ADR101	2318332002	Leonardo L03 TNK 4.3 (65332002)	\N	ELE	920	19	\N	2318332002	\N
LM_ELE_ADR100	2318355029	Leonardo L03 TN4.3 (65355029)	\N	ELE	910	19	\N	2318355029	\N
LM_ELE_ADR048	63325012	Winda W8 (63325012)	\N	ELE	2020	\N	\N	63325012	\N
LM_ELE_ADR051	63284036	Tablica TP 1.-2 (63284036)	\N	ELE	2030	\N	\N	63284036	\N
LM_ELE_ADR053	63265005	Tablica TP 2.-1 (63265005)	\N	ELE	2040	\N	\N	63265005	\N
LM_LC_ADR158	62065867	Licznik ciepła FC najemcy L03 - obieg FO (HC05, HC08) (62065867)	\N	LC	180	\N	\N	62065867	\N
LM_ELE_ADR021	33344042	Tablice TA 3.0, TA 3.1, TA 3.2 (33344042)	\N	ELE	40	\N	\N	33344042	\N
LM_ELE_ADR066	16380796	SP U1 - Powierzchnia 1.04 (16380796)	\N	ELE	60	\N	\N	16380796	\N
LM_ELE_ADR017	63311012	Rozdzielnica RW3 (63311012)	\N	ELE	550	\N	\N	63311012	\N
LM_LC_ADR156	62065878	Licznik ciepła FC - FR (62065878)	\N	LC	1230	\N	\N	62065878	\N
LM_LC_ADR155	78251253	Licznik ciepła FC - FO (78251253)	\N	LC	160	\N	\N	78251253	\N
LM_LC_ADR154	62065870	Licznik ciepła obiegu grzejników RAD (62065870)	\N	LC	150	\N	\N	62065870	\N
LM_LC_ADR152	62065879	Licznik ciepła obiegu AHU - AR (62065879)	\N	LC	1210	\N	\N	62065879	\N
LM_LC_ADR153	78251254	Licznik ciepła obiegu AO (78251254)	\N	LC	140	\N	\N	78251254	\N
LM_LC_ADR82	67884167	Licznik ciepła - grzejnik Corneliani (67884167)	\N	LC	310	\N	\N	67884167	\N
LM_ELE_ADR008	2316326010	AHU 3.3 NDI (63326010)	\N	ELE	530	\N	\N	2316326010	\N
LM_ELE_ADR064	BRAK	SP U1 - Powierzchnia 1.02	\N	ELE	2080	\N	\N	BRAK	\N
LM_ELE_ADR058	63284023	Tablica  T-UPS (63284023)	\N	ELE	2090	\N	\N	63284023	\N
LM_ELE_ADR074	BRAK	SP U3 - Powierzchnia 0.11	\N	ELE	2110	\N	\N	BRAK	\N
LM_ELE_ADR076	15420085	SP U4 - powierzchnia 0.16 (15420085)	\N	ELE	2120	\N	\N	15420085	\N
LM_ELE_ADR109	63371006	Magazyn U.02  (63371006)	\N	ELE	2180	\N	\N	63371006	\N
LM_WOD_ADR240	00207182	Wodomierz toalety L01 (00207182)	\N	WOD	1720	\N	\N	00207182	\N
LM_LH_ADR_B17	71644762	Licznik chłodu - Davide Lifestyle L00 (71644762)	\N	LH	2610	8	\N	71644762	\N
LM_ELE_ADR014	2316362007	Centrala AHU R4 Les Amis (63362007)	\N	ELE	1870	9	\N	2316362007	\N
LM_LH_ADR219	78675971	Licznik chłodu L03 MBDA (78675971)	\N	LH	1450	5	\N	78675971	\N
LM_LH_ADR220	78676883	Licznik chłodu L03 MBDA serwerownia (78676883)	\N	LH	1460	5	\N	78676883	\N
LM_LC_ADR173	78675879	Licznik ciepła L03 MBDA (78675879)	\N	LC	210	5	\N	78675879	\N
LM_ELE_ADR077	48503026G402010565	SP U4 - powierzchnia 0.13 CulinaryOn (16350655)	\N	ELE	820	7	\N	48503026G402010565	\N
LM_LC_ADR104	67887353	Licznik ciepła - grzejnik CulinaryOn (67887353)	\N	LC	1200	7	\N	67887353	\N
LM_LC_ADR_B26	71670106	Licznik ciepła - CulinaryOn L00 (71670106)	\N	LC	1060	7	\N	71670106	\N
LM_LC_ADR_B30	62065865	Licznik ciepła FC najemcy HBO L05 - obieg FO (HC01) (62065865)	\N	LC	1070	2	\N	62065865	\N
LM_LH_ADR_B37	62065888	Licznik chłodu serwerownia najemcy L05  HBO serw- S (HC01) (62065888)	\N	LH	1130	2	\N	62065888	\N
LM_LC_ADR_B41	78478336	Licznik ciepła - HBO L05 (78478336)	\N	LC	2490	2	\N	78478336	\N
LM_LH_ADR_B42	78478337	Licznik chłodu - HBO L05 (78478337)	\N	LH	1160	2	\N	78478337	\N
LM_LH_ADR221	71230687	Licznik chłodu L01 - ZEGNA (71230687)	\N	LH	450	21	\N	71230687	\N
LM_LC_ADR163	71888359	Licznik ciepła - ZEGNA L00 (71888359)	\N	LC	590	21	\N	71888359	\N
LM_LC_ADR164	71876833	Licznik ciepła - ZEGNA grzejniki L00 (71876833)	\N	LC	600	21	\N	71876833	\N
LM_LC_ADR174	71297057	Licznik ciepła L01 - ZEGNA (71297057)	\N	LC	220	21	\N	71297057	\N
LM_LH_ADR201	71834619	Licznik chłodu - ZEGNA L00 (71834619)	\N	LH	610	21	\N	71834619	\N
LM_LC_ADR32	80443474	Licznik ciepła - PZFD L03 (80443474)	\N	LC	300	10	\N	80443474	\N
LM_LC_ADR_B33	62065877	Licznik ciepła FC najemcy L05 Seewald - obieg FO (HC05, HC08) (62065877)	\N	LC	1090	3	\N	62065877	\N
LM_LH_ADR_B39	78251259	Licznik chłodu FC L05 Seewald - obieg FO (HC05, HC08) (78251259) (MWh)	\N	LH	1140	3	\N	78251259	\N
LM_LH_ADR227	80120069	Licznik chłodu L00 - GCN/Almidecor (80120069)	\N	LH	470	1	\N	80120069	\N
LM_LC_ADR103	67676944	Licznik ciepła - grzejnik GCN (67676944)	\N	LC	1190	1	\N	67676944	\N
LM_WOD_ADR241	00207171	Wodomierz toalety L00 (00207171)	\N	WOD	1730	\N	\N	00207171	\N
LM_ELE_ADR128	08216809	po KSP (w szachcie L01 na solution) (08216809)	\N	ELE	1750	\N	\N	08216809	\N
LM_ELE_ADR002	63354008	AHU 2.4 HOGAN LOVELS (63354008)	\N	ELE	1800	\N	\N	63354008	\N
LM_WOD_ADR141	16838217	Wodomierz piano 2 (16838217)	\N	WOD	1630	\N	\N	16838217	\N
LM_WOD_ADR142	16803909	Wodomierz TWC (16803909)	\N	WOD	1640	\N	\N	16803909	\N
LM_ELE_ADR043	63354018	Winda W2 (63354018)	\N	ELE	2290	\N	\N	63354018	\N
LM_ELE_ADR_B11	63284007	Licznik elektryczny Rozdzielnica RW2, RPCH- TRANE2(63284007)	\N	ELE	2300	\N	\N	63284007	\N
LM_ELE_ADR019	63326006	Rozdzielnica T-TAR (63326006)	\N	ELE	560	\N	\N	63326006	\N
LM_ELE_ADR024	63325014	Tablice TA 1.2, TA 1.3, TA 1.4, TA 1.5 (63325014)	\N	ELE	570	\N	\N	63325014	\N
LM_ELE_ADR041	63325008	Tablica T-WC (63325008)	\N	ELE	650	\N	\N	63325008	\N
LM_ELE_ADR045	63354004	Winda W4 (63354004)	\N	ELE	660	\N	\N	63354004	\N
LM_ELE_ADR047	63354016	Winda W7 (63354016)	\N	ELE	670	\N	\N	63354016	\N
LM_ELE_ADR052	63265003	Tablica TP 1.-1 (63265003)	\N	ELE	690	\N	\N	63265003	\N
LM_ELE_ADR038	1816332105	Rozdzielnia RPCH (33332105)	\N	ELE	640	\N	\N	1816332105	\N
LM_ELE_ADR_B06	1816331030	Licznik elektryczny Chiller CHI1 (33331030)	\N	ELE	2260	\N	\N	1816331030	\N
LM_ELE_ADR071	48503026H16502010220	SP U2 - Almidecor (dawniej powierzchnia 1.07) (16410250)	\N	ELE	800	4	\N	48503026H16502010220	\N
LM_LH_ADR217	78647934	Licznik chłodu FC L00 - AUDI (78647934)	\N	LH	1500	11	\N	78647934	\N
LM_LC_ADR171	78647936	Licznik ciepła L00 - AUDI (78647936)	\N	LC	1240	11	\N	78647936	\N
LM_LH_ADR232	78675881	Licznik chłodu - AUDI serwerownia (78675881)	\N	LH	1520	11	\N	78675881	\N
LM_LC_ADR178	78675880	Licznik ciepła L-1 - AUDI - grzejniki (78675880)	\N	LC	250	11	\N	78675880	\N
LM_LC_ADR172	78647937	Licznik ciepła L01 - AUDI (78647937)	\N	LC	20	11	\N	78647937	\N
LM_ELE_ADR114	1816331023	Licznik elektryczny AUDI - TU4 (33331023)	\N	ELE	1550	11	\N	1816331023	\N
LM_ELE_ADR039	1816344019	Tablica T-Piano W.Kruk (33344019)	\N	ELE	1980	16	\N	1816344019	\N
LM_LC_ADR161	62065874	Licznik ciepła FC najemcy L02 - obieg FO (HC01) IT ERGO (62065874)	\N	LC	1320	18	\N	62065874	\N
LM_ELE_ADR011	2316371001	AHU 2.2 IT ERGO (63371001)	\N	ELE	1850	18	\N	2316371001	\N
LM_ELE_ADR080	2317445010	SP 1 - Tablica TN 1.2 (64445010)	\N	ELE	70	18	\N	2317445010	\N
LM_ELE_ADR009	2316362010	AHU 3.2 IT ERGO (63362010)	\N	ELE	1840	18	\N	2316362010	\N
LM_WOD_ADR143	161032822	Brama wjazdowa (16838122)	\N	WOD	1650	\N	\N	161032822	\N
LM_ELE_ADR054	63265011	Tablica TP 1.1, TP 1.3, TP 1.5 (63265011)	\N	ELE	700	\N	\N	63265011	\N
LM_ELE_ADR057	63284015	Tablica  TP-WIND (63284015)	\N	ELE	710	\N	\N	63284015	\N
LM_ELE_ADR060	BRAK	SP U1 - Powierzchnia 0.02	\N	ELE	730	\N	\N	BRAK	\N
LM_ELE_ADR061	BRAK	SP U1 - Powierzchnia 0.03	\N	ELE	740	\N	\N	BRAK	\N
LM_ELE_ADR111	63371013	Magazyn U.04 FABIANA FILLIPPI (63371013)	\N	ELE	930	\N	\N	63371013	\N
LM_ELE_ADR116	63371010	AHU R4K (63371010)	\N	ELE	940	\N	\N	63371010	\N
LM_ELE_ADR118	63362009	AHU B1 (63362009)	\N	ELE	950	\N	\N	63362009	\N
LM_ELE_ADR119	63362017	AHU T (63362017)	\N	ELE	960	\N	\N	63362017	\N
LM_ELE_ADR_B01	16380762	Licznik elektryczny - Corneliani (16380762)	\N	ELE	2410	\N	\N	16380762	\N
LM_ELE_ADR_B10	63284002	Licznik elektryczny - Rozdzielnica RW1 (63284002)	\N	ELE	2420	\N	\N	63284002	\N
LM_WOD_ADR_B76	16838219	Wodomierz od strony ul. Książęcej L04 (16838219)	\N	WOD	2580	\N	\N	16838219	\N
LM_WOD_ADR_B77	16838216	Wodomierz od Kruka L04 (16838216)	\N	WOD	2590	\N	\N	16838216	\N
LM_ELE_ADR018	63326011	Rozdzielnica RM (63326011)	\N	ELE	1900	\N	\N	63326011	\N
LM_ELE_ADR020	63311020	Tablice TA 3.3, TA 3.4, TA 3.5 (63311020)	\N	ELE	1910	\N	\N	63311020	\N
LM_ELE_ADR022	33344025	Tablice TA 2.-1, TA 2.2, TA 2.3, TA 2.4 (33344025)	\N	ELE	1920	\N	\N	33344025	\N
LM_ELE_ADR015	2316326007	AHU R1 ALMIDECOR (63326007)	\N	ELE	1880	\N	\N	2316326007	\N
LM_ELE_ADR_B05	1816331016	Licznik elektryczny Chiller CHI2 (33331016)	\N	ELE	2390	\N	\N	1816331016	\N
LM_LC_ADR_B31	62065868	Licznik ciepła FC najemcy L04 Hogan58 - obieg FO (HC05, HC08) (62065868)	\N	LC	2480	15	\N	62065868	\N
LM_LH_ADR_B40	78251265	Licznik chłodu FC L04 Hogan - obieg FO (HC01) (78251265) (MWh)	\N	LH	1150	15	\N	78251265	\N
LM_LH_ADR_B38	78251257	Licznik chłodu FC L04 Hogan - obieg FO (HC05, HC08) (78251257) (MWh)	\N	LH	2560	15	\N	78251257	\N
LM_LH_ADR223	80032572	Licznik chłodu L01 - Almidecor (80032572)	\N	LH	1470	4	\N	80032572	\N
LM_LC_ADR175	80096039	Licznik ciepła L00 - Almidecor (80096039)	\N	LC	230	4	\N	80096039	\N
LM_LH_ADR222	80032573	Licznik chłodu L00 - Almidecor (80032573)	\N	LH	460	4	\N	80032573	\N
LM_LC_ADR176	80096038	Licznik ciepła L01 - Almidecor (80096038)	\N	LC	240	4	\N	80096038	\N
LM_ELE_ADR121	1818137046	Amaro L00 (35137046)	Amaro, we od recepcji Pl. 3 Krzyży, korytarzyk w lewo, po lewej tablica elektryczna	ELE	1740	13	\N	1818137046	\N
LM_ELE_ADR046	2316354008	Solution space TN 1.1 - TU5 (63325003)	\N	ELE	2270	6	\N	2316354008	\N
LM_ELE_ADR_B02	16380819	Licznik elektryczny - Davide Lifestyle (16380819)	\N	ELE	2430	8	\N	16380819	\N
LM_WOD_ADR148	00214876	Wodomierz MBDA (00214876)	\N	WOD	1670	5	\N	00214876	\N
LM_LH_ADR_B27	71670180	Licznik chłodu - CulinaryOn L00 (71670180)	\N	LH	2530	7	\N	71670180	\N
LM_ELE_ADR003	2316354013	AHU 2.5 HBO (63354013)	\N	ELE	1810	2	\N	2316354013	\N
LM_ELE_ADR006	2316326004	AHU 1.5 HBO (63326004)	\N	ELE	1820	2	\N	2316326004	\N
LM_ELE_ADR124	1816331007	ZEGNA - TU 2 (RGNN) (33331007)	\N	ELE	2320	21	\N	1816331007	\N
LM_WOD_ADR30	19737052	Wodomierz PZFD L03 (19737052)	\N	WOD	1780	10	\N	19737052	\N
LM_ELE_ADR_B12	272103494	Licznik elektryczny Seewald kuchnia 1 (11111111)	\N	ELE	2630	3	\N	272103494	\N
LM_ELE_ADR_B13	272103657	Licznik elektryczny Seewald kuchnia 2 (22222222)	\N	ELE	2640	3	\N	272103657	\N
LM_LC_ADR168	80087616	Licznik ciepła L00 GCN (80087616)	\N	LC	200	1	\N	80087616	\N
LM_LH_ADR226	80120070	Licznik chłodu FC L00 - GCN (80120070)	\N	LH	1490	1	\N	80120070	\N
LM_LC_ADR_B46	80087615	Licznik ciepła GCN (80087615)	\N	LC	2650	1	\N	80087615	\N
LM_LC_ADR224	71705791	Licznik ciepła - Amaro grzejniki  (licznik na L-1) (71505791)	\N	LC	1330	13	\N	71705791	\N
LM_ELE_ADR027	2316311028	AHU R5 AMARO (63311028)	\N	ELE	580	13	\N	2316311028	\N
LM_ELE_ADR110	2316371014	Amaro - magazyn (63371014)	\N	ELE	2190	13	\N	2316371014	\N
LM_LH_ADR_B44	80255450	Licznik chłodu Centrala Amaro (80255450)	\N	LH	2570	13	\N	80255450	\N
LM_LC_ADR_B43	80255449	Licznik ciepła  - Centrala Amaro (80255449)	\N	LC	2500	13	\N	80255449	\N
LM_ELE_ADR049	2316354002	Winda Piano W.Kruk (63354002)	\N	ELE	680	16	\N	2316354002	\N
LM_LC_ADR_B45	71522586	Licznik ciepła EON (71522586)	\N	LC	2220	17	\N	71522586	\N
LM_ELE_ADR087	2317441065	SP 3 - Tablica TN 3.2 IT ERGO (64441065)	\N	ELE	2210	18	\N	2317441065	\N
LM_WOD_ADR132	77436051	Wodomierz ERGO - pomieszczenie(17360035)	Pokój sprzątaczek, np WC	WOD	1570	18	\N	17FA358454Q	1/2
LM_WOD_ADR133	77435192	Wodomierz ERGO - recepcja (17360039)	Przy recepcji, między WC	WOD	1580	18	\N	17FA358457T	1/2
LM_WOD_ADR_B78	60600683	Wodomierz HBO (00129890)	\N	WOD	1170	2	Niewymieniony	60600683	\N
LM_WOD_ADR150	60882996	Wodomierz AUDI (00228857)	\N	WOD	1680	11	Niewymieniony - nie znaleziony	60882996	\N
LM_WOD_ADR135	77902822	Wodomierz Hogan Lovells L04 - od Książecej (77902822)	\N	WOD	1600	15	Niewymieniony - jeden zawór, za mała rewizja	77902822	\N
LM_ELE_ADR013	2316362006	AHU 1.2 IT ERGO (63362006)	\N	ELE	1860	18	\N	2316362006	\N
LM_LC_ADR157	62065866	Licznik ciepła FC najemcy L02 - obieg FO (HC05, HC08) IT ERGO (62065866)	\N	LC	170	18	\N	62065866	\N
LM_LC_ADR151	78059564	Główny licznik ciepła budynku L-1 (78059564)	\N	LC	130	\N	\N	78059564	\N
LM_LH_ADR198	78251269	Licznik chłodu obiegu FC - FR L-2 (78251269)	\N	LH	360	\N	\N	78251269	\N
LM_LH_ADR194	78251261	Licznik chłodu obieg AHU - AO L-2 (78251261)	\N	LH	1410	\N	\N	78251261	\N
LM_LH_ADR195	78251260	Licznik chłodu AHU - AR (78251260)	\N	LH	340	\N	\N	78251260	\N
LM_LH_ADR196	78251264	Licznik chłodu obiegu serwerowni S - L-2 (78251264)	\N	LH	350	\N	\N	78251264	\N
LM_LH_ADR199	78251263	Licznik chłodu FC L02 - obieg FO IT ERGO (HC05, HC08) (78251263)	\N	LH	80	18	\N	78251263	\N
LM_LH_ADR211	62065882	Licznik chłodu serwerownia najemcy L02 - S (HC01) (62065882)	\N	LH	410	18	\N	62065882	\N
LM_ELE_ADR055	63265006	Tablica TP 2.3 (63265006)	\N	ELE	2050	\N	\N	63265006	\N
LM_ELE_ADR056	63284037	Tablica  TP 3.1, TP 3.3, TP 3.5 (63284037)	\N	ELE	2060	\N	\N	63284037	\N
LM_ELE_ADR063	BRAK	SP U1 - Powierzchnia 0.05	\N	ELE	2070	\N	\N	BRAK	\N
LM_ELE_ADR_B08	1817261013	Licznik elektryczny SP 1 Hogan - Tablica TN 1.4 (34261013)	\N	ELE	1050	15	\N	1817261013	\N
LM_ELE_ADR_B07	1817174066	Licznik elektryczny SP 3 Hogan - Tablica TN 3.4 (34174066)	\N	ELE	1040	15	\N	1817174066	\N
LM_ELE_ADR_B03	1517162019	Licznik elektryczny SP K1 Hogan - Tablica TNK 1.4 (04162019)	\N	ELE	1030	15	\N	1517162019	\N
LM_ELE_ADR_B04	1816331005	Licznik elektryczny Chiller CHI3 (33331005)	\N	ELE	2380	\N	\N	1816331005	\N
LM_ELE_ADR112	2316362018	AHU R2 AUDI (63362018)	\N	ELE	2330	\N	\N	2316362018	\N
LM_ELE_ADR068	48503026H16472010039	SP U2 - Heban - Powierzchnia 0.07 (16390068)	\N	ELE	780	\N	\N	48503026H16472010039	\N
LM_ELE_ADR125	1517311047	Hogan - logo (04311047)	\N	ELE	2670	15	\N	1517311047	\N
LM_ELE_ADR120	2316326003	Centrala Amaro AHU N2 - RW4 (63326003)	\N	ELE	970	13	\N	2316326003	\N
LM_ELE_ADR059	2317445001	SP K1 - Tablica TNK 1.2 - IT ERGO (64445001)	\N	ELE	720	18	\N	2317445001	\N
LM_ELE_ADR084	2317445019	SP 2 - Tablica TN 2.2 IT ERGO (64445019)	\N	ELE	830	18	\N	2317445019	\N
LM_LC_ADR170	80091629	Licznik ciepła L03 NDI (80091629)	\N	LC	10	20	\N	80091629	\N
LM_ELE_ADR088	2318245036	SP 3 - Tablica TN 3.3 - NDI (65245036)	\N	ELE	850	20	\N	2318245036	\N
LM_LH_ADR216	80091630	Licznik chłodu FC L03 - NDI Serwerownia (80091630)	\N	LH	430	20	\N	80091630	\N
LM_LH_ADR215	80091631	Licznik chłodu FC L03 - NDI (80091631)	\N	LH	1440	20	\N	80091631	\N
recznie2010	48503026H16502010235	TPSA	Centrala telefoniczna -2	\N	\N	\N	\N	48503026H16502010235	\N
LM_ELE_ADR067	48503026H16502010235	SP U1 - Powierzchnia 1.05 (16380761)	Technogim szynotor	ELE	770	\N	\N	48503026H16502010235	\N
LM_ELE_ADR081	2316354003	SP 1 - Solution Space L01 TN 1.1 (TU5) (63354003)	\N	ELE	2130	6	nr fabryczny z pliku Wojtka	2316354003	\N
LM_LH_ADR204	78251262	Licznik chłodu Solution Space L03 szacht (78251262)	\N	LH	390	6	\N	78251262	\N
LM_ELE_ADR090	2318334011	SP 3 - Tablica TN 3.5 - Solution Space L00 (65334011)	\N	ELE	2150	6	\N	2318334011	\N
LM_LC_ADR162	62065876	Licznik ciepła - Solution Space L03 (62065876)	\N	LC	190	6	\N	62065876	\N
LM_ELE_ADR028	2316362014	AHU R6 SOLUTION SPACE L01 (63362014)	\N	ELE	1950	6	\N	2316362014	\N
LM_ELE_ADR012	2316362002	AHU 1.3 SOLUTION SPACE L03 (63362002)	\N	ELE	540	6	\N	2316362002	\N
LM_ELE_ADR099	2318352007	SP K3 - Tablica TN 1.3 - Solution Space L03 (65352007)	\N	ELE	900	6	\N	2318352007	\N
LM_LH_ADR228	80271297	Licznik chłodu Solution Space L00 (80271297)	\N	LH	1510	6	\N	80271297	\N
LM_LC_ADR165	80108185	Licznik ciepła - Solution Space grzejniki L-1 (80108185)	\N	LC	1250	6	\N	80108185	\N
LM_LC_ADR_B20	71150834	Licznik ciepła - Davide Lifestyle L01 (71150834)	\N	LC	2450	8	\N	71150834	\N
LM_ELE_ADR072	48503026H16502010251	SP U3 - MBDA tablica TNK (dawniej powierzchnia 0.09) (16380803)	\N	ELE	2100	5	\N	48503026H16502010251	\N
recznie160	2316326009	CulinaryOn	Rozdzielnia szafa 14	ELE	\N	7	\N	2316326009	\N
recznie190	71516192	CulinaryOn	pokój 50 poziom1	LH	\N	7	\N	71516192	\N
recznie150	48503028H16492010700	CulinaryOn z drabiną	CulinaryOn +1	ELE	\N	7	\N	48503028H16492010700	\N
LM_ELE_ADR_B09	1817261024	SP 1 - Główny licznik elektryczny HBO (34261024)	\N	ELE	2400	2	\N	1817261024	\N
recznie1530	620665888	HBO	HBO od Książencej	LH	\N	2	\N	620665888	\N
recznie1400	80137646	Green Cafe Nero WL klimakonwektory	poziom +1 Solutions duża kuchnia	LH	\N	1	\N	80137646	\N
recznie330	1816332087	LesAmis	Rozdzielnia szafa 14	ELE	\N	9	\N	1816332087	\N
LM_LH_ADR33	80446698	Licznik chłodu - PZFD L03 (80446698)	\N	LH	520	10	\N	80446698	\N
LM_ELE_ADR069	48503028H16492010698	Green Cafe Nero GCN (15270553)	\N	ELE	2680	1	\N	48503028H16492010698	\N
LM_WOD_ADR250_Solution Space	77435199	Wodomierz Solution Space łazienki L03 (18733482)	Poziom 3, WC damski przy pok 120	WOD	1770	6	\N	181173780A	1/2
recznie1480	77581168	HBO - Podlewanie dachu	Pokój kurierów	WOD	\N	2	\N	160559458	3/4
LM_WOD_ADR247_Solution Space	77436047	Wodomierz Solution Space łazienki L01 (18734980)	WC damska, nad umywalką z lewej	WOD	1760	6	\N	181072960A	1/2
recznie1090	77435219	MBDA woda (214876 albo 500641936)	MBDA kuchnia, sufit za 2 lampą 	WOD	\N	5	\N	36254453	1/2
LM_WOD_ADR248_Solution Space	77436034	Wodomierz Solution Space kuchnia 2 (18733476)	Szafa np drzwi w kanciapie sprzątaczek 3p	WOD	1020	6	\N	181174655A	1/2
LM_WOD_ADR129	76305864	Wodomierz ZEGNA L01 (18727749)	Poziom 1, przy drzwiach nad szafą	WOD	980	21	\N	181106629A	1/2
recznie1420	60587375	Wodomierz Seewald	Toalety obok szklanych drzwi, drabinka	WOD	\N	3	Niewymieniony - za mała rewizja	60587375	\N
recznie70	57783922	Almidecor wodomierz	Almidecor +1, rewizja pod umywalką	WOD	\N	4	Niewymieniony - jeden zawór, za licznikiem	57783922	\N
recznie10	77436059	Wodomierz zieleń Seewald	Dach obok chillera	WOD	\N	3	Brak nasadki	1920543256	1/2
LM_LC_ADR166	80138392	Licznik ciepła - Solution Space grzejniki L-1 (80138392)	\N	LC	1260	6	\N	80138392	\N
LM_LC_ADR181	80272797	Licznik ciepła  - Solution Space L01 (80272797)	\N	LC	1280	6	\N	80272797	\N
LM_LH_ADR230	80271298	Licznik chłodu Solution Space L01 (80271298)	\N	LH	1540	6	\N	80271298	\N
LM_LC_ADR180	80272796	Licznik ciepła  - Solution Space L01 (80272796)	\N	LC	1270	6	\N	80272796	\N
LM_LH_ADR229	80271273	Licznik chłodu Solution Space L01 (80271273)	\N	LH	480	6	\N	80271273	\N
LM_LH_ADR212	62065884	Licznik chłodu Solution Space L03 serwerownia (62065884)	\N	LH	420	6	\N	62065884	\N
LM_LH_ADR231	71259540	Licznik chłodu Solution Space L01 (71259540)	\N	LH	490	6	\N	71259540	\N
LM_ELE_ADR085	65341010	SP K3 - Tablica TNK 3.2 - Solution Space L01 (65341010)	\N	ELE	2140	6	\N	65341010	\N
LM_ELE_ADR097	65341005	SP K3 - Tablica TNK 3.2 - Solution Space L03 (65341005)	\N	ELE	880	6	\N	65341005	\N
LM_LC_ADR179	80272795	Licznik ciepła  - Solution Space L00 (80272795)	\N	LC	30	6	\N	80272795	\N
recznie590	48503026H16502010252	Davide ręcznie z dużą drabiną	Davide poziom 0	ELE	\N	8	\N	48503026H16502010252	\N
recznie610	48503026H16502010237	Davide ręcznie z dużą drabiną	Davide poziom 0	ELE	\N	8	\N	48503026H16502010237	\N
zdemontowany580	48503026H16472010063	Davide zdemontowany	\N	ELE	\N	8	\N	48503026H16472010063	\N
LM_LH_ADR188	71512146	Licznik chłodu - Les Amis L00 (strefa 4B) (71512146)	\N	LH	1370	9	\N	71512146	\N
LM_LC_ADR193	67884166	Licznik ciepła - Les Amis (nad barem) (67884166)	\N	LC	2660	9	\N	67884166	\N
LM_ELE_ADR115	2316371005	AHU R3KZ Les Amis (63371005)	\N	ELE	90	9	\N	2316371005	\N
LM_ELE_ADR113	2316371016	AHU R3 LES AMIS (63371016)	\N	ELE	2200	9	\N	2316371016	\N
LM_ELE_ADR094	1818244023	Licznik elektryczny - Les Amis L01 (35244023)	\N	ELE	860	9	\N	1818244023	\N
LM_ELE_ADR010	2316371007	AHU 2.3 MBDA (63371007)	\N	ELE	2280	5	\N	2316371007	\N
LM_ELE_ADR075	48503026H16502010245	SP U3 - MBDA tablica TN (16380798)	\N	ELE	2690	5	\N	48503026H16502010245	\N
LM_ELE_ADR108	2316371009	Magazyn U.01  HBO Magazyn (63371009)	\N	ELE	2170	2	\N	2316371009	\N
LM_LH_ADR_B35	620665881	Licznik chłodu najemcy FC L05 HBO serw - obieg FO (HC01) (62065881)	\N	LH	2540	2	\N	620665881	\N
LM_WOD_ADR237	77435203	Wodomierz LES AMIS (18740005)	Rozdz. elekt. sufit czujka dymu	WOD	1690	9	\N	181235653A	1/2
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

COPY public.odczyty (data, adres, odczyt, status) FROM stdin;
2022-07-01	LM_LC_ADR170	57.38	\N
2022-07-01	LM_LC_ADR172	136.26	\N
2022-07-01	LM_LC_ADR179	88.44	\N
2022-07-01	LM_ELE_ADR021	290944.91	\N
2022-07-01	LM_ELE_ADR078	57593	\N
2022-07-01	LM_ELE_ADR066	0	\N
2022-07-01	LM_ELE_ADR080	180056.63	\N
2022-07-01	LM_LH_ADR199	150.7	\N
2022-07-01	LM_ELE_ADR115	27858.97	\N
2022-07-01	LM_WOD_ADR249_Solution Space	117.16	\N
2022-07-01	LM_WOD_MAIN_W	0	\N
2022-07-01	LM_LC_ADR123	547.3	\N
2022-07-01	LM_LC_ADR151	31384	\N
2022-07-01	LM_LC_ADR153	10646	\N
2022-07-01	LM_LC_ADR154	2756.7	\N
2022-07-01	LM_LC_ADR155	7219.3	\N
2022-07-01	LM_LC_ADR157	1136.1	\N
2022-07-01	LM_LC_ADR158	371	\N
2022-07-01	LM_LC_ADR162	812.9	\N
2022-07-01	LM_LC_ADR168	120.8	\N
2022-07-01	LM_LC_ADR173	103.38	\N
2022-07-01	LM_LC_ADR174	224.2	\N
2022-07-01	LM_LC_ADR175	0	\N
2022-07-01	LM_LC_ADR176	85.9	\N
2022-07-01	LM_LC_ADR178	142.9	\N
2022-07-01	LM_LC_ADR184	45.23	\N
2022-07-01	LM_LC_ADR186	19.23	\N
2022-07-01	LM_LC_ADR187	32.69	\N
2022-07-01	LM_LC_ADR209	0	\N
2022-07-01	LM_LC_ADR32	0	\N
2022-07-01	LM_LC_ADR82	30.91	\N
2022-07-01	LM_LH_ADR122	18.9	\N
2022-07-01	LM_LH_ADR189	65.2	\N
2022-07-01	LM_LH_ADR195	466.2	\N
2022-07-01	LM_LH_ADR196	9	\N
2022-07-01	LM_LH_ADR198	1328.1	\N
2022-07-01	LM_LH_ADR200	50.8	\N
2022-07-01	LM_LH_ADR203	230.5	\N
2022-07-01	LM_LH_ADR204	108.2	\N
2022-07-01	LM_LH_ADR208	341.5	\N
2022-07-01	LM_LH_ADR211	42.8	\N
2022-07-01	LM_LH_ADR212	220.5	\N
2022-07-01	LM_LH_ADR216	37.57	\N
2022-07-01	LM_LH_ADR218	470.4	\N
2022-07-01	LM_LH_ADR221	388	\N
2022-07-01	LM_LH_ADR222	0	\N
2022-07-01	LM_LH_ADR227	41.2	\N
2022-07-01	LM_LH_ADR229	0	\N
2022-07-01	LM_LH_ADR231	0	\N
2022-07-01	LM_LH_ADR234	0	\N
2022-07-01	LM_LH_ADR235	93.8	\N
2022-07-01	LM_LH_ADR33	0	\N
2022-07-01	LM_ELE_ADR008	107658.1	\N
2022-07-01	LM_ELE_ADR012	95750.37	\N
2022-07-01	LM_ELE_ADR017	13458.34	\N
2022-07-01	LM_ELE_ADR019	4038.61	\N
2022-07-01	LM_ELE_ADR024	132698.83	\N
2022-07-01	LM_ELE_ADR027	36475.91	\N
2022-07-01	LM_LC_ADR163	31.06	\N
2022-07-01	LM_LC_ADR164	0.02	\N
2022-07-01	LM_LH_ADR201	108.3	\N
2022-07-01	LM_ELE_ADR029	14653.02	\N
2022-07-01	LM_ELE_ADR031	197992.11	\N
2022-07-01	LM_ELE_ADR038	387295.59	\N
2022-07-01	LM_ELE_ADR041	69146.05	\N
2022-07-01	LM_ELE_ADR045	6263.06	\N
2022-07-01	LM_ELE_ADR047	5546.5	\N
2022-07-01	LM_ELE_ADR049	15252.18	\N
2022-07-01	LM_ELE_ADR052	11577.88	\N
2022-07-01	LM_ELE_ADR054	32078.85	\N
2022-07-01	LM_ELE_ADR057	6386.44	\N
2022-07-01	LM_ELE_ADR059	25007.72	\N
2022-07-01	LM_ELE_ADR060	0	\N
2022-07-01	LM_ELE_ADR061	0	\N
2022-07-01	LM_ELE_ADR062	24203	\N
2022-07-01	LM_ELE_ADR065	0	\N
2022-07-01	LM_ELE_ADR067	336	\N
2022-07-01	LM_ELE_ADR068	11055	\N
2022-07-01	LM_ELE_ADR070	88	\N
2022-07-01	LM_ELE_ADR071	84632	\N
2022-07-01	LM_ELE_ADR073	88	\N
2022-07-01	LM_ELE_ADR077	1063	\N
2022-07-01	LM_ELE_ADR084	57216.79	\N
2022-07-01	LM_ELE_ADR086	16308.78	\N
2022-07-01	LM_ELE_ADR088	41588.69	\N
2022-07-01	LM_ELE_ADR094	1495.76	\N
2022-07-01	LM_ELE_ADR095	107784.38	\N
2022-07-01	LM_ELE_ADR097	35288.88	\N
2022-07-01	LM_ELE_ADR098	3693.79	\N
2022-07-01	LM_ELE_ADR099	90719.15	\N
2022-07-01	LM_ELE_ADR100	20164.65	\N
2022-07-01	LM_ELE_ADR101	8377.45	\N
2022-07-01	LM_ELE_ADR111	362.62	\N
2022-07-01	LM_ELE_ADR116	15151.01	\N
2022-07-01	LM_ELE_ADR118	21845.7	\N
2022-07-01	LM_ELE_ADR119	78925.78	\N
2022-07-01	LM_ELE_ADR120	96175.71	\N
2022-07-01	LM_WOD_ADR129	129.81	\N
2022-07-01	LM_WOD_ADR140	123.6	\N
2022-07-01	LM_WOD_ADR147	63.56	\N
2022-07-01	LM_WOD_ADR246_Solution Space	592.42	\N
2022-07-01	LM_WOD_ADR248_Solution Space	51.98	\N
2022-07-01	LM_ELE_ADR_B03	133927.86	\N
2022-07-01	LM_ELE_ADR_B07	106398.84	\N
2022-07-01	LM_ELE_ADR_B08	158308.77	\N
2022-07-01	LM_LC_ADR_B26	171.16	\N
2022-07-01	LM_LC_ADR_B30	451.8	\N
2022-07-01	LM_LC_ADR_B32	994.1	\N
2022-07-01	LM_LC_ADR_B33	898.8	\N
2022-07-01	LM_LH_ADR_B19	108.4	\N
2022-07-01	LM_LH_ADR_B21	207.5	\N
2022-07-01	LM_LH_ADR_B34	0	\N
2022-07-01	LM_LH_ADR_B37	0.4	\N
2022-07-01	LM_LH_ADR_B39	103.5	\N
2022-07-01	LM_LH_ADR_B40	174.9	\N
2022-07-01	LM_LH_ADR_B42	0	\N
2022-07-01	LM_WOD_ADR_B78	197.93	\N
2022-07-01	LM_LC_ADR102	56.01	\N
2022-07-01	LM_LC_ADR103	61.7	\N
2022-07-01	LM_LC_ADR104	83.61	\N
2022-07-01	LM_LC_ADR152	5154.3	\N
2022-07-01	LM_LC_ADR149	0.91	\N
2022-07-01	LM_LC_ADR156	3673.9	\N
2022-07-01	LM_LC_ADR171	308.38	\N
2022-07-01	LM_LC_ADR165	51.82	\N
2022-07-01	LM_LC_ADR166	40.61	\N
2022-07-01	LM_LC_ADR180	148	\N
2022-07-01	LM_LC_ADR181	0.1	\N
2022-07-01	LM_LC_ADR182	93.4	\N
2022-07-01	LM_LC_ADR183	1.42	\N
2022-07-01	LM_LC_ADR185	19.25	\N
2022-07-01	LM_LC_ADR161	1487.9	\N
2022-07-01	LM_LC_ADR224	176.36	\N
2022-07-01	LM_LC_ADR89	40.1	\N
2022-07-01	LM_LC_ADR93	39.61	\N
2022-07-01	LM_LH_ADR145	10.07	\N
2022-07-01	LM_LH_ADR188	32.18	\N
2022-07-01	LM_LH_ADR190	7.89	\N
2022-07-01	LM_LH_ADR191	18.8	\N
2022-07-01	LM_LH_ADR192	0	\N
2022-07-01	LM_LH_ADR194	0	\N
2022-07-01	LM_LH_ADR207	431.3	\N
2022-07-01	LM_LH_ADR197	1328.7	\N
2022-07-01	LM_LH_ADR215	0	\N
2022-07-01	LM_LH_ADR219	0.03	\N
2022-07-01	LM_LH_ADR220	112.2	\N
2022-07-01	LM_LH_ADR223	209.7	\N
2022-07-01	LM_LH_ADR225	73.5	\N
2022-07-01	LM_LH_ADR226	83.76	\N
2022-07-01	LM_LH_ADR217	529.6	\N
2022-07-01	LM_LH_ADR228	32.1	\N
2022-07-01	LM_LH_ADR232	63.11	\N
2022-07-01	LM_LH_ADR233	49.1	\N
2022-07-01	LM_LH_ADR230	1.7	\N
2022-07-01	LM_ELE_ADR114	27.81	\N
2022-07-01	LM_ELE_ADR117	22970.57	\N
2022-07-01	LM_WOD_ADR132	311.92	\N
2022-07-01	LM_WOD_ADR133	358.08	\N
2022-07-01	LM_WOD_ADR134	19	\N
2022-07-01	LM_WOD_ADR135	0	\N
2022-07-01	LM_WOD_ADR136	72.41	\N
2022-07-01	LM_WOD_ADR139	1572.9	\N
2022-07-01	LM_WOD_ADR141	17	\N
2022-07-01	LM_WOD_ADR142	36	\N
2022-07-01	LM_WOD_ADR143	582.86	\N
2022-07-01	LM_WOD_ADR146	32184	\N
2022-07-01	LM_WOD_ADR148	0.04	\N
2022-07-01	LM_WOD_ADR150	44.07	\N
2022-07-01	LM_WOD_ADR237	924.63	\N
2022-07-01	LM_WOD_ADR238	2543.96	\N
2022-07-01	LM_WOD_ADR239	37.72	\N
2022-07-01	LM_WOD_ADR240	148.24	\N
2022-07-01	LM_WOD_ADR241	283.56	\N
2022-07-01	LM_ELE_ADR121	222733.06	\N
2022-07-01	LM_ELE_ADR128	0	\N
2022-07-01	LM_WOD_ADR247_Solution Space	634.2	\N
2022-07-01	LM_WOD_ADR250_Solution Space	219.77	\N
2022-07-01	LM_WOD_ADR30	0	\N
2022-07-01	LM_ELE_ADR001	72028.56	\N
2022-07-01	LM_ELE_ADR002	93230.48	\N
2022-07-01	LM_ELE_ADR003	125026.27	\N
2022-07-01	LM_ELE_ADR006	0	\N
2022-07-01	LM_ELE_ADR007	144870.08	\N
2022-07-01	LM_ELE_ADR009	196862.67	\N
2022-07-01	LM_ELE_ADR011	178260.88	\N
2022-07-01	LM_ELE_ADR013	235891.63	\N
2022-07-01	LM_ELE_ADR014	15599.71	\N
2022-07-01	LM_ELE_ADR015	138966.39	\N
2022-07-01	LM_ELE_ADR016	975281.94	\N
2022-07-01	LM_ELE_ADR018	13873.74	\N
2022-07-01	LM_ELE_ADR020	142979.61	\N
2022-07-01	LM_ELE_ADR022	173347.95	\N
2022-07-01	LM_ELE_ADR023	37106.97	\N
2022-07-01	LM_ELE_ADR025	601433.13	\N
2022-07-01	LM_ELE_ADR028	19956.12	\N
2022-07-01	LM_ELE_ADR034	31908.06	\N
2022-07-01	LM_ELE_ADR036	93833.78	\N
2022-07-01	LM_ELE_ADR039	386735.59	\N
2022-07-01	LM_ELE_ADR040	36656.9	\N
2022-07-01	LM_ELE_ADR042	3663.7	\N
2022-07-01	LM_ELE_ADR044	7087.78	\N
2022-07-01	LM_ELE_ADR048	7455.55	\N
2022-07-01	LM_ELE_ADR051	7149.27	\N
2022-07-01	LM_ELE_ADR053	29548.03	\N
2022-07-01	LM_ELE_ADR055	5903.21	\N
2022-07-01	LM_ELE_ADR056	0	\N
2022-07-01	LM_ELE_ADR063	190	\N
2022-07-01	LM_ELE_ADR064	0	\N
2022-07-01	LM_ELE_ADR058	86380.9	\N
2022-07-01	LM_ELE_ADR072	28553	\N
2022-07-01	LM_ELE_ADR074	84632	\N
2022-07-01	LM_ELE_ADR076	0	\N
2022-07-01	LM_ELE_ADR081	69447.65	\N
2022-07-01	LM_ELE_ADR085	62098.68	\N
2022-07-01	LM_ELE_ADR090	42335.07	\N
2022-07-01	LM_ELE_ADR107	91734.39	\N
2022-07-01	LM_ELE_ADR108	7133.66	\N
2022-07-01	LM_ELE_ADR109	2038.88	\N
2022-07-01	LM_ELE_ADR110	415.27	\N
2022-07-01	LM_ELE_ADR113	57066.96	\N
2022-07-01	LM_ELE_ADR087	92304.4	\N
2022-07-01	LM_LC_ADR_B45	222.55	\N
2022-07-01	LM_LH_ADR_B46	49.35	\N
2022-07-01	LM_LH_ADR_B47	132	\N
2022-07-01	LM_WOD_ADR_B74	39.11	\N
2022-07-01	LM_ELE_ADR_B06	507190.53	\N
2022-07-01	LM_ELE_ADR046	0	\N
2022-07-01	LM_ELE_ADR010	124094.37	\N
2022-07-01	LM_ELE_ADR043	2961.62	\N
2022-07-01	LM_ELE_ADR_B11	35375.25	\N
2022-07-01	LM_WOD_ADR242	45.09	\N
2022-07-01	LM_ELE_ADR124	120544.22	\N
2022-07-01	LM_ELE_ADR112	746744.88	\N
2022-07-01	LM_WOD_ADR_B75	186.2	\N
2022-07-01	LM_ELE_ADR091	13055.05	\N
2022-07-01	LM_WOD_ADR_B80	134.02	\N
2022-07-01	LM_WOD_ADR_B81	46.57	\N
2022-07-01	LM_ELE_ADR_B04	288663.16	\N
2022-07-01	LM_ELE_ADR_B05	276909.94	\N
2022-07-01	LM_ELE_ADR_B09	309238.09	\N
2022-07-01	LM_ELE_ADR_B01	0	\N
2022-07-01	LM_ELE_ADR_B10	31900.8	\N
2022-07-01	LM_ELE_ADR_B02	0	\N
2022-07-01	LM_LC_ADR_B18	18.8	\N
2022-07-01	LM_LC_ADR_B20	69.82	\N
2022-07-01	LM_LC_ADR_B22	56.38	\N
2022-07-01	LM_LC_ADR_B24	10.69	\N
2022-07-01	LM_LC_ADR_B31	465.2	\N
2022-07-01	LM_LC_ADR_B41	529.7	\N
2022-07-01	LM_LC_ADR_B43	9.2	\N
2022-07-01	LM_LH_ADR_B23	73.9	\N
2022-07-01	LM_LH_ADR_B25	77.7	\N
2022-07-01	LM_LH_ADR_B27	162.3	\N
2022-07-01	LM_LH_ADR_B35	0	\N
2022-07-01	LM_LH_ADR_B36	0	\N
2022-07-01	LM_LH_ADR_B38	74.1	\N
2022-07-01	LM_LH_ADR_B44	4.6	\N
2022-07-01	LM_WOD_ADR_B76	1741.49	\N
2022-07-01	LM_WOD_ADR_B77	9.06	\N
2022-07-01	LM_LC_ADR_B16	38.82	\N
2022-07-01	LM_LH_ADR_B17	56.8	\N
2022-07-01	LM_WOD_ADR_B79	360.11	\N
2022-07-01	LM_ELE_ADR_B12	19276.73	\N
2022-07-01	LM_ELE_ADR_B13	15053.19	\N
2022-07-01	LM_LC_ADR_B46	58.87	\N
2022-07-01	LM_LC_ADR193	0	\N
2022-07-01	LM_ELE_ADR125	5112.76	\N
2022-07-01	LM_ELE_ADR069	317187	\N
2021-06-01	LM_LC_ADR170	48.89	\N
2021-06-01	LM_LC_ADR172	90.12	\N
2021-06-01	LM_LC_ADR179	70.6	\N
2021-06-01	LM_ELE_ADR021	192566.34	\N
2021-06-01	LM_ELE_ADR078	35268	\N
2021-06-01	LM_ELE_ADR066	0	\N
2021-06-01	LM_ELE_ADR080	144294.8	\N
2021-06-01	LM_LH_ADR199	117.2	\N
2021-06-01	LM_ELE_ADR115	20223.93	\N
2021-06-01	LM_WOD_ADR249_Solution Space	68.05	\N
2021-06-01	LM_WOD_MAIN_W	0	\N
2021-06-01	LM_LC_ADR123	363.4	\N
2021-06-01	LM_LC_ADR151	25963	\N
2021-06-01	LM_LC_ADR153	9212	\N
2021-06-01	LM_LC_ADR154	2096.1	\N
2021-06-01	LM_LC_ADR155	5619.7	\N
2021-06-01	LM_LC_ADR157	903.4	\N
2021-06-01	LM_LC_ADR158	282.5	\N
2021-06-01	LM_LC_ADR162	656.6	\N
2021-06-01	LM_LC_ADR168	69	\N
2021-06-01	LM_LC_ADR173	79.31	\N
2021-06-01	LM_LC_ADR174	133.64	\N
2021-06-01	LM_LC_ADR175	0	\N
2021-06-01	LM_LC_ADR176	84.6	\N
2021-06-01	LM_LC_ADR178	95.2	\N
2021-06-01	LM_LC_ADR184	38.96	\N
2021-06-01	LM_LC_ADR186	15.54	\N
2021-06-01	LM_LC_ADR187	29.04	\N
2021-06-01	LM_LC_ADR209	84.19	\N
2021-06-01	LM_LC_ADR32	0	\N
2021-06-01	LM_LC_ADR82	0	\N
2021-06-01	LM_LH_ADR122	9.1	\N
2021-06-01	LM_LH_ADR189	40.53	\N
2021-06-01	LM_LH_ADR195	330.6	\N
2021-06-01	LM_LH_ADR196	9	\N
2021-06-01	LM_LH_ADR198	951.3	\N
2021-06-01	LM_LH_ADR200	37.9	\N
2021-06-01	LM_LH_ADR203	194.8	\N
2021-06-01	LM_LH_ADR204	76.4	\N
2021-06-01	LM_LH_ADR208	239.3	\N
2021-06-01	LM_LH_ADR211	17.1	\N
2021-06-01	LM_LH_ADR212	94.5	\N
2021-06-01	LM_LH_ADR216	26.15	\N
2021-06-01	LM_LH_ADR218	320.5	\N
2021-06-01	LM_LH_ADR221	209.5	\N
2021-06-01	LM_LH_ADR222	0	\N
2021-06-01	LM_LH_ADR227	28	\N
2021-06-01	LM_LH_ADR229	82.16	\N
2021-06-01	LM_LH_ADR231	0	\N
2021-06-01	LM_LH_ADR234	0	\N
2021-06-01	LM_LH_ADR235	78	\N
2021-06-01	LM_LH_ADR33	0	\N
2021-06-01	LM_ELE_ADR008	73981.53	\N
2021-06-01	LM_ELE_ADR012	58983.29	\N
2021-06-01	LM_ELE_ADR017	10418.6	\N
2021-06-01	LM_ELE_ADR019	2439.5	\N
2021-06-01	LM_ELE_ADR024	105229.13	\N
2021-06-01	LM_ELE_ADR027	33393.04	\N
2021-06-01	LM_LC_ADR163	26.44	\N
2021-06-01	LM_LC_ADR164	0.02	\N
2021-06-01	LM_LH_ADR201	49.5	\N
2021-06-01	LM_ELE_ADR029	8793.51	\N
2021-06-01	LM_ELE_ADR031	135128.66	\N
2021-06-01	LM_ELE_ADR038	245291.06	\N
2021-06-01	LM_ELE_ADR041	56748.99	\N
2021-06-01	LM_ELE_ADR045	4896.31	\N
2021-06-01	LM_ELE_ADR047	4383.63	\N
2021-06-01	LM_ELE_ADR049	12459.6	\N
2021-06-01	LM_ELE_ADR052	9261.37	\N
2021-06-01	LM_ELE_ADR054	25997.03	\N
2021-06-01	LM_ELE_ADR057	5152.67	\N
2021-06-01	LM_ELE_ADR059	18866.35	\N
2021-06-01	LM_ELE_ADR060	0	\N
2021-06-01	LM_ELE_ADR061	0	\N
2021-06-01	LM_ELE_ADR062	15578	\N
2021-06-01	LM_ELE_ADR065	0	\N
2021-06-01	LM_ELE_ADR067	125	\N
2021-06-01	LM_ELE_ADR068	385	\N
2021-06-01	LM_ELE_ADR070	80	\N
2021-06-01	LM_ELE_ADR071	60950	\N
2021-06-01	LM_ELE_ADR073	80	\N
2021-06-01	LM_ELE_ADR077	1063	\N
2021-06-01	LM_ELE_ADR084	47209.16	\N
2021-06-01	LM_ELE_ADR086	10480.78	\N
2021-06-01	LM_ELE_ADR088	29262.2	\N
2021-06-01	LM_ELE_ADR094	1238.7	\N
2021-06-01	LM_ELE_ADR095	80342.51	\N
2021-06-01	LM_ELE_ADR097	21701.48	\N
2021-06-01	LM_ELE_ADR098	2909.97	\N
2021-06-01	LM_ELE_ADR099	53031.18	\N
2021-06-01	LM_ELE_ADR100	12352	\N
2021-06-01	LM_ELE_ADR101	5822.82	\N
2021-06-01	LM_ELE_ADR111	362.07	\N
2021-06-01	LM_ELE_ADR116	7935.64	\N
2021-06-01	LM_ELE_ADR118	17897.09	\N
2021-06-01	LM_ELE_ADR119	61974.37	\N
2021-06-01	LM_ELE_ADR120	72537.47	\N
2021-06-01	LM_WOD_ADR129	85.72	\N
2021-06-01	LM_WOD_ADR140	120.03	\N
2021-06-01	LM_WOD_ADR147	49.13	\N
2021-06-01	LM_WOD_ADR246_Solution Space	387.23	\N
2021-06-01	LM_WOD_ADR248_Solution Space	27.93	\N
2021-06-01	LM_ELE_ADR_B03	107709.4	\N
2021-06-01	LM_ELE_ADR_B07	85880.59	\N
2021-06-01	LM_ELE_ADR_B08	128213.57	\N
2021-06-01	LM_LC_ADR_B26	104.64	\N
2021-06-01	LM_LC_ADR_B30	342.8	\N
2021-06-01	LM_LC_ADR_B32	764.8	\N
2021-06-01	LM_LC_ADR_B33	649.8	\N
2021-06-01	LM_LH_ADR_B19	67.6	\N
2021-06-01	LM_LH_ADR_B21	142.4	\N
2021-06-01	LM_LH_ADR_B34	0	\N
2021-06-01	LM_LH_ADR_B37	0.4	\N
2021-06-01	LM_LH_ADR_B39	78.6	\N
2021-06-01	LM_LH_ADR_B40	136	\N
2021-06-01	LM_LH_ADR_B42	0	\N
2021-06-01	LM_WOD_ADR_B78	173.38	\N
2021-06-01	LM_LC_ADR102	40.84	\N
2021-06-01	LM_LC_ADR103	44.89	\N
2021-06-01	LM_LC_ADR104	54.69	\N
2021-06-01	LM_LC_ADR152	4236	\N
2021-06-01	LM_LC_ADR149	0.91	\N
2021-06-01	LM_LC_ADR156	2744.9	\N
2021-06-01	LM_LC_ADR171	238.8	\N
2021-06-01	LM_LC_ADR165	35.77	\N
2021-06-01	LM_LC_ADR166	28.91	\N
2021-06-01	LM_LC_ADR180	123.7	\N
2021-06-01	LM_LC_ADR181	0.1	\N
2021-06-01	LM_LC_ADR182	73.3	\N
2021-06-01	LM_LC_ADR183	1.42	\N
2021-06-01	LM_LC_ADR185	16.13	\N
2021-06-01	LM_LC_ADR161	1198.1	\N
2021-06-01	LM_LC_ADR224	123.62	\N
2021-06-01	LM_LC_ADR89	26.01	\N
2021-06-01	LM_LC_ADR93	25.51	\N
2021-06-01	LM_LH_ADR145	5.54	\N
2021-06-01	LM_LH_ADR188	19.44	\N
2021-06-01	LM_LH_ADR190	5.29	\N
2021-06-01	LM_LH_ADR191	13	\N
2021-06-01	LM_LH_ADR192	0	\N
2021-06-01	LM_LH_ADR194	670.3	\N
2021-06-01	LM_LH_ADR207	378.2	\N
2021-06-01	LM_LH_ADR197	1082.6	\N
2021-06-01	LM_LH_ADR215	0	\N
2021-06-01	LM_LH_ADR219	0.02	\N
2021-06-01	LM_LH_ADR220	71.98	\N
2021-06-01	LM_LH_ADR223	130.4	\N
2021-06-01	LM_LH_ADR225	52	\N
2021-06-01	LM_LH_ADR226	50.97	\N
2021-06-01	LM_LH_ADR217	424.7	\N
2021-06-01	LM_LH_ADR228	26.5	\N
2021-06-01	LM_LH_ADR232	45.08	\N
2021-06-01	LM_LH_ADR233	33.1	\N
2021-06-01	LM_LH_ADR230	1.5	\N
2021-06-01	LM_ELE_ADR114	207899.48	\N
2021-06-01	LM_ELE_ADR117	20134.77	\N
2021-06-01	LM_WOD_ADR132	254.46	\N
2021-06-01	LM_WOD_ADR133	316.99	\N
2021-06-01	LM_WOD_ADR134	18.02	\N
2021-06-01	LM_WOD_ADR135	0	\N
2021-06-01	LM_WOD_ADR136	60.77	\N
2021-06-01	LM_WOD_ADR139	1032.98	\N
2021-06-01	LM_WOD_ADR141	17	\N
2021-06-01	LM_WOD_ADR142	36	\N
2021-06-01	LM_WOD_ADR143	299.54	\N
2021-06-01	LM_WOD_ADR146	24155.3	\N
2021-06-01	LM_WOD_ADR148	0.05	\N
2021-06-01	LM_WOD_ADR150	32.02	\N
2021-06-01	LM_WOD_ADR237	779.2	\N
2021-06-01	LM_WOD_ADR238	2209.21	\N
2021-06-01	LM_WOD_ADR239	25.78	\N
2021-06-01	LM_WOD_ADR240	88.61	\N
2021-06-01	LM_WOD_ADR241	880.08	\N
2021-06-01	LM_ELE_ADR121	85.44	\N
2021-06-01	LM_ELE_ADR128	0	\N
2021-06-01	LM_WOD_ADR247_Solution Space	350.96	\N
2021-06-01	LM_WOD_ADR250_Solution Space	127.6	\N
2021-06-01	LM_WOD_ADR30	0	\N
2021-06-01	LM_ELE_ADR001	56427.91	\N
2021-06-01	LM_ELE_ADR002	75395.06	\N
2021-06-01	LM_ELE_ADR003	90935.47	\N
2021-06-01	LM_ELE_ADR006	65550.22	\N
2021-06-01	LM_ELE_ADR007	110943.97	\N
2021-06-01	LM_ELE_ADR009	152491.48	\N
2021-06-01	LM_ELE_ADR011	150191.86	\N
2021-06-01	LM_ELE_ADR013	191491.58	\N
2021-06-01	LM_ELE_ADR014	11440.88	\N
2021-06-01	LM_ELE_ADR015	105475.88	\N
2021-06-01	LM_ELE_ADR016	821760.81	\N
2021-06-01	LM_ELE_ADR018	10877.55	\N
2021-06-01	LM_ELE_ADR020	114805.68	\N
2021-06-01	LM_ELE_ADR022	109758.09	\N
2021-06-01	LM_ELE_ADR023	23986.56	\N
2021-06-01	LM_ELE_ADR025	321945.44	\N
2021-06-01	LM_ELE_ADR028	15546.67	\N
2021-06-01	LM_ELE_ADR034	17813.01	\N
2021-06-01	LM_ELE_ADR036	77533.31	\N
2021-06-01	LM_ELE_ADR039	262252.56	\N
2021-06-01	LM_ELE_ADR040	29531	\N
2021-06-01	LM_ELE_ADR042	2900.5	\N
2021-06-01	LM_ELE_ADR044	5800.44	\N
2021-06-01	LM_ELE_ADR048	6095.32	\N
2021-06-01	LM_ELE_ADR051	5774.04	\N
2021-06-01	LM_ELE_ADR053	15347.95	\N
2021-06-01	LM_ELE_ADR055	4731.25	\N
2021-06-01	LM_ELE_ADR056	18394.74	\N
2021-06-01	LM_ELE_ADR063	189	\N
2021-06-01	LM_ELE_ADR064	0	\N
2021-06-01	LM_ELE_ADR058	68719.66	\N
2021-06-01	LM_ELE_ADR072	19575	\N
2021-06-01	LM_ELE_ADR074	60950	\N
2021-06-01	LM_ELE_ADR076	0	\N
2021-06-01	LM_ELE_ADR081	35676.77	\N
2021-06-01	LM_ELE_ADR085	34477.14	\N
2021-06-01	LM_ELE_ADR090	31482.06	\N
2021-06-01	LM_ELE_ADR107	60698.46	\N
2021-06-01	LM_ELE_ADR108	5774.78	\N
2021-06-01	LM_ELE_ADR109	2010.96	\N
2021-06-01	LM_ELE_ADR110	406.22	\N
2021-06-01	LM_ELE_ADR113	43660.87	\N
2021-06-01	LM_ELE_ADR087	75488.87	\N
2021-06-01	LM_LC_ADR_B45	146.87	\N
2021-06-01	LM_LH_ADR_B46	49.35	\N
2021-06-01	LM_LH_ADR_B47	83.5	\N
2021-06-01	LM_WOD_ADR_B74	25.52	\N
2021-06-01	LM_ELE_ADR_B06	356973.25	\N
2021-06-01	LM_ELE_ADR046	0	\N
2021-06-01	LM_ELE_ADR010	96480.23	\N
2021-06-01	LM_ELE_ADR043	2298.65	\N
2021-06-01	LM_ELE_ADR_B11	26790.12	\N
2021-06-01	LM_WOD_ADR242	40.24	\N
2021-06-01	LM_ELE_ADR124	52028.99	\N
2021-06-01	LM_ELE_ADR112	645954.81	\N
2021-06-01	LM_WOD_ADR_B75	122.52	\N
2021-06-01	LM_ELE_ADR091	8611.27	\N
2021-06-01	LM_WOD_ADR_B80	87.54	\N
2021-06-01	LM_WOD_ADR_B81	35.62	\N
2021-06-01	LM_ELE_ADR_B04	211503.73	\N
2021-06-01	LM_ELE_ADR_B05	189549.97	\N
2021-06-01	LM_ELE_ADR_B09	246870.89	\N
2021-06-01	LM_ELE_ADR_B01	0	\N
2021-06-01	LM_ELE_ADR_B10	25096.67	\N
2021-06-01	LM_ELE_ADR_B02	0	\N
2021-06-01	LM_LC_ADR_B18	14.46	\N
2021-06-01	LM_LC_ADR_B20	58.11	\N
2021-06-01	LM_LC_ADR_B22	30.35	\N
2021-06-01	LM_LC_ADR_B24	10	\N
2021-06-01	LM_LC_ADR_B31	350	\N
2021-06-01	LM_LC_ADR_B41	382.8	\N
2021-06-01	LM_LC_ADR_B43	5.3	\N
2021-06-01	LM_LH_ADR_B23	44.4	\N
2021-06-01	LM_LH_ADR_B25	24	\N
2021-06-01	LM_LH_ADR_B27	79.9	\N
2021-06-01	LM_LH_ADR_B35	0	\N
2021-06-01	LM_LH_ADR_B36	0	\N
2021-06-01	LM_LH_ADR_B38	61.8	\N
2021-06-01	LM_LH_ADR_B44	3.4	\N
2021-06-01	LM_WOD_ADR_B76	1242.51	\N
2021-06-01	LM_WOD_ADR_B77	5.52	\N
2021-06-01	LM_LC_ADR_B16	32.45	\N
2021-06-01	LM_LH_ADR_B17	38.4	\N
2021-06-01	LM_WOD_ADR_B79	315.17	\N
2021-06-01	LM_ELE_ADR_B12	13608.09	\N
2021-06-01	LM_ELE_ADR_B13	13060.88	\N
2021-06-01	LM_LC_ADR_B46	45.07	\N
2021-06-01	LM_LC_ADR193	0	\N
2021-06-01	LM_ELE_ADR125	3967.1	\N
2021-06-01	LM_ELE_ADR069	237816	\N
2021-06-01	LM_ELE_ADR075	80	\N
2022-07-01	LM_ELE_ADR075	11724	\N
2022-07-01	LM_LC_ADR159	5030	\N
2022-07-01	LM_LC_ADR160	13230	\N
2022-07-01	LM_LH_ADR167	5720	\N
2022-07-01	LM_WOD_ADR236	16.77	\N
2022-07-01	zdemontowany580	6	\N
2022-07-01	zdemontowany600	3194	\N
2022-08-01	LM_LC_ADR170	57.4	\N
2022-08-01	LM_LC_ADR172	136.39	\N
2022-08-01	LM_LC_ADR179	88.44	\N
2022-08-01	LM_ELE_ADR021	293087.91	\N
2022-08-01	LM_ELE_ADR078	58053	\N
2022-08-01	LM_ELE_ADR066	0	\N
2022-08-01	LM_ELE_ADR080	181621.42	\N
2022-08-01	LM_LH_ADR199	153.4	\N
2022-08-01	LM_ELE_ADR115	28235.14	\N
2022-08-01	LM_WOD_ADR249_Solution Space	120.29	\N
2022-08-01	LM_WOD_MAIN_W	0	\N
2022-08-01	LM_LC_ADR123	547.8	\N
2022-08-01	LM_LC_ADR151	31411	\N
2022-08-01	LM_LC_ADR153	10652	\N
2022-08-01	LM_LC_ADR154	2763.5	\N
2022-08-01	LM_LC_ADR155	7226.4	\N
2022-08-01	LM_LC_ADR157	1137.9	\N
2022-08-01	LM_LC_ADR158	371.5	\N
2022-08-01	LM_LC_ADR162	813.3	\N
2022-08-01	LM_LC_ADR168	121	\N
2022-08-01	LM_LC_ADR173	103.51	\N
2022-08-01	LM_LC_ADR174	225.35	\N
2022-08-01	LM_LC_ADR175	0	\N
2022-08-01	LM_LC_ADR176	85.9	\N
2022-08-01	LM_LC_ADR178	143.34	\N
2022-08-01	LM_LC_ADR184	45.23	\N
2022-08-01	LM_LC_ADR186	19.23	\N
2022-08-01	LM_LC_ADR187	32.69	\N
2022-08-01	LM_LC_ADR209	0	\N
2022-08-01	LM_LC_ADR32	0	\N
2022-08-01	LM_LC_ADR82	31.21	\N
2022-08-01	LM_LH_ADR122	19.6	\N
2022-08-01	LM_LH_ADR189	67.47	\N
2022-08-01	LM_LH_ADR195	479.7	\N
2022-08-01	LM_LH_ADR196	9	\N
2022-08-01	LM_LH_ADR198	1350.9	\N
2022-08-01	LM_LH_ADR200	51.5	\N
2022-08-01	LM_LH_ADR203	232.3	\N
2022-08-01	LM_LH_ADR204	110.6	\N
2022-08-01	LM_LH_ADR208	346.3	\N
2022-08-01	LM_LH_ADR211	43.9	\N
2022-08-01	LM_LH_ADR212	226.9	\N
2022-08-01	LM_LH_ADR216	38.47	\N
2022-08-01	LM_LH_ADR218	480.8	\N
2022-08-01	LM_LH_ADR221	398.2	\N
2022-08-01	LM_LH_ADR222	0	\N
2022-08-01	LM_LH_ADR227	44	\N
2022-08-01	LM_LH_ADR229	0	\N
2022-08-01	LM_LH_ADR231	0	\N
2022-08-01	LM_LH_ADR234	0	\N
2022-08-01	LM_LH_ADR235	95.8	\N
2022-08-01	LM_LH_ADR33	0	\N
2022-08-01	LM_ELE_ADR008	108768.02	\N
2022-08-01	LM_ELE_ADR012	96431.96	\N
2022-08-01	LM_ELE_ADR017	13533.61	\N
2022-08-01	LM_ELE_ADR019	4038.63	\N
2022-08-01	LM_ELE_ADR024	134131.23	\N
2022-08-01	LM_ELE_ADR027	36475.91	\N
2022-08-01	LM_LC_ADR163	31.06	\N
2022-08-01	LM_LC_ADR164	0.02	\N
2022-08-01	LM_LH_ADR201	113.2	\N
2022-08-01	LM_ELE_ADR029	14973.24	\N
2022-08-01	LM_ELE_ADR031	199787.88	\N
2022-08-01	LM_ELE_ADR038	394251.91	\N
2022-08-01	LM_ELE_ADR041	69367.37	\N
2022-08-01	LM_ELE_ADR045	6330.15	\N
2022-08-01	LM_ELE_ADR047	5604.81	\N
2022-08-01	LM_ELE_ADR049	15381.68	\N
2022-08-01	LM_ELE_ADR052	11686.83	\N
2022-08-01	LM_ELE_ADR054	32364.25	\N
2022-08-01	LM_ELE_ADR057	6445.27	\N
2022-08-01	LM_ELE_ADR059	25294.68	\N
2022-08-01	LM_ELE_ADR060	0	\N
2022-08-01	LM_ELE_ADR061	0	\N
2022-08-01	LM_ELE_ADR062	24593	\N
2022-08-01	LM_ELE_ADR065	0	\N
2022-08-01	LM_ELE_ADR067	336	\N
2022-08-01	LM_ELE_ADR068	11728	\N
2022-08-01	LM_ELE_ADR070	88	\N
2022-08-01	LM_ELE_ADR071	85753	\N
2022-08-01	LM_ELE_ADR073	88	\N
2022-08-01	LM_ELE_ADR077	1063	\N
2022-08-01	LM_ELE_ADR084	57587.74	\N
2022-08-01	LM_ELE_ADR086	16615.18	\N
2022-08-01	LM_ELE_ADR088	42106.51	\N
2022-08-01	LM_ELE_ADR094	1495.96	\N
2022-08-01	LM_ELE_ADR095	109122.55	\N
2022-08-01	LM_ELE_ADR097	36023.88	\N
2022-08-01	LM_ELE_ADR098	3734.85	\N
2022-08-01	LM_ELE_ADR099	92508.73	\N
2022-08-01	LM_ELE_ADR100	20457.24	\N
2022-08-01	LM_ELE_ADR101	8503.86	\N
2022-08-01	LM_ELE_ADR111	362.63	\N
2022-08-01	LM_ELE_ADR116	15151.01	\N
2022-08-01	LM_ELE_ADR118	22003.1	\N
2022-08-01	LM_ELE_ADR119	79595.05	\N
2022-08-01	LM_ELE_ADR120	97760.04	\N
2022-08-01	LM_WOD_ADR129	131.71	\N
2022-08-01	LM_WOD_ADR140	123.74	\N
2022-08-01	LM_WOD_ADR147	64.22	\N
2022-08-01	LM_WOD_ADR246_Solution Space	602.2	\N
2022-08-01	LM_WOD_ADR248_Solution Space	53.25	\N
2022-08-01	LM_ELE_ADR_B03	135678.06	\N
2022-08-01	LM_ELE_ADR_B07	107862.08	\N
2022-08-01	LM_ELE_ADR_B08	160286.33	\N
2022-08-01	LM_LC_ADR_B26	171.18	\N
2022-08-01	LM_LC_ADR_B30	452.5	\N
2022-08-01	LM_LC_ADR_B32	994.6	\N
2022-08-01	LM_LC_ADR_B33	899.7	\N
2022-08-01	LM_LH_ADR_B19	109.6	\N
2022-08-01	LM_LH_ADR_B21	210.3	\N
2022-08-01	LM_LH_ADR_B34	0	\N
2022-08-01	LM_LH_ADR_B37	0.4	\N
2022-08-01	LM_LH_ADR_B39	107.6	\N
2022-08-01	LM_LH_ADR_B40	181.1	\N
2022-08-01	LM_LH_ADR_B42	0	\N
2022-08-01	LM_WOD_ADR_B78	200.09	\N
2022-08-01	LM_LC_ADR102	56.15	\N
2022-08-01	LM_LC_ADR103	61.86	\N
2022-08-01	LM_LC_ADR104	83.87	\N
2022-08-01	LM_LC_ADR152	5158.5	\N
2022-08-01	LM_LC_ADR149	0.91	\N
2022-08-01	LM_LC_ADR156	3678.7	\N
2022-08-01	LM_LC_ADR171	308.95	\N
2022-08-01	LM_LC_ADR165	51.99	\N
2022-08-01	LM_LC_ADR166	40.73	\N
2022-08-01	LM_LC_ADR180	148	\N
2022-08-01	LM_LC_ADR181	0.1	\N
2022-08-01	LM_LC_ADR182	93.44	\N
2022-08-01	LM_LC_ADR183	1.42	\N
2022-08-01	LM_LC_ADR185	19.25	\N
2022-08-01	LM_LC_ADR161	1489	\N
2022-08-01	LM_LC_ADR224	176.88	\N
2022-08-01	LM_LC_ADR89	40.23	\N
2022-08-01	LM_LC_ADR93	39.74	\N
2022-08-01	LM_LH_ADR145	10.07	\N
2022-08-01	LM_LH_ADR188	32.18	\N
2022-08-01	LM_LH_ADR190	7.89	\N
2022-08-01	LM_LH_ADR191	18.8	\N
2022-08-01	LM_LH_ADR192	0	\N
2022-08-01	LM_LH_ADR194	0	\N
2022-08-01	LM_LH_ADR207	433.7	\N
2022-08-01	LM_LH_ADR197	1345	\N
2022-08-01	LM_LH_ADR215	0	\N
2022-08-01	LM_LH_ADR219	0.03	\N
2022-08-01	LM_LH_ADR220	112.2	\N
2022-08-01	LM_LH_ADR223	217	\N
2022-08-01	LM_LH_ADR225	77.2	\N
2022-08-01	LM_LH_ADR226	83.76	\N
2022-08-01	LM_LH_ADR217	537.7	\N
2022-08-01	LM_LH_ADR228	34	\N
2022-08-01	LM_LH_ADR232	63.94	\N
2022-08-01	LM_LH_ADR233	50	\N
2022-08-01	LM_LH_ADR230	1.8	\N
2022-08-01	LM_ELE_ADR114	301041.94	\N
2022-08-01	LM_ELE_ADR117	23072.57	\N
2022-08-01	LM_WOD_ADR132	313.98	\N
2022-08-01	LM_WOD_ADR133	360.1	\N
2022-08-01	LM_WOD_ADR134	19.01	\N
2022-08-01	LM_WOD_ADR135	0	\N
2022-08-01	LM_WOD_ADR136	72.91	\N
2022-08-01	LM_WOD_ADR139	1600.48	\N
2022-08-01	LM_WOD_ADR141	17	\N
2022-08-01	LM_WOD_ADR142	36	\N
2022-08-01	LM_WOD_ADR143	582.86	\N
2022-08-01	LM_WOD_ADR146	32583	\N
2022-08-01	LM_WOD_ADR148	0.04	\N
2022-08-01	LM_WOD_ADR150	44.59	\N
2022-08-01	LM_WOD_ADR237	924.64	\N
2022-08-01	LM_WOD_ADR238	2543.96	\N
2022-08-01	LM_WOD_ADR239	38.48	\N
2022-08-01	LM_WOD_ADR240	151.23	\N
2022-08-01	LM_WOD_ADR241	328.41	\N
2022-08-01	LM_ELE_ADR121	227845.25	\N
2022-08-01	LM_ELE_ADR128	0	\N
2022-08-01	LM_WOD_ADR247_Solution Space	644.72	\N
2022-08-01	LM_WOD_ADR250_Solution Space	223.05	\N
2022-08-01	LM_WOD_ADR30	0	\N
2022-08-01	LM_ELE_ADR001	72979.99	\N
2022-08-01	LM_ELE_ADR002	93956.62	\N
2022-08-01	LM_ELE_ADR003	125330.03	\N
2022-08-01	LM_ELE_ADR006	0	\N
2022-08-01	LM_ELE_ADR007	145559.05	\N
2022-08-01	LM_ELE_ADR009	197472.42	\N
2022-08-01	LM_ELE_ADR011	178793.27	\N
2022-08-01	LM_ELE_ADR013	236800.28	\N
2022-08-01	LM_ELE_ADR014	15771.5	\N
2022-08-01	LM_ELE_ADR015	140218.45	\N
2022-08-01	LM_ELE_ADR016	980949.25	\N
2022-08-01	LM_ELE_ADR018	14001.45	\N
2022-08-01	LM_ELE_ADR020	143992.3	\N
2022-08-01	LM_ELE_ADR022	174643.36	\N
2022-08-01	LM_ELE_ADR023	37740.97	\N
2022-08-01	LM_ELE_ADR025	616090.38	\N
2022-08-01	LM_ELE_ADR028	19982.99	\N
2022-08-01	LM_ELE_ADR034	32556.35	\N
2022-08-01	LM_ELE_ADR036	94115.63	\N
2022-08-01	LM_ELE_ADR039	390408.16	\N
2022-08-01	LM_ELE_ADR040	36656.9	\N
2022-08-01	LM_ELE_ADR042	3696.53	\N
2022-08-01	LM_ELE_ADR044	7150.33	\N
2022-08-01	LM_ELE_ADR048	7520.34	\N
2022-08-01	LM_ELE_ADR051	7214.82	\N
2022-08-01	LM_ELE_ADR053	30526.02	\N
2022-08-01	LM_ELE_ADR055	5958.28	\N
2022-08-01	LM_ELE_ADR056	0	\N
2022-08-01	LM_ELE_ADR063	190	\N
2022-08-01	LM_ELE_ADR064	0	\N
2022-08-01	LM_ELE_ADR058	87206.44	\N
2022-08-01	LM_ELE_ADR072	28982	\N
2022-08-01	LM_ELE_ADR074	85753	\N
2022-08-01	LM_ELE_ADR076	0	\N
2022-08-01	LM_ELE_ADR081	70027.22	\N
2022-08-01	LM_ELE_ADR085	63461.54	\N
2022-08-01	LM_ELE_ADR090	43279.88	\N
2022-08-01	LM_ELE_ADR107	92975.9	\N
2022-08-01	LM_ELE_ADR108	7162.34	\N
2022-08-01	LM_ELE_ADR109	2039.1	\N
2022-08-01	LM_ELE_ADR110	419.31	\N
2022-08-01	LM_ELE_ADR113	57753.77	\N
2022-08-01	LM_ELE_ADR087	93027.6	\N
2022-08-01	LM_LC_ADR_B45	222.63	\N
2022-08-01	LM_LH_ADR_B46	49.35	\N
2022-08-01	LM_LH_ADR_B47	138.3	\N
2022-08-01	LM_WOD_ADR_B74	40.17	\N
2022-08-01	LM_ELE_ADR_B06	520087.25	\N
2022-08-01	LM_ELE_ADR046	0	\N
2022-08-01	LM_ELE_ADR010	125176.61	\N
2022-08-01	LM_ELE_ADR043	2992.08	\N
2022-08-01	LM_ELE_ADR_B11	36122.72	\N
2022-08-01	LM_WOD_ADR242	45.81	\N
2022-08-01	LM_ELE_ADR124	123760.54	\N
2022-08-01	LM_ELE_ADR112	750394.5	\N
2022-08-01	LM_WOD_ADR_B75	187.26	\N
2022-08-01	LM_ELE_ADR091	13265.21	\N
2022-08-01	LM_WOD_ADR_B80	137.9	\N
2022-08-01	LM_WOD_ADR_B81	48.04	\N
2022-08-01	LM_ELE_ADR_B04	295630	\N
2022-08-01	LM_ELE_ADR_B05	298740.59	\N
2022-08-01	LM_ELE_ADR_B09	313154.31	\N
2022-08-01	LM_ELE_ADR_B01	0	\N
2022-08-01	LM_ELE_ADR_B10	32454.5	\N
2022-08-01	LM_ELE_ADR_B02	0	\N
2022-08-01	LM_LC_ADR_B18	18.81	\N
2022-08-01	LM_LC_ADR_B20	69.83	\N
2022-08-01	LM_LC_ADR_B22	56.38	\N
2022-08-01	LM_LC_ADR_B24	10.69	\N
2022-08-01	LM_LC_ADR_B31	465.3	\N
2022-08-01	LM_LC_ADR_B41	530.4	\N
2022-08-01	LM_LC_ADR_B43	9.3	\N
2022-08-01	LM_LH_ADR_B23	73.9	\N
2022-08-01	LM_LH_ADR_B25	77.7	\N
2022-08-01	LM_LH_ADR_B27	163.2	\N
2022-08-01	LM_LH_ADR_B35	0	\N
2022-08-01	LM_LH_ADR_B36	0	\N
2022-08-01	LM_LH_ADR_B38	76.3	\N
2022-08-01	LM_LH_ADR_B44	4.6	\N
2022-08-01	LM_WOD_ADR_B76	1747.88	\N
2022-08-01	LM_WOD_ADR_B77	9.07	\N
2022-08-01	LM_LC_ADR_B16	38.82	\N
2022-08-01	LM_LH_ADR_B17	58.8	\N
2022-08-01	LM_WOD_ADR_B79	360.11	\N
2022-08-01	LM_ELE_ADR_B12	19604.4	\N
2022-08-01	LM_ELE_ADR_B13	15053.19	\N
2022-08-01	LM_LC_ADR_B46	58.87	\N
2022-08-01	LM_LC_ADR193	0	\N
2022-08-01	LM_ELE_ADR125	5145.92	\N
2022-08-01	LM_ELE_ADR069	320593	\N
2022-08-01	LM_ELE_ADR075	11892	\N
2022-08-01	LM_LC_ADR159	5030	\N
2022-08-01	LM_LC_ADR160	13360	\N
2022-08-01	LM_LH_ADR167	6760	\N
2022-08-01	LM_WOD_ADR236	18.28	\N
2022-08-01	zdemontowany580	6	\N
2022-08-01	zdemontowany600	3194	\N
2022-09-01	LM_LC_ADR170	57.41	\N
2022-09-01	LM_LC_ADR172	136.49	\N
2022-09-01	LM_LC_ADR179	88.55	\N
2022-09-01	LM_ELE_ADR021	297963.69	\N
2022-09-01	LM_ELE_ADR078	58985	\N
2022-09-01	LM_ELE_ADR066	0	\N
2022-09-01	LM_ELE_ADR080	185441.66	\N
2022-09-01	LM_LH_ADR199	160.7	\N
2022-09-01	LM_ELE_ADR115	28729.75	\N
2022-09-01	LM_WOD_ADR249_Solution Space	127.54	\N
2022-09-01	LM_WOD_MAIN_W	0	\N
2022-09-01	LM_LC_ADR123	548.3	\N
2022-09-01	LM_LC_ADR151	31432	\N
2022-09-01	LM_LC_ADR153	10657	\N
2022-09-01	LM_LC_ADR154	2768.9	\N
2022-09-01	LM_LC_ADR155	7231.8	\N
2022-09-01	LM_LC_ADR157	1139.5	\N
2022-09-01	LM_LC_ADR158	371.7	\N
2022-09-01	LM_LC_ADR162	813.5	\N
2022-09-01	LM_LC_ADR168	121.5	\N
2022-09-01	LM_LC_ADR173	103.65	\N
2022-09-01	LM_LC_ADR174	226.39	\N
2022-09-01	LM_LC_ADR175	0	\N
2022-09-01	LM_LC_ADR176	85.9	\N
2022-09-01	LM_LC_ADR178	143.69	\N
2022-09-01	LM_LC_ADR184	45.23	\N
2022-09-01	LM_LC_ADR186	19.23	\N
2022-09-01	LM_LC_ADR187	32.69	\N
2022-09-01	LM_LC_ADR209	0	\N
2022-09-01	LM_LC_ADR32	0	\N
2022-09-01	LM_LC_ADR82	31.44	\N
2022-09-01	LM_LH_ADR122	20.7	\N
2022-09-01	LM_LH_ADR189	73.19	\N
2022-09-01	LM_LH_ADR195	526.9	\N
2022-09-01	LM_LH_ADR196	9	\N
2022-09-01	LM_LH_ADR198	1418.3	\N
2022-09-01	LM_LH_ADR200	54.3	\N
2022-09-01	LM_LH_ADR203	239.6	\N
2022-09-01	LM_LH_ADR204	117.5	\N
2022-09-01	LM_LH_ADR208	359.1	\N
2022-09-01	LM_LH_ADR211	46.6	\N
2022-09-01	LM_LH_ADR212	242.2	\N
2022-09-01	LM_LH_ADR216	40.47	\N
2022-09-01	LM_LH_ADR218	512.9	\N
2022-09-01	LM_LH_ADR221	424.6	\N
2022-09-01	LM_LH_ADR222	0	\N
2022-09-01	LM_LH_ADR227	47.4	\N
2022-09-01	LM_LH_ADR229	0	\N
2022-09-01	LM_LH_ADR231	0	\N
2022-09-01	LM_LH_ADR234	0	\N
2022-09-01	LM_LH_ADR235	103.7	\N
2022-09-01	LM_LH_ADR33	0	\N
2022-09-01	LM_ELE_ADR008	111499.97	\N
2022-09-01	LM_ELE_ADR012	98050.78	\N
2022-09-01	LM_ELE_ADR017	13827.66	\N
2022-09-01	LM_ELE_ADR019	4038.66	\N
2022-09-01	LM_ELE_ADR024	137357.64	\N
2022-09-01	LM_ELE_ADR027	36475.91	\N
2022-09-01	LM_LC_ADR163	31.06	\N
2022-09-01	LM_LC_ADR164	0.02	\N
2022-09-01	LM_LH_ADR201	127.9	\N
2022-09-01	LM_ELE_ADR029	15681.86	\N
2022-09-01	LM_ELE_ADR031	203961.95	\N
2022-09-01	LM_ELE_ADR038	412871.03	\N
2022-09-01	LM_ELE_ADR041	69653.47	\N
2022-09-01	LM_ELE_ADR045	6458.27	\N
2022-09-01	LM_ELE_ADR047	5766.2	\N
2022-09-01	LM_ELE_ADR049	15684.34	\N
2022-09-01	LM_ELE_ADR052	11941.56	\N
2022-09-01	LM_ELE_ADR054	33041.18	\N
2022-09-01	LM_ELE_ADR057	6595.97	\N
2022-09-01	LM_ELE_ADR059	25994.92	\N
2022-09-01	LM_ELE_ADR060	0	\N
2022-09-01	LM_ELE_ADR061	0	\N
2022-09-01	LM_ELE_ADR062	25612	\N
2022-09-01	LM_ELE_ADR065	0	\N
2022-09-01	LM_ELE_ADR067	336	\N
2022-09-01	LM_ELE_ADR068	13294	\N
2022-09-01	LM_ELE_ADR070	88	\N
2022-09-01	LM_ELE_ADR071	88688	\N
2022-09-01	LM_ELE_ADR073	88	\N
2022-09-01	LM_ELE_ADR077	1063	\N
2022-09-01	LM_ELE_ADR084	58609.72	\N
2022-09-01	LM_ELE_ADR086	17335.22	\N
2022-09-01	LM_ELE_ADR088	43371.84	\N
2022-09-01	LM_ELE_ADR094	1496.32	\N
2022-09-01	LM_ELE_ADR095	112256.6	\N
2022-09-01	LM_ELE_ADR097	37710.06	\N
2022-09-01	LM_ELE_ADR098	3838.09	\N
2022-09-01	LM_ELE_ADR099	96700.73	\N
2022-09-01	LM_ELE_ADR100	21121.66	\N
2022-09-01	LM_ELE_ADR101	8799.91	\N
2022-09-01	LM_ELE_ADR111	362.64	\N
2022-09-01	LM_ELE_ADR116	15151.01	\N
2022-09-01	LM_ELE_ADR118	22352.1	\N
2022-09-01	LM_ELE_ADR119	81419.8	\N
2022-09-01	LM_ELE_ADR120	101491.25	\N
2022-09-01	LM_WOD_ADR129	135.88	\N
2022-09-01	LM_WOD_ADR140	124.09	\N
2022-09-01	LM_WOD_ADR147	65.89	\N
2022-09-01	LM_WOD_ADR246_Solution Space	626.31	\N
2022-09-01	LM_WOD_ADR248_Solution Space	56.17	\N
2022-09-01	LM_ELE_ADR_B03	137731.3	\N
2022-09-01	LM_ELE_ADR_B07	109651.58	\N
2022-09-01	LM_ELE_ADR_B08	162789.95	\N
2022-09-01	LM_LC_ADR_B26	171.24	\N
2022-09-01	LM_LC_ADR_B30	452.7	\N
2022-09-01	LM_LC_ADR_B32	994.9	\N
2022-09-01	LM_LC_ADR_B33	900.2	\N
2022-09-01	LM_LH_ADR_B19	111.8	\N
2022-09-01	LM_LH_ADR_B21	218.2	\N
2022-09-01	LM_LH_ADR_B34	0	\N
2022-09-01	LM_LH_ADR_B37	0.4	\N
2022-09-01	LM_LH_ADR_B39	112.9	\N
2022-09-01	LM_LH_ADR_B40	190.2	\N
2022-09-01	LM_LH_ADR_B42	0	\N
2022-09-01	LM_WOD_ADR_B78	202.5	\N
2022-09-01	LM_LC_ADR102	56.27	\N
2022-09-01	LM_LC_ADR103	61.99	\N
2022-09-01	LM_LC_ADR104	84.07	\N
2022-09-01	LM_LC_ADR152	5161.8	\N
2022-09-01	LM_LC_ADR149	0.91	\N
2022-09-01	LM_LC_ADR156	3682.9	\N
2022-09-01	LM_LC_ADR171	309.05	\N
2022-09-01	LM_LC_ADR165	52.11	\N
2022-09-01	LM_LC_ADR166	40.82	\N
2022-09-01	LM_LC_ADR180	148	\N
2022-09-01	LM_LC_ADR181	0.1	\N
2022-09-01	LM_LC_ADR182	93.45	\N
2022-09-01	LM_LC_ADR183	1.42	\N
2022-09-01	LM_LC_ADR185	19.25	\N
2022-09-01	LM_LC_ADR161	1489.9	\N
2022-09-01	LM_LC_ADR224	177.3	\N
2022-09-01	LM_LC_ADR89	40.33	\N
2022-09-01	LM_LC_ADR93	39.84	\N
2022-09-01	LM_LH_ADR145	10.07	\N
2022-09-01	LM_LH_ADR188	32.18	\N
2022-09-01	LM_LH_ADR190	7.89	\N
2022-09-01	LM_LH_ADR191	18.8	\N
2022-09-01	LM_LH_ADR192	0	\N
2022-09-01	LM_LH_ADR194	0	\N
2022-09-01	LM_LH_ADR207	445.2	\N
2022-09-01	LM_LH_ADR197	1404.2	\N
2022-09-01	LM_LH_ADR215	0	\N
2022-09-01	LM_LH_ADR219	0.04	\N
2022-09-01	LM_LH_ADR220	112.2	\N
2022-09-01	LM_LH_ADR223	239.5	\N
2022-09-01	LM_LH_ADR225	78.8	\N
2022-09-01	LM_LH_ADR226	83.76	\N
2022-09-01	LM_LH_ADR217	562.5	\N
2022-09-01	LM_LH_ADR228	37.9	\N
2022-09-01	LM_LH_ADR232	66.05	\N
2022-09-01	LM_LH_ADR233	54.2	\N
2022-09-01	LM_LH_ADR230	1.8	\N
2022-09-01	LM_ELE_ADR114	311584.16	\N
2022-09-01	LM_ELE_ADR117	23340.68	\N
2022-09-01	LM_WOD_ADR132	320.7	\N
2022-09-01	LM_WOD_ADR133	366.1	\N
2022-09-01	LM_WOD_ADR134	19.05	\N
2022-09-01	LM_WOD_ADR135	0	\N
2022-09-01	LM_WOD_ADR136	74.3	\N
2022-09-01	LM_WOD_ADR139	1670.86	\N
2022-09-01	LM_WOD_ADR141	17	\N
2022-09-01	LM_WOD_ADR142	36	\N
2022-09-01	LM_WOD_ADR143	582.86	\N
2022-09-01	LM_WOD_ADR146	33544.4	\N
2022-09-01	LM_WOD_ADR148	0.01	\N
2022-09-01	LM_WOD_ADR150	45.79	\N
2022-09-01	LM_WOD_ADR237	924.88	\N
2022-09-01	LM_WOD_ADR238	2543.96	\N
2022-09-01	LM_WOD_ADR239	39.71	\N
2022-09-01	LM_WOD_ADR240	158.27	\N
2022-09-01	LM_WOD_ADR241	401	\N
2022-09-01	LM_ELE_ADR121	237993.97	\N
2022-09-01	LM_ELE_ADR128	0	\N
2022-09-01	LM_WOD_ADR247_Solution Space	665.82	\N
2022-09-01	LM_WOD_ADR250_Solution Space	233.12	\N
2022-09-01	LM_WOD_ADR30	0	\N
2022-09-01	LM_ELE_ADR001	75093.15	\N
2022-09-01	LM_ELE_ADR002	95679.74	\N
2022-09-01	LM_ELE_ADR003	126341.92	\N
2022-09-01	LM_ELE_ADR006	0	\N
2022-09-01	LM_ELE_ADR007	146721.22	\N
2022-09-01	LM_ELE_ADR009	198962.86	\N
2022-09-01	LM_ELE_ADR011	180004.89	\N
2022-09-01	LM_ELE_ADR013	238657.03	\N
2022-09-01	LM_ELE_ADR014	16206.45	\N
2022-09-01	LM_ELE_ADR015	142370.44	\N
2022-09-01	LM_ELE_ADR016	993257.94	\N
2022-09-01	LM_ELE_ADR018	14343.24	\N
2022-09-01	LM_ELE_ADR020	146320	\N
2022-09-01	LM_ELE_ADR022	178604.61	\N
2022-09-01	LM_ELE_ADR023	39394.87	\N
2022-09-01	LM_ELE_ADR025	650495.81	\N
2022-09-01	LM_ELE_ADR028	20004.36	\N
2022-09-01	LM_ELE_ADR034	34074.86	\N
2022-09-01	LM_ELE_ADR036	94479.82	\N
2022-09-01	LM_ELE_ADR039	400377.13	\N
2022-09-01	LM_ELE_ADR040	36656.9	\N
2022-09-01	LM_ELE_ADR042	3773.6	\N
2022-09-01	LM_ELE_ADR044	7302.42	\N
2022-09-01	LM_ELE_ADR048	7679.92	\N
2022-09-01	LM_ELE_ADR051	7365.46	\N
2022-09-01	LM_ELE_ADR053	32708.36	\N
2022-09-01	LM_ELE_ADR055	6086.18	\N
2022-09-01	LM_ELE_ADR056	0	\N
2022-09-01	LM_ELE_ADR063	190	\N
2022-09-01	LM_ELE_ADR064	0	\N
2022-09-01	LM_ELE_ADR058	89106.27	\N
2022-09-01	LM_ELE_ADR072	29906	\N
2022-09-01	LM_ELE_ADR074	88688	\N
2022-09-01	LM_ELE_ADR076	0	\N
2022-09-01	LM_ELE_ADR081	71422.88	\N
2022-09-01	LM_ELE_ADR085	66471.4	\N
2022-09-01	LM_ELE_ADR090	45412.35	\N
2022-09-01	LM_ELE_ADR107	95975.62	\N
2022-09-01	LM_ELE_ADR108	7260.1	\N
2022-09-01	LM_ELE_ADR109	2040.57	\N
2022-09-01	LM_ELE_ADR110	457.17	\N
2022-09-01	LM_ELE_ADR113	59305.69	\N
2022-09-01	LM_ELE_ADR087	94879.68	\N
2022-09-01	LM_LC_ADR_B45	222.77	\N
2022-09-01	LM_LH_ADR_B46	49.35	\N
2022-09-01	LM_LH_ADR_B47	147.6	\N
2022-09-01	LM_WOD_ADR_B74	41.27	\N
2022-09-01	LM_ELE_ADR_B06	539084.13	\N
2022-09-01	LM_ELE_ADR046	0	\N
2022-09-01	LM_ELE_ADR010	127603.35	\N
2022-09-01	LM_ELE_ADR043	3061.71	\N
2022-09-01	LM_ELE_ADR_B11	36978.41	\N
2022-09-01	LM_WOD_ADR242	47.28	\N
2022-09-01	LM_ELE_ADR124	131811.58	\N
2022-09-01	LM_ELE_ADR112	758163.06	\N
2022-09-01	LM_WOD_ADR_B75	188.55	\N
2022-09-01	LM_ELE_ADR091	13755.97	\N
2022-09-01	LM_WOD_ADR_B80	140.98	\N
2022-09-01	LM_WOD_ADR_B81	49.76	\N
2022-09-01	LM_ELE_ADR_B04	311263.25	\N
2022-09-01	LM_ELE_ADR_B05	314182.88	\N
2022-09-01	LM_ELE_ADR_B09	317637.22	\N
2022-09-01	LM_ELE_ADR_B01	0	\N
2022-09-01	LM_ELE_ADR_B10	33092.62	\N
2022-09-01	LM_ELE_ADR_B02	0	\N
2022-09-01	LM_LC_ADR_B18	18.82	\N
2022-09-01	LM_LC_ADR_B20	69.85	\N
2022-09-01	LM_LC_ADR_B22	56.38	\N
2022-09-01	LM_LC_ADR_B24	10.69	\N
2022-09-01	LM_LC_ADR_B31	465.4	\N
2022-09-01	LM_LC_ADR_B41	530.9	\N
2022-09-01	LM_LC_ADR_B43	9.4	\N
2022-09-01	LM_LH_ADR_B23	73.9	\N
2022-09-01	LM_LH_ADR_B25	77.7	\N
2022-09-01	LM_LH_ADR_B27	164.2	\N
2022-09-01	LM_LH_ADR_B35	0	\N
2022-09-01	LM_LH_ADR_B36	0	\N
2022-09-01	LM_LH_ADR_B38	79.6	\N
2022-09-01	LM_LH_ADR_B44	4.7	\N
2022-09-01	LM_WOD_ADR_B76	1843.26	\N
2022-09-01	LM_WOD_ADR_B77	9.07	\N
2022-09-01	LM_LC_ADR_B16	38.82	\N
2022-09-01	LM_LH_ADR_B17	62.5	\N
2022-09-01	LM_WOD_ADR_B79	360.11	\N
2022-09-01	LM_ELE_ADR_B12	20020.21	\N
2022-09-01	LM_ELE_ADR_B13	15053.19	\N
2022-09-01	LM_LC_ADR_B46	58.87	\N
2022-09-01	LM_LC_ADR193	0	\N
2022-09-01	LM_ELE_ADR125	5222.8	\N
2022-09-01	LM_ELE_ADR069	327665	\N
2022-09-01	LM_ELE_ADR075	12299	\N
2022-09-01	LM_LC_ADR159	5030	\N
2022-09-01	LM_LC_ADR160	13450	\N
2022-09-01	LM_LH_ADR167	11550	\N
2022-09-01	LM_WOD_ADR236	21.34	\N
2022-09-01	zdemontowany580	6	\N
2022-09-01	zdemontowany600	3194	\N
2022-10-01	LM_LC_ADR170	57.99	\N
2022-10-01	LM_LC_ADR172	136.9	\N
2022-10-01	LM_LC_ADR179	88.74	\N
2022-10-01	LM_ELE_ADR021	303024.88	\N
2022-10-01	LM_ELE_ADR078	59611	\N
2022-10-01	LM_ELE_ADR066	0	\N
2022-10-01	LM_ELE_ADR080	187882.73	\N
2022-10-01	LM_LH_ADR199	162.2	\N
2022-10-01	LM_ELE_ADR115	29344.34	\N
2022-10-01	LM_WOD_ADR249_Solution Space	132.18	\N
2022-10-01	LM_WOD_MAIN_W	0	\N
2022-10-01	LM_LC_ADR123	551	\N
2022-10-01	LM_LC_ADR151	31647	\N
2022-10-01	LM_LC_ADR153	10701	\N
2022-10-01	LM_LC_ADR154	2811.3	\N
2022-10-01	LM_LC_ADR155	7304.1	\N
2022-10-01	LM_LC_ADR157	1155.1	\N
2022-10-01	LM_LC_ADR158	376.4	\N
2022-10-01	LM_LC_ADR162	820.2	\N
2022-10-01	LM_LC_ADR168	129	\N
2022-10-01	LM_LC_ADR173	104.73	\N
2022-10-01	LM_LC_ADR174	233	\N
2022-10-01	LM_LC_ADR175	0	\N
2022-10-01	LM_LC_ADR176	85.9	\N
2022-10-01	LM_LC_ADR178	146.56	\N
2022-10-01	LM_LC_ADR184	45.23	\N
2022-10-01	LM_LC_ADR186	19.23	\N
2022-10-01	LM_LC_ADR187	32.69	\N
2022-10-01	LM_LC_ADR209	0	\N
2022-10-01	LM_LC_ADR32	0	\N
2022-10-01	LM_LC_ADR82	33.42	\N
2022-10-01	LM_LH_ADR122	21.6	\N
2022-10-01	LM_LH_ADR189	75.16	\N
2022-10-01	LM_LH_ADR195	531.8	\N
2022-10-01	LM_LH_ADR196	9	\N
2022-10-01	LM_LH_ADR198	0	\N
2022-10-01	LM_LH_ADR200	54.9	\N
2022-10-01	LM_LH_ADR203	241.4	\N
2022-10-01	LM_LH_ADR204	118.6	\N
2022-10-01	LM_LH_ADR208	365.9	\N
2022-10-01	LM_LH_ADR211	48.4	\N
2022-10-01	LM_LH_ADR212	251.4	\N
2022-10-01	LM_LH_ADR216	40.47	\N
2022-10-01	LM_LH_ADR218	527.7	\N
2022-10-01	LM_LH_ADR221	437.1	\N
2022-10-01	LM_LH_ADR222	0	\N
2022-10-01	LM_LH_ADR227	51	\N
2022-10-01	LM_LH_ADR229	0	\N
2022-10-01	LM_LH_ADR231	0	\N
2022-10-01	LM_LH_ADR234	0	\N
2022-10-01	LM_LH_ADR235	104.5	\N
2022-10-01	LM_LH_ADR33	0	\N
2022-10-01	LM_ELE_ADR008	113298.62	\N
2022-10-01	LM_ELE_ADR012	99185.62	\N
2022-10-01	LM_ELE_ADR017	14025.04	\N
2022-10-01	LM_ELE_ADR019	4038.66	\N
2022-10-01	LM_ELE_ADR024	139699.97	\N
2022-10-01	LM_ELE_ADR027	36475.91	\N
2022-10-01	LM_LC_ADR163	31.06	\N
2022-10-01	LM_LC_ADR164	0.02	\N
2022-10-01	LM_LH_ADR201	136.6	\N
2022-10-01	LM_ELE_ADR029	16187.06	\N
2022-10-01	LM_ELE_ADR031	206400.83	\N
2022-10-01	LM_ELE_ADR038	419798.88	\N
2022-10-01	LM_ELE_ADR041	70676.16	\N
2022-10-01	LM_ELE_ADR045	6552.14	\N
2022-10-01	LM_ELE_ADR047	5868.06	\N
2022-10-01	LM_ELE_ADR049	15891.37	\N
2022-10-01	LM_ELE_ADR052	12112.3	\N
2022-10-01	LM_ELE_ADR054	33503.15	\N
2022-10-01	LM_ELE_ADR057	6701.19	\N
2022-10-01	LM_ELE_ADR059	26461.34	\N
2022-10-01	LM_ELE_ADR060	0	\N
2022-10-01	LM_ELE_ADR061	0	\N
2022-10-01	LM_ELE_ADR062	26321	\N
2022-10-01	LM_ELE_ADR065	0	\N
2022-10-01	LM_ELE_ADR067	336	\N
2022-10-01	LM_ELE_ADR068	14347	\N
2022-10-01	LM_ELE_ADR070	88	\N
2022-10-01	LM_ELE_ADR071	90619	\N
2022-10-01	LM_ELE_ADR073	88	\N
2022-10-01	LM_ELE_ADR077	1063	\N
2022-10-01	LM_ELE_ADR084	59262.02	\N
2022-10-01	LM_ELE_ADR086	17801.11	\N
2022-10-01	LM_ELE_ADR088	44130.52	\N
2022-10-01	LM_ELE_ADR094	1503.69	\N
2022-10-01	LM_ELE_ADR095	114378.06	\N
2022-10-01	LM_ELE_ADR097	38940.71	\N
2022-10-01	LM_ELE_ADR098	3917.64	\N
2022-10-01	LM_ELE_ADR099	99075.79	\N
2022-10-01	LM_ELE_ADR100	21488.22	\N
2022-10-01	LM_ELE_ADR101	8994.47	\N
2022-10-01	LM_ELE_ADR111	362.65	\N
2022-10-01	LM_ELE_ADR116	15151.01	\N
2022-10-01	LM_ELE_ADR118	22656.48	\N
2022-10-01	LM_ELE_ADR119	82577.41	\N
2022-10-01	LM_ELE_ADR120	104097.81	\N
2022-10-01	LM_WOD_ADR129	139.48	\N
2022-10-01	LM_WOD_ADR140	124.37	\N
2022-10-01	LM_WOD_ADR147	67	\N
2022-10-01	LM_WOD_ADR246_Solution Space	639.67	\N
2022-10-01	LM_WOD_ADR248_Solution Space	58.21	\N
2022-10-01	LM_ELE_ADR_B03	139460.73	\N
2022-10-01	LM_ELE_ADR_B07	111147.73	\N
2022-10-01	LM_ELE_ADR_B08	165089.58	\N
2022-10-01	LM_LC_ADR_B26	171.92	\N
2022-10-01	LM_LC_ADR_B30	457	\N
2022-10-01	LM_LC_ADR_B32	1004	\N
2022-10-01	LM_LC_ADR_B33	909.3	\N
2022-10-01	LM_LH_ADR_B19	114.4	\N
2022-10-01	LM_LH_ADR_B21	221.6	\N
2022-10-01	LM_LH_ADR_B34	0	\N
2022-10-01	LM_LH_ADR_B37	0.4	\N
2022-10-01	LM_LH_ADR_B39	113.6	\N
2022-10-01	LM_LH_ADR_B40	191.8	\N
2022-10-01	LM_LH_ADR_B42	0	\N
2022-10-01	LM_WOD_ADR_B78	204.98	\N
2022-10-01	LM_LC_ADR102	57.24	\N
2022-10-01	LM_LC_ADR103	63.03	\N
2022-10-01	LM_LC_ADR104	85.92	\N
2022-10-01	LM_LC_ADR152	5199.4	\N
2022-10-01	LM_LC_ADR149	0.91	\N
2022-10-01	LM_LC_ADR156	3714.2	\N
2022-10-01	LM_LC_ADR171	309.24	\N
2022-10-01	LM_LC_ADR165	53.09	\N
2022-10-01	LM_LC_ADR166	41.55	\N
2022-10-01	LM_LC_ADR180	148.69	\N
2022-10-01	LM_LC_ADR181	0.1	\N
2022-10-01	LM_LC_ADR182	94.08	\N
2022-10-01	LM_LC_ADR183	1.42	\N
2022-10-01	LM_LC_ADR185	19.25	\N
2022-10-01	LM_LC_ADR161	1502.3	\N
2022-10-01	LM_LC_ADR224	180.83	\N
2022-10-01	LM_LC_ADR89	41.16	\N
2022-10-01	LM_LC_ADR93	40.67	\N
2022-10-01	LM_LH_ADR145	10.07	\N
2022-10-01	LM_LH_ADR188	32.18	\N
2022-10-01	LM_LH_ADR190	7.89	\N
2022-10-01	LM_LH_ADR191	18.8	\N
2022-10-01	LM_LH_ADR192	0	\N
2022-10-01	LM_LH_ADR194	0	\N
2022-10-01	LM_LH_ADR207	450.8	\N
2022-10-01	LM_LH_ADR197	1414.6	\N
2022-10-01	LM_LH_ADR215	0	\N
2022-10-01	LM_LH_ADR219	0.04	\N
2022-10-01	LM_LH_ADR220	112.2	\N
2022-10-01	LM_LH_ADR223	251.9	\N
2022-10-01	LM_LH_ADR225	82.7	\N
2022-10-01	LM_LH_ADR226	83.81	\N
2022-10-01	LM_LH_ADR217	571.7	\N
2022-10-01	LM_LH_ADR228	38.1	\N
2022-10-01	LM_LH_ADR232	67.38	\N
2022-10-01	LM_LH_ADR233	54.3	\N
2022-10-01	LM_LH_ADR230	1.8	\N
2022-10-01	LM_ELE_ADR114	27.81	\N
2022-10-01	LM_ELE_ADR117	23588.3	\N
2022-10-01	LM_WOD_ADR132	324.66	\N
2022-10-01	LM_WOD_ADR133	370.2	\N
2022-10-01	LM_WOD_ADR134	19.08	\N
2022-10-01	LM_WOD_ADR135	0	\N
2022-10-01	LM_WOD_ADR136	75.19	\N
2022-10-01	LM_WOD_ADR139	1703.13	\N
2022-10-01	LM_WOD_ADR141	17	\N
2022-10-01	LM_WOD_ADR142	36	\N
2022-10-01	LM_WOD_ADR143	582.86	\N
2022-10-01	LM_WOD_ADR146	34101.3	\N
2022-10-01	LM_WOD_ADR148	0.03	\N
2022-10-01	LM_WOD_ADR150	46.79	\N
2022-10-01	LM_WOD_ADR237	926.11	\N
2022-10-01	LM_WOD_ADR238	2543.96	\N
2022-10-01	LM_WOD_ADR239	40.6	\N
2022-10-01	LM_WOD_ADR240	163.89	\N
2022-10-01	LM_WOD_ADR241	445.66	\N
2022-10-01	LM_ELE_ADR121	85.44	\N
2022-10-01	LM_ELE_ADR128	0	\N
2022-10-01	LM_WOD_ADR247_Solution Space	681.81	\N
2022-10-01	LM_WOD_ADR250_Solution Space	240.69	\N
2022-10-01	LM_WOD_ADR30	0	\N
2022-10-01	LM_ELE_ADR001	76404.35	\N
2022-10-01	LM_ELE_ADR002	96846.38	\N
2022-10-01	LM_ELE_ADR003	127689.08	\N
2022-10-01	LM_ELE_ADR006	0	\N
2022-10-01	LM_ELE_ADR007	147721.22	\N
2022-10-01	LM_ELE_ADR009	199928.39	\N
2022-10-01	LM_ELE_ADR011	180794.91	\N
2022-10-01	LM_ELE_ADR013	241267.72	\N
2022-10-01	LM_ELE_ADR014	16504.29	\N
2022-10-01	LM_ELE_ADR015	143689.16	\N
2022-10-01	LM_ELE_ADR016	1001217.44	\N
2022-10-01	LM_ELE_ADR018	14569.4	\N
2022-10-01	LM_ELE_ADR020	148098.06	\N
2022-10-01	LM_ELE_ADR022	183444.03	\N
2022-10-01	LM_ELE_ADR023	40526.44	\N
2022-10-01	LM_ELE_ADR025	675872.13	\N
2022-10-01	LM_ELE_ADR028	20025.27	\N
2022-10-01	LM_ELE_ADR034	35099.37	\N
2022-10-01	LM_ELE_ADR036	95701.01	\N
2022-10-01	LM_ELE_ADR039	406712.91	\N
2022-10-01	LM_ELE_ADR040	36656.9	\N
2022-10-01	LM_ELE_ADR042	3829.06	\N
2022-10-01	LM_ELE_ADR044	7408.1	\N
2022-10-01	LM_ELE_ADR048	7793.67	\N
2022-10-01	LM_ELE_ADR051	7464.56	\N
2022-10-01	LM_ELE_ADR053	34256.26	\N
2022-10-01	LM_ELE_ADR055	6175.22	\N
2022-10-01	LM_ELE_ADR056	0	\N
2022-10-01	LM_ELE_ADR063	190	\N
2022-10-01	LM_ELE_ADR064	0	\N
2022-10-01	LM_ELE_ADR058	90383.27	\N
2022-10-01	LM_ELE_ADR072	30512	\N
2022-10-01	LM_ELE_ADR074	90619	\N
2022-10-01	LM_ELE_ADR076	0	\N
2022-10-01	LM_ELE_ADR081	72671.72	\N
2022-10-01	LM_ELE_ADR085	68240.63	\N
2022-10-01	LM_ELE_ADR090	46360.36	\N
2022-10-01	LM_ELE_ADR107	97896.89	\N
2022-10-01	LM_ELE_ADR108	7492.56	\N
2022-10-01	LM_ELE_ADR109	2041.46	\N
2022-10-01	LM_ELE_ADR110	479.05	\N
2022-10-01	LM_ELE_ADR113	60312.29	\N
2022-10-01	LM_ELE_ADR087	96040.44	\N
2022-10-01	LM_LC_ADR_B45	225.53	\N
2022-10-01	LM_LH_ADR_B46	49.35	\N
2022-10-01	LM_LH_ADR_B47	148.8	\N
2022-10-01	LM_WOD_ADR_B74	42.04	\N
2022-10-01	LM_ELE_ADR_B06	545348.94	\N
2022-10-01	LM_ELE_ADR046	0	\N
2022-10-01	LM_ELE_ADR010	129307.77	\N
2022-10-01	LM_ELE_ADR043	3113.53	\N
2022-10-01	LM_ELE_ADR_B11	37732.34	\N
2022-10-01	LM_WOD_ADR242	48.24	\N
2022-10-01	LM_ELE_ADR124	137109.38	\N
2022-10-01	LM_ELE_ADR112	762760.88	\N
2022-10-01	LM_WOD_ADR_B75	189.53	\N
2022-10-01	LM_ELE_ADR091	14088.18	\N
2022-10-01	LM_WOD_ADR_B80	144.69	\N
2022-10-01	LM_WOD_ADR_B81	51.01	\N
2022-10-01	LM_ELE_ADR_B04	314645.09	\N
2022-10-01	LM_ELE_ADR_B05	321904.75	\N
2022-10-01	LM_ELE_ADR_B09	321712.94	\N
2022-10-01	LM_ELE_ADR_B01	0	\N
2022-10-01	LM_ELE_ADR_B10	33647.01	\N
2022-10-01	LM_ELE_ADR_B02	0	\N
2022-10-01	LM_LC_ADR_B18	18.95	\N
2022-10-01	LM_LC_ADR_B20	70.13	\N
2022-10-01	LM_LC_ADR_B22	56.38	\N
2022-10-01	LM_LC_ADR_B24	10.69	\N
2022-10-01	LM_LC_ADR_B31	469	\N
2022-10-01	LM_LC_ADR_B41	539.3	\N
2022-10-01	LM_LC_ADR_B43	9.6	\N
2022-10-01	LM_LH_ADR_B23	73.9	\N
2022-10-01	LM_LH_ADR_B25	77.7	\N
2022-10-01	LM_LH_ADR_B27	164.8	\N
2022-10-01	LM_LH_ADR_B35	0	\N
2022-10-01	LM_LH_ADR_B36	0	\N
2022-10-01	LM_LH_ADR_B38	80.1	\N
2022-10-01	LM_LH_ADR_B44	4.8	\N
2022-10-01	LM_WOD_ADR_B76	1864.29	\N
2022-10-01	LM_WOD_ADR_B77	9.11	\N
2022-10-01	LM_LC_ADR_B16	38.82	\N
2022-10-01	LM_LH_ADR_B17	65	\N
2022-10-01	LM_WOD_ADR_B79	515.65	\N
2022-10-01	LM_ELE_ADR_B12	20259.02	\N
2022-10-01	LM_ELE_ADR_B13	15053.19	\N
2022-10-01	LM_LC_ADR_B46	58.87	\N
2022-10-01	LM_LC_ADR193	0	\N
2022-10-01	LM_ELE_ADR125	5273.38	\N
2022-10-01	LM_ELE_ADR069	332514	\N
2022-10-01	LM_ELE_ADR075	12550	\N
2022-10-01	LM_LC_ADR159	5030	\N
2022-10-01	LM_LC_ADR160	14260	\N
2022-10-01	LM_LH_ADR167	13220	\N
2022-10-01	LM_WOD_ADR236	25.38	\N
2022-10-01	zdemontowany580	6	\N
2022-10-01	zdemontowany600	3194	\N
2022-01-01	LM_WOD_ADR148	0.04	\N
2022-03-01	LM_LH_ADR194	0	\N
2022-04-01	LM_LH_ADR167	1590	\N
2022-04-01	LM_WOD_ADR236	10.2	\N
2022-02-01	zdemontowany580	6	\N
2022-03-01	zdemontowany580	6	\N
2022-05-01	LM_LC_ADR32	0	\N
2021-07-01	LM_LC_ADR170	48.95	\N
2021-07-01	LM_LC_ADR172	90.22	\N
2021-07-01	LM_LC_ADR179	70.6	\N
2021-07-01	LM_ELE_ADR021	196075.66	\N
2021-07-01	LM_ELE_ADR078	36857	\N
2021-07-01	LM_ELE_ADR066	0	\N
2021-07-01	LM_ELE_ADR080	146553.95	\N
2021-07-01	LM_LH_ADR199	122.4	\N
2021-07-01	LM_ELE_ADR115	20787.79	\N
2021-07-01	LM_WOD_ADR249_Solution Space	70.29	\N
2021-07-01	LM_WOD_MAIN_W	0	\N
2021-07-01	LM_LC_ADR123	369	\N
2021-07-01	LM_LC_ADR151	25987	\N
2021-07-01	LM_LC_ADR153	9220	\N
2021-07-01	LM_LC_ADR154	2101.1	\N
2021-07-01	LM_LC_ADR155	5624.4	\N
2021-07-01	LM_LC_ADR157	903.6	\N
2021-07-01	LM_LC_ADR158	282.7	\N
2021-07-01	LM_LC_ADR162	657.2	\N
2021-07-01	LM_LC_ADR168	69.2	\N
2021-07-01	LM_LC_ADR173	79.4	\N
2021-07-01	LM_LC_ADR174	135.09	\N
2021-07-01	LM_LC_ADR175	0	\N
2021-07-01	LM_LC_ADR176	84.6	\N
2021-07-01	LM_LC_ADR178	95.55	\N
2021-07-01	LM_LC_ADR184	38.96	\N
2021-07-01	LM_LC_ADR186	15.54	\N
2021-07-01	LM_LC_ADR187	29.04	\N
2021-07-01	LM_LC_ADR209	84.68	\N
2021-07-01	LM_LC_ADR32	0	\N
2021-07-01	LM_LC_ADR82	0	\N
2021-07-01	LM_LH_ADR122	10	\N
2021-07-01	LM_LH_ADR189	43.85	\N
2021-07-01	LM_LH_ADR195	356	\N
2021-07-01	LM_LH_ADR196	9	\N
2021-07-01	LM_LH_ADR198	1004.5	\N
2021-07-01	LM_LH_ADR200	40.2	\N
2021-07-01	LM_LH_ADR203	199.7	\N
2021-07-01	LM_LH_ADR204	81.8	\N
2021-07-01	LM_LH_ADR208	247.7	\N
2021-07-01	LM_LH_ADR211	19.3	\N
2021-07-01	LM_LH_ADR212	105	\N
2021-07-01	LM_LH_ADR216	27.97	\N
2021-07-01	LM_LH_ADR218	332.6	\N
2021-07-01	LM_LH_ADR221	229.8	\N
2021-07-01	LM_LH_ADR222	0	\N
2021-07-01	LM_LH_ADR227	29.5	\N
2021-07-01	LM_LH_ADR229	83.86	\N
2021-07-01	LM_LH_ADR231	0	\N
2021-07-01	LM_LH_ADR234	0	\N
2021-07-01	LM_LH_ADR235	83.8	\N
2021-07-01	LM_LH_ADR33	0	\N
2021-07-01	LM_ELE_ADR008	76030.41	\N
2021-07-01	LM_ELE_ADR012	60508.99	\N
2021-07-01	LM_ELE_ADR017	10605.57	\N
2021-07-01	LM_ELE_ADR019	2439.52	\N
2021-07-01	LM_ELE_ADR024	106947.7	\N
2021-07-01	LM_ELE_ADR027	33502.36	\N
2021-07-01	LM_LC_ADR163	26.44	\N
2021-07-01	LM_LC_ADR164	0.02	\N
2021-07-01	LM_LH_ADR201	56.5	\N
2021-07-01	LM_ELE_ADR029	9132.79	\N
2021-07-01	LM_ELE_ADR031	141139.25	\N
2021-07-01	LM_ELE_ADR038	254048.58	\N
2021-07-01	LM_ELE_ADR041	56975.13	\N
2021-07-01	LM_ELE_ADR045	4993.68	\N
2021-07-01	LM_ELE_ADR047	4475.68	\N
2021-07-01	LM_ELE_ADR049	12684.92	\N
2021-07-01	LM_ELE_ADR052	9439.95	\N
2021-07-01	LM_ELE_ADR054	26478.94	\N
2021-07-01	LM_ELE_ADR057	5234.49	\N
2021-07-01	LM_ELE_ADR059	19332.39	\N
2021-07-01	LM_ELE_ADR060	0	\N
2021-07-01	LM_ELE_ADR061	0	\N
2021-07-01	LM_ELE_ADR062	16182	\N
2021-07-01	LM_ELE_ADR065	0	\N
2021-07-01	LM_ELE_ADR067	125	\N
2021-07-01	LM_ELE_ADR068	390	\N
2021-07-01	LM_ELE_ADR070	80	\N
2021-07-01	LM_ELE_ADR071	62922	\N
2021-07-01	LM_ELE_ADR073	80	\N
2021-07-01	LM_ELE_ADR077	1063	\N
2021-07-01	LM_ELE_ADR084	47836.67	\N
2021-07-01	LM_ELE_ADR086	10860.53	\N
2021-07-01	LM_ELE_ADR088	30209.18	\N
2021-07-01	LM_ELE_ADR094	1335.77	\N
2021-07-01	LM_ELE_ADR095	82457.02	\N
2021-07-01	LM_ELE_ADR097	22452.25	\N
2021-07-01	LM_ELE_ADR098	2970.22	\N
2021-07-01	LM_ELE_ADR099	55189.32	\N
2021-07-01	LM_ELE_ADR100	12895.4	\N
2021-07-01	LM_ELE_ADR101	6012.68	\N
2021-07-01	LM_ELE_ADR111	362.08	\N
2021-07-01	LM_ELE_ADR116	8819.65	\N
2021-07-01	LM_ELE_ADR118	18129.85	\N
2021-07-01	LM_ELE_ADR119	63259.13	\N
2021-07-01	LM_ELE_ADR120	72597.1	\N
2021-07-01	LM_WOD_ADR129	89.1	\N
2021-07-01	LM_WOD_ADR140	120.19	\N
2021-07-01	LM_WOD_ADR147	50.46	\N
2021-07-01	LM_WOD_ADR246_Solution Space	404.81	\N
2021-07-01	LM_WOD_ADR248_Solution Space	29.65	\N
2021-07-01	LM_ELE_ADR_B03	109787.11	\N
2021-07-01	LM_ELE_ADR_B07	87212.62	\N
2021-07-01	LM_ELE_ADR_B08	130174.9	\N
2021-07-01	LM_LC_ADR_B26	104.73	\N
2021-07-01	LM_LC_ADR_B30	342.9	\N
2021-07-01	LM_LC_ADR_B32	765.8	\N
2021-07-01	LM_LC_ADR_B33	650.3	\N
2021-07-01	LM_LH_ADR_B19	70.7	\N
2021-07-01	LM_LH_ADR_B21	150.5	\N
2021-07-01	LM_LH_ADR_B34	0	\N
2021-07-01	LM_LH_ADR_B37	0.4	\N
2021-07-01	LM_LH_ADR_B39	85.6	\N
2021-07-01	LM_LH_ADR_B40	143.2	\N
2021-07-01	LM_LH_ADR_B42	0	\N
2021-07-01	LM_WOD_ADR_B78	173.99	\N
2021-07-01	LM_LC_ADR102	40.95	\N
2021-07-01	LM_LC_ADR103	45.01	\N
2021-07-01	LM_LC_ADR104	54.9	\N
2021-07-01	LM_LC_ADR152	4239.1	\N
2021-07-01	LM_LC_ADR149	0.91	\N
2021-07-01	LM_LC_ADR156	2750.2	\N
2021-07-01	LM_LC_ADR171	239.05	\N
2021-07-01	LM_LC_ADR165	35.9	\N
2021-07-01	LM_LC_ADR166	29	\N
2021-07-01	LM_LC_ADR180	123.88	\N
2021-07-01	LM_LC_ADR181	0.1	\N
2021-07-01	LM_LC_ADR182	73.31	\N
2021-07-01	LM_LC_ADR183	1.42	\N
2021-07-01	LM_LC_ADR185	16.13	\N
2021-07-01	LM_LC_ADR161	1199.4	\N
2021-07-01	LM_LC_ADR224	124.01	\N
2021-07-01	LM_LC_ADR89	26.11	\N
2021-07-01	LM_LC_ADR93	25.61	\N
2021-07-01	LM_LH_ADR145	7.38	\N
2021-07-01	LM_LH_ADR188	24.06	\N
2021-07-01	LM_LH_ADR190	6.43	\N
2021-07-01	LM_LH_ADR191	15.2	\N
2021-07-01	LM_LH_ADR192	0	\N
2021-07-01	LM_LH_ADR194	700.5	\N
2021-07-01	LM_LH_ADR207	381.3	\N
2021-07-01	LM_LH_ADR197	1127.2	\N
2021-07-01	LM_LH_ADR215	0	\N
2021-07-01	LM_LH_ADR219	0.02	\N
2021-07-01	LM_LH_ADR220	71.98	\N
2021-07-01	LM_LH_ADR223	141.6	\N
2021-07-01	LM_LH_ADR225	54.3	\N
2021-07-01	LM_LH_ADR226	50.97	\N
2021-07-01	LM_LH_ADR217	442.3	\N
2021-07-01	LM_LH_ADR228	26.8	\N
2021-07-01	LM_LH_ADR232	46.58	\N
2021-07-01	LM_LH_ADR233	38	\N
2021-07-01	LM_LH_ADR230	1.5	\N
2021-07-01	LM_ELE_ADR114	213759.08	\N
2021-07-01	LM_ELE_ADR117	20477.34	\N
2021-07-01	LM_WOD_ADR132	259.85	\N
2021-07-01	LM_WOD_ADR133	320.07	\N
2021-07-01	LM_WOD_ADR134	18.1	\N
2021-07-01	LM_WOD_ADR135	0	\N
2021-07-01	LM_WOD_ADR136	61.77	\N
2021-07-01	LM_WOD_ADR139	1081.36	\N
2021-07-01	LM_WOD_ADR141	17	\N
2021-07-01	LM_WOD_ADR142	36	\N
2021-07-01	LM_WOD_ADR143	361.07	\N
2021-07-01	LM_WOD_ADR146	25269.3	\N
2021-07-01	LM_WOD_ADR148	0.05	\N
2021-07-01	LM_WOD_ADR150	32.9	\N
2021-07-01	LM_WOD_ADR237	860.95	\N
2021-07-01	LM_WOD_ADR238	2210.03	\N
2021-07-01	LM_WOD_ADR239	26.41	\N
2021-07-01	LM_WOD_ADR240	91.54	\N
2021-07-01	LM_WOD_ADR241	899.35	\N
2021-07-01	LM_ELE_ADR121	158906.41	\N
2021-07-01	LM_ELE_ADR128	0	\N
2021-07-01	LM_WOD_ADR247_Solution Space	369.57	\N
2021-07-01	LM_WOD_ADR250_Solution Space	133.57	\N
2021-07-01	LM_WOD_ADR30	0	\N
2021-07-01	LM_ELE_ADR001	57763.27	\N
2021-07-01	LM_ELE_ADR002	76678.03	\N
2021-07-01	LM_ELE_ADR003	92503.44	\N
2021-07-01	LM_ELE_ADR006	66431.46	\N
2021-07-01	LM_ELE_ADR007	112584.56	\N
2021-07-01	LM_ELE_ADR009	153932.03	\N
2021-07-01	LM_ELE_ADR011	151400.55	\N
2021-07-01	LM_ELE_ADR013	191805.73	\N
2021-07-01	LM_ELE_ADR014	11718.3	\N
2021-07-01	LM_ELE_ADR015	107978.89	\N
2021-07-01	LM_ELE_ADR016	835718.31	\N
2021-07-01	LM_ELE_ADR018	11105.94	\N
2021-07-01	LM_ELE_ADR020	116572.42	\N
2021-07-01	LM_ELE_ADR022	112688.87	\N
2021-07-01	LM_ELE_ADR023	24779.33	\N
2021-07-01	LM_ELE_ADR025	333624.31	\N
2021-07-01	LM_ELE_ADR028	15919.27	\N
2021-07-01	LM_ELE_ADR034	18925	\N
2021-07-01	LM_ELE_ADR036	77843.42	\N
2021-07-01	LM_ELE_ADR039	270321.13	\N
2021-07-01	LM_ELE_ADR040	29531	\N
2021-07-01	LM_ELE_ADR042	2962.27	\N
2021-07-01	LM_ELE_ADR044	5891.29	\N
2021-07-01	LM_ELE_ADR048	6186.79	\N
2021-07-01	LM_ELE_ADR051	5881.92	\N
2021-07-01	LM_ELE_ADR053	16437.02	\N
2021-07-01	LM_ELE_ADR055	4823.35	\N
2021-07-01	LM_ELE_ADR056	18756.74	\N
2021-07-01	LM_ELE_ADR063	189	\N
2021-07-01	LM_ELE_ADR064	0	\N
2021-07-01	LM_ELE_ADR058	70101.91	\N
2021-07-01	LM_ELE_ADR072	20274	\N
2021-07-01	LM_ELE_ADR074	62922	\N
2021-07-01	LM_ELE_ADR076	0	\N
2021-07-01	LM_ELE_ADR081	36841.69	\N
2021-07-01	LM_ELE_ADR085	36149.33	\N
2021-07-01	LM_ELE_ADR090	32102.88	\N
2021-07-01	LM_ELE_ADR107	63073.41	\N
2021-07-01	LM_ELE_ADR108	5889.39	\N
2021-07-01	LM_ELE_ADR109	2011.29	\N
2021-07-01	LM_ELE_ADR110	406.22	\N
2021-07-01	LM_ELE_ADR113	44751.11	\N
2021-07-01	LM_ELE_ADR087	76703.7	\N
2021-07-01	LM_LC_ADR_B45	147.02	\N
2021-07-01	LM_LH_ADR_B46	49.35	\N
2021-07-01	LM_LH_ADR_B47	94.5	\N
2021-07-01	LM_WOD_ADR_B74	26.48	\N
2021-07-01	LM_ELE_ADR_B06	378002.34	\N
2021-07-01	LM_ELE_ADR046	0	\N
2021-07-01	LM_ELE_ADR010	99055.91	\N
2021-07-01	LM_ELE_ADR043	2352.51	\N
2021-07-01	LM_ELE_ADR_B11	27260.23	\N
2021-07-01	LM_WOD_ADR242	40.24	\N
2021-07-01	LM_ELE_ADR124	57138.13	\N
2021-07-01	LM_ELE_ADR112	655449.06	\N
2021-07-01	LM_WOD_ADR_B75	127.07	\N
2021-07-01	LM_ELE_ADR091	8948.39	\N
2021-07-01	LM_WOD_ADR_B80	90.46	\N
2021-07-01	LM_WOD_ADR_B81	36.43	\N
2021-07-01	LM_ELE_ADR_B04	225975.13	\N
2021-07-01	LM_ELE_ADR_B05	202525.88	\N
2021-07-01	LM_ELE_ADR_B09	251422.56	\N
2021-07-01	LM_ELE_ADR_B01	0	\N
2021-07-01	LM_ELE_ADR_B10	25237.06	\N
2021-07-01	LM_ELE_ADR_B02	0	\N
2021-07-01	LM_LC_ADR_B18	14.47	\N
2021-07-01	LM_LC_ADR_B20	58.14	\N
2021-07-01	LM_LC_ADR_B22	30.38	\N
2021-07-01	LM_LC_ADR_B24	10	\N
2021-07-01	LM_LC_ADR_B31	350.1	\N
2021-07-01	LM_LC_ADR_B41	383	\N
2021-07-01	LM_LC_ADR_B43	5.5	\N
2021-07-01	LM_LH_ADR_B23	50	\N
2021-07-01	LM_LH_ADR_B25	31.1	\N
2021-07-01	LM_LH_ADR_B27	94.8	\N
2021-07-01	LM_LH_ADR_B35	0	\N
2021-07-01	LM_LH_ADR_B36	0	\N
2021-07-01	LM_LH_ADR_B38	65.5	\N
2021-07-01	LM_LH_ADR_B44	3.4	\N
2021-07-01	LM_WOD_ADR_B76	1658.89	\N
2021-07-01	LM_WOD_ADR_B77	8.57	\N
2021-07-01	LM_LC_ADR_B16	32.45	\N
2021-07-01	LM_LH_ADR_B17	40.8	\N
2021-07-01	LM_WOD_ADR_B79	326.42	\N
2021-07-01	LM_ELE_ADR_B12	14061.99	\N
2021-07-01	LM_ELE_ADR_B13	13382.25	\N
2021-07-01	LM_LC_ADR_B46	45.07	\N
2021-07-01	LM_LC_ADR193	0	\N
2021-07-01	LM_ELE_ADR125	4098.1	\N
2021-07-01	LM_ELE_ADR069	243151	\N
2021-07-01	LM_ELE_ADR075	80	\N
2021-08-01	LM_LC_ADR170	48.96	\N
2021-08-01	LM_LC_ADR172	90.23	\N
2021-08-01	LM_LC_ADR179	70.6	\N
2021-08-01	LM_ELE_ADR021	199225.73	\N
2021-08-01	LM_ELE_ADR078	38202	\N
2021-08-01	LM_ELE_ADR066	0	\N
2021-08-01	LM_ELE_ADR080	149258.53	\N
2021-08-01	LM_LH_ADR199	128.7	\N
2021-08-01	LM_ELE_ADR115	21314.64	\N
2021-08-01	LM_WOD_ADR249_Solution Space	73.63	\N
2021-08-01	LM_WOD_MAIN_W	0	\N
2021-08-01	LM_LC_ADR123	371.5	\N
2021-08-01	LM_LC_ADR151	25990	\N
2021-08-01	LM_LC_ADR153	9222	\N
2021-08-01	LM_LC_ADR154	2101.6	\N
2021-08-01	LM_LC_ADR155	5624.8	\N
2021-08-01	LM_LC_ADR157	903.7	\N
2021-08-01	LM_LC_ADR158	282.7	\N
2021-08-01	LM_LC_ADR162	657.2	\N
2021-08-01	LM_LC_ADR168	69.5	\N
2021-08-01	LM_LC_ADR173	79.4	\N
2021-08-01	LM_LC_ADR174	135.32	\N
2021-08-01	LM_LC_ADR175	0	\N
2021-08-01	LM_LC_ADR176	84.7	\N
2021-08-01	LM_LC_ADR178	95.58	\N
2021-08-01	LM_LC_ADR184	38.96	\N
2021-08-01	LM_LC_ADR186	15.54	\N
2021-08-01	LM_LC_ADR187	29.04	\N
2021-08-01	LM_LC_ADR209	84.68	\N
2021-08-01	LM_LC_ADR32	0	\N
2021-08-01	LM_LC_ADR82	0	\N
2021-08-01	LM_LH_ADR122	10.8	\N
2021-08-01	LM_LH_ADR189	49.28	\N
2021-08-01	LM_LH_ADR195	390.1	\N
2021-08-01	LM_LH_ADR196	9	\N
2021-08-01	LM_LH_ADR198	1054.8	\N
2021-08-01	LM_LH_ADR200	42.4	\N
2021-08-01	LM_LH_ADR203	205.6	\N
2021-08-01	LM_LH_ADR204	86.2	\N
2021-08-01	LM_LH_ADR208	256.8	\N
2021-08-01	LM_LH_ADR211	21.6	\N
2021-08-01	LM_LH_ADR212	115	\N
2021-08-01	LM_LH_ADR216	27.97	\N
2021-08-01	LM_LH_ADR218	346.1	\N
2021-08-01	LM_LH_ADR221	247.3	\N
2021-08-01	LM_LH_ADR222	0	\N
2021-08-01	LM_LH_ADR227	34.4	\N
2021-08-01	LM_LH_ADR229	83.86	\N
2021-08-01	LM_LH_ADR231	0	\N
2021-08-01	LM_LH_ADR234	0	\N
2021-08-01	LM_LH_ADR235	84.1	\N
2021-08-01	LM_LH_ADR33	0	\N
2021-08-01	LM_ELE_ADR008	77991.25	\N
2021-08-01	LM_ELE_ADR012	61467.31	\N
2021-08-01	LM_ELE_ADR017	10777.36	\N
2021-08-01	LM_ELE_ADR019	2439.53	\N
2021-08-01	LM_ELE_ADR024	108638.59	\N
2021-08-01	LM_ELE_ADR027	33675.56	\N
2021-08-01	LM_LC_ADR163	26.44	\N
2021-08-01	LM_LC_ADR164	0.02	\N
2021-08-01	LM_LH_ADR201	65.7	\N
2021-08-01	LM_ELE_ADR029	9532.79	\N
2021-08-01	LM_ELE_ADR031	143999.84	\N
2021-08-01	LM_ELE_ADR038	262812.63	\N
2021-08-01	LM_ELE_ADR041	57072.89	\N
2021-08-01	LM_ELE_ADR045	5091.3	\N
2021-08-01	LM_ELE_ADR047	4569.57	\N
2021-08-01	LM_ELE_ADR049	12897.12	\N
2021-08-01	LM_ELE_ADR052	9609.51	\N
2021-08-01	LM_ELE_ADR054	26931.77	\N
2021-08-01	LM_ELE_ADR057	5320.81	\N
2021-08-01	LM_ELE_ADR059	19784.14	\N
2021-08-01	LM_ELE_ADR060	0	\N
2021-08-01	LM_ELE_ADR061	0	\N
2021-08-01	LM_ELE_ADR062	16746	\N
2021-08-01	LM_ELE_ADR065	0	\N
2021-08-01	LM_ELE_ADR067	125	\N
2021-08-01	LM_ELE_ADR068	473	\N
2021-08-01	LM_ELE_ADR070	80	\N
2021-08-01	LM_ELE_ADR071	64861	\N
2021-08-01	LM_ELE_ADR073	80	\N
2021-08-01	LM_ELE_ADR077	1063	\N
2021-08-01	LM_ELE_ADR084	48649.1	\N
2021-08-01	LM_ELE_ADR086	11215.69	\N
2021-08-01	LM_ELE_ADR088	31259.51	\N
2021-08-01	LM_ELE_ADR094	1414.52	\N
2021-08-01	LM_ELE_ADR095	84463.25	\N
2021-08-01	LM_ELE_ADR097	23214.79	\N
2021-08-01	LM_ELE_ADR098	3036.39	\N
2021-08-01	LM_ELE_ADR099	57513.94	\N
2021-08-01	LM_ELE_ADR100	13375.62	\N
2021-08-01	LM_ELE_ADR101	6199.88	\N
2021-08-01	LM_ELE_ADR111	362.08	\N
2021-08-01	LM_ELE_ADR116	9988.41	\N
2021-08-01	LM_ELE_ADR118	18346.22	\N
2021-08-01	LM_ELE_ADR119	64472.79	\N
2021-08-01	LM_ELE_ADR120	72649.29	\N
2021-08-01	LM_WOD_ADR129	92.15	\N
2021-08-01	LM_WOD_ADR140	120.39	\N
2021-08-01	LM_WOD_ADR147	51.55	\N
2021-08-01	LM_WOD_ADR246_Solution Space	419.69	\N
2021-08-01	LM_WOD_ADR248_Solution Space	31.4	\N
2021-08-01	LM_ELE_ADR_B03	111810.77	\N
2021-08-01	LM_ELE_ADR_B07	88525.84	\N
2021-08-01	LM_ELE_ADR_B08	132174.78	\N
2021-08-01	LM_LC_ADR_B26	104.76	\N
2021-08-01	LM_LC_ADR_B30	342.9	\N
2021-08-01	LM_LC_ADR_B32	765.8	\N
2021-08-01	LM_LC_ADR_B33	650.3	\N
2021-08-01	LM_LH_ADR_B19	72.8	\N
2021-08-01	LM_LH_ADR_B21	156.1	\N
2021-08-01	LM_LH_ADR_B34	0	\N
2021-08-01	LM_LH_ADR_B37	0.4	\N
2021-08-01	LM_LH_ADR_B39	91.8	\N
2021-08-01	LM_LH_ADR_B40	151.1	\N
2021-08-01	LM_LH_ADR_B42	0	\N
2021-08-01	LM_WOD_ADR_B78	175.02	\N
2021-08-01	LM_LC_ADR102	40.96	\N
2021-08-01	LM_LC_ADR103	45.02	\N
2021-08-01	LM_LC_ADR104	54.92	\N
2021-08-01	LM_LC_ADR152	4239.4	\N
2021-08-01	LM_LC_ADR149	0.91	\N
2021-08-01	LM_LC_ADR156	2750.8	\N
2021-08-01	LM_LC_ADR171	239.09	\N
2021-08-01	LM_LC_ADR165	35.91	\N
2021-08-01	LM_LC_ADR166	29	\N
2021-08-01	LM_LC_ADR180	123.88	\N
2021-08-01	LM_LC_ADR181	0.1	\N
2021-08-01	LM_LC_ADR182	73.31	\N
2021-08-01	LM_LC_ADR183	1.42	\N
2021-08-01	LM_LC_ADR185	16.13	\N
2021-08-01	LM_LC_ADR161	1199.6	\N
2021-08-01	LM_LC_ADR224	124.04	\N
2021-08-01	LM_LC_ADR89	26.12	\N
2021-08-01	LM_LC_ADR93	25.62	\N
2021-08-01	LM_LH_ADR145	9.48	\N
2021-08-01	LM_LH_ADR188	30.99	\N
2021-08-01	LM_LH_ADR190	7.62	\N
2021-08-01	LM_LH_ADR191	18.6	\N
2021-08-01	LM_LH_ADR192	0	\N
2021-08-01	LM_LH_ADR194	745.6	\N
2021-08-01	LM_LH_ADR207	384.4	\N
2021-08-01	LM_LH_ADR197	1173.4	\N
2021-08-01	LM_LH_ADR215	0	\N
2021-08-01	LM_LH_ADR219	0.03	\N
2021-08-01	LM_LH_ADR220	71.98	\N
2021-08-01	LM_LH_ADR223	155.4	\N
2021-08-01	LM_LH_ADR225	58.5	\N
2021-08-01	LM_LH_ADR226	50.97	\N
2021-08-01	LM_LH_ADR217	458.4	\N
2021-08-01	LM_LH_ADR228	26.8	\N
2021-08-01	LM_LH_ADR232	47.99	\N
2021-08-01	LM_LH_ADR233	42.9	\N
2021-08-01	LM_LH_ADR230	1.5	\N
2021-08-01	LM_ELE_ADR114	8.22	\N
2021-08-01	LM_ELE_ADR117	20751.78	\N
2021-08-01	LM_WOD_ADR132	265.85	\N
2021-08-01	LM_WOD_ADR133	323.46	\N
2021-08-01	LM_WOD_ADR134	18.19	\N
2021-08-01	LM_WOD_ADR135	0	\N
2021-08-01	LM_WOD_ADR136	62.56	\N
2021-08-01	LM_WOD_ADR139	1135.66	\N
2021-08-01	LM_WOD_ADR141	17	\N
2021-08-01	LM_WOD_ADR142	36	\N
2021-08-01	LM_WOD_ADR143	410.99	\N
2021-08-01	LM_WOD_ADR146	26031.1	\N
2021-08-01	LM_WOD_ADR148	0.05	\N
2021-08-01	LM_WOD_ADR150	33.84	\N
2021-08-01	LM_WOD_ADR237	911.1	\N
2021-08-01	LM_WOD_ADR238	2210.83	\N
2021-08-01	LM_WOD_ADR239	27.29	\N
2021-08-01	LM_WOD_ADR240	95.85	\N
2021-08-01	LM_WOD_ADR241	918.89	\N
2021-08-01	LM_ELE_ADR121	85.44	\N
2021-08-01	LM_ELE_ADR128	0	\N
2021-08-01	LM_WOD_ADR247_Solution Space	385.1	\N
2021-08-01	LM_WOD_ADR250_Solution Space	141.48	\N
2021-08-01	LM_WOD_ADR30	0	\N
2021-08-01	LM_ELE_ADR001	58874.63	\N
2021-08-01	LM_ELE_ADR002	77871.91	\N
2021-08-01	LM_ELE_ADR003	94020.49	\N
2021-08-01	LM_ELE_ADR006	67161.58	\N
2021-08-01	LM_ELE_ADR007	113735.45	\N
2021-08-01	LM_ELE_ADR009	154667.53	\N
2021-08-01	LM_ELE_ADR011	152282.5	\N
2021-08-01	LM_ELE_ADR013	192124.03	\N
2021-08-01	LM_ELE_ADR014	11997.58	\N
2021-08-01	LM_ELE_ADR015	110355.66	\N
2021-08-01	LM_ELE_ADR016	849366.19	\N
2021-08-01	LM_ELE_ADR018	11321.59	\N
2021-08-01	LM_ELE_ADR020	118231.04	\N
2021-08-01	LM_ELE_ADR022	115261.86	\N
2021-08-01	LM_ELE_ADR023	25488.13	\N
2021-08-01	LM_ELE_ADR025	344389	\N
2021-08-01	LM_ELE_ADR028	16577.74	\N
2021-08-01	LM_ELE_ADR034	19986.18	\N
2021-08-01	LM_ELE_ADR036	78001.34	\N
2021-08-01	LM_ELE_ADR039	278047.41	\N
2021-08-01	LM_ELE_ADR040	29531	\N
2021-08-01	LM_ELE_ADR042	3020.34	\N
2021-08-01	LM_ELE_ADR044	5981.1	\N
2021-08-01	LM_ELE_ADR048	6282.09	\N
2021-08-01	LM_ELE_ADR051	5976.99	\N
2021-08-01	LM_ELE_ADR053	17375.76	\N
2021-08-01	LM_ELE_ADR055	4909.11	\N
2021-08-01	LM_ELE_ADR056	19092.07	\N
2021-08-01	LM_ELE_ADR063	189	\N
2021-08-01	LM_ELE_ADR064	0	\N
2021-08-01	LM_ELE_ADR058	71415.94	\N
2021-08-01	LM_ELE_ADR072	20934	\N
2021-08-01	LM_ELE_ADR074	64861	\N
2021-08-01	LM_ELE_ADR076	0	\N
2021-08-01	LM_ELE_ADR081	37751.1	\N
2021-08-01	LM_ELE_ADR085	38020.19	\N
2021-08-01	LM_ELE_ADR090	32589.7	\N
2021-08-01	LM_ELE_ADR107	65332.71	\N
2021-08-01	LM_ELE_ADR108	5984.64	\N
2021-08-01	LM_ELE_ADR109	2011.43	\N
2021-08-01	LM_ELE_ADR110	406.22	\N
2021-08-01	LM_ELE_ADR113	45796.69	\N
2021-08-01	LM_ELE_ADR087	78117.51	\N
2021-08-01	LM_LC_ADR_B45	147.02	\N
2021-08-01	LM_LH_ADR_B46	49.35	\N
2021-08-01	LM_LH_ADR_B47	106.3	\N
2021-08-01	LM_WOD_ADR_B74	27.48	\N
2021-08-01	LM_ELE_ADR_B06	393270.28	\N
2021-08-01	LM_ELE_ADR046	0	\N
2021-08-01	LM_ELE_ADR010	100958.26	\N
2021-08-01	LM_ELE_ADR043	2402.06	\N
2021-08-01	LM_ELE_ADR_B11	27748.44	\N
2021-08-01	LM_WOD_ADR242	40.33	\N
2021-08-01	LM_ELE_ADR124	62021.04	\N
2021-08-01	LM_ELE_ADR112	664588.69	\N
2021-08-01	LM_WOD_ADR_B75	129.59	\N
2021-08-01	LM_ELE_ADR091	9276.48	\N
2021-08-01	LM_WOD_ADR_B80	93.04	\N
2021-08-01	LM_WOD_ADR_B81	37.08	\N
2021-08-01	LM_ELE_ADR_B04	253045.06	\N
2021-08-01	LM_ELE_ADR_B05	209713.36	\N
2021-08-01	LM_ELE_ADR_B09	256001.17	\N
2021-08-01	LM_ELE_ADR_B01	0	\N
2021-08-01	LM_ELE_ADR_B10	25476.3	\N
2021-08-01	LM_ELE_ADR_B02	0	\N
2021-08-01	LM_LC_ADR_B18	14.47	\N
2021-08-01	LM_LC_ADR_B20	58.14	\N
2021-08-01	LM_LC_ADR_B22	30.38	\N
2021-08-01	LM_LC_ADR_B24	10	\N
2021-08-01	LM_LC_ADR_B31	350.1	\N
2021-08-01	LM_LC_ADR_B41	383	\N
2021-08-01	LM_LC_ADR_B43	5.8	\N
2021-08-01	LM_LH_ADR_B23	55.8	\N
2021-08-01	LM_LH_ADR_B25	38.6	\N
2021-08-01	LM_LH_ADR_B27	99.3	\N
2021-08-01	LM_LH_ADR_B35	0	\N
2021-08-01	LM_LH_ADR_B36	0	\N
2021-08-01	LM_LH_ADR_B38	69.2	\N
2021-08-01	LM_LH_ADR_B44	3.5	\N
2021-08-01	LM_WOD_ADR_B76	1736.04	\N
2021-08-01	LM_WOD_ADR_B77	8.71	\N
2021-08-01	LM_LC_ADR_B16	32.45	\N
2021-08-01	LM_LH_ADR_B17	42.6	\N
2021-08-01	LM_WOD_ADR_B79	333.79	\N
2021-08-01	LM_ELE_ADR_B12	14472.51	\N
2021-08-01	LM_ELE_ADR_B13	13666.55	\N
2021-08-01	LM_LC_ADR_B46	45.07	\N
2021-08-01	LM_LC_ADR193	0	\N
2021-08-01	LM_ELE_ADR125	4221.8	\N
2021-08-01	LM_ELE_ADR069	248273	\N
2021-08-01	LM_ELE_ADR075	80	\N
2021-09-01	LM_LC_ADR170	49.22	\N
2021-09-01	LM_LC_ADR172	90.23	\N
2021-09-01	LM_LC_ADR179	70.6	\N
2021-09-01	LM_ELE_ADR021	202861.77	\N
2021-09-01	LM_ELE_ADR078	39808	\N
2021-09-01	LM_ELE_ADR066	0	\N
2021-09-01	LM_ELE_ADR080	152355.84	\N
2021-09-01	LM_LH_ADR199	132.9	\N
2021-09-01	LM_ELE_ADR115	22000.96	\N
2021-09-01	LM_WOD_ADR249_Solution Space	77.08	\N
2021-09-01	LM_WOD_MAIN_W	0	\N
2021-09-01	LM_LC_ADR123	378	\N
2021-09-01	LM_LC_ADR151	26063	\N
2021-09-01	LM_LC_ADR153	9242	\N
2021-09-01	LM_LC_ADR154	2117	\N
2021-09-01	LM_LC_ADR155	5653	\N
2021-09-01	LM_LC_ADR157	912.4	\N
2021-09-01	LM_LC_ADR158	284	\N
2021-09-01	LM_LC_ADR162	658.8	\N
2021-09-01	LM_LC_ADR168	70.7	\N
2021-09-01	LM_LC_ADR173	80.09	\N
2021-09-01	LM_LC_ADR174	138.75	\N
2021-09-01	LM_LC_ADR175	0	\N
2021-09-01	LM_LC_ADR176	84.7	\N
2021-09-01	LM_LC_ADR178	96.69	\N
2021-09-01	LM_LC_ADR184	38.96	\N
2021-09-01	LM_LC_ADR186	15.54	\N
2021-09-01	LM_LC_ADR187	29.04	\N
2021-09-01	LM_LC_ADR209	84.68	\N
2021-09-01	LM_LC_ADR32	0	\N
2021-09-01	LM_LC_ADR82	0	\N
2021-09-01	LM_LH_ADR122	12.2	\N
2021-09-01	LM_LH_ADR189	53.72	\N
2021-09-01	LM_LH_ADR195	402.3	\N
2021-09-01	LM_LH_ADR196	9	\N
2021-09-01	LM_LH_ADR198	1092.3	\N
2021-09-01	LM_LH_ADR200	43.5	\N
2021-09-01	LM_LH_ADR203	210.2	\N
2021-09-01	LM_LH_ADR204	90.1	\N
2021-09-01	LM_LH_ADR208	265.1	\N
2021-09-01	LM_LH_ADR211	24.1	\N
2021-09-01	LM_LH_ADR212	125.2	\N
2021-09-01	LM_LH_ADR216	30.09	\N
2021-09-01	LM_LH_ADR218	360.6	\N
2021-09-01	LM_LH_ADR221	263.5	\N
2021-09-01	LM_LH_ADR222	0	\N
2021-09-01	LM_LH_ADR227	40	\N
2021-09-01	LM_LH_ADR229	84.81	\N
2021-09-01	LM_LH_ADR231	0	\N
2021-09-01	LM_LH_ADR234	0	\N
2021-09-01	LM_LH_ADR235	84.1	\N
2021-09-01	LM_LH_ADR33	0	\N
2021-09-01	LM_ELE_ADR008	80200.38	\N
2021-09-01	LM_ELE_ADR012	61981.32	\N
2021-09-01	LM_ELE_ADR017	10980.81	\N
2021-09-01	LM_ELE_ADR019	2439.53	\N
2021-09-01	LM_ELE_ADR024	110566.53	\N
2021-09-01	LM_ELE_ADR027	33968.52	\N
2021-09-01	LM_LC_ADR163	26.45	\N
2021-09-01	LM_LC_ADR164	0.02	\N
2021-09-01	LM_LH_ADR201	72.8	\N
2021-09-01	LM_ELE_ADR029	9979.25	\N
2021-09-01	LM_ELE_ADR031	148047.17	\N
2021-09-01	LM_ELE_ADR038	273782.66	\N
2021-09-01	LM_ELE_ADR041	57700.88	\N
2021-09-01	LM_ELE_ADR045	5196.68	\N
2021-09-01	LM_ELE_ADR047	4670.91	\N
2021-09-01	LM_ELE_ADR049	13137.29	\N
2021-09-01	LM_ELE_ADR052	9802.2	\N
2021-09-01	LM_ELE_ADR054	27444.63	\N
2021-09-01	LM_ELE_ADR057	5416.5	\N
2021-09-01	LM_ELE_ADR059	20294.84	\N
2021-09-01	LM_ELE_ADR060	0	\N
2021-09-01	LM_ELE_ADR061	0	\N
2021-09-01	LM_ELE_ADR062	17338	\N
2021-09-01	LM_ELE_ADR065	0	\N
2021-09-01	LM_ELE_ADR067	126	\N
2021-09-01	LM_ELE_ADR068	554	\N
2021-09-01	LM_ELE_ADR070	80	\N
2021-09-01	LM_ELE_ADR071	66971	\N
2021-09-01	LM_ELE_ADR073	80	\N
2021-09-01	LM_ELE_ADR077	1063	\N
2021-09-01	LM_ELE_ADR084	49669.82	\N
2021-09-01	LM_ELE_ADR086	11612.12	\N
2021-09-01	LM_ELE_ADR088	32222.84	\N
2021-09-01	LM_ELE_ADR094	1432.65	\N
2021-09-01	LM_ELE_ADR095	86779.09	\N
2021-09-01	LM_ELE_ADR097	24151.32	\N
2021-09-01	LM_ELE_ADR098	3108.81	\N
2021-09-01	LM_ELE_ADR099	60490.83	\N
2021-09-01	LM_ELE_ADR100	13787.12	\N
2021-09-01	LM_ELE_ADR101	6408.37	\N
2021-09-01	LM_ELE_ADR111	362.23	\N
2021-09-01	LM_ELE_ADR116	11303.96	\N
2021-09-01	LM_ELE_ADR118	18628.89	\N
2021-09-01	LM_ELE_ADR119	65852.02	\N
2021-09-01	LM_ELE_ADR120	72716.67	\N
2021-09-01	LM_WOD_ADR129	95.53	\N
2021-09-01	LM_WOD_ADR140	120.62	\N
2021-09-01	LM_WOD_ADR147	52.87	\N
2021-09-01	LM_WOD_ADR246_Solution Space	436.83	\N
2021-09-01	LM_WOD_ADR248_Solution Space	32.97	\N
2021-09-01	LM_ELE_ADR_B03	114001.12	\N
2021-09-01	LM_ELE_ADR_B07	89911.17	\N
2021-09-01	LM_ELE_ADR_B08	134226.34	\N
2021-09-01	LM_LC_ADR_B26	105.07	\N
2021-09-01	LM_LC_ADR_B30	343.7	\N
2021-09-01	LM_LC_ADR_B32	767.2	\N
2021-09-01	LM_LC_ADR_B33	652.3	\N
2021-09-01	LM_LH_ADR_B19	73.8	\N
2021-09-01	LM_LH_ADR_B21	161.1	\N
2021-09-01	LM_LH_ADR_B34	0	\N
2021-09-01	LM_LH_ADR_B37	0.4	\N
2021-09-01	LM_LH_ADR_B39	93.9	\N
2021-09-01	LM_LH_ADR_B40	155.4	\N
2021-09-01	LM_LH_ADR_B42	0	\N
2021-09-01	LM_WOD_ADR_B78	176.42	\N
2021-09-01	LM_LC_ADR102	41.37	\N
2021-09-01	LM_LC_ADR103	45.43	\N
2021-09-01	LM_LC_ADR104	55.57	\N
2021-09-01	LM_LC_ADR152	4244.1	\N
2021-09-01	LM_LC_ADR149	0.91	\N
2021-09-01	LM_LC_ADR156	2765.7	\N
2021-09-01	LM_LC_ADR171	239.2	\N
2021-09-01	LM_LC_ADR165	36.32	\N
2021-09-01	LM_LC_ADR166	29.3	\N
2021-09-01	LM_LC_ADR180	124.44	\N
2021-09-01	LM_LC_ADR181	0.1	\N
2021-09-01	LM_LC_ADR182	73.36	\N
2021-09-01	LM_LC_ADR183	1.42	\N
2021-09-01	LM_LC_ADR185	16.13	\N
2021-09-01	LM_LC_ADR161	1207.9	\N
2021-09-01	LM_LC_ADR224	125.26	\N
2021-09-01	LM_LC_ADR89	26.45	\N
2021-09-01	LM_LC_ADR93	25.95	\N
2021-09-01	LM_LH_ADR145	9.8	\N
2021-09-01	LM_LH_ADR188	32.18	\N
2021-09-01	LM_LH_ADR190	7.79	\N
2021-09-01	LM_LH_ADR191	18.8	\N
2021-09-01	LM_LH_ADR192	0	\N
2021-09-01	LM_LH_ADR194	771	\N
2021-09-01	LM_LH_ADR207	387.7	\N
2021-09-01	LM_LH_ADR197	1202.5	\N
2021-09-01	LM_LH_ADR215	0	\N
2021-09-01	LM_LH_ADR219	0.03	\N
2021-09-01	LM_LH_ADR220	71.98	\N
2021-09-01	LM_LH_ADR223	169.6	\N
2021-09-01	LM_LH_ADR225	62.6	\N
2021-09-01	LM_LH_ADR226	51.42	\N
2021-09-01	LM_LH_ADR217	470	\N
2021-09-01	LM_LH_ADR228	26.8	\N
2021-09-01	LM_LH_ADR232	49.4	\N
2021-09-01	LM_LH_ADR233	44.6	\N
2021-09-01	LM_LH_ADR230	1.5	\N
2021-09-01	LM_ELE_ADR114	27.81	\N
2021-09-01	LM_ELE_ADR117	21109.11	\N
2021-09-01	LM_WOD_ADR132	272.88	\N
2021-09-01	LM_WOD_ADR133	327.27	\N
2021-09-01	LM_WOD_ADR134	18.27	\N
2021-09-01	LM_WOD_ADR135	0	\N
2021-09-01	LM_WOD_ADR136	63.5	\N
2021-09-01	LM_WOD_ADR139	1190.78	\N
2021-09-01	LM_WOD_ADR141	17	\N
2021-09-01	LM_WOD_ADR142	36	\N
2021-09-01	LM_WOD_ADR143	461.96	\N
2021-09-01	LM_WOD_ADR146	26660.2	\N
2021-09-01	LM_WOD_ADR148	0.05	\N
2021-09-01	LM_WOD_ADR150	34.87	\N
2021-09-01	LM_WOD_ADR237	921.96	\N
2021-09-01	LM_WOD_ADR238	2211.66	\N
2021-09-01	LM_WOD_ADR239	27.72	\N
2021-09-01	LM_WOD_ADR240	99.92	\N
2021-09-01	LM_WOD_ADR241	942.09	\N
2021-09-01	LM_ELE_ADR121	159197.11	\N
2021-09-01	LM_ELE_ADR128	0	\N
2021-09-01	LM_WOD_ADR247_Solution Space	403.63	\N
2021-09-01	LM_WOD_ADR250_Solution Space	150.71	\N
2021-09-01	LM_WOD_ADR30	0	\N
2021-09-01	LM_ELE_ADR001	60136.47	\N
2021-09-01	LM_ELE_ADR002	79330.15	\N
2021-09-01	LM_ELE_ADR003	95754.95	\N
2021-09-01	LM_ELE_ADR006	67984.52	\N
2021-09-01	LM_ELE_ADR007	115028.41	\N
2021-09-01	LM_ELE_ADR009	155515.97	\N
2021-09-01	LM_ELE_ADR011	153288.19	\N
2021-09-01	LM_ELE_ADR013	192436.98	\N
2021-09-01	LM_ELE_ADR014	12320.34	\N
2021-09-01	LM_ELE_ADR015	113091.75	\N
2021-09-01	LM_ELE_ADR016	864589.63	\N
2021-09-01	LM_ELE_ADR018	11572.28	\N
2021-09-01	LM_ELE_ADR020	120383.42	\N
2021-09-01	LM_ELE_ADR022	118320.97	\N
2021-09-01	LM_ELE_ADR023	26475.51	\N
2021-09-01	LM_ELE_ADR025	356782.56	\N
2021-09-01	LM_ELE_ADR028	17203.97	\N
2021-09-01	LM_ELE_ADR034	21184.16	\N
2021-09-01	LM_ELE_ADR036	78816.08	\N
2021-09-01	LM_ELE_ADR039	284463.22	\N
2021-09-01	LM_ELE_ADR040	29531	\N
2021-09-01	LM_ELE_ADR042	3086.24	\N
2021-09-01	LM_ELE_ADR044	6083.54	\N
2021-09-01	LM_ELE_ADR048	6389.79	\N
2021-09-01	LM_ELE_ADR051	6086.89	\N
2021-09-01	LM_ELE_ADR053	17451.16	\N
2021-09-01	LM_ELE_ADR055	5007.91	\N
2021-09-01	LM_ELE_ADR056	19470.48	\N
2021-09-01	LM_ELE_ADR063	189	\N
2021-09-01	LM_ELE_ADR064	0	\N
2021-09-01	LM_ELE_ADR058	72905.41	\N
2021-09-01	LM_ELE_ADR072	21684	\N
2021-09-01	LM_ELE_ADR074	66971	\N
2021-09-01	LM_ELE_ADR076	0	\N
2021-09-01	LM_ELE_ADR081	38846.95	\N
2021-09-01	LM_ELE_ADR085	40309.34	\N
2021-09-01	LM_ELE_ADR090	33148.19	\N
2021-09-01	LM_ELE_ADR107	67646.13	\N
2021-09-01	LM_ELE_ADR108	6060.87	\N
2021-09-01	LM_ELE_ADR109	2011.73	\N
2021-09-01	LM_ELE_ADR110	406.22	\N
2021-09-01	LM_ELE_ADR113	46624.06	\N
2021-09-01	LM_ELE_ADR087	79767.31	\N
2021-09-01	LM_LC_ADR_B45	147.19	\N
2021-09-01	LM_LH_ADR_B46	49.35	\N
2021-09-01	LM_LH_ADR_B47	113	\N
2021-09-01	LM_WOD_ADR_B74	28.46	\N
2021-09-01	LM_ELE_ADR_B06	402729.09	\N
2021-09-01	LM_ELE_ADR046	0	\N
2021-09-01	LM_ELE_ADR010	102811.7	\N
2021-09-01	LM_ELE_ADR043	2456.58	\N
2021-09-01	LM_ELE_ADR_B11	28238.55	\N
2021-09-01	LM_WOD_ADR242	40.46	\N
2021-09-01	LM_ELE_ADR124	67253.3	\N
2021-09-01	LM_ELE_ADR112	674885.69	\N
2021-09-01	LM_WOD_ADR_B75	134.01	\N
2021-09-01	LM_ELE_ADR091	9650.81	\N
2021-09-01	LM_WOD_ADR_B80	95.86	\N
2021-09-01	LM_WOD_ADR_B81	38	\N
2021-09-01	LM_ELE_ADR_B04	262766.25	\N
2021-09-01	LM_ELE_ADR_B05	220849.41	\N
2021-09-01	LM_ELE_ADR_B09	261323.31	\N
2021-09-01	LM_ELE_ADR_B01	0	\N
2021-09-01	LM_ELE_ADR_B10	26075.45	\N
2021-09-01	LM_ELE_ADR_B02	0	\N
2021-09-01	LM_LC_ADR_B18	14.53	\N
2021-09-01	LM_LC_ADR_B20	58.19	\N
2021-09-01	LM_LC_ADR_B22	30.56	\N
2021-09-01	LM_LC_ADR_B24	10	\N
2021-09-01	LM_LC_ADR_B31	350.3	\N
2021-09-01	LM_LC_ADR_B41	383.7	\N
2021-09-01	LM_LC_ADR_B43	6.1	\N
2021-09-01	LM_LH_ADR_B23	59	\N
2021-09-01	LM_LH_ADR_B25	45	\N
2021-09-01	LM_LH_ADR_B27	102.6	\N
2021-09-01	LM_LH_ADR_B35	0	\N
2021-09-01	LM_LH_ADR_B36	0	\N
2021-09-01	LM_LH_ADR_B38	70.3	\N
2021-09-01	LM_LH_ADR_B44	3.8	\N
2021-09-01	LM_WOD_ADR_B76	1736.57	\N
2021-09-01	LM_WOD_ADR_B77	8.75	\N
2021-09-01	LM_LC_ADR_B16	32.45	\N
2021-09-01	LM_LH_ADR_B17	43.7	\N
2021-09-01	LM_WOD_ADR_B79	344.29	\N
2021-09-01	LM_ELE_ADR_B12	14876.21	\N
2021-09-01	LM_ELE_ADR_B13	14013.86	\N
2021-09-01	LM_LC_ADR_B46	45.07	\N
2021-09-01	LM_LC_ADR193	0	\N
2021-09-01	LM_ELE_ADR125	4364.85	\N
2021-09-01	LM_ELE_ADR069	254150	\N
2021-09-01	LM_ELE_ADR075	80	\N
2021-10-01	LM_LC_ADR170	49.47	\N
2021-10-01	LM_LC_ADR172	90.34	\N
2021-10-01	LM_LC_ADR179	70.63	\N
2021-10-01	LM_ELE_ADR021	207188.98	\N
2021-10-01	LM_ELE_ADR078	41999	\N
2021-10-01	LM_ELE_ADR066	0	\N
2021-10-01	LM_ELE_ADR080	155066.56	\N
2021-10-01	LM_LH_ADR199	135.4	\N
2021-10-01	LM_ELE_ADR115	22689.9	\N
2021-10-01	LM_WOD_ADR249_Solution Space	81.19	\N
2021-10-01	LM_WOD_MAIN_W	0	\N
2021-10-01	LM_LC_ADR123	391.8	\N
2021-10-01	LM_LC_ADR151	26237.002	\N
2021-10-01	LM_LC_ADR153	9285	\N
2021-10-01	LM_LC_ADR154	2148.1	\N
2021-10-01	LM_LC_ADR155	5712	\N
2021-10-01	LM_LC_ADR157	924.5	\N
2021-10-01	LM_LC_ADR158	287.4	\N
2021-10-01	LM_LC_ADR162	662.7	\N
2021-10-01	LM_LC_ADR168	73.7	\N
2021-10-01	LM_LC_ADR173	81.97	\N
2021-10-01	LM_LC_ADR174	146.61	\N
2021-10-01	LM_LC_ADR175	0	\N
2021-10-01	LM_LC_ADR176	84.7	\N
2021-10-01	LM_LC_ADR178	98.91	\N
2021-10-01	LM_LC_ADR184	39.17	\N
2021-10-01	LM_LC_ADR186	15.54	\N
2021-10-01	LM_LC_ADR187	29.04	\N
2021-10-01	LM_LC_ADR209	84.72	\N
2021-10-01	LM_LC_ADR32	0	\N
2021-10-01	LM_LC_ADR82	0.77	\N
2021-10-01	LM_LH_ADR122	13.3	\N
2021-10-01	LM_LH_ADR189	55.42	\N
2021-10-01	LM_LH_ADR195	408.4	\N
2021-10-01	LM_LH_ADR196	9	\N
2021-10-01	LM_LH_ADR198	1122	\N
2021-10-01	LM_LH_ADR200	44.4	\N
2021-10-01	LM_LH_ADR203	212.7	\N
2021-10-01	LM_LH_ADR204	92.5	\N
2021-10-01	LM_LH_ADR208	271.8	\N
2021-10-01	LM_LH_ADR211	26.2	\N
2021-10-01	LM_LH_ADR212	134.8	\N
2021-10-01	LM_LH_ADR216	30.09	\N
2021-10-01	LM_LH_ADR218	372.5	\N
2021-10-01	LM_LH_ADR221	279.7	\N
2021-10-01	LM_LH_ADR222	0	\N
2021-10-01	LM_LH_ADR227	40.9	\N
2021-10-01	LM_LH_ADR229	84.81	\N
2021-10-01	LM_LH_ADR231	0	\N
2021-10-01	LM_LH_ADR234	0	\N
2021-10-01	LM_LH_ADR235	84.4	\N
2021-10-01	LM_LH_ADR33	0	\N
2021-10-01	LM_ELE_ADR008	82018.48	\N
2021-10-01	LM_ELE_ADR012	63353	\N
2021-10-01	LM_ELE_ADR017	11189.95	\N
2021-10-01	LM_ELE_ADR019	2439.53	\N
2021-10-01	LM_ELE_ADR024	112330.98	\N
2021-10-01	LM_ELE_ADR027	34233.54	\N
2021-10-01	LM_LC_ADR163	26.46	\N
2021-10-01	LM_LC_ADR164	0.02	\N
2021-10-01	LM_LH_ADR201	80.4	\N
2021-10-01	LM_ELE_ADR029	10393.14	\N
2021-10-01	LM_ELE_ADR031	155303.34	\N
2021-10-01	LM_ELE_ADR038	282444.97	\N
2021-10-01	LM_ELE_ADR041	58626.18	\N
2021-10-01	LM_ELE_ADR045	5304.21	\N
2021-10-01	LM_ELE_ADR047	4774.66	\N
2021-10-01	LM_ELE_ADR049	13358.75	\N
2021-10-01	LM_ELE_ADR052	9973.67	\N
2021-10-01	LM_ELE_ADR054	27897.96	\N
2021-10-01	LM_ELE_ADR057	5513.08	\N
2021-10-01	LM_ELE_ADR059	20733.94	\N
2021-10-01	LM_ELE_ADR060	0	\N
2021-10-01	LM_ELE_ADR061	0	\N
2021-10-01	LM_ELE_ADR062	17897	\N
2021-10-01	LM_ELE_ADR065	0	\N
2021-10-01	LM_ELE_ADR067	127	\N
2021-10-01	LM_ELE_ADR068	691	\N
2021-10-01	LM_ELE_ADR070	88	\N
2021-10-01	LM_ELE_ADR071	68685	\N
2021-10-01	LM_ELE_ADR073	88	\N
2021-10-01	LM_ELE_ADR077	1063	\N
2021-10-01	LM_ELE_ADR084	50500.22	\N
2021-10-01	LM_ELE_ADR086	11968.03	\N
2021-10-01	LM_ELE_ADR088	33125.77	\N
2021-10-01	LM_ELE_ADR094	1436.89	\N
2021-10-01	LM_ELE_ADR095	88822.03	\N
2021-10-01	LM_ELE_ADR097	25116.91	\N
2021-10-01	LM_ELE_ADR098	3118.36	\N
2021-10-01	LM_ELE_ADR099	63245.66	\N
2021-10-01	LM_ELE_ADR100	14378.39	\N
2021-10-01	LM_ELE_ADR101	6596.67	\N
2021-10-01	LM_ELE_ADR111	362.45	\N
2021-10-01	LM_ELE_ADR116	12475.49	\N
2021-10-01	LM_ELE_ADR118	18737.56	\N
2021-10-01	LM_ELE_ADR119	67089.59	\N
2021-10-01	LM_ELE_ADR120	72774.93	\N
2021-10-01	LM_WOD_ADR129	99.27	\N
2021-10-01	LM_WOD_ADR140	120.87	\N
2021-10-01	LM_WOD_ADR147	53.88	\N
2021-10-01	LM_WOD_ADR246_Solution Space	456.02	\N
2021-10-01	LM_WOD_ADR248_Solution Space	34.73	\N
2021-10-01	LM_ELE_ADR_B03	116011.19	\N
2021-10-01	LM_ELE_ADR_B07	91297.08	\N
2021-10-01	LM_ELE_ADR_B08	136360.48	\N
2021-10-01	LM_LC_ADR_B26	106.14	\N
2021-10-01	LM_LC_ADR_B30	348	\N
2021-10-01	LM_LC_ADR_B32	773.3	\N
2021-10-01	LM_LC_ADR_B33	658.9	\N
2021-10-01	LM_LH_ADR_B19	77	\N
2021-10-01	LM_LH_ADR_B21	165.9	\N
2021-10-01	LM_LH_ADR_B34	0	\N
2021-10-01	LM_LH_ADR_B37	0.4	\N
2021-10-01	LM_LH_ADR_B39	94.9	\N
2021-10-01	LM_LH_ADR_B40	158.1	\N
2021-10-01	LM_LH_ADR_B42	0	\N
2021-10-01	LM_WOD_ADR_B78	177.62	\N
2021-10-01	LM_LC_ADR102	42.15	\N
2021-10-01	LM_LC_ADR103	46.22	\N
2021-10-01	LM_LC_ADR104	56.96	\N
2021-10-01	LM_LC_ADR152	4267.9	\N
2021-10-01	LM_LC_ADR149	0.91	\N
2021-10-01	LM_LC_ADR156	2796.9	\N
2021-10-01	LM_LC_ADR171	239.54	\N
2021-10-01	LM_LC_ADR165	37.14	\N
2021-10-01	LM_LC_ADR166	29.88	\N
2021-10-01	LM_LC_ADR180	125.39	\N
2021-10-01	LM_LC_ADR181	0.1	\N
2021-10-01	LM_LC_ADR182	73.67	\N
2021-10-01	LM_LC_ADR183	1.42	\N
2021-10-01	LM_LC_ADR185	16.13	\N
2021-10-01	LM_LC_ADR161	1221	\N
2021-10-01	LM_LC_ADR224	127.77	\N
2021-10-01	LM_LC_ADR89	27.13	\N
2021-10-01	LM_LC_ADR93	26.63	\N
2021-10-01	LM_LH_ADR145	9.8	\N
2021-10-01	LM_LH_ADR188	32.18	\N
2021-10-01	LM_LH_ADR190	7.79	\N
2021-10-01	LM_LH_ADR191	18.8	\N
2021-10-01	LM_LH_ADR192	0	\N
2021-10-01	LM_LH_ADR194	780	\N
2021-10-01	LM_LH_ADR207	390.1	\N
2021-10-01	LM_LH_ADR197	1220.3	\N
2021-10-01	LM_LH_ADR215	0	\N
2021-10-01	LM_LH_ADR219	0.03	\N
2021-10-01	LM_LH_ADR220	71.98	\N
2021-10-01	LM_LH_ADR223	176.6	\N
2021-10-01	LM_LH_ADR225	65.8	\N
2021-10-01	LM_LH_ADR226	52.68	\N
2021-10-01	LM_LH_ADR217	478.1	\N
2021-10-01	LM_LH_ADR228	26.8	\N
2021-10-01	LM_LH_ADR232	50.73	\N
2021-10-01	LM_LH_ADR233	45	\N
2021-10-01	LM_LH_ADR230	1.6	\N
2021-10-01	LM_ELE_ADR114	234686.39	\N
2021-10-01	LM_ELE_ADR117	21530.5	\N
2021-10-01	LM_WOD_ADR132	278.82	\N
2021-10-01	LM_WOD_ADR133	330.9	\N
2021-10-01	LM_WOD_ADR134	18.32	\N
2021-10-01	LM_WOD_ADR135	0	\N
2021-10-01	LM_WOD_ADR136	64.42	\N
2021-10-01	LM_WOD_ADR139	1229.01	\N
2021-10-01	LM_WOD_ADR141	17	\N
2021-10-01	LM_WOD_ADR142	36	\N
2021-10-01	LM_WOD_ADR143	536.38	\N
2021-10-01	LM_WOD_ADR146	27358.2	\N
2021-10-01	LM_WOD_ADR148	0.05	\N
2021-10-01	LM_WOD_ADR150	35.9	\N
2021-10-01	LM_WOD_ADR237	922.44	\N
2021-10-01	LM_WOD_ADR238	2212.2	\N
2021-10-01	LM_WOD_ADR239	28.41	\N
2021-10-01	LM_WOD_ADR240	104.38	\N
2021-10-01	LM_WOD_ADR241	966.51	\N
2021-10-01	LM_ELE_ADR121	159337.59	\N
2021-10-01	LM_ELE_ADR128	0	\N
2021-10-01	LM_WOD_ADR247_Solution Space	432.41	\N
2021-10-01	LM_WOD_ADR250_Solution Space	158.95	\N
2021-10-01	LM_WOD_ADR30	0	\N
2021-10-01	LM_ELE_ADR001	61353.58	\N
2021-10-01	LM_ELE_ADR002	80798.09	\N
2021-10-01	LM_ELE_ADR003	97450.34	\N
2021-10-01	LM_ELE_ADR006	69242.64	\N
2021-10-01	LM_ELE_ADR007	116377.61	\N
2021-10-01	LM_ELE_ADR009	156773.48	\N
2021-10-01	LM_ELE_ADR011	154770.3	\N
2021-10-01	LM_ELE_ADR013	194130.38	\N
2021-10-01	LM_ELE_ADR014	12619.06	\N
2021-10-01	LM_ELE_ADR015	115660.3	\N
2021-10-01	LM_ELE_ADR016	878135.44	\N
2021-10-01	LM_ELE_ADR018	11797.69	\N
2021-10-01	LM_ELE_ADR020	122399.73	\N
2021-10-01	LM_ELE_ADR022	121126.85	\N
2021-10-01	LM_ELE_ADR023	27435.62	\N
2021-10-01	LM_ELE_ADR025	368265.22	\N
2021-10-01	LM_ELE_ADR028	17225	\N
2021-10-01	LM_ELE_ADR034	22241.62	\N
2021-10-01	LM_ELE_ADR036	80053	\N
2021-10-01	LM_ELE_ADR039	291323.94	\N
2021-10-01	LM_ELE_ADR040	29531	\N
2021-10-01	LM_ELE_ADR042	3145.55	\N
2021-10-01	LM_ELE_ADR044	6182.73	\N
2021-10-01	LM_ELE_ADR048	6495.33	\N
2021-10-01	LM_ELE_ADR051	6186.87	\N
2021-10-01	LM_ELE_ADR053	17518.61	\N
2021-10-01	LM_ELE_ADR055	5096.3	\N
2021-10-01	LM_ELE_ADR056	19810.58	\N
2021-10-01	LM_ELE_ADR063	189	\N
2021-10-01	LM_ELE_ADR064	0	\N
2021-10-01	LM_ELE_ADR058	74235.74	\N
2021-10-01	LM_ELE_ADR072	22363	\N
2021-10-01	LM_ELE_ADR074	68685	\N
2021-10-01	LM_ELE_ADR076	0	\N
2021-10-01	LM_ELE_ADR081	40065.14	\N
2021-10-01	LM_ELE_ADR085	42413.95	\N
2021-10-01	LM_ELE_ADR090	33862.21	\N
2021-10-01	LM_ELE_ADR107	69925.54	\N
2021-10-01	LM_ELE_ADR108	6121.08	\N
2021-10-01	LM_ELE_ADR109	2012.89	\N
2021-10-01	LM_ELE_ADR110	406.22	\N
2021-10-01	LM_ELE_ADR113	47648.37	\N
2021-10-01	LM_ELE_ADR087	81020.84	\N
2021-10-01	LM_LC_ADR_B45	149.22	\N
2021-10-01	LM_LH_ADR_B46	49.35	\N
2021-10-01	LM_LH_ADR_B47	115.5	\N
2021-10-01	LM_WOD_ADR_B74	29.68	\N
2021-10-01	LM_ELE_ADR_B06	407569	\N
2021-10-01	LM_ELE_ADR046	0	\N
2021-10-01	LM_ELE_ADR010	105187.4	\N
2021-10-01	LM_ELE_ADR043	2504.1	\N
2021-10-01	LM_ELE_ADR_B11	28783.63	\N
2021-10-01	LM_WOD_ADR242	41.48	\N
2021-10-01	LM_ELE_ADR124	72250.16	\N
2021-10-01	LM_ELE_ADR112	683710.06	\N
2021-10-01	LM_WOD_ADR_B75	141.49	\N
2021-10-01	LM_ELE_ADR091	9985.07	\N
2021-10-01	LM_WOD_ADR_B80	101.04	\N
2021-10-01	LM_WOD_ADR_B81	38.94	\N
2021-10-01	LM_ELE_ADR_B04	269433.63	\N
2021-10-01	LM_ELE_ADR_B05	230654.34	\N
2021-10-01	LM_ELE_ADR_B09	266403.13	\N
2021-10-01	LM_ELE_ADR_B01	0	\N
2021-10-01	LM_ELE_ADR_B10	26616.45	\N
2021-10-01	LM_ELE_ADR_B02	0	\N
2021-10-01	LM_LC_ADR_B18	14.71	\N
2021-10-01	LM_LC_ADR_B20	58.37	\N
2021-10-01	LM_LC_ADR_B22	30.9	\N
2021-10-01	LM_LC_ADR_B24	10.02	\N
2021-10-01	LM_LC_ADR_B31	352.6	\N
2021-10-01	LM_LC_ADR_B41	387	\N
2021-10-01	LM_LC_ADR_B43	6.3	\N
2021-10-01	LM_LH_ADR_B23	62.5	\N
2021-10-01	LM_LH_ADR_B25	48	\N
2021-10-01	LM_LH_ADR_B27	108.8	\N
2021-10-01	LM_LH_ADR_B35	0	\N
2021-10-01	LM_LH_ADR_B36	0	\N
2021-10-01	LM_LH_ADR_B38	71.3	\N
2021-10-01	LM_LH_ADR_B44	4.1	\N
2021-10-01	LM_WOD_ADR_B76	1736.57	\N
2021-10-01	LM_WOD_ADR_B77	8.81	\N
2021-10-01	LM_LC_ADR_B16	32.45	\N
2021-10-01	LM_LH_ADR_B17	46	\N
2021-10-01	LM_WOD_ADR_B79	360.11	\N
2021-10-01	LM_ELE_ADR_B12	15296.32	\N
2021-10-01	LM_ELE_ADR_B13	14309.25	\N
2021-10-01	LM_LC_ADR_B46	45.07	\N
2021-10-01	LM_LC_ADR193	0	\N
2021-10-01	LM_ELE_ADR125	4493.19	\N
2021-10-01	LM_ELE_ADR069	259359	\N
2021-10-01	LM_ELE_ADR075	88	\N
2022-02-01	LM_LC_ADR179	84.03	\N
2022-02-01	LM_ELE_ADR021	251549.02	\N
2022-02-01	LM_ELE_ADR078	51470	\N
2022-02-01	LM_ELE_ADR066	0	\N
2022-02-01	LM_LH_ADR199	143.6	\N
2022-02-01	LM_WOD_ADR249_Solution Space	97.4	\N
2022-02-01	LM_LC_ADR151	29352	\N
2022-02-01	LM_LC_ADR153	10127.999	\N
2022-02-01	LM_LC_ADR154	2484.3	\N
2022-02-01	LM_LC_ADR157	1048.1	\N
2022-02-01	LM_LC_ADR158	339.7	\N
2022-02-01	LM_LC_ADR162	756.6	\N
2022-02-01	LM_LC_ADR168	104.7	\N
2022-02-01	LM_LC_ADR173	96.82	\N
2022-02-01	LM_LC_ADR174	185.11	\N
2022-02-01	LM_LC_ADR175	0	\N
2022-02-01	LM_LC_ADR178	123.98	\N
2022-02-01	LM_LC_ADR184	42.21	\N
2022-02-01	LM_LC_ADR186	19.23	\N
2022-02-01	LM_LC_ADR187	32.69	\N
2022-02-01	LM_LC_ADR209	93.91	\N
2022-02-01	LM_LC_ADR32	0	\N
2022-02-01	LM_LC_ADR82	17.73	\N
2022-02-01	LM_LH_ADR189	59.89	\N
2022-02-01	LM_LH_ADR195	421.2	\N
2022-02-01	LM_LH_ADR196	9	\N
2022-02-01	LM_LH_ADR198	1202.7	\N
2022-02-01	LM_LH_ADR200	46.2	\N
2022-02-01	LM_LH_ADR203	219.2	\N
2022-02-01	LM_LH_ADR204	97	\N
2022-02-01	LM_LH_ADR211	34	\N
2022-02-01	LM_LH_ADR212	172.6	\N
2022-02-01	LM_LH_ADR216	34.12	\N
2022-02-01	LM_LH_ADR218	413.2	\N
2022-02-01	LM_LH_ADR221	320	\N
2022-02-01	LM_LH_ADR227	41.2	\N
2022-02-01	LM_LH_ADR229	84.89	\N
2022-02-01	LM_LH_ADR231	0	\N
2022-02-01	LM_LH_ADR234	0	\N
2022-02-01	LM_LH_ADR235	86.5	\N
2022-02-01	LM_LH_ADR33	0	\N
2022-02-01	LM_ELE_ADR008	97831.65	\N
2022-02-01	LM_ELE_ADR012	87149.57	\N
2022-02-01	LM_ELE_ADR017	12257.11	\N
2022-02-01	LM_ELE_ADR024	121066.4	\N
2022-02-01	LM_ELE_ADR027	35402.46	\N
2022-02-01	LM_LC_ADR163	29.09	\N
2022-02-01	LM_LC_ADR164	0.02	\N
2022-02-01	LM_ELE_ADR029	12371.34	\N
2022-02-01	LM_ELE_ADR031	181418.47	\N
2022-02-01	LM_ELE_ADR038	334335	\N
2022-02-01	LM_ELE_ADR041	64496.91	\N
2022-02-01	LM_ELE_ADR045	5726.03	\N
2022-02-01	LM_ELE_ADR047	5176.02	\N
2022-02-01	LM_ELE_ADR049	14222.81	\N
2022-02-01	LM_ELE_ADR052	10706.11	\N
2022-02-01	LM_ELE_ADR054	29812.87	\N
2022-02-01	LM_ELE_ADR057	5904.71	\N
2022-02-01	LM_ELE_ADR060	0	\N
2022-02-01	LM_ELE_ADR061	0	\N
2022-02-01	LM_ELE_ADR062	20565	\N
2022-02-01	LM_ELE_ADR067	263	\N
2022-02-01	LM_ELE_ADR068	4985	\N
2022-02-01	LM_ELE_ADR070	88	\N
2022-02-01	LM_ELE_ADR071	75233	\N
2022-02-01	LM_ELE_ADR073	88	\N
2022-02-01	LM_ELE_ADR077	1063	\N
2022-02-01	LM_ELE_ADR084	53847.27	\N
2022-02-01	LM_ELE_ADR086	13821.6	\N
2022-02-01	LM_ELE_ADR088	36948.7	\N
2022-02-01	LM_ELE_ADR094	1462.52	\N
2022-02-01	LM_ELE_ADR095	97442.04	\N
2022-02-01	LM_ELE_ADR098	3400.38	\N
2022-02-01	LM_ELE_ADR099	76247.55	\N
2022-02-01	LM_ELE_ADR101	7398.1	\N
2022-02-01	LM_ELE_ADR111	362.57	\N
2022-02-01	LM_ELE_ADR116	15037.65	\N
2022-02-01	LM_ELE_ADR118	20349.74	\N
2022-02-01	LM_ELE_ADR119	72391.63	\N
2022-02-01	LM_ELE_ADR120	81033.69	\N
2022-02-01	LM_WOD_ADR129	112.4	\N
2022-02-01	LM_WOD_ADR140	122.18	\N
2022-02-01	LM_WOD_ADR147	58.49	\N
2022-02-01	LM_ELE_ADR_B03	124573.65	\N
2022-02-01	LM_ELE_ADR_B07	98367.93	\N
2022-02-01	LM_ELE_ADR_B08	146734.16	\N
2022-02-01	LM_LC_ADR_B26	145.93	\N
2022-02-01	LM_LC_ADR_B30	411.4	\N
2022-02-01	LM_LC_ADR_B32	913.5	\N
2022-02-01	LM_LC_ADR_B33	815.6	\N
2022-02-01	LM_LH_ADR_B19	100.4	\N
2022-02-01	LM_LH_ADR_B21	194.8	\N
2022-02-01	LM_LH_ADR_B34	0	\N
2022-02-01	LM_LH_ADR_B37	0.4	\N
2022-02-01	LM_LH_ADR_B39	95.9	\N
2022-02-01	LM_LH_ADR_B40	161.1	\N
2022-02-01	LM_LH_ADR_B42	0	\N
2022-02-01	LM_WOD_ADR_B78	185.42	\N
2022-02-01	LM_LC_ADR102	49.8	\N
2022-02-01	LM_LC_ADR103	54.9	\N
2022-02-01	LM_LC_ADR104	72.38	\N
2022-02-01	LM_LC_ADR152	4794.2	\N
2022-02-01	LM_LC_ADR149	0.91	\N
2022-02-01	LM_LC_ADR156	3338.1	\N
2022-02-01	LM_LC_ADR166	35.97	\N
2022-02-01	LM_LC_ADR180	140.15	\N
2022-02-01	LM_LC_ADR181	0.1	\N
2022-02-01	LM_LC_ADR182	86.42	\N
2022-02-01	LM_LC_ADR183	1.42	\N
2022-02-01	LM_LC_ADR185	18.94	\N
2022-02-01	LM_LC_ADR161	1382.2	\N
2022-02-01	LM_LC_ADR224	154.87	\N
2022-02-01	LM_LC_ADR89	34.48	\N
2022-02-01	LM_LC_ADR93	33.99	\N
2022-02-01	LM_LH_ADR145	10.07	\N
2022-02-01	LM_LH_ADR188	32.18	\N
2022-02-01	LM_LH_ADR190	7.89	\N
2022-02-01	LM_LH_ADR191	18.8	\N
2022-02-01	LM_LH_ADR207	404	\N
2022-02-01	LM_LH_ADR197	1255	\N
2022-02-01	LM_LH_ADR215	0	\N
2022-02-01	LM_LH_ADR219	0.03	\N
2022-02-01	LM_LH_ADR220	112.2	\N
2022-02-01	LM_LH_ADR226	74.26	\N
2022-02-01	LM_LH_ADR217	500.6	\N
2022-02-01	LM_LH_ADR228	28.8	\N
2022-02-01	LM_LH_ADR232	56.08	\N
2022-02-01	LM_LH_ADR233	45.1	\N
2022-02-01	LM_LH_ADR230	1.7	\N
2022-02-01	LM_ELE_ADR114	27.81	\N
2022-02-01	LM_ELE_ADR117	22575.19	\N
2022-02-01	LM_WOD_ADR132	295.06	\N
2022-02-01	LM_WOD_ADR134	18.68	\N
2022-02-01	LM_WOD_ADR135	0	\N
2021-11-01	LM_LC_ADR170	49.54	\N
2021-11-01	LM_LC_ADR172	94.94	\N
2021-11-01	LM_LC_ADR179	71.39	\N
2021-11-01	LM_ELE_ADR021	213901.73	\N
2021-11-01	LM_ELE_ADR078	44522	\N
2021-11-01	LM_ELE_ADR066	0	\N
2021-11-01	LM_ELE_ADR080	158258.48	\N
2021-11-01	LM_LH_ADR199	138.6	\N
2022-02-01	LM_ELE_ADR080	166806.13	\N
2022-02-01	LM_WOD_MAIN_W	0	\N
2022-02-01	LM_LC_ADR155	6635.4	\N
2022-02-01	LM_LH_ADR122	14.6	\N
2022-02-01	LM_LH_ADR222	0	\N
2022-02-01	LM_ELE_ADR065	0	\N
2022-02-01	LM_ELE_ADR100	16913.35	\N
2022-02-01	LM_WOD_ADR248_Solution Space	42.87	\N
2022-02-01	LM_LC_ADR165	45.27	\N
2022-02-01	LM_LH_ADR192	0	\N
2022-02-01	LM_LH_ADR223	176.6	\N
2022-02-01	LM_LH_ADR225	70.8	\N
2022-02-01	LM_WOD_ADR136	67.95	\N
2022-02-01	LM_WOD_ADR139	1373.72	\N
2022-02-01	LM_WOD_ADR141	17	\N
2022-02-01	LM_WOD_ADR142	36	\N
2022-02-01	LM_WOD_ADR143	557.39	\N
2022-02-01	LM_WOD_ADR146	29509.9	\N
2022-02-01	LM_WOD_ADR148	0.03	\N
2022-02-01	LM_WOD_ADR237	923.48	\N
2022-02-01	LM_WOD_ADR238	2339.71	\N
2022-02-01	LM_WOD_ADR239	32.58	\N
2022-02-01	LM_WOD_ADR240	123.18	\N
2022-02-01	LM_WOD_ADR241	75.02	\N
2022-02-01	LM_ELE_ADR121	175365.19	\N
2022-02-01	LM_ELE_ADR128	0	\N
2022-02-01	LM_WOD_ADR247_Solution Space	529.71	\N
2022-02-01	LM_WOD_ADR250_Solution Space	189.3	\N
2022-02-01	LM_WOD_ADR30	0	\N
2022-02-01	LM_ELE_ADR001	66007.05	\N
2022-02-01	LM_ELE_ADR002	86535.94	\N
2022-02-01	LM_ELE_ADR003	113987.09	\N
2022-02-01	LM_ELE_ADR006	74879.59	\N
2022-02-01	LM_ELE_ADR009	171144.14	\N
2022-02-01	LM_ELE_ADR011	159997.03	\N
2022-02-01	LM_ELE_ADR013	210673.16	\N
2022-02-01	LM_ELE_ADR014	13952.76	\N
2022-02-01	LM_ELE_ADR015	126920.1	\N
2022-02-01	LM_ELE_ADR016	923599.81	\N
2022-02-01	LM_ELE_ADR018	12752.73	\N
2022-02-01	LM_ELE_ADR020	132678.55	\N
2022-02-01	LM_ELE_ADR022	142617.03	\N
2022-02-01	LM_ELE_ADR023	31583.81	\N
2022-02-01	LM_ELE_ADR025	472703.31	\N
2022-02-01	LM_ELE_ADR028	18901.9	\N
2022-02-01	LM_ELE_ADR034	26667.94	\N
2022-02-01	LM_ELE_ADR036	87695.79	\N
2022-02-01	LM_ELE_ADR040	35362.11	\N
2022-02-01	LM_ELE_ADR042	3386.54	\N
2022-02-01	LM_ELE_ADR044	6584.33	\N
2022-02-01	LM_ELE_ADR048	6929.77	\N
2022-02-01	LM_ELE_ADR051	6629.05	\N
2022-02-01	LM_ELE_ADR053	20754.22	\N
2022-02-01	LM_ELE_ADR055	5466.68	\N
2022-02-01	LM_ELE_ADR056	21274.12	\N
2022-02-01	LM_ELE_ADR063	190	\N
2022-02-01	LM_ELE_ADR064	0	\N
2022-02-01	LM_ELE_ADR058	79819.27	\N
2022-02-01	LM_ELE_ADR072	25104	\N
2022-02-01	LM_ELE_ADR074	75233	\N
2022-02-01	LM_ELE_ADR076	0	\N
2022-02-01	LM_ELE_ADR085	51580.84	\N
2022-02-01	LM_ELE_ADR090	36665.89	\N
2022-02-01	LM_ELE_ADR107	80298.7	\N
2022-02-01	LM_ELE_ADR108	6415.71	\N
2022-02-01	LM_ELE_ADR109	2014.96	\N
2022-02-01	LM_ELE_ADR110	410.99	\N
2022-02-01	LM_ELE_ADR113	52000.55	\N
2022-02-01	LM_ELE_ADR087	86546.52	\N
2022-02-01	LM_LC_ADR_B45	195.43	\N
2022-02-01	LM_LH_ADR_B46	49.35	\N
2022-02-01	LM_LH_ADR_B47	116.9	\N
2022-02-01	LM_WOD_ADR_B74	33.72	\N
2022-02-01	LM_ELE_ADR_B06	443934.75	\N
2022-02-01	LM_ELE_ADR046	0	\N
2022-02-01	LM_ELE_ADR043	2712.82	\N
2022-02-01	LM_ELE_ADR_B11	31498.86	\N
2022-02-01	LM_WOD_ADR242	42.36	\N
2022-02-01	LM_ELE_ADR124	94003.3	\N
2022-02-01	LM_ELE_ADR112	712140.31	\N
2022-02-01	LM_WOD_ADR_B75	178.47	\N
2022-02-01	LM_ELE_ADR091	11382.49	\N
2022-02-01	LM_WOD_ADR_B80	115.74	\N
2022-02-01	LM_WOD_ADR_B81	41.97	\N
2022-02-01	LM_ELE_ADR_B04	277274.69	\N
2022-02-01	LM_ELE_ADR_B05	241527.45	\N
2022-02-01	LM_ELE_ADR_B09	287958.41	\N
2022-02-01	LM_ELE_ADR_B01	0	\N
2022-02-01	LM_ELE_ADR_B10	29013.71	\N
2022-02-01	LM_LC_ADR_B18	18	\N
2022-02-01	LM_LC_ADR_B20	69.09	\N
2022-02-01	LM_LC_ADR_B22	50.73	\N
2022-02-01	LM_LC_ADR_B24	10.02	\N
2022-02-01	LM_LC_ADR_B31	415.4	\N
2022-02-01	LM_LC_ADR_B41	474	\N
2022-02-01	LM_LC_ADR_B43	7.8	\N
2022-02-01	LM_LH_ADR_B23	64.3	\N
2022-02-01	LM_LH_ADR_B25	57.1	\N
2022-02-01	LM_LH_ADR_B27	134.9	\N
2022-02-01	LM_LH_ADR_B35	0	\N
2022-02-01	LM_LH_ADR_B36	0	\N
2022-02-01	LM_LH_ADR_B38	72	\N
2022-02-01	LM_LH_ADR_B44	4.5	\N
2022-02-01	LM_WOD_ADR_B77	8.96	\N
2022-02-01	LM_LC_ADR_B16	38.82	\N
2022-02-01	LM_LH_ADR_B17	49.7	\N
2022-02-01	LM_WOD_ADR_B79	360.11	\N
2022-02-01	LM_ELE_ADR_B12	17378.82	\N
2022-02-01	LM_ELE_ADR_B13	15053.19	\N
2022-02-01	LM_LC_ADR_B46	50.53	\N
2022-02-01	LM_LC_ADR193	0	\N
2022-02-01	LM_ELE_ADR125	4839.43	\N
2022-02-01	LM_ELE_ADR069	284569	\N
2022-02-01	LM_ELE_ADR075	10457	\N
2022-02-01	LM_LC_ADR159	4420	\N
2022-02-01	LM_LC_ADR160	7870	\N
2022-02-01	LM_LH_ADR167	1350	\N
2021-11-01	LM_ELE_ADR115	22939.2	\N
2021-11-01	LM_WOD_ADR249_Solution Space	85.74	\N
2021-11-01	LM_WOD_MAIN_W	0	\N
2021-11-01	LM_LC_ADR123	416.2	\N
2021-11-01	LM_LC_ADR151	26574	\N
2021-11-01	LM_LC_ADR153	9363	\N
2021-11-01	LM_LC_ADR154	2207.4	\N
2021-11-01	LM_LC_ADR155	5813.4	\N
2021-11-01	LM_LC_ADR157	940.3	\N
2021-11-01	LM_LC_ADR158	291.6	\N
2021-11-01	LM_LC_ADR162	668.5	\N
2021-11-01	LM_LC_ADR168	76.4	\N
2021-11-01	LM_LC_ADR173	83.2	\N
2021-11-01	LM_LC_ADR174	159.41	\N
2021-11-01	LM_LC_ADR175	0	\N
2021-11-01	LM_LC_ADR176	84.7	\N
2021-11-01	LM_LC_ADR178	103.23	\N
2021-11-01	LM_LC_ADR184	39.72	\N
2021-11-01	LM_LC_ADR186	15.54	\N
2021-11-01	LM_LC_ADR187	29.04	\N
2021-11-01	LM_LC_ADR209	85.34	\N
2021-11-01	LM_LC_ADR32	0	\N
2021-11-01	LM_LC_ADR82	3.76	\N
2021-11-01	LM_LH_ADR122	14.1	\N
2021-11-01	LM_LH_ADR189	56.45	\N
2021-11-01	LM_LH_ADR195	408.6	\N
2021-11-01	LM_LH_ADR196	9	\N
2021-11-01	LM_LH_ADR198	1147	\N
2021-11-01	LM_LH_ADR200	44.9	\N
2021-11-01	LM_LH_ADR203	215.1	\N
2021-11-01	LM_LH_ADR204	93.8	\N
2021-11-01	LM_LH_ADR208	271.8	\N
2021-11-01	LM_LH_ADR211	28.2	\N
2021-11-01	LM_LH_ADR212	144.7	\N
2021-11-01	LM_LH_ADR216	31.79	\N
2021-11-01	LM_LH_ADR218	384.5	\N
2021-11-01	LM_LH_ADR221	296.5	\N
2021-11-01	LM_LH_ADR222	0	\N
2021-11-01	LM_LH_ADR227	41.2	\N
2021-11-01	LM_LH_ADR229	84.82	\N
2021-11-01	LM_LH_ADR231	0	\N
2021-11-01	LM_LH_ADR234	0	\N
2021-11-01	LM_LH_ADR235	86.2	\N
2021-11-01	LM_LH_ADR33	0	\N
2021-11-01	LM_ELE_ADR008	84389.87	\N
2021-11-01	LM_ELE_ADR012	65753.73	\N
2021-11-01	LM_ELE_ADR017	11461.11	\N
2021-11-01	LM_ELE_ADR019	2439.53	\N
2021-11-01	LM_ELE_ADR024	114290.45	\N
2021-11-01	LM_ELE_ADR027	34534.44	\N
2021-11-01	LM_LC_ADR163	26.58	\N
2021-11-01	LM_LC_ADR164	0.02	\N
2021-11-01	LM_LH_ADR201	85.1	\N
2021-11-01	LM_ELE_ADR029	10848.29	\N
2021-11-01	LM_ELE_ADR031	155303.34	\N
2021-11-01	LM_ELE_ADR038	290953.88	\N
2021-11-01	LM_ELE_ADR041	59927.11	\N
2021-11-01	LM_ELE_ADR045	5418.25	\N
2021-11-01	LM_ELE_ADR047	4885.87	\N
2021-11-01	LM_ELE_ADR049	13586.14	\N
2021-11-01	LM_ELE_ADR052	10158.32	\N
2021-11-01	LM_ELE_ADR054	28384.81	\N
2021-11-01	LM_ELE_ADR057	5622.2	\N
2021-11-01	LM_ELE_ADR059	21204.06	\N
2021-11-01	LM_ELE_ADR060	0	\N
2021-11-01	LM_ELE_ADR061	0	\N
2021-11-01	LM_ELE_ADR062	18489	\N
2021-11-01	LM_ELE_ADR065	0	\N
2021-11-01	LM_ELE_ADR067	159	\N
2021-11-01	LM_ELE_ADR068	937	\N
2021-11-01	LM_ELE_ADR070	88	\N
2021-11-01	LM_ELE_ADR071	70367	\N
2021-11-01	LM_ELE_ADR073	88	\N
2021-11-01	LM_ELE_ADR077	1063	\N
2021-11-01	LM_ELE_ADR084	51441.46	\N
2021-11-01	LM_ELE_ADR086	12364.14	\N
2021-11-01	LM_ELE_ADR088	34059.27	\N
2021-11-01	LM_ELE_ADR094	1439.15	\N
2021-11-01	LM_ELE_ADR095	91050.13	\N
2021-11-01	LM_ELE_ADR097	26106.75	\N
2021-11-01	LM_ELE_ADR098	3118.36	\N
2021-11-01	LM_ELE_ADR099	66215.56	\N
2021-11-01	LM_ELE_ADR100	14952.33	\N
2021-11-01	LM_ELE_ADR101	6798.02	\N
2021-11-01	LM_ELE_ADR111	362.57	\N
2021-11-01	LM_ELE_ADR116	13736.22	\N
2021-11-01	LM_ELE_ADR118	19120.28	\N
2021-11-01	LM_ELE_ADR119	68396.63	\N
2021-11-01	LM_ELE_ADR120	72856.38	\N
2021-11-01	LM_WOD_ADR129	102.7	\N
2021-11-01	LM_WOD_ADR140	121.4	\N
2021-11-01	LM_WOD_ADR147	55.13	\N
2021-11-01	LM_WOD_ADR246_Solution Space	475.32	\N
2021-11-01	LM_WOD_ADR248_Solution Space	36.83	\N
2021-11-01	LM_ELE_ADR_B03	118130.75	\N
2021-11-01	LM_ELE_ADR_B07	92810.26	\N
2021-11-01	LM_ELE_ADR_B08	138671.16	\N
2021-11-01	LM_LC_ADR_B26	108.28	\N
2021-11-01	LM_LC_ADR_B30	356	\N
2021-11-01	LM_LC_ADR_B32	784.2	\N
2021-11-01	LM_LC_ADR_B33	675.7	\N
2021-11-01	LM_LH_ADR_B19	81.1	\N
2021-11-01	LM_LH_ADR_B21	171.9	\N
2021-11-01	LM_LH_ADR_B34	0	\N
2021-11-01	LM_LH_ADR_B37	0.4	\N
2021-11-01	LM_LH_ADR_B39	95.4	\N
2021-11-01	LM_LH_ADR_B40	159.2	\N
2021-11-01	LM_LH_ADR_B42	0	\N
2021-11-01	LM_WOD_ADR_B78	179.52	\N
2021-11-01	LM_LC_ADR102	43.49	\N
2021-11-01	LM_LC_ADR103	47.71	\N
2021-11-01	LM_LC_ADR104	59.66	\N
2021-11-01	LM_LC_ADR152	4320.8	\N
2021-11-01	LM_LC_ADR149	0.91	\N
2021-11-01	LM_LC_ADR156	2861.5	\N
2021-11-01	LM_LC_ADR171	245.03	\N
2021-11-01	LM_LC_ADR165	38.66	\N
2021-11-01	LM_LC_ADR166	31	\N
2021-11-01	LM_LC_ADR180	127	\N
2021-11-01	LM_LC_ADR181	0.1	\N
2021-11-01	LM_LC_ADR182	74.34	\N
2021-11-01	LM_LC_ADR183	1.42	\N
2021-11-01	LM_LC_ADR185	16.13	\N
2021-11-01	LM_LC_ADR161	1244.2	\N
2021-11-01	LM_LC_ADR224	132.55	\N
2021-11-01	LM_LC_ADR89	28.41	\N
2021-11-01	LM_LC_ADR93	27.91	\N
2021-11-01	LM_LH_ADR145	9.8	\N
2021-11-01	LM_LH_ADR188	32.18	\N
2021-11-01	LM_LH_ADR190	7.79	\N
2021-11-01	LM_LH_ADR191	18.8	\N
2021-11-01	LM_LH_ADR192	0	\N
2021-11-01	LM_LH_ADR194	786.5	\N
2021-11-01	LM_LH_ADR207	392.8	\N
2021-11-01	LM_LH_ADR197	1232.7	\N
2021-11-01	LM_LH_ADR215	0	\N
2021-11-01	LM_LH_ADR219	0.03	\N
2021-11-01	LM_LH_ADR220	71.98	\N
2021-11-01	LM_LH_ADR223	176.6	\N
2021-11-01	LM_LH_ADR225	70.4	\N
2021-11-01	LM_LH_ADR226	54.04	\N
2021-11-01	LM_LH_ADR217	486.2	\N
2021-11-01	LM_LH_ADR228	27.8	\N
2021-11-01	LM_LH_ADR232	52.1	\N
2021-11-01	LM_LH_ADR233	45.1	\N
2021-11-01	LM_LH_ADR230	1.6	\N
2021-11-01	LM_ELE_ADR114	241310.66	\N
2021-11-01	LM_ELE_ADR117	22082.3	\N
2021-11-01	LM_WOD_ADR132	284.9	\N
2021-11-01	LM_WOD_ADR133	334.73	\N
2021-11-01	LM_WOD_ADR134	18.32	\N
2021-11-01	LM_WOD_ADR135	0	\N
2021-11-01	LM_WOD_ADR136	65.37	\N
2021-11-01	LM_WOD_ADR139	1270.98	\N
2021-11-01	LM_WOD_ADR141	17	\N
2021-11-01	LM_WOD_ADR142	36	\N
2021-11-01	LM_WOD_ADR143	557.39	\N
2021-11-01	LM_WOD_ADR146	28035.4	\N
2021-11-01	LM_WOD_ADR148	0.05	\N
2021-11-01	LM_WOD_ADR150	36.78	\N
2021-11-01	LM_WOD_ADR237	922.81	\N
2021-11-01	LM_WOD_ADR238	2212.76	\N
2021-11-01	LM_WOD_ADR239	29.33	\N
2021-11-01	LM_WOD_ADR240	110.02	\N
2021-11-01	LM_WOD_ADR241	995.57	\N
2021-11-01	LM_ELE_ADR121	85.44	\N
2021-11-01	LM_ELE_ADR128	0	\N
2021-11-01	LM_WOD_ADR247_Solution Space	467.93	\N
2021-11-01	LM_WOD_ADR250_Solution Space	168.58	\N
2021-11-01	LM_WOD_ADR30	0	\N
2021-11-01	LM_ELE_ADR001	62406.46	\N
2021-11-01	LM_ELE_ADR002	82267.13	\N
2021-11-01	LM_ELE_ADR003	100545.7	\N
2021-11-01	LM_ELE_ADR006	72619.51	\N
2021-11-01	LM_ELE_ADR007	118932.88	\N
2021-11-01	LM_ELE_ADR009	159571.61	\N
2021-11-01	LM_ELE_ADR011	156200.34	\N
2021-11-01	LM_ELE_ADR013	197507.05	\N
2021-11-01	LM_ELE_ADR014	12937.41	\N
2021-11-01	LM_ELE_ADR015	118610.77	\N
2021-11-01	LM_ELE_ADR016	892473.13	\N
2021-11-01	LM_ELE_ADR018	12046.4	\N
2021-11-01	LM_ELE_ADR020	124256.97	\N
2021-11-01	LM_ELE_ADR022	124642.66	\N
2021-11-01	LM_ELE_ADR023	28479.32	\N
2021-11-01	LM_ELE_ADR025	381943.75	\N
2021-11-01	LM_ELE_ADR028	17755.81	\N
2021-11-01	LM_ELE_ADR034	23374.37	\N
2021-11-01	LM_ELE_ADR036	81774.63	\N
2021-11-01	LM_ELE_ADR039	301225.47	\N
2021-11-01	LM_ELE_ADR040	29531	\N
2021-11-01	LM_ELE_ADR042	3207.42	\N
2021-11-01	LM_ELE_ADR044	6292.31	\N
2021-11-01	LM_ELE_ADR048	6612.93	\N
2021-11-01	LM_ELE_ADR051	6299.91	\N
2021-11-01	LM_ELE_ADR053	17590.96	\N
2021-11-01	LM_ELE_ADR055	5191.88	\N
2021-11-01	LM_ELE_ADR056	20173.27	\N
2021-11-01	LM_ELE_ADR063	189	\N
2021-11-01	LM_ELE_ADR064	0	\N
2021-11-01	LM_ELE_ADR058	75657.16	\N
2021-11-01	LM_ELE_ADR072	23013	\N
2021-11-01	LM_ELE_ADR074	70367	\N
2021-11-01	LM_ELE_ADR076	0	\N
2021-11-01	LM_ELE_ADR081	42130.11	\N
2021-11-01	LM_ELE_ADR085	44662.06	\N
2021-11-01	LM_ELE_ADR090	34610.97	\N
2021-11-01	LM_ELE_ADR107	72506.31	\N
2021-11-01	LM_ELE_ADR108	6208.57	\N
2021-11-01	LM_ELE_ADR109	2013.65	\N
2021-11-01	LM_ELE_ADR110	406.22	\N
2021-11-01	LM_ELE_ADR113	48651.14	\N
2021-11-01	LM_ELE_ADR087	82530.24	\N
2021-11-01	LM_LC_ADR_B45	151.41	\N
2021-11-01	LM_LH_ADR_B46	49.35	\N
2021-11-01	LM_LH_ADR_B47	116.3	\N
2021-11-01	LM_WOD_ADR_B74	30.84	\N
2021-11-01	LM_ELE_ADR_B06	416481.91	\N
2021-11-01	LM_ELE_ADR046	0	\N
2021-11-01	LM_ELE_ADR010	108857.47	\N
2021-11-01	LM_ELE_ADR043	2557.22	\N
2021-11-01	LM_ELE_ADR_B11	29399.33	\N
2021-11-01	LM_WOD_ADR242	41.67	\N
2021-11-01	LM_ELE_ADR124	77755.88	\N
2021-11-01	LM_ELE_ADR112	693226.56	\N
2021-11-01	LM_WOD_ADR_B75	153.17	\N
2021-11-01	LM_ELE_ADR091	10344.79	\N
2021-11-01	LM_WOD_ADR_B80	104.82	\N
2021-11-01	LM_WOD_ADR_B81	39.84	\N
2021-11-01	LM_ELE_ADR_B04	272130.16	\N
2021-11-01	LM_ELE_ADR_B05	235930.5	\N
2021-11-01	LM_ELE_ADR_B09	272122.81	\N
2021-11-01	LM_ELE_ADR_B01	0	\N
2021-11-01	LM_ELE_ADR_B10	27224.63	\N
2021-11-01	LM_ELE_ADR_B02	0	\N
2021-11-01	LM_LC_ADR_B18	15.22	\N
2021-11-01	LM_LC_ADR_B20	58.98	\N
2021-11-01	LM_LC_ADR_B22	31.31	\N
2021-11-01	LM_LC_ADR_B24	10.02	\N
2021-11-01	LM_LC_ADR_B31	357.1	\N
2021-11-01	LM_LC_ADR_B41	396.2	\N
2021-11-01	LM_LC_ADR_B43	6.7	\N
2021-11-01	LM_LH_ADR_B23	64.1	\N
2021-11-01	LM_LH_ADR_B25	49.6	\N
2021-11-01	LM_LH_ADR_B27	117	\N
2021-11-01	LM_LH_ADR_B35	0	\N
2021-11-01	LM_LH_ADR_B36	0	\N
2021-11-01	LM_LH_ADR_B38	71.7	\N
2021-11-01	LM_LH_ADR_B44	4.3	\N
2021-11-01	LM_WOD_ADR_B76	1736.79	\N
2021-11-01	LM_WOD_ADR_B77	8.96	\N
2021-11-01	LM_LC_ADR_B16	32.5	\N
2021-11-01	LM_LH_ADR_B17	47.4	\N
2021-11-01	LM_WOD_ADR_B79	360.11	\N
2021-11-01	LM_ELE_ADR_B12	15764.47	\N
2021-11-01	LM_ELE_ADR_B13	14656.99	\N
2021-11-01	LM_LC_ADR_B46	45.09	\N
2021-11-01	LM_LC_ADR193	0	\N
2021-11-01	LM_ELE_ADR125	4633.62	\N
2021-11-01	LM_ELE_ADR069	264405	\N
2021-11-01	LM_ELE_ADR075	88	\N
2021-12-01	LM_LC_ADR170	50.01	\N
2021-12-01	LM_LC_ADR172	98.28	\N
2021-12-01	LM_LC_ADR179	74.86	\N
2021-12-01	LM_ELE_ADR021	221886.38	\N
2021-12-01	LM_ELE_ADR078	46879	\N
2021-12-01	LM_ELE_ADR066	0	\N
2021-12-01	LM_ELE_ADR080	161290.13	\N
2021-12-01	LM_LH_ADR199	139.6	\N
2021-12-01	LM_ELE_ADR115	23010.26	\N
2021-12-01	LM_WOD_ADR249_Solution Space	89.88	\N
2021-12-01	LM_WOD_MAIN_W	0	\N
2021-12-01	LM_LC_ADR123	445	\N
2021-12-01	LM_LC_ADR151	27145.998	\N
2021-12-01	LM_LC_ADR153	9492	\N
2021-12-01	LM_LC_ADR154	2283.5	\N
2021-12-01	LM_LC_ADR155	6001.2	\N
2021-12-01	LM_LC_ADR157	963.8	\N
2021-12-01	LM_LC_ADR158	301.6	\N
2021-12-01	LM_LC_ADR162	687.7	\N
2021-12-01	LM_LC_ADR168	84.3	\N
2021-12-01	LM_LC_ADR173	86.01	\N
2021-12-01	LM_LC_ADR174	168.36	\N
2021-12-01	LM_LC_ADR175	0	\N
2021-12-01	LM_LC_ADR176	84.7	\N
2021-12-01	LM_LC_ADR178	108.98	\N
2021-12-01	LM_LC_ADR184	40.56	\N
2021-12-01	LM_LC_ADR186	16.93	\N
2021-12-01	LM_LC_ADR187	29.04	\N
2021-12-01	LM_LC_ADR209	86.55	\N
2021-12-01	LM_LC_ADR32	0	\N
2021-12-01	LM_LC_ADR82	7.63	\N
2021-12-01	LM_LH_ADR122	14.5	\N
2021-12-01	LM_LH_ADR189	57.14	\N
2021-12-01	LM_LH_ADR195	408.7	\N
2021-12-01	LM_LH_ADR196	9	\N
2021-12-01	LM_LH_ADR198	1162.7	\N
2021-12-01	LM_LH_ADR200	45.3	\N
2021-12-01	LM_LH_ADR203	217	\N
2021-12-01	LM_LH_ADR204	94.7	\N
2021-12-01	LM_LH_ADR208	285.4	\N
2021-12-01	LM_LH_ADR211	30.1	\N
2021-12-01	LM_LH_ADR212	153.8	\N
2021-12-01	LM_LH_ADR216	32.53	\N
2021-12-01	LM_LH_ADR218	390.4	\N
2021-12-01	LM_LH_ADR221	305.7	\N
2021-12-01	LM_LH_ADR222	0	\N
2021-12-01	LM_LH_ADR227	41.2	\N
2021-12-01	LM_LH_ADR229	84.82	\N
2021-12-01	LM_LH_ADR231	0	\N
2021-12-01	LM_LH_ADR234	0	\N
2021-12-01	LM_LH_ADR235	86.2	\N
2021-12-01	LM_LH_ADR33	0	\N
2021-12-01	LM_ELE_ADR008	87657.12	\N
2021-12-01	LM_ELE_ADR012	68968.79	\N
2021-12-01	LM_ELE_ADR017	11719.38	\N
2021-12-01	LM_ELE_ADR019	2439.53	\N
2021-12-01	LM_ELE_ADR024	116178.59	\N
2021-12-01	LM_ELE_ADR027	34825.37	\N
2021-12-01	LM_LC_ADR163	27.61	\N
2021-12-01	LM_LC_ADR164	0.02	\N
2021-12-01	LM_LH_ADR201	86.9	\N
2021-12-01	LM_ELE_ADR029	11311.51	\N
2021-12-01	LM_ELE_ADR031	174115.2	\N
2021-12-01	LM_ELE_ADR038	304032.09	\N
2021-12-01	LM_ELE_ADR041	61263.04	\N
2021-12-01	LM_ELE_ADR045	5523.23	\N
2021-12-01	LM_ELE_ADR047	4983.1	\N
2021-12-01	LM_ELE_ADR049	13793.91	\N
2021-12-01	LM_ELE_ADR052	10335.3	\N
2021-12-01	LM_ELE_ADR054	28842.25	\N
2021-12-01	LM_ELE_ADR057	5723.59	\N
2021-12-01	LM_ELE_ADR059	21649.59	\N
2021-12-01	LM_ELE_ADR060	0	\N
2021-12-01	LM_ELE_ADR061	0	\N
2021-12-01	LM_ELE_ADR062	19120	\N
2021-12-01	LM_ELE_ADR065	0	\N
2021-12-01	LM_ELE_ADR067	189	\N
2021-12-01	LM_ELE_ADR068	1605	\N
2021-12-01	LM_ELE_ADR070	88	\N
2021-12-01	LM_ELE_ADR071	71956	\N
2021-12-01	LM_ELE_ADR073	88	\N
2021-12-01	LM_ELE_ADR077	1063	\N
2021-12-01	LM_ELE_ADR084	52398.76	\N
2021-12-01	LM_ELE_ADR086	12826.31	\N
2021-12-01	LM_ELE_ADR088	35020.33	\N
2021-12-01	LM_ELE_ADR094	1445.03	\N
2021-12-01	LM_ELE_ADR095	93095.74	\N
2021-12-01	LM_ELE_ADR097	27063.03	\N
2021-12-01	LM_ELE_ADR098	3307.74	\N
2021-12-01	LM_ELE_ADR099	69555.8	\N
2021-12-01	LM_ELE_ADR100	15682.85	\N
2021-12-01	LM_ELE_ADR101	6991.29	\N
2021-12-01	LM_ELE_ADR111	362.57	\N
2021-12-01	LM_ELE_ADR116	14916.2	\N
2021-12-01	LM_ELE_ADR118	19546.53	\N
2021-12-01	LM_ELE_ADR119	69677.38	\N
2021-12-01	LM_ELE_ADR120	73410.26	\N
2021-12-01	LM_WOD_ADR129	106.16	\N
2021-12-01	LM_WOD_ADR140	121.75	\N
2021-12-01	LM_WOD_ADR147	56.27	\N
2021-12-01	LM_WOD_ADR246_Solution Space	489.39	\N
2021-12-01	LM_WOD_ADR248_Solution Space	39.01	\N
2021-12-01	LM_ELE_ADR_B03	120211.43	\N
2021-12-01	LM_ELE_ADR_B07	94537.42	\N
2021-12-01	LM_ELE_ADR_B08	141309.81	\N
2021-12-01	LM_LC_ADR_B26	113.46	\N
2021-12-01	LM_LC_ADR_B30	368.3	\N
2021-12-01	LM_LC_ADR_B32	813	\N
2021-12-01	LM_LC_ADR_B33	710.5	\N
2021-12-01	LM_LH_ADR_B19	85.1	\N
2021-12-01	LM_LH_ADR_B21	177.2	\N
2021-12-01	LM_LH_ADR_B34	0	\N
2021-12-01	LM_LH_ADR_B37	0.4	\N
2021-12-01	LM_LH_ADR_B39	95.5	\N
2021-12-01	LM_LH_ADR_B40	159.8	\N
2021-12-01	LM_LH_ADR_B42	0	\N
2021-12-01	LM_WOD_ADR_B78	181.86	\N
2021-12-01	LM_LC_ADR102	45.28	\N
2021-12-01	LM_LC_ADR103	49.7	\N
2021-12-01	LM_LC_ADR104	63.27	\N
2021-12-01	LM_LC_ADR152	4411.5	\N
2021-12-01	LM_LC_ADR149	0.91	\N
2021-12-01	LM_LC_ADR156	2964.8	\N
2021-12-01	LM_LC_ADR171	249.2	\N
2021-12-01	LM_LC_ADR165	40.56	\N
2021-12-01	LM_LC_ADR166	32.41	\N
2021-12-01	LM_LC_ADR180	129.57	\N
2021-12-01	LM_LC_ADR181	0.1	\N
2021-12-01	LM_LC_ADR182	76.94	\N
2021-12-01	LM_LC_ADR183	1.42	\N
2021-12-01	LM_LC_ADR185	16.62	\N
2021-12-01	LM_LC_ADR161	1277	\N
2021-12-01	LM_LC_ADR224	138.52	\N
2021-12-01	LM_LC_ADR89	30.09	\N
2021-12-01	LM_LC_ADR93	29.61	\N
2021-12-01	LM_LH_ADR145	9.8	\N
2021-12-01	LM_LH_ADR188	32.18	\N
2021-12-01	LM_LH_ADR190	7.79	\N
2021-12-01	LM_LH_ADR191	18.8	\N
2021-12-01	LM_LH_ADR192	0	\N
2021-12-01	LM_LH_ADR194	795.2	\N
2021-12-01	LM_LH_ADR207	395.2	\N
2021-12-01	LM_LH_ADR197	1239.7	\N
2021-12-01	LM_LH_ADR215	0	\N
2021-12-01	LM_LH_ADR219	0.03	\N
2021-12-01	LM_LH_ADR220	71.98	\N
2021-12-01	LM_LH_ADR223	176.6	\N
2021-12-01	LM_LH_ADR225	70.4	\N
2021-12-01	LM_LH_ADR226	58.18	\N
2021-12-01	LM_LH_ADR217	489.7	\N
2021-12-01	LM_LH_ADR228	28.8	\N
2021-12-01	LM_LH_ADR232	53.25	\N
2021-12-01	LM_LH_ADR233	45.1	\N
2021-12-01	LM_LH_ADR230	1.7	\N
2021-12-01	LM_ELE_ADR114	247634.91	\N
2021-12-01	LM_ELE_ADR117	22371.36	\N
2021-12-01	LM_WOD_ADR132	290.1	\N
2021-12-01	LM_WOD_ADR133	337.75	\N
2021-12-01	LM_WOD_ADR134	18.55	\N
2021-12-01	LM_WOD_ADR135	0	\N
2021-12-01	LM_WOD_ADR136	66.16	\N
2021-12-01	LM_WOD_ADR139	1305.86	\N
2021-12-01	LM_WOD_ADR141	17	\N
2021-12-01	LM_WOD_ADR142	36	\N
2021-12-01	LM_WOD_ADR143	557.39	\N
2021-12-01	LM_WOD_ADR146	28433.8	\N
2021-12-01	LM_WOD_ADR148	0.05	\N
2021-12-01	LM_WOD_ADR150	37.82	\N
2021-12-01	LM_WOD_ADR237	923.16	\N
2021-12-01	LM_WOD_ADR238	2217.83	\N
2021-12-01	LM_WOD_ADR239	30.43	\N
2021-12-01	LM_WOD_ADR240	114.89	\N
2021-12-01	LM_WOD_ADR241	21.66	\N
2021-12-01	LM_ELE_ADR121	160482.23	\N
2021-12-01	LM_ELE_ADR128	0	\N
2021-12-01	LM_WOD_ADR247_Solution Space	484.18	\N
2021-12-01	LM_WOD_ADR250_Solution Space	176.16	\N
2021-12-01	LM_WOD_ADR30	0	\N
2021-12-01	LM_ELE_ADR001	62817.65	\N
2021-12-01	LM_ELE_ADR002	83687.92	\N
2021-12-01	LM_ELE_ADR003	104475.01	\N
2021-12-01	LM_ELE_ADR006	73468.91	\N
2021-12-01	LM_ELE_ADR007	122108.38	\N
2021-12-01	LM_ELE_ADR009	161795.31	\N
2021-12-01	LM_ELE_ADR011	157710.08	\N
2021-12-01	LM_ELE_ADR013	200293.13	\N
2021-12-01	LM_ELE_ADR014	13264.14	\N
2021-12-01	LM_ELE_ADR015	121732.38	\N
2021-12-01	LM_ELE_ADR016	906453	\N
2021-12-01	LM_ELE_ADR018	12278.52	\N
2021-12-01	LM_ELE_ADR020	126629.52	\N
2021-12-01	LM_ELE_ADR022	130675.54	\N
2021-12-01	LM_ELE_ADR023	29456.91	\N
2021-12-01	LM_ELE_ADR025	404558.78	\N
2021-12-01	LM_ELE_ADR028	17925.33	\N
2021-12-01	LM_ELE_ADR034	0	\N
2021-12-01	LM_ELE_ADR036	83523.47	\N
2021-12-01	LM_ELE_ADR039	312062.59	\N
2021-12-01	LM_ELE_ADR040	30078.59	\N
2021-12-01	LM_ELE_ADR042	3266.06	\N
2021-12-01	LM_ELE_ADR044	6393.12	\N
2021-12-01	LM_ELE_ADR048	6726.06	\N
2021-12-01	LM_ELE_ADR051	6406.67	\N
2021-12-01	LM_ELE_ADR053	17972.91	\N
2021-12-01	LM_ELE_ADR055	5281.78	\N
2021-12-01	LM_ELE_ADR056	20527.41	\N
2021-12-01	LM_ELE_ADR063	190	\N
2021-12-01	LM_ELE_ADR064	0	\N
2021-12-01	LM_ELE_ADR058	77006.38	\N
2021-12-01	LM_ELE_ADR072	23652	\N
2021-12-01	LM_ELE_ADR074	71956	\N
2021-12-01	LM_ELE_ADR076	0	\N
2021-12-01	LM_ELE_ADR081	43258.4	\N
2021-12-01	LM_ELE_ADR085	46950.37	\N
2021-12-01	LM_ELE_ADR090	35266.67	\N
2021-12-01	LM_ELE_ADR107	75135.8	\N
2021-12-01	LM_ELE_ADR108	6263.11	\N
2021-12-01	LM_ELE_ADR109	2014.39	\N
2021-12-01	LM_ELE_ADR110	407.04	\N
2021-12-01	LM_ELE_ADR113	49715.89	\N
2021-12-01	LM_ELE_ADR087	83817.7	\N
2021-12-01	LM_LC_ADR_B45	158.78	\N
2021-12-01	LM_LH_ADR_B46	49.35	\N
2021-12-01	LM_LH_ADR_B47	116.6	\N
2021-12-01	LM_WOD_ADR_B74	31.8	\N
2021-12-01	LM_ELE_ADR_B06	425251.5	\N
2021-12-01	LM_ELE_ADR046	0	\N
2021-12-01	LM_ELE_ADR010	111399.96	\N
2021-12-01	LM_ELE_ADR043	2607.36	\N
2021-12-01	LM_ELE_ADR_B11	29981.4	\N
2021-12-01	LM_WOD_ADR242	41.8	\N
2021-12-01	LM_ELE_ADR124	82924.04	\N
2021-12-01	LM_ELE_ADR112	702843.56	\N
2021-12-01	LM_WOD_ADR_B75	161.94	\N
2021-12-01	LM_ELE_ADR091	10684.79	\N
2021-12-01	LM_WOD_ADR_B80	108.3	\N
2021-12-01	LM_WOD_ADR_B81	40.57	\N
2021-12-01	LM_ELE_ADR_B04	274142.25	\N
2021-12-01	LM_ELE_ADR_B05	237516.69	\N
2021-12-01	LM_ELE_ADR_B09	277900.25	\N
2021-12-01	LM_ELE_ADR_B01	0	\N
2021-12-01	LM_ELE_ADR_B10	27797.94	\N
2021-12-01	LM_ELE_ADR_B02	0	\N
2021-12-01	LM_LC_ADR_B18	16.12	\N
2021-12-01	LM_LC_ADR_B20	62.24	\N
2021-12-01	LM_LC_ADR_B22	35.95	\N
2021-12-01	LM_LC_ADR_B24	10.02	\N
2021-12-01	LM_LC_ADR_B31	367.3	\N
2021-12-01	LM_LC_ADR_B41	415.5	\N
2021-12-01	LM_LC_ADR_B43	7	\N
2021-12-01	LM_LH_ADR_B23	64.1	\N
2021-12-01	LM_LH_ADR_B25	49.9	\N
2021-12-01	LM_LH_ADR_B27	123.1	\N
2021-12-01	LM_LH_ADR_B35	0	\N
2021-12-01	LM_LH_ADR_B36	0	\N
2021-12-01	LM_LH_ADR_B38	71.8	\N
2021-12-01	LM_LH_ADR_B44	4.5	\N
2021-12-01	LM_WOD_ADR_B76	1736.79	\N
2021-12-01	LM_WOD_ADR_B77	8.96	\N
2021-12-01	LM_LC_ADR_B16	34.75	\N
2021-12-01	LM_LH_ADR_B17	48.3	\N
2021-12-01	LM_WOD_ADR_B79	360.11	\N
2021-12-01	LM_ELE_ADR_B12	16269.72	\N
2021-12-01	LM_ELE_ADR_B13	15053.19	\N
2021-12-01	LM_LC_ADR_B46	45.14	\N
2021-12-01	LM_LC_ADR193	0	\N
2021-12-01	LM_ELE_ADR125	4717.58	\N
2021-12-01	LM_ELE_ADR069	269329	\N
2021-12-01	LM_ELE_ADR075	9989	\N
2021-12-01	LM_LC_ADR159	1290	\N
2021-12-01	LM_LC_ADR160	3490	\N
2021-12-01	LM_LH_ADR167	450	\N
2021-12-01	LM_WOD_ADR236	1.97	\N
2022-01-01	LM_LC_ADR170	51.84	\N
2022-01-01	LM_LC_ADR172	108.63	\N
2022-01-01	LM_LC_ADR179	79.35	\N
2022-01-01	LM_ELE_ADR021	236525.53	\N
2022-01-01	LM_ELE_ADR078	49498	\N
2022-01-01	LM_ELE_ADR066	0	\N
2022-01-01	LM_ELE_ADR080	163986.41	\N
2022-01-01	LM_LH_ADR199	141.4	\N
2022-01-01	LM_ELE_ADR115	23772.85	\N
2022-01-01	LM_WOD_ADR249_Solution Space	93.71	\N
2022-01-01	LM_WOD_MAIN_W	0	\N
2022-01-01	LM_LC_ADR123	474	\N
2022-01-01	LM_LC_ADR151	28209	\N
2022-01-01	LM_LC_ADR153	9785	\N
2022-01-01	LM_LC_ADR154	2378.7	\N
2022-01-01	LM_LC_ADR155	6315.9	\N
2022-01-01	LM_LC_ADR157	1003.5	\N
2022-01-01	LM_LC_ADR158	320.2	\N
2022-01-01	LM_LC_ADR162	722.6	\N
2022-01-01	LM_LC_ADR168	93.8	\N
2022-01-01	LM_LC_ADR173	91.25	\N
2022-01-01	LM_LC_ADR174	176.56	\N
2022-01-01	LM_LC_ADR175	0	\N
2022-01-01	LM_LC_ADR176	84.7	\N
2022-01-01	LM_LC_ADR178	116.42	\N
2022-01-01	LM_LC_ADR184	41.71	\N
2022-01-01	LM_LC_ADR186	19.23	\N
2022-01-01	LM_LC_ADR187	32.51	\N
2022-01-01	LM_LC_ADR209	86.55	\N
2022-01-01	LM_LC_ADR32	0	\N
2022-01-01	LM_LC_ADR82	12.48	\N
2022-01-01	LM_LH_ADR122	14.5	\N
2022-01-01	LM_LH_ADR189	57.73	\N
2022-01-01	LM_LH_ADR195	414.4	\N
2022-01-01	LM_LH_ADR196	9	\N
2022-01-01	LM_LH_ADR198	1179.4	\N
2022-01-01	LM_LH_ADR200	45.8	\N
2022-01-01	LM_LH_ADR203	218.2	\N
2022-01-01	LM_LH_ADR204	95.6	\N
2022-01-01	LM_LH_ADR208	292.7	\N
2022-01-01	LM_LH_ADR211	32	\N
2022-01-01	LM_LH_ADR212	162.3	\N
2022-01-01	LM_LH_ADR216	32.53	\N
2022-01-01	LM_LH_ADR218	400.5	\N
2022-01-01	LM_LH_ADR221	312.5	\N
2022-01-01	LM_LH_ADR222	0	\N
2022-01-01	LM_LH_ADR227	41.2	\N
2022-01-01	LM_LH_ADR229	84.82	\N
2022-01-01	LM_LH_ADR231	0	\N
2022-01-01	LM_LH_ADR234	0	\N
2022-01-01	LM_LH_ADR235	86.4	\N
2022-01-01	LM_LH_ADR33	0	\N
2022-01-01	LM_ELE_ADR008	92839.15	\N
2022-01-01	LM_ELE_ADR012	77785.52	\N
2022-01-01	LM_ELE_ADR017	11969.04	\N
2022-01-01	LM_ELE_ADR019	2568.88	\N
2022-01-01	LM_ELE_ADR024	118400.54	\N
2022-01-01	LM_ELE_ADR027	35094.67	\N
2022-01-01	LM_LC_ADR163	29	\N
2022-01-01	LM_LC_ADR164	0.02	\N
2022-01-01	LM_LH_ADR201	87.9	\N
2022-01-01	LM_ELE_ADR029	11808.99	\N
2022-01-01	LM_ELE_ADR031	177510.55	\N
2022-01-01	LM_ELE_ADR038	319410.91	\N
2022-01-01	LM_ELE_ADR041	62763.87	\N
2022-01-01	LM_ELE_ADR045	5622.15	\N
2022-01-01	LM_ELE_ADR047	5075.38	\N
2022-01-01	LM_ELE_ADR049	13993.98	\N
2022-01-01	LM_ELE_ADR052	10508.33	\N
2022-01-01	LM_ELE_ADR054	29301.04	\N
2022-01-01	LM_ELE_ADR057	5817.09	\N
2022-01-01	LM_ELE_ADR059	22110.31	\N
2022-01-01	LM_ELE_ADR060	0	\N
2022-01-01	LM_ELE_ADR061	0	\N
2022-01-01	LM_ELE_ADR062	19766	\N
2022-01-01	LM_ELE_ADR065	0	\N
2022-01-01	LM_ELE_ADR067	262	\N
2022-01-01	LM_ELE_ADR068	3284	\N
2022-01-01	LM_ELE_ADR070	88	\N
2022-01-01	LM_ELE_ADR071	73505	\N
2022-01-01	LM_ELE_ADR073	88	\N
2022-01-01	LM_ELE_ADR077	1063	\N
2022-01-01	LM_ELE_ADR084	53243.11	\N
2022-01-01	LM_ELE_ADR086	13280.89	\N
2022-01-01	LM_ELE_ADR088	35881.03	\N
2022-01-01	LM_ELE_ADR094	1453.44	\N
2022-01-01	LM_ELE_ADR095	95113.39	\N
2022-01-01	LM_ELE_ADR097	28016.34	\N
2022-01-01	LM_ELE_ADR098	3356.22	\N
2022-01-01	LM_ELE_ADR099	72670.2	\N
2022-01-01	LM_ELE_ADR100	16213.03	\N
2022-01-01	LM_ELE_ADR101	7179.73	\N
2022-01-01	LM_ELE_ADR111	362.57	\N
2022-01-01	LM_ELE_ADR116	15001.36	\N
2022-01-01	LM_ELE_ADR118	19930.98	\N
2022-01-01	LM_ELE_ADR119	70936.2	\N
2022-01-01	LM_ELE_ADR120	76621.32	\N
2022-01-01	LM_WOD_ADR129	109.4	\N
2022-01-01	LM_WOD_ADR140	121.97	\N
2022-01-01	LM_WOD_ADR147	57.36	\N
2022-01-01	LM_WOD_ADR246_Solution Space	502.53	\N
2022-01-01	LM_WOD_ADR248_Solution Space	41.04	\N
2022-01-01	LM_ELE_ADR_B03	122213.41	\N
2022-01-01	LM_ELE_ADR_B07	96226.13	\N
2022-01-01	LM_ELE_ADR_B08	143926.66	\N
2022-01-01	LM_LC_ADR_B26	129.57	\N
2022-01-01	LM_LC_ADR_B30	389.7	\N
2022-01-01	LM_LC_ADR_B32	862.4	\N
2022-01-01	LM_LC_ADR_B33	762.8	\N
2022-01-01	LM_LH_ADR_B19	89.4	\N
2022-01-01	LM_LH_ADR_B21	183.3	\N
2022-01-01	LM_LH_ADR_B34	0	\N
2022-01-01	LM_LH_ADR_B37	0.4	\N
2022-01-01	LM_LH_ADR_B39	95.7	\N
2022-01-01	LM_LH_ADR_B40	160.4	\N
2022-01-01	LM_LH_ADR_B42	0	\N
2022-01-01	LM_WOD_ADR_B78	183.44	\N
2022-01-01	LM_LC_ADR102	47.42	\N
2022-01-01	LM_LC_ADR103	52.19	\N
2022-01-01	LM_LC_ADR104	67.69	\N
2022-01-01	LM_LC_ADR152	4597.5	\N
2022-01-01	LM_LC_ADR149	0.91	\N
2022-01-01	LM_LC_ADR156	3146.6	\N
2022-01-01	LM_LC_ADR171	267.51	\N
2022-01-01	LM_LC_ADR165	42.84	\N
2022-01-01	LM_LC_ADR166	34.14	\N
2022-01-01	LM_LC_ADR180	134.03	\N
2022-01-01	LM_LC_ADR181	0.1	\N
2022-01-01	LM_LC_ADR182	81.59	\N
2022-01-01	LM_LC_ADR183	1.42	\N
2022-01-01	LM_LC_ADR185	18.82	\N
2022-01-01	LM_LC_ADR161	1334.1	\N
2022-01-01	LM_LC_ADR224	146.45	\N
2022-01-01	LM_LC_ADR89	32.21	\N
2022-01-01	LM_LC_ADR93	31.76	\N
2022-01-01	LM_LH_ADR145	10.07	\N
2022-01-01	LM_LH_ADR188	32.18	\N
2022-01-01	LM_LH_ADR190	7.89	\N
2022-01-01	LM_LH_ADR191	18.8	\N
2022-01-01	LM_LH_ADR192	0	\N
2022-01-01	LM_LH_ADR194	0	\N
2022-01-01	LM_LH_ADR207	398.2	\N
2022-01-01	LM_LH_ADR197	1246.7	\N
2022-01-01	LM_LH_ADR215	0	\N
2022-01-01	LM_LH_ADR219	0.03	\N
2022-01-01	LM_LH_ADR220	71.98	\N
2022-01-01	LM_LH_ADR223	176.6	\N
2022-01-01	LM_LH_ADR225	70.4	\N
2022-01-01	LM_LH_ADR226	66.45	\N
2022-01-01	LM_LH_ADR217	494.1	\N
2022-01-01	LM_LH_ADR228	28.8	\N
2022-01-01	LM_LH_ADR232	54.48	\N
2022-01-01	LM_LH_ADR233	45.1	\N
2022-01-01	LM_LH_ADR230	1.7	\N
2022-01-01	LM_ELE_ADR114	254182.16	\N
2022-01-01	LM_ELE_ADR117	22560.46	\N
2022-01-01	LM_WOD_ADR132	292.85	\N
2022-01-01	LM_WOD_ADR133	339.79	\N
2022-01-01	LM_WOD_ADR134	18.59	\N
2022-01-01	LM_WOD_ADR135	0	\N
2022-01-01	LM_WOD_ADR136	67.18	\N
2022-01-01	LM_WOD_ADR139	1338.72	\N
2022-01-01	LM_WOD_ADR141	17	\N
2022-01-01	LM_WOD_ADR142	36	\N
2022-01-01	LM_WOD_ADR143	557.39	\N
2022-01-01	LM_WOD_ADR146	28874	\N
2022-01-01	LM_WOD_ADR150	38.79	\N
2022-01-01	LM_WOD_ADR237	923.35	\N
2022-01-01	LM_WOD_ADR238	2277.4	\N
2022-01-01	LM_WOD_ADR239	31.4	\N
2022-01-01	LM_WOD_ADR240	119.13	\N
2022-01-01	LM_WOD_ADR241	45.32	\N
2022-01-01	LM_ELE_ADR121	85.44	\N
2022-01-01	LM_ELE_ADR128	0	\N
2022-01-01	LM_WOD_ADR247_Solution Space	505.49	\N
2022-01-01	LM_WOD_ADR250_Solution Space	182.53	\N
2022-01-01	LM_WOD_ADR30	0	\N
2022-01-01	LM_ELE_ADR001	64962.33	\N
2022-01-01	LM_ELE_ADR002	85021.45	\N
2022-01-01	LM_ELE_ADR003	110804.38	\N
2022-01-01	LM_ELE_ADR006	74055.76	\N
2022-01-01	LM_ELE_ADR007	126956.69	\N
2022-01-01	LM_ELE_ADR009	166633.06	\N
2022-01-01	LM_ELE_ADR011	159020.13	\N
2022-01-01	LM_ELE_ADR013	206741.16	\N
2022-01-01	LM_ELE_ADR014	13583.26	\N
2022-01-01	LM_ELE_ADR015	124156.66	\N
2022-01-01	LM_ELE_ADR016	914650.06	\N
2022-01-01	LM_ELE_ADR018	12501.57	\N
2022-01-01	LM_ELE_ADR020	129521.89	\N
2022-01-01	LM_ELE_ADR022	136147.75	\N
2022-01-01	LM_ELE_ADR023	30457.3	\N
2022-01-01	LM_ELE_ADR025	436062.22	\N
2022-01-01	LM_ELE_ADR028	18611.53	\N
2022-01-01	LM_ELE_ADR034	25480.77	\N
2022-01-01	LM_ELE_ADR036	85486.1	\N
2022-01-01	LM_ELE_ADR039	327294.56	\N
2022-01-01	LM_ELE_ADR040	33078.72	\N
2022-01-01	LM_ELE_ADR042	3321.99	\N
2022-01-01	LM_ELE_ADR044	6485.85	\N
2022-01-01	LM_ELE_ADR048	6826.89	\N
2022-01-01	LM_ELE_ADR051	6510	\N
2022-01-01	LM_ELE_ADR053	19195.94	\N
2022-01-01	LM_ELE_ADR055	5367.62	\N
2022-01-01	LM_ELE_ADR056	20874.4	\N
2022-01-01	LM_ELE_ADR063	190	\N
2022-01-01	LM_ELE_ADR064	0	\N
2022-01-01	LM_ELE_ADR058	78316.08	\N
2022-01-01	LM_ELE_ADR072	24321	\N
2022-01-01	LM_ELE_ADR074	73505	\N
2022-01-01	LM_ELE_ADR076	0	\N
2022-01-01	LM_ELE_ADR081	47140.29	\N
2022-01-01	LM_ELE_ADR085	49034.06	\N
2022-01-01	LM_ELE_ADR090	35908.32	\N
2022-01-01	LM_ELE_ADR107	77556.34	\N
2022-01-01	LM_ELE_ADR108	6319.58	\N
2022-01-01	LM_ELE_ADR109	2014.63	\N
2022-01-01	LM_ELE_ADR110	410.79	\N
2022-01-01	LM_ELE_ADR113	50768.7	\N
2022-01-01	LM_ELE_ADR087	85085.46	\N
2022-01-01	LM_LC_ADR_B45	177.11	\N
2022-01-01	LM_LH_ADR_B46	49.35	\N
2022-01-01	LM_LH_ADR_B47	116.7	\N
2022-01-01	LM_WOD_ADR_B74	32.68	\N
2022-01-01	LM_ELE_ADR_B06	433482.75	\N
2022-01-01	LM_ELE_ADR046	0	\N
2022-01-01	LM_ELE_ADR010	113322.88	\N
2022-01-01	LM_ELE_ADR043	2658.11	\N
2022-01-01	LM_ELE_ADR_B11	30629.97	\N
2022-01-01	LM_WOD_ADR242	42.06	\N
2022-01-01	LM_ELE_ADR124	88215.27	\N
2022-01-01	LM_ELE_ADR112	707275.75	\N
2022-01-01	LM_WOD_ADR_B75	174.46	\N
2022-01-01	LM_ELE_ADR091	11008.27	\N
2022-01-01	LM_WOD_ADR_B80	111.57	\N
2022-01-01	LM_WOD_ADR_B81	41.05	\N
2022-01-01	LM_ELE_ADR_B04	275595.09	\N
2022-01-01	LM_ELE_ADR_B05	239370.66	\N
2022-01-01	LM_ELE_ADR_B09	282907.28	\N
2022-01-01	LM_ELE_ADR_B01	0	\N
2022-01-01	LM_ELE_ADR_B10	28369.16	\N
2022-01-01	LM_ELE_ADR_B02	0	\N
2022-01-01	LM_LC_ADR_B18	16.89	\N
2022-01-01	LM_LC_ADR_B20	64.1	\N
2022-01-01	LM_LC_ADR_B22	44.72	\N
2022-01-01	LM_LC_ADR_B24	10.02	\N
2022-01-01	LM_LC_ADR_B31	389.9	\N
2022-01-01	LM_LC_ADR_B41	443.7	\N
2022-01-01	LM_LC_ADR_B43	7.4	\N
2022-01-01	LM_LH_ADR_B23	64.1	\N
2022-01-01	LM_LH_ADR_B25	52.6	\N
2022-01-01	LM_LH_ADR_B27	129.7	\N
2022-01-01	LM_LH_ADR_B35	0	\N
2022-01-01	LM_LH_ADR_B36	0	\N
2022-01-01	LM_LH_ADR_B38	71.9	\N
2022-01-01	LM_LH_ADR_B44	4.5	\N
2022-01-01	LM_WOD_ADR_B76	1736.79	\N
2022-01-01	LM_WOD_ADR_B77	8.96	\N
2022-01-01	LM_LC_ADR_B16	35.75	\N
2022-01-01	LM_LH_ADR_B17	48.8	\N
2022-01-01	LM_WOD_ADR_B79	360.11	\N
2022-01-01	LM_ELE_ADR_B12	16811.19	\N
2022-01-01	LM_ELE_ADR_B13	15053.19	\N
2022-01-01	LM_LC_ADR_B46	47.31	\N
2022-01-01	LM_LC_ADR193	0	\N
2022-01-01	LM_ELE_ADR125	4775.08	\N
2022-01-01	LM_ELE_ADR069	275813	\N
2022-01-01	LM_ELE_ADR075	10193	\N
2022-01-01	LM_LC_ADR159	4010	\N
2022-01-01	LM_LC_ADR160	5620	\N
2022-01-01	LM_LH_ADR167	780	\N
2022-01-01	LM_WOD_ADR236	3.52	\N
2022-02-01	LM_LC_ADR170	54.02	\N
2022-02-01	LM_LC_ADR172	119.11	\N
2022-02-01	LM_ELE_ADR115	24653.31	\N
2022-02-01	LM_LC_ADR123	495.8	\N
2022-02-01	LM_LC_ADR176	84.7	\N
2022-02-01	LM_LH_ADR208	301.7	\N
2022-02-01	LM_ELE_ADR019	3435.56	\N
2022-02-01	LM_LH_ADR201	89.1	\N
2022-02-01	LM_ELE_ADR059	22648.19	\N
2022-02-01	LM_ELE_ADR097	29310.53	\N
2022-02-01	LM_WOD_ADR246_Solution Space	516.55	\N
2022-02-01	LM_LC_ADR171	292.38	\N
2022-02-01	LM_LH_ADR194	0	\N
2022-02-01	LM_WOD_ADR133	341.32	\N
2022-02-01	LM_WOD_ADR150	39.76	\N
2022-02-01	LM_ELE_ADR007	132043.48	\N
2022-02-01	LM_ELE_ADR039	344429.31	\N
2022-02-01	LM_ELE_ADR081	52698.55	\N
2022-02-01	LM_ELE_ADR010	115438.13	\N
2022-02-01	LM_ELE_ADR_B02	0	\N
2022-02-01	LM_WOD_ADR_B76	1736.79	\N
2022-02-01	LM_WOD_ADR236	5.6	\N
2022-03-01	LM_LC_ADR170	55.27	\N
2022-03-01	LM_LC_ADR172	124.87	\N
2022-03-01	LM_LC_ADR179	85.58	\N
2022-03-01	LM_ELE_ADR021	264735.34	\N
2022-02-01	zdemontowany600	3194	\N
2022-03-01	LM_ELE_ADR078	52811	\N
2022-03-01	LM_ELE_ADR066	0	\N
2022-03-01	LM_ELE_ADR080	169140	\N
2022-03-01	LM_LH_ADR199	145.4	\N
2022-03-01	LM_ELE_ADR115	25335.08	\N
2022-03-01	LM_WOD_ADR249_Solution Space	100.75	\N
2022-03-01	LM_WOD_MAIN_W	0	\N
2022-03-01	LM_LC_ADR123	516	\N
2022-03-01	LM_LC_ADR151	30093	\N
2022-03-01	LM_LC_ADR153	10320	\N
2022-03-01	LM_LC_ADR154	2568.2	\N
2022-03-01	LM_LC_ADR155	6859.6	\N
2022-03-01	LM_LC_ADR157	1083.4	\N
2022-03-01	LM_LC_ADR158	351.4	\N
2022-03-01	LM_LC_ADR162	779.1	\N
2022-03-01	LM_LC_ADR168	110.9	\N
2022-03-01	LM_LC_ADR173	99.3	\N
2022-03-01	LM_LC_ADR174	196.42	\N
2022-03-01	LM_LC_ADR175	0	\N
2022-03-01	LM_LC_ADR176	84.7	\N
2022-03-01	LM_LC_ADR178	129.89	\N
2022-03-01	LM_LC_ADR184	42.83	\N
2022-03-01	LM_LC_ADR186	19.23	\N
2022-03-01	LM_LC_ADR187	32.69	\N
2022-03-01	LM_LC_ADR209	95.73	\N
2022-03-01	LM_LC_ADR32	0	\N
2022-03-01	LM_LC_ADR82	21.84	\N
2022-03-01	LM_LH_ADR122	14.8	\N
2022-03-01	LM_LH_ADR189	60.09	\N
2022-03-01	LM_LH_ADR195	426.9	\N
2022-03-01	LM_LH_ADR196	9	\N
2022-03-01	LM_LH_ADR198	1218.1	\N
2022-03-01	LM_LH_ADR200	46.6	\N
2022-03-01	LM_LH_ADR203	220	\N
2022-03-01	LM_LH_ADR204	98.3	\N
2022-03-01	LM_LH_ADR208	309.1	\N
2022-03-01	LM_LH_ADR211	35.7	\N
2022-03-01	LM_LH_ADR212	181.3	\N
2022-03-01	LM_LH_ADR216	34.87	\N
2022-03-01	LM_LH_ADR218	420.3	\N
2022-03-01	LM_LH_ADR221	330.5	\N
2022-03-01	LM_LH_ADR222	0	\N
2022-03-01	LM_LH_ADR227	41.2	\N
2022-03-01	LM_LH_ADR229	84.89	\N
2022-03-01	LM_LH_ADR231	0	\N
2022-03-01	LM_LH_ADR234	0	\N
2022-03-01	LM_LH_ADR235	86.8	\N
2022-03-01	LM_LH_ADR33	0	\N
2022-03-01	LM_ELE_ADR008	100582.66	\N
2022-03-01	LM_ELE_ADR012	91251.63	\N
2022-03-01	LM_ELE_ADR017	12498.35	\N
2022-03-01	LM_ELE_ADR019	3913.96	\N
2022-03-01	LM_ELE_ADR024	123242.23	\N
2022-03-01	LM_ELE_ADR027	35663.11	\N
2022-03-01	LM_LC_ADR163	29.27	\N
2022-03-01	LM_LC_ADR164	0.02	\N
2022-03-01	LM_LH_ADR201	90.5	\N
2022-03-01	LM_ELE_ADR029	12802.35	\N
2022-03-01	LM_ELE_ADR031	184708.7	\N
2022-03-01	LM_ELE_ADR038	346919.88	\N
2022-03-01	LM_ELE_ADR041	65758.1	\N
2022-03-01	LM_ELE_ADR045	5815.95	\N
2022-03-01	LM_ELE_ADR047	5258.95	\N
2022-03-01	LM_ELE_ADR049	14411.51	\N
2022-03-01	LM_ELE_ADR052	10869.97	\N
2022-03-01	LM_ELE_ADR054	30235.71	\N
2022-03-01	LM_ELE_ADR057	5984.45	\N
2022-03-01	LM_ELE_ADR059	23096.9	\N
2022-03-01	LM_ELE_ADR060	0	\N
2022-03-01	LM_ELE_ADR061	0	\N
2022-03-01	LM_ELE_ADR062	21285	\N
2022-03-01	LM_ELE_ADR065	0	\N
2022-03-01	LM_ELE_ADR067	264	\N
2022-03-01	LM_ELE_ADR068	6409	\N
2022-03-01	LM_ELE_ADR070	88	\N
2022-03-01	LM_ELE_ADR071	76851	\N
2022-03-01	LM_ELE_ADR073	88	\N
2022-03-01	LM_ELE_ADR077	1063	\N
2022-03-01	LM_ELE_ADR084	54394.71	\N
2022-03-01	LM_ELE_ADR086	14286.6	\N
2022-03-01	LM_ELE_ADR088	37864.15	\N
2022-03-01	LM_ELE_ADR094	1470.89	\N
2022-03-01	LM_ELE_ADR095	99386.1	\N
2022-03-01	LM_ELE_ADR097	30406.63	\N
2022-03-01	LM_ELE_ADR098	3438.05	\N
2022-03-01	LM_ELE_ADR099	79358.54	\N
2022-03-01	LM_ELE_ADR100	17622.77	\N
2022-03-01	LM_ELE_ADR101	7582.94	\N
2022-03-01	LM_ELE_ADR111	362.6	\N
2022-03-01	LM_ELE_ADR116	15066.03	\N
2022-03-01	LM_ELE_ADR118	20442.57	\N
2022-03-01	LM_ELE_ADR119	73607.42	\N
2022-03-01	LM_ELE_ADR120	84726.41	\N
2022-03-01	LM_WOD_ADR129	115.42	\N
2022-03-01	LM_WOD_ADR140	122.34	\N
2022-03-01	LM_WOD_ADR147	59.5	\N
2022-03-01	LM_WOD_ADR246_Solution Space	529.87	\N
2022-03-01	LM_WOD_ADR248_Solution Space	44.34	\N
2022-03-01	LM_ELE_ADR_B03	126484.05	\N
2022-03-01	LM_ELE_ADR_B07	100077.98	\N
2022-03-01	LM_ELE_ADR_B08	149098	\N
2022-03-01	LM_LC_ADR_B26	155.21	\N
2022-03-01	LM_LC_ADR_B30	426.1	\N
2022-03-01	LM_LC_ADR_B32	947.1	\N
2022-03-01	LM_LC_ADR_B33	852.2	\N
2022-03-01	LM_LH_ADR_B19	100.8	\N
2022-03-01	LM_LH_ADR_B21	195.8	\N
2022-03-01	LM_LH_ADR_B34	0	\N
2022-03-01	LM_LH_ADR_B37	0.4	\N
2022-03-01	LM_LH_ADR_B39	96.1	\N
2022-03-01	LM_LH_ADR_B40	161.8	\N
2022-03-01	LM_LH_ADR_B42	0	\N
2022-03-01	LM_WOD_ADR_B78	187.41	\N
2022-03-01	LM_LC_ADR102	51.71	\N
2022-03-01	LM_LC_ADR103	57.02	\N
2022-03-01	LM_LC_ADR104	75.92	\N
2022-03-01	LM_LC_ADR152	4924	\N
2022-03-01	LM_LC_ADR149	0.91	\N
2022-03-01	LM_LC_ADR156	3455.3	\N
2022-03-01	LM_LC_ADR171	303.49	\N
2022-03-01	LM_LC_ADR165	47.18	\N
2022-03-01	LM_LC_ADR166	37.39	\N
2022-03-01	LM_LC_ADR180	144.13	\N
2022-03-01	LM_LC_ADR181	0.1	\N
2022-03-01	LM_LC_ADR182	89.29	\N
2022-03-01	LM_LC_ADR183	1.42	\N
2022-03-01	LM_LC_ADR185	18.94	\N
2022-03-01	LM_LC_ADR161	1418.2	\N
2022-03-01	LM_LC_ADR224	161.21	\N
2022-03-01	LM_LC_ADR89	36.24	\N
2022-03-01	LM_LC_ADR93	35.76	\N
2022-03-01	LM_LH_ADR145	10.07	\N
2022-03-01	LM_LH_ADR188	32.18	\N
2022-03-01	LM_LH_ADR190	7.89	\N
2022-03-01	LM_LH_ADR191	18.8	\N
2022-03-01	LM_LH_ADR192	0	\N
2022-03-01	LM_LH_ADR207	409	\N
2022-03-01	LM_LH_ADR197	1262.5	\N
2022-03-01	LM_LH_ADR215	0	\N
2022-03-01	LM_LH_ADR219	0.03	\N
2022-03-01	LM_LH_ADR220	112.2	\N
2022-03-01	LM_LH_ADR223	180.1	\N
2022-03-01	LM_LH_ADR225	70.9	\N
2022-03-01	LM_LH_ADR226	77.77	\N
2022-03-01	LM_LH_ADR217	504.4	\N
2022-03-01	LM_LH_ADR228	29.2	\N
2022-03-01	LM_LH_ADR232	57.39	\N
2022-03-01	LM_LH_ADR233	45.2	\N
2022-03-01	LM_LH_ADR230	1.7	\N
2022-03-01	LM_ELE_ADR114	27.81	\N
2022-03-01	LM_ELE_ADR117	22587.41	\N
2022-03-01	LM_WOD_ADR132	297.13	\N
2022-03-01	LM_WOD_ADR133	343.27	\N
2022-03-01	LM_WOD_ADR134	18.68	\N
2022-03-01	LM_WOD_ADR135	0	\N
2022-03-01	LM_WOD_ADR136	68.77	\N
2022-03-01	LM_WOD_ADR139	1400.07	\N
2022-03-01	LM_WOD_ADR141	17	\N
2022-03-01	LM_WOD_ADR142	36	\N
2022-03-01	LM_WOD_ADR143	557.39	\N
2022-03-01	LM_WOD_ADR146	29910.6	\N
2022-03-01	LM_WOD_ADR148	0.01	\N
2022-03-01	LM_WOD_ADR150	40.66	\N
2022-03-01	LM_WOD_ADR237	923.65	\N
2022-03-01	LM_WOD_ADR238	2425.17	\N
2022-03-01	LM_WOD_ADR239	33.48	\N
2022-03-01	LM_WOD_ADR240	127.75	\N
2022-03-01	LM_WOD_ADR241	98.56	\N
2022-03-01	LM_ELE_ADR121	185092.89	\N
2022-03-01	LM_ELE_ADR128	0	\N
2022-03-01	LM_WOD_ADR247_Solution Space	552.04	\N
2022-03-01	LM_WOD_ADR250_Solution Space	195.05	\N
2022-03-01	LM_WOD_ADR30	0	\N
2022-03-01	LM_ELE_ADR001	66393.08	\N
2022-03-01	LM_ELE_ADR002	87824.46	\N
2022-03-01	LM_ELE_ADR003	115854.34	\N
2022-03-01	LM_ELE_ADR006	0	\N
2022-03-01	LM_ELE_ADR007	136337.09	\N
2022-03-01	LM_ELE_ADR009	174986.86	\N
2022-03-01	LM_ELE_ADR011	162767.81	\N
2022-03-01	LM_ELE_ADR013	214703.75	\N
2022-03-01	LM_ELE_ADR014	14267.42	\N
2022-03-01	LM_ELE_ADR015	129229.89	\N
2022-03-01	LM_ELE_ADR016	930790.56	\N
2022-03-01	LM_ELE_ADR018	12963.05	\N
2022-03-01	LM_ELE_ADR020	135180.03	\N
2022-03-01	LM_ELE_ADR022	149547.11	\N
2022-03-01	LM_ELE_ADR023	32657.76	\N
2022-03-01	LM_ELE_ADR025	499290.94	\N
2022-03-01	LM_ELE_ADR028	19004.5	\N
2022-03-01	LM_ELE_ADR034	27653.83	\N
2022-03-01	LM_ELE_ADR036	89326.59	\N
2022-03-01	LM_ELE_ADR039	356898.47	\N
2022-03-01	LM_ELE_ADR040	36084.46	\N
2022-03-01	LM_ELE_ADR042	3439.37	\N
2022-03-01	LM_ELE_ADR044	6665.97	\N
2022-03-01	LM_ELE_ADR048	7017.49	\N
2022-03-01	LM_ELE_ADR051	6727.22	\N
2022-03-01	LM_ELE_ADR053	22354.8	\N
2022-03-01	LM_ELE_ADR055	5549.35	\N
2022-03-01	LM_ELE_ADR056	21604.85	\N
2022-03-01	LM_ELE_ADR063	190	\N
2022-03-01	LM_ELE_ADR064	0	\N
2022-03-01	LM_ELE_ADR058	81051.47	\N
2022-03-01	LM_ELE_ADR072	25747	\N
2022-03-01	LM_ELE_ADR074	76851	\N
2022-03-01	LM_ELE_ADR076	0	\N
2022-03-01	LM_ELE_ADR081	57250.61	\N
2022-03-01	LM_ELE_ADR085	53664.79	\N
2022-03-01	LM_ELE_ADR090	37275.48	\N
2022-03-01	LM_ELE_ADR107	82612.55	\N
2022-03-01	LM_ELE_ADR108	6462.26	\N
2022-03-01	LM_ELE_ADR109	2015.63	\N
2022-03-01	LM_ELE_ADR110	411.51	\N
2022-03-01	LM_ELE_ADR113	53021.61	\N
2022-03-01	LM_ELE_ADR087	87801.48	\N
2022-03-01	LM_LC_ADR_B45	207.05	\N
2022-03-01	LM_LH_ADR_B46	49.35	\N
2022-03-01	LM_LH_ADR_B47	117.4	\N
2022-03-01	LM_WOD_ADR_B74	34.71	\N
2022-03-01	LM_ELE_ADR_B06	453654.47	\N
2022-03-01	LM_ELE_ADR046	0	\N
2022-03-01	LM_ELE_ADR010	117036.63	\N
2022-03-01	LM_ELE_ADR043	2759.5	\N
2022-03-01	LM_ELE_ADR_B11	32227.1	\N
2022-03-01	LM_WOD_ADR242	42.46	\N
2022-03-01	LM_ELE_ADR124	99040.4	\N
2022-03-01	LM_ELE_ADR112	716228.81	\N
2022-03-01	LM_WOD_ADR_B75	179.96	\N
2022-03-01	LM_ELE_ADR091	11695.15	\N
2022-03-01	LM_WOD_ADR_B80	119.68	\N
2022-03-01	LM_WOD_ADR_B81	42.69	\N
2022-03-01	LM_ELE_ADR_B04	278856.91	\N
2022-03-01	LM_ELE_ADR_B05	243363.95	\N
2022-03-01	LM_ELE_ADR_B09	292142.66	\N
2022-03-01	LM_ELE_ADR_B01	0	\N
2022-03-01	LM_ELE_ADR_B10	29549	\N
2022-03-01	LM_ELE_ADR_B02	0	\N
2022-03-01	LM_LC_ADR_B18	18.22	\N
2022-03-01	LM_LC_ADR_B20	69.31	\N
2022-03-01	LM_LC_ADR_B22	54.91	\N
2022-03-01	LM_LC_ADR_B24	10.66	\N
2022-03-01	LM_LC_ADR_B31	432.7	\N
2022-03-01	LM_LC_ADR_B41	495.6	\N
2022-03-01	LM_LC_ADR_B43	8.1	\N
2022-03-01	LM_LH_ADR_B23	66.3	\N
2022-03-01	LM_LH_ADR_B25	58.3	\N
2022-03-01	LM_LH_ADR_B27	139.1	\N
2022-03-01	LM_LH_ADR_B35	0	\N
2022-03-01	LM_LH_ADR_B36	0	\N
2022-03-01	LM_LH_ADR_B38	72	\N
2022-03-01	LM_LH_ADR_B44	4.5	\N
2022-03-01	LM_WOD_ADR_B76	1736.79	\N
2022-03-01	LM_WOD_ADR_B77	8.96	\N
2022-03-01	LM_LC_ADR_B16	38.82	\N
2022-03-01	LM_LH_ADR_B17	50	\N
2022-03-01	LM_WOD_ADR_B79	360.11	\N
2022-03-01	LM_ELE_ADR_B12	17833.39	\N
2022-03-01	LM_ELE_ADR_B13	15053.19	\N
2022-03-01	LM_LC_ADR_B46	53.49	\N
2022-03-01	LM_LC_ADR193	0	\N
2022-03-01	LM_ELE_ADR125	4892.61	\N
2022-03-01	LM_ELE_ADR069	292197	\N
2022-03-01	LM_ELE_ADR075	10654	\N
2022-03-01	LM_LC_ADR159	5030	\N
2022-03-01	LM_LC_ADR160	9590	\N
2022-03-01	LM_LH_ADR167	1420	\N
2022-03-01	LM_WOD_ADR236	7.72	\N
2022-03-01	zdemontowany600	3194	\N
2022-04-01	LM_LC_ADR170	56.1	\N
2022-04-01	LM_LC_ADR172	129.26	\N
2022-04-01	LM_LC_ADR179	86.04	\N
2022-04-01	LM_ELE_ADR021	274907.25	\N
2022-04-01	LM_ELE_ADR078	54151	\N
2022-04-01	LM_ELE_ADR066	0	\N
2022-04-01	LM_ELE_ADR080	171785.92	\N
2022-04-01	LM_LH_ADR199	146.3	\N
2022-04-01	LM_ELE_ADR115	26034.44	\N
2022-04-01	LM_WOD_ADR249_Solution Space	105.14	\N
2022-04-01	LM_WOD_MAIN_W	0	\N
2022-04-01	LM_LC_ADR123	535.6	\N
2022-04-01	LM_LC_ADR151	30737	\N
2022-04-01	LM_LC_ADR153	10495	\N
2022-04-01	LM_LC_ADR154	2648.2	\N
2022-04-01	LM_LC_ADR155	7025.3	\N
2022-04-01	LM_LC_ADR157	1108.5	\N
2022-04-01	LM_LC_ADR158	360.5	\N
2022-04-01	LM_LC_ADR162	796.7	\N
2022-04-01	LM_LC_ADR168	115.7	\N
2022-04-01	LM_LC_ADR173	100.73	\N
2022-04-01	LM_LC_ADR174	211.56	\N
2022-04-01	LM_LC_ADR175	0	\N
2022-04-01	LM_LC_ADR176	85.7	\N
2022-04-01	LM_LC_ADR178	135.54	\N
2022-04-01	LM_LC_ADR184	44.04	\N
2022-04-01	LM_LC_ADR186	19.23	\N
2022-04-01	LM_LC_ADR187	32.69	\N
2022-04-01	LM_LC_ADR209	95.73	\N
2022-04-01	LM_LC_ADR32	0	\N
2022-04-01	LM_LC_ADR82	25.8	\N
2022-04-01	LM_LH_ADR122	15.1	\N
2022-04-01	LM_LH_ADR189	60.31	\N
2022-04-01	LM_LH_ADR195	432.4	\N
2022-04-01	LM_LH_ADR196	9	\N
2022-04-01	LM_LH_ADR198	1238.1	\N
2022-04-01	LM_LH_ADR200	47.2	\N
2022-04-01	LM_LH_ADR203	221.7	\N
2022-04-01	LM_LH_ADR204	100.4	\N
2022-04-01	LM_LH_ADR208	318.1	\N
2022-04-01	LM_LH_ADR211	37.5	\N
2022-04-01	LM_LH_ADR212	190.6	\N
2022-04-01	LM_LH_ADR216	34.87	\N
2022-04-01	LM_LH_ADR218	431.6	\N
2022-04-01	LM_LH_ADR221	346.1	\N
2022-04-01	LM_LH_ADR222	0	\N
2022-04-01	LM_LH_ADR227	41.2	\N
2022-04-01	LM_LH_ADR231	0	\N
2022-04-01	LM_LH_ADR234	0	\N
2022-04-01	LM_LH_ADR235	86.9	\N
2022-04-01	LM_LH_ADR33	0	\N
2022-04-01	LM_ELE_ADR008	102291.11	\N
2022-04-01	LM_ELE_ADR012	92346.79	\N
2022-04-01	LM_ELE_ADR017	12757.99	\N
2022-04-01	LM_ELE_ADR019	4038.56	\N
2022-04-01	LM_ELE_ADR024	125577.14	\N
2022-04-01	LM_ELE_ADR027	35941.96	\N
2022-04-01	LM_LC_ADR163	30.1	\N
2022-04-01	LM_LC_ADR164	0.02	\N
2022-04-01	LM_LH_ADR201	94.1	\N
2022-04-01	LM_ELE_ADR029	13331	\N
2022-04-01	LM_ELE_ADR031	188273.64	\N
2022-04-01	LM_ELE_ADR038	358703.31	\N
2022-04-01	LM_ELE_ADR041	66973.3	\N
2022-04-01	LM_ELE_ADR045	5914.61	\N
2022-04-01	LM_ELE_ADR047	5357.25	\N
2022-04-01	LM_ELE_ADR049	14618.48	\N
2022-04-01	LM_ELE_ADR052	11045.31	\N
2022-04-01	LM_ELE_ADR054	30687.91	\N
2022-04-01	LM_ELE_ADR057	6080.57	\N
2022-04-01	LM_ELE_ADR059	23574.64	\N
2022-04-01	LM_ELE_ADR060	0	\N
2022-04-01	LM_ELE_ADR061	0	\N
2022-04-01	LM_ELE_ADR062	22038	\N
2022-04-01	LM_ELE_ADR065	0	\N
2022-04-01	LM_ELE_ADR067	266	\N
2022-04-01	LM_ELE_ADR068	7740	\N
2022-04-01	LM_ELE_ADR070	88	\N
2022-04-01	LM_ELE_ADR071	78744	\N
2022-04-01	LM_ELE_ADR073	88	\N
2022-04-01	LM_ELE_ADR077	1063	\N
2022-04-01	LM_ELE_ADR084	55071.62	\N
2022-04-01	LM_ELE_ADR086	14782.28	\N
2022-04-01	LM_ELE_ADR088	38918.8	\N
2022-04-01	LM_ELE_ADR094	1479.88	\N
2022-04-01	LM_ELE_ADR095	101468.18	\N
2022-04-01	LM_ELE_ADR097	31638.74	\N
2022-04-01	LM_ELE_ADR098	3490.14	\N
2022-04-01	LM_ELE_ADR099	82524.71	\N
2022-04-01	LM_ELE_ADR100	18419.08	\N
2022-04-01	LM_ELE_ADR101	7778.43	\N
2022-04-01	LM_ELE_ADR111	362.6	\N
2022-04-01	LM_ELE_ADR116	15087.19	\N
2022-04-01	LM_ELE_ADR118	20882.47	\N
2022-04-01	LM_ELE_ADR119	74945.36	\N
2022-04-01	LM_ELE_ADR120	88401.65	\N
2022-04-01	LM_WOD_ADR129	119.25	\N
2022-04-01	LM_WOD_ADR140	122.67	\N
2022-04-01	LM_WOD_ADR147	60.69	\N
2022-04-01	LM_WOD_ADR246_Solution Space	545.18	\N
2022-04-01	LM_WOD_ADR248_Solution Space	46.22	\N
2022-04-01	LM_ELE_ADR_B03	128346.27	\N
2022-04-01	LM_ELE_ADR_B07	101725.52	\N
2022-04-01	LM_ELE_ADR_B08	151519.53	\N
2022-04-01	LM_LC_ADR_B26	163.63	\N
2022-04-01	LM_LC_ADR_B30	439.5	\N
2022-04-01	LM_LC_ADR_B32	968.7	\N
2022-04-01	LM_LC_ADR_B33	873.9	\N
2022-04-01	LM_LH_ADR_B19	101.8	\N
2022-04-01	LM_LH_ADR_B21	197.5	\N
2022-04-01	LM_LH_ADR_B34	0	\N
2022-04-01	LM_LH_ADR_B37	0.4	\N
2022-04-01	LM_LH_ADR_B39	97.1	\N
2022-04-01	LM_LH_ADR_B40	163.3	\N
2022-04-01	LM_LH_ADR_B42	0	\N
2022-04-01	LM_WOD_ADR_B78	190.19	\N
2022-04-01	LM_LC_ADR102	53.55	\N
2022-04-01	LM_LC_ADR103	59.08	\N
2022-04-01	LM_LC_ADR104	79.33	\N
2022-04-01	LM_LC_ADR152	5053.9	\N
2022-04-01	LM_LC_ADR149	0.91	\N
2022-04-01	LM_LC_ADR156	3555.1	\N
2022-04-01	LM_LC_ADR171	305.81	\N
2022-04-01	LM_LC_ADR165	49.14	\N
2022-04-01	LM_LC_ADR166	38.77	\N
2022-04-01	LM_LC_ADR180	144.71	\N
2022-04-01	LM_LC_ADR181	0.1	\N
2022-04-01	LM_LC_ADR182	91.46	\N
2022-04-01	LM_LC_ADR183	1.42	\N
2022-04-01	LM_LC_ADR185	18.94	\N
2022-04-01	LM_LC_ADR161	1449.7	\N
2022-04-01	LM_LC_ADR224	167.58	\N
2022-04-01	LM_LC_ADR89	37.92	\N
2022-04-01	LM_LC_ADR93	37.43	\N
2022-04-01	LM_LH_ADR145	10.07	\N
2022-04-01	LM_LH_ADR188	32.18	\N
2022-04-01	LM_LH_ADR190	7.89	\N
2022-04-01	LM_LH_ADR191	18.8	\N
2022-04-01	LM_LH_ADR192	0	\N
2022-04-01	LM_LH_ADR194	0	\N
2022-04-01	LM_LH_ADR207	414.4	\N
2022-04-01	LM_LH_ADR197	1272.6	\N
2022-04-01	LM_LH_ADR215	0	\N
2022-04-01	LM_LH_ADR219	0.03	\N
2022-04-01	LM_LH_ADR220	112.2	\N
2022-04-01	LM_LH_ADR223	184.7	\N
2022-04-01	LM_LH_ADR225	70.9	\N
2022-04-01	LM_LH_ADR226	81.44	\N
2022-04-01	LM_LH_ADR217	505.5	\N
2022-04-01	LM_LH_ADR228	29.6	\N
2022-04-01	LM_LH_ADR232	58.81	\N
2022-04-01	LM_LH_ADR233	45.6	\N
2022-04-01	LM_LH_ADR230	1.7	\N
2022-04-01	LM_ELE_ADR114	27.81	\N
2022-04-01	LM_ELE_ADR117	22600.58	\N
2022-04-01	LM_WOD_ADR132	300.1	\N
2022-04-01	LM_WOD_ADR133	345.99	\N
2022-04-01	LM_WOD_ADR134	18.69	\N
2022-04-01	LM_WOD_ADR135	0	\N
2022-04-01	LM_WOD_ADR136	69.78	\N
2022-04-01	LM_WOD_ADR139	1436.01	\N
2022-04-01	LM_WOD_ADR141	17	\N
2022-04-01	LM_WOD_ADR142	36	\N
2022-04-01	LM_WOD_ADR143	557.39	\N
2022-04-01	LM_WOD_ADR146	30399.6	\N
2022-04-01	LM_WOD_ADR148	0.05	\N
2022-04-01	LM_WOD_ADR150	41.69	\N
2022-04-01	LM_WOD_ADR237	924.01	\N
2022-04-01	LM_WOD_ADR238	2523.19	\N
2022-04-01	LM_WOD_ADR239	34.71	\N
2022-04-01	LM_WOD_ADR240	132.77	\N
2022-04-01	LM_WOD_ADR241	129.16	\N
2022-04-01	LM_ELE_ADR121	195389.77	\N
2022-04-01	LM_ELE_ADR128	0	\N
2022-04-01	LM_WOD_ADR247_Solution Space	575.25	\N
2022-04-01	LM_WOD_ADR250_Solution Space	201.8	\N
2022-04-01	LM_WOD_ADR30	0	\N
2022-04-01	LM_ELE_ADR001	67985.07	\N
2022-04-01	LM_ELE_ADR002	89203.39	\N
2022-04-01	LM_ELE_ADR003	121408.7	\N
2022-04-01	LM_ELE_ADR006	0	\N
2022-04-01	LM_ELE_ADR007	141611.14	\N
2022-04-01	LM_ELE_ADR009	183606.16	\N
2022-04-01	LM_ELE_ADR011	167799.08	\N
2022-04-01	LM_ELE_ADR013	223925.5	\N
2022-04-01	LM_ELE_ADR014	14614.84	\N
2022-04-01	LM_ELE_ADR015	131713.36	\N
2022-04-01	LM_ELE_ADR016	939551.75	\N
2022-04-01	LM_ELE_ADR018	13189.93	\N
2022-04-01	LM_ELE_ADR020	137552.64	\N
2022-04-01	LM_ELE_ADR022	156802.69	\N
2022-04-01	LM_ELE_ADR023	33777.39	\N
2022-04-01	LM_ELE_ADR025	525948.56	\N
2022-04-01	LM_ELE_ADR028	19343.6	\N
2022-04-01	LM_ELE_ADR034	28718.52	\N
2022-04-01	LM_ELE_ADR036	90925.55	\N
2022-04-01	LM_ELE_ADR039	367002.13	\N
2022-04-01	LM_ELE_ADR040	36311.37	\N
2022-04-01	LM_ELE_ADR042	3495.41	\N
2022-04-01	LM_ELE_ADR044	6766.31	\N
2022-04-01	LM_ELE_ADR048	7122.83	\N
2022-04-01	LM_ELE_ADR051	6833.06	\N
2022-04-01	LM_ELE_ADR053	24089.09	\N
2022-04-01	LM_ELE_ADR055	5636.67	\N
2022-04-01	LM_ELE_ADR056	21963.17	\N
2022-04-01	LM_ELE_ADR063	190	\N
2022-04-01	LM_ELE_ADR064	0	\N
2022-04-01	LM_ELE_ADR058	82381.25	\N
2022-04-01	LM_ELE_ADR072	26434	\N
2022-04-01	LM_ELE_ADR074	78744	\N
2022-04-01	LM_ELE_ADR076	0	\N
2022-04-01	LM_ELE_ADR081	62465.91	\N
2022-04-01	LM_ELE_ADR085	55790.04	\N
2022-04-01	LM_ELE_ADR090	38053.16	\N
2022-04-01	LM_ELE_ADR107	84886.65	\N
2022-04-01	LM_ELE_ADR108	6508.1	\N
2022-04-01	LM_ELE_ADR109	2015.9	\N
2022-04-01	LM_ELE_ADR110	412.82	\N
2022-04-01	LM_ELE_ADR113	53932.97	\N
2022-04-01	LM_ELE_ADR087	88907.2	\N
2022-04-01	LM_LC_ADR_B45	213.85	\N
2022-04-01	LM_LH_ADR_B46	49.35	\N
2022-04-01	LM_LH_ADR_B47	118.8	\N
2022-04-01	LM_WOD_ADR_B74	35.81	\N
2022-04-01	LM_ELE_ADR_B06	464107.69	\N
2022-04-01	LM_ELE_ADR046	0	\N
2022-04-01	LM_ELE_ADR010	118763.17	\N
2022-04-01	LM_ELE_ADR043	2808.8	\N
2022-04-01	LM_ELE_ADR_B11	33012.06	\N
2022-04-01	LM_WOD_ADR242	42.71	\N
2022-04-01	LM_ELE_ADR124	104475.61	\N
2022-04-01	LM_ELE_ADR112	721506.81	\N
2022-04-01	LM_WOD_ADR_B75	181.24	\N
2022-04-01	LM_ELE_ADR091	12029.86	\N
2022-04-01	LM_WOD_ADR_B80	123.46	\N
2022-04-01	LM_WOD_ADR_B81	43.51	\N
2022-04-01	LM_ELE_ADR_B04	280562.19	\N
2022-04-01	LM_ELE_ADR_B05	245753.11	\N
2022-04-01	LM_ELE_ADR_B09	296830.09	\N
2022-04-01	LM_ELE_ADR_B01	0	\N
2022-04-01	LM_ELE_ADR_B10	30132.73	\N
2022-04-01	LM_ELE_ADR_B02	0	\N
2022-04-01	LM_LC_ADR_B18	18.43	\N
2022-04-01	LM_LC_ADR_B20	69.51	\N
2022-04-01	LM_LC_ADR_B22	55.37	\N
2022-04-01	LM_LC_ADR_B24	10.66	\N
2022-04-01	LM_LC_ADR_B31	445.1	\N
2022-04-01	LM_LC_ADR_B41	509.9	\N
2022-04-01	LM_LC_ADR_B43	8.4	\N
2022-04-01	LM_LH_ADR_B23	68.3	\N
2022-04-01	LM_LH_ADR_B25	61.1	\N
2022-04-01	LM_LH_ADR_B27	146.7	\N
2022-04-01	LM_LH_ADR_B35	0	\N
2022-04-01	LM_LH_ADR_B36	0	\N
2022-04-01	LM_LH_ADR_B38	72.3	\N
2022-04-01	LM_LH_ADR_B44	4.5	\N
2022-04-01	LM_WOD_ADR_B76	1736.79	\N
2022-04-01	LM_WOD_ADR_B77	8.96	\N
2022-04-01	LM_LC_ADR_B16	38.82	\N
2022-04-01	LM_LH_ADR_B17	50.3	\N
2022-04-01	LM_WOD_ADR_B79	360.11	\N
2022-04-01	LM_ELE_ADR_B12	18207.51	\N
2022-04-01	LM_ELE_ADR_B13	15053.19	\N
2022-04-01	LM_LC_ADR_B46	56.4	\N
2022-04-01	LM_LC_ADR193	0	\N
2022-04-01	LM_ELE_ADR125	4948.6	\N
2022-04-01	LM_ELE_ADR069	299740	\N
2022-04-01	LM_ELE_ADR075	10852	\N
2022-04-01	LM_LC_ADR159	5030	\N
2022-04-01	LM_LC_ADR160	11180	\N
2022-04-01	zdemontowany580	6	\N
2022-04-01	zdemontowany600	3194	\N
2022-04-01	LM_LH_ADR229	84.9	\N
2022-05-01	LM_LC_ADR170	57.36	\N
2022-05-01	LM_LC_ADR172	134.96	\N
2022-05-01	LM_LC_ADR179	88.1	\N
2022-05-01	LM_ELE_ADR021	284290.44	\N
2022-05-01	LM_ELE_ADR078	55609	\N
2022-05-01	LM_ELE_ADR066	0	\N
2022-05-01	LM_ELE_ADR080	175085.22	\N
2022-05-01	LM_LH_ADR199	146.7	\N
2022-05-01	LM_ELE_ADR115	27049.53	\N
2022-05-01	LM_WOD_ADR249_Solution Space	109.94	\N
2022-05-01	LM_WOD_MAIN_W	0	\N
2022-05-01	LM_LC_ADR123	544.7	\N
2022-05-01	LM_LC_ADR151	31238	\N
2022-05-01	LM_LC_ADR153	10605	\N
2022-05-01	LM_LC_ADR154	2724.4	\N
2022-05-01	LM_LC_ADR155	7184.8	\N
2022-05-01	LM_LC_ADR157	1130.9	\N
2022-05-01	LM_LC_ADR158	369.7	\N
2022-05-01	LM_LC_ADR162	811.4	\N
2022-05-01	LM_LC_ADR168	120.4	\N
2022-05-01	LM_LC_ADR173	102.73	\N
2022-05-01	LM_LC_ADR174	218.74	\N
2022-05-01	LM_LC_ADR175	0	\N
2022-05-01	LM_LC_ADR176	85.7	\N
2022-05-01	LM_LC_ADR178	140.75	\N
2022-05-01	LM_LC_ADR184	45.06	\N
2022-05-01	LM_LC_ADR186	19.23	\N
2022-05-01	LM_LC_ADR187	32.69	\N
2022-05-01	LM_LC_ADR209	96.95	\N
2022-05-01	LM_LC_ADR82	29.39	\N
2022-05-01	LM_LH_ADR122	16.5	\N
2022-05-01	LM_LH_ADR189	60.9	\N
2022-05-01	LM_LH_ADR195	437.7	\N
2022-05-01	LM_LH_ADR196	9	\N
2022-05-01	LM_LH_ADR198	1261.5	\N
2022-05-01	LM_LH_ADR200	48.1	\N
2022-05-01	LM_LH_ADR203	224.4	\N
2022-05-01	LM_LH_ADR204	102.5	\N
2022-05-01	LM_LH_ADR208	327.5	\N
2022-05-01	LM_LH_ADR211	39.7	\N
2022-05-01	LM_LH_ADR212	202	\N
2022-05-01	LM_LH_ADR216	36.68	\N
2022-05-01	LM_LH_ADR218	442	\N
2022-05-01	LM_LH_ADR221	359.8	\N
2022-05-01	LM_LH_ADR222	0	\N
2022-05-01	LM_LH_ADR227	41.2	\N
2022-05-01	LM_LH_ADR229	0	\N
2022-05-01	LM_LH_ADR231	0	\N
2022-05-01	LM_LH_ADR234	0	\N
2022-05-01	LM_LH_ADR235	87.5	\N
2022-05-01	LM_LH_ADR33	0	\N
2022-05-01	LM_ELE_ADR008	104387.92	\N
2022-05-01	LM_ELE_ADR012	93689.1	\N
2022-05-01	LM_ELE_ADR017	13060.93	\N
2022-05-01	LM_ELE_ADR019	4038.56	\N
2022-05-01	LM_ELE_ADR024	128487.45	\N
2022-05-01	LM_ELE_ADR027	36284.19	\N
2022-05-01	LM_LC_ADR163	31.06	\N
2022-05-01	LM_LC_ADR164	0.02	\N
2022-05-01	LM_LH_ADR201	96	\N
2022-05-01	LM_ELE_ADR029	13886.41	\N
2022-05-01	LM_ELE_ADR031	192171.02	\N
2022-05-01	LM_ELE_ADR038	371132.25	\N
2022-05-01	LM_ELE_ADR041	68303.02	\N
2022-05-01	LM_ELE_ADR045	6028.42	\N
2022-05-01	LM_ELE_ADR047	5469.66	\N
2022-05-01	LM_ELE_ADR049	14863.12	\N
2022-05-01	LM_ELE_ADR052	11254.79	\N
2022-05-01	LM_ELE_ADR054	31233.31	\N
2022-05-01	LM_ELE_ADR057	6197.41	\N
2022-05-01	LM_ELE_ADR059	24139.2	\N
2022-05-01	LM_ELE_ADR060	0	\N
2022-05-01	LM_ELE_ADR061	0	\N
2022-05-01	LM_ELE_ADR062	22939	\N
2022-05-01	LM_ELE_ADR065	0	\N
2022-05-01	LM_ELE_ADR067	266	\N
2022-05-01	LM_ELE_ADR068	9044	\N
2022-05-01	LM_ELE_ADR070	88	\N
2022-05-01	LM_ELE_ADR071	81075	\N
2022-05-01	LM_ELE_ADR073	88	\N
2022-05-01	LM_ELE_ADR077	1063	\N
2022-05-01	LM_ELE_ADR084	56037.26	\N
2022-05-01	LM_ELE_ADR086	15372.26	\N
2022-05-01	LM_ELE_ADR088	40069.15	\N
2022-05-01	LM_ELE_ADR094	1491.13	\N
2022-05-01	LM_ELE_ADR095	103949.59	\N
2022-05-01	LM_ELE_ADR097	33045.06	\N
2022-05-01	LM_ELE_ADR098	3568.5	\N
2022-05-01	LM_ELE_ADR099	86102.52	\N
2022-05-01	LM_ELE_ADR100	19275.93	\N
2022-05-01	LM_ELE_ADR101	8009.68	\N
2022-05-01	LM_ELE_ADR111	362.62	\N
2022-05-01	LM_ELE_ADR116	15111.47	\N
2022-05-01	LM_ELE_ADR118	21344.06	\N
2022-05-01	LM_ELE_ADR119	76554.36	\N
2022-05-01	LM_ELE_ADR120	91540.93	\N
2022-05-01	LM_WOD_ADR129	123.09	\N
2022-05-01	LM_WOD_ADR140	123.01	\N
2022-05-01	LM_WOD_ADR147	61.87	\N
2022-05-01	LM_WOD_ADR246_Solution Space	562.39	\N
2022-05-01	LM_WOD_ADR248_Solution Space	48.27	\N
2022-05-01	LM_ELE_ADR_B03	130512.45	\N
2022-05-01	LM_ELE_ADR_B07	103733.95	\N
2022-05-01	LM_ELE_ADR_B08	154235.86	\N
2022-05-01	LM_LC_ADR_B26	170.99	\N
2022-05-01	LM_LC_ADR_B30	449.5	\N
2022-05-01	LM_LC_ADR_B32	989.8	\N
2022-05-01	LM_LC_ADR_B33	894.3	\N
2022-05-01	LM_LH_ADR_B19	103.2	\N
2022-05-01	LM_LH_ADR_B21	199.5	\N
2022-05-01	LM_LH_ADR_B34	0	\N
2022-05-01	LM_LH_ADR_B37	0.4	\N
2022-05-01	LM_LH_ADR_B39	98	\N
2022-05-01	LM_LH_ADR_B40	165.1	\N
2022-05-01	LM_LH_ADR_B42	0	\N
2022-05-01	LM_WOD_ADR_B78	192.83	\N
2022-05-01	LM_LC_ADR102	55.3	\N
2022-05-01	LM_LC_ADR103	60.94	\N
2022-05-01	LM_LC_ADR104	82.38	\N
2022-05-01	LM_LC_ADR152	5133	\N
2022-05-01	LM_LC_ADR149	0.91	\N
2022-05-01	LM_LC_ADR156	3645.1	\N
2022-05-01	LM_LC_ADR171	306.52	\N
2022-05-01	LM_LC_ADR165	51.04	\N
2022-05-01	LM_LC_ADR166	40.06	\N
2022-05-01	LM_LC_ADR180	147.99	\N
2022-05-01	LM_LC_ADR181	0.1	\N
2022-05-01	LM_LC_ADR182	93.39	\N
2022-05-01	LM_LC_ADR183	1.42	\N
2022-05-01	LM_LC_ADR185	19.25	\N
2022-05-01	LM_LC_ADR161	1480.9	\N
2022-05-01	LM_LC_ADR224	173.85	\N
2022-05-01	LM_LC_ADR89	39.45	\N
2022-05-01	LM_LC_ADR93	38.97	\N
2022-05-01	LM_LH_ADR145	10.07	\N
2022-05-01	LM_LH_ADR188	32.18	\N
2022-05-01	LM_LH_ADR190	7.89	\N
2022-05-01	LM_LH_ADR191	18.8	\N
2022-05-01	LM_LH_ADR192	0	\N
2022-05-01	LM_LH_ADR194	0	\N
2022-05-01	LM_LH_ADR207	421	\N
2022-05-01	LM_LH_ADR197	1284.4	\N
2022-05-01	LM_LH_ADR215	0	\N
2022-05-01	LM_LH_ADR219	0.03	\N
2022-05-01	LM_LH_ADR220	112.2	\N
2022-05-01	LM_LH_ADR223	190.9	\N
2022-05-01	LM_LH_ADR225	71.6	\N
2022-05-01	LM_LH_ADR226	83.69	\N
2022-05-01	LM_LH_ADR217	510.2	\N
2022-05-01	LM_LH_ADR228	29.9	\N
2022-05-01	LM_LH_ADR232	60.48	\N
2022-05-01	LM_LH_ADR233	46	\N
2022-05-01	LM_LH_ADR230	1.7	\N
2022-05-01	LM_ELE_ADR114	284250.81	\N
2022-05-01	LM_ELE_ADR117	22617.56	\N
2022-05-01	LM_WOD_ADR132	304.21	\N
2022-05-01	LM_WOD_ADR133	350.54	\N
2022-05-01	LM_WOD_ADR134	18.87	\N
2022-05-01	LM_WOD_ADR135	0	\N
2022-05-01	LM_WOD_ADR136	70.88	\N
2022-05-01	LM_WOD_ADR139	1483.48	\N
2022-05-01	LM_WOD_ADR141	17	\N
2022-05-01	LM_WOD_ADR142	36	\N
2022-05-01	LM_WOD_ADR143	557.39	\N
2022-05-01	LM_WOD_ADR146	30945.6	\N
2022-05-01	LM_WOD_ADR148	0.02	\N
2022-05-01	LM_WOD_ADR150	42.57	\N
2022-05-01	LM_WOD_ADR237	924.28	\N
2022-05-01	LM_WOD_ADR238	2543.96	\N
2022-05-01	LM_WOD_ADR239	36.19	\N
2022-05-01	LM_WOD_ADR240	139.03	\N
2022-05-01	LM_WOD_ADR241	168.18	\N
2022-05-01	LM_ELE_ADR121	206125.86	\N
2022-05-01	LM_ELE_ADR128	0	\N
2022-05-01	LM_WOD_ADR247_Solution Space	600.83	\N
2022-05-01	LM_WOD_ADR250_Solution Space	208.11	\N
2022-05-01	LM_WOD_ADR30	0	\N
2022-05-01	LM_ELE_ADR001	69794.89	\N
2022-05-01	LM_ELE_ADR002	90834.27	\N
2022-05-01	LM_ELE_ADR003	122790.72	\N
2022-05-01	LM_ELE_ADR006	0	\N
2022-05-01	LM_ELE_ADR007	143000.38	\N
2022-05-01	LM_ELE_ADR009	191555.8	\N
2022-05-01	LM_ELE_ADR011	174874.69	\N
2022-05-01	LM_ELE_ADR013	230167.98	\N
2022-05-01	LM_ELE_ADR014	15032.82	\N
2022-05-01	LM_ELE_ADR015	134669.66	\N
2022-05-01	LM_ELE_ADR016	957208.44	\N
2022-05-01	LM_ELE_ADR018	13461.68	\N
2022-05-01	LM_ELE_ADR020	139931.41	\N
2022-05-01	LM_ELE_ADR022	164685.34	\N
2022-05-01	LM_ELE_ADR023	35150.33	\N
2022-05-01	LM_ELE_ADR025	557444.75	\N
2022-05-01	LM_ELE_ADR028	19603.88	\N
2022-05-01	LM_ELE_ADR034	29979.99	\N
2022-05-01	LM_ELE_ADR036	92688.02	\N
2022-05-01	LM_ELE_ADR039	376073.91	\N
2022-05-01	LM_ELE_ADR040	36656.9	\N
2022-05-01	LM_ELE_ADR042	3562.77	\N
2022-05-01	LM_ELE_ADR044	6887.94	\N
2022-05-01	LM_ELE_ADR048	7248.93	\N
2022-05-01	LM_ELE_ADR051	6957.29	\N
2022-05-01	LM_ELE_ADR053	26274.24	\N
2022-05-01	LM_ELE_ADR055	5742.39	\N
2022-05-01	LM_ELE_ADR056	0	\N
2022-05-01	LM_ELE_ADR063	190	\N
2022-05-01	LM_ELE_ADR064	0	\N
2022-05-01	LM_ELE_ADR058	83960.37	\N
2022-05-01	LM_ELE_ADR072	27267	\N
2022-05-01	LM_ELE_ADR074	81075	\N
2022-05-01	LM_ELE_ADR076	0	\N
2022-05-01	LM_ELE_ADR081	66878.66	\N
2022-05-01	LM_ELE_ADR085	58201.61	\N
2022-05-01	LM_ELE_ADR090	39702.84	\N
2022-05-01	LM_ELE_ADR107	87654.19	\N
2022-05-01	LM_ELE_ADR108	6649.51	\N
2022-05-01	LM_ELE_ADR109	2016.21	\N
2022-05-01	LM_ELE_ADR110	414.14	\N
2022-05-01	LM_ELE_ADR113	55051.66	\N
2022-05-01	LM_ELE_ADR087	90269.49	\N
2022-05-01	LM_LC_ADR_B45	220.88	\N
2022-05-01	LM_LH_ADR_B46	49.35	\N
2022-05-01	LM_LH_ADR_B47	120	\N
2022-05-01	LM_WOD_ADR_B74	36.96	\N
2022-05-01	LM_ELE_ADR_B06	476119.75	\N
2022-05-01	LM_ELE_ADR046	0	\N
2022-05-01	LM_ELE_ADR010	120885.59	\N
2022-05-01	LM_ELE_ADR043	2869.1	\N
2022-05-01	LM_ELE_ADR_B11	33946.3	\N
2022-05-01	LM_WOD_ADR242	43.47	\N
2022-05-01	LM_ELE_ADR124	110786.2	\N
2022-05-01	LM_ELE_ADR112	734826	\N
2022-05-01	LM_WOD_ADR_B75	182.98	\N
2022-05-01	LM_ELE_ADR091	12433.91	\N
2022-05-01	LM_WOD_ADR_B80	127.51	\N
2022-05-01	LM_WOD_ADR_B81	44.68	\N
2022-05-01	LM_ELE_ADR_B04	283434.06	\N
2022-05-01	LM_ELE_ADR_B05	251748.33	\N
2022-05-01	LM_ELE_ADR_B09	301870.78	\N
2022-05-01	LM_ELE_ADR_B01	0	\N
2022-05-01	LM_ELE_ADR_B10	30829.07	\N
2022-05-01	LM_ELE_ADR_B02	0	\N
2022-05-01	LM_LC_ADR_B18	18.69	\N
2022-05-01	LM_LC_ADR_B20	69.74	\N
2022-05-01	LM_LC_ADR_B22	56.38	\N
2022-05-01	LM_LC_ADR_B24	10.66	\N
2022-05-01	LM_LC_ADR_B31	461.9	\N
2022-05-01	LM_LC_ADR_B41	525.1	\N
2022-05-01	LM_LC_ADR_B43	8.8	\N
2022-05-01	LM_LH_ADR_B23	69.9	\N
2022-05-01	LM_LH_ADR_B25	65.6	\N
2022-05-01	LM_LH_ADR_B27	160.9	\N
2022-05-01	LM_LH_ADR_B35	0	\N
2022-05-01	LM_LH_ADR_B36	0	\N
2022-05-01	LM_LH_ADR_B38	72.5	\N
2022-05-01	LM_LH_ADR_B44	4.5	\N
2022-05-01	LM_WOD_ADR_B76	1736.79	\N
2022-05-01	LM_WOD_ADR_B77	8.96	\N
2022-05-01	LM_LC_ADR_B16	38.82	\N
2022-05-01	LM_LH_ADR_B17	51.1	\N
2022-05-01	LM_WOD_ADR_B79	360.11	\N
2022-05-01	LM_ELE_ADR_B12	18656.4	\N
2022-05-01	LM_ELE_ADR_B13	15053.19	\N
2022-05-01	LM_LC_ADR_B46	58.62	\N
2022-05-01	LM_LC_ADR193	0	\N
2022-05-01	LM_ELE_ADR125	5015.07	\N
2022-05-01	LM_ELE_ADR069	306807	\N
2022-05-01	LM_ELE_ADR075	11167	\N
2022-05-01	LM_LC_ADR159	5030	\N
2022-05-01	LM_LC_ADR160	12630	\N
2022-05-01	LM_LH_ADR167	2050	\N
2022-05-01	LM_WOD_ADR236	12.91	\N
2022-05-01	zdemontowany580	6	\N
2022-05-01	zdemontowany600	3194	\N
2022-06-01	LM_LC_ADR170	57.38	\N
2022-06-01	LM_LC_ADR172	136.07	\N
2022-06-01	LM_LC_ADR179	88.4	\N
2022-06-01	LM_ELE_ADR021	287369.66	\N
2022-06-01	LM_ELE_ADR078	56598	\N
2022-06-01	LM_ELE_ADR066	0	\N
2022-06-01	LM_ELE_ADR080	177349.31	\N
2022-06-01	LM_LH_ADR199	147.4	\N
2022-06-01	LM_ELE_ADR115	27662.35	\N
2022-06-01	LM_WOD_ADR249_Solution Space	113.02	\N
2022-06-01	LM_WOD_MAIN_W	0	\N
2022-06-01	LM_LC_ADR123	546.6	\N
2022-06-01	LM_LC_ADR151	31348	\N
2022-06-01	LM_LC_ADR153	10636	\N
2022-06-01	LM_LC_ADR154	2748.5	\N
2022-06-01	LM_LC_ADR155	7211.5	\N
2022-06-01	LM_LC_ADR157	1135	\N
2022-06-01	LM_LC_ADR158	370.7	\N
2022-06-01	LM_LC_ADR162	812.7	\N
2022-06-01	LM_LC_ADR168	120.5	\N
2022-06-01	LM_LC_ADR173	103.21	\N
2022-06-01	LM_LC_ADR174	222.82	\N
2022-06-01	LM_LC_ADR175	0	\N
2022-06-01	LM_LC_ADR176	85.9	\N
2022-06-01	LM_LC_ADR178	142.36	\N
2022-06-01	LM_LC_ADR184	45.23	\N
2022-06-01	LM_LC_ADR186	19.23	\N
2022-06-01	LM_LC_ADR187	32.69	\N
2022-06-01	LM_LC_ADR209	96.95	\N
2022-06-01	LM_LC_ADR32	0	\N
2022-06-01	LM_LC_ADR82	30.52	\N
2022-06-01	LM_LH_ADR122	17.9	\N
2022-06-01	LM_LH_ADR189	61.71	\N
2022-06-01	LM_LH_ADR195	442.1	\N
2022-06-01	LM_LH_ADR196	9	\N
2022-06-01	LM_LH_ADR198	1285.3	\N
2022-06-01	LM_LH_ADR200	49.1	\N
2022-06-01	LM_LH_ADR203	226.3	\N
2022-06-01	LM_LH_ADR204	104.2	\N
2022-06-01	LM_LH_ADR208	333.5	\N
2022-06-01	LM_LH_ADR211	41.1	\N
2022-06-01	LM_LH_ADR212	210.1	\N
2022-06-01	LM_LH_ADR216	36.68	\N
2022-06-01	LM_LH_ADR218	452.2	\N
2022-06-01	LM_LH_ADR221	372.3	\N
2022-06-01	LM_LH_ADR222	0	\N
2022-06-01	LM_LH_ADR227	41.2	\N
2022-06-01	LM_LH_ADR229	0	\N
2022-06-01	LM_LH_ADR231	0	\N
2022-06-01	LM_LH_ADR234	0	\N
2022-06-01	LM_LH_ADR235	88.9	\N
2022-06-01	LM_LH_ADR33	0	\N
2022-06-01	LM_ELE_ADR008	105849.91	\N
2022-06-01	LM_ELE_ADR012	94597.81	\N
2022-06-01	LM_ELE_ADR017	13267.13	\N
2022-06-01	LM_ELE_ADR019	4038.56	\N
2022-06-01	LM_ELE_ADR024	130399.06	\N
2022-06-01	LM_ELE_ADR027	36475.91	\N
2022-06-01	LM_LC_ADR163	31.06	\N
2022-06-01	LM_LC_ADR164	0.02	\N
2022-06-01	LM_LH_ADR201	100.7	\N
2022-06-01	LM_ELE_ADR029	14262.2	\N
2022-06-01	LM_ELE_ADR031	194718.31	\N
2022-06-01	LM_ELE_ADR038	377873.16	\N
2022-06-01	LM_ELE_ADR041	68877.95	\N
2022-06-01	LM_ELE_ADR045	6134.91	\N
2022-06-01	LM_ELE_ADR047	5503.58	\N
2022-06-01	LM_ELE_ADR049	15040.74	\N
2022-06-01	LM_ELE_ADR052	11401.46	\N
2022-06-01	LM_ELE_ADR054	31616.32	\N
2022-06-01	LM_ELE_ADR057	6281.51	\N
2022-06-01	LM_ELE_ADR059	24532.34	\N
2022-06-01	LM_ELE_ADR060	0	\N
2022-06-01	LM_ELE_ADR061	0	\N
2022-06-01	LM_ELE_ADR062	23518	\N
2022-06-01	LM_ELE_ADR065	0	\N
2022-06-01	LM_ELE_ADR067	266	\N
2022-06-01	LM_ELE_ADR068	9957	\N
2022-06-01	LM_ELE_ADR070	88	\N
2022-06-01	LM_ELE_ADR071	82597	\N
2022-06-01	LM_ELE_ADR073	88	\N
2022-06-01	LM_ELE_ADR077	1063	\N
2022-06-01	LM_ELE_ADR084	56602.41	\N
2022-06-01	LM_ELE_ADR086	15778.74	\N
2022-06-01	LM_ELE_ADR088	40777.64	\N
2022-06-01	LM_ELE_ADR094	1493.89	\N
2022-06-01	LM_ELE_ADR095	105679.88	\N
2022-06-01	LM_ELE_ADR097	33997.25	\N
2022-06-01	LM_ELE_ADR098	3626.88	\N
2022-06-01	LM_ELE_ADR099	88164.2	\N
2022-06-01	LM_ELE_ADR100	19656.19	\N
2022-06-01	LM_ELE_ADR101	8167.63	\N
2022-06-01	LM_ELE_ADR111	362.62	\N
2022-06-01	LM_ELE_ADR116	15133.64	\N
2022-06-01	LM_ELE_ADR118	21585.51	\N
2022-06-01	LM_ELE_ADR119	77653.16	\N
2022-06-01	LM_ELE_ADR120	93691.69	\N
2022-06-01	LM_WOD_ADR129	126.06	\N
2022-06-01	LM_WOD_ADR140	123.31	\N
2022-06-01	LM_WOD_ADR147	62.6	\N
2022-06-01	LM_WOD_ADR246_Solution Space	576.41	\N
2022-06-01	LM_WOD_ADR248_Solution Space	49.99	\N
2022-06-01	LM_ELE_ADR_B03	132042.22	\N
2022-06-01	LM_ELE_ADR_B07	105023.56	\N
2022-06-01	LM_ELE_ADR_B08	156166.81	\N
2022-06-01	LM_LC_ADR_B26	171.13	\N
2022-06-01	LM_LC_ADR_B30	451.1	\N
2022-06-01	LM_LC_ADR_B32	993.1	\N
2022-06-01	LM_LC_ADR_B33	897.7	\N
2022-06-01	LM_LH_ADR_B19	104.9	\N
2022-06-01	LM_LH_ADR_B21	202.4	\N
2022-06-01	LM_LH_ADR_B34	0	\N
2022-06-01	LM_LH_ADR_B37	0.4	\N
2022-06-01	LM_LH_ADR_B39	99.6	\N
2022-06-01	LM_LH_ADR_B40	167.9	\N
2022-06-01	LM_LH_ADR_B42	0	\N
2022-06-01	LM_WOD_ADR_B78	194.81	\N
2022-06-01	LM_LC_ADR102	55.83	\N
2022-06-01	LM_LC_ADR103	61.51	\N
2022-06-01	LM_LC_ADR104	83.3	\N
2022-06-01	LM_LC_ADR152	5148.2	\N
2022-06-01	LM_LC_ADR149	0.91	\N
2022-06-01	LM_LC_ADR156	3666.6	\N
2022-06-01	LM_LC_ADR171	307.82	\N
2022-06-01	LM_LC_ADR165	51.62	\N
2022-06-01	LM_LC_ADR166	40.47	\N
2022-06-01	LM_LC_ADR180	147.99	\N
2022-06-01	LM_LC_ADR181	0.1	\N
2022-06-01	LM_LC_ADR182	93.4	\N
2022-06-01	LM_LC_ADR183	1.42	\N
2022-06-01	LM_LC_ADR185	19.25	\N
2022-06-01	LM_LC_ADR161	1486.6	\N
2022-06-01	LM_LC_ADR224	175.72	\N
2022-06-01	LM_LC_ADR89	39.93	\N
2022-06-01	LM_LC_ADR93	39.45	\N
2022-06-01	LM_LH_ADR145	10.07	\N
2022-06-01	LM_LH_ADR188	32.18	\N
2022-06-01	LM_LH_ADR190	7.89	\N
2022-06-01	LM_LH_ADR191	18.8	\N
2022-06-01	LM_LH_ADR192	0	\N
2022-06-01	LM_LH_ADR194	0	\N
2022-06-01	LM_LH_ADR207	424.2	\N
2022-06-01	LM_LH_ADR197	1297	\N
2022-06-01	LM_LH_ADR215	0	\N
2022-06-01	LM_LH_ADR219	0.03	\N
2022-06-01	LM_LH_ADR220	112.2	\N
2022-06-01	LM_LH_ADR223	196.3	\N
2022-06-01	LM_LH_ADR225	71.6	\N
2022-06-01	LM_LH_ADR226	83.76	\N
2022-06-01	LM_LH_ADR217	517.4	\N
2022-06-01	LM_LH_ADR228	30.7	\N
2022-06-01	LM_LH_ADR232	61.68	\N
2022-06-01	LM_LH_ADR233	46.6	\N
2022-06-01	LM_LH_ADR230	1.7	\N
2022-06-01	LM_ELE_ADR114	289638.25	\N
2022-06-01	LM_ELE_ADR117	22632.71	\N
2022-06-01	LM_WOD_ADR132	308.09	\N
2022-06-01	LM_WOD_ADR133	353.89	\N
2022-06-01	LM_WOD_ADR134	18.95	\N
2022-06-01	LM_WOD_ADR135	0	\N
2022-06-01	LM_WOD_ADR136	71.56	\N
2022-06-01	LM_WOD_ADR139	1522.08	\N
2022-06-01	LM_WOD_ADR141	17	\N
2022-06-01	LM_WOD_ADR142	36	\N
2022-06-01	LM_WOD_ADR143	580.05	\N
2022-06-01	LM_WOD_ADR146	31510.4	\N
2022-06-01	LM_WOD_ADR148	0.03	\N
2022-06-01	LM_WOD_ADR150	43.27	\N
2022-06-01	LM_WOD_ADR237	924.46	\N
2022-06-01	LM_WOD_ADR238	2543.96	\N
2022-06-01	LM_WOD_ADR239	36.8	\N
2022-06-01	LM_WOD_ADR240	143.85	\N
2022-06-01	LM_WOD_ADR241	233.29	\N
2022-06-01	LM_ELE_ADR121	213389.63	\N
2022-06-01	LM_ELE_ADR128	0	\N
2022-06-01	LM_WOD_ADR247_Solution Space	617.78	\N
2022-06-01	LM_WOD_ADR250_Solution Space	213.19	\N
2022-06-01	LM_WOD_ADR30	0	\N
2022-06-01	LM_ELE_ADR001	70882.25	\N
2022-06-01	LM_ELE_ADR002	91919.29	\N
2022-06-01	LM_ELE_ADR003	124008.52	\N
2022-06-01	LM_ELE_ADR006	0	\N
2022-06-01	LM_ELE_ADR007	143716.09	\N
2022-06-01	LM_ELE_ADR009	195924.27	\N
2022-06-01	LM_ELE_ADR011	177425.91	\N
2022-06-01	LM_ELE_ADR013	234331.38	\N
2022-06-01	LM_ELE_ADR014	15295.71	\N
2022-06-01	LM_ELE_ADR015	136655.91	\N
2022-06-01	LM_ELE_ADR016	966111.38	\N
2022-06-01	LM_ELE_ADR018	13649.89	\N
2022-06-01	LM_ELE_ADR020	141309.42	\N
2022-06-01	LM_ELE_ADR022	169589.16	\N
2022-06-01	LM_ELE_ADR023	36072.65	\N
2022-06-01	LM_ELE_ADR025	577498.19	\N
2022-06-01	LM_ELE_ADR028	19785.33	\N
2022-06-01	LM_ELE_ADR034	30853.19	\N
2022-06-01	LM_ELE_ADR036	93461.22	\N
2022-06-01	LM_ELE_ADR039	380373	\N
2022-06-01	LM_ELE_ADR040	36656.9	\N
2022-06-01	LM_ELE_ADR042	3609.07	\N
2022-06-01	LM_ELE_ADR044	6975.3	\N
2022-06-01	LM_ELE_ADR048	7341.33	\N
2022-06-01	LM_ELE_ADR051	7043.83	\N
2022-06-01	LM_ELE_ADR053	27811.23	\N
2022-06-01	LM_ELE_ADR055	5816.13	\N
2022-06-01	LM_ELE_ADR056	0	\N
2022-06-01	LM_ELE_ADR063	190	\N
2022-06-01	LM_ELE_ADR064	0	\N
2022-06-01	LM_ELE_ADR058	85061.02	\N
2022-06-01	LM_ELE_ADR072	27851	\N
2022-06-01	LM_ELE_ADR074	82597	\N
2022-06-01	LM_ELE_ADR076	0	\N
2022-06-01	LM_ELE_ADR081	68469.75	\N
2022-06-01	LM_ELE_ADR085	59896.44	\N
2022-06-01	LM_ELE_ADR090	40898.86	\N
2022-06-01	LM_ELE_ADR107	89415.07	\N
2022-06-01	LM_ELE_ADR108	6939.94	\N
2022-06-01	LM_ELE_ADR109	2016.79	\N
2022-06-01	LM_ELE_ADR110	414.46	\N
2022-06-01	LM_ELE_ADR113	55983.84	\N
2022-06-01	LM_ELE_ADR087	91239.62	\N
2022-06-01	LM_LC_ADR_B45	222.2	\N
2022-06-01	LM_LH_ADR_B46	49.35	\N
2022-06-01	LM_LH_ADR_B47	122	\N
2022-06-01	LM_WOD_ADR_B74	37.85	\N
2022-06-01	LM_ELE_ADR_B06	488731.34	\N
2022-06-01	LM_ELE_ADR046	0	\N
2022-06-01	LM_ELE_ADR010	122330.97	\N
2022-06-01	LM_ELE_ADR043	2910.78	\N
2022-06-01	LM_ELE_ADR_B11	34595.72	\N
2022-06-01	LM_WOD_ADR242	44.22	\N
2022-06-01	LM_ELE_ADR124	115237.59	\N
2022-06-01	LM_ELE_ADR112	740775	\N
2022-06-01	LM_WOD_ADR_B75	184.58	\N
2022-06-01	LM_ELE_ADR091	12715.05	\N
2022-06-01	LM_WOD_ADR_B80	130.56	\N
2022-06-01	LM_WOD_ADR_B81	45.64	\N
2022-06-01	LM_ELE_ADR_B04	283892.09	\N
2022-06-01	LM_ELE_ADR_B05	258105.33	\N
2022-06-01	LM_ELE_ADR_B09	304934.66	\N
2022-06-01	LM_ELE_ADR_B01	0	\N
2022-06-01	LM_ELE_ADR_B10	31313.13	\N
2022-06-01	LM_ELE_ADR_B02	0	\N
2022-06-01	LM_LC_ADR_B18	18.78	\N
2022-06-01	LM_LC_ADR_B20	69.81	\N
2022-06-01	LM_LC_ADR_B22	56.38	\N
2022-06-01	LM_LC_ADR_B24	10.69	\N
2022-06-01	LM_LC_ADR_B31	464.5	\N
2022-06-01	LM_LC_ADR_B41	528.6	\N
2022-06-01	LM_LC_ADR_B43	9	\N
2022-06-01	LM_LH_ADR_B23	71.8	\N
2022-06-01	LM_LH_ADR_B25	71.1	\N
2022-06-01	LM_LH_ADR_B27	161.5	\N
2022-06-01	LM_LH_ADR_B35	0	\N
2022-06-01	LM_LH_ADR_B36	0	\N
2022-06-01	LM_LH_ADR_B38	72.7	\N
2022-06-01	LM_LH_ADR_B44	4.5	\N
2022-06-01	LM_WOD_ADR_B76	1739.86	\N
2022-06-01	LM_WOD_ADR_B77	8.97	\N
2022-06-01	LM_LC_ADR_B16	38.82	\N
2022-06-01	LM_LH_ADR_B17	53.1	\N
2022-06-01	LM_WOD_ADR_B79	360.11	\N
2022-06-01	LM_ELE_ADR_B12	18935.2	\N
2022-06-01	LM_ELE_ADR_B13	15053.19	\N
2022-06-01	LM_LC_ADR_B46	58.87	\N
2022-06-01	LM_LC_ADR193	0	\N
2022-06-01	LM_ELE_ADR125	5060.15	\N
2022-06-01	LM_ELE_ADR069	311232	\N
2022-06-01	LM_ELE_ADR075	11416	\N
2022-06-01	LM_LC_ADR159	5030	\N
2022-06-01	LM_LC_ADR160	13080	\N
2022-06-01	LM_LH_ADR167	3420	\N
2022-06-01	LM_WOD_ADR236	14.53	\N
2022-06-01	zdemontowany580	6	\N
2022-06-01	zdemontowany600	3194	\N
2022-11-01	LM_LC_ADR170	58.68	\N
2022-11-01	LM_LC_ADR172	138.64	\N
2022-11-01	LM_LC_ADR179	90.56	\N
2022-11-01	LM_ELE_ADR021	309934.72	\N
2022-11-01	LM_ELE_ADR078	60263	\N
2022-11-01	LM_ELE_ADR066	0	\N
2022-11-01	LM_ELE_ADR080	190751.53	\N
2022-11-01	LM_LH_ADR199	162.8	\N
2022-11-01	LM_ELE_ADR115	29473.14	\N
2022-11-01	LM_WOD_ADR249_Solution Space	136.58	\N
2022-11-01	LM_WOD_MAIN_W	0	\N
2022-11-01	LM_LC_ADR123	553.9	\N
2022-11-01	LM_LC_ADR151	31921	\N
2022-11-01	LM_LC_ADR153	10749	\N
2022-11-01	LM_LC_ADR154	2862.3	\N
2022-11-01	LM_LC_ADR155	7394.6	\N
2022-11-01	LM_LC_ADR157	1168.6	\N
2022-11-01	LM_LC_ADR158	381	\N
2022-11-01	LM_LC_ADR162	830	\N
2022-11-01	LM_LC_ADR168	129.1	\N
2022-11-01	LM_LC_ADR173	106.11	\N
2022-11-01	LM_LC_ADR174	239.98	\N
2022-11-01	LM_LC_ADR175	0	\N
2022-11-01	LM_LC_ADR176	85.9	\N
2022-11-01	LM_LC_ADR178	150.06	\N
2022-11-01	LM_LC_ADR184	45.23	\N
2022-11-01	LM_LC_ADR186	19.23	\N
2022-11-01	LM_LC_ADR187	32.69	\N
2022-11-01	LM_LC_ADR209	0	\N
2022-11-01	LM_LC_ADR32	0	\N
2022-11-01	LM_LC_ADR82	36.02	\N
2022-11-01	LM_LH_ADR122	22.3	\N
2022-11-01	LM_LH_ADR189	76.47	\N
2022-11-01	LM_LH_ADR195	532.1	\N
2022-11-01	LM_LH_ADR196	9	\N
2022-11-01	LM_LH_ADR198	0	\N
2022-11-01	LM_LH_ADR200	55.4	\N
2022-11-01	LM_LH_ADR203	242.5	\N
2022-11-01	LM_LH_ADR204	119.9	\N
2022-11-01	LM_LH_ADR208	372.2	\N
2022-11-01	LM_LH_ADR211	50.3	\N
2022-11-01	LM_LH_ADR212	260.4	\N
2022-11-01	LM_LH_ADR216	41.31	\N
2022-11-01	LM_LH_ADR218	540.1	\N
2022-11-01	LM_LH_ADR221	449.3	\N
2022-11-01	LM_LH_ADR222	0	\N
2022-11-01	LM_LH_ADR227	53.8	\N
2022-11-01	LM_LH_ADR229	0	\N
2022-11-01	LM_LH_ADR231	0	\N
2022-11-01	LM_LH_ADR234	0	\N
2022-11-01	LM_LH_ADR235	104.6	\N
2022-11-01	LM_LH_ADR33	0	\N
2022-11-01	LM_ELE_ADR008	115282.66	\N
2022-11-01	LM_ELE_ADR012	100419.94	\N
2022-11-01	LM_ELE_ADR017	14244.84	\N
2022-11-01	LM_ELE_ADR019	4038.66	\N
2022-11-01	LM_ELE_ADR024	142129.39	\N
2022-11-01	LM_ELE_ADR027	36475.91	\N
2022-11-01	LM_LC_ADR163	31.06	\N
2022-11-01	LM_LC_ADR164	0.02	\N
2022-11-01	LM_LH_ADR201	142.2	\N
2022-11-01	LM_ELE_ADR029	16602.76	\N
2022-11-01	LM_ELE_ADR031	209284.16	\N
2022-11-01	LM_ELE_ADR038	426621.81	\N
2022-11-01	LM_ELE_ADR041	71852.55	\N
2022-11-01	LM_ELE_ADR045	6655.17	\N
2022-11-01	LM_ELE_ADR047	5966.5	\N
2022-11-01	LM_ELE_ADR049	16095.98	\N
2022-11-01	LM_ELE_ADR052	12289.81	\N
2022-11-01	LM_ELE_ADR054	34010.84	\N
2022-11-01	LM_ELE_ADR057	6811.28	\N
2022-11-01	LM_ELE_ADR059	26962.76	\N
2022-11-01	LM_ELE_ADR060	0	\N
2022-11-01	LM_ELE_ADR061	0	\N
2022-11-01	LM_ELE_ADR062	27078	\N
2022-11-01	LM_ELE_ADR065	0	\N
2022-11-01	LM_ELE_ADR067	336	\N
2022-11-01	LM_ELE_ADR068	15456	\N
2022-11-01	LM_ELE_ADR070	88	\N
2022-11-01	LM_ELE_ADR071	92739	\N
2022-11-01	LM_ELE_ADR073	88	\N
2022-11-01	LM_ELE_ADR077	1063	\N
2022-11-01	LM_ELE_ADR084	59926.8	\N
2022-11-01	LM_ELE_ADR086	18305.55	\N
2022-11-01	LM_ELE_ADR088	45016.21	\N
2022-11-01	LM_ELE_ADR094	1505.26	\N
2022-11-01	LM_ELE_ADR095	116725.74	\N
2022-11-01	LM_ELE_ADR097	40072.1	\N
2022-11-01	LM_ELE_ADR098	3989.49	\N
2022-11-01	LM_ELE_ADR099	101647.32	\N
2022-11-01	LM_ELE_ADR100	21969.28	\N
2022-11-01	LM_ELE_ADR101	9196.26	\N
2022-11-01	LM_ELE_ADR111	362.65	\N
2022-11-01	LM_ELE_ADR116	15151.01	\N
2022-11-01	LM_ELE_ADR118	23070.99	\N
2022-11-01	LM_ELE_ADR119	83890.93	\N
2022-11-01	LM_ELE_ADR120	106938.09	\N
2022-11-01	LM_WOD_ADR129	142.62	\N
2022-11-01	LM_WOD_ADR140	124.71	\N
2022-11-01	LM_WOD_ADR147	68.07	\N
2022-11-01	LM_WOD_ADR246_Solution Space	654.58	\N
2022-11-01	LM_WOD_ADR248_Solution Space	60.22	\N
2022-11-01	LM_ELE_ADR_B03	141325.73	\N
2022-11-01	LM_ELE_ADR_B07	112719.26	\N
2022-11-01	LM_ELE_ADR_B08	167365.52	\N
2022-11-01	LM_LC_ADR_B26	172.78	\N
2022-11-01	LM_LC_ADR_B30	463.9	\N
2022-11-01	LM_LC_ADR_B32	1018.9	\N
2022-11-01	LM_LC_ADR_B33	922.6	\N
2022-11-01	LM_LH_ADR_B19	115.9	\N
2022-11-01	LM_LH_ADR_B21	223.3	\N
2022-11-01	LM_LH_ADR_B34	0	\N
2022-11-01	LM_LH_ADR_B37	0.4	\N
2022-11-01	LM_LH_ADR_B39	113.9	\N
2022-11-01	LM_LH_ADR_B40	193.1	\N
2022-11-01	LM_LH_ADR_B42	0	\N
2022-11-01	LM_WOD_ADR_B78	207.09	\N
2022-11-01	LM_LC_ADR102	58.49	\N
2022-11-01	LM_LC_ADR103	64.37	\N
2022-11-01	LM_LC_ADR104	88.28	\N
2022-11-01	LM_LC_ADR152	5246.3	\N
2022-11-01	LM_LC_ADR149	0.91	\N
2022-11-01	LM_LC_ADR156	3765.6	\N
2022-11-01	LM_LC_ADR171	313.35	\N
2022-11-01	LM_LC_ADR165	54.3	\N
2022-11-01	LM_LC_ADR166	42.45	\N
2022-11-01	LM_LC_ADR180	149.83	\N
2022-11-01	LM_LC_ADR181	0.1	\N
2022-11-01	LM_LC_ADR182	95.71	\N
2022-11-01	LM_LC_ADR183	1.42	\N
2022-11-01	LM_LC_ADR185	19.25	\N
2022-11-01	LM_LC_ADR161	1514.9	\N
2022-11-01	LM_LC_ADR224	185.23	\N
2022-11-01	LM_LC_ADR89	42.21	\N
2022-11-01	LM_LC_ADR93	41.71	\N
2022-11-01	LM_LH_ADR145	10.07	\N
2022-11-01	LM_LH_ADR188	32.18	\N
2022-11-01	LM_LH_ADR190	7.89	\N
2022-11-01	LM_LH_ADR191	18.8	\N
2022-11-01	LM_LH_ADR192	0	\N
2022-11-01	LM_LH_ADR194	0	\N
2022-11-01	LM_LH_ADR207	460.1	\N
2022-11-01	LM_LH_ADR197	1422	\N
2022-11-01	LM_LH_ADR215	0	\N
2022-11-01	LM_LH_ADR219	0.04	\N
2022-11-01	LM_LH_ADR220	112.2	\N
2022-11-01	LM_LH_ADR223	262.7	\N
2022-11-01	LM_LH_ADR225	84.8	\N
2022-11-01	LM_LH_ADR226	83.81	\N
2022-11-01	LM_LH_ADR217	580.5	\N
2022-11-01	LM_LH_ADR228	38.6	\N
2022-11-01	LM_LH_ADR232	68.78	\N
2022-11-01	LM_LH_ADR233	54.3	\N
2022-11-01	LM_LH_ADR230	1.8	\N
2022-11-01	LM_ELE_ADR114	328143.41	\N
2022-11-01	LM_ELE_ADR117	24018.29	\N
2022-11-01	LM_WOD_ADR132	328.89	\N
2022-11-01	LM_WOD_ADR133	374.6	\N
2022-11-01	LM_WOD_ADR134	19.14	\N
2022-11-01	LM_WOD_ADR135	0	\N
2022-11-01	LM_WOD_ADR136	75.97	\N
2022-11-01	LM_WOD_ADR139	1735.17	\N
2022-11-01	LM_WOD_ADR141	17	\N
2022-11-01	LM_WOD_ADR142	36	\N
2022-11-01	LM_WOD_ADR143	582.86	\N
2022-11-01	LM_WOD_ADR146	34631	\N
2022-11-01	LM_WOD_ADR148	0.02	\N
2022-11-01	LM_WOD_ADR150	47.56	\N
2022-11-01	LM_WOD_ADR237	926.26	\N
2022-11-01	LM_WOD_ADR238	3154.34	\N
2022-11-01	LM_WOD_ADR239	41.64	\N
2022-11-01	LM_WOD_ADR240	170.74	\N
2022-11-01	LM_WOD_ADR241	495.57	\N
2022-11-01	LM_ELE_ADR121	255737.2	\N
2022-11-01	LM_ELE_ADR128	0	\N
2022-11-01	LM_WOD_ADR247_Solution Space	698.63	\N
2022-11-01	LM_WOD_ADR250_Solution Space	247.47	\N
2022-11-01	LM_WOD_ADR30	0	\N
2022-11-01	LM_ELE_ADR001	77956.95	\N
2022-11-01	LM_ELE_ADR002	98109.87	\N
2022-11-01	LM_ELE_ADR003	129234.06	\N
2022-11-01	LM_ELE_ADR006	0	\N
2022-11-01	LM_ELE_ADR007	148872.52	\N
2022-11-01	LM_ELE_ADR009	201068.3	\N
2022-11-01	LM_ELE_ADR011	181717.41	\N
2022-11-01	LM_ELE_ADR013	243142.89	\N
2022-11-01	LM_ELE_ADR014	16831.08	\N
2022-11-01	LM_ELE_ADR015	145178.86	\N
2022-11-01	LM_ELE_ADR016	1009437.31	\N
2022-11-01	LM_ELE_ADR018	14806.32	\N
2022-11-01	LM_ELE_ADR020	150184.77	\N
2022-11-01	LM_ELE_ADR022	189039.94	\N
2022-11-01	LM_ELE_ADR023	41706.17	\N
2022-11-01	LM_ELE_ADR025	701734	\N
2022-11-01	LM_ELE_ADR028	20048.84	\N
2022-11-01	LM_ELE_ADR034	36158.82	\N
2022-11-01	LM_ELE_ADR036	97130.74	\N
2022-11-01	LM_ELE_ADR039	412827.66	\N
2022-11-01	LM_ELE_ADR040	36656.9	\N
2022-11-01	LM_ELE_ADR042	3888.89	\N
2022-11-01	LM_ELE_ADR044	7517.02	\N
2022-11-01	LM_ELE_ADR048	7911.85	\N
2022-11-01	LM_ELE_ADR051	7569.03	\N
2022-11-01	LM_ELE_ADR053	35894.45	\N
2022-11-01	LM_ELE_ADR055	6267.97	\N
2022-11-01	LM_ELE_ADR056	0	\N
2022-11-01	LM_ELE_ADR063	190	\N
2022-11-01	LM_ELE_ADR064	0	\N
2022-11-01	LM_ELE_ADR058	91723.52	\N
2022-11-01	LM_ELE_ADR072	31151	\N
2022-11-01	LM_ELE_ADR074	92739	\N
2022-11-01	LM_ELE_ADR076	0	\N
2022-11-01	LM_ELE_ADR081	73855.2	\N
2022-11-01	LM_ELE_ADR085	70000.13	\N
2022-11-01	LM_ELE_ADR090	47763.68	\N
2022-11-01	LM_ELE_ADR107	99982.59	\N
2022-11-01	LM_ELE_ADR108	7577.27	\N
2022-11-01	LM_ELE_ADR109	2041.95	\N
2022-11-01	LM_ELE_ADR110	501.56	\N
2022-11-01	LM_ELE_ADR113	61471.57	\N
2022-11-01	LM_ELE_ADR087	97168.26	\N
2022-11-01	LM_LC_ADR_B45	229.85	\N
2022-11-01	LM_LH_ADR_B46	49.35	\N
2022-11-01	LM_LH_ADR_B47	149.5	\N
2022-11-01	LM_WOD_ADR_B74	42.82	\N
2022-11-01	LM_ELE_ADR_B06	550474.5	\N
2022-11-01	LM_ELE_ADR046	0	\N
2022-11-01	LM_ELE_ADR010	131145.16	\N
2022-11-01	LM_ELE_ADR043	3167.27	\N
2022-11-01	LM_ELE_ADR_B11	38165.41	\N
2022-11-01	LM_WOD_ADR242	49.53	\N
2022-11-01	LM_ELE_ADR124	142215.47	\N
2022-11-01	LM_ELE_ADR112	767511.44	\N
2022-11-01	LM_WOD_ADR_B75	190.69	\N
2022-11-01	LM_ELE_ADR091	14425.76	\N
2022-11-01	LM_WOD_ADR_B80	148.81	\N
2022-11-01	LM_WOD_ADR_B81	52.19	\N
2022-11-01	LM_ELE_ADR_B04	320261.66	\N
2022-11-01	LM_ELE_ADR_B05	326449.75	\N
2022-11-01	LM_ELE_ADR_B09	326041.16	\N
2022-11-01	LM_ELE_ADR_B01	0	\N
2022-11-01	LM_ELE_ADR_B10	34241.66	\N
2022-11-01	LM_ELE_ADR_B02	0	\N
2022-11-01	LM_LC_ADR_B18	19.12	\N
2022-11-01	LM_LC_ADR_B20	70.63	\N
2022-11-01	LM_LC_ADR_B22	56.38	\N
2022-11-01	LM_LC_ADR_B24	10.69	\N
2022-11-01	LM_LC_ADR_B31	476.1	\N
2022-11-01	LM_LC_ADR_B41	552	\N
2022-11-01	LM_LC_ADR_B43	9.8	\N
2022-11-01	LM_LH_ADR_B23	73.9	\N
2022-11-01	LM_LH_ADR_B25	77.7	\N
2022-11-01	LM_LH_ADR_B27	165.3	\N
2022-11-01	LM_LH_ADR_B35	0	\N
2022-11-01	LM_LH_ADR_B36	0	\N
2022-11-01	LM_LH_ADR_B38	80.5	\N
2022-11-01	LM_LH_ADR_B44	4.8	\N
2022-11-01	LM_WOD_ADR_B76	1896.4	\N
2022-11-01	LM_WOD_ADR_B77	9.11	\N
2022-11-01	LM_LC_ADR_B16	38.82	\N
2022-11-01	LM_LH_ADR_B17	65.6	\N
2022-11-01	LM_WOD_ADR_B79	515.65	\N
2022-11-01	LM_ELE_ADR_B12	20501.12	\N
2022-11-01	LM_ELE_ADR_B13	15053.19	\N
2022-11-01	LM_LC_ADR_B46	58.87	\N
2022-11-01	LM_LC_ADR193	0	\N
2022-11-01	LM_ELE_ADR125	5329.84	\N
2022-11-01	LM_ELE_ADR069	337570	\N
2022-11-01	LM_ELE_ADR075	12792	\N
2022-11-01	LM_LC_ADR159	5030	\N
2022-11-01	LM_LC_ADR160	15210	\N
2022-11-01	LM_LH_ADR167	14570	\N
2022-11-01	LM_WOD_ADR236	28.41	\N
2022-11-01	zdemontowany580	6	\N
2022-11-01	zdemontowany600	3194	\N
2022-12-01	LM_LC_ADR170	60.94	\N
2022-12-01	LM_LC_ADR172	145.32	\N
2022-12-01	LM_LC_ADR179	97.58	\N
2022-12-01	LM_ELE_ADR021	321502.38	\N
2022-12-01	LM_ELE_ADR078	60921	\N
2022-12-01	LM_ELE_ADR066	0	\N
2022-12-01	LM_ELE_ADR080	193868.25	\N
2022-12-01	LM_LH_ADR199	163.5	\N
2022-12-01	LM_ELE_ADR115	29500.74	\N
2022-12-01	LM_WOD_ADR249_Solution Space	141.19	\N
2022-12-01	LM_WOD_MAIN_W	0	\N
2022-12-01	LM_LC_ADR123	557.6	\N
2022-12-01	LM_LC_ADR151	32525	\N
2022-12-01	LM_LC_ADR153	10849	\N
2022-12-01	LM_LC_ADR154	2943.1	\N
2022-12-01	LM_LC_ADR155	7603	\N
2022-12-01	LM_LC_ADR157	1191.7	\N
2022-12-01	LM_LC_ADR158	394.2	\N
2022-12-01	LM_LC_ADR162	858.8	\N
2022-12-01	LM_LC_ADR168	132.2	\N
2022-12-01	LM_LC_ADR173	110.4	\N
2022-12-01	LM_LC_ADR174	244.21	\N
2022-12-01	LM_LC_ADR175	0	\N
2022-12-01	LM_LC_ADR176	85.9	\N
2022-12-01	LM_LC_ADR178	155.91	\N
2022-12-01	LM_LC_ADR184	45.23	\N
2022-12-01	LM_LC_ADR186	19.23	\N
2022-12-01	LM_LC_ADR187	32.69	\N
2022-12-01	LM_LC_ADR209	0	\N
2022-12-01	LM_LC_ADR32	0	\N
2022-12-01	LM_LC_ADR82	40.48	\N
2022-12-01	LM_LH_ADR122	22.7	\N
2022-12-01	LM_LH_ADR189	78.09	\N
2022-12-01	LM_LH_ADR195	532.2	\N
2022-12-01	LM_LH_ADR196	9	\N
2022-12-01	LM_LH_ADR198	0	\N
2022-12-01	LM_LH_ADR200	56.1	\N
2022-12-01	LM_LH_ADR203	243.5	\N
2022-12-01	LM_LH_ADR204	120.7	\N
2022-12-01	LM_LH_ADR208	378.7	\N
2022-12-01	LM_LH_ADR211	52.2	\N
2022-12-01	LM_LH_ADR212	269.1	\N
2022-12-01	LM_LH_ADR216	42.78	\N
2022-12-01	LM_LH_ADR218	551.1	\N
2022-12-01	LM_LH_ADR221	456	\N
2022-12-01	LM_LH_ADR222	0	\N
2022-12-01	LM_LH_ADR227	57.4	\N
2022-12-01	LM_LH_ADR229	0	\N
2022-12-01	LM_LH_ADR231	0	\N
2022-12-01	LM_LH_ADR234	0	\N
2022-12-01	LM_LH_ADR235	104.7	\N
2022-12-01	LM_LH_ADR33	0	\N
2022-12-01	LM_ELE_ADR008	117331.03	\N
2022-12-01	LM_ELE_ADR012	101613.66	\N
2022-12-01	LM_ELE_ADR017	14495.57	\N
2022-12-01	LM_ELE_ADR019	4171.31	\N
2022-12-01	LM_ELE_ADR024	144229.13	\N
2022-12-01	LM_ELE_ADR027	36475.91	\N
2022-12-01	LM_LC_ADR163	36.2	\N
2022-12-01	LM_LC_ADR164	0.02	\N
2022-12-01	LM_LH_ADR201	143.5	\N
2022-12-01	LM_ELE_ADR029	17014.38	\N
2022-12-01	LM_ELE_ADR031	212450.91	\N
2022-12-01	LM_ELE_ADR038	437256.72	\N
2022-12-01	LM_ELE_ADR041	73269.73	\N
2022-12-01	LM_ELE_ADR045	6759.9	\N
2022-12-01	LM_ELE_ADR047	6066.03	\N
2022-12-01	LM_ELE_ADR049	16300.83	\N
2022-12-01	LM_ELE_ADR052	12470.69	\N
2022-12-01	LM_ELE_ADR054	34526.13	\N
2022-12-01	LM_ELE_ADR057	6926.28	\N
2022-12-01	LM_ELE_ADR059	27457.56	\N
2022-12-01	LM_ELE_ADR060	0	\N
2022-12-01	LM_ELE_ADR061	0	\N
2022-12-01	LM_ELE_ADR062	27762	\N
2022-12-01	LM_ELE_ADR065	0	\N
2022-12-01	LM_ELE_ADR067	336	\N
2022-12-01	LM_ELE_ADR068	16477	\N
2022-12-01	LM_ELE_ADR070	88	\N
2022-12-01	LM_ELE_ADR071	94629	\N
2022-12-01	LM_ELE_ADR073	88	\N
2022-12-01	LM_ELE_ADR077	1063	\N
2022-12-01	LM_ELE_ADR084	60803.82	\N
2022-12-01	LM_ELE_ADR086	18817.84	\N
2022-12-01	LM_ELE_ADR088	46023.2	\N
2022-12-01	LM_ELE_ADR094	1509.96	\N
2022-12-01	LM_ELE_ADR095	119112.66	\N
2022-12-01	LM_ELE_ADR097	41225.33	\N
2022-12-01	LM_ELE_ADR098	4069.32	\N
2022-12-01	LM_ELE_ADR099	104652.81	\N
2022-12-01	LM_ELE_ADR100	22647.67	\N
2022-12-01	LM_ELE_ADR101	9402.61	\N
2022-12-01	LM_ELE_ADR111	362.68	\N
2022-12-01	LM_ELE_ADR116	15151.01	\N
2022-12-01	LM_ELE_ADR118	23566.04	\N
2022-12-01	LM_ELE_ADR119	85120.34	\N
2022-12-01	LM_ELE_ADR120	109739.67	\N
2022-12-01	LM_WOD_ADR129	145.38	\N
2022-12-01	LM_WOD_ADR140	125.32	\N
2022-12-01	LM_WOD_ADR147	69.31	\N
2022-12-01	LM_WOD_ADR246_Solution Space	670.27	\N
2022-12-01	LM_WOD_ADR248_Solution Space	62.43	\N
2022-12-01	LM_ELE_ADR_B03	143242.31	\N
2022-12-01	LM_ELE_ADR_B07	114445.81	\N
2022-12-01	LM_ELE_ADR_B08	169989.16	\N
2022-12-01	LM_LC_ADR_B26	174.22	\N
2022-12-01	LM_LC_ADR_B30	478.4	\N
2022-12-01	LM_LC_ADR_B32	1062.2	\N
2022-12-01	LM_LC_ADR_B33	949.7	\N
2022-12-01	LM_LH_ADR_B19	116.5	\N
2022-12-01	LM_LH_ADR_B21	224.4	\N
2022-12-01	LM_LH_ADR_B34	0	\N
2022-12-01	LM_LH_ADR_B37	0.4	\N
2022-12-01	LM_LH_ADR_B39	114	\N
2022-12-01	LM_LH_ADR_B40	193.8	\N
2022-12-01	LM_LH_ADR_B42	0	\N
2022-12-01	LM_WOD_ADR_B78	208.72	\N
2022-12-01	LM_LC_ADR102	60.47	\N
2022-12-01	LM_LC_ADR103	66.53	\N
2022-12-01	LM_LC_ADR104	92.15	\N
2022-12-01	LM_LC_ADR152	5354.8	\N
2022-12-01	LM_LC_ADR149	0.91	\N
2022-12-01	LM_LC_ADR156	3879.2	\N
2022-12-01	LM_LC_ADR171	326.34	\N
2022-12-01	LM_LC_ADR165	56.25	\N
2022-12-01	LM_LC_ADR166	43.89	\N
2022-12-01	LM_LC_ADR180	153.1	\N
2022-12-01	LM_LC_ADR181	0.1	\N
2022-12-01	LM_LC_ADR182	100.6	\N
2022-12-01	LM_LC_ADR183	1.42	\N
2022-12-01	LM_LC_ADR185	20.04	\N
2022-12-01	LM_LC_ADR161	1547.2	\N
2022-12-01	LM_LC_ADR224	192.58	\N
2022-12-01	LM_LC_ADR89	43.99	\N
2022-12-01	LM_LC_ADR93	43.44	\N
2022-12-01	LM_LH_ADR145	10.07	\N
2022-12-01	LM_LH_ADR188	32.18	\N
2022-12-01	LM_LH_ADR190	7.89	\N
2022-12-01	LM_LH_ADR191	18.8	\N
2022-12-01	LM_LH_ADR192	0	\N
2022-12-01	LM_LH_ADR194	0	\N
2022-12-01	LM_LH_ADR207	470.7	\N
2022-12-01	LM_LH_ADR197	1428	\N
2022-12-01	LM_LH_ADR215	0	\N
2022-12-01	LM_LH_ADR219	0.04	\N
2022-12-01	LM_LH_ADR220	112.2	\N
2022-12-01	LM_LH_ADR223	267.1	\N
2022-12-01	LM_LH_ADR225	85	\N
2022-12-01	LM_LH_ADR226	84.84	\N
2022-12-01	LM_LH_ADR217	587.2	\N
2022-12-01	LM_LH_ADR228	40	\N
2022-12-01	LM_LH_ADR232	70.09	\N
2022-12-01	LM_LH_ADR233	54.3	\N
2022-12-01	LM_LH_ADR230	1.8	\N
2022-12-01	LM_ELE_ADR114	335524.91	\N
2022-12-01	LM_ELE_ADR117	24030.56	\N
2022-12-01	LM_WOD_ADR132	333.17	\N
2022-12-01	LM_WOD_ADR133	379.74	\N
2022-12-01	LM_WOD_ADR134	19.3	\N
2022-12-01	LM_WOD_ADR135	0	\N
2022-12-01	LM_WOD_ADR136	76.69	\N
2022-12-01	LM_WOD_ADR139	1764.47	\N
2022-12-01	LM_WOD_ADR141	17	\N
2022-12-01	LM_WOD_ADR142	36	\N
2022-12-01	LM_WOD_ADR143	582.86	\N
2022-12-01	LM_WOD_ADR146	34924.5	\N
2022-12-01	LM_WOD_ADR148	0.03	\N
2022-12-01	LM_WOD_ADR150	48.32	\N
2022-12-01	LM_WOD_ADR237	926.4	\N
2022-12-01	LM_WOD_ADR238	3242.01	\N
2022-12-01	LM_WOD_ADR239	42.62	\N
2022-12-01	LM_WOD_ADR240	176.37	\N
2022-12-01	LM_WOD_ADR241	543.07	\N
2022-12-01	LM_ELE_ADR121	265118.34	\N
2022-12-01	LM_ELE_ADR128	0	\N
2022-12-01	LM_WOD_ADR247_Solution Space	720.18	\N
2022-12-01	LM_WOD_ADR250_Solution Space	257.2	\N
2022-12-01	LM_WOD_ADR30	0	\N
2022-12-01	LM_ELE_ADR001	79658.73	\N
2022-12-01	LM_ELE_ADR002	99437.37	\N
2022-12-01	LM_ELE_ADR003	130967.55	\N
2022-12-01	LM_ELE_ADR006	0	\N
2022-12-01	LM_ELE_ADR007	150009.14	\N
2022-12-01	LM_ELE_ADR009	202241.53	\N
2022-12-01	LM_ELE_ADR011	182680.66	\N
2022-12-01	LM_ELE_ADR013	245788.36	\N
2022-12-01	LM_ELE_ADR014	17197.44	\N
2022-12-01	LM_ELE_ADR015	146681.64	\N
2022-12-01	LM_ELE_ADR016	1016861.94	\N
2022-12-01	LM_ELE_ADR018	15047.94	\N
2022-12-01	LM_ELE_ADR020	153302.09	\N
2022-12-01	LM_ELE_ADR022	194854.97	\N
2022-12-01	LM_ELE_ADR023	42808.63	\N
2022-12-01	LM_ELE_ADR025	732578.31	\N
2022-12-01	LM_ELE_ADR028	20074.1	\N
2022-12-01	LM_ELE_ADR034	37231.04	\N
2022-12-01	LM_ELE_ADR036	98937.95	\N
2022-12-01	LM_ELE_ADR039	424177.88	\N
2022-12-01	LM_ELE_ADR040	37576.49	\N
2022-12-01	LM_ELE_ADR042	3949.28	\N
2022-12-01	LM_ELE_ADR044	7621.93	\N
2022-12-01	LM_ELE_ADR048	8032.44	\N
2022-12-01	LM_ELE_ADR051	7676.43	\N
2022-12-01	LM_ELE_ADR053	37490.02	\N
2022-12-01	LM_ELE_ADR055	0	\N
2022-12-01	LM_ELE_ADR056	0	\N
2022-12-01	LM_ELE_ADR063	190	\N
2022-12-01	LM_ELE_ADR064	0	\N
2022-12-01	LM_ELE_ADR058	93089.91	\N
2022-12-01	LM_ELE_ADR072	31812	\N
2022-12-01	LM_ELE_ADR074	94629	\N
2022-12-01	LM_ELE_ADR076	0	\N
2022-12-01	LM_ELE_ADR081	76487.04	\N
2022-12-01	LM_ELE_ADR085	71985.25	\N
2022-12-01	LM_ELE_ADR090	49312.93	\N
2022-12-01	LM_ELE_ADR107	102168.23	\N
2022-12-01	LM_ELE_ADR108	7821.08	\N
2022-12-01	LM_ELE_ADR109	2043.74	\N
2022-12-01	LM_ELE_ADR110	521.24	\N
2022-12-01	LM_ELE_ADR113	62382.46	\N
2022-12-01	LM_ELE_ADR087	98473.95	\N
2022-12-01	LM_LC_ADR_B45	244.83	\N
2022-12-01	LM_LH_ADR_B46	49.35	\N
2022-12-01	LM_LH_ADR_B47	150	\N
2022-12-01	LM_WOD_ADR_B74	43.64	\N
2022-12-01	LM_ELE_ADR_B06	558623.5	\N
2022-12-01	LM_ELE_ADR046	0	\N
2022-12-01	LM_ELE_ADR010	133128.36	\N
2022-12-01	LM_ELE_ADR043	3221.71	\N
2022-12-01	LM_ELE_ADR_B11	38361.3	\N
2022-12-01	LM_WOD_ADR242	50.61	\N
2022-12-01	LM_ELE_ADR124	147387.55	\N
2022-12-01	LM_ELE_ADR112	772258.75	\N
2022-12-01	LM_WOD_ADR_B75	191.39	\N
2022-12-01	LM_ELE_ADR091	14767.47	\N
2022-12-01	LM_WOD_ADR_B80	152.38	\N
2022-12-01	LM_WOD_ADR_B81	53.28	\N
2022-12-01	LM_ELE_ADR_B04	320859.63	\N
2022-12-01	LM_ELE_ADR_B05	329807.81	\N
2022-12-01	LM_ELE_ADR_B09	330137.5	\N
2022-12-01	LM_ELE_ADR_B01	0	\N
2022-12-01	LM_ELE_ADR_B10	34843.28	\N
2022-12-01	LM_ELE_ADR_B02	0	\N
2022-12-01	LM_LC_ADR_B18	19.23	\N
2022-12-01	LM_LC_ADR_B20	71.06	\N
2022-12-01	LM_LC_ADR_B22	56.38	\N
2022-12-01	LM_LC_ADR_B24	10.69	\N
2022-12-01	LM_LC_ADR_B31	490.7	\N
2022-12-01	LM_LC_ADR_B41	571.7	\N
2022-12-01	LM_LC_ADR_B43	10.1	\N
2022-12-01	LM_LH_ADR_B23	73.9	\N
2022-12-01	LM_LH_ADR_B25	77.7	\N
2022-12-01	LM_LH_ADR_B27	165.8	\N
2022-12-01	LM_LH_ADR_B35	0	\N
2022-12-01	LM_LH_ADR_B36	0	\N
2022-12-01	LM_LH_ADR_B38	80.7	\N
2022-12-01	LM_LH_ADR_B44	4.8	\N
2022-12-01	LM_WOD_ADR_B76	1908.29	\N
2022-12-01	LM_WOD_ADR_B77	9.11	\N
2022-12-01	LM_LC_ADR_B16	38.82	\N
2022-12-01	LM_LH_ADR_B17	65.9	\N
2022-12-01	LM_WOD_ADR_B79	515.65	\N
2022-12-01	LM_ELE_ADR_B12	20812.22	\N
2022-12-01	LM_ELE_ADR_B13	15053.19	\N
2022-12-01	LM_LC_ADR_B46	58.91	\N
2022-12-01	LM_LC_ADR193	0	\N
2022-12-01	LM_ELE_ADR125	5387.84	\N
2022-12-01	LM_ELE_ADR069	344855	\N
2022-12-01	LM_ELE_ADR075	13071	\N
2022-12-01	LM_LC_ADR159	5660	\N
2022-12-01	LM_LC_ADR160	16650	\N
2022-12-01	LM_LH_ADR167	14870	\N
2022-12-01	LM_WOD_ADR236	31.17	\N
2022-12-01	zdemontowany580	6	\N
2022-12-01	zdemontowany600	3194	\N
2023-01-01	LM_LC_ADR170	63.9	\N
2023-01-01	LM_LC_ADR172	151.96	\N
2023-01-01	LM_LC_ADR179	111.91	\N
2023-01-01	LM_ELE_ADR021	337420.44	\N
2023-01-01	LM_ELE_ADR078	61380	\N
2023-01-01	LM_ELE_ADR066	0	\N
2023-01-01	LM_ELE_ADR080	196759.48	\N
2023-01-01	LM_LH_ADR199	164	\N
2023-01-01	LM_ELE_ADR115	29529.25	\N
2023-01-01	LM_WOD_ADR249_Solution Space	144.98	\N
2023-01-01	LM_WOD_MAIN_W	0	\N
2023-01-01	LM_LC_ADR123	561.4	\N
2023-01-01	LM_LC_ADR151	33333	\N
2023-01-01	LM_LC_ADR153	10985	\N
2023-01-01	LM_LC_ADR154	3040.9	\N
2023-01-01	LM_LC_ADR155	7875.6	\N
2023-01-01	LM_LC_ADR157	1214.6	\N
2023-01-01	LM_LC_ADR158	409.5	\N
2023-01-01	LM_LC_ADR162	909.7	\N
2023-01-01	LM_LC_ADR168	136.8	\N
2023-01-01	LM_LC_ADR173	114.35	\N
2023-01-01	LM_LC_ADR174	247.61	\N
2023-01-01	LM_LC_ADR175	0	\N
2023-01-01	LM_LC_ADR176	86	\N
2023-01-01	LM_LC_ADR178	162.77	\N
2023-01-01	LM_LC_ADR184	45.23	\N
2023-01-01	LM_LC_ADR186	25.6	\N
2023-01-01	LM_LC_ADR187	32.69	\N
2023-01-01	LM_LC_ADR209	0	\N
2023-01-01	LM_LC_ADR32	0	\N
2023-01-01	LM_LC_ADR82	45.64	\N
2023-01-01	LM_LH_ADR122	22.7	\N
2023-01-01	LM_LH_ADR189	79.17	\N
2023-01-01	LM_LH_ADR195	532.2	\N
2023-01-01	LM_LH_ADR196	9	\N
2023-01-01	LM_LH_ADR198	0	\N
2023-01-01	LM_LH_ADR200	56.7	\N
2023-01-01	LM_LH_ADR203	243.9	\N
2023-01-01	LM_LH_ADR204	121.6	\N
2023-01-01	LM_LH_ADR208	385	\N
2023-01-01	LM_LH_ADR211	53.6	\N
2023-01-01	LM_LH_ADR212	277.2	\N
2023-01-01	LM_LH_ADR216	42.78	\N
2023-01-01	LM_LH_ADR218	560.5	\N
2023-01-01	LM_LH_ADR221	462.3	\N
2023-01-01	LM_LH_ADR222	0	\N
2023-01-01	LM_LH_ADR227	57.4	\N
2023-01-01	LM_LH_ADR229	0	\N
2023-01-01	LM_LH_ADR231	0	\N
2023-01-01	LM_LH_ADR234	0	\N
2023-01-01	LM_LH_ADR235	104.8	\N
2023-01-01	LM_LH_ADR33	0	\N
2023-01-01	LM_ELE_ADR008	119255.51	\N
2023-01-01	LM_ELE_ADR012	103501.11	\N
2023-01-01	LM_ELE_ADR017	14722.21	\N
2023-01-01	LM_ELE_ADR019	4656.49	\N
2023-01-01	LM_ELE_ADR024	146105.52	\N
2023-01-01	LM_ELE_ADR027	36475.91	\N
2023-01-01	LM_LC_ADR163	48.05	\N
2023-01-01	LM_LC_ADR164	0.02	\N
2023-01-01	LM_LH_ADR201	143.5	\N
2023-01-01	LM_ELE_ADR029	17475.58	\N
2023-01-01	LM_ELE_ADR031	214995.72	\N
2023-01-01	LM_ELE_ADR038	442950.19	\N
2023-01-01	LM_ELE_ADR041	74763.05	\N
2023-01-01	LM_ELE_ADR045	6855.31	\N
2023-01-01	LM_ELE_ADR047	6158.25	\N
2023-01-01	LM_ELE_ADR049	16496.89	\N
2023-01-01	LM_ELE_ADR052	12643.34	\N
2023-01-01	LM_ELE_ADR054	35036.11	\N
2023-01-01	LM_ELE_ADR057	7026.04	\N
2023-01-01	LM_ELE_ADR059	27928.23	\N
2023-01-01	LM_ELE_ADR060	0	\N
2023-01-01	LM_ELE_ADR061	0	\N
2023-01-01	LM_ELE_ADR062	27924	\N
2023-01-01	LM_ELE_ADR065	0	\N
2023-01-01	LM_ELE_ADR067	336	\N
2023-01-01	LM_ELE_ADR068	17494	\N
2023-01-01	LM_ELE_ADR070	88	\N
2023-01-01	LM_ELE_ADR071	96474	\N
2023-01-01	LM_ELE_ADR073	88	\N
2023-01-01	LM_ELE_ADR077	1063	\N
2023-01-01	LM_ELE_ADR084	61578.17	\N
2023-01-01	LM_ELE_ADR086	19319.89	\N
2023-01-01	LM_ELE_ADR088	47136.67	\N
2023-01-01	LM_ELE_ADR094	1513.05	\N
2023-01-01	LM_ELE_ADR095	121381.3	\N
2023-01-01	LM_ELE_ADR097	42357.75	\N
2023-01-01	LM_ELE_ADR098	4136.86	\N
2023-01-01	LM_ELE_ADR099	107636.13	\N
2023-01-01	LM_ELE_ADR100	23390.31	\N
2023-01-01	LM_ELE_ADR101	9597.74	\N
2023-01-01	LM_ELE_ADR111	362.68	\N
2023-01-01	LM_ELE_ADR116	15151.01	\N
2023-01-01	LM_ELE_ADR118	24005.6	\N
2023-01-01	LM_ELE_ADR119	86320.29	\N
2023-01-01	LM_ELE_ADR120	112242.52	\N
2023-01-01	LM_WOD_ADR129	148.2	\N
2023-01-01	LM_WOD_ADR140	126.08	\N
2023-01-01	LM_WOD_ADR147	70.62	\N
2023-01-01	LM_WOD_ADR246_Solution Space	681.92	\N
2023-01-01	LM_WOD_ADR248_Solution Space	64.21	\N
2023-01-01	LM_ELE_ADR_B03	145056.17	\N
2023-01-01	LM_ELE_ADR_B07	116315.13	\N
2023-01-01	LM_ELE_ADR_B08	172654.84	\N
2023-01-01	LM_LC_ADR_B26	178.38	\N
2023-01-01	LM_LC_ADR_B30	498.6	\N
2023-01-01	LM_LC_ADR_B32	1120.4	\N
2023-01-01	LM_LC_ADR_B33	984.8	\N
2023-01-01	LM_LH_ADR_B19	117.4	\N
2023-01-01	LM_LH_ADR_B21	225.3	\N
2023-01-01	LM_LH_ADR_B34	0	\N
2023-01-01	LM_LH_ADR_B37	0.4	\N
2023-01-01	LM_LH_ADR_B39	114.2	\N
2023-01-01	LM_LH_ADR_B40	194.1	\N
2023-01-01	LM_LH_ADR_B42	0	\N
2023-01-01	LM_WOD_ADR_B78	209.15	\N
2023-01-01	LM_LC_ADR102	62.72	\N
2023-01-01	LM_LC_ADR103	68.95	\N
2023-01-01	LM_LC_ADR104	96.74	\N
2023-01-01	LM_LC_ADR152	5486.1	\N
2023-01-01	LM_LC_ADR149	0.91	\N
2023-01-01	LM_LC_ADR156	4054.7	\N
2023-01-01	LM_LC_ADR171	343.58	\N
2023-01-01	LM_LC_ADR165	58.46	\N
2023-01-01	LM_LC_ADR166	45.5	\N
2023-01-01	LM_LC_ADR180	159.92	\N
2023-01-01	LM_LC_ADR181	0.1	\N
2023-01-01	LM_LC_ADR182	107.07	\N
2023-01-01	LM_LC_ADR183	1.42	\N
2023-01-01	LM_LC_ADR185	20.48	\N
2023-01-01	LM_LC_ADR161	1581.1	\N
2023-01-01	LM_LC_ADR224	200.97	\N
2023-01-01	LM_LC_ADR89	46.07	\N
2023-01-01	LM_LC_ADR93	45.46	\N
2023-01-01	LM_LH_ADR145	10.07	\N
2023-01-01	LM_LH_ADR188	32.18	\N
2023-01-01	LM_LH_ADR190	7.89	\N
2023-01-01	LM_LH_ADR191	18.8	\N
2023-01-01	LM_LH_ADR192	0	\N
2023-01-01	LM_LH_ADR194	0	\N
2023-01-01	LM_LH_ADR207	481.3	\N
2023-01-01	LM_LH_ADR197	1432	\N
2023-01-01	LM_LH_ADR215	0	\N
2023-01-01	LM_LH_ADR219	0.04	\N
2023-01-01	LM_LH_ADR220	112.2	\N
2023-01-01	LM_LH_ADR223	271.6	\N
2023-01-01	LM_LH_ADR225	85	\N
2023-01-01	LM_LH_ADR226	87.3	\N
2023-01-01	LM_LH_ADR217	591.4	\N
2023-01-01	LM_LH_ADR228	40.2	\N
2023-01-01	LM_LH_ADR232	71.33	\N
2023-01-01	LM_LH_ADR233	54.3	\N
2023-01-01	LM_LH_ADR230	1.8	\N
2023-01-01	LM_ELE_ADR114	27.81	\N
2023-01-01	LM_ELE_ADR117	24360.42	\N
2023-01-01	LM_WOD_ADR132	336.67	\N
2023-01-01	LM_WOD_ADR133	384.23	\N
2023-01-01	LM_WOD_ADR134	19.39	\N
2023-01-01	LM_WOD_ADR135	0	\N
2023-01-01	LM_WOD_ADR136	77.42	\N
2023-01-01	LM_WOD_ADR139	1786.35	\N
2023-01-01	LM_WOD_ADR141	17	\N
2023-01-01	LM_WOD_ADR142	36	\N
2023-01-01	LM_WOD_ADR143	582.86	\N
2023-01-01	LM_WOD_ADR146	34972.4	\N
2023-01-01	LM_WOD_ADR148	0.05	\N
2023-01-01	LM_WOD_ADR150	49.1	\N
2023-01-01	LM_WOD_ADR237	926.71	\N
2023-01-01	LM_WOD_ADR238	3330.5	\N
2023-01-01	LM_WOD_ADR239	43.43	\N
2023-01-01	LM_WOD_ADR240	181.26	\N
2023-01-01	LM_WOD_ADR241	585.39	\N
2023-01-01	LM_ELE_ADR121	85.44	\N
2023-01-01	LM_ELE_ADR128	0	\N
2023-01-01	LM_WOD_ADR247_Solution Space	742.29	\N
2023-01-01	LM_WOD_ADR250_Solution Space	264.33	\N
2023-01-01	LM_WOD_ADR30	0	\N
2023-01-01	LM_ELE_ADR001	81267.88	\N
2023-01-01	LM_ELE_ADR002	100670.06	\N
2023-01-01	LM_ELE_ADR003	132369.53	\N
2023-01-01	LM_ELE_ADR006	0	\N
2023-01-01	LM_ELE_ADR007	150706.86	\N
2023-01-01	LM_ELE_ADR009	203376.13	\N
2023-01-01	LM_ELE_ADR011	183591.56	\N
2023-01-01	LM_ELE_ADR013	249715.39	\N
2023-01-01	LM_ELE_ADR014	17567.85	\N
2023-01-01	LM_ELE_ADR015	148128.83	\N
2023-01-01	LM_ELE_ADR016	1024885	\N
2023-01-01	LM_ELE_ADR018	15281.03	\N
2023-01-01	LM_ELE_ADR020	156622.3	\N
2023-01-01	LM_ELE_ADR022	201792.56	\N
2023-01-01	LM_ELE_ADR023	43907.54	\N
2023-01-01	LM_ELE_ADR025	764784.69	\N
2023-01-01	LM_ELE_ADR028	20098.56	\N
2023-01-01	LM_ELE_ADR034	38232.14	\N
2023-01-01	LM_ELE_ADR036	101049.15	\N
2023-01-01	LM_ELE_ADR039	439472.56	\N
2023-01-01	LM_ELE_ADR040	39824.29	\N
2023-01-01	LM_ELE_ADR042	4007.18	\N
2023-01-01	LM_ELE_ADR044	7717.05	\N
2023-01-01	LM_ELE_ADR048	8139.93	\N
2023-01-01	LM_ELE_ADR051	7775.16	\N
2023-01-01	LM_ELE_ADR053	38696.36	\N
2023-01-01	LM_ELE_ADR055	0	\N
2023-01-01	LM_ELE_ADR056	0	\N
2023-01-01	LM_ELE_ADR063	190	\N
2023-01-01	LM_ELE_ADR064	0	\N
2023-01-01	LM_ELE_ADR058	94381	\N
2023-01-01	LM_ELE_ADR072	32426	\N
2023-01-01	LM_ELE_ADR074	96474	\N
2023-01-01	LM_ELE_ADR076	0	\N
2023-01-01	LM_ELE_ADR081	80683.98	\N
2023-01-01	LM_ELE_ADR085	74046.35	\N
2023-01-01	LM_ELE_ADR090	50641.16	\N
2023-01-01	LM_ELE_ADR107	104292.87	\N
2023-01-01	LM_ELE_ADR108	8078.58	\N
2023-01-01	LM_ELE_ADR109	2044.27	\N
2023-01-01	LM_ELE_ADR110	544.63	\N
2023-01-01	LM_ELE_ADR113	63513.73	\N
2023-01-01	LM_ELE_ADR087	99648.2	\N
2023-01-01	LM_LC_ADR_B45	267.07	\N
2023-01-01	LM_LH_ADR_B46	49.35	\N
2023-01-01	LM_LH_ADR_B47	150.1	\N
2023-01-01	LM_WOD_ADR_B74	44.46	\N
2023-01-01	LM_ELE_ADR_B06	566054.31	\N
2023-01-01	LM_ELE_ADR046	0	\N
2023-01-01	LM_ELE_ADR010	135087.95	\N
2023-01-01	LM_ELE_ADR043	3273.2	\N
2023-01-01	LM_ELE_ADR_B11	38909.11	\N
2023-01-01	LM_WOD_ADR242	51.6	\N
2023-01-01	LM_ELE_ADR124	152581.89	\N
2023-01-01	LM_ELE_ADR112	777140.25	\N
2023-01-01	LM_WOD_ADR_B75	191.71	\N
2023-01-01	LM_ELE_ADR091	15087.75	\N
2023-01-01	LM_WOD_ADR_B80	156	\N
2023-01-01	LM_WOD_ADR_B81	54.25	\N
2023-01-01	LM_ELE_ADR_B04	321350.63	\N
2023-01-01	LM_ELE_ADR_B05	331686	\N
2023-01-01	LM_ELE_ADR_B09	332627.19	\N
2023-01-01	LM_ELE_ADR_B01	0	\N
2023-01-01	LM_ELE_ADR_B10	35400.75	\N
2023-01-01	LM_ELE_ADR_B02	0	\N
2023-01-01	LM_LC_ADR_B18	19.4	\N
2023-01-01	LM_LC_ADR_B20	71.25	\N
2023-01-01	LM_LC_ADR_B22	56.38	\N
2023-01-01	LM_LC_ADR_B24	10.69	\N
2023-01-01	LM_LC_ADR_B31	514.9	\N
2023-01-01	LM_LC_ADR_B41	596	\N
2023-01-01	LM_LC_ADR_B43	10.3	\N
2023-01-01	LM_LH_ADR_B23	73.9	\N
2023-01-01	LM_LH_ADR_B25	77.7	\N
2023-01-01	LM_LH_ADR_B27	166.4	\N
2023-01-01	LM_LH_ADR_B35	0	\N
2023-01-01	LM_LH_ADR_B36	0	\N
2023-01-01	LM_LH_ADR_B38	80.7	\N
2023-01-01	LM_LH_ADR_B44	4.8	\N
2023-01-01	LM_WOD_ADR_B76	1908.29	\N
2023-01-01	LM_WOD_ADR_B77	9.11	\N
2023-01-01	LM_LC_ADR_B16	38.83	\N
2023-01-01	LM_LH_ADR_B17	66.3	\N
2023-01-01	LM_WOD_ADR_B79	515.65	\N
2023-01-01	LM_ELE_ADR_B12	21181.79	\N
2023-01-01	LM_ELE_ADR_B13	15053.19	\N
2023-01-01	LM_LC_ADR_B46	59.5	\N
2023-01-01	LM_LC_ADR193	0	\N
2023-01-01	LM_ELE_ADR125	5441.6	\N
2023-01-01	LM_ELE_ADR069	347572	\N
2023-01-01	LM_ELE_ADR075	13329	\N
2023-01-01	LM_LC_ADR159	8210	\N
2023-01-01	LM_LC_ADR160	17970	\N
2023-01-01	LM_LH_ADR167	14870	\N
2023-01-01	LM_WOD_ADR236	33.69	\N
2023-01-01	zdemontowany580	6	\N
2023-01-01	zdemontowany600	3194	\N
2023-02-01	LM_LC_ADR170	67.08	\N
2023-02-01	LM_LC_ADR172	157.98	\N
2023-02-01	LM_LC_ADR179	124.39	\N
2023-02-01	LM_ELE_ADR021	349425.5	\N
2023-02-01	LM_ELE_ADR078	61734	\N
2023-02-01	LM_ELE_ADR066	0	\N
2023-02-01	LM_ELE_ADR080	199832.5	\N
2023-02-01	LM_LH_ADR199	164.4	\N
2023-02-01	LM_ELE_ADR115	29561.87	\N
2023-02-01	LM_WOD_ADR249_Solution Space	148.58	\N
2023-02-01	LM_WOD_MAIN_W	0	\N
2023-02-01	LM_LC_ADR123	564.8	\N
2023-02-01	LM_LC_ADR151	34017	\N
2023-02-01	LM_LC_ADR153	11105	\N
2023-02-01	LM_LC_ADR154	3135	\N
2023-02-01	LM_LC_ADR155	8106.4	\N
2023-02-01	LM_LC_ADR157	1237.4	\N
2023-02-01	LM_LC_ADR158	424.9	\N
2023-02-01	LM_LC_ADR162	955.6	\N
2023-02-01	LM_LC_ADR168	137.6	\N
2023-02-01	LM_LC_ADR173	118.91	\N
2023-02-01	LM_LC_ADR174	255.29	\N
2023-02-01	LM_LC_ADR175	0	\N
2023-02-01	LM_LC_ADR176	86.3	\N
2023-02-01	LM_LC_ADR178	169.28	\N
2023-02-01	LM_LC_ADR184	45.23	\N
2023-02-01	LM_LC_ADR186	26.44	\N
2023-02-01	LM_LC_ADR187	32.69	\N
2023-02-01	LM_LC_ADR209	0	\N
2023-02-01	LM_LC_ADR32	0	\N
2023-02-01	LM_LC_ADR82	50.71	\N
2023-02-01	LM_LH_ADR122	22.9	\N
2023-02-01	LM_LH_ADR189	79.48	\N
2023-02-01	LM_LH_ADR195	532.3	\N
2023-02-01	LM_LH_ADR196	9	\N
2023-02-01	LM_LH_ADR198	0	\N
2023-02-01	LM_LH_ADR200	57.2	\N
2023-02-01	LM_LH_ADR203	244.4	\N
2023-02-01	LM_LH_ADR204	122.6	\N
2023-02-01	LM_LH_ADR208	392.4	\N
2023-02-01	LM_LH_ADR211	55.1	\N
2023-02-01	LM_LH_ADR212	286.2	\N
2023-02-01	LM_LH_ADR216	43.41	\N
2023-02-01	LM_LH_ADR218	573.1	\N
2023-02-01	LM_LH_ADR221	472.3	\N
2023-02-01	LM_LH_ADR222	0	\N
2023-02-01	LM_LH_ADR227	57.4	\N
2023-02-01	LM_LH_ADR229	0	\N
2023-02-01	LM_LH_ADR231	0	\N
2023-02-01	LM_LH_ADR234	0	\N
2023-02-01	LM_LH_ADR235	105.2	\N
2023-02-01	LM_LH_ADR33	0	\N
2023-02-01	LM_ELE_ADR008	121315.96	\N
2023-02-01	LM_ELE_ADR012	105518.2	\N
2023-02-01	LM_ELE_ADR017	14962.82	\N
2023-02-01	LM_ELE_ADR019	4656.49	\N
2023-02-01	LM_ELE_ADR024	148155.55	\N
2023-02-01	LM_ELE_ADR027	36475.91	\N
2023-02-01	LM_LC_ADR163	56.59	\N
2023-02-01	LM_LC_ADR164	0.02	\N
2023-02-01	LM_LH_ADR201	143.5	\N
2023-02-01	LM_ELE_ADR029	18011.28	\N
2023-02-01	LM_ELE_ADR031	218022.66	\N
2023-02-01	LM_ELE_ADR038	449184.19	\N
2023-02-01	LM_ELE_ADR041	76354.41	\N
2023-02-01	LM_ELE_ADR045	6959.5	\N
2023-02-01	LM_ELE_ADR047	6257.09	\N
2023-02-01	LM_ELE_ADR049	16712.15	\N
2023-02-01	LM_ELE_ADR052	12831	\N
2023-02-01	LM_ELE_ADR054	35567.65	\N
2023-02-01	LM_ELE_ADR057	7124.97	\N
2023-02-01	LM_ELE_ADR059	28457.76	\N
2023-02-01	LM_ELE_ADR060	0	\N
2023-02-01	LM_ELE_ADR061	0	\N
2023-02-01	LM_ELE_ADR062	27924	\N
2023-02-01	LM_ELE_ADR065	0	\N
2023-02-01	LM_ELE_ADR067	336	\N
2023-02-01	LM_ELE_ADR068	18527	\N
2023-02-01	LM_ELE_ADR070	88	\N
2023-02-01	LM_ELE_ADR071	98230	\N
2023-02-01	LM_ELE_ADR073	88	\N
2023-02-01	LM_ELE_ADR077	1063	\N
2023-02-01	LM_ELE_ADR084	62345.22	\N
2023-02-01	LM_ELE_ADR086	19875.48	\N
2023-02-01	LM_ELE_ADR088	48358.47	\N
2023-02-01	LM_ELE_ADR094	1514.81	\N
2023-02-01	LM_ELE_ADR095	123856.49	\N
2023-02-01	LM_ELE_ADR097	43601.66	\N
2023-02-01	LM_ELE_ADR098	4214.07	\N
2023-02-01	LM_ELE_ADR099	110794.08	\N
2023-02-01	LM_ELE_ADR100	24259.2	\N
2023-02-01	LM_ELE_ADR101	9813.76	\N
2023-02-01	LM_ELE_ADR111	362.68	\N
2023-02-01	LM_ELE_ADR116	15151.01	\N
2023-02-01	LM_ELE_ADR118	24494.85	\N
2023-02-01	LM_ELE_ADR119	87636.96	\N
2023-02-01	LM_ELE_ADR120	115046.81	\N
2023-02-01	LM_WOD_ADR129	151.03	\N
2023-02-01	LM_WOD_ADR140	128.51	\N
2023-02-01	LM_WOD_ADR147	72	\N
2023-02-01	LM_WOD_ADR246_Solution Space	697.18	\N
2023-02-01	LM_WOD_ADR248_Solution Space	66.14	\N
2023-02-01	LM_ELE_ADR_B03	147086.02	\N
2023-02-01	LM_ELE_ADR_B07	118305.8	\N
2023-02-01	LM_ELE_ADR_B08	175650.11	\N
2023-02-01	LM_LC_ADR_B26	179.61	\N
2023-02-01	LM_LC_ADR_B30	510.3	\N
2023-02-01	LM_LC_ADR_B32	1172.5	\N
2023-02-01	LM_LC_ADR_B33	1009	\N
2023-02-01	LM_LH_ADR_B19	118	\N
2023-02-01	LM_LH_ADR_B21	225.9	\N
2023-02-01	LM_LH_ADR_B34	0	\N
2023-02-01	LM_LH_ADR_B37	0.4	\N
2023-02-01	LM_LH_ADR_B39	114.3	\N
2023-02-01	LM_LH_ADR_B40	194.5	\N
2023-02-01	LM_LH_ADR_B42	0	\N
2023-02-01	LM_WOD_ADR_B78	209.28	\N
2023-02-01	LM_LC_ADR102	64.86	\N
2023-02-01	LM_LC_ADR103	71.24	\N
2023-02-01	LM_LC_ADR104	101.1	\N
2023-02-01	LM_LC_ADR152	5583.2	\N
2023-02-01	LM_LC_ADR149	0.91	\N
2023-02-01	LM_LC_ADR156	4203.2	\N
2023-02-01	LM_LC_ADR171	363.61	\N
2023-02-01	LM_LC_ADR165	60.54	\N
2023-02-01	LM_LC_ADR166	47.05	\N
2023-02-01	LM_LC_ADR180	167.29	\N
2023-02-01	LM_LC_ADR181	0.1	\N
2023-02-01	LM_LC_ADR182	112.96	\N
2023-02-01	LM_LC_ADR183	1.42	\N
2023-02-01	LM_LC_ADR185	20.93	\N
2023-02-01	LM_LC_ADR161	1608	\N
2023-02-01	LM_LC_ADR224	208.99	\N
2023-02-01	LM_LC_ADR89	48.09	\N
2023-02-01	LM_LC_ADR93	47.42	\N
2023-02-01	LM_LH_ADR145	10.07	\N
2023-02-01	LM_LH_ADR188	32.18	\N
2023-02-01	LM_LH_ADR190	7.89	\N
2023-02-01	LM_LH_ADR191	18.8	\N
2023-02-01	LM_LH_ADR192	0	\N
2023-02-01	LM_LH_ADR194	0	\N
2023-02-01	LM_LH_ADR207	492.2	\N
2023-02-01	LM_LH_ADR197	1435.6	\N
2023-02-01	LM_LH_ADR215	0	\N
2023-02-01	LM_LH_ADR219	0.04	\N
2023-02-01	LM_LH_ADR220	147.33	\N
2023-02-01	LM_LH_ADR223	271.7	\N
2023-02-01	LM_LH_ADR225	85	\N
2023-02-01	LM_LH_ADR226	87.68	\N
2023-02-01	LM_LH_ADR217	596.3	\N
2023-02-01	LM_LH_ADR228	40.2	\N
2023-02-01	LM_LH_ADR232	72.62	\N
2023-02-01	LM_LH_ADR233	54.3	\N
2023-02-01	LM_LH_ADR230	1.8	\N
2023-02-01	LM_ELE_ADR114	27.81	\N
2023-02-01	LM_ELE_ADR117	24666.06	\N
2023-02-01	LM_WOD_ADR132	339.76	\N
2023-02-01	LM_WOD_ADR133	388.81	\N
2023-02-01	LM_WOD_ADR134	19.44	\N
2023-02-01	LM_WOD_ADR135	0	\N
2023-02-01	LM_WOD_ADR136	78.11	\N
2023-02-01	LM_WOD_ADR139	1812.56	\N
2023-02-01	LM_WOD_ADR141	17	\N
2023-02-01	LM_WOD_ADR142	36	\N
2023-02-01	LM_WOD_ADR143	582.86	\N
2023-02-01	LM_WOD_ADR146	35270	\N
2023-02-01	LM_WOD_ADR148	0.05	\N
2023-02-01	LM_WOD_ADR150	49.84	\N
2023-02-01	LM_WOD_ADR237	926.83	\N
2023-02-01	LM_WOD_ADR238	3411.32	\N
2023-02-01	LM_WOD_ADR239	44.56	\N
2023-02-01	LM_WOD_ADR240	186.24	\N
2023-02-01	LM_WOD_ADR241	632.21	\N
2023-02-01	LM_ELE_ADR121	85.44	\N
2023-02-01	LM_ELE_ADR128	0	\N
2023-02-01	LM_WOD_ADR247_Solution Space	767.92	\N
2023-02-01	LM_WOD_ADR250_Solution Space	270.69	\N
2023-02-01	LM_WOD_ADR30	0	\N
2023-02-01	LM_ELE_ADR001	82984.83	\N
2023-02-01	LM_ELE_ADR002	102869.34	\N
2023-02-01	LM_ELE_ADR003	134148.08	\N
2023-02-01	LM_ELE_ADR006	0	\N
2023-02-01	LM_ELE_ADR007	152649.22	\N
2023-02-01	LM_ELE_ADR009	204605.28	\N
2023-02-01	LM_ELE_ADR011	184577.89	\N
2023-02-01	LM_ELE_ADR013	253299.28	\N
2023-02-01	LM_ELE_ADR014	17985.66	\N
2023-02-01	LM_ELE_ADR015	149805.83	\N
2023-02-01	LM_ELE_ADR016	1033610.63	\N
2023-02-01	LM_ELE_ADR018	15535.51	\N
2023-02-01	LM_ELE_ADR020	160245.81	\N
2023-02-01	LM_ELE_ADR022	208138.17	\N
2023-02-01	LM_ELE_ADR023	45126.16	\N
2023-02-01	LM_ELE_ADR025	797463.81	\N
2023-02-01	LM_ELE_ADR028	20122.77	\N
2023-02-01	LM_ELE_ADR034	39320.56	\N
2023-02-01	LM_ELE_ADR036	103145.74	\N
2023-02-01	LM_ELE_ADR039	453434.19	\N
2023-02-01	LM_ELE_ADR040	40940.66	\N
2023-02-01	LM_ELE_ADR042	4069.74	\N
2023-02-01	LM_ELE_ADR044	7815.58	\N
2023-02-01	LM_ELE_ADR048	8248.46	\N
2023-02-01	LM_ELE_ADR051	7883.53	\N
2023-02-01	LM_ELE_ADR053	39941.28	\N
2023-02-01	LM_ELE_ADR055	0	\N
2023-02-01	LM_ELE_ADR056	0	\N
2023-02-01	LM_ELE_ADR063	190	\N
2023-02-01	LM_ELE_ADR064	0	\N
2023-02-01	LM_ELE_ADR058	95801.05	\N
2023-02-01	LM_ELE_ADR072	33105	\N
2023-02-01	LM_ELE_ADR074	98230	\N
2023-02-01	LM_ELE_ADR076	0	\N
2023-02-01	LM_ELE_ADR081	84610.09	\N
2023-02-01	LM_ELE_ADR085	76268.23	\N
2023-02-01	LM_ELE_ADR090	52085.98	\N
2023-02-01	LM_ELE_ADR107	106678.06	\N
2023-02-01	LM_ELE_ADR108	8401.32	\N
2023-02-01	LM_ELE_ADR109	2045.53	\N
2023-02-01	LM_ELE_ADR110	564	\N
2023-02-01	LM_ELE_ADR113	64746.69	\N
2023-02-01	LM_ELE_ADR087	100984.3	\N
2023-02-01	LM_LC_ADR_B45	286.29	\N
2023-02-01	LM_LH_ADR_B46	49.35	\N
2023-02-01	LM_LH_ADR_B47	150.2	\N
2023-02-01	LM_WOD_ADR_B74	45.37	\N
2023-02-01	LM_ELE_ADR_B06	574234.63	\N
2023-02-01	LM_ELE_ADR046	0	\N
2023-02-01	LM_ELE_ADR010	137238.44	\N
2023-02-01	LM_ELE_ADR043	3330.99	\N
2023-02-01	LM_ELE_ADR_B11	39738.29	\N
2023-02-01	LM_WOD_ADR242	52.55	\N
2023-02-01	LM_ELE_ADR124	158128.05	\N
2023-02-01	LM_ELE_ADR112	782472.44	\N
2023-02-01	LM_WOD_ADR_B75	192.17	\N
2023-02-01	LM_ELE_ADR091	15441.95	\N
2023-02-01	LM_WOD_ADR_B80	159.77	\N
2023-02-01	LM_WOD_ADR_B81	55.46	\N
2023-02-01	LM_ELE_ADR_B04	321888.84	\N
2023-02-01	LM_ELE_ADR_B05	333957.69	\N
2023-02-01	LM_ELE_ADR_B09	333729.78	\N
2023-02-01	LM_ELE_ADR_B01	0	\N
2023-02-01	LM_ELE_ADR_B10	36015.22	\N
2023-02-01	LM_ELE_ADR_B02	0	\N
2023-02-01	LM_LC_ADR_B18	19.5	\N
2023-02-01	LM_LC_ADR_B20	71.37	\N
2023-02-01	LM_LC_ADR_B22	56.38	\N
2023-02-01	LM_LC_ADR_B24	10.69	\N
2023-02-01	LM_LC_ADR_B31	535.8	\N
2023-02-01	LM_LC_ADR_B41	607.2	\N
2023-02-01	LM_LC_ADR_B43	10.4	\N
2023-02-01	LM_LH_ADR_B23	73.9	\N
2023-02-01	LM_LH_ADR_B25	77.7	\N
2023-02-01	LM_LH_ADR_B27	166.8	\N
2023-02-01	LM_LH_ADR_B35	0	\N
2023-02-01	LM_LH_ADR_B36	0	\N
2023-02-01	LM_LH_ADR_B38	80.8	\N
2023-02-01	LM_LH_ADR_B44	4.9	\N
2023-02-01	LM_WOD_ADR_B76	1908.29	\N
2023-02-01	LM_WOD_ADR_B77	9.11	\N
2023-02-01	LM_LC_ADR_B16	38.83	\N
2023-02-01	LM_LH_ADR_B17	66.6	\N
2023-02-01	LM_WOD_ADR_B79	515.65	\N
2023-02-01	LM_ELE_ADR_B12	21605.75	\N
2023-02-01	LM_ELE_ADR_B13	15053.19	\N
2023-02-01	LM_LC_ADR_B46	59.52	\N
2023-02-01	LM_LC_ADR193	0	\N
2023-02-01	LM_ELE_ADR125	5501.38	\N
2023-02-01	LM_ELE_ADR069	347572	\N
2023-02-01	LM_ELE_ADR075	13565	\N
2023-02-01	LM_LC_ADR159	9980	\N
2023-02-01	LM_LC_ADR160	19720	\N
2023-02-01	LM_LH_ADR167	14870	\N
2023-02-01	LM_WOD_ADR236	36.3	\N
2023-02-01	zdemontowany580	6	\N
2023-02-01	zdemontowany600	3194	\N
2023-03-01	LM_LC_ADR170	69.96	\N
2023-03-01	LM_LC_ADR172	163.76	\N
2023-03-01	LM_LC_ADR179	129.76	\N
2023-03-01	LM_ELE_ADR021	363299.09	\N
2023-03-01	LM_ELE_ADR078	62038	\N
2023-03-01	LM_ELE_ADR066	0	\N
2023-03-01	LM_ELE_ADR080	202360.88	\N
2023-03-01	LM_LH_ADR199	164.6	\N
2023-03-01	LM_ELE_ADR115	29590.49	\N
2023-03-01	LM_WOD_ADR249_Solution Space	149.92	\N
2023-03-01	LM_WOD_MAIN_W	0	\N
2023-03-01	LM_LC_ADR123	568.1	\N
2023-03-01	LM_LC_ADR151	34684	\N
2023-03-01	LM_LC_ADR153	11242	\N
2023-03-01	LM_LC_ADR154	3226	\N
2023-03-01	LM_LC_ADR155	8308.6	\N
2023-03-01	LM_LC_ADR157	1251.7	\N
2023-03-01	LM_LC_ADR158	439.3	\N
2023-03-01	LM_LC_ADR162	995.7	\N
2023-03-01	LM_LC_ADR168	140	\N
2023-03-01	LM_LC_ADR173	123.42	\N
2023-03-01	LM_LC_ADR174	262.63	\N
2023-03-01	LM_LC_ADR175	0	\N
2023-03-01	LM_LC_ADR176	86.4	\N
2023-03-01	LM_LC_ADR178	175.45	\N
2023-03-01	LM_LC_ADR184	45.23	\N
2023-03-01	LM_LC_ADR186	26.44	\N
2023-03-01	LM_LC_ADR187	32.69	\N
2023-03-01	LM_LC_ADR209	0	\N
2023-03-01	LM_LC_ADR32	0	\N
2023-03-01	LM_LC_ADR82	55.56	\N
2023-03-01	LM_LH_ADR122	23.1	\N
2023-03-01	LM_LH_ADR189	79.79	\N
2023-03-01	LM_LH_ADR195	532.3	\N
2023-03-01	LM_LH_ADR196	9	\N
2023-03-01	LM_LH_ADR198	0	\N
2023-03-01	LM_LH_ADR200	57.7	\N
2023-03-01	LM_LH_ADR203	245	\N
2023-03-01	LM_LH_ADR204	123.4	\N
2023-03-01	LM_LH_ADR208	398.3	\N
2023-03-01	LM_LH_ADR211	56	\N
2023-03-01	LM_LH_ADR212	293.9	\N
2023-03-01	LM_LH_ADR216	44.08	\N
2023-03-01	LM_LH_ADR218	586.2	\N
2023-03-01	LM_LH_ADR221	481.5	\N
2023-03-01	LM_LH_ADR222	0	\N
2023-03-01	LM_LH_ADR227	57.4	\N
2023-03-01	LM_LH_ADR229	0	\N
2023-03-01	LM_LH_ADR231	0	\N
2023-03-01	LM_LH_ADR234	0	\N
2023-03-01	LM_LH_ADR235	105.3	\N
2023-03-01	LM_LH_ADR33	0	\N
2023-03-01	LM_ELE_ADR008	123161.13	\N
2023-03-01	LM_ELE_ADR012	107333.73	\N
2023-03-01	LM_ELE_ADR017	15128.99	\N
2023-03-01	LM_ELE_ADR019	4859.35	\N
2023-03-01	LM_ELE_ADR024	149895.75	\N
2023-03-01	LM_ELE_ADR027	36475.91	\N
2023-03-01	LM_LC_ADR163	65.43	\N
2023-03-01	LM_LC_ADR164	0.02	\N
2023-03-01	LM_LH_ADR201	143.5	\N
2023-03-01	LM_ELE_ADR029	18499.56	\N
2023-03-01	LM_ELE_ADR031	220905.14	\N
2023-03-01	LM_ELE_ADR038	454392.28	\N
2023-03-01	LM_ELE_ADR041	77762.1	\N
2023-03-01	LM_ELE_ADR045	7057.55	\N
2023-03-01	LM_ELE_ADR047	6352.41	\N
2023-03-01	LM_ELE_ADR049	16902.35	\N
2023-03-01	LM_ELE_ADR052	12995.82	\N
2023-03-01	LM_ELE_ADR054	36038.21	\N
2023-03-01	LM_ELE_ADR057	7187.96	\N
2023-03-01	LM_ELE_ADR059	28727.14	\N
2023-03-01	LM_ELE_ADR060	0	\N
2023-03-01	LM_ELE_ADR061	0	\N
2023-03-01	LM_ELE_ADR062	27924	\N
2023-03-01	LM_ELE_ADR065	0	\N
2023-03-01	LM_ELE_ADR067	336	\N
2023-03-01	LM_ELE_ADR068	19591	\N
2023-03-01	LM_ELE_ADR070	88	\N
2023-03-01	LM_ELE_ADR071	99730	\N
2023-03-01	LM_ELE_ADR073	88	\N
2023-03-01	LM_ELE_ADR077	1063	\N
2023-03-01	LM_ELE_ADR084	63332.33	\N
2023-03-01	LM_ELE_ADR086	20347.16	\N
2023-03-01	LM_ELE_ADR088	49360.2	\N
2023-03-01	LM_ELE_ADR094	1516.44	\N
2023-03-01	LM_ELE_ADR095	126059.43	\N
2023-03-01	LM_ELE_ADR097	44672.53	\N
2023-03-01	LM_ELE_ADR098	4229.83	\N
2023-03-01	LM_ELE_ADR099	113650.72	\N
2023-03-01	LM_ELE_ADR100	24908.97	\N
2023-03-01	LM_ELE_ADR101	10010.6	\N
2023-03-01	LM_ELE_ADR111	368.05	\N
2023-03-01	LM_ELE_ADR116	15151.01	\N
2023-03-01	LM_ELE_ADR118	24907.88	\N
2023-03-01	LM_ELE_ADR119	88770.67	\N
2023-03-01	LM_ELE_ADR120	117600.03	\N
2023-03-01	LM_WOD_ADR129	151.8	\N
2023-03-01	LM_WOD_ADR140	129.27	\N
2023-03-01	LM_WOD_ADR147	72.42	\N
2023-03-01	LM_WOD_ADR246_Solution Space	702.12	\N
2023-03-01	LM_WOD_ADR248_Solution Space	66.73	\N
2023-03-01	LM_ELE_ADR_B03	148793.31	\N
2023-03-01	LM_ELE_ADR_B07	119908.18	\N
2023-03-01	LM_ELE_ADR_B08	178095.75	\N
2023-03-01	LM_LC_ADR_B26	179.66	\N
2023-03-01	LM_LC_ADR_B30	518.8	\N
2023-03-01	LM_LC_ADR_B32	1218.9	\N
2023-03-01	LM_LC_ADR_B33	1036.1	\N
2023-03-01	LM_LH_ADR_B19	118.5	\N
2023-03-01	LM_LH_ADR_B21	226.5	\N
2023-03-01	LM_LH_ADR_B34	0	\N
2023-03-01	LM_LH_ADR_B37	0.4	\N
2023-03-01	LM_LH_ADR_B39	114.3	\N
2023-03-01	LM_LH_ADR_B40	194.8	\N
2023-03-01	LM_LH_ADR_B42	0	\N
2023-03-01	LM_WOD_ADR_B78	209.28	\N
2023-03-01	LM_LC_ADR102	66.87	\N
2023-03-01	LM_LC_ADR103	73.42	\N
2023-03-01	LM_LC_ADR104	105.33	\N
2023-03-01	LM_LC_ADR152	5686.1	\N
2023-03-01	LM_LC_ADR149	0.91	\N
2023-03-01	LM_LC_ADR156	4341	\N
2023-03-01	LM_LC_ADR171	384.81	\N
2023-03-01	LM_LC_ADR165	62.6	\N
2023-03-01	LM_LC_ADR166	48.58	\N
2023-03-01	LM_LC_ADR180	173.61	\N
2023-03-01	LM_LC_ADR181	0.1	\N
2023-03-01	LM_LC_ADR182	118.04	\N
2023-03-01	LM_LC_ADR183	1.42	\N
2023-03-01	LM_LC_ADR185	22.63	\N
2023-03-01	LM_LC_ADR161	1632.9	\N
2023-03-01	LM_LC_ADR224	216.77	\N
2023-03-01	LM_LC_ADR89	50	\N
2023-03-01	LM_LC_ADR93	49.3	\N
2023-03-01	LM_LH_ADR145	10.07	\N
2023-03-01	LM_LH_ADR188	32.18	\N
2023-03-01	LM_LH_ADR190	7.89	\N
2023-03-01	LM_LH_ADR191	18.8	\N
2023-03-01	LM_LH_ADR192	0	\N
2023-03-01	LM_LH_ADR194	0	\N
2023-03-01	LM_LH_ADR207	501.9	\N
2023-03-01	LM_LH_ADR197	1438.5	\N
2023-03-01	LM_LH_ADR215	0	\N
2023-03-01	LM_LH_ADR219	0.04	\N
2023-03-01	LM_LH_ADR220	147.33	\N
2023-03-01	LM_LH_ADR223	271.7	\N
2023-03-01	LM_LH_ADR225	85	\N
2023-03-01	LM_LH_ADR226	89.04	\N
2023-03-01	LM_LH_ADR217	601.3	\N
2023-03-01	LM_LH_ADR228	40.2	\N
2023-03-01	LM_LH_ADR232	73.83	\N
2023-03-01	LM_LH_ADR233	54.3	\N
2023-03-01	LM_LH_ADR230	1.8	\N
2023-03-01	LM_ELE_ADR114	27.81	\N
2023-03-01	LM_ELE_ADR117	24751.4	\N
2023-03-01	LM_WOD_ADR132	341.62	\N
2023-03-01	LM_WOD_ADR133	390.28	\N
2023-03-01	LM_WOD_ADR134	20.17	\N
2023-03-01	LM_WOD_ADR135	0	\N
2023-03-01	LM_WOD_ADR136	75.97	\N
2023-03-01	LM_WOD_ADR139	1837.83	\N
2023-03-01	LM_WOD_ADR141	17	\N
2023-03-01	LM_WOD_ADR142	36	\N
2023-03-01	LM_WOD_ADR143	582.86	\N
2023-03-01	LM_WOD_ADR146	35710.7	\N
2023-03-01	LM_WOD_ADR148	0.01	\N
2023-03-01	LM_WOD_ADR150	50.63	\N
2023-03-01	LM_WOD_ADR237	926.83	\N
2023-03-01	LM_WOD_ADR238	3436.93	\N
2023-03-01	LM_WOD_ADR239	44.9	\N
2023-03-01	LM_WOD_ADR240	191.38	\N
2023-03-01	LM_WOD_ADR241	678.59	\N
2023-03-01	LM_ELE_ADR121	292226.31	\N
2023-03-01	LM_ELE_ADR128	0	\N
2023-03-01	LM_WOD_ADR247_Solution Space	776.23	\N
2023-03-01	LM_WOD_ADR250_Solution Space	272.82	\N
2023-03-01	LM_WOD_ADR30	0	\N
2023-03-01	LM_ELE_ADR001	84531.76	\N
2023-03-01	LM_ELE_ADR002	107228.75	\N
2023-03-01	LM_ELE_ADR003	135723.55	\N
2023-03-01	LM_ELE_ADR006	0	\N
2023-03-01	LM_ELE_ADR007	157484.8	\N
2023-03-01	LM_ELE_ADR009	205692.5	\N
2023-03-01	LM_ELE_ADR011	185445.8	\N
2023-03-01	LM_ELE_ADR013	257023.89	\N
2023-03-01	LM_ELE_ADR014	18370.12	\N
2023-03-01	LM_ELE_ADR015	151311.72	\N
2023-03-01	LM_ELE_ADR016	1040437.94	\N
2023-03-01	LM_ELE_ADR018	15758.57	\N
2023-03-01	LM_ELE_ADR020	163397.23	\N
2023-03-01	LM_ELE_ADR022	214409.38	\N
2023-03-01	LM_ELE_ADR023	46184.61	\N
2023-03-01	LM_ELE_ADR025	827827.19	\N
2023-03-01	LM_ELE_ADR028	20143.3	\N
2023-03-01	LM_ELE_ADR034	40271.11	\N
2023-03-01	LM_ELE_ADR036	104968.27	\N
2023-03-01	LM_ELE_ADR039	466917.72	\N
2023-03-01	LM_ELE_ADR040	42285.22	\N
2023-03-01	LM_ELE_ADR042	4123.56	\N
2023-03-01	LM_ELE_ADR044	7912.23	\N
2023-03-01	LM_ELE_ADR048	8363.63	\N
2023-03-01	LM_ELE_ADR051	7976.87	\N
2023-03-01	LM_ELE_ADR053	41056.58	\N
2023-03-01	LM_ELE_ADR055	0	\N
2023-03-01	LM_ELE_ADR056	0	\N
2023-03-01	LM_ELE_ADR063	190	\N
2023-03-01	LM_ELE_ADR064	0	\N
2023-03-01	LM_ELE_ADR058	97037.38	\N
2023-03-01	LM_ELE_ADR072	33684	\N
2023-03-01	LM_ELE_ADR074	99730	\N
2023-03-01	LM_ELE_ADR076	0	\N
2023-03-01	LM_ELE_ADR081	88653.81	\N
2023-03-01	LM_ELE_ADR085	78352.92	\N
2023-03-01	LM_ELE_ADR090	53227.9	\N
2023-03-01	LM_ELE_ADR107	108779.65	\N
2023-03-01	LM_ELE_ADR108	8403.01	\N
2023-03-01	LM_ELE_ADR109	2047.95	\N
2023-03-01	LM_ELE_ADR110	579.99	\N
2023-03-01	LM_ELE_ADR113	65482.63	\N
2023-03-01	LM_ELE_ADR087	102164.58	\N
2023-03-01	LM_LC_ADR_B45	302.63	\N
2023-03-01	LM_LH_ADR_B46	49.35	\N
2023-03-01	LM_LH_ADR_B47	150.3	\N
2023-03-01	LM_WOD_ADR_B74	45.65	\N
2023-03-01	LM_ELE_ADR_B06	578940.13	\N
2023-03-01	LM_ELE_ADR046	0	\N
2023-03-01	LM_ELE_ADR010	139226.02	\N
2023-03-01	LM_ELE_ADR043	3385.61	\N
2023-03-01	LM_ELE_ADR_B11	40465.4	\N
2023-03-01	LM_WOD_ADR242	52.9	\N
2023-03-01	LM_ELE_ADR124	163121.91	\N
2023-03-01	LM_ELE_ADR112	786894.75	\N
2023-03-01	LM_WOD_ADR_B75	192.3	\N
2023-03-01	LM_ELE_ADR091	15748.2	\N
2023-03-01	LM_WOD_ADR_B80	163.3	\N
2023-03-01	LM_WOD_ADR_B81	56.45	\N
2023-03-01	LM_ELE_ADR_B04	322362.31	\N
2023-03-01	LM_ELE_ADR_B05	337983.56	\N
2023-03-01	LM_ELE_ADR_B09	334388.5	\N
2023-03-01	LM_ELE_ADR_B01	0	\N
2023-03-01	LM_ELE_ADR_B10	36557.56	\N
2023-03-01	LM_ELE_ADR_B02	0	\N
2023-03-01	LM_LC_ADR_B18	19.56	\N
2023-03-01	LM_LC_ADR_B20	71.49	\N
2023-03-01	LM_LC_ADR_B22	56.38	\N
2023-03-01	LM_LC_ADR_B24	10.69	\N
2023-03-01	LM_LC_ADR_B31	553	\N
2023-03-01	LM_LC_ADR_B41	622.8	\N
2023-03-01	LM_LC_ADR_B43	10.6	\N
2023-03-01	LM_LH_ADR_B23	73.9	\N
2023-03-01	LM_LH_ADR_B25	77.7	\N
2023-03-01	LM_LH_ADR_B27	167.1	\N
2023-03-01	LM_LH_ADR_B35	0	\N
2023-03-01	LM_LH_ADR_B36	0	\N
2023-03-01	LM_LH_ADR_B38	80.9	\N
2023-03-01	LM_LH_ADR_B44	4.9	\N
2023-03-01	LM_WOD_ADR_B76	1908.29	\N
2023-03-01	LM_WOD_ADR_B77	9.11	\N
2023-03-01	LM_LC_ADR_B16	38.83	\N
2023-03-01	LM_LH_ADR_B17	66.9	\N
2023-03-01	LM_WOD_ADR_B79	515.65	\N
2023-03-01	LM_ELE_ADR_B12	22018.16	\N
2023-03-01	LM_ELE_ADR_B13	15053.19	\N
2023-03-01	LM_LC_ADR_B46	59.54	\N
2023-03-01	LM_LC_ADR193	0	\N
2023-03-01	LM_ELE_ADR125	5553.81	\N
2023-03-01	LM_ELE_ADR069	347572	\N
2023-03-01	LM_ELE_ADR075	13832	\N
2023-03-01	LM_LC_ADR159	11860	\N
2023-03-01	LM_LC_ADR160	21410	\N
2023-03-01	LM_LH_ADR167	14890	\N
2023-03-01	LM_WOD_ADR236	38.69	\N
2023-03-01	zdemontowany580	6	\N
2023-03-01	zdemontowany600	3194	\N
2023-05-01	LM_LC_ADR170	72.91	\N
2023-04-01	LM_LC_ADR172	167.09	Normal
2023-04-01	LM_LC_ADR179	130.85	Normal
2023-04-01	LM_ELE_ADR021	375231.66	Normal
2023-04-01	LM_ELE_ADR066	0	Normal
2023-04-01	LM_ELE_ADR080	204975.48	Normal
2023-04-01	LM_LH_ADR199	164.6	Normal
2023-04-01	LM_ELE_ADR115	29615.94	Normal
2023-04-01	LM_WOD_ADR249_Solution Space	149.92	Normal
2023-04-01	LM_WOD_MAIN_W	0	Normal
2023-04-01	LM_LC_ADR123	571.5	Normal
2023-04-01	LM_LC_ADR151	35207	Normal
2023-04-01	LM_LC_ADR153	11351	Normal
2023-04-01	LM_LC_ADR154	3310.8	Normal
2023-04-01	LM_LC_ADR155	8447.9	Normal
2023-04-01	LM_LC_ADR157	1251.7	Normal
2023-04-01	LM_LC_ADR158	451.1	Normal
2023-04-01	LM_LC_ADR162	1028.6	Normal
2023-04-01	LM_LC_ADR168	141.7	Normal
2023-04-01	LM_LC_ADR173	126.6	Normal
2023-04-01	LM_LC_ADR175	0	Normal
2023-04-01	LM_LC_ADR176	86.4	Normal
2023-04-01	LM_LC_ADR178	181.13	Normal
2023-04-01	LM_LC_ADR184	45.27	Normal
2023-04-01	LM_LC_ADR186	27.6	Normal
2023-04-01	LM_LC_ADR187	32.69	Normal
2023-04-01	LM_LC_ADR209	0	Normal
2023-04-01	LM_LC_ADR32	0	Normal
2023-04-01	LM_LC_ADR82	59.96	Normal
2023-04-01	LM_LH_ADR122	23.3	Normal
2023-04-01	LM_LH_ADR189	80.02	Normal
2023-04-01	LM_LH_ADR195	532.4	Normal
2023-04-01	LM_LH_ADR196	9	Normal
2023-04-01	LM_LH_ADR198	0	Normal
2023-04-01	LM_LH_ADR200	58.4	Normal
2023-04-01	LM_LH_ADR203	245.6	Normal
2023-04-01	LM_LH_ADR227	57.5	Normal
2023-04-01	LM_LH_ADR229	0	Normal
2023-04-01	LM_LH_ADR231	0	Normal
2023-04-01	LM_LH_ADR234	0	Normal
2023-04-01	LM_LH_ADR33	0	Normal
2023-04-01	LM_ELE_ADR008	125282.4	Normal
2023-04-01	LM_ELE_ADR012	109354.98	Normal
2023-04-01	LM_ELE_ADR017	15286.18	Normal
2023-04-01	LM_ELE_ADR019	4859.35	Normal
2023-04-01	LM_ELE_ADR027	36475.91	Normal
2023-04-01	LM_LC_ADR163	69.62	Normal
2023-04-01	LM_LC_ADR164	0.02	Normal
2023-04-01	LM_LH_ADR201	145.4	Normal
2023-04-01	LM_ELE_ADR031	224273.41	Normal
2023-04-01	LM_ELE_ADR038	460074.47	Normal
2023-04-01	LM_ELE_ADR041	79212.01	Normal
2023-04-01	LM_ELE_ADR047	6459.96	Normal
2023-04-01	LM_ELE_ADR052	13174.38	Normal
2023-04-01	LM_ELE_ADR054	36543.52	Normal
2023-04-01	LM_ELE_ADR057	7237.7	Normal
2023-04-01	LM_ELE_ADR059	28811.73	Normal
2023-04-01	LM_ELE_ADR060	0	Normal
2023-04-01	LM_ELE_ADR062	27924	Normal
2023-04-01	LM_ELE_ADR065	0	Normal
2023-04-01	LM_ELE_ADR067	336	Normal
2023-04-01	LM_ELE_ADR068	20745	Normal
2023-04-01	LM_ELE_ADR071	101408	Normal
2023-04-01	LM_ELE_ADR073	88	Normal
2023-05-01	LM_LC_ADR172	168.45	\N
2023-04-01	LM_LH_ADR212	302.5	Normal
2023-04-01	LM_LH_ADR216	44.64	Normal
2023-04-01	LM_LH_ADR218	597.9	Normal
2023-04-01	LM_ELE_ADR077	1063	Normal
2023-04-01	LM_ELE_ADR084	64390.7	Normal
2023-04-01	LM_ELE_ADR086	20859.93	Normal
2023-04-01	LM_ELE_ADR095	128497.9	Normal
2023-04-01	LM_ELE_ADR097	45832.1	Normal
2023-04-01	LM_ELE_ADR098	4229.83	Normal
2023-04-01	LM_ELE_ADR099	116849.51	Normal
2023-04-01	LM_ELE_ADR101	10226.26	Normal
2023-04-01	LM_ELE_ADR111	368.05	Normal
2023-04-01	LM_ELE_ADR116	15151.01	Normal
2023-04-01	LM_ELE_ADR118	25375.77	Normal
2023-04-01	LM_ELE_ADR120	120365.15	Normal
2023-04-01	LM_WOD_ADR129	151.8	Normal
2023-04-01	LM_WOD_ADR140	129.27	Normal
2023-04-01	LM_WOD_ADR147	72.42	Normal
2023-04-01	LM_ELE_ADR_B03	150643.23	Normal
2023-04-01	LM_ELE_ADR_B07	121628.93	Normal
2023-04-01	LM_ELE_ADR_B08	180629.45	Normal
2023-04-01	LM_LC_ADR_B26	179.68	Normal
2023-04-01	LM_LC_ADR_B32	1255.9	Fault
2023-04-01	LM_LH_ADR_B19	119.5	Normal
2023-04-01	LM_LH_ADR_B21	227.5	Normal
2023-04-01	LM_LH_ADR_B34	0	Normal
2023-04-01	LM_LH_ADR_B37	0.4	Normal
2023-04-01	LM_LH_ADR_B39	114.4	Normal
2023-04-01	LM_LH_ADR_B42	0	Normal
2023-04-01	LM_WOD_ADR_B78	209.28	Normal
2023-04-01	LM_LC_ADR102	68.71	Normal
2023-04-01	LM_LC_ADR103	75.46	Normal
2023-04-01	LM_LC_ADR152	5774.6	Normal
2023-04-01	LM_LC_ADR149	0.94	Normal
2023-04-01	LM_LC_ADR156	4448.3	Normal
2023-04-01	LM_LC_ADR171	398.4	Normal
2023-04-01	LM_LC_ADR165	64.59	Normal
2023-04-01	LM_LC_ADR180	179.15	Normal
2023-04-01	LM_LC_ADR182	123.16	Normal
2023-04-01	LM_LC_ADR183	1.44	Normal
2023-04-01	LM_LC_ADR185	22.63	Normal
2023-04-01	LM_LC_ADR224	223.94	Normal
2023-04-01	LM_LC_ADR89	51.76	Normal
2023-04-01	LM_LC_ADR93	51.02	Normal
2023-04-01	LM_LH_ADR145	10.07	Normal
2023-04-01	LM_LH_ADR190	7.89	Normal
2023-04-01	LM_LH_ADR191	18.8	Normal
2023-04-01	LM_LH_ADR192	0	Normal
2023-04-01	LM_LH_ADR194	0	Normal
2023-04-01	LM_LH_ADR207	512.6	Normal
2023-04-01	LM_LH_ADR215	0	Normal
2023-04-01	LM_LH_ADR219	0.04	Normal
2023-04-01	LM_LH_ADR220	147.33	Normal
2023-04-01	LM_LH_ADR223	272.1	Normal
2023-04-01	LM_LH_ADR217	605.9	Normal
2023-04-01	LM_LH_ADR228	40.4	Normal
2023-04-01	LM_LH_ADR232	75.16	Normal
2023-04-01	LM_LH_ADR233	54.3	Normal
2023-04-01	LM_ELE_ADR114	361669.38	Normal
2023-04-01	LM_ELE_ADR117	24763.93	Normal
2023-04-01	LM_WOD_ADR132	341.62	Normal
2023-04-01	LM_WOD_ADR133	390.28	Normal
2023-04-01	LM_WOD_ADR134	21.34	Normal
2023-04-01	LM_WOD_ADR136	75.97	Normal
2023-04-01	LM_WOD_ADR139	1865.73	Normal
2023-04-01	LM_WOD_ADR141	17	Normal
2023-04-01	LM_WOD_ADR142	36	Normal
2023-04-01	LM_WOD_ADR143	582.86	Normal
2023-04-01	LM_WOD_ADR148	0.05	Normal
2023-04-01	LM_WOD_ADR150	51.59	Normal
2023-04-01	LM_WOD_ADR238	3436.93	Normal
2023-04-01	LM_WOD_ADR240	197.1	Normal
2023-04-01	LM_WOD_ADR241	726.41	Normal
2023-04-01	LM_ELE_ADR121	301782.06	Unknown
2023-04-01	LM_ELE_ADR001	86345.66	Normal
2023-04-01	LM_ELE_ADR002	111019.7	Normal
2023-04-01	LM_ELE_ADR003	137441.92	Normal
2023-04-01	LM_ELE_ADR006	0	Normal
2023-04-01	LM_ELE_ADR007	162398.14	Normal
2023-04-01	LM_ELE_ADR009	207917.05	Normal
2023-04-01	LM_ELE_ADR011	185688.38	Normal
2023-04-01	LM_ELE_ADR013	257297.94	Normal
2023-04-01	LM_ELE_ADR014	18794.91	Normal
2023-04-01	LM_ELE_ADR015	152944.63	Normal
2023-04-01	LM_ELE_ADR016	1048560	Normal
2023-04-01	LM_ELE_ADR018	15999.75	Normal
2023-04-01	LM_ELE_ADR022	219184.28	Normal
2023-04-01	LM_ELE_ADR023	47324.73	Normal
2023-04-01	LM_ELE_ADR025	857506.31	Normal
2023-04-01	LM_ELE_ADR028	20164.87	Normal
2023-04-01	LM_ELE_ADR034	41320.17	Normal
2023-04-01	LM_ELE_ADR036	106660.43	Normal
2023-04-01	LM_ELE_ADR039	477747.06	Normal
2023-04-01	LM_ELE_ADR040	43428.96	Normal
2023-04-01	LM_ELE_ADR044	8035.53	Normal
2023-04-01	LM_ELE_ADR048	8485.55	Normal
2023-04-01	LM_ELE_ADR051	8080.75	Normal
2023-04-01	LM_ELE_ADR053	42255.18	Normal
2023-04-01	LM_ELE_ADR055	0	Normal
2023-04-01	LM_ELE_ADR063	190	Normal
2023-04-01	LM_ELE_ADR064	0	Normal
2023-04-01	LM_ELE_ADR058	98370.7	Normal
2023-04-01	LM_ELE_ADR076	0	Normal
2023-04-01	LM_ELE_ADR081	90289.48	Normal
2023-04-01	LM_ELE_ADR085	80551.34	Normal
2023-04-01	LM_ELE_ADR090	53838.21	Normal
2023-04-01	LM_ELE_ADR107	111111.31	Normal
2023-04-01	LM_ELE_ADR109	2049.25	Normal
2023-04-01	LM_ELE_ADR110	599.08	Normal
2023-04-01	LM_ELE_ADR113	66661.13	Normal
2023-04-01	LM_ELE_ADR087	103524.55	Normal
2023-04-01	LM_LC_ADR_B45	314.78	Fault
2023-04-01	LM_LC_ADR170	71.88	Normal
2023-04-01	LM_ELE_ADR078	62372	Normal
2023-04-01	LM_LC_ADR174	270.7	Normal
2023-04-01	LM_LH_ADR204	124.3	Normal
2023-04-01	LM_LH_ADR208	404.4	Normal
2023-04-01	LM_LH_ADR211	57	Normal
2023-04-01	LM_LH_ADR221	492	Normal
2023-04-01	LM_LH_ADR222	0	Normal
2023-04-01	LM_LH_ADR235	105.6	Normal
2023-04-01	LM_ELE_ADR024	151819.39	Normal
2023-04-01	LM_ELE_ADR029	19014.8	Normal
2023-04-01	LM_ELE_ADR045	7168.66	Normal
2023-04-01	LM_ELE_ADR049	17121.44	Normal
2023-04-01	LM_ELE_ADR061	0	Normal
2023-04-01	LM_ELE_ADR070	88	Normal
2023-04-01	LM_ELE_ADR088	50543.44	Normal
2023-04-01	LM_ELE_ADR094	1519.78	Normal
2023-04-01	LM_ELE_ADR100	25707.94	Normal
2023-04-01	LM_ELE_ADR119	90070.16	Normal
2023-04-01	LM_WOD_ADR246_Solution Space	702.12	Normal
2023-04-01	LM_WOD_ADR248_Solution Space	66.73	Normal
2023-04-01	LM_LC_ADR_B30	525.3	Fault
2023-04-01	LM_LC_ADR_B33	1053	Fault
2023-04-01	LM_LH_ADR_B40	195.6	Normal
2023-04-01	LM_LC_ADR104	109.09	Normal
2023-04-01	LM_LC_ADR166	50.02	Normal
2023-04-01	LM_LC_ADR181	0.1	Normal
2023-04-01	LM_LC_ADR161	1646.6	Normal
2023-04-01	LM_LH_ADR188	32.18	Normal
2023-04-01	LM_LH_ADR197	1442.4	Normal
2023-04-01	LM_LH_ADR225	85	Normal
2023-04-01	LM_LH_ADR226	90.01	Normal
2023-04-01	LM_LH_ADR230	1.8	Normal
2023-04-01	LM_WOD_ADR135	0	Normal
2023-04-01	LM_WOD_ADR146	36179.7	Normal
2023-04-01	LM_WOD_ADR237	926.83	Normal
2023-04-01	LM_WOD_ADR239	44.9	Normal
2023-04-01	LM_ELE_ADR128	0	Normal
2023-04-01	LM_WOD_ADR247_Solution Space	776.23	Normal
2023-04-01	LM_WOD_ADR250_Solution Space	272.82	Normal
2023-04-01	LM_WOD_ADR30	0	Normal
2023-04-01	LM_ELE_ADR020	166432.73	Normal
2023-04-01	LM_ELE_ADR042	4183.55	Normal
2023-04-01	LM_ELE_ADR056	0	Normal
2023-04-01	LM_ELE_ADR072	34328	Normal
2023-04-01	LM_ELE_ADR074	101408	Normal
2023-04-01	LM_ELE_ADR108	8403.6	Normal
2023-04-01	LM_LH_ADR_B46	49.35	Fault
2023-04-01	LM_LH_ADR_B47	150.9	Fault
2023-04-01	LM_WOD_ADR_B74	45.65	Normal
2023-04-01	LM_ELE_ADR_B06	585104.56	Normal
2023-04-01	LM_ELE_ADR046	0	Normal
2023-04-01	LM_ELE_ADR010	141469.16	Normal
2023-04-01	LM_ELE_ADR043	3446	Normal
2023-04-01	LM_ELE_ADR_B11	41251.9	Fault
2023-04-01	LM_WOD_ADR242	52.9	Normal
2023-04-01	LM_ELE_ADR124	168546.56	Normal
2023-04-01	LM_ELE_ADR112	792019.5	Normal
2023-04-01	LM_WOD_ADR_B75	192.3	Normal
2023-04-01	LM_ELE_ADR091	16084.07	Normal
2023-04-01	LM_WOD_ADR_B80	167.88	Normal
2023-04-01	LM_WOD_ADR_B81	57.68	Normal
2023-04-01	LM_ELE_ADR_B04	322880.75	Normal
2023-04-01	LM_ELE_ADR_B05	342110.84	Normal
2023-04-01	LM_ELE_ADR_B09	334857.81	Fault
2023-04-01	LM_ELE_ADR_B01	0	Normal
2023-04-01	LM_ELE_ADR_B10	37137.55	Fault
2023-04-01	LM_ELE_ADR_B02	0	Normal
2023-04-01	LM_LC_ADR_B18	19.63	Normal
2023-04-01	LM_LC_ADR_B20	71.61	Normal
2023-04-01	LM_LC_ADR_B22	56.38	Normal
2023-04-01	LM_LC_ADR_B24	10.69	Normal
2023-04-01	LM_LC_ADR_B31	566.8	Fault
2023-04-01	LM_LC_ADR_B41	634.1	Fault
2023-04-01	LM_LC_ADR_B43	10.7	Fault
2023-04-01	LM_LH_ADR_B23	73.9	Normal
2023-04-01	LM_LH_ADR_B25	77.7	Normal
2023-04-01	LM_LH_ADR_B27	167.5	Normal
2023-04-01	LM_LH_ADR_B35	0	Normal
2023-04-01	LM_LH_ADR_B36	0	Normal
2023-04-01	LM_LH_ADR_B38	81.1	Normal
2023-04-01	LM_LH_ADR_B44	4.9	Normal
2023-04-01	LM_WOD_ADR_B76	1908.29	Normal
2023-04-01	LM_WOD_ADR_B77	9.11	Normal
2023-04-01	LM_LC_ADR_B16	38.83	Normal
2023-04-01	LM_LH_ADR_B17	67.3	Normal
2023-04-01	LM_WOD_ADR_B79	515.65	Normal
2023-04-01	LM_ELE_ADR_B12	22374.41	Normal
2023-04-01	LM_ELE_ADR_B13	15053.19	Normal
2023-04-01	LM_LC_ADR_B46	59.55	Fault
2023-04-01	LM_LC_ADR193	0	Normal
2023-04-01	LM_ELE_ADR125	5610	Normal
2023-04-01	LM_ELE_ADR069	347572	Normal
2023-04-01	LM_ELE_ADR075	14155	Normal
2023-04-01	LM_LC_ADR159	12470	Normal
2023-04-01	LM_LC_ADR160	22940	Normal
2023-04-01	LM_LH_ADR167	15310	Normal
2023-04-01	LM_WOD_ADR236	41.24	Normal
2023-04-01	zdemontowany580	6	Zdemontowany
2023-04-01	zdemontowany600	3194	Zdemontowany
2023-05-01	LM_LC_ADR179	130.9	\N
2023-05-01	LM_ELE_ADR021	381417.69	\N
2023-05-01	LM_ELE_ADR078	62703	\N
2023-05-01	LM_ELE_ADR066	0	\N
2023-05-01	LM_ELE_ADR080	208266.67	\N
2023-05-01	LM_LH_ADR199	166.4	\N
2023-05-01	LM_ELE_ADR115	29636.15	\N
2023-05-01	LM_WOD_ADR249_Solution Space	149.92	\N
2023-05-01	LM_WOD_MAIN_W	0	\N
2023-05-01	LM_LC_ADR123	574.2	\N
2023-05-01	LM_LC_ADR151	35498	\N
2023-05-01	LM_LC_ADR153	11411	\N
2023-05-01	LM_LC_ADR154	3365.7	\N
2023-05-01	LM_LC_ADR155	8536.3	\N
2023-05-01	LM_LC_ADR157	1259.4	\N
2023-05-01	LM_LC_ADR158	458.1	\N
2023-05-01	LM_LC_ADR162	1043.5	\N
2023-05-01	LM_LC_ADR168	142.2	\N
2023-05-01	LM_LC_ADR173	128.44	\N
2023-05-01	LM_LC_ADR174	278.42	\N
2023-05-01	LM_LC_ADR175	0	\N
2023-05-01	LM_LC_ADR176	86.4	\N
2023-05-01	LM_LC_ADR178	184.99	\N
2023-05-01	LM_LC_ADR184	45.72	\N
2023-05-01	LM_LC_ADR186	28.66	\N
2023-05-01	LM_LC_ADR187	32.69	\N
2023-05-01	LM_LC_ADR209	0	\N
2023-05-01	LM_LC_ADR32	0	\N
2023-05-01	LM_LC_ADR82	62.82	\N
2023-05-01	LM_LH_ADR122	23.9	\N
2023-05-01	LM_LH_ADR189	80.12	\N
2023-05-01	LM_LH_ADR195	533.2	\N
2023-05-01	LM_LH_ADR196	9	\N
2023-05-01	LM_LH_ADR198	0	\N
2023-05-01	LM_LH_ADR200	59.2	\N
2023-05-01	LM_LH_ADR203	249	\N
2023-05-01	LM_LH_ADR204	125.9	\N
2023-05-01	LM_LH_ADR208	411.3	\N
2023-05-01	LM_LH_ADR211	58.6	\N
2023-05-01	LM_LH_ADR212	311.9	\N
2023-05-01	LM_LH_ADR216	46.01	\N
2023-05-01	LM_LH_ADR218	610.5	\N
2023-05-01	LM_LH_ADR221	504.3	\N
2023-05-01	LM_LH_ADR222	0	\N
2023-05-01	LM_LH_ADR227	57.9	\N
2023-05-01	LM_LH_ADR229	0	\N
2023-05-01	LM_LH_ADR231	0	\N
2023-05-01	LM_LH_ADR234	0	\N
2023-05-01	LM_LH_ADR235	106.1	\N
2023-05-01	LM_LH_ADR33	0	\N
2023-05-01	LM_ELE_ADR008	127070.55	\N
2023-05-01	LM_ELE_ADR012	111258.51	\N
2023-05-01	LM_ELE_ADR017	15445.92	\N
2023-05-01	LM_ELE_ADR019	4859.35	\N
2023-05-01	LM_ELE_ADR024	153738.61	\N
2023-05-01	LM_ELE_ADR027	36475.91	\N
2023-05-01	LM_LC_ADR163	69.78	\N
2023-05-01	LM_LC_ADR164	0.02	\N
2023-05-01	LM_LH_ADR201	150	\N
2023-05-01	LM_ELE_ADR029	19497.96	\N
2023-05-01	LM_ELE_ADR031	226910.73	\N
2023-05-01	LM_ELE_ADR038	466763.91	\N
2023-05-01	LM_ELE_ADR041	80531.99	\N
2023-05-01	LM_ELE_ADR045	7270.53	\N
2023-05-01	LM_ELE_ADR047	6559.5	\N
2023-05-01	LM_ELE_ADR049	17330.11	\N
2023-05-01	LM_ELE_ADR052	13351.14	\N
2023-05-01	LM_ELE_ADR054	37046.75	\N
2023-05-01	LM_ELE_ADR057	7281.18	\N
2023-05-01	LM_ELE_ADR059	28953.47	\N
2023-05-01	LM_ELE_ADR060	0	\N
2023-05-01	LM_ELE_ADR061	0	\N
2023-05-01	LM_ELE_ADR062	27924	\N
2023-05-01	LM_ELE_ADR065	0	\N
2023-05-01	LM_ELE_ADR067	336	\N
2023-05-01	LM_ELE_ADR068	21858	\N
2023-05-01	LM_ELE_ADR070	88	\N
2023-05-01	LM_ELE_ADR071	103023	\N
2023-05-01	LM_ELE_ADR073	88	\N
2023-05-01	LM_ELE_ADR077	1063	\N
2023-05-01	LM_ELE_ADR084	65300.24	\N
2023-05-01	LM_ELE_ADR086	21349.72	\N
2023-05-01	LM_ELE_ADR088	51594.39	\N
2023-05-01	LM_ELE_ADR094	1521.18	\N
2023-05-01	LM_ELE_ADR095	130900.73	\N
2023-05-01	LM_ELE_ADR097	47129.52	\N
2023-05-01	LM_ELE_ADR098	4370.03	\N
2023-05-01	LM_ELE_ADR099	119818.35	\N
2023-05-01	LM_ELE_ADR100	26477.79	\N
2023-05-01	LM_ELE_ADR101	10432.67	\N
2023-05-01	LM_ELE_ADR111	368.07	\N
2023-05-01	LM_ELE_ADR116	15151.01	\N
2023-05-01	LM_ELE_ADR118	25789.36	\N
2023-05-01	LM_ELE_ADR119	91310.19	\N
2023-05-01	LM_ELE_ADR120	123092.91	\N
2023-05-01	LM_WOD_ADR129	151.8	\N
2023-05-01	LM_WOD_ADR140	129.27	\N
2023-05-01	LM_WOD_ADR147	72.42	\N
2023-05-01	LM_WOD_ADR246_Solution Space	702.12	\N
2023-05-01	LM_WOD_ADR248_Solution Space	66.73	\N
2023-05-01	LM_ELE_ADR_B03	152500.8	\N
2023-05-01	LM_ELE_ADR_B07	123219.66	\N
2023-05-01	LM_ELE_ADR_B08	182953.69	\N
2023-05-01	LM_LC_ADR_B26	179.68	\N
2023-05-01	LM_LC_ADR_B30	527.8	\N
2023-05-01	LM_LC_ADR_B32	1276	\N
2023-05-01	LM_LC_ADR_B33	1058.8	\N
2023-05-01	LM_LH_ADR_B19	121	\N
2023-05-01	LM_LH_ADR_B21	229.2	\N
2023-05-01	LM_LH_ADR_B34	0	\N
2023-05-01	LM_LH_ADR_B37	0.4	\N
2023-05-01	LM_LH_ADR_B39	114.8	\N
2023-05-01	LM_LH_ADR_B40	196.9	\N
2023-05-01	LM_LH_ADR_B42	0	\N
2023-05-01	LM_WOD_ADR_B78	209.28	\N
2023-05-01	LM_LC_ADR102	69.94	\N
2023-05-01	LM_LC_ADR103	76.88	\N
2023-05-01	LM_LC_ADR104	111.49	\N
2023-05-01	LM_LC_ADR152	5814.4	\N
2023-05-01	LM_LC_ADR149	0.94	\N
2023-05-01	LM_LC_ADR156	4508.6	\N
2023-05-01	LM_LC_ADR171	404.37	\N
2023-05-01	LM_LC_ADR165	66	\N
2023-05-01	LM_LC_ADR166	51	\N
2023-05-01	LM_LC_ADR180	181.96	\N
2023-05-01	LM_LC_ADR181	13.8	\N
2023-05-01	LM_LC_ADR182	125.34	\N
2023-05-01	LM_LC_ADR183	1.44	\N
2023-05-01	LM_LC_ADR185	22.63	\N
2023-05-01	LM_LC_ADR161	1663.5	\N
2023-05-01	LM_LC_ADR224	228.82	\N
2023-05-01	LM_LC_ADR89	52.93	\N
2023-05-01	LM_LC_ADR93	52.17	\N
2023-05-01	LM_LH_ADR145	10.07	\N
2023-05-01	LM_LH_ADR188	32.18	\N
2023-05-01	LM_LH_ADR190	7.89	\N
2023-05-01	LM_LH_ADR191	18.8	\N
2023-05-01	LM_LH_ADR192	0	\N
2023-05-01	LM_LH_ADR194	0	\N
2023-05-01	LM_LH_ADR207	521.9	\N
2023-05-01	LM_LH_ADR197	1455.8	\N
2023-05-01	LM_LH_ADR215	0	\N
2023-05-01	LM_LH_ADR219	0.04	\N
2023-05-01	LM_LH_ADR220	147.33	\N
2023-05-01	LM_LH_ADR223	273.4	\N
2023-05-01	LM_LH_ADR225	85.4	\N
2023-05-01	LM_LH_ADR226	90.15	\N
2023-05-01	LM_LH_ADR217	611.2	\N
2023-05-01	LM_LH_ADR228	40.4	\N
2023-05-01	LM_LH_ADR232	76.41	\N
2023-05-01	LM_LH_ADR233	54.6	\N
2023-05-01	LM_LH_ADR230	1.8	\N
2023-05-01	LM_ELE_ADR114	368130.22	\N
2023-05-01	LM_ELE_ADR117	24776.59	\N
2023-05-01	LM_WOD_ADR132	341.62	\N
2023-05-01	LM_WOD_ADR133	390.28	\N
2023-05-01	LM_WOD_ADR134	22.13	\N
2023-05-01	LM_WOD_ADR135	0	\N
2023-05-01	LM_WOD_ADR136	75.97	\N
2023-05-01	LM_WOD_ADR139	1895.18	\N
2023-05-01	LM_WOD_ADR141	17	\N
2023-05-01	LM_WOD_ADR142	36	\N
2023-05-01	LM_WOD_ADR143	582.86	\N
2023-05-01	LM_WOD_ADR146	36567.5	\N
2023-05-01	LM_WOD_ADR148	0.05	\N
2023-05-01	LM_WOD_ADR150	52.45	\N
2023-05-01	LM_WOD_ADR237	926.83	\N
2023-05-01	LM_WOD_ADR238	3436.93	\N
2023-05-01	LM_WOD_ADR239	44.9	\N
2023-05-01	LM_WOD_ADR240	202.16	\N
2023-05-01	LM_WOD_ADR241	777.88	\N
2023-05-01	LM_ELE_ADR121	85.44	\N
2023-05-01	LM_ELE_ADR128	0	\N
2023-05-01	LM_WOD_ADR247_Solution Space	776.23	\N
2023-05-01	LM_WOD_ADR250_Solution Space	272.82	\N
2023-05-01	LM_WOD_ADR30	0	\N
2023-05-01	LM_ELE_ADR001	87221.28	\N
2023-05-01	LM_ELE_ADR002	112244.52	\N
2023-05-01	LM_ELE_ADR003	139113.52	\N
2023-05-01	LM_ELE_ADR006	0	\N
2023-05-01	LM_ELE_ADR007	166122.59	\N
2023-05-01	LM_ELE_ADR009	209543.42	\N
2023-05-01	LM_ELE_ADR011	187672.63	\N
2023-05-01	LM_ELE_ADR013	258804.92	\N
2023-05-01	LM_ELE_ADR014	19205.86	\N
2023-05-01	LM_ELE_ADR015	154497.16	\N
2023-05-01	LM_ELE_ADR016	1056581.63	\N
2023-05-01	LM_ELE_ADR018	16238.13	\N
2023-05-01	LM_ELE_ADR020	168402.08	\N
2023-05-01	LM_ELE_ADR022	221736.52	\N
2023-05-01	LM_ELE_ADR023	48465.1	\N
2023-05-01	LM_ELE_ADR025	882806.81	\N
2023-05-01	LM_ELE_ADR028	20185.23	\N
2023-05-01	LM_ELE_ADR034	42372.07	\N
2023-05-01	LM_ELE_ADR036	108164.6	\N
2023-05-01	LM_ELE_ADR039	485118.19	\N
2023-05-01	LM_ELE_ADR040	43495.41	\N
2023-05-01	LM_ELE_ADR042	4240.21	\N
2023-05-01	LM_ELE_ADR044	8148.6	\N
2023-05-01	LM_ELE_ADR048	8591.13	\N
2023-05-01	LM_ELE_ADR051	8185.81	\N
2023-05-01	LM_ELE_ADR053	43380.66	\N
2023-05-01	LM_ELE_ADR055	0	\N
2023-05-01	LM_ELE_ADR056	0	\N
2023-05-01	LM_ELE_ADR063	190	\N
2023-05-01	LM_ELE_ADR064	0	\N
2023-05-01	LM_ELE_ADR058	99699.63	\N
2023-05-01	LM_ELE_ADR072	34969	\N
2023-05-01	LM_ELE_ADR074	103023	\N
2023-05-01	LM_ELE_ADR076	0	\N
2023-05-01	LM_ELE_ADR081	91185.3	\N
2023-05-01	LM_ELE_ADR085	82617.73	\N
2023-05-01	LM_ELE_ADR090	54328.45	\N
2023-05-01	LM_ELE_ADR107	113305.2	\N
2023-05-01	LM_ELE_ADR108	8403.6	\N
2023-05-01	LM_ELE_ADR109	2050.34	\N
2023-05-01	LM_ELE_ADR110	620.32	\N
2023-05-01	LM_ELE_ADR113	67820.41	\N
2023-05-01	LM_ELE_ADR087	105202.29	\N
2023-05-01	LM_LC_ADR_B45	322.27	\N
2023-05-01	LM_LH_ADR_B46	49.35	\N
2023-05-01	LM_LH_ADR_B47	152.3	\N
2023-05-01	LM_WOD_ADR_B74	45.65	\N
2023-05-01	LM_ELE_ADR_B06	591144.31	\N
2023-05-01	LM_ELE_ADR046	0	\N
2023-05-01	LM_ELE_ADR010	143674.27	\N
2023-05-01	LM_ELE_ADR043	3503	\N
2023-05-01	LM_ELE_ADR_B11	42031.14	\N
2023-05-01	LM_WOD_ADR242	52.9	\N
2023-05-01	LM_ELE_ADR124	173718.48	\N
2023-05-01	LM_ELE_ADR112	797173.19	\N
2023-05-01	LM_WOD_ADR_B75	192.3	\N
2023-05-01	LM_ELE_ADR091	16414.9	\N
2023-05-01	LM_WOD_ADR_B80	171.18	\N
2023-05-01	LM_WOD_ADR_B81	58.71	\N
2023-05-01	LM_ELE_ADR_B04	324806.88	\N
2023-05-01	LM_ELE_ADR_B05	348061.5	\N
2023-05-01	LM_ELE_ADR_B09	335217.25	\N
2023-05-01	LM_ELE_ADR_B01	0	\N
2023-05-01	LM_ELE_ADR_B10	37720.23	\N
2023-05-01	LM_ELE_ADR_B02	0	\N
2023-05-01	LM_LC_ADR_B18	19.64	\N
2023-05-01	LM_LC_ADR_B20	71.69	\N
2023-05-01	LM_LC_ADR_B22	56.38	\N
2023-05-01	LM_LC_ADR_B24	10.69	\N
2023-05-01	LM_LC_ADR_B31	574.4	\N
2023-05-01	LM_LC_ADR_B41	638.7	\N
2023-05-01	LM_LC_ADR_B43	10.9	\N
2023-05-01	LM_LH_ADR_B23	73.9	\N
2023-05-01	LM_LH_ADR_B25	77.7	\N
2023-05-01	LM_LH_ADR_B27	168.1	\N
2023-05-01	LM_LH_ADR_B35	0	\N
2023-05-01	LM_LH_ADR_B36	0	\N
2023-05-01	LM_LH_ADR_B38	81.4	\N
2023-05-01	LM_LH_ADR_B44	4.9	\N
2023-05-01	LM_WOD_ADR_B76	1908.29	\N
2023-05-01	LM_WOD_ADR_B77	9.11	\N
2023-05-01	LM_LC_ADR_B16	38.83	\N
2023-05-01	LM_LH_ADR_B17	68	\N
2023-05-01	LM_WOD_ADR_B79	515.65	\N
2023-05-01	LM_ELE_ADR_B12	22646.74	\N
2023-05-01	LM_ELE_ADR_B13	15053.19	\N
2023-05-01	LM_LC_ADR_B46	59.55	\N
2023-05-01	LM_LC_ADR193	0	\N
2023-05-01	LM_ELE_ADR125	5664.98	\N
2023-05-01	LM_ELE_ADR069	347572	\N
2023-05-01	LM_ELE_ADR075	14441	\N
2023-05-01	LM_LC_ADR159	12470	\N
2023-05-01	LM_LC_ADR160	23960	\N
2023-05-01	LM_LH_ADR167	16670	\N
2023-05-01	LM_WOD_ADR236	43.23	\N
2023-05-01	zdemontowany580	6	\N
2023-05-01	zdemontowany600	3194	\N
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

