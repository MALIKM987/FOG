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

Status: **rdzeń zweryfikowany; optymalizacja ADC wymaga v5.1**

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

Walidacja v5:
- 14 bit: sigma około 1.16x analogowego v4.1,
- 16 bit: sigma około 1.07x analogowego v4.1 w bieżącym Monte Carlo,
- 12 bit: około 1.73x,
- 1 MS/s daje 50 próbek/okres i około -50 dB tłumienia TIA+AAF przy Nyquiście,
- 100 kS/s jest nieakceptowalne,
- 2 MS/s ujawniło niemonotoniczny bias do dalszego badania.

v5.1 powinno zbadać dither/koherentną kwantyzację, fazę zegara, fs pod szumem i dobór AAF. Decymacja wyjściowa pozostaje częścią tej optymalizacji.

## v5.1 — optymalizacja ADC / zegara / AAF

Status: **zweryfikowany**

Cel:

- Monte Carlo detekcji `0.0001 deg/s` dla 12/14/16 bit,
- sweep fazy zegara ADC względem modulacji,
- Monte Carlo dla 500 kS/s, 1 MS/s i 2 MS/s,
- sweep AAF 80/100/150 kHz,
- określenie minimalnych praktycznych parametrów ADC przed doborem BOM-u.

Wynik roboczy:
- minimum 14 bit, preferowane 16 bit,
- nominalnie 1 MS/s,
- AAF 100 kHz jako roboczy kandydat,
- 500 kS/s pozostaje możliwym wariantem optymalizacyjnym,
- 2 MS/s ma otwarty deterministyczny bias i nie daje obecnie wystarczającej korzyści.

Decymacja i paired Monte Carlo pozostają zadaniami optymalizacyjnymi, ale nie blokują przejścia do v6.

## v6 — SMF, polaryzacja i depolaryzator

Status: **zweryfikowany model wrażliwościowy; nominalne r=0.1 nie spełnia celu 3-sigma**

Dodano:

- 1 km zwykłego włókna jednomodowego jako cewkę nie-PM,
- Jones-equivalent model względnego stanu CW/CCW,
- dynamiczne parametry theta i delta,
- skończony extinction ratio polaryzatora,
- efektywną widzialność zależną od polaryzacji,
- polarization phase bias,
- fenomenologiczny parametr skuteczności depolaryzatora,
- sweep depol_residual 1.0 -> 0,
- Monte Carlo losowych stanów SMF,
- ponowny test detekcji 0.0001 deg/s,
- logowanie V_pol(t) i phi_pol(t).

Roboczy tor cyfrowy v6 używa 16 bit / 1 MS/s / AAF 100 kHz.

Ważne: v6 jest modelem wrażliwościowym. `depol_residual` i `pol_nr_scale` nie są jeszcze parametrami konkretnego elementu BOM i wymagają późniejszej kalibracji eksperymentalnej.

Walidacja:
- bez tłumienia wpływu polaryzacji zero-rate sigma ≈ 0.862 deg/h,
- residual 0.1 -> ≈ 0.146 deg/h w Monte Carlo losowych stanów,
- residual 0.05 -> ≈ 0.0865 deg/h,
- detection dla 0.0001 deg/s przy residual 0.1 daje tylko ≈ 2.42 sigma.

Wniosek: standardowe SMF pozostaje możliwe, ale wymagana skuteczniejsza kontrola/depolaryzacja niż nominalne r=0.1 w obecnym modelu.

## v6.1 — próg wymaganej kontroli polaryzacji

Status: **zweryfikowany**

Dodano:
- detection sweep residual: 0.10, 0.075, 0.05, 0.025, 0,
- paired Monte Carlo z tymi samymi stanami SMF i seedami,
- osobne robust class separation i paired delta,
- wyznaczenie największego testowanego residual dla 3-sigma i 4-sigma,
- pomocniczą interpolację progu 3-sigma i 4-sigma,
- sweep pol_nr_scale od 0 do 8e-4,
- generowanie roboczego wymagania do FOG_v6_1_requirement.csv.

Walidacja v6.1:
- residual 0.05 daje punktowo 3.24 sigma,
- residual 0.025 daje 3.72 sigma,
- interpolowany próg 3 sigma = 0.0614,
- interpolowany próg 4 sigma = 0.0162,
- bootstrap wskazuje 0.025 jako bezpieczniejszy punkt dla wymagania 3-sigma,
- pol_nr_scale >= 4e-4 wyraźnie pogarsza wynik przy residual 0.05.

Fenomenologiczny residual nadal nie jest parametrem katalogowym.

## v6.2 — fizyczny model depolaryzatora Lyota pod BOM

