# Walidacja FOG v3

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v3 potwierdza zgodność hierarchicznego modelu fizycznego z analitycznym bilansem mocy oraz zachowuje dokładność toru pomiarowego z v2.1.

## Walidacja toru pomiarowego

Dla `Omega = 1 deg/s`:

- `Omega_measured = 0.999985491 deg/s`
- błąd `Omega = -1.45086e-5 deg/s`
- `STD_Omega = 1.63211e-6 deg/s`

Wyniki są zgodne z v2.1, więc dodanie bilansu mocy i hierarchii fizycznej nie zmieniło zachowania części pomiarowej.

## Bilans mocy

Dla nominalnych parametrów v3:

- moc źródła: `1.000 mW`
- moc po wspólnym torze do wejścia pętli: `353.973 uW`
- skala mocy przy fotodiodzie: `45.3848 uW`
- średnia moc analityczna: `59.7486 uW`
- średnia moc w Simulinku: `59.7500 uW`
- minimum w symulacji: `31.6758 uW`
- maksimum w symulacji: `90.7693 uW`
- teoretyczny maksymalny peak: `90.7695 uW`
- skumulowana strata do skali detektora: `13.4309 dB`

Błąd średniej mocy teoria/symulacja:

`0.002395%`

To potwierdza zgodność modelu Simulink z analitycznym bilansem mocy.

## Straty krok po kroku

Największe składowe nominalnego budżetu:

- K1 launch: około `3.2103 dB`
- wspólny connector forward: `0.2 dB`
- polaryzator forward: `0.8 dB`
- depolaryzator forward: `0.3 dB`
- K2 + pętla + PZT + spawy w skali powrotu: około `4.4103 dB`
- depolaryzator return: `0.3 dB`
- polaryzator return: `0.8 dB`
- wspólny connector return: `0.2 dB`
- K1 detector: około `3.2103 dB`

Wartości są założeniami modelowymi v3 i nie są jeszcze zatwierdzonym BOM-em.

## Sweep mocy źródła

| Moc źródła [mW] | Średnia moc detektora [uW] | Teoretyczny peak [uW] | Peak <= 100 uW |
|---:|---:|---:|:---:|
| 0.5 | 29.8743 | 45.3848 | tak |
| 1.0 | 59.7486 | 90.7695 | tak |
| 2.0 | 119.4972 | 181.5390 | nie |
| 3.0 | 179.2458 | 272.3085 | nie |

Próg `100 uW` jest roboczym celem projektowym modelu, nie limitem zatwierdzonego odbiornika. Ostateczna ocena wymaga danych konkretnej fotodiody/TIA.

## Hierarchia modelu

Sprawdzony plik `FOG_v3.slx` zawiera na poziomie głównym podsystemy:

- `Optical Source`
- `Optical Front End`
- `Sagnac Interferometer`
- `Photoreceiver`
- `Lock-In DSP`

Model ma więc dwa poziomy:

1. widok fizyczny urządzenia,
2. szczegółowe równania wewnątrz podsystemów.

To jest docelowy kierunek wizualizacji kolejnych wersji FOG.

## Wnioski

1. v3 zachowuje dokładność estymacji prędkości z v2.1.
2. Hierarchizacja modelu nie zmieniła wyników matematycznych.
3. Bilans mocy Simulinka zgadza się z obliczeniami analitycznymi z błędem około `0.0024%`.
4. Nominalne źródło `1 mW` daje w modelu peak około `90.77 uW`, czyli mieści się w roboczym celu `100 uW`.
5. `2-3 mW` przekracza ten roboczy próg, więc rzeczywisty zakres wejściowy fotoodbiornika będzie istotnym parametrem BOM-u.
6. Następny etap powinien wprowadzić rzeczywiste dane elementów albo model szumów fotodetektora i elektroniki.

## Dane źródłowe

- `results/v3/FOG_v3_baseline.csv`
- `results/v3/FOG_v3_power_budget.csv`
- `results/v3/FOG_v3_source_power_sweep.csv`
