# Walidacja FOG v6 - standard SMF, polaryzacja i depolaryzator

## Status

**Model wrażliwościowy v6 zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

Wniosek projektowy nie jest jednak równoważny stwierdzeniu, że nominalny punkt `depol_residual = 0.1` spełnia cel detekcji `0.0001 deg/s`.

Przeciwnie: przy losowych stanach SMF nominalne `r=0.1` daje separację tylko około `2.42 sigma`.

## 1. Regresja idealnej polaryzacji

Dla:

- `Omega = 1 deg/s`,
- `pol_enable = 0`,
- 16 bit / 1 MS/s,
- AAF 100 kHz,

otrzymano:

- `Omega_est = 0.999976255 deg/s`,
- błąd = `-2.37448e-5 deg/s`,
- STD = `1.65245e-6 deg/s`,
- `V_pol = V_cal = 0.993695382`,
- `phi_pol = 0`.

To potwierdza, że samo dodanie subsystemu polaryzacyjnego nie zepsuło podstawowego toru.

## 2. Dynamiczny sweep skuteczności depolaryzacji

| residual | Vpol min | max |phi_pol| [rad] | zero mean [deg/s] | zero STD [deg/s] | scale error |
|---:|---:|---:|---:|---:|---:|
| 1.00 | 0.98364 | 1.294e-5 | -9.58e-6 | 1.527e-4 | -0.2937% |
| 0.50 | 0.98867 | 6.469e-6 | -5.49e-6 | 8.297e-5 | -0.1496% |
| 0.20 | 0.99168 | 2.587e-6 | -1.71e-6 | 3.033e-5 | -0.0623% |
| 0.10 | 0.99269 | 1.294e-6 | -2.42e-6 | 1.813e-5 | -0.0347% |
| 0.05 | 0.99319 | 6.469e-7 | +1.15e-6 | 1.152e-5 | -0.0203% |
| 0.00 | 0.99370 | 0 | ~0 | 1.651e-6 | -0.0112% |

Efekt depolaryzatora jest wyraźny i zgodny z konstrukcją modelu.

Przejście:

`r = 1 -> r = 0.1`

zmniejsza bezwzględny błąd skali około **8.47 razy**.

Dla:

`r = 1 -> r = 0.05`

redukcja wynosi około **14.47 razy**.

## 3. Monte Carlo losowych stanów standardowego SMF

Każdy punkt:
- N = 20,
- pełny szum Photoreceivera,
- losowy statyczny stan polaryzacji między realizacjami.

| residual | zero sigma [deg/h] | P95 |Omega| [deg/s] | max |Omega| [deg/s] | mean visibility |
|---:|---:|---:|---:|---:|
| 1.00 | 0.8624 | 5.344e-4 | 7.879e-4 | 0.98723 |
| 0.20 | 0.2498 | 1.517e-4 | 1.731e-4 | 0.99103 |
| 0.10 | 0.1460 | 7.752e-5 | 7.871e-5 | 0.99230 |
| 0.05 | 0.08646 | 3.882e-5 | 4.113e-5 | 0.99321 |

Redukcja zero-rate sigma:

- `1 -> 0.1`: około **5.91x**,
- `1 -> 0.05`: około **9.98x**.

Redukcja 95 percentyla |Omega|:

- `1 -> 0.1`: około **6.89x**,
- `1 -> 0.05`: około **13.77x**.

### Niepewność statystyczna

Przy N=20 orientacyjne 95% przedziały ufności dla sigma są szerokie:

- r=1.0: około `0.656 ... 1.260 deg/h`,
- r=0.2: `0.190 ... 0.365 deg/h`,
- r=0.1: `0.111 ... 0.213 deg/h`,
- r=0.05: `0.0658 ... 0.126 deg/h`.

Trend jest jednak na tyle silny, że wniosek o dużej redukcji wpływu polaryzacji wraz z malejącym residual jest wiarygodny w ramach modelu.

## 4. Detekcja 0.0001 deg/s dla nominalnego r=0.1

`0.0001 deg/s = 0.36 deg/h`.

Dla:
- `depol_residual = 0.1`,
- N=30 na klasę,

otrzymano:

- zero mean = `1.1044e-5 deg/s`,
- zero sigma = `3.3210e-5 deg/s = 0.11956 deg/h`,
- próg zero `3 sigma = 0.35867 deg/h`,
- signal mean = `1.0240e-4 deg/s`,
- signal sigma = `4.1662e-5 deg/s`,
- signal bias = `+2.40e-6 deg/s`,
- separacja zero/signal = **2.425 sigma**.

Różnica średnich klas wynosi około:

`9.136e-5 deg/s = 0.3289 deg/h`.

### Wniosek

Nominalny punkt `r=0.1` **nie daje jeszcze robust detekcji 3-sigma** dla `0.0001 deg/s` w tym modelu.

To ważniejszy wynik niż samo porównanie sygnału 0.36 deg/h z `3 sigma` zera, ponieważ rozkład klasy sygnałowej również ma własny rozrzut.

## 5. Co to znaczy dla użycia zwykłego SMF

v6 nie mówi, że standardowe SMF jest nieprzydatne.

Mówi:

1. bez skutecznej kontroli polaryzacji wpływ SMF dominuje nad wcześniejszym szumem ADC/Photoreceivera,
2. modelowy residual = 0.1 jest jeszcze zbyt duży dla celu 0.0001 deg/s,
3. residual = 0.05 w Monte Carlo zero-rate daje sigma około 0.0865 deg/h, znacznie bliżej wyników toru przed dodaniem polaryzacji,
4. potrzebny jest test detekcji dla residual około 0.05 i niżej,
5. rzeczywisty residual i `pol_nr_scale` muszą zostać zmierzone lub skalibrowane.

## 6. Bardzo ważne ograniczenie fizyczne

Model v6 jest modelem wrażliwościowym.

W kodzie:
- cewka pozostaje 1 km standardowego SMF,
- depolaryzator jest opisany fenomenologicznym `depol_residual`,
- `pol_nr_scale` jest parametrem wymagającym kalibracji,
- częstotliwości zmian theta/delta są przyspieszonym testem wrażliwości.

Dlatego wartości biasu z v6 nie są prognozą dokładności gotowego fizycznego żyroskopu.

## 7. Następny krok v6.1

Przed temperaturą rekomendowane jest krótkie v6.1:

1. detection sweep dla residual:
   `0.10, 0.075, 0.05, 0.025, 0`,
2. paired Monte Carlo z tymi samymi stanami SMF i seedami,
3. sweep `pol_nr_scale`,
4. wyznaczenie granicznego residual wymaganego dla separacji >=3 sigma i >=4 sigma,
5. przeliczenie tego na wymaganie eksperymentalne dla prototypu.

Dopiero potem warto przejść do v7, aby nie mieszać nieustalonego błędu polaryzacyjnego z dryftem termicznym.

## Dane źródłowe

- `results/v6/FOG_v6_baseline.csv`
- `results/v6/FOG_v6_depolarizer_sweep.csv`
- `results/v6/FOG_v6_smf_monte_carlo.csv`
- `results/v6/FOG_v6_detection_random_smf.csv`
- `results/v6/FOG_v6_model_parameters.csv`
