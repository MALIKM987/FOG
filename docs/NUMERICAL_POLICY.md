# Polityka numeryczna symulatora FOG

## Cel

Ten dokument określa domyślne ustawienia kroku solvera po walidacji v3.1.

## Domyślne tryby

### FAST

Zastosowanie:

- rozwój modelu,
- 20 kHz,
- duża liczba realizacji szumu,
- Monte Carlo,
- testy regresyjne.

Ustawienie:

`Ts = 0.20 us`

Dla 20 kHz błąd numeryczny Omega w teście v3.1 wyniósł około `1.67e-5 deg/s`.

### STANDARD

Zastosowanie:

- ogólne badania częstotliwości 20-150 kHz,
- generowanie wyników do analizy,
- standardowa walidacja nowych wersji modelu.

Ustawienie:

`Ts = 0.05 us`

W teście v3.1 maksymalny błąd Omega w zakresie do 150 kHz był mniejszy niż `0.001 deg/s`.

### REFERENCE

Zastosowanie:

- kontrola zbieżności,
- walidacja wyników wysokiej częstotliwości,
- przypadki wymagające wysokiej dokładności numerycznej.

Ustawienie:

`Ts = 0.02 us`

## Zasada

Jeżeli oczekiwany efekt fizyczny lub szum jest tego samego rzędu co błąd numeryczny dla danego trybu, należy przejść na dokładniejszy tryb i powtórzyć test.

## Źródło decyzji

`docs/VALIDATION_V3_1.md`