Status: **zweryfikowany; wygenerowano pierwsze wymagania BOM z symulacji**

Dodano:
- model widma Gaussa SLD,
- Jones propagation przez dwie sekcje PM,
- spectral-averaged Stokes i worst-case DOP,
- beat length jako parametr materiałowy,
- długości sekcji L1/L2 i ratio 1:2,
- błąd spawu osi wokół 45 stopni,
- sweep minimalnej L1 vs bandwidth,
- konserwatywny guard dla efektywnego komponentu 8 nm,
- benchmark aktualnych klas SLD 1550 nm,
- benchmark PM1550 class z beat length <=5 mm,
- mapowanie worst-case DOP -> depol_residual proxy,
- automatyczne wymagania zakupowe do BOM-u,
- opcjonalną ponowną walidację wybranego projektu w FOG_v6.

Walidacja:
- dla guard 8 nm minimum bezpiecznego L1 wynosi około 1.05 m,
- 1.2 m + 2.4 m przechodzi proxy 2.5%,
- wariant konserwatywny 1.7 m + 3.4 m daje residual proxy ~0.01745,
- wybrany wariant pozostaje bezpieczny do efektywnego bandwidth około 5 nm,
- modelowy limit spawu dla proxy 2.5% to około +/-0.7 deg; cel procesu +/-0.5 deg,
- pełny FOG z tym proxy daje 3.48 sigma dla 0.0001 deg/s.

Roboczy BOM depolaryzatora:
- około 6 m PM1550 PANDA, beat length <=5 mm @1550 nm,
- sekcje 1.7 m i 3.4 m,
- spaw osi 45 deg +/-0.5 deg,
- polarizer ER >=25 dB,
- przed zakupem źródła należy zmierzyć realne widmo i moc dostępnego SLD.

Od v6.2 każdy etap generuje również wymagania materiałowe, tolerancje i pomiary przedzakupowe, nie tylko wynik matematyczny.

## v6.3 — optical BOM lock

Status: **zweryfikowany; roboczy optical BOM i acceptance plan zamknięte**

Cel:

- zamknąć wymagania materiałowe części optycznej,
- rozdzielić elementy LAB VERIFY / BUY / FABRICATE / CONDITIONAL,
- policzyć wymagany zakres fazy PZT i wymagania drivera,
- ustalić dopuszczalną moc źródła i ewentualne tłumienie,
- zablokować klasę sprzęgaczy K1/K2,
- zablokować ER/IL polaryzatora,
- zaprojektować geometrię 1 km cewki SMF,
- wygenerować laboratoryjny plan testów odbiorczych,
- wygenerować finalny roboczy procurement CSV.

Robocze założenia po v6.2:
- Lyot: 1.7 m + 3.4 m PM1550, około 6 m do zakupu,
- PM beat length <=5 mm @1550 nm,
- spaw 45 deg +/-0.5 deg,
- polarizer minimum 25 dB ER, preferowane >=30 dB,
- source target 0.8-1.0 mW at K1,
- PZT: beta=1.84 @20 kHz, phi0≈3.04 rad, preferowane Vpi<=20 V,
- driver: preferowane >=50 Vpp i >=30 kHz,
- coil: 1000 m G.652.D/SMF-28 class, geometria ok. 160 mm średnicy efektywnej.

Walidacja v6.3:
- PZT wymaga 1.9337 pi p-p; dla Vpi=20 V około 38.7 Vpp,
- target źródła 0.8-1.0 mW, maksimum około 1.10 mW dla 10% headroom,
- coupler 45/55 daje tylko około 0.044 dB penalty,
- polarizer minimum 25 dB ER, preferowane >=30 dB,
- 1 km cewki na 155 mm core / 30 mm window daje 18 warstw, ~1997 zwojów i mean diameter ~159.395 mm,
- wygenerowano optical BOM lock, procurement plan i lab acceptance tests.

Element dostępny w laboratorium nie jest automatycznie zaakceptowany. Musi przejść test odbiorczy z FOG_v6_3_lab_acceptance_tests.csv.

Procurement hotfix: lista obejmuje teraz także CONDITIONAL BUY, BUILD / VERIFY, BUY AS NEEDED i PROCESS / CONSUMABLES, a nie tylko pozycje BUY / ORGANIZE.

Przed v7 priorytetem operacyjnym jest audyt laboratoryjnego źródła, sprzęgaczy i fotodiody. Materiał coil former zostaje celowo otwarty do modelu termicznego.

## v7 — temperatura, Shupe i thermal BOM

Status: **zweryfikowany; thermal BOM provisional**

