# FOG v5.1 - próba 1

## Status

Pierwszy etap `v5.1A` zakończył się poprawnie. `v5.1B` został przerwany przez ograniczenie Simulinka dotyczące sample-time offset przy fixed-step solverze.

## Wyniki v5.1A

Dla `Omega = 0.0001 deg/s`, `f_s = 1 MS/s`, `Tavg = 10 ms`:

| ADC | zero 3-sigma [deg/h] | signal mean [deg/s] | bias [deg/s] | separation [sigma] |
|---:|---:|---:|---:|---:|
| 12 bit | 0.2510 | 7.3913e-5 | -2.6087e-5 | 3.150 |
| 14 bit | 0.2095 | 9.0145e-5 | -9.8549e-6 | 4.077 |
| 16 bit | 0.2946 | 1.0492e-4 | +4.9172e-6 | 4.623 |

Interpretacja:

- 12 bit przekracza 3-sigma tylko nieznacznie i ma duży ujemny bias amplitudy,
- 14 bit daje wyraźną separację ponad 4 sigma,
- 16 bit daje największą separację około 4.62 sigma,
- różnice sigma między 14 i 16 bit przy tylko 30 realizacjach nie są wystarczające do wniosku, że 14 bit ma niższy rzeczywisty szum.

Wniosek roboczy: 14 bit pozostaje minimalnym sensownym kandydatem, 16 bit wariantem preferowanym.

## Przyczyna przerwania v5.1B

Skrypt używał faz:

`0, 0.125, ..., 0.875 Ts_ADC`

przy:

`Ts_solver = 0.05 us`.

Dla `f_s = 1 MS/s` offset `0.125 Ts_ADC = 125 ns`, który nie jest całkowitą wielokrotnością kroku solvera `50 ns`.

Simulink wymaga, aby offset dyskretnego sample time był zgodny z fixed-step siatką czasu.

## Hotfix

Sweep fazy zmieniono na:

`0, 0.1, ..., 0.9 Ts_ADC`.

Dla:

- 500 kS/s daje to krok offsetu 200 ns,
- 1 MS/s daje 100 ns,
- 2 MS/s daje 50 ns.

Wszystkie są całkowitymi wielokrotnościami kroku solvera 50 ns.

Dodano również jawny test wyrównania offsetu do siatki solvera.

## Resume

Poprawiony skrypt wykrywa istniejący plik:

`FOG_v5_1_detection_vs_bits.csv`

i wczytuje wyniki v5.1A zamiast powtarzać kosztowne 180 symulacji.

Po ponownym uruchomieniu powinien więc przejść bezpośrednio do v5.1B.
