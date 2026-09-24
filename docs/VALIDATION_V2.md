# Walidacja FOG v2

## Status

**Rdzeń modelu v2 zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

Walidacja potwierdza poprawne odwzorowanie fizycznego modulatora PZT i różnicy faz wynikającej z opóźnienia propagacji CW/CCW.

## Punkt bazowy

Parametry:

- `lambda = 1550 nm`
- `L = 1000 m`
- `D = 160 mm`
- `n_g = 1.4682`
- `tau = 4.897388 us`
- `f_opt = 102.095 kHz`
- `f_design = 20 kHz`
- `beta_target = 1.84 rad`
- `phi0 = 3.037518 rad`

Dla `Omega = 1 deg/s`:

- `Delta_phi_S = 0.037759 rad`
- `Omega_measured = 1.000159695 deg/s`
- błąd `Omega = +0.000159695 deg/s`

Porównanie modulacji:

- `beta_theory = 1.840000000 rad`
- `beta_sim = 1.839891517 rad`
- błąd bezwzględny `beta = -0.000108483 rad`
- błąd względny około `-0.00590%`

To potwierdza zależność:

`beta = 2 phi0 |sin(pi f_mod tau)|`

dla punktu projektowego 20 kHz.

## Sweep częstotliwości

| f_mod [kHz] | beta teoria [rad] | beta symulacja [rad] | błąd beta [%] | phi0 dla beta=1.84 [rad] | Omega zmierzona [deg/s] | błąd Omega [deg/s] |
|---:|---:|---:|---:|---:|---:|---:|
| 5.000 | 0.466880 | 0.466878 | -0.00037 | 11.9710 | 1.075665 | +0.075665 |
| 10.000 | 0.930997 | 0.930984 | -0.00147 | 6.0033 | 1.003761 | +0.003761 |
| 20.000 | 1.840000 | 1.839892 | -0.00590 | 3.0375 | 1.000160 | +0.000160 |
| 50.000 | 4.225905 | 4.224352 | -0.03676 | 1.3226 | 0.999068 | -0.000932 |
| 102.095 | 6.075036 | 6.068793 | -0.10277 | 0.9200 | 1.001680 | +0.001680 |
| 150.000 | 4.498314 | 4.487557 | -0.23915 | 1.2425 | 0.994868 | -0.005132 |

## Wnioski

1. Zależność amplitudy różnicowej modulacji od częstotliwości i opóźnienia jest odwzorowana poprawnie.
2. `f_opt = 1/(2 tau)` rzeczywiście maksymalizuje czynnik `|sin(pi f_mod tau)|`. W punkcie około 102.095 kHz jego wartość wynosi 1.
3. Przy stałym `phi0 = 3.0375 rad` amplituda `beta` rośnie do około 6.075 rad przy `f_opt`.
4. Aby utrzymać `beta = 1.84 rad`, wymagana amplituda PZT maleje do `phi0 = 0.92 rad` przy `f_opt`.
5. Czułość demodulacji pierwszej harmonicznej nie jest tym samym co maksymalizacja `beta`. `J1(beta)` zmienia wartość i znak.
6. Różnica między `beta_theory` i `beta_sim` rośnie wraz z częstotliwością, ale nawet przy 150 kHz pozostaje poniżej 0.25%. Jest to zgodne z ograniczoną rozdzielczością czasową symulacji i interpolacją opóźnienia.

## Uwaga o punkcie 5 kHz

Błąd estymacji `Omega` przy 5 kHz wynosi około `+0.0757 deg/s`, mimo bardzo dobrej zgodności `beta`.

Nie wskazuje to na błąd modelu opóźnienia PZT. Głównym podejrzanym jest obecna ścieżka demodulacji:

- filtr lock-in jest tylko pierwszego rzędu,
- `fc = 300 Hz`,
- sygnał nośny przy 5 kHz jest znacznie słabiej tłumiony niż przy 20-150 kHz,
- końcowa estymacja powstaje z krótkiego okna czasowego.

Przed uznaniem charakterystyki błędu `Omega(f_mod)` za wynik fizyczny należy w następnej korekcie wydłużyć okno symulacji i/lub ulepszyć filtrację synchroniczną.

Nie blokuje to walidacji głównego celu v2: fizycznej relacji PZT + opóźnienie CW/CCW.

## Dane źródłowe

- `results/v2/FOG_v2_baseline.csv`
- `results/v2/FOG_v2_frequency_sweep.csv`
