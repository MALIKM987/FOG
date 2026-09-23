# Model FOG v2

## Status

Implementacja przygotowana do walidacji lokalnej w MATLAB/Simulink R2023b.

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

Amplituda różnicowej modulacji wynosi więc:

`beta = 2 phi0 |sin(pi f_mod tau)|`.

## Parametry bazowe

- `lambda = 1550 nm`
- `L = 1000 m`
- `D = 160 mm`
- `n_g = 1.4682`
- `tau ~= 4.897 us`
- `f_opt = 1/(2 tau) ~= 102.10 kHz`
- punkt projektowy: `f_design = 20 kHz`
- cel: `beta_target = 1.84 rad`

Amplituda pojedynczego przejścia PZT zostaje dobrana przy 20 kHz:

`phi0_fixed = beta_target / [2 |sin(pi f_design tau)|]`

co daje około `3.04 rad`.

## Referencja lock-in

W v2 referencja lock-in nie jest osobnym idealnym generatorem. Powstaje z rzeczywistej różnicowej modulacji:

`reference(t) = Delta_phi_m(t) / beta`.

Dzięki temu zachowuje prawidłową fazę po wprowadzeniu opóźnienia `tau`.

## Sweep częstotliwości

Skrypt bada:

- 5 kHz
- 10 kHz
- 20 kHz
- 50 kHz
- `f_opt` około 102.10 kHz
- 150 kHz

Dla każdego punktu zapisuje:

- `beta` z teorii,
- `beta` zmierzone w modelu,
- błąd amplitudy,
- `|sin(pi f tau)|`,
- `J1(beta)`,
- wymaganą wartość `phi0` dla utrzymania `beta = 1.84 rad`,
- estymowaną prędkość kątową dla 1 deg/s,
- błąd estymacji,
- średnią wartość wyjścia filtru lock-in.

## Ważne rozróżnienie

`f_opt = 1/(2 tau)` maksymalizuje czynnik:

`|sin(pi f_mod tau)|`

czyli maksymalną różnicę faz uzyskaną z zadanej amplitudy `phi0`.

Nie oznacza to automatycznie maksimum czułości demodulacji pierwszej harmonicznej. Czułość tej ścieżki zależy także od:

`J1(beta)`.

Dla dużego `beta` funkcja Bessela może maleć, zmienić znak lub przejść przez zero. Dlatego w praktycznym układzie częstotliwość i amplituda PZT muszą być dobierane razem.

## Pliki wynikowe

Po poprawnym uruchomieniu skrypt generuje:

- `FOG_v2.slx`
- `FOG_v2_baseline.csv`
- `FOG_v2_frequency_sweep.csv`

Wyniki nie są jeszcze wpisane jako zweryfikowane w repozytorium. Powinny zostać dodane dopiero po uruchomieniu modelu na środowisku docelowym i sprawdzeniu zgodności `beta_sim` z `beta_theory`.
