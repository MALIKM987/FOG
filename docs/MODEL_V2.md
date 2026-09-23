# Model FOG v2

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

v2 usuwa największe uproszczenie v1: zamiast podawać gotową różnicową modulację fazy, modeluje fazę PZT oraz różnicę wynikającą z czasu propagacji fal CW i CCW.

## Model modulatora

Faza wprowadzana przez PZT:

`phi_m(t) = phi0 sin(2 pi f_mod t)`

Druga fala widzi modulator po czasie:

`tau = n_g L / c`

Dlatego interferometr otrzymuje:

`Delta_phi_m(t) = phi_m(t) - phi_m(t - tau)`

Po przekształceniu:

`Delta_phi_m(t) = 2 phi0 sin(pi f_mod tau) cos(2 pi f_mod t - pi f_mod tau)`

Amplituda różnicowej modulacji wynosi:

`beta = 2 phi0 |sin(pi f_mod tau)|`.

## Parametry bazowe

- `lambda = 1550 nm`
- `L = 1000 m`
- `D = 160 mm`
- `n_g = 1.4682`
- `tau = 4.897388 us`
- `f_opt = 102.095 kHz`
- punkt projektowy: `f_design = 20 kHz`
- cel: `beta_target = 1.84 rad`

Dla 20 kHz:

`phi0_fixed = 3.037518 rad`.

## Wynik walidacji punktu bazowego

Dla `Omega = 1 deg/s`:

- `beta_theory = 1.840000000 rad`
- `beta_sim = 1.839891517 rad`
- względny błąd beta około `-0.00590%`
- `Omega_measured = 1.000159695 deg/s`
- błąd Omega `+0.000159695 deg/s`

Rdzeń modelu PZT + delay jest więc zgodny z zależnością analityczną.

## Referencja lock-in

Referencja lock-in powstaje z rzeczywistej różnicowej modulacji:

`reference(t) = Delta_phi_m(t) / beta`.

Dzięki temu zachowuje prawidłową fazę po wprowadzeniu opóźnienia `tau`.

## Sweep częstotliwości

Zweryfikowane punkty:

- 5 kHz
- 10 kHz
- 20 kHz
- 50 kHz
- 102.095 kHz
- 150 kHz

Najważniejsze wyniki:

- przy `f_opt ~= 102.095 kHz` czynnik `|sin(pi f_mod tau)| = 1`,
- dla stałego `phi0 = 3.037518 rad` otrzymujemy tam `beta_theory ~= 6.075 rad`,
- aby utrzymać `beta = 1.84 rad`, wystarczy przy `f_opt` `phi0 = 0.92 rad`,
- `J1(beta)` zmienia wartość i znak, więc maksimum opóźnieniowej skuteczności modulacji nie jest tym samym co maksimum czułości pierwszej harmonicznej.

## Uwaga o demodulacji przy 5 kHz

Przy 5 kHz model opóźnienia nadal odtwarza beta z błędem mniejszym niż 0.001%, lecz estymacja Omega ma większy błąd.

To wskazuje na ograniczenie obecnego demodulatora lock-in i krótkiego okna czasowego, a nie na niezgodność równania opóźnienia. Szczegóły są w `docs/VALIDATION_V2.md`.

## Pliki

Kod:

- `matlab/v2/FOG_start_v2.m`

Zweryfikowane wyniki:

- `results/v2/FOG_v2_baseline.csv`
- `results/v2/FOG_v2_frequency_sweep.csv`

Raport:

- `docs/VALIDATION_V2.md`
