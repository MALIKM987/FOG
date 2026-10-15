# Walidacja FOG v2.1

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v2.1 naprawia artefakt demodulacji lock-in obserwowany w v2 przy niskiej częstotliwości modulacji.

## Punkt bazowy 20 kHz

Dla `Omega = 1 deg/s`:

- `Omega_mean = 0.999985491 deg/s`
- błąd `Omega = -0.000014509 deg/s`
- `STD_Omega = 0.000001632 deg/s`
- `beta_theory = 1.840000000 rad`
- `beta_sim = 1.839891517 rad`

Względny błąd beta wynosi około `-0.00590%`.

## Najważniejszy test 5 kHz

W v2:

- błąd `Omega ~= +0.075665 deg/s`

W v2.1:

- `Omega_measured = 0.999998184 deg/s`
- błąd `Omega = -0.000001816 deg/s`

Redukcja bezwzględnego błędu wynosi około **99.9976%**, czyli około **41 674 razy**.

To potwierdza, że duży błąd v2 przy 5 kHz był artefaktem toru lock-in, a nie błędem modelu PZT + opóźnienie CW/CCW.

## Sweep częstotliwości

| f_mod [kHz] | Omega zmierzona [deg/s] | błąd [deg/s] | STD Omega [deg/s] |
|---:|---:|---:|---:|
| 5.000 | 0.999998184 | -0.000001816 | 2.0518e-3 |
| 10.000 | 0.999993570 | -0.000006430 | 6.1670e-5 |
| 20.000 | 0.999985491 | -0.000014509 | 1.6321e-6 |
| 50.000 | 0.999032355 | -0.000967645 | 5.3422e-8 |
| 102.095 | 1.001494504 | +0.001494504 | 7.6246e-9 |
| 150.000 | 0.994867043 | -0.005132957 | 5.9633e-10 |

## Interpretacja

1. Butterworth 4. rzędu skutecznie usunął resztkową składową po mieszaczu przy 5-20 kHz.
2. Malejące `STD_Omega` przy wzroście częstotliwości potwierdza coraz skuteczniejsze tłumienie harmonicznych przez filtr.
3. Pozostały błąd średniej przy 50-150 kHz nie ma charakteru tętnienia, ponieważ STD jest bardzo małe.
4. Ten błąd koreluje ze wzrostem różnicy `beta_sim - beta_theory` i najprawdopodobniej pochodzi z dyskretyzacji czasowej / interpolacji bloku Transport Delay przy stałym kroku `Ts = 0.2 us`.
5. Przed wyciąganiem wniosków o dokładności absolutnej dla częstotliwości powyżej 50 kHz warto wykonać osobny test zbieżności numerycznej ze zmniejszanym krokiem solvera.

## Wniosek

**v2.1 spełnia cel korekty toru lock-in.**

Model można wykorzystać jako bazę do v3, przy czym test zbieżności numerycznej dla wysokich częstotliwości powinien zostać zachowany jako osobna kontrola jakości modelu.

## Dane źródłowe

- `results/v2_1/FOG_v2_1_baseline.csv`
- `results/v2_1/FOG_v2_1_frequency_sweep.csv`
