# Model FOG v2.1

## Cel

v2.1 nie zmienia fizyki modelu v2. Jego zadaniem jest poprawienie toru demodulacji lock-in, ponieważ walidacja v2 ujawniła artefakt przy 5 kHz:

- `beta_theory` i `beta_sim` były praktycznie identyczne,
- mimo to estymacja `Omega` miała błąd około `+0.0757 deg/s`.

To wskazywało na ograniczenie filtru i krótkiego okna uśredniania, a nie na błąd modelu PZT + delay.

## Zmiany względem v2

1. Filtr lock-in:
   - było: filtr 1. rzędu,
   - jest: analogowy Butterworth 4. rzędu.

2. Częstotliwość graniczna pozostaje:
   - `fc = 300 Hz`.

3. Czas symulacji:
   - było: `20 ms`,
   - jest: `50 ms`.

4. Okno estymacji:
   - ostatnie `10 ms` symulacji.

5. Dodano:
   - `STD_Omega_deg_s`,
   - `LockIn_LPF_std`,
   - osobny wykres błędu Omega,
   - osobny wykres resztkowego tętnienia.

## Test akceptacyjny

Najważniejszy test v2.1 to punkt `5 kHz`.

W v2:

`Omega_measured ~= 1.0757 deg/s`

dla zadanego:

`Omega = 1 deg/s`.

Po poprawie lock-in oczekujemy znaczącego spadku tego błędu przy zachowaniu zgodności:

`beta_sim ~= beta_theory`.

## Status

Implementacja gotowa. Oczekuje na lokalne uruchomienie i zapis rzeczywistych wyników do `results/v2_1/`.
