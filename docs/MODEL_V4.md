# Model FOG v4 - fotodioda, TIA i szumy

## Cel

v4 przechodzi od idealnego fotoodbiornika do pierwszego modelu stochasticznego.

Architektura fizyczna v3 zostaje zachowana. Zmieniany jest głównie podsystem:

`Photoreceiver`.

Na poziomie głównym nadal widoczny jest jeden fizyczny blok odbiornika, natomiast po wejściu do środka znajdują się:

- fotodioda InGaAs,
- prąd ciemny,
- shot noise fotoprądu,
- shot noise prądu ciemnego,
- Johnson noise rezystora TIA,
- szum prądowy wzmacniacza,
- szum napięciowy wzmacniacza przeliczony na równoważny prąd,
- ograniczone pasmo TIA.

## Nominalne parametry v4

Są to **założenia modelowe**, a nie zatwierdzone parametry BOM-u.

| Parametr | Wartość |
|---|---:|
| Responsywność fotodiody | 0.9 A/W |
| Dark current | 5 nA |
| Rf TIA | 20 kOhm |
| Temperatura | 300 K |
| Pasmo TIA (-3 dB) | 200 kHz |
| OpAmp voltage noise | 4 nV/sqrtHz |
| OpAmp current noise | 2 fA/sqrtHz |
| f_mod | 20 kHz |
| krok solvera FAST | 0.20 us |

## Shot noise fotoprądu

Fotoprąd:

`I_photo(t) = R_pd P_detector(t)`

Jednostronna gęstość amplitudowa shot noise:

`i_photo_shot = sqrt(2 q I_photo)`

W modelu amplituda tego szumu zmienia się dynamicznie wraz z mocą optyczną.

## Shot noise dark current

`i_dark_shot = sqrt(2 q I_dark)`

Prąd ciemny jest również dodawany jako składowa DC fotodiody.

## Johnson noise

Rezystor sprzężenia TIA:

`i_R = sqrt(4 k T / R_f)`

jest modelowany jako równoważny szum prądowy na wejściu odbiornika.

## Szum wzmacniacza

v4 uwzględnia:

`i_n`

oraz napięciowy szum wejściowy:

`e_n`.

W tej wersji:

`i_en,eq = e_n / R_f`.

Jest to uproszczenie. Pełny noise gain zależny od pojemności fotodiody i wejścia wzmacniacza nie jest jeszcze modelowany.

## Generacja białego szumu

Dla jednostronnej ASD `S` i czasu próbkowania `Ts` próbki białego szumu mają odchylenie:

`sigma_sample = S / sqrt(2 Ts)`.

Dzięki temu po filtracji RMS odpowiada założonej gęstości widmowej.

## TIA

TIA nie jest już idealnym mnożeniem przez `R_f`.

v4 używa transmitancji pierwszego rzędu:

`H_TIA(s) = R_f omega_c / (s + omega_c)`

dla:

`f_c = 200 kHz`.

Model uwzględnia więc zarówno tłumienie, jak i przesunięcie fazowe przy częstotliwości modulacji.

## Kompensacja lock-in

Przesunięcie fazowe TIA przy `f_mod`:

`phi_TIA = atan(f_mod/f_TIA)`

jest kompensowane przez opóźnienie sygnału referencyjnego.

Normalizacja lock-in uwzględnia również:

`|H_TIA(j 2 pi f_mod)|`.

Dzięki temu dodanie ograniczonego pasma odbiornika nie powinno samo w sobie powodować biasu estymacji.

## Budżet szumów

Skrypt tworzy:

`FOG_v4_noise_budget.csv`

z następującymi składnikami:

- photo shot,
- dark-current shot,
- Rf Johnson,
- OpAmp current,
- OpAmp voltage equivalent,
- total RSS.

Dla każdego składnika zapisywane są:

- wejściowa ASD w pA/sqrtHz,
- RMS na wyjściu TIA,
- udział w całkowitej wariancji.

## Walidacja odbiornika

Skrypt wykonuje trzy poziomy testów.

### v4A - bez szumu

`noise_enable = 0`

Sprawdza, czy po dodaniu pasma TIA i kompensacji fazy wynik nadal odpowiada v3.

### v4B - RMS fotoodbiornika

Dla `Omega = 0` porównywane są:

- analityczny RMS szumu TIA,
- RMS zmierzony w Simulinku,
- średni fotoprąd teoria/symulacja.

### v4C - Monte Carlo

Pierwsza seria obejmuje:

- 0 deg/s
- 0.0001 deg/s
- 0.0005 deg/s
- 0.001 deg/s
- 0.005 deg/s
- 0.01 deg/s
- 0.1 deg/s
- 1 deg/s

Dla każdego punktu wykonywanych jest domyślnie 12 niezależnych realizacji.

Zapisywane są:

- średnia Omega,
- STD,
- bias,
- RMSE,
- prosty współczynnik `|Omega| / STD`.

Dla punktu zerowego wyznaczane są:

- `sigma_zero`,
- próg `1 sigma`,
- próg `3 sigma`.

Próg 3-sigma jest **metryką tej konkretnej symulacji i okna uśredniania**, a nie jeszcze pełną specyfikacją ARW/bias instability.

## Polityka numeryczna

Monte Carlo korzysta z trybu FAST:

`Ts = 0.20 us`

ponieważ v3.1 potwierdziło, że przy 20 kHz błąd numeryczny przy tym kroku jest bardzo mały względem celu v4.

Dokładniejsze wyniki referencyjne można później powtórzyć dla:

`Ts = 0.05 us`.

## Pliki wynikowe

Po poprawnym uruchomieniu:

- `FOG_v4.slx`
- `FOG_v4_noise_budget.csv`
- `FOG_v4_receiver_validation.csv`
- `FOG_v4_monte_carlo_raw.csv`
- `FOG_v4_monte_carlo_summary.csv`
- `FOG_v4_baseline.csv`

## Status

**Hotfix gotowy, wymagana ponowna walidacja lokalna.**

Pierwsza próba ujawniła techniczny błąd topologii: po przebudowie portów subsystemu Photoreceiver jego połączenia z Optical Front End i Lock-In DSP były wiszącymi liniami.

Skrypt został poprawiony i ma teraz jawne ponowne łączenie subsystemu oraz test topologii przed symulacją.

Pierwsze wyniki nie są traktowane jako wyniki fizyczne v4. Szczegóły:
`docs/VALIDATION_V4_ATTEMPT1.md`.
