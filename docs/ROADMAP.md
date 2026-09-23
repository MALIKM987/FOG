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

Uwaga: punkt 5 kHz ujawnił ograniczenie filtru lock-in i krótkiego okna uśredniania. Zostało to poprawione i zweryfikowane w v2.1.

## v2.1 — poprawiony lock-in

Status: **zweryfikowany**

Zmiany:

- Butterworth 4. rzędu zamiast LPF 1. rzędu,
- wydłużenie symulacji do 50 ms,
- estymacja z ostatnich 10 ms,
- pomiar STD Omega i STD wyjścia lock-in.

Wynik testu 5 kHz:

- v2: błąd około +0.075665 deg/s,
- v2.1: błąd około -1.816e-6 deg/s,
- redukcja bezwzględnego błędu około 99.9976%.

Pozostały mały błąd średniej przy 50-150 kHz wymaga osobnego testu zbieżności numerycznej solvera i Transport Delay, ale nie blokuje przejścia do modelu strat optycznych.

## v3 — bilans mocy i straty optyczne

Status: **zweryfikowany**

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

Wynik: model liczy moc w każdym punkcie toru, porównuje analityczny i symulowany poziom na fotodiodzie oraz generuje sweep mocy źródła.

Walidacja dla źródła 1 mW: średnia moc teoria 59.748616 uW, Simulink 59.750047 uW, błąd 0.002395%; peak 90.7695 uW.

Dodatkowo v3 wprowadza hierarchiczny widok fizyczny urządzenia: Optical Source, Optical Front End, Sagnac Interferometer, Photoreceiver i Lock-In DSP. Szczegółowe równania są ukryte wewnątrz podsystemów.

## v3.1 — test zbieżności numerycznej

Status: **zweryfikowany**

Cel został osiągnięty:

- potwierdzono numeryczne źródło małego błędu przy 50-150 kHz,
- porównać kroki 0.20, 0.10, 0.05 i 0.02 us,
- zbadać wpływ dyskretyzacji na Transport Delay,
- wybrano politykę: FAST 0.20 us dla 20 kHz i Monte Carlo, STANDARD 0.05 us dla sweepów do 150 kHz, REFERENCE 0.02 us dla walidacji.

Test obejmuje 20, 50, około 102.095 i 150 kHz. Szczegóły w `docs/VALIDATION_V3_1.md` i `docs/NUMERICAL_POLICY.md`.

## v4 — szumy fotodetektora i elektroniki

Status: **zweryfikowany model szumowy; statystyka Monte Carlo wstępna**

Dodano:

- shot noise,
- thermal noise,
- dark current,
- szum TIA,
- ograniczone pasmo odbiornika,
- SNR,
- ograniczone pasmo TIA,
- kompensację fazy TIA w lock-in,
- Monte Carlo małych prędkości,
- estymację progu 1-sigma i 3-sigma dla zadanego okna pomiarowego.

Walidacja: RMS szumu teoria/Simulink zgadza się do około 0.005%; photo-shot noise stanowi około 95.2% wariancji. Wstępny zero-rate sigma = 2.53e-5 deg/s, a próg 3-sigma = 7.60e-5 deg/s dla obecnego 10 ms okna i 12 realizacji Monte Carlo.

Przed traktowaniem progu detekcji jako specyfikacji należy wykonać rozszerzone Monte Carlo i sweep czasu uśredniania.

## v4.1 — rozszerzona analiza statystyczna

Status: **zweryfikowany**

Cel:

- zwiększyć zero-rate Monte Carlo do 100 realizacji,
- zbadać `sigma_Omega(Tavg)` dla 1, 2, 5, 10 i 20 ms,
- sprawdzić skalowanie `1/sqrt(T)`,
- ustabilizować próg 1-sigma i 3-sigma,
- powtórzyć detekcję `0.0001 deg/s` dla 50 realizacji,
- porównać deterministyczny bias przy `Ts=0.20 us` i `0.05 us`.

Wynik: sigma przy 20 ms = 1.525e-5 deg/s (0.0549 deg/h), próg 3-sigma = 0.1647 deg/h. Punkt 0.0001 deg/s przy 10 ms ma separację około 4.83 sigma. Nachylenie sigma(Tavg) = -0.393, więc w zakresie 1-20 ms nie obserwujemy jeszcze idealnego prawa białego szumu -0.5.

## v5 — tor cyfrowy

Status: **implementacja gotowa, oczekuje na walidację lokalną**

Dodano:

- ADC,
- sampling,
- anti-aliasing,
- kwantyzację,
- skończoną rozdzielczość,
- cyfrową demodulację synchroniczną,
- filtrację cyfrową,
- anti-alias AFE,
- sample-and-hold,
- kwantyzację N-bit,
- cyfrową referencję lock-in,
- sweep 8-16 bit,
- sweep 100 kS/s - 2 MS/s,
- Monte Carlo 12/14/16 bit,
- porównanie szumu ADC z analogowym limitem v4.1.

Decymacja wyjściowa pozostaje do ewentualnego v5.1 po walidacji podstawowego toru ADC.

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
