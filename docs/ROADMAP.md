# Roadmap symulatora FOG

## Założenie

Model rozwijamy warstwowo. Każda wersja dodaje jedno istotne zjawisko fizyczne albo element toru pomiarowego. Dzięki temu można osobno zweryfikować wpływ kolejnych uproszczeń oraz wykorzystać historię rozwoju jako materiał do pracy magisterskiej.

## v1 — model deterministyczny

Status: **działa**

Zakres:

- prędkość kątowa `Omega`,
- faza Sagnaca,
- sinusoidalna modulacja różnicowej fazy,
- interferencja,
- moc optyczna,
- fotodioda,
- TIA,
- demodulacja synchroniczna,
- filtr dolnoprzepustowy,
- estymacja liniowa,
- korekcja `asin`,
- automatyczne testy od -20 do +20 deg/s.

Najważniejszy wynik: estymacja liniowa traci dokładność dla większych prędkości, natomiast korekcja `asin` odtwarza wejście z małym błędem numerycznym.

## v2 — fizyczny PZT i opóźnienie CW/CCW

Cel: usunąć największe uproszczenie v1.

Zamiast zadawać bezpośrednio gotową różnicową modulację

`Delta_phi_m(t) = beta sin(2 pi f_m t)`

modelujemy rzeczywistą modulację jednego przejścia

`phi_m(t) = phi_0 sin(2 pi f_m t)`

oraz różnicę widzianą przez fale przeciwbieżne

`Delta_phi_m(t) = phi_m(t) - phi_m(t - tau)`.

Zakres badań:

- zależność skuteczności modulacji od `f_m`,
- walidacja `beta = 2 phi_0 |sin(pi f_m tau)|`,
- testy dla 5, 10, 20, 50, 102 i 150 kHz,
- porównanie z częstotliwością `f_opt = 1/(2 tau)`,
- wpływ parametrów cewki na `tau` i `f_opt`.

## v3 — bilans mocy i straty optyczne

Dodać:

- dwa sprzęgacze 2x2,
- nierówny podział mocy,
- insertion loss,
- attenuation cewki,
- straty spawów i złączy,
- visibility interferencji,
- parametry źródła.

Wynik: rzeczywisty poziom mocy na fotodiodzie i margines dynamiczny.

## v4 — szumy fotodetektora i elektroniki

Dodać:

- shot noise,
- thermal noise,
- dark current,
- szum TIA,
- ograniczone pasmo odbiornika,
- SNR.

Wynik: rozdzielczość i szum wskazania.

## v5 — tor cyfrowy

Dodać:

- ADC,
- sampling,
- anti-aliasing,
- kwantyzację,
- skończoną rozdzielczość,
- cyfrową demodulację synchroniczną,
- filtrację i decymację.

## v6 — SMF, polaryzacja i depolaryzator

Dodać model:

- zwykłego włókna jednomodowego,
- zmian stanu polaryzacji,
- polaryzatora,
- depolaryzatora Lyota,
- kontrastu interferencji zależnego od polaryzacji.

To jest kluczowe dla oceny wariantu prototypu opartego na tanim włóknie SMF.

## v7 — temperatura i dryft

Dodać:

- zmianę współczynnika załamania,
- rozszerzalność cewki,
- asymetrię termiczną,
- dryft wskazania,
- zapis temperatury,
- model kompensacji.

## v8 — closed-loop

Dodać:

- sprzężenie zwrotne,
- fazę kompensującą Sagnaca,
- regulator,
- estymację prędkości z sygnału kompensacji,
- porównanie open-loop vs closed-loop.

## Zasada pracy z repozytorium

Dla każdej wersji zachowujemy:

1. skrypt generujący model,
2. parametry wejściowe,
3. wynikową tabelę CSV,
4. opis założeń i ograniczeń,
5. wykresy i raport walidacyjny,
6. informację, jakie zjawisko dodano względem poprzedniej wersji.

Pliki `.slx` mogą być generowane ze skryptu, aby kod źródłowy pozostawał podstawowym źródłem prawdy.
