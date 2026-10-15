# Walidacja FOG v3.1 - zbieżność numeryczna

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

Test potwierdza, że mały błąd obserwowany przy wysokich częstotliwościach modulacji wynika głównie z rozdzielczości czasowej solvera i reprezentacji `Transport Delay`, a nie z fizyki modelu FOG.

## Zakres testu

Częstotliwości:

- 20 kHz
- 50 kHz
- 102.095 kHz
- 150 kHz

Kroki solvera:

- 0.20 us
- 0.10 us
- 0.05 us
- 0.02 us

Łącznie wykonano 16 symulacji.

## Wynik główny

Zmniejszenie kroku z `0.20 us` do `0.02 us` redukuje bezwzględny błąd Omega:

| f_mod [kHz] | błąd Omega @ 0.20 us [deg/s] | błąd Omega @ 0.02 us [deg/s] | poprawa |
|---:|---:|---:|---:|
| 20 | -1.6696e-5 | -2.4927e-6 | 6.70x |
| 50 | -9.6974e-4 | -2.2477e-5 | 43.14x |
| 102.095 | +1.4923e-3 | +2.9357e-5 | 50.83x |
| 150 | -5.1351e-3 | -1.0954e-4 | 46.88x |

Błąd beta również maleje bardzo wyraźnie:

| f_mod [kHz] | błąd beta @ 0.20 us [%] | błąd beta @ 0.02 us [%] | poprawa |
|---:|---:|---:|---:|
| 20 | -0.005896 | -0.0000776 | 75.94x |
| 50 | -0.036756 | -0.000485 | 75.75x |
| 102.095 | -0.102770 | -0.000467 | 219.95x |
| 150 | -0.239149 | -0.001194 | 200.36x |

To jest silne potwierdzenie numerycznego źródła błędu.

## Istotna obserwacja: 0.05 us jako kompromis

Krok `0.05 us` daje:

- około 1000 kroków/okres przy 20 kHz,
- około 400 przy 50 kHz,
- około 196 przy 102 kHz,
- około 133 przy 150 kHz.

Przy tym kroku błąd Omega wynosi:

- 20 kHz: `-3.98e-6 deg/s`
- 50 kHz: `-1.22e-4 deg/s`
- 102.095 kHz: `+1.83e-4 deg/s`
- 150 kHz: `-6.33e-4 deg/s`

Czyli nawet w najgorszym punkcie 150 kHz błąd pozostaje poniżej `0.001 deg/s`.

Czas pojedynczej symulacji przy `0.05 us` wynosi około `1.46-2.53 s`, podczas gdy przy `0.02 us` rośnie do około `3.49-3.66 s`.

## Zalecana polityka numeryczna

Dla dalszego rozwoju:

- **20 kHz, szybkie testy i Monte Carlo:** `Ts = 0.20 us` jest wystarczające, bo błąd numeryczny Omega jest rzędu `1.7e-5 deg/s`.
- **sweep 20-150 kHz i walidacje ogólne:** `Ts = 0.05 us` jako kompromis dokładność/czas.
- **test referencyjny / walidacja wysokiej częstotliwości:** `Ts = 0.02 us`.

Nie ma potrzeby używania `0.02 us` jako domyślnego kroku wszystkich symulacji.

## Uwaga o nieidealnej monotoniczności beta przy 20 i 50 kHz

Błąd beta nie maleje idealnie monotonicznie między `0.05 us` i `0.02 us` dla 20 i 50 kHz. Jest już jednak na poziomie poniżej `0.0005%`.

Wynika to z interakcji:

- interpolacji Transport Delay,
- położenia ekstremów sinusoidy względem siatki czasowej,
- sposobu estymacji beta z maksimum i minimum próbek.

Nie zmienia to głównego wniosku z testu.

## Wniosek

**Hipoteza v3.1 została potwierdzona.**

Błędy obserwowane wcześniej dla wysokich częstotliwości nie są właściwością FOG. Są w dominującym stopniu efektem numerycznym.

Model może przejść do v4, czyli modelowania szumów fotodiody i TIA.

## Dane źródłowe

- `results/v3_1/FOG_v3_1_convergence.csv`
- `results/v3_1/FOG_v3_1_summary.csv`
