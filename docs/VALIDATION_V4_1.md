# Walidacja FOG v4.1 - rozszerzona analiza statystyczna

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v4.1 nie zmienia fizyki modelu v4. Rozszerza statystykę zero-rate, zależność szumu od czasu uśredniania, detekcję małej prędkości oraz osobno kontroluje bias numeryczny.

## 1. Zero-rate Monte Carlo

Wykonano:

- `N = 100` niezależnych realizacji,
- czasy uśredniania: `1, 2, 5, 10, 20 ms`,
- tryb numeryczny FAST: `Ts = 0.20 us`.

Wyniki:

| Tavg [ms] | mean [deg/s] | sigma [deg/s] | sigma [deg/h] | 3-sigma [deg/h] |
|---:|---:|---:|---:|---:|
| 1 | -8.2344e-6 | 4.7054e-5 | 0.1694 | 0.5082 |
| 2 | -6.9878e-6 | 4.0938e-5 | 0.1474 | 0.4421 |
| 5 | -4.3317e-6 | 2.4091e-5 | 0.08673 | 0.2602 |
| 10 | -1.1950e-6 | 1.9999e-5 | 0.07200 | 0.2160 |
| 20 | -1.4074e-6 | 1.5247e-5 | 0.05489 | 0.1647 |

Szacowane 95% przedziały ufności dla sigma, wynikające ze 100 realizacji:

- 10 ms: około `1.756e-5 ... 2.323e-5 deg/s`,
- 20 ms: około `1.339e-5 ... 1.771e-5 deg/s`.

Dla odpowiadającego progu `3 sigma` daje to orientacyjnie:

- 10 ms: `0.190 ... 0.251 deg/h`,
- 20 ms: `0.145 ... 0.191 deg/h`.

## 2. Skalowanie sigma z czasem uśredniania

Dopasowany wykładnik:

`sigma(Tavg) ~ Tavg^a`

wyniósł:

`a = -0.3931`.

Idealny biały szum dawałby:

`a = -0.5`.

Bootstrap po realizacjach daje orientacyjny 95% przedział dla nachylenia około:

`-0.47 ... -0.315`.

Oznacza to, że w zakresie `1-20 ms` wyjście nie zachowuje się jeszcze jak idealnie niezależne białe próbki po prostym uśrednianiu.

Najbardziej prawdopodobne źródła:

- korelacja czasowa wprowadzona przez 4-rzędowy LPF lock-in,
- skończone pasmo TIA,
- zbyt krótki zakres `Tavg` do obserwacji asymptotycznego `1/sqrt(T)`.

Nie należy więc na podstawie v4.1 deklarować idealnego prawa `T^-1/2`. Wymaga to dłuższych okien lub analizy PSD/Allan.

## 3. Detection check dla 0.0001 deg/s

Dla:

`Omega = 0.0001 deg/s = 0.36 deg/h`

oraz:

- `Tavg = 10 ms`,
- `N = 50` realizacji,

otrzymano:

- mean: `9.90545e-5 deg/s`,
- STD: `2.14634e-5 deg/s`,
- bias: `-9.45e-7 deg/s`,
- RMSE: `2.12687e-5 deg/s`,
- `|Omega|/STD = 4.659`,
- separacja klasy zero i klasy sygnału: `4.833 sigma`.

95% przedział ufności dla średniej punktu sygnałowego wynosi w przybliżeniu:

`9.30e-5 ... 1.0515e-4 deg/s`.

Punkt `0.0001 deg/s` jest więc w obecnym modelu wyraźnie rozróżnialny od zera przy tym czasie uśredniania.

## 4. Numerical baseline FAST vs STANDARD

Bez szumu, dla `Omega = 1 deg/s`:

| Ts [us] | Omega measured [deg/s] | error [deg/s] |
|---:|---:|---:|
| 0.20 | 0.999904586 | -9.541e-5 |
| 0.05 | 0.999995688 | -4.312e-6 |

Zmniejszenie kroku z `0.20 us` do `0.05 us` redukuje bezwzględny bias około **22.1 razy**.

To potwierdza, że większa część stałego błędu v4 przy 1 deg/s pochodzi z trybu FAST, a nie z samej fizyki odbiornika.

## 5. Zalecenia

1. **Monte Carlo i rozwój modelu:** można nadal używać FAST `Ts=0.20 us`.
2. **Wyniki dokładności i biasu:** używać STANDARD `Ts=0.05 us`.
3. **Minimalna wykrywalna prędkość:** nie raportować jako ostatecznej specyfikacji wyłącznie na podstawie 10 ms.
4. Przed v5 warto wykonać krótki dodatkowy test długich czasów uśredniania lub pozostawić analizę Allan/PSD do późniejszego etapu.
5. W obecnym modelu punkt `0.0001 deg/s` przy `Tavg=10 ms` jest detekowalny z separacją około `4.83 sigma`.

## Dane źródłowe

- `results/v4_1/FOG_v4_1_zero_rate_vs_Tavg.csv`
- `results/v4_1/FOG_v4_1_detection_check.csv`
- `results/v4_1/FOG_v4_1_numerical_baseline.csv`

Pełne surowe pliki lokalne:
- `FOG_v4_1_zero_rate_raw.csv`
- `FOG_v4_1_detection_raw.csv`
