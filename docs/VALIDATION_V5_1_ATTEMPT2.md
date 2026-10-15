# FOG v5.1 - próba 2

## Status

v5.1A i v5.1B zakończyły się poprawnie. v5.1C zostało przerwane przy `2 MS/s` przez niezgodność okresu próbkowania ADC z krokiem fixed-step solvera.

## Wyniki v5.1B - wpływ fazy zegara ADC

| fs [kS/s] | P2P błędu @ 1 deg/s | max |error| @ 1 deg/s | P2P błędu @ 1e-4 deg/s | max |error| @ 1e-4 deg/s |
|---:|---:|---:|---:|---:|
| 500 | 2.6883e-4 | 1.4986e-4 | 3.1088e-4 | 1.6064e-4 |
| 1000 | 1.5578e-4 | 1.3083e-4 | 1.3103e-4 | 7.2387e-5 |
| 2000 | 1.0371e-4 | 4.4079e-4 | 1.2609e-4 | 8.1039e-5 |

### Interpretacja

Faza zegara ADC ma mierzalny wpływ na bias.

Dla 500 kS/s zmiana fazy zegara powoduje największy peak-to-peak błąd.

Dla 1 MS/s zależność jest mniejsza.

Dla 2 MS/s peak-to-peak jest jeszcze mniejszy, ale występuje duży offset wspólny, ponieważ maksymalny błąd bezwzględny przy 1 deg/s wynosi około `4.41e-4 deg/s`.

To oznacza, że anomalia 2 MS/s z v5 nie jest wyłącznie efektem wyboru jednej fazy zegara. Istnieje składowa biasu wspólna dla faz, którą należy rozdzielić od modulacji fazowej.

## Przyczyna przerwania v5.1C

v5.1C używało:

`Ts_solver = 0.20 us`.

Dla `2 MS/s`:

`Ts_ADC = 0.50 us`

co daje:

`Ts_ADC / Ts_solver = 2.5`.

Simulink fixed-step wymaga całkowitej wielokrotności.

500 kS/s i 1 MS/s przeszły, ponieważ ich okresy próbkowania są wielokrotnościami 0.20 us.

## Hotfix

Dla v5.1C przyjęto:

`Ts_solver = 0.10 us`.

Wtedy:

- 500 kS/s: 20 kroków solvera na próbkę,
- 1 MS/s: 10 kroków,
- 2 MS/s: 5 kroków.

Dodano również jawny test zgodności `Ts_ADC / Ts_solver`.

## Resume

Skrypt po ponownym uruchomieniu:

- wczyta istniejące wyniki v5.1A,
- wczyta istniejące wyniki v5.1B,
- przejdzie bezpośrednio do v5.1C.

Nie ma potrzeby ponownego wykonywania wcześniejszych sweepów.
