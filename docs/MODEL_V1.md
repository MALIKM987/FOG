# Model FOG v1

## Status

Model został uruchomiony w MATLAB/Simulink R2023b Update 7 i przeszedł serię testów dla prędkości od -20 do +20 deg/s.

## Parametry

- długość fali: `lambda = 1550 nm`
- długość cewki: `L = 1000 m`
- średnia średnica cewki: `D = 160 mm`
- współczynnik grupowy: `n_g = 1.4682`
- częstotliwość modulacji: `f_mod = 20 kHz`
- amplituda różnicowej modulacji: `beta = 1.84 rad`
- responsywność fotodiody: `R_pd = 0.9 A/W`
- transimpedancja: `R_TIA = 20 kOhm`
- filtr lock-in: `f_c = 300 Hz`

## Model Sagnaca

Przyjęto

`Delta_phi_S = K_sag Omega`

gdzie

`K_sag = 2 pi L D / (lambda c)`.

Dla parametrów bazowych:

- `K_sag = 2.163453 rad/(rad/s)`
- `tau = n_g L / c = 4.897 us`
- `f_opt = 1/(2 tau) = 102.10 kHz`

Dla `Omega = 1 deg/s`:

`Delta_phi_S = 0.037759 rad`.

## Interferencja

W v1 użyty jest uproszczony model:

`P(t) = P_scale [1 + V cos(Delta_phi_S + beta sin(2 pi f_mod t))]`

gdzie `V` oznacza visibility.

Jest to model deterministyczny. Nie obejmuje jeszcze rzeczywistego opóźnienia propagacji w modulatorze, szumów ani zmian polaryzacji.

## Demodulacja

Napięcie z TIA jest mnożone przez referencję 20 kHz i filtrowane dolnoprzepustowo. Po normalizacji otrzymujemy wielkość proporcjonalną do

`sin(Delta_phi_S)`.

Model porównuje dwa sposoby estymacji:

1. przybliżenie liniowe,
2. korekcję nieliniową `asin`.

## Wyniki walidacji

Dla 20 deg/s:

- estymacja liniowa: około 18.152 deg/s,
- błąd liniowy: około -1.848 deg/s, czyli około -9.24%,
- estymacja `asin`: około 20.008 deg/s,
- błąd `asin`: około +0.0081 deg/s, czyli około +0.040%.

Wniosek: przybliżenie liniowe jest użyteczne w pobliżu zera, ale dla większej fazy Sagnaca potrzebna jest korekcja nieliniowości.

## Ograniczenie v1

Najważniejsze uproszczenie to bezpośrednie zadanie różnicowej modulacji fazy.

W rzeczywistym układzie modulator wprowadza

`phi_m(t) = phi_0 sin(2 pi f_m t)`

a fale CW i CCW próbkują modulator w różnych chwilach. Dlatego:

`Delta_phi_m(t) = phi_m(t) - phi_m(t - tau)`.

To będzie podstawą modelu v2.
