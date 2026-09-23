# Walidacja FOG v6.2 - fizyczny depolaryzator Lyota pod BOM

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v6.2 poprawnie przełożyło wcześniejszy fenomenologiczny próg polaryzacyjny na wymagania dotyczące źródła, PM fiber, długości sekcji Lyota i dokładności spawu osi.

## 1. Długość depolaryzacyjna

Dla beat length 5 mm @1550 nm:

| efektywna szerokość widma | Ldp krótkiej sekcji |
|---:|---:|
| 8 nm | 0.9688 m |
| 30 nm | 0.2583 m |
| 45 nm | 0.1722 m |
| 85 nm | 0.0912 m |
| 100 nm | 0.0775 m |

Trend jest zgodny z oczekiwaniem: im szersze widmo, tym krótsza sekcja PM potrzebna do utraty koherencji między osiami.

## 2. Minimalna L1 dla progów z v6.1

Dla modelowego progu bezpiecznego 2.5%:

- 8 nm -> L1 około 1.05 m, L2 około 2.10 m,
- 10 nm -> 0.85 m / 1.70 m,
- 15 nm -> 0.60 m / 1.20 m,
- 30 nm -> 0.30 m / 0.60 m,
- 45-50 nm -> około 0.20 m / 0.40 m,
- 85-100 nm -> około 0.10 m / 0.20 m.

## 3. Konserwatywny guard 8 nm

| L1 / L2 | PM total | worst DOP proxy z tolerancją | wynik 2.5% |
|---:|---:|---:|---:|
| 0.5 / 1.0 m | 1.5 m | 0.4435 | FAIL |
| 1.0 / 2.0 m | 3.0 m | 0.03159 | FAIL |
| 1.2 / 2.4 m | 3.6 m | 0.01796 | PASS |
| 1.5 / 3.0 m | 4.5 m | 0.01745 | PASS |
| 1.7 / 3.4 m | 5.1 m | 0.01745 | PASS |

To pokazuje, że 1.2 m + 2.4 m jest już wystarczające dla założonego guard 8 nm i tolerancji montażowych.

Wybrany wariant 1.7 m + 3.4 m jest bardziej konserwatywny i daje dodatkowy margines przy nieznanym rzeczywistym widmie źródła.

## 4. Dominująca tolerancja: spaw 45 stopni

Dla wybranego wariantu 1.7 m + 3.4 m:

- maksymalny błąd osi dla progu 5%: około +/-1.4 deg,
- maksymalny błąd osi dla progu 2.5%: około +/-0.7 deg.

Projektowy cel +/-0.5 deg pozostawia rozsądny margines.

Po osiągnięciu wystarczającej dekoherencji widmowej dalsze zwiększanie długości PM nie poprawia znacząco wyniku, ponieważ residual osiąga podłogę około 0.01745 wynikającą z błędu osi 0.5 deg.

## 5. Minimalna efektywna szerokość widma

Dla wybranego wariantu:

- L1 = 1.7 m,
- L2 = 3.4 m,
- beat length = 5 mm,
- błąd osi +/-0.5 deg,

minimalna efektywna szerokość widma dla proxy <=2.5% wynosi około **5 nm**.

Jest to bardzo ważny wynik zakupowy: szerokość 3-dB może być duża, ale przed zakupem lub użyciem źródła trzeba sprawdzić, czy widmo nie zawiera wąskiego dominującego komponentu o efektywnej szerokości poniżej około 5 nm.

## 6. Benchmark źródeł

Dla benchmarków 1550 nm o minimalnej szerokości 30-100 nm nawet kompaktowy Lyot 0.5 m + 1.0 m osiąga w modelu podłogę około 0.01745 przy błędzie osi 0.5 deg.

To prowadzi do dwóch wariantów BOM:

### Wariant A - konserwatywny

- L1 = 1.7 m,
- L2 = 3.4 m,
- zakup około 6 m PM fiber,
- odporny w modelu na efektywny komponent widma do około 5 nm.

### Wariant B - kompaktowy po pomiarze źródła

Jeśli zmierzone widmo laboratoryjnego SLD jest gładkie i ma efektywną szerokość zdecydowanie powyżej 8-15 nm, można skrócić sekcje. Dla 30 nm model wymaga tylko około 0.30 m + 0.60 m dla progu 2.5%.

Na tym etapie do BOM-u bazowego zostaje wariant konserwatywny, a kompaktowy jest opcją redukcji kosztu po pomiarze źródła.

## 7. Weryfikacja w pełnym FOG

Dla fizycznie wyznaczonego proxy:

`residual_proxy = 0.017452`

otrzymano przy N=20:

- zero sigma = 0.1035 deg/h,
- signal mean = 9.15e-5 deg/s,
- signal bias = -8.50e-6 deg/s,
- class separation = **3.4788 sigma**.

Wybrany projekt przechodzi więc punktowe kryterium 3-sigma w pełnym modelu FOG.

Nie osiąga potwierdzonego 4-sigma, co jest zgodne z v6.1, gdzie interpolowany próg 4-sigma był około residual=0.0162.

Przy N=20 należy traktować tę walidację jako projektową, nie jako końcową charakterystykę metrologiczną.

## 8. Wymagania BOM wynikające z v6.2

- źródło: 1550 nm, szerokopasmowe SLD/ASE; preferencyjnie zmierzone >=30 nm i bez wąskich dominujących pików,
- PM fiber: PANDA PM1550 class, beat length <=5 mm @1550 nm,
- Lyot L1 = 1.7 m,
- Lyot L2 = 3.4 m,
- zakup PM fiber: około 6 m,
- spaw osi: 45 deg, cel technologiczny +/-0.5 deg, modelowy limit bezpieczny około +/-0.7 deg,
- polarizer: ER >=25 dB jako obecne wymaganie modelowe,
- cewka: 1000 m standardowego SMF, około 0.2 dB/km class.

## 9. Co jeszcze trzeba zmierzyć przed zakupem

Najważniejsze jest zmierzenie w laboratorium rzeczywistego źródła:

1. mocy przy wejściu toru,
2. długości centralnej,
3. pełnego widma,
4. szerokości 3-dB,
5. obecności wąskich subpików.

Jeżeli dostępne źródło spełni te wymagania, nie ma powodu kupować nowego SLD tylko na podstawie modelu.

## 10. Zweryfikowane benchmarki katalogowe

Oficjalny katalog Thorlabs dla PM1550-HP podaje zakres 1440-1625 nm, tłumienie <0.5 dB/km i beat length <=5.0 mm. Aktualne materiały katalogowe SLD 1550 nm obejmują m.in. warianty około 1 mW / 110 nm i 2.5 mW / 90 nm, więc zakresy użyte w v6.2 są realistycznymi benchmarkami.

## 11. Następny krok

Można przejść do v7 temperatura/dryft, ale od tej wersji każdy test musi również generować wymagania materiałowe i pomiarowe dla prototypu.

Dla v7 oznacza to m.in.: wymagania dla czujnika temperatury, stabilności źródła, konstrukcji cewki i izolacji termicznej.

## Dane źródłowe

- results/v6_2/FOG_v6_2_depolarizing_length_estimate.csv
- results/v6_2/FOG_v6_2_length_vs_bandwidth.csv
- results/v6_2/FOG_v6_2_effective8nm_guard.csv
- results/v6_2/FOG_v6_2_source_benchmark.csv
- results/v6_2/FOG_v6_2_selected_design.csv
- results/v6_2/FOG_v6_2_bom_requirements.csv
- results/v6_2/FOG_v6_2_fog_verification.csv