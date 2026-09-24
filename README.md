# FOG

Repozytorium pracy magisterskiej dotyczącej **interferometrycznego żyroskopu światłowodowego (IFOG)** opartego na efekcie Sagnaca, z cyfrowym przetwarzaniem sygnału, analizą błędów, przygotowaniem BOM-u i modelem closed-loop.

## Aktualny stan

Środowisko:
- MATLAB R2023b Update 7
- Simulink R2023b
- Signal Processing Toolbox
- Control System Toolbox
- Optimization Toolbox
- Symbolic Math Toolbox

Rozwój modelu jest prowadzony warstwowo. Każda wersja dodaje jedno zjawisko fizyczne lub element toru pomiarowego, a następnie jest sprawdzana osobnym zestawem wyników.

Aktualnie zakończono i zapisano:
- v1-v5.1: Sagnac, PZT, lock-in, power budget, RX noise, ADC/DSP,
- v6-v6.3: standard SMF, polarization, Lyot depolarizer, optical BOM,
- v7: uniform thermal drift, Shupe i thermal BOM,
- v8: closed-loop feasibility / actuator / DAC,
- v8.1: integrated optical closed-loop.

v7.1 (thermo-mechanical stress / winding / potting gate) jest zaimplementowane i czeka na lokalne uruchomienie / kalibrację.

## Bazowa architektura POC

```text
SLD/ASE
  -> K1
  -> polarizer / Lyot
  -> K2
  -> 1 km SMF Sagnac loop + phase shifter
  -> K2 / K1 return
  -> InGaAs photodiode
  -> TIA
  -> anti-alias filter
  -> ADC
  -> digital lock-in
  -> open-loop estimate

closed-loop:
digital residual -> PI/NCO -> DAC/driver -> phase feedback actuator -> Sagnac
```

## Robocze parametry

| Parametr | Wartość robocza |
|---|---:|
| Długość fali | 1550 nm |
| Cewka | 1000 m standard SMF |
| Efektywna średnica modelu | ~159.4 mm |
| Modulacja | 20 kHz |
| beta | 1.84 rad |
| ADC | 16 bit / 1 MS/s |
| AAF | ~100 kHz |
| Digital LPF | 300 Hz |
| Lyot | 1.7 m + 3.4 m PM1550 |
| PM fiber purchase | ~6 m |
| Closed-loop PI | nominalnie 50 Hz |

## Najważniejsze wyniki

- v3: dla źródła 1 mW peak detector power ~90.8 uW.
- v4: modelowany RX noise ~47.7 uV RMS.
- v4.1: zero-rate sigma ~0.0549 deg/h przy 20 ms averaging.
- v5.1: 14 bit minimum praktyczne, 16 bit preferowane.
- v6.1: modelowy polarization residual ~0.05 daje >3 sigma punktowo; 0.025 jest bezpieczniejszym celem modelowym.
- v6.2: Lyot 1.7 m + 3.4 m daje residual proxy ~0.01745.
- v6.3: 1000 m SMF -> ~18 warstw, ~1997 zwojów, średnica efektywna ~159.395 mm.
- v7: Invar36 przechodzi obecny combined thermal screening.
- v8: low-Vpi long-range fiber PZT class przechodzi ideal reset feasibility dla +/-20 deg/s, high-Vpi class nie.
- v8.1: integrated optical closed-loop działa dla 1 i 20 deg/s; test 0.0001 deg/s daje ~6.42 sigma w konkretnym modelu / oknie 20 ms.

## Ważne ograniczenie

„Zweryfikowany model” oznacza zgodność implementacji z przyjętym modelem i testami numerycznymi. Nie oznacza jeszcze walidacji metrologicznej fizycznego żyroskopu.

Najważniejsze parametry wymagające pomiaru na hardware:
- realne widmo i moc SLD,
- realne K1/K2,
- realny photoreceiver,
- Vpi / phase range / capacitance / resonances PZT,
- reset glitch i driver current,
- thermo-mechanical stress, winding i potting,
- długookresowa stabilność biasu.

## Dokumentacja

- `docs/ROADMAP.md` — historia i status wszystkich wersji.
- `docs/PROJECT_SUMMARY_MODELS_AND_POC.md` — zbiorcze podsumowanie modeli, wyników i budowy POC.
- `docs/MODEL_*.md` — opis każdej wersji.
- `docs/VALIDATION_*.md` — wyniki walidacji.
- `results/` — tabele wynikowe CSV.
- `matlab/` — skrypty generujące modele.

## Zasada repozytorium

Skrypty MATLAB są podstawowym źródłem prawdy. Modele `.slx` mogą być generowane lokalnie ze skryptów. Pliki `.slxc` są cache Simulinka i pozostają ignorowane.

Dalszy rozwój po v8.1 powinien przede wszystkim wykorzystywać **zmierzone parametry pierwszego prototypu**.
