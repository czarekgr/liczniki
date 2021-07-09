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
-- Data for Name: liczniki; Type: TABLE DATA; Schema: public; Owner: czarek
--

COPY public.liczniki (adres, nr_fabryczny, opis, lokalizacja, rodzaj, kolejnosc_pdf, najemca, kolejnosc) FROM stdin;
LM_LC_ADR151	78059564	Główny licznik ciepła budynku L-1 (78059564)	\N	LC	130	\N	90
LM_LH_ADR198	78251269	Licznik chłodu obiegu FC - FR L-2 (78251269)	\N	LH	360	\N	110
LM_LH_ADR194	78251261	Licznik chłodu obieg AHU - AO L-2 (78251261)	\N	LH	1410	\N	130
LM_LH_ADR195	78251260	Licznik chłodu AHU - AR (78251260)	\N	LH	340	\N	140
LM_LH_ADR196	78251264	Licznik chłodu obiegu serwerowni S - L-2 (78251264)	\N	LH	350	\N	150
LM_LC_ADR157	62065866	Licznik ciepła FC najemcy L02 - obieg FO (HC05, HC08) IT ERGO (62065866)	\N	LC	170	\N	430
LM_LH_ADR199	78251263	Licznik chłodu FC L02 - obieg FO IT ERGO (HC05, HC08) (78251263)	\N	LH	80	\N	440
LM_LH_ADR211	62065882	Licznik chłodu serwerownia najemcy L02 - S (HC01) (62065882)	\N	LH	410	\N	450
LM_LH_ADR203	78251266	Licznik chłodu FC L02 - obieg FO IT ERGO (HC01) (78251266)	\N	LH	380	\N	460
LM_LH_ADR204	78251262	Licznik chłodu Solution Space L03 szacht (78251262)	\N	LH	390	\N	1570
LM_LC_ADR209	71476893	Licznik ciepła  - Amaro L00 (71476893)	\N	LC	290	\N	1720
LM_LH_ADR122	71595108	Licznik chłodu - Centrale CulinaryOn (71595108)	\N	LH	320	\N	1910
LM_WOD_ADR_B80	58376978	Wodomierz - Davide Lifestyle (58376978)	\N	WOD	2360	\N	2090
LM_LH_ADR189	71512143	Licznik chłodu - Les Amis L01 (strefa 2B) (71512143)	\N	LH	330	\N	2240
LM_ELE_ADR007	2316325006	AHU 1.4 HOGAN LOVELLS (63325006)	\N	ELE	1830	\N	680
LM_LH_ADR200	78251258	Licznik chłodu FC L03 - obieg FO (HC05, HC08) (78251258)	\N	LH	370	\N	\N
LM_LH_ADR208	62065887	Licznik chłodu serwerownia najemcy L03 - S (HC05) (62065887)	\N	LH	400	\N	\N
LM_LC_ADR93	67884164	Licznik ciepła - grzejnik Fabiana (67884164)	\N	LC	1350	\N	2040
LM_LC_ADR_B22	71649394	Licznik ciepła - Fabiana L00 (71649394)	\N	LC	2460	\N	2060
LM_LC_ADR_B20	71150834	Licznik ciepła - Davide Lifestyle L01 (71150834)	\N	LC	2450	\N	2130
LM_LC_ADR_B18	71647821	Licznik ciepła - Davide Lifestyle L01 (71647821)	\N	LC	2440	\N	2150
LM_LC_ADR89	67884165	Licznik ciepła - grzejnik Davide (67884165)	\N	LC	1340	\N	2170
LM_LC_ADR_B24	71649395	Licznik ciepła - Corneliani L01 (71649395)	\N	LC	2470	\N	2180
LM_LC_ADR183	71512151	Licznik ciepła - Les Amis (strefa 2A) (71512151)	\N	LC	1300	\N	2270
LM_WOD_ADR242	181195090	Wodomierz Solution Space L00 (18734962)	\N	WOD	2310	\N	1340
LM_WOD_ADR249_Solution Space	181174659A	Wodomierz Solution Space kuchnia 1 (18733477)	\N	WOD	100	\N	1530
LM_ELE_ADR095	2317384011	SP K2 - Tablica TNK 2.2 IT ERGO (64384011)	\N	ELE	870	\N	500
LM_LH_ADR219	78675971	Licznik chłodu L03 MBDA (78675971)	\N	LH	1450	\N	1220
LM_LH_ADR220	78676883	Licznik chłodu L03 MBDA serwerownia (78676883)	\N	LH	1460	\N	1230
LM_WOD_ADR140	161032832	Wodomierz piano 1 W.Kruk (16803910)	\N	WOD	990	\N	710
LM_ELE_ADR098	2317441033	SP K3 - Tablica TNK 3.2 IT ERGO (64441033)	\N	ELE	890	\N	520
LM_LH_ADR197	78251268	Licznik chłodu obiegu FC - FO L-2 (78251268)	\N	LH	1430	\N	120
LM_LC_ADR103	67676944	Licznik ciepła - grzejnik GCN (67676944)	\N	LC	1190	\N	370
LM_LH_ADR207	62065885	Licznik chłodu serwerownia IT ERGO (62065885)	\N	LH	1420	\N	420
LM_LC_ADR_B32	62065875	Licznik ciepła FC najemcy L04 Hogan1- obieg FO (HC01) (62065875)	\N	LC	1080	\N	640
LM_LC_ADR_B33	62065877	Licznik ciepła FC najemcy L05 Seewald - obieg FO (HC05, HC08) (62065877)	\N	LC	1090	\N	880
LM_LH_ADR218	78647935	Licznik chłodu FC L01 - AUDI (78647935)	\N	LH	440	\N	980
LM_LC_ADR102	67219624	Licznik ciepła - grzejnik Almidecor (67219624)	\N	LC	1180	\N	1100
LM_LH_ADR221	71230687	Licznik chłodu L01 - ZEGNA (71230687)	\N	LH	450	\N	1290
LM_LC_ADR163	71888359	Licznik ciepła - ZEGNA L00 (71888359)	\N	LC	590	\N	1300
LM_LC_ADR164	71876833	Licznik ciepła - ZEGNA grzejniki L00 (71876833)	\N	LC	600	\N	1320
LM_LH_ADR212	62065884	Licznik chłodu Solution Space L03 serwerownia (62065884)	\N	LH	420	\N	1550
LM_LC_ADR104	67887353	Licznik ciepła - grzejnik CulinaryOn (67887353)	\N	LC	1200	\N	1870
LM_LC_ADR_B26	71670106	Licznik ciepła - CulinaryOn L00 (71670106)	\N	LC	1060	\N	1880
LM_LH_ADR_B47	71571363	Licznik chłodu - EON (71571363)	\N	LH	2240	\N	1970
LM_LH_ADR_B46	71571362	Licznik chłodu - EON serwerownia (71571362)	\N	LH	2230	\N	1980
LM_LH_ADR_B23	71649391	Licznik chłodu - Fabiana L00 (71649391)	\N	LH	2510	\N	2050
LM_LH_ADR_B25	71649390	Licznik chłodu - Corneliani L01 (71649390)	\N	LH	2520	\N	2190
LM_LC_ADR_B30	62065865	Licznik ciepła FC najemcy HBO L05 - obieg FO (HC01) (62065865)	\N	LC	1070	\N	2590
LM_LH_ADR231	71259540	Licznik chłodu Solution Space L01 (71259540)	\N	LH	490	\N	2670
LM_ELE_ADR062	16280856	SP U1 - Powierzchnia 0.04 - Fabiana Filippi L00 (16280856)	\N	ELE	750	\N	\N
LM_ELE_ADR065	BRAK	SP U1 - Powierzchnia 1.03	\N	ELE	760	\N	\N
LM_LC_ADR224	71505791	Licznik ciepła - Amaro grzejniki  (licznik na L-1) (71505791)	\N	LC	1330	\N	\N
LM_LH_ADR_B37	62065888	Licznik chłodu serwerownia najemcy L05  HBO serw- S (HC01) (62065888)	\N	LH	1130	\N	\N
LM_ELE_ADR067	16380761	SP U1 - Powierzchnia 1.05 (16380761)	\N	ELE	770	\N	\N
LM_ELE_ADR068	16390068	SP U2 - Powierzchnia 0.07 (16390068)	\N	ELE	780	\N	\N
LM_ELE_ADR070	16350646	SP U2 - Powierzchnia 0.12 (16350646)	\N	ELE	790	\N	\N
LM_ELE_ADR071	16410250	SP U2 - Almidecor (dawniej powierzchnia 1.07) (16410250)	\N	ELE	800	\N	\N
LM_ELE_ADR073	BRAK	SP U3 - Powierzchnia 0.10	\N	ELE	810	\N	\N
LM_ELE_ADR023	63326018	Tablice T-TOZ (63326018)	\N	ELE	1930	\N	\N
LM_ELE_ADR025	33344014	Tablice TA 2.-1, TA 2.2, TA 2.3, TA 2.4 (33344014)	\N	ELE	1940	\N	\N
LM_ELE_ADR034	63325002	T-TEL (63325002)	\N	ELE	1960	\N	\N
LM_ELE_ADR036	63326008	Rozdzielnica TWC2 (63326008)	\N	ELE	1970	\N	\N
LM_ELE_ADR040	63284001	Tablica T-OGS (rezerwa) (63284001)	\N	ELE	1990	\N	\N
LM_ELE_ADR042	63182019	Winda W1 (63182019)	\N	ELE	2000	\N	\N
LM_ELE_ADR044	63354012	Winda W3 (63354012)	\N	ELE	2010	\N	\N
LM_ELE_ADR048	63325012	Winda W8 (63325012)	\N	ELE	2020	\N	\N
LM_ELE_ADR051	63284036	Tablica TP 1.-2 (63284036)	\N	ELE	2030	\N	\N
LM_ELE_ADR053	63265005	Tablica TP 2.-1 (63265005)	\N	ELE	2040	\N	\N
LM_LC_ADR158	62065867	Licznik ciepła FC najemcy L03 - obieg FO (HC05, HC08) (62065867)	\N	LC	180	\N	\N
LM_WOD_MAIN_W	BRAK		\N	WOD	110	\N	\N
LM_ELE_ADR021	33344042	Tablice TA 3.0, TA 3.1, TA 3.2 (33344042)	\N	ELE	40	\N	\N
LM_ELE_ADR078	16230375	SP U4 - powierzchnia 0.06 CulinaryOn (16230375)	\N	ELE	50	\N	\N
LM_ELE_ADR066	16380796	SP U1 - Powierzchnia 1.04 (16380796)	\N	ELE	60	\N	\N
LM_ELE_ADR017	63311012	Rozdzielnica RW3 (63311012)	\N	ELE	550	\N	\N
LM_ELE_ADR055	63265006	Tablica TP 2.3 (63265006)	\N	ELE	2050	\N	\N
LM_ELE_ADR056	63284037	Tablica  TP 3.1, TP 3.3, TP 3.5 (63284037)	\N	ELE	2060	\N	\N
LM_ELE_ADR063	BRAK	SP U1 - Powierzchnia 0.05	\N	ELE	2070	\N	\N
LM_LC_ADR156	62065878	Licznik ciepła FC - FR (62065878)	\N	LC	1230	\N	160
LM_LC_ADR155	78251253	Licznik ciepła FC - FO (78251253)	\N	LC	160	\N	170
LM_LC_ADR154	62065870	Licznik ciepła obiegu grzejników RAD (62065870)	\N	LC	150	\N	180
LM_LC_ADR152	62065879	Licznik ciepła obiegu AHU - AR (62065879)	\N	LC	1210	\N	200
LM_LC_ADR153	78251254	Licznik ciepła obiegu AO (78251254)	\N	LC	140	\N	190
LM_LC_ADR161	62065874	Licznik ciepła FC najemcy L02 - obieg FO (HC01) IT ERGO (62065874)	\N	LC	1320	\N	470
LM_LC_ADR_B31	62065868	Licznik ciepła FC najemcy L04 Hogan58 - obieg FO (HC05, HC08) (62065868)	\N	LC	2480	\N	600
LM_LH_ADR_B40	78251265	Licznik chłodu FC L04 Hogan - obieg FO (HC01) (78251265) (MWh)	\N	LH	1150	\N	630
LM_LC_ADR_B41	78478336	Licznik ciepła - HBO L05 (78478336)	\N	LC	2490	\N	760
LM_LH_ADR_B42	78478337	Licznik chłodu - HBO L05 (78478337)	\N	LH	1160	\N	2570
LM_LH_ADR_B39	78251259	Licznik chłodu FC L05 Seewald - obieg FO (HC05, HC08) (78251259) (MWh)	\N	LH	1140	\N	890
LM_LC_ADR173	78675879	Licznik ciepła L03 MBDA (78675879)	\N	LC	210	\N	2650
LM_LH_ADR217	78647934	Licznik chłodu FC L00 - AUDI (78647934)	\N	LH	1500	\N	990
LM_LC_ADR171	78647936	Licznik ciepła L00 - AUDI (78647936)	\N	LC	1240	\N	1000
LM_LH_ADR232	78675881	Licznik chłodu - AUDI serwerownia (78675881)	\N	LH	1520	\N	1010
LM_LC_ADR178	78675880	Licznik ciepła L-1 - AUDI - grzejniki (78675880)	\N	LC	250	\N	1020
LM_LC_ADR82	67884167	Licznik ciepła - grzejnik Corneliani (67884167)	\N	LC	310	\N	2730
LM_LC_ADR174	71297057	Licznik ciepła L01 - ZEGNA (71297057)	\N	LC	220	\N	1280
LM_LH_ADR201	71834619	Licznik chłodu - ZEGNA L00 (71834619)	\N	LH	610	\N	1310
LM_LC_ADR162	62065876	Licznik ciepła - Solution Space L03 (62065876)	\N	LC	190	\N	1560
LM_LC_ADR182	71496751	Licznik ciepła - Leonardo (71496751)	\N	LC	1290	\N	1650
LM_LH_ADR233	71497211	Licznik chłodu Leonardo L03 (71497211)	\N	LH	1530	\N	1660
LM_LH_ADR234	71497210	Licznik chłodu Leonardo L03 (71497210)	\N	LH	500	\N	1670
LM_LH_ADR235	71476894	Licznik chłodu - Amaro L00 (71476894)	\N	LH	510	\N	1730
LM_LC_ADR185	71612821	Licznik ciepła - Fabiana Filippi L00 (71612821)	\N	LC	1310	\N	2020
LM_LH_ADR225	71612822	Licznik chłodu - Fabiana Filippi L00 (71612822)	\N	LH	1480	\N	2030
LM_LC_ADR_B16	71150833	Licznik ciepła - Davide Lifestyle L00 (71150833)	\N	LC	2600	\N	2110
LM_LH_ADR_B21	71644763	Licznik chłodu - Davide Lifestyle L01 (71644763)	\N	LH	1110	\N	2140
LM_ELE_ADR011	2316371001	AHU 2.2 IT ERGO (63371001)	\N	ELE	1850	\N	550
LM_LH_ADR_B19	71644764	Licznik chłodu - Davide Lifestyle L01 (71644764)	\N	LH	1100	\N	2160
LM_LC_ADR184	71512150	Licznik ciepła - Les Amis (strefa 2B) (71512150)	\N	LC	260	\N	2230
LM_LC_ADR149	71512149	Licznik ciepła - Les Amis (71512149)	\N	LC	1220	\N	2250
LM_LH_ADR145	71512145	Licznik chłodu - Les Amis (71512145)	\N	LH	1360	\N	2260
LM_LH_ADR190	71512144	Licznik chłodu - Les Amis L01 (strefa 2A) (71512144)	\N	LH	1380	\N	2280
LM_LC_ADR186	71512152	Licznik ciepła - Les Amis (strefa 2A bliżej 1C) (71512152)	\N	LC	270	\N	2290
LM_LH_ADR191	71512148	Licznik chłodu - Les Amis L01 (strefa 2A bliżej 1C) (71512148)	\N	LH	1390	\N	2300
LM_LC_ADR187	71512153	Licznik ciepła - Les Amis (strefa 3D) (71512153)	\N	LC	280	\N	2310
LM_LH_ADR192	71512147	Licznik chłodu - Les Amis L01 (strefa 3D) (71512147)	\N	LH	1400	\N	2320
LM_LH_ADR188	71512146	Licznik chłodu - Les Amis L00 (strefa 4B) (71512146)	\N	LH	1370	\N	2340
LM_LC_ADR193	67884166	Licznik ciepła - Les Amis (nad barem) (67884166)	\N	LC	2660	\N	2330
LM_LH_ADR_B34	62065880	Licznik chłodu serwerownia najemcy L05 HBO serw - S (HC05) (62065880)	\N	LH	1120	\N	2620
LM_ELE_ADR039	1816344019	Tablica T-Piano W.Kruk (33344019)	\N	ELE	1980	\N	730
LM_ELE_ADR115	2316371005	AHU R3KZ Les Amis (63371005)	\N	ELE	90	\N	2380
LM_ELE_ADR028	2316362014	AHU R6 SOLUTION SPACE L01 (63362014)	\N	ELE	1950	\N	1510
LM_ELE_ADR012	2316362002	AHU 1.3 SOLUTION SPACE L03 (63362002)	\N	ELE	540	\N	1610
LM_ELE_ADR008	2316326010	AHU 3.3 NDI (63326010)	\N	ELE	530	\N	1190
LM_ELE_ADR080	2317445010	SP 1 - Tablica TN 1.2 (64445010)	\N	ELE	70	\N	490
LM_ELE_ADR064	BRAK	SP U1 - Powierzchnia 1.02	\N	ELE	2080	\N	\N
LM_ELE_ADR058	63284023	Tablica  T-UPS (63284023)	\N	ELE	2090	\N	\N
LM_ELE_ADR074	BRAK	SP U3 - Powierzchnia 0.11	\N	ELE	2110	\N	\N
LM_ELE_ADR076	15420085	SP U4 - powierzchnia 0.16 (15420085)	\N	ELE	2120	\N	\N
LM_ELE_ADR081	65334007	SP 1 - Tablica TN 1.3 - Solution Space L01 (65334007)	\N	ELE	2130	\N	\N
LM_ELE_ADR085	65341010	SP K3 - Tablica TNK 3.2 - Solution Space L01 (65341010)	\N	ELE	2140	\N	\N
LM_ELE_ADR090	65334011	SP 3 - Tablica TN 3.5 - Solution Space L00 (65334011)	\N	ELE	2150	\N	\N
LM_ELE_ADR107	35415001	EON L04 (35415001)	\N	ELE	2160	\N	\N
LM_ELE_ADR108	63371009	Magazyn U.01  HBO Magazyn (63371009)	\N	ELE	2170	\N	\N
LM_ELE_ADR109	63371006	Magazyn U.02  (63371006)	\N	ELE	2180	\N	\N
LM_ELE_ADR110	63371014	Amaro - magazyn (63371014)	\N	ELE	2190	\N	\N
LM_ELE_ADR094	35244023	Licznik elektryczny - Les Amis L01 (35244023)	\N	ELE	860	\N	\N
LM_ELE_ADR097	65341005	SP K3 - Tablica TNK 3.2 - Solution Space L03 (65341005)	\N	ELE	880	\N	\N
LM_LH_ADR_B35	62065881	Licznik chłodu najemcy FC L05 HBO serw - obieg FO (HC01) (62065881)	\N	LH	2540	\N	\N
LM_WOD_ADR237	18740005	Wodomierz LES AMIS (18740005)	\N	WOD	1690	\N	\N
LM_WOD_ADR240	00207182	Wodomierz toalety L01 (00207182)	\N	WOD	1720	\N	\N
LM_WOD_ADR241	00207171	Wodomierz toalety L00 (00207171)	\N	WOD	1730	\N	\N
LM_WOD_ADR30	19737052	Wodomierz PZFD L03 (19737052)	\N	WOD	1780	\N	\N
LM_WOD_ADR146	11036701	Główny wodomierz (11036701)	\N	WOD	1660	\N	\N
LM_WOD_ADR148	00214876	Wodomierz MBDA (00214876)	\N	WOD	1670	\N	\N
LM_ELE_ADR121	35137046	Amaro L00 (35137046)	\N	ELE	1740	\N	\N
LM_ELE_ADR128	08216809	po KSP (w szachcie L01 na solution) (08216809)	\N	ELE	1750	\N	\N
LM_ELE_ADR002	63354008	AHU 2.4 HOGAN LOVELS (63354008)	\N	ELE	1800	\N	\N
LM_WOD_ADR141	16838217	Wodomierz piano 2 (16838217)	\N	WOD	1630	\N	\N
LM_WOD_ADR142	16803909	Wodomierz TWC (16803909)	\N	WOD	1640	\N	\N
LM_WOD_ADR143	16838122	Brama wjazdowa (16838122)	\N	WOD	1650	\N	\N
LM_ELE_ADR043	63354018	Winda W2 (63354018)	\N	ELE	2290	\N	\N
LM_ELE_ADR_B11	63284007	Licznik elektryczny Rozdzielnica RW2, RPCH- TRANE2(63284007)	\N	ELE	2300	\N	\N
LM_ELE_ADR019	63326006	Rozdzielnica T-TAR (63326006)	\N	ELE	560	\N	\N
LM_ELE_ADR024	63325014	Tablice TA 1.2, TA 1.3, TA 1.4, TA 1.5 (63325014)	\N	ELE	570	\N	\N
LM_ELE_ADR029	66334053	Licznik elektryczny - PZFD L03 (66334053)	\N	ELE	620	\N	\N
LM_ELE_ADR041	63325008	Tablica T-WC (63325008)	\N	ELE	650	\N	\N
LM_ELE_ADR045	63354004	Winda W4 (63354004)	\N	ELE	660	\N	\N
LM_ELE_ADR047	63354016	Winda W7 (63354016)	\N	ELE	670	\N	\N
LM_ELE_ADR049	63354002	Winda Piano W.Kruk (63354002)	\N	ELE	680	\N	\N
LM_ELE_ADR052	63265003	Tablica TP 1.-1 (63265003)	\N	ELE	690	\N	\N
LM_WOD_ADR134	17360045	Wodomierz ERGO - sala kinowa (17360045)	\N	WOD	1590	\N	410
LM_WOD_ADR135	77902822	Wodomierz Hogan Lovells L04 - od Książecej (77902822)	\N	WOD	1600	\N	2530
LM_WOD_ADR136	77902823	Wodomierz Hogan Lovells L04 - od Placu Trzech Krzyży (77902823)	\N	WOD	1610	\N	580
LM_LH_ADR_B38	78251257	Licznik chłodu FC L04 Hogan - obieg FO (HC05, HC08) (78251257) (MWh)	\N	LH	2560	\N	610
LM_ELE_ADR009	2316362010	AHU 3.2 IT ERGO (63362010)	\N	ELE	1840	\N	560
LM_LH_ADR_B27	71670180	Licznik chłodu - CulinaryOn L00 (71670180)	\N	LH	2530	\N	1890
LM_LC_ADR172	78647937	Licznik ciepła L01 - AUDI (78647937)	\N	LC	20	\N	970
LM_LC_ADR123	71595107	Licznik ciepła - Centrale CulinaryOn (71595107)	\N	LC	120	\N	1900
LM_LC_ADR_B45	71522586	Licznik ciepła EON (71522586)	\N	LC	2220	\N	1960
LM_WOD_ADR_B81	58376979	Wodomierz - Fabiana (58376979)	\N	WOD	2370	\N	2010
LM_LH_ADR_B36	62065883	Licznik chłodu serwerownia najemcy L04 Hogan serw - S (HC01) (62065883)	\N	LH	2550	\N	2550
LM_ELE_ADR038	1816332105	Rozdzielnia RPCH (33332105)	\N	ELE	640	\N	290
LM_ELE_ADR003	2316354013	AHU 2.5 HBO (63354013)	\N	ELE	1810	\N	850
LM_ELE_ADR046	2316354008	Solution space TN 1.1 - TU5 (63325003)	\N	ELE	2270	\N	690
LM_ELE_ADR006	2316326004	AHU 1.5 HBO (63326004)	\N	ELE	1820	\N	840
LM_ELE_ADR_B06	1816331030	Licznik elektryczny Chiller CHI1 (33331030)	\N	ELE	2260	\N	930
LM_ELE_ADR114	1816331023	Licznik elektryczny AUDI - TU4 (33331023)	\N	ELE	1550	\N	1030
LM_ELE_ADR010	2316371007	AHU 2.3 MBDA (63371007)	\N	ELE	2280	\N	1260
LM_ELE_ADR031	1816331002	Solution Tn-2.1 - TU3 (33331002)	\N	ELE	630	\N	1480
LM_ELE_ADR027	2316311028	AHU R5 AMARO (63311028)	\N	ELE	580	\N	1780
LM_ELE_ADR001	2316354011	AHU 3.4 EON (63354011)	\N	ELE	1790	\N	2000
LM_ELE_ADR113	2316371016	AHU R3 LES AMIS (63371016)	\N	ELE	2200	\N	2370
LM_ELE_ADR117	2316362003	AHU R4KZ (63362003)	\N	ELE	1560	\N	2400
LM_WOD_ADR133	17FA358457T	Wodomierz ERGO - recepcja (17360039)	\N	WOD	1580	\N	390
LM_WOD_ADR132	17FA358454Q	Wodomierz ERGO - pomieszczenie(17360035)	\N	WOD	1570	\N	400
LM_WOD_ADR_B78	60600683	Wodomierz HBO (00129890)	\N	WOD	1170	\N	740
LM_WOD_ADR150	60882996	Wodomierz AUDI (00228857)	\N	WOD	1680	\N	960
LM_WOD_ADR147	181022659A	Wodomierz NDI (18726655)	\N	WOD	1000	\N	1140
LM_WOD_ADR129	181106C29A	Wodomierz ZEGNA L01 (18727749)	\N	WOD	980	\N	1270
LM_WOD_ADR247_Solution Space	181072960A	Wodomierz Solution Space łazienki L01 (18734980)	\N	WOD	1760	\N	1410
LM_WOD_ADR246_Solution Space	181195096A	Wodomierz Solution Space kuchnia L01 (18734955)	\N	WOD	1010	\N	1420
LM_WOD_ADR250_Solution Space	181173780A	Wodomierz Solution Space łazienki L03 (18733482)	\N	WOD	1770	\N	1520
LM_WOD_ADR248_Solution Space	181174655A	Wodomierz Solution Space kuchnia 2 (18733476)	\N	WOD	1020	\N	1540
LM_WOD_ADR239	181195981A	Wodomierz Leonardo L03 (18739958)	\N	WOD	1710	\N	1640
LM_WOD_ADR238	180702718A	Wodomierz Amaro L00 (18740019)	\N	WOD	1700	\N	1710
LM_WOD_ADR_B75	191183429A	Wodomierz- zimna woda - CulinaryOn (19726823)	\N	WOD	2340	\N	1820
LM_WOD_ADR_B74	190405578A	Wodomierz - EON (19700657)	\N	WOD	2250	\N	1950
LM_ELE_ADR087	2317441065	SP 3 - Tablica TN 3.2 IT ERGO (64441065)	\N	ELE	2210	\N	530
LM_ELE_ADR072	48503026h16502010251	SP U3 - MBDA tablica TNK (dawniej powierzchnia 0.09) (16380803)	\N	ELE	2100	\N	1250
LM_ELE_ADR099	2318352007	SP K3 - Tablica TN 1.3 - Solution Space L03 (65352007)	\N	ELE	900	\N	1580
LM_ELE_ADR054	63265011	Tablica TP 1.1, TP 1.3, TP 1.5 (63265011)	\N	ELE	700	\N	\N
LM_ELE_ADR057	63284015	Tablica  TP-WIND (63284015)	\N	ELE	710	\N	\N
LM_ELE_ADR060	BRAK	SP U1 - Powierzchnia 0.02	\N	ELE	730	\N	\N
LM_ELE_ADR061	BRAK	SP U1 - Powierzchnia 0.03	\N	ELE	740	\N	\N
LM_ELE_ADR100	65355029	Leonardo L03 TN4.3 (65355029)	\N	ELE	910	\N	\N
LM_ELE_ADR101	65332002	Leonardo L03 TNK 4.3 (65332002)	\N	ELE	920	\N	\N
LM_ELE_ADR111	63371013	Magazyn U.04 FABIANA FILLIPPI (63371013)	\N	ELE	930	\N	\N
LM_ELE_ADR116	63371010	AHU R4K (63371010)	\N	ELE	940	\N	\N
LM_ELE_ADR118	63362009	AHU B1 (63362009)	\N	ELE	950	\N	\N
LM_ELE_ADR119	63362017	AHU T (63362017)	\N	ELE	960	\N	\N
LM_ELE_ADR091	63362011	P4 centrala telefoniczna Play (63362011)	\N	ELE	2350	\N	\N
LM_ELE_ADR_B09	34261024	SP 1 - Główny licznik elektryczny HBO (34261024)	\N	ELE	2400	\N	\N
LM_ELE_ADR_B01	16380762	Licznik elektryczny - Corneliani (16380762)	\N	ELE	2410	\N	\N
LM_ELE_ADR_B10	63284002	Licznik elektryczny - Rozdzielnica RW1 (63284002)	\N	ELE	2420	\N	\N
LM_ELE_ADR_B02	16380819	Licznik elektryczny - Davide Lifestyle (16380819)	\N	ELE	2430	\N	\N
LM_ELE_ADR069	15270553	Green Cafe Nero GCN (15270553)	\N	ELE	2680	\N	\N
LM_ELE_ADR075	16380798	SP U3 - MBDA tablica TN (16380798)	\N	ELE	2690	\N	\N
LM_ELE_ADR077	16350655	SP U4 - powierzchnia 0.13 CulinaryOn (16350655)	\N	ELE	820	\N	\N
LM_ELE_ADR125	04311047	Hogan - logo (04311047)	\N	ELE	2670	\N	\N
LM_WOD_ADR_B76	16838219	Wodomierz od strony ul. Książęcej L04 (16838219)	\N	WOD	2580	\N	\N
LM_WOD_ADR_B77	16838216	Wodomierz od Kruka L04 (16838216)	\N	WOD	2590	\N	\N
LM_ELE_ADR086	65334004	SP 2 - Tablica TN 2.4 - Space Solution L01 (65334004)	\N	ELE	840	\N	\N
LM_ELE_ADR016	63326001	Centrala AHU 2 (63326001)	\N	ELE	1890	\N	\N
LM_ELE_ADR018	63326011	Rozdzielnica RM (63326011)	\N	ELE	1900	\N	\N
LM_ELE_ADR020	63311020	Tablice TA 3.3, TA 3.4, TA 3.5 (63311020)	\N	ELE	1910	\N	\N
LM_ELE_ADR022	33344025	Tablice TA 2.-1, TA 2.2, TA 2.3, TA 2.4 (33344025)	\N	ELE	1920	\N	\N
LM_ELE_ADR013	2316362006	AHU 1.2 IT ERGO (63362006)	\N	ELE	1860	\N	540
LM_WOD_ADR139	57760157	Wodomierz GCN  (57760157)	\N	WOD	1620	1	310
LM_LC_ADR168	80087616	Licznik ciepła L00 GCN (80087616)	\N	LC	200	\N	320
LM_LH_ADR226	80120070	Licznik chłodu FC L00 - GCN (80120070)	\N	LH	1490	\N	330
LM_LC_ADR_B46	80087615	Licznik ciepła GCN (80087615)	\N	LC	2650	\N	1940
LM_LH_ADR223	80032572	Licznik chłodu L01 - Almidecor (80032572)	\N	LH	1470	\N	1080
LM_LC_ADR175	80096039	Licznik ciepła L00 - Almidecor (80096039)	\N	LC	230	\N	1060
LM_LH_ADR222	80032573	Licznik chłodu L00 - Almidecor (80032573)	\N	LH	460	\N	1070
LM_LC_ADR176	80096038	Licznik ciepła L01 - Almidecor (80096038)	\N	LC	240	\N	1090
LM_LC_ADR179	80272795	Licznik ciepła  - Solution Space L00 (80272795)	\N	LC	30	\N	1350
LM_LH_ADR215	\N	Licznik chłodu FC L03 - NDI (80091631)	\N	LH	1440	\N	1120
LM_ELE_ADR120	2316326003	Centrala Amaro AHU N2 - RW4 (63326003)	\N	ELE	970	\N	1790
LM_ELE_ADR124	1816331007	ZEGNA - TU 2 (RGNN) (33331007)	\N	ELE	2320	\N	1330
LM_LH_ADR228	80271297	Licznik chłodu Solution Space L00 (80271297)	\N	LH	1510	\N	1360
LM_LC_ADR165	80108185	Licznik ciepła - Solution Space grzejniki L-1 (80108185)	\N	LC	1250	\N	1370
LM_LC_ADR166	80138392	Licznik ciepła - Solution Space grzejniki L-1 (80138392)	\N	LC	1260	\N	1380
LM_LC_ADR181	80272797	Licznik ciepła  - Solution Space L01 (80272797)	\N	LC	1280	\N	1440
LM_LH_ADR230	80271298	Licznik chłodu Solution Space L01 (80271298)	\N	LH	1540	\N	1450
LM_LC_ADR180	80272796	Licznik ciepła  - Solution Space L01 (80272796)	\N	LC	1270	\N	1460
LM_LH_ADR229	80271273	Licznik chłodu Solution Space L01 (80271273)	\N	LH	480	\N	1470
LM_LH_ADR_B44	80255450	Licznik chłodu Centrala Amaro (80255450)	\N	LH	2570	\N	1750
LM_LC_ADR_B43	80255449	Licznik ciepła  - Centrala Amaro (80255449)	\N	LC	2500	\N	1760
LM_LH_ADR227	80120069	Licznik chłodu L00 - GCN/Almidecor (80120069)	\N	LH	470	\N	1930
LM_LH_ADR_B17	71644762	Licznik chłodu - Davide Lifestyle L00 (71644762)	\N	LH	2610	\N	2120
LM_ELE_ADR_B05	1816331016	Licznik elektryczny Chiller CHI2 (33331016)	\N	ELE	2390	\N	940
LM_LC_ADR32	80443474	Licznik ciepła - PZFD L03 (80443474)	\N	LC	300	\N	2770
LM_LH_ADR33	80446698	Licznik chłodu - PZFD L03 (80446698)	\N	LH	520	\N	2780
LM_ELE_ADR_B12	272103494	Licznik elektryczny Seewald kuchnia 1 (11111111)	\N	ELE	2630	\N	910
LM_ELE_ADR_B13	272103657	Licznik elektryczny Seewald kuchnia 2 (22222222)	\N	ELE	2640	\N	920
LM_ELE_ADR_B04	1816331005	Licznik elektryczny Chiller CHI3 (33331005)	\N	ELE	2380	\N	950
LM_LC_ADR170	80091629	Licznik ciepła L03 NDI (80091629)	\N	LC	10	\N	\N
LM_LH_ADR216	\N	Licznik chłodu FC L03 - NDI Serwerownia (80091630)	\N	LH	430	\N	1130
LM_ELE_ADR014	2316362007	Centrala AHU R4 Les Amis (63362007)	\N	ELE	1870	\N	2390
LM_ELE_ADR112	2316362018	AHU R2 AUDI (63362018)	\N	ELE	2330	\N	1040
LM_ELE_ADR015	2316326007	AHU R1 ALMIDECOR (63326007)	\N	ELE	1880	\N	1020
LM_WOD_ADR_B79	191061232A	Wodomierz - ciepła woda - CulinaryOn (19726824)	\N	WOD	2620	\N	1810
LM_ELE_ADR059	2317445001	SP K1 - Tablica TNK 1.2 - IT ERGO (64445001)	\N	ELE	720	\N	480
LM_ELE_ADR084	2317445019	SP 2 - Tablica TN 2.2 IT ERGO (64445019)	\N	ELE	830	\N	510
LM_ELE_ADR_B08	1817261013	Licznik elektryczny SP 1 Hogan - Tablica TN 1.4 (34261013)	\N	ELE	1050	\N	650
LM_ELE_ADR_B07	1817174066	Licznik elektryczny SP 3 Hogan - Tablica TN 3.4 (34174066)	\N	ELE	1040	\N	660
LM_ELE_ADR_B03	1517162019	Licznik elektryczny SP K1 Hogan - Tablica TNK 1.4 (04162019)	\N	ELE	1030	\N	670
LM_ELE_ADR088	2318245036	SP 3 - Tablica TN 3.3 - NDI (65245036)	\N	ELE	850	\N	1180
\.


--
-- PostgreSQL database dump complete
--

