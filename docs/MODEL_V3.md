# Model FOG v3

## Cel

v3 łączy dwie rzeczy:

1. zachowuje zweryfikowaną fizykę v2.1,
2. przekształca model z ciągu drobnych bloków matematycznych w hierarchiczny model odpowiadający fizycznej budowie FOG.

Na poziomie głównym Simulinka widoczne są duże bloki:

- Optical Source,
- Optical Front End,
- Sagnac Interferometer,
- Photoreceiver,
- Lock-In DSP,
- Rotation Input,
- Omega Display.

Dwuklik na podsystem otwiera jego model matematyczny.

## Topologia fizyczna

```text
Optical Source
     |
     v
Optical Front End <-----------------------------+
K1 + connector + polarizer + depolarizer       |
     |                                          |
     v                                          |
Sagnac Interferometer                           |
K2 + 1000 m SMF + PZT --------------------------+
     |
     +-------- reference -------------------+
                                           |
Optical Front End -> Photoreceiver -> Lock-In DSP -> Omega
```

Ten układ jest celowo hierarchiczny. Poziom główny ma pokazywać urządzenie, a nie pojedyncze równania.

## Nominalne założenia strat v3

Wartości są na tym etapie parametrami symulacyjnymi, a nie zatwierdzonym BOM-em:

| Parametr | Wartość |
|---|---:|
| Moc źródła | 1.0 mW |
| K1 | 50:50 |
| Excess/insertion loss K1 | 0.20 dB / przejście |
| Wspólny connector | 0.20 dB / przejście |
| Polaryzator | 0.80 dB / przejście |
| Depolaryzator | 0.30 dB / przejście |
| K2 | 50:50 |
| Excess/insertion loss K2 | 0.20 dB / przejście |
| SMF | 0.20 dB/km |
| Długość cewki | 1 km |
| PZT insertion loss | 0.50 dB |
| Spawy pętli | 6 x 0.05 dB |

## Model mocy w pętli

Po mocy wejściowej do K2 skala wybranego portu powrotnego jest modelowana jako:

`K_sagnac_power = 2 r (1-r) eta_K2^2 eta_loop`

gdzie:

- `r` jest współczynnikiem podziału K2,
- `eta_K2` obejmuje stratę nadmiarową pojedynczego przejścia,
- `eta_loop` obejmuje cewkę, PZT i spawy.

Dla `r = 0.5` czynnik idealnego split/recombine daje `0.5`.

Sygnał na wyjściu interferometru ma postać:

`P_return(t) = P_scale [1 + V cos(Delta_phi_S + Delta_phi_m(t))]`

## Bilans mocy

Skrypt generuje szczegółową tabelę:

`FOG_v3_power_budget.csv`

obejmującą:

- moc po każdym etapie,
- stratę danego kroku,
- skumulowaną stratę względem źródła.

Dodatkowo generowany jest sweep mocy źródła:

`FOG_v3_source_power_sweep.csv`

dla:

- 0.5 mW,
- 1.0 mW,
- 2.0 mW,
- 3.0 mW.

Raportowane są:

- skala mocy przy fotodiodzie,
- średnia moc dla punktu bazowego,
- teoretyczny peak interferencji,
- informacja, czy peak mieści się w roboczym celu 100 uW.

Roboczy zakres 1-100 uW nie jest jeszcze parametrem konkretnego odbiornika. Ma jedynie wspierać dobór BOM-u.

## Walidacja dynamiczna

Model uruchamia przypadek:

`Omega = 1 deg/s`

i porównuje:

- wynik estymatora,
- STD Omega,
- analityczną średnią moc na fotodiodzie,
- średnią moc z Simulinka,
- minimum i maksimum mocy w oknie pomiarowym.

Średnia teoretyczna uwzględnia sinusoidalną modulację:

`P_avg = P_scale [1 + V J0(beta) cos(Delta_phi_S)]`.

## Pliki wynikowe

Po uruchomieniu:

- `FOG_v3.slx`
- `FOG_v3_power_budget.csv`
- `FOG_v3_source_power_sweep.csv`
- `FOG_v3_baseline.csv`

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Najważniejsze wyniki walidacji:

- `Omega = 1 deg/s -> 0.999985491 deg/s`,
- średnia moc detektora: teoria `59.748616 uW`, Simulink `59.750047 uW`,
- błąd teoria/symulacja mocy: `0.002395%`,
- teoretyczny peak przy źródle 1 mW: `90.769514 uW`.

Szczegóły: `docs/VALIDATION_V3.md`.
