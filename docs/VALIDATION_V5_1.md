# Walidacja FOG v5.1 - optymalizacja ADC / DSP

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v5.1 zakończyło pełny zestaw testów:
- detekcja małej prędkości vs liczba bitów,
- sweep fazy zegara ADC,
- Monte Carlo vs częstotliwość próbkowania,
- Monte Carlo vs częstotliwość filtru antyaliasingowego.

## 1. Detekcja 0.0001 deg/s vs liczba bitów

Warunki:
- fs = 1 MS/s,
- AAF = 150 kHz,
- Tavg = 10 ms,
- 30 realizacji zera + 30 realizacji sygnału na każdą rozdzielczość.

| ADC | zero sigma [deg/h] | zero 3-sigma [deg/h] | signal mean [deg/s] | signal bias [deg/s] | separacja zero/signal |
|---:|---:|---:|---:|---:|---:|
| 12 bit | 0.08368 | 0.2510 | 7.3913e-5 | -2.6087e-5 | 3.150 sigma |
| 14 bit | 0.06982 | 0.2095 | 9.0145e-5 | -9.8549e-6 | 4.077 sigma |
| 16 bit | 0.09820 | 0.2946 | 1.0492e-4 | +4.9172e-6 | 4.623 sigma |

### Wniosek

- 12 bit jest rozwiązaniem granicznym. Separacja przekracza 3 sigma, ale bias amplitudy jest duży.
- 14 bit daje wyraźną detekcję powyżej 4 sigma i znacznie mniejszy bias.
- 16 bit daje największą separację i najmniejszy bias sygnału.

Różnica zero-rate sigma między 14 i 16 bit przy N=30 nie dowodzi, że 14 bit ma niższy rzeczywisty szum. Orientacyjne 95% przedziały dla sigma są szerokie i nakładają się.

**Robocza specyfikacja: minimum 14 bit, preferowane 16 bit.**

## 2. Wpływ fazy zegara ADC

Deterministyczny sweep fazy wykonano dla offsetu:
`0 ... 0.9 Ts`.

| fs | P2P błędu @ 1 deg/s | max |error| @ 1 deg/s | P2P błędu @ 1e-4 deg/s | max |error| @ 1e-4 deg/s |
|---:|---:|---:|---:|---:|
| 500 kS/s | 2.6883e-4 | 1.4986e-4 | 3.1088e-4 | 1.6064e-4 |
| 1 MS/s | 1.5578e-4 | 1.3083e-4 | 1.3103e-4 | 7.2387e-5 |
| 2 MS/s | 1.0371e-4 | 4.4079e-4 | 1.2609e-4 | 8.1039e-5 |

### Wniosek

Faza zegara ADC ma mierzalny wpływ na koherentny bias kwantyzacji.

1 MS/s daje mniejszą zależność fazową niż 500 kS/s.

Przy 2 MS/s zmiana fazy jest jeszcze mniejsza, ale występuje duży offset wspólny około 3.4e-4 ... 4.4e-4 deg/s dla testu 1 deg/s. Oznacza to, że anomalia 2 MS/s nie jest wyłącznie problemem fazy próbkowania.

## 3. Monte Carlo vs częstotliwość próbkowania

Warunki:
- 16 bit,
- AAF = 150 kHz,
- Tavg = 10 ms,
- 20 realizacji na punkt,
- Ts_solver = 0.10 us.

| fs | próbki/okres | TIA+AAF @ Nyquist | bias zero [deg/s] | sigma [deg/h] |
|---:|---:|---:|---:|---:|
| 500 kS/s | 25 | -21.91 dB | +9.824e-6 | 0.06022 |
| 1 MS/s | 50 | -50.43 dB | +3.619e-6 | 0.04742 |
| 2 MS/s | 100 | -80.06 dB | +4.191e-6 | 0.05483 |

### Ważna uwaga statystyczna

Każdy punkt ma tylko N=20 i używa osobnych realizacji szumu.

Orientacyjne 95% przedziały ufności dla sigma:
- 500 kS/s: około 0.0458 ... 0.0880 deg/h,
- 1 MS/s: około 0.0361 ... 0.0693 deg/h,
- 2 MS/s: około 0.0417 ... 0.0801 deg/h.

