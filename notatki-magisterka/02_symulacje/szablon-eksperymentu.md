# Szablon raportu z symulacji / eksperymentu

Skopiować jako: `EXP-YYYY-NNN-nazwa.md`. Nie nadpisywać poprzednich raportów; nowa konfiguracja = nowy eksperyment lub jawna rewizja.

## Metryka
- **Identyfikator:** EXP-YYYY-NNN
- **Data:** RRRR-MM-DD
- **Osoba / środowisko:** 
- **Typ:** SYMULACJA / POMIAR / OBLICZENIE
- **Status:** PLAN / WYKONANO / ZWERYFIKOWANO / ODRZUCONO
- **Cel / hipoteza:** 
- **Powiązane notatki i decyzje:** 
- **Commit SHA modelu:** 
- **Wersja MATLAB / Simulink i toolboksy:** 

## Model i założenia
- Schemat blokowy, port fotodiody i konwencje znaków:
- Równania:
- Ograniczenia (np. bez polaryzacji, szumów):
- Jakie parametry są mierzone, a jakie przyjęte hipotetycznie:

## Dane wejściowe
| Parametr | Wartość | Jednostka | Pochodzenie |
|---|---:|---|---|
| L | | m | |
| D | | m | |
| λ0 | | nm | |
| n_g | | 1 | |
| źródło | | LASER / ASE | |
| Δλ FWHM | | nm | |
| Ω | | deg/s | |
| f_m | | Hz | |
| φ0 | | rad | |
| seed losowy (gdy potrzebny) | | — | |

## Uruchomienie i pliki
- Polecenie uruchomienia:
- Nazwy plików skryptu/modelu:
- Dane surowe:
- Nazwy wykresów:
- Czas symulacji, solver i krok próbkowania:

## Wyniki
| Metryka | Przewidywanie | Wynik | Różnica | Komentarz |
|---|---:|---:|---:|---|
| K_S | | | | |
| τ | | | | |
| f_proper | | | | |
| S1(Ω) | | | | |
| Widzialność V | | | | |

## Ocena
- Czy hipoteza potwierdzona?
- Co wynika z modelu, a co jest arbitralnym wyborem?
- Możliwe błędy numeryczne i fizyczne:
- Jak odtworzyć wynik?
- Co należy sprawdzić pomiarem?
- Kandydat na rysunek/tabelę do pracy magisterskiej:

**Zasada publikacji:** wynik bez kodu, konfiguracji, wykresu i jednoznacznego powiązania z commitem oznaczamy jako niezweryfikowany.
