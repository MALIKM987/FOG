# Model FOG v2.1

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

v2.1 nie zmienia fizyki modelu v2. Poprawia tor demodulacji lock-in, który w v2 powodował artefakt przy 5 kHz.

## Zmiany względem v2

- filtr lock-in: 1. rząd -> Butterworth 4. rzędu,
- `fc = 300 Hz`,
- czas symulacji: `20 ms -> 50 ms`,
- estymacja z ostatnich `10 ms`,
- dodane `STD_Omega_deg_s` i `LockIn_LPF_std`.

## Wynik testu akceptacyjnego

Dla `5 kHz` i zadanego `Omega = 1 deg/s`:

v2:

`Omega_measured ~= 1.075665 deg/s`

v2.1:

`Omega_measured = 0.999998184 deg/s`

Błąd spadł z około `+0.075665 deg/s` do `-1.816e-6 deg/s`.

Oznacza to redukcję bezwzględnego błędu o około `99.9976%`.

## Punkt 20 kHz

- `Omega_mean = 0.999985491 deg/s`
- `Omega_error = -1.4509e-5 deg/s`
- `STD_Omega = 1.6321e-6 deg/s`
- `beta_theory = 1.84 rad`
- `beta_sim = 1.839891517 rad`

## Uwaga o wysokich częstotliwościach

Przy 50-150 kHz pozostaje mały błąd średniej mimo bardzo małego STD. Towarzyszy mu rosnąca różnica między `beta_sim` i `beta_theory`.

Najbardziej prawdopodobnym źródłem jest ograniczona rozdzielczość numeryczna bloku `Transport Delay` przy `Ts = 0.2 us`.

Nie jest to już błąd lock-in. Warto później wykonać test zbieżności dla `Ts = 0.2, 0.1, 0.05, 0.02 us`.

## Pliki

Kod:

- `matlab/v2_1/FOG_start_v2_1.m`

Wyniki:

- `results/v2_1/FOG_v2_1_baseline.csv`
- `results/v2_1/FOG_v2_1_frequency_sweep.csv`

Raport:

- `docs/VALIDATION_V2_1.md`
