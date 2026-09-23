# Roadmap symulatora FOG

## Założenie

Model rozwijamy warstwowo. Każda wersja dodaje jedno istotne zjawisko fizyczne albo element toru pomiarowego. Dzięki temu można osobno zweryfikować wpływ kolejnych uproszczeń oraz wykorzystać historię rozwoju jako materiał do pracy magisterskiej.

## v1 — model deterministyczny

Status: **zweryfikowany**

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

## v2 — fizyczny PZT i opóźnienie CW/CCW

Status: **zweryfikowany rdzeń fizyczny**

Modeluje:

- `phi_m(t)`,
- opóźnienie `tau`,
- `phi_m(t-tau)`,
- `Delta_phi_m(t)`,
- zależność `beta = 2 phi0 |sin(pi f_m tau)|`,
- sweep 5-150 kHz,
- wymaganą amplitudę PZT dla zadanego beta,
- wpływ `J1(beta)` na demodulację.

Walidacja punktu bazowego 20 kHz wykazała względny błąd beta około `-0.0059%`.

Uwaga: punkt 5 kHz ujawnił ograniczenie aktualnego filtru lock-in i krótkiego okna uśredniania. Nie podważa to modelu opóźnienia, ale należy je poprawić przed badaniem niskich częstotliwości modulacji.

## v3 — bilans mocy i straty optyczne

Status: **następny etap**

Dodać:

- źródło o jawnie zadanej mocy,
- sprzęgacz wejściowy K1,
- sprzęgacz pętli K2,
- rzeczywiste współczynniki podziału,
- insertion loss,
- tłumienie cewki w dB/km,
- straty spawów,
- straty złączy,
- polaryzator/depolaryzator jako pozycje stratne,
- modulator jako element stratny,
- bilans mocy na fotodiodzie,
- margines względem nasycenia i minimalnej mocy odbiornika.

Wynik: model ma liczyć moc w każdym punkcie toru i porównać ją z poziomem na fotodiodzie.

## v4 — szumy fotodetektora i elektroniki

Dodać:

- shot noise,
- thermal noise,
- dark current,
- szum TIA,
- ograniczone pasmo odbiornika,
- SNR.

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

Dodać:

- zwykłe włókno jednomodowe,
- zmianę stanu polaryzacji,
- polaryzator,
- depolaryzator Lyota,
- kontrast interferencji zależny od polaryzacji.

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

Pliki `.slx` są generowane ze skryptu. Kod źródłowy pozostaje podstawowym źródłem prawdy.
