# Walidacja FOG v4 - fotodioda, TIA i szumy

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7 po hotfixie topologii Photoreceiver.**

Pierwsza próba była nieważna z powodu odłączonego subsystemu Photoreceiver. Po poprawce tor został prawidłowo połączony i wyniki v4 są spójne z modelem analitycznym.

## 1. Walidacja fotoprądu i RMS szumu

Dla `Omega = 0`:

- analityczny średni fotoprąd: `53.782976 uA`
- średni fotoprąd z Simulinka: `53.784702 uA`
- względna różnica: około `+0.00321%`

Szum na wyjściu TIA:

- teoria: `47.697074 uV RMS`
- Simulink: `47.694708 uV RMS`
- różnica: `-0.004961%`

Zgodność teoria/symulacja jest więc bardzo dobra.

## 2. Budżet szumów

| Źródło | ASD [pA/sqrtHz] | RMS na wyjściu TIA [uV] | udział w wariancji |
|---|---:|---:|---:|
| Photo shot | 4.151381 | 46.536910 | 95.1944% |
| Dark-current shot | 0.040027 | 0.448704 | 0.00885% |
| Rf Johnson | 0.910159 | 10.202866 | 4.57574% |
| OpAmp current | 0.002000 | 0.022420 | 0.000022% |
| OpAmp voltage equiv. | 0.200000 | 2.241996 | 0.220946% |
| RSS | 4.254875 | 47.697074 | 100% |

Dla nominalnych parametrów v4 model jest **shot-noise dominated**. Photo-shot noise odpowiada za około 95.2% wariancji szumu.

Wniosek dotyczy wyłącznie obecnych założeń źródła, strat i fotoodbiornika.

## 3. Tor deterministyczny po dodaniu TIA bandwidth

Dla zadanego:

`Omega = 1 deg/s`

bez losowego szumu otrzymano:

- `Omega_est = 0.999904586 deg/s`
- błąd deterministyczny: `-9.54137e-5 deg/s`

Błąd jest mały, ale większy niż w v3. Wynika z dodania transmitancji TIA, kompensacji fazowej oraz użycia trybu FAST `Ts = 0.20 us`.

Nie należy mylić tego biasu z szumem losowym. W kolejnej kontroli warto:
- sprawdzić baseline w trybie STANDARD `Ts = 0.05 us`,
- ewentualnie wprowadzić kalibrację stałego gain/phase toru odbiornika.

## 4. Monte Carlo małych prędkości

Wykonano 12 realizacji dla każdego poziomu:

| Omega zadane [deg/s] | mean [deg/s] | STD [deg/s] | bias [deg/s] | SNR = |Omega|/STD |
|---:|---:|---:|---:|---:|
| 0 | 3.9301e-6 | 2.5344e-5 | 3.9301e-6 | - |
| 0.0001 | 1.00938e-4 | 2.3910e-5 | 9.3834e-7 | 4.18 |
| 0.0005 | 4.93182e-4 | 2.3083e-5 | -6.8178e-6 | 21.66 |
| 0.001 | 1.00053e-3 | 1.4480e-5 | 5.3354e-7 | 69.06 |
| 0.005 | 5.00172e-3 | 2.3924e-5 | 1.7201e-6 | 209.0 |
| 0.01 | 9.99464e-3 | 2.1003e-5 | -5.3640e-6 | 476.1 |
| 0.1 | 9.99995e-2 | 1.4023e-5 | -4.5935e-7 | 7131 |
| 1 | 0.999915 | 2.6096e-5 | -8.4608e-5 | 38320 |

## 5. Zero-rate noise i roboczy próg detekcji

Dla punktu zerowego:

- zero-rate bias: `+3.9301e-6 deg/s`
- zero-rate sigma: `2.53443e-5 deg/s`
- roboczy próg 3-sigma: `7.60330e-5 deg/s`

Po przeliczeniu:

- sigma: około `0.0912 deg/h`
- 3-sigma: około `0.2737 deg/h`

Punkt:

`0.0001 deg/s = 0.36 deg/h`

ma w tej serii Monte Carlo:

`SNR ~= 4.18`

czyli leży powyżej roboczego progu 3-sigma.

## 6. Bardzo ważne ograniczenie statystyczne

Monte Carlo ma na tym etapie tylko **12 realizacji na punkt**.

Dlatego:

- sigma zero,
- próg 3-sigma,
- SNR małych prędkości

są wynikami **wstępnymi**, nie ostateczną specyfikacją żyroskopu.

Przed raportowaniem minimalnej wykrywalnej prędkości jako wyniku pracy należy zwiększyć liczbę realizacji co najmniej do 100-500 i zbadać zależność od czasu uśredniania.

## 7. Znaczenie dla BOM-u

Przy obecnych parametrach dominującym źródłem szumu jest photo-shot noise, a nie wzmacniacz.

Jeżeli rzeczywisty odbiornik będzie miał parametry zbliżone do nominalnych założeń v4, dalsze radykalne obniżanie `e_n` lub `i_n` wzmacniacza przyniesie ograniczoną poprawę bez zmiany mocy optycznej, pasma lub sposobu detekcji.

Ten wniosek należy ponownie sprawdzić po podstawieniu rzeczywistych kart katalogowych.

## Dane źródłowe

- `results/v4/FOG_v4_baseline.csv`
- `results/v4/FOG_v4_receiver_validation.csv`
- `results/v4/FOG_v4_noise_budget.csv`
- `results/v4/FOG_v4_monte_carlo_summary.csv`

Pierwsza nieudana próba:
- `docs/VALIDATION_V4_ATTEMPT1.md`
