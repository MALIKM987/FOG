# Sześć artykułów naukowych do projektu FOG

Zestaw uporządkowany 10.11.2026 na podstawie przesłanych sześciu oryginalnych PDF-ów oraz sześciu polskich opracowań z ilustracjami. Oryginały i przekłady **nie są dołączone jako binarne pliki do publicznego repo**. Poniżej są trwałe odnośniki do publikacji i techniczna mapa wykorzystania.

| Nr | Źródło | Pełny tekst / DOI | Rola w projekcie | Priorytet |
|---|---|---|---|---|
| 1 | H. C. Lefèvre, *Fundamentals of the Interferometric Fiber-Optic Gyroscope*, **Optical Review** 4, 20–27 (1997) | [J-STAGE PDF](https://www.jstage.jst.go.jp/article/or/4/1A/4_1A_20/_pdf), [DOI](https://doi.org/10.1007/BF02935984) | Wyprowadzenie fazy Sagnaca, wzajemność, modulacja, źródła szerokopasmowe | bardzo wysoki |
| 2 | H. C. Lefèvre, *The fiber-optic gyroscope, a century after Sagnac's experiment*, **C. R. Physique** 15, 851–858 (2014) | [DOI](https://doi.org/10.1016/j.crhy.2014.10.007) | Kontekst, źródła ASE, polaryzacja, nieidealności FOG | wysoki |
| 3 | M. Skalský, Z. Havránek, J. Fialka, *Efficient Modulation and Processing Method for Closed-Loop Fiber Optic Gyroscope with Piezoelectric Modulator*, **Sensors** 19, 1710 (2019) | [MDPI](https://www.mdpi.com/1424-8220/19/7/1710), [DOI](https://doi.org/10.3390/s19071710) | Zbudowany SMF + SFS/ASE + PZT, Lyot, fotodioda/TIA, próbkowanie cyfrowe | bardzo wysoki |
| 4 | R. J. Pérez, I. Álvarez, J. M. Enguita, *Theoretical Design of a Depolarized Interferometric Fiber-Optic Gyroscope (IFOG) on SMF-28 ...*, **Sensors** 16, 604 (2016) | [MDPI](https://www.mdpi.com/1424-8220/16/5/604), [DOI](https://doi.org/10.3390/s16050604) | Model optyki i elektroniki, TIA, demodulacja fazoczuła, Simulink | bardzo wysoki |
| 5 | Z. Wang i in., *Optically compensated polarization reciprocity in interferometric fiber-optic gyroscopes*, **Optics Express** 22, 4908–4919 (2014) | [DOI](https://doi.org/10.1364/OE.22.004908) | Warianty portów odbiorczych; reciprocity i kompensacja polaryzacyjna | średni / etap 2 |
| 6 | Z. Wang i in., *All-Depolarized Interferometric Fiber-Optic Gyroscope Based on Optical Compensation*, **IEEE Photonics Journal** 6, art. 7100208 (2014) | [DOI](https://doi.org/10.1109/JPHOT.2014.2299212) | Eksperyment ASE 1550 nm i depolaryzatory Lyota bez polaryzatora | bardzo wysoki / etap 2 |

## Kluczowe zastrzeżenia

- **Lefèvre 1997 to inna publikacja niż Lefèvre 1996.** W `references.bib` pozostawiamy osobne wpisy; DOI konferencyjny z 1996 roku nie oznacza PDF-a z *Optical Review* (1997).
- **Pérez 2016** używa w projekcie źródła **SLD 1310 nm**, nie generatora ASE 1550 nm. Praca jest przede wszystkim symulacyjna (OptSim, Multisim, MATLAB/Simulink), nie eksperymentalnym potwierdzeniem naszego wariantu.
- **Skalský 2019** to demonstracja na światłowodzie SMF i erbowym źródle SFS. Pokazany układ zawiera zarówno depolaryzator Lyota, jak i polaryzator.
- **Wang 2014 IEEE / Optics Express** opisują pokrewną rodzinę konstrukcji, ale o różnym układzie torów i długościach depolaryzatorów. Brak polaryzatora działa dzięki właściwie zaprojektowanej kompensacji optycznej, a nie samemu użyciu ASE.
- Licencja **CC BY 4.0**: Pérez 2016 i Skalský 2019 (wskazana w pełnych tekstach). Inne artykuły i ich oryginalne ilustracje wymagają osobnej analizy warunków redystrybucji.

## Do pierwszego demonstratora Sagnaca

Czytać najpierw: Lefèvre 1997 → Skalský 2019 → Pérez 2016 → Lefèvre 2014.

Pozostałe dwa wykorzystać szczególnie do etapu porównania architektur z polaryzatorem i bez polaryzatora, optymalizacji DOP oraz błędów polaryzacyjnych.

Dalsze notatki: [FOG_6_ARTYKULOW_ANALIZA.md](reading_notes/FOG_6_ARTYKULOW_ANALIZA.md).

Rekordy do cytowania: [references.bib](references.bib).
