# Bibliografia robocza FOG

**Zasada:** każda pozycja musi zawierać DOI lub stabilny URL. Cytat i twierdzenie w pracy należy sprawdzić **w pełnym tekście** źródła, nie tylko na podstawie abstraktu. Stan „źródło zidentyfikowane” nie znaczy „publikacja przeczytana”.

**Bibliografia maszynowa:** [references.bib](references.bib) zawiera zweryfikowane rekordy L1, L2, L3, L5 i L7. L4 oraz L6 wymagają sprawdzenia dokładnych metadanych przed przeniesieniem do BibTeX.

## Podstawowe opracowania

**[L1]** H. C. Lefèvre, „The fiber-optic gyroscope, a century after Sagnac's experiment: The ultimate rotation-sensing technology?”, *Comptes Rendus Physique* 15 (2014), nr 10, s. 851–858.  
DOI: https://doi.org/10.1016/j.crhy.2014.10.007  
Temat: fizyka FOG, znaczenie efektu Sagnaca i technologie żyroskopów.  
Status: **ŹRÓDŁO ZIDENTYFIKOWANE**, wymaga analizy tekstu.

**[L2]** H. C. Lefèvre, „Fundamentals of the Interferometric Fiber-Optic Gyroscope”, *Optical Fiber Sensors* (1996), paper Tu3S1.  
DOI: https://doi.org/10.1364/OFS.1996.Tu3S1  
Temat: zasada działania, wzajemność, modulacja, źródła i elementy optyczne.  
Status: **ŹRÓDŁO ZIDENTYFIKOWANE**, wymaga analizy tekstu.

**[L3]** M. Skalský, Z. Havránek, J. Fialka, „Efficient Modulation and Processing Method for Closed-Loop Fiber Optic Gyroscope with Piezoelectric Modulator”, *Sensors* 19(7), 1710 (2019). DOI: https://doi.org/10.3390/s19071710.  
Tekst: https://pmc.ncbi.nlm.nih.gov/articles/PMC6480926/  
Temat: modulacja z opóźnieniem w pętli i „proper frequency” \(f_b=1/(2\tau)\), uwarunkowania modulatora PZT.  
Status: **ŹRÓDŁO ZIDENTYFIKOWANE**, autorzy i DOI sprawdzeni; zweryfikować pełne równania oraz zakres stosowalności do open-loop.

**[L4]** „Miniaturization of Interferometric Optical Gyroscopes: A Review”, 2023, *IEEE*.  
Indeks: https://ieeexplore.ieee.org/document/10301584  
Temat: źródła szerokopasmowe, stabilność średniej długości fali, błędy, szumy.  
Status: **ŹRÓDŁO ZIDENTYFIKOWANE**, sprawdzić pełną metrykę i dostępność.

**[L5]** J. Nayak, „Fiber-optic gyroscopes: from design to production”, *Applied Optics* 50(25), E152–E161 (2011).  
DOI: https://doi.org/10.1364/AO.50.00E152  
Temat: źródła błędów, rozpraszanie wsteczne, wybór źródła.  
Status: **ŹRÓDŁO ZIDENTYFIKOWANE**, wymaga lektury całego tekstu.

**[L6]** „Calculation of Rayleigh backscattering noise in fiber-optic gyroscopes”, *Journal of the Optical Society of America A* 2 (1985).  
Abstrakt: https://www.wip.osapublishing.org/josaa/abstract.cfm?uri=josaa-2-6-872  
Temat: ilościowe modelowanie rozpraszania Rayleigha przy małej spójności.  
Status: **ŹRÓDŁO ZIDENTYFIKOWANE**, pełna metryka i równania do sprawdzenia.

**[L7]** A. Kolkiran, G. S. Agarwal, „Heisenberg limited Sagnac interferometry”, *Optics Express* 15(11), 6798–6808 (2007).  
DOI: https://doi.org/10.1364/OE.15.006798  
Temat: **sekcja 3.1, wejście klasyczne** – współczynniki sprzęgacza 50:50, dwie przeciwbieżne amplitudy i porty interferometryczne.  
Status: **METRYKA I SEKCJA 3.1 SPRAWDZONE** na stronie wydawcy Optica; pełną analizę innych części publikacji odłożyć (dotyczą m.in. kwantowego interferometru). Klucz BibTeX: `kolkiran2007sagnac`.

## Mapa cytowania

| Teza w brudnopisie | Kandydat źródłowy | Co trzeba sprawdzić przed cytowaniem |
|---|---|---|
| Macierz idealnego sprzęgacza i interferencja pól | [L7], [L2] | zweryfikować konwencję portów z E01/1.2 |
| Faza Sagnaca proporcjonalna do Ω | [L1], [L2] | współczynnik 2πLD/(λc), geometria |
| Sygnał interferencji i wymaganie biasu | [L2], [L3] | znaki, port sprzęgacza, sposób demodulacji |
| Częstotliwość proper 1/(2τ) | [L3] | τ i dokładna definicja fazy modulatora |
| ASE i spójność krótkoczasowa | [L4], [L5] | dokładny model widma i rola opóźnienia |
| Rayleigh oraz szum od rozpraszania | [L5], [L6] | warunki źródeł i zakres redukcji |
| Stabilność widma a współczynnik skali | [L4] | średnia/efektywna długość fali |

## Dalszy proces bibliograficzny

- Dopisywać do `references.bib` nowe rekordy po sprawdzeniu autorów, tytułu, roku i DOI.
- Dopisać numer strony/rysunku/wzoru pod każdą tezę.
- Rozdzielić cytowania **teorii** od cytowań parametrów **konkretnego komponentu**.
- Unikać kopii wykresów z artykułów; przygotować własne schematy i wyniki z właściwym odniesieniem.