Dodano:
- uniform-temperature scale-factor model,
- zmiany D(T), L(T), ng(T), tau(T) i beta(T),
- pure Shupe model po rzeczywistych 18 warstwach cewki v6.3,
- porównanie sequential winding i symmetric/QAD proxy,
- sweep ramp 1 / 5 C/min,
- sweep thermal enclosure tau = 15 / 30 / 60 / 120 s,
- screening formera: Al6061, Invar36, G10-FR4, POM-C i fused-silica benchmark,
- CTE-mismatch stress-risk proxy,
- Pt100 AA/A/B requirement check,
- dwuczujnikową kompensację inner/outer,
- sensor noise/sample-rate Monte Carlo,
- thermal BOM,
- thermal acceptance-test plan.

Jawne kryteria robocze:
- thermal error budget = 0.12 deg/h,
- winding asymmetry proxy = 2%,
- CTE mismatch proxy <=5 ppm/K,
- minimum Pt100 Class A, preferred AA,
- thermal enclosure target tau_outer >=60 s,
- sensor readout noise target <=0.01 C RMS po filtracji.

Walidacja:
- Invar36 jako jedyny przechodzi obecny combined screening,
- uniform scale coefficient ~1.859 ppm/K,
- Invar QAD2% @1 C/min, tau60 = ~0.0564 deg/h,
- dla 5 C/min i 2% asymetrii potrzebna jest aktywna kompensacja,
- bez kompensacji 5 C/min wymagane <=0.85% asymetrii przy tau60 lub <=1.64% przy tau120,
- dwuczujnikowa kompensacja przechodzi dla filtered sensor noise <=0.01 C RMS; preferred <=0.005 C,
- około 1 Hz sampling jest wystarczający,
- thermal enclosure tau >=60 s z aktywną kompensacją.

Ważne: Invar36 pozostaje provisional, ponieważ v7 nie obejmuje pełnego thermo-mechanical stress effect.

## v7.1 — thermo-mechanical stress / winding / potting gate

Status: **implementacja gotowa, oczekuje na lokalną walidację**

Dodano:
- jawny Mohr/T-dot stress term oddzielony od pure Shupe,
- effective strain-transfer sweep zamiast arbitralnego wyboru kleju,
- paired stress mismatch sweep,
- wymagany max strain transfer dla każdego formera,
- Invar fixation scenarios,
- bonded-environment CTE sweep,
- winding tension 5-20 g z przeliczeniem na stress/microstrain,
- procesowy target 5-10 g i dynamic variation <=+/-0.5 g,
- bezpośredni acceptance coefficient K_Tdot,
- thermo-mechanical BOM,
- potting decision gate.

Budżet projektowy:
- total thermal = 0.12 deg/h,
- stress sub-budget = 0.06 deg/h,
- acceptance at 5 C/min: |K_Tdot| <=0.012 deg/h/(C/min).

Ważne:
- strain_transfer jest parametrem efektywnym i musi zostać skalibrowany,
- v7.1 celowo nie zamyka konkretnego kleju przed pomiarem,
- po v7.1 dalsze modele termo-mechaniczne bez danych z prototypu mają malejącą wartość.

### Gate po v7.1

Po lokalnej walidacji v7.1 priorytet przechodzi z symulacji na prototyp:
- audyt lab source/K1/K2/photodiode,
- zakup PZT, polarizer, PM fiber, SMF,
- wykonanie Lyota i cewki,
- thermal-ramp calibration.

Dopiero dane z pierwszego prototypu mają wrócić do modelu i zamknąć finalny former/potting.

## v8 — closed-loop

Status: **wartościowy, ale nie blokuje pierwszego POC**

Dodać:
- sprzężenie zwrotne,
- fazę kompensującą Sagnaca,
- regulator,
- estymację prędkości z sygnału kompensacji,
- porównanie open-loop vs closed-loop.

Decyzja projektowa:
v8 ma sens po uruchomieniu toru optycznego open-loop i pomiarze realnego PZT/ADC, ponieważ wtedy parametry regulatora i zakres kompensacji będą oparte na rzeczywistym sprzęcie. Nie należy opóźniać zakupów i pierwszego prototypu tylko po to, aby rozbudowywać symulator.

## Zasada pracy z repozytorium

Dla każdej wersji zachowujemy:

1. skrypt generujący model,
2. parametry wejściowe,
3. wynikową tabelę CSV,
4. opis założeń i ograniczeń,
5. wykresy i raport walidacyjny,
6. informację, jakie zjawisko dodano względem poprzedniej wersji.

Pliki `.slx` są generowane ze skryptu. Kod źródłowy pozostaje podstawowym źródłem prawdy.
