# FOG v3.1 - test zbieżności numerycznej

## Cel

v3.1 nie zmienia fizyki modelu v3. Jest kontrolą jakości numerycznej.

W v2.1/v3 przy wysokich częstotliwościach modulacji pozostał mały błąd średniej Omega mimo bardzo małego tętnienia. Jednocześnie rosła różnica między beta z teorii i z symulacji. Hipoteza robocza: głównym źródłem jest krok solvera oraz interpolacja bloku Transport Delay.

## Test

Częstotliwości:

- 20 kHz
- 50 kHz
- f_opt około 102.095 kHz
- 150 kHz

Kroki solvera:

- 0.20 us
- 0.10 us
- 0.05 us
- 0.02 us

Łącznie 16 symulacji.

## Mierzone wielkości

Dla każdej kombinacji zapisywane są:

- liczba kroków na okres modulacji,
- tau/Ts,
- część ułamkowa opóźnienia względem siatki solvera,
- beta z teorii,
- beta z Simulinka,
- błąd beta w radianach i procentach,
- średnia estymowana Omega,
- błąd Omega,
- STD Omega,
- czas wykonania symulacji.

## Model

Skrypt kopiuje zweryfikowany `FOG_v3.slx` do `FOG_v3_1.slx`. Nie modyfikuje oryginalnego modelu v3.

Do kopii dodawany jest jedynie logger sygnału `Delta phi mod`, potrzebny do bezpośredniego pomiaru beta.

## Kryterium interpretacji

Jeżeli wraz ze zmniejszaniem `Ts` maleją:

- `|beta_sim - beta_theory|`
- oraz `|Omega_est - Omega_input|`

to potwierdzamy, że obserwowany błąd wysokich częstotliwości jest głównie artefaktem numerycznym.

Nie zakładamy z góry, że najmniejszy krok będzie krokiem docelowym. Po walidacji wybieramy kompromis między czasem symulacji a błędem.

## Pliki wynikowe

- `FOG_v3_1_convergence.csv`
- `FOG_v3_1_summary.csv`
- `FOG_v3_1.slx`

## Status

Implementacja gotowa do uruchomienia lokalnego.
