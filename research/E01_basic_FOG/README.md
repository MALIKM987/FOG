# E01 – Podstawowy interferometryczny żyroskop światłowodowy

**Status:** Etapy 1.1–1.3 opracowane teoretycznie; **1.4 – kod MATLAB przygotowany, oczekuje na lokalne uruchomienie i testy** (bez wyników pomiarowych).  
**Data rozpoczęcia zapisu:** 2026-10-15.  
**Cel:** szczegółowo zrozumieć podstawowy tor optyczny FOG i zbadać zasadność zastosowania lasera lub źródła szerokopasmowego ASE. Źródło ASE jest dostępne w laboratorium, ale jego parametry nie są tu jeszcze potwierdzone.

## Zakres E01

Model optyczny zawiera pięć podstawowych elementów funkcjonalnych:

| Element | Zadanie |
|---|---|
| Źródło światła: LASER / ASE | dostarcza światło o określonej mocy i widmie |
| Sprzęgacz światłowodowy 2×2 | dzieli falę na CW/CCW i ponownie je łączy |
| Modulator fazy | wytwarza sterowaną różnicową fazę między CW i CCW |
| Cewka światłowodowa | umożliwia powstanie fazy Sagnaca podczas obrotu |
| Fotodioda | zamienia moc optyczną w sygnał elektryczny |

Nie zapominamy o koniecznych połączeniach optycznych ani o sygnale elektrycznym sterującym modulatorem. Ich funkcje opisujemy bez projektowania pełnej elektroniki.

### Minimalna topologia ideowa

```text
     [LASER / ASE]               [fotodioda]
           |                          ^
       port wejściowy           port wyjściowy
           |                          |
        +------------------------------+
        |       sprzęgacz 2×2          |
        +------------------------------+
           |                       |
      [modulator]                  |
           |                       |
           +--- [cewka SMF] -------+
                CW ↻     CCW ↺
```

*Schemat portowy poglądowy.* Fale CW i CCW biegną przez tę samą cewkę w przeciwnych kierunkach. Pojedynczy modulator lokujemy blisko jednego końca pętli, by przejścia CW i CCW zachodziły w różnych chwilach. W Etapie 1.1 port B zdefiniowano jako ciemny przy zerowej różnicy faz; konwencja znaku obrotu i straty wymagają dalszego doprecyzowania.

## Pytania badawcze

1. Jak powstaje różnica faz Sagnaca i jak zależy od Ω, L, D oraz λ?
2. Dlaczego idealny sygnał fotodiody bez modulacji nie rozróżnia kierunku obrotu?
3. Dlaczego jeden wspólny modulator wprowadza różnicową fazę, chociaż działa na obie fale?
4. Dlaczego źródło ASE umożliwia interferencję mimo szerokiego widma?
5. Co realnie może poprawić szerokie widmo, a jakie są jego ograniczenia i źródła szumów?

## Założenia etapu

- Idealny model **skalarny**: brak modelowania polaryzacji i depolaryzatora.
- Monomodowa cewka, początkowo wspólna geometria dla obu typów źródła.
- Najpierw liniowa fizyka interferometru, później opcjonalne uproszczone zakłócenia.
- Oddzielamy efekt Sagnaca od fazy wymuszanej przez modulator.
- Porównujemy LASER i ASE przy jednakowo zdefiniowanej mocy wejściowej.
- Źródło szerokopasmowe wymaga całkowania po widmie; pojedyncza długość fali jest tylko przybliżeniem.

## Postęp badania

| Podetap | Cel | Stan |
|---|---|---|
| **1.1** | Zasada działania i ścieżka optyczna | **Opracowano teoretycznie** |
| **1.2** | Wyprowadzenie modelu matematycznego: sprzęgacz, fazy, detektor | **Opracowano analitycznie** |
| **1.3** | Uporządkowane porównanie LASER/ASE i spójności | **Opracowano teoretycznie** |
| **1.4** | Pierwszy osobny model symulacyjny E01 | **Kod MATLAB gotowy, test wykonawczy oczekuje** |
| 1.5 | Badania parametryczne i walidacja | Do wykonania |
| 1.6 | Ostateczne wnioski z badań | Do wykonania |

## Pliki etapu

- **[Etap 1.1: fizyczna zasada działania](01_01_optical_path.md)** – opis pięciu elementów, portów sprzęgacza, CW/CCW, modulatora i fotodiody.
- **[Etap 1.2: wyprowadzenie matematyczne](01_02_mathematical_derivation.md)** – macierz sprzęgacza, amplitudy CW/CCW, interferencja, modulacja oraz demodulacja.
- **[Etap 1.3: LASER vs ASE](01_03_laser_vs_ase.md)** – spójność, model widmowy, ograniczenia i hipotezy badawcze.
- [model.md](model.md) – skrócony model, parametry i równania.
- [source_switching_plan.md](simulations/source_switching_plan.md) – projekt późniejszej symulacji LASER/ASE.
- **[E01_start.m](simulations/matlab/E01_start.m)** – uruchamialny skrypt z jedną linią `SOURCE = "LASER"` lub `"ASE"`.
- **[Symulacja MATLAB](simulations/matlab/README.md)** – model średniego sygnału + oddzielne statystyczne modele szumu źródła i fotodiody (LASER/ASE), opcjonalny tor pasożytniczy, wykresy i testy.
- [simulations/README.md](simulations/README.md) – katalog symulacji; bez wymuszania programu.
- [results/README.md](results/README.md) – kryteria zapisu wyników (na razie brak wyników E01).
- [conclusions.md](conclusions.md) – aktualne wnioski wyłącznie teoretyczne i pytania otwarte.
- [notes/2026-10-15_meeting.md](notes/2026-10-15_meeting.md) – kontekst rozmowy z promotorem, zapisany na podstawie relacji studenta.

## Wiedza wspólna i literatura

- [Teoria Sagnaca](../../theory/sagnac.md).
- [Modulacja fazy](../../theory/phase_modulation.md).
- [Źródła światła i spójność](../../theory/optical_sources.md).
- [Bibliografia](../../bibliography/sources.md) oraz [BibTeX](../../bibliography/references.bib).

**Uwaga:** wcześniejsze modele MATLAB v1–v8.1 to osobna, historyczna linia rozwoju symulacji, nie wyniki E01.
