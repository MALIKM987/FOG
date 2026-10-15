# FOG v7 - temperatura, Shupe i thermal BOM

## Cel

v7 dodaje do projektu rzeczywisty problem termiczny cewki i równocześnie utrzymuje zasadę przyjętą od v6.2:

**symulacja ma kończyć się wymaganiem materiałowym, montażowym albo pomiarowym.**

v7 odpowiada na pytania:

- jak temperatura zmienia scale factor,
- jak duży może być czysty efekt Shupe,
- z jakiego materiału wykonać former,
- jak wolno może zmieniać się temperatura otoczenia bez kompensacji,
- czy potrzebna jest izolacja,
- ilu czujników temperatury potrzeba,
- jaka dokładność i szum toru temperatury są wymagane,
- jak przygotować thermal acceptance test.

## 1. Jednorodna temperatura

Dla każdego materiału formera model zmienia:

- średnicę cewki D(T),
- długość włókna L(T),
- group index ng(T),
- transit time tau(T),
- efektywną głębokość modulacji beta(T),
- współczynnik Sagnaca.

Scale factor uwzględnia więc jednocześnie geometrię i zmianę odpowiedzi lock-in przez J1(beta).

## 2. Właściwości krzemionki

Roboczo:

- dn/dT = 8.4e-6 1/K przy około 1550 nm,
- alpha_fiber = 0.55e-6 1/K.

Te wartości są benchmarkami do modelu termicznego. Po wykonaniu cewki scale-factor temperature coefficient będzie kalibrowany eksperymentalnie.

## 3. Czysty efekt Shupe

v7 implementuje:

`Omega_E = n/(D L) * (dn/dT + n alpha) * integral[dT/dt(l,t) (L-2l) dl]`

Całka jest liczona po rzeczywistych długościach 18 warstw cewki wynikających z v6.3.

Temperatura każdej warstwy jest reprezentowana uproszczonym radialnym modelem pierwszego rzędu.

To nie jest jeszcze FEM.

## 4. Winding symmetry

v7 raportuje dwa wyniki:

- sequential winding upper-bound proxy,
- symmetric / quadrupolar proxy z parametrem winding_asymmetry_fraction.

Nominalnie:

`winding_asymmetry_fraction = 0.02`.

To oznacza test modelowy 2% pozostałej asymetrii, a nie gwarantowaną skuteczność realnego QAD.

## 5. Materiały formera

Porównywane są:

- Al6061-T6,
- Invar36,
- G10-FR4,
- POM-C,
- fused silica jako benchmark.

Screening ocenia:

- CTE,
- różnicę CTE względem silica fiber,
- thermal diffusivity,
- uniform scale coefficient,
- wymaganą dokładność czujnika temperatury,
- Shupe proxy przy 1 C/min,
- wynik dla izolacji opisanej tau_outer = 60 s.

Stress-risk jest na tym etapie reprezentowany różnicą CTE. Pełny photoelastic / Mohr T-dot stress effect pozostaje poza v7.

## 6. Kryteria screeningowe

v7 stosuje jawne kryteria projektowe:

- thermal error budget = 1/3 sygnału 0.0001 deg/s, czyli 0.12 deg/h,
- CTE mismatch proxy <=5 ppm/K,
- Pt100 Class A powinien wystarczyć do uniform scale compensation przy 20 deg/s,
- QAD 2% Shupe proxy przy 1 C/min i tau_outer=60 s powinien pozostać <=0.12 deg/h.

Materiał przechodzący wszystkie trzy jest wybierany jako provisional former.

## 7. Izolacja termiczna

Model bada:

- tau_outer = 15, 30, 60, 120 s,
- ambient ramp = 1 i 5 C/min.

`tau_outer` jest parametrem całej obudowy / izolacji i ma zostać później zmierzony testem skokowym.

Nie jest bezpośrednio parametrem katalogowym konkretnej pianki.

## 8. Czujniki temperatury

v7 wykorzystuje dwa czujniki:

- INNER,
- OUTER.

Pierwszy reprezentuje wewnętrzną granicę termiczną formera, drugi zewnętrzną część cewki / obudowy.

Test kompensacji bada:

- sample period 0.5, 1, 2, 5 s,
- noise STD 0.005, 0.01, 0.03, 0.05 C,
- filtr termiczny 10 s,
- stress ramp 5 C/min.

Metryką jest P95 pozostałego thermal rate error.

## 9. Pt100 / Pt1000

Model sprawdza klasy IEC 60751:

- AA,
- A,
- B.

Dla 25 C:

- AA około +/-0.1425 C,
- A około +/-0.20 C,
- B około +/-0.425 C.

Do BOM-u roboczo:

- minimum Class A,
- preferowane Class AA,
- 4-wire preferred.

Dokładność absolutna jest potrzebna głównie do scale-factor correction.

Shupe compensation wymaga przede wszystkim niskiego szumu i stabilnego różnicowego pomiaru temperatury, dlatego tor readout ma osobne wymaganie noise <=0.01 C RMS po filtracji.

## 10. Thermal BOM

Skrypt generuje:

- provisional former material,
- wymaganie na thermal enclosure,
- dwa sensory temperatury,
- wymaganie na readout,
- wymaganie na winding symmetry,
- otwartą pozycję potting / adhesive,
- plan testu w komorze lub z kontrolowanym grzaniem.

## 11. Ważne ograniczenie

Pure Shupe nie jest jedynym termicznym błędem FOG.

Literatura wskazuje także efekt związany z niesymetrycznymi naprężeniami termicznymi i zmianą lokalnego współczynnika fazowego. Ten Mohr / T-dot stress term może być większy od czystego Shupe.

Dlatego:

- potting,
- klej,
- napięcie włókna,
- sposób mocowania do formera

nie są jeszcze zamykane w v7.

To będzie v7.1 po pomiarze i kalibracji pierwszej konstrukcji.

## 12. Pliki wynikowe

- FOG_v7_uniform_temperature_sweep.csv
- FOG_v7_shupe_transient_sweep.csv
- FOG_v7_former_material_screening.csv
- FOG_v7_temperature_sensor_sweep.csv
- FOG_v7_pt100_class_check.csv
- FOG_v7_thermal_bom.csv
- FOG_v7_thermal_acceptance_tests.csv

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Wynik:
- provisional former: Invar36,
- scale temperature coefficient: około 1.859 ppm/K,
- QAD2% Shupe @1 C/min, tau60: około 0.0564 deg/h,
- przy 5 C/min i 2% asymetrii nawet tau120 nie przechodzi bez kompensacji,
- two-sensor compensation przechodzi dla <=0.01 C RMS po filtracji,
- <=0.005 C RMS jest preferowanym celem,
- Pt100 Class B przechodzi sam uniform-scale model, ale Class A pozostaje minimum projektowym,
- potting / thermo-mechanical stress pozostaje do v7.1.

Szczegóły: `docs/VALIDATION_V7.md`.