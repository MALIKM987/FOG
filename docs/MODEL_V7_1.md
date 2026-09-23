# FOG v7.1 - thermo-mechanical stress, winding i potting gate

## Dlaczego v7.1

v7 pokazało, że czysty Shupe można ograniczyć symetrycznym uzwojeniem, izolacją i dwuczujnikową kompensacją. Nie zamykało jednak naprężeń termo-mechanicznych.

Literatura rozdziela dwa składniki błędu termicznego FOG:

1. pure Shupe: różnica T-dot pomiędzy punktami symetrycznymi,
2. Mohr / strain-induced T-dot: różnica lokalnego współczynnika fazowego/strain sensitivity pomiędzy punktami symetrycznymi, mnożona przez średnie T-dot.

v7.1 implementuje drugi składnik jako model wrażliwościowy i zamienia go na wymagania produkcyjne.

## Model

Dla jednorodnego T-dot i stałej różnicy współczynnika pomiędzy parą symetryczną użyto redukcji:

`Omega_M = ng L/(4D) * Delta(nS) * Tdot`

oraz:

`Delta(nS) = n_eff (1-p_e) * mismatch * eta * (alpha_structure-alpha_fiber)`

gdzie:

- `eta` to efektywny transfer odkształcenia 0...1,
- `mismatch` to niedopasowanie naprężeniowe pary symetrycznej,
- `alpha_structure-alpha_fiber` to mismatch CTE,
- `p_e` to efektywny współczynnik strain-optic.

### Krytyczne ograniczenie

`eta` nie jest bezpośrednio modułem Younga ani parametrem katalogowym kleju. Jest parametrem konstrukcji obejmującym coating, kontakt, klej, grubość warstwy, bonded fraction i możliwość poślizgu.

Dlatego v7.1 nie wybiera konkretnego epoksydu na podstawie datasheetu. Wyznacza dopuszczalne `eta` i wymaga jego kalibracji przez thermal-ramp test.

## Budżet

Z v7:

- całkowity thermal budget = 0.12 deg/h.

v7.1 dzieli go projektowo:

- około 0.06 deg/h na residual pure-Shupe / compensation,
- około 0.06 deg/h na thermo-mechanical T-dot.

Dla testu 5 C/min daje to wymaganie konstrukcyjne:

`|K_Tdot| <= 0.012 deg/h per (C/min)`.

To jest bezpośrednio mierzalne w laboratorium.

## Materiały formera

Ponownie porównywane są:

- Al6061-T6,
- Invar36,
- G10-FR4,
- POM-C,
- fused silica benchmark.

v7.1 nie używa samego CTE jako werdyktu. Dla każdego materiału wyznacza:

- maksymalny dopuszczalny effective strain transfer przy 2% pair mismatch i 5 C/min,
- maksymalny pair mismatch przy eta=0.05 i eta=0.10.

To pokazuje, jak bardzo konstrukcja musi odsprzęgać strain od włókna.

## Scenariusze mocowania

Testowane są scenariusze effective strain transfer:

- 0.02 minimal/slip-like,
- 0.05 compliant sparse,
- 0.10 moderate bonded,
- 0.30 strong bonded,
- 0.70 rigid transfer.

Te nazwy są scenariuszami modelowymi. Nie są przypisane 1:1 do konkretnych klejów.

## Winding tension

v7.1 dodaje fizyczny proces nawoju.

Testowane napięcie:

- 5 g,
- 7.5 g,
- 10 g,
- 15 g,
- 20 g.

Skrypt przelicza je na force, axial stress i microstrain dla 125 um silica glass.

Do procesu roboczo:

- 5-10 g setpoint,
- dynamic variation <= +/-0.5 g preferred,
- tension logging przez pełne 1000 m.

To odpowiada klasie precyzyjnych procesów winding opisywanych przez dostawców i systemy automatyczne, ale konkretne optimum dla naszego SMF musi zostać sprawdzone eksperymentalnie.

## Potting

v7.1 celowo **nie zamyka pełnego pottingu**.

Powód:

- literatura pokazuje silny wpływ własności kleju i stress distribution na thermal drift,
- mismatch coating/adhesive może generować hoop stress i bias spikes przy mikrorozwarstwieniu,
- pełne sztywne zalanie może poprawić mechanikę, ale pogorszyć thermo-mechanical T-dot.

Pierwszy prototyp powinien więc preferować minimalne / symetryczne / compliant fixation, a potting ma przejść osobny gate pomiarowy.

## Acceptance gate

Po zbudowaniu couponu lub cewki mierzymy:

- zero-rate podczas +5 C/min,
- zero-rate podczas chłodzenia,
- dwa RTD,
- pure-Shupe component z modelu v7,
- residual po jego odjęciu.

Z residual fitujemy:

`K_Tdot [deg/h per (C/min)]`.

PASS:

`|K_Tdot| <= 0.012 deg/h/(C/min)`.

Jeśli warunek nie jest spełniony, zmieniamy former / fixation / winding symmetry zanim zamkniemy klej.

## Opcjonalna zaawansowana walidacja

Jeśli laboratorium ma dostęp do Rayleigh-OFDR lub podobnego pomiaru rozłożonych odkształceń, można bezpośrednio zmierzyć strain-versus-temperature wzdłuż cewki i zastąpić `eta` rzeczywistym profilem.

To byłoby znacznie silniejsze naukowo niż dalsze arbitralne dopracowywanie modelu.

## Wyniki skryptu

- FOG_v7_1_mohr_stress_sweep.csv
- FOG_v7_1_former_stress_requirement.csv
- FOG_v7_1_invar_fixation_scenarios.csv
- FOG_v7_1_bonded_CTE_sweep.csv
- FOG_v7_1_winding_tension.csv
- FOG_v7_1_thermomechanical_bom.csv
- FOG_v7_1_acceptance_tests.csv

## Kryterium zakończenia

v7.1 można zakończyć jako etap symulacyjny po lokalnym uruchomieniu i interpretacji sweepów.

Finalny potting i finalny former mogą być zamknięte dopiero po pierwszym thermal-ramp measurement, ponieważ bez pomiaru dalsze zwiększanie złożoności modelu ma malejącą wartość.

## Status

Implementacja gotowa do lokalnej walidacji.