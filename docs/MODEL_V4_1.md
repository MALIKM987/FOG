# FOG v4.1 - rozszerzona analiza statystyczna

## Cel

v4.1 nie zmienia fizyki modelu v4. Jest warstwą statystyczną nad zweryfikowanym `FOG_v4.slx`.

Główne cele:

- zwiększyć Monte Carlo z 12 do 100 realizacji zero-rate,
- zbadać wpływ czasu uśredniania na `sigma_Omega`,
- sprawdzić zgodność ze skalowaniem białego szumu `1/sqrt(T)`,
- ustabilizować roboczy próg 1-sigma i 3-sigma,
- ponownie sprawdzić punkt `0.0001 deg/s`,
- osobno sprawdzić deterministyczny bias numeryczny FAST vs STANDARD.

## Zero-rate Monte Carlo

Domyślnie:

- `Nmc = 100`,
- `Ts = 0.20 us` (FAST),
- `Tsettle = 20 ms`,
- czasy uśredniania: `1, 2, 5, 10, 20 ms`.

Każda realizacja jest symulowana tylko raz. Z jej końca liczone są średnie dla wszystkich pięciu okien.

Zapisywane są:

- mean zero-rate,
- sigma zero-rate,
- sigma w deg/h,
- próg 1-sigma,
- próg 3-sigma,
- `sigma*sqrt(T)`.

Dodatkowo wykonywane jest dopasowanie:

`log10(sigma) = a log10(Tavg) + b`.

Dla idealnego białego szumu oczekujemy:

`a ~= -0.5`.

## Detection check

Dla:

`Omega = 0.0001 deg/s`

wykonywanych jest:

`Ndetect = 50`

realizacji przy `Tavg = 10 ms`.

Raportowane są:

- mean,
- STD,
- bias,
- RMSE,
- `|Omega|/STD`,
- separacja średnich klasy zero i sygnału wyrażona w połączonej sigmie.

## Numerical baseline check

Bez szumu wykonywane są dwa przebiegi dla:

`Omega = 1 deg/s`

z krokami:

- FAST: `0.20 us`,
- STANDARD: `0.05 us`.

Celem jest sprawdzenie, ile z obserwowanego stałego biasu pochodzi z rozdzielczości numerycznej.

## Pliki wynikowe

- `FOG_v4_1.slx`
- `FOG_v4_1_zero_rate_vs_Tavg.csv`
- `FOG_v4_1_zero_rate_raw.csv`
- `FOG_v4_1_detection_check.csv`
- `FOG_v4_1_detection_raw.csv`
- `FOG_v4_1_numerical_baseline.csv`

## Uwaga interpretacyjna

v4.1 nadal bada wyłącznie biały szum fotodetektora/TIA w obecnym modelu.

Nie obejmuje jeszcze:

- dryftu temperatury,
- flicker noise / 1/f,
- niestabilności źródła,
- polaryzacji SMF,
- backscatter,
- efektów mechanicznych cewki,
- kwantyzacji ADC.

Dlatego wynik `3 sigma` nie jest jeszcze końcową specyfikacją żyroskopu.

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Najważniejsze wyniki:

- 100 realizacji zero-rate,
- sigma przy 10 ms: `1.9999e-5 deg/s`,
- sigma przy 20 ms: `1.5247e-5 deg/s`,
- próg 3-sigma przy 20 ms: `0.1647 deg/h`,
- dopasowany slope `sigma(Tavg)`: `-0.3931`,
- detekcja `0.0001 deg/s` przy 10 ms: separacja `4.83 sigma`,
- bias 1 deg/s maleje z `-9.54e-5` do `-4.31e-6 deg/s` po przejściu FAST -> STANDARD.

Szczegóły: `docs/VALIDATION_V4_1.md`.
