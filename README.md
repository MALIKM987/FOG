# FOG

Repozytorium pracy magisterskiej dotyczącej **interferometrycznego żyroskopu światłowodowego (FOG)** opartego na efekcie Sagnaca, z cyfrowym przetwarzaniem sygnału i kompensacją błędów.

## Aktualny stan

Środowisko symulacyjne:

- MATLAB R2023b Update 7
- Simulink R2023b
- Signal Processing Toolbox
- Control System Toolbox
- Optimization Toolbox
- Symbolic Math Toolbox

Pierwszy model `FOG v1` został uruchomiony i zweryfikowany w Simulinku. Model obejmuje:

- przeliczenie prędkości kątowej na fazę Sagnaca,
- sinusoidalną modulację fazy,
- interferencję,
- model fotodiody i TIA,
- demodulację synchroniczną,
- estymację liniową oraz korekcję `asin`,
- automatyczne testy dla zakresu od -20 do +20 deg/s.

## Parametry bazowe v1

| Parametr | Wartość |
|---|---:|
| Długość fali | 1550 nm |
| Długość cewki | 1000 m |
| Średnia średnica cewki | 160 mm |
| Współczynnik grupowy | 1.4682 |
| Częstotliwość modulacji | 20 kHz |
| Amplituda różnicowej modulacji fazy | 1.84 rad |
| Responsywność fotodiody | 0.9 A/W |
| TIA | 20 kOhm |

Dla tej geometrii:

- `K_sag ≈ 2.16345 rad/(rad/s)`,
- `tau ≈ 4.897 us`,
- `f_opt ≈ 102.10 kHz`,
- dla `1 deg/s`: `Delta_phi_S ≈ 0.037759 rad`.

## Plan rozwoju symulacji

1. **v1** — model deterministyczny, lock-in i korekcja nieliniowości.
2. **v2** — fizyczny modulator PZT i opóźnienie propagacji CW/CCW.
3. **v3** — bilans mocy, straty sprzęgaczy i cewki.
4. **v4** — fotodioda, shot noise, TIA i szumy elektroniki.
5. **v5** — ADC, próbkowanie i kwantyzacja.
6. **v6** — zwykłe włókno SMF, polaryzacja i depolaryzator.
7. **v7** — temperatura, dryft i błędy systematyczne.
8. **v8** — kompensacja oraz wariant closed-loop.

## Cel projektu

Repozytorium ma być jednocześnie:

- kodem źródłowym symulatora,
- historią rozwoju modelu,
- zbiorem wyników i eksperymentów,
- technicznym zapleczem do pracy magisterskiej,
- punktem odniesienia przy budowie fizycznego prototypu FOG.
