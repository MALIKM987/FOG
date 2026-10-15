# E01 – Podstawowy interferometryczny żyroskop światłowodowy

**Status:** KONCEPCJA (bez nowej symulacji i bez wyników pomiarowych).  
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

*Schemat portowy poglądowy.* Fale CW i CCW biegną przez tę samą cewkę w przeciwnych kierunkach. Pojedynczy modulator lokujemy blisko jednego końca pętli, by przejścia CW i CCW zachodziły w różnych chwilach. Konwencja portów, kierunek znaku i straty wymagają doprecyzowania w konkretnym modelu.

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

## Pliki etapu

- [model.md](model.md) – konkretny model, parametry, równania i status wyprowadzeń.
- [source_switching_plan.md](simulations/source_switching_plan.md) – projekt późniejszej symulacji LASER/ASE.
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