Przedziały silnie się nakładają. Nie można więc stwierdzić, że 1 MS/s ma fizycznie mniejszy szum od 500 kS/s lub 2 MS/s na podstawie tego Monte Carlo.

Wartości `Sigma_factor_vs_analog_v4_1 < 1` również nie oznaczają, że ADC redukuje fizyczny szum. Porównanie używa innego N Monte Carlo i innego kroku solvera niż referencja v4.1.

### Wniosek projektowy

1 MS/s pozostaje najlepszym nominalnym kompromisem:
- 50 próbek na okres modulacji,
- około -50 dB tłumienia przy Nyquiście,
- brak problemu małej liczby próbek,
- mniejsze wymagania obliczeniowe niż 2 MS/s.

500 kS/s pozostaje możliwym wariantem do późniejszej optymalizacji MCU/FPGA.

2 MS/s nie wnosi obecnie wystarczającej korzyści, a deterministyczny bias pozostaje otwarty.

## 4. Sweep filtru antyaliasingowego

Warunki:
- 16 bit,
- fs = 1 MS/s,
- Tavg = 10 ms,
- 20 realizacji na punkt.

| AAF fc | gain @20 kHz | phase lag @20 kHz | TIA+AAF @ Nyquist | sigma [deg/h] |
|---:|---:|---:|---:|---:|
| 80 kHz | 0.999992 | 37.77 deg | -72.27 dB | 0.10131 |
| 100 kHz | 0.999999 | 30.11 deg | -64.52 dB | 0.08389 |
| 150 kHz | 1.000000 | 20.01 deg | -50.43 dB | 0.11002 |

Orientacyjne 95% przedziały ufności dla sigma:
- 80 kHz: około 0.0770 ... 0.1480 deg/h,
- 100 kHz: około 0.0638 ... 0.1225 deg/h,
- 150 kHz: około 0.0837 ... 0.1607 deg/h.

Przedziały się nakładają, więc ranking Monte Carlo nie jest statystycznie rozstrzygający.

### Wniosek projektowy

AAF 100 kHz jest atrakcyjnym **roboczym kandydatem**:
- praktycznie jednostkowe wzmocnienie przy 20 kHz,
- około -64.5 dB wraz z TIA przy Nyquiście 1 MS/s,
- mniej przesunięcia fazowego niż 80 kHz.

Nie jest jeszcze formalnie udowodnione, że ma niższy szum od 80 lub 150 kHz.

## 5. Robocza specyfikacja cyfrowego toru po v5.1

Na potrzeby dalszego modelu przyjmujemy:

- **ADC minimum: 14 bit**
- **ADC preferowane: 16 bit**
- **nominalne fs: 1 MS/s**
- **zakres wejściowy: 0 ... 2 V** w obecnej architekturze
- **AAF roboczo: 100 kHz, 4-rzędowy Butterworth**
- **f_mod: 20 kHz**
- synchronizacja ADC i referencji lock-in jest istotna.

Wartości są specyfikacją symulacyjną, nie jeszcze konkretnym elementem BOM.

## 6. Otwarte kwestie

Nie blokują przejścia do v6, ale warto je zachować:

1. dodatkowy wspólny bias dla 2 MS/s,
2. dokładniejszy paired Monte Carlo z tymi samymi seedami dla porównania fs/AAF,
3. większe N dla 14 vs 16 bit,
4. decymacja po cyfrowym LPF,
5. obciążenie obliczeniowe MCU/FPGA.

## 7. Następny etap

Model może przejść do:

**v6 - zwykłe włókno SMF, polaryzacja i depolaryzator.**

Jest to kluczowy etap dla planowanego taniego prototypu na zwykłym włóknie jednomodowym.

## Dane źródłowe

- `results/v5_1/FOG_v5_1_detection_vs_bits.csv`
- `results/v5_1/FOG_v5_1_clock_phase_sweep.csv`
- `results/v5_1/FOG_v5_1_clock_phase_summary.csv`
- `results/v5_1/FOG_v5_1_fs_monte_carlo.csv`
- `results/v5_1/FOG_v5_1_aaf_monte_carlo.csv`

Historia hotfixów:
- `docs/VALIDATION_V5_1_ATTEMPT1.md`
- `docs/VALIDATION_V5_1_ATTEMPT2.md`
