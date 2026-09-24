# Walidacja FOG v6.1 - próg wymaganej kontroli polaryzacji

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v6.1 wyznacza modelowy próg skuteczności kontroli polaryzacji dla 1 km standardowego SMF. Wynik jest wymaganiem modelowym, nie bezpośrednim parametrem katalogowym depolaryzatora.

## 1. Paired detection sweep

Warunki: standard SMF 1000 m, target 0.0001 deg/s = 0.36 deg/h, ER polaryzatora 25 dB jako założenie, pol_nr_scale = 2e-4, ADC 16 bit / 1 MS/s, AAF 100 kHz, N=30 par na punkt, wspólne stany SMF i seedy.

| residual | zero sigma [deg/h] | zero 3-sigma [deg/h] | signal mean [deg/s] | separation [sigma] |
|---:|---:|---:|---:|---:|
| 0.100 | 0.15630 | 0.46889 | 9.8937e-5 | 2.308 |
| 0.075 | 0.13249 | 0.39747 | 9.9839e-5 | 2.716 |
| 0.050 | 0.10905 | 0.32714 | 1.0154e-4 | 3.239 |
| 0.025 | 0.09570 | 0.28708 | 1.0149e-4 | 3.723 |
| 0.000 | 0.07980 | 0.23941 | 1.0287e-4 | 4.507 |

### Wynik punktowy

- największy przetestowany residual spełniający >=3 sigma: **0.05**
- największy przetestowany residual spełniający >=4 sigma: **0.00**
- interpolowany próg 3 sigma: **0.06143**
- interpolowany próg 4 sigma: **0.01618**

Interpolacja jest wyłącznie pomocnicza.

## 2. Dodatkowa analiza bootstrap

Bootstrap po 30 sparowanych realizacjach, z zachowaniem wspólnego banku przypadków między residual, daje orientacyjne 95% przedziały dla class separation:

| residual | point estimate | bootstrap 95% CI |
|---:|---:|---:|
| 0.100 | 2.308 | 1.90 ... 3.10 |
| 0.075 | 2.716 | 2.26 ... 3.60 |
| 0.050 | 3.239 | 2.69 ... 4.33 |
| 0.025 | 3.723 | 3.09 ... 5.09 |
| 0.000 | 4.507 | 3.72 ... 6.28 |

Rozróżnienie projektowe:
- punktowy próg 3-sigma: residual około 0.05, interpolacyjnie 0.061;
- konserwatywny punkt 3-sigma, dla którego dolna granica bootstrap pozostaje >3: residual około **0.025** na obecnej siatce;
- obecne N=30 nie potwierdza dolnej granicy bootstrap >4 nawet dla residual=0.

Do BOM-u nie należy więc przyjmować 0.061 jako twardej gwarancji.

## 3. Paired delta

Paired delta używa identycznego stanu SMF i identycznego szumu dla pary zero/signal. Średnia delta pozostaje bardzo bliska 0.0001 deg/s, a paired delta SNR wynosi około 25-30. Pokazuje to silną składową common-mode, ale ta metryka nie jest podstawowym kryterium detekcji niezależnych pomiarów.

## 4. Sweep pol_nr_scale przy residual = 0.05

| pol_nr_scale | zero sigma [deg/h] | P95 |Omega| [deg/s] |
|---:|---:|---:|
| 0 | 0.07646 | 4.34e-5 |
| 5e-5 | 0.07531 | 4.27e-5 |
| 1e-4 | 0.07638 | 4.18e-5 |
| 2e-4 | 0.08631 | 4.11e-5 |
| 4e-4 | 0.12385 | 6.61e-5 |
| 8e-4 | 0.22598 | 1.255e-4 |

Model jest stosunkowo mało wrażliwy na pol_nr_scale do około 1e-4. Nominalne 2e-4 nadal daje umiarkowany wzrost szumu. Od około 4e-4 degradacja staje się wyraźna.

## 5. Robocze wymaganie modelowe

Dla celu 0.0001 deg/s:

- minimalne kryterium punktowe: depol_residual <= 0.05 daje separację >3 sigma;
- bezpieczniejszy cel projektowy na obecnej statystyce: **depol_residual <= 0.025**;
- punktowa interpolacja 4-sigma daje około 0.016, ale nie jest jeszcze statystycznie potwierdzona.

## 6. Znaczenie dla standardowego SMF

Standardowe SMF pozostaje realnym kandydatem do prototypu, ale wymaga bardzo skutecznej kontroli polaryzacji. Residual jest parametrem modelowym i nie można go przeliczyć 1:1 na DOP, extinction ratio ani długość sekcji PM.

## 7. Następny logiczny krok: v6.2

Przed v7 temperatura/dryft rekomendowany jest fizycznie parametryzowany model depolaryzatora Lyota. Powinien uwzględnić szerokość widma SLD, coherence length, birefringence / beat length PM fiber, długości dwóch sekcji PM i kąt 45 stopni, a następnie zmapować te parametry na modelowy residual.

To jest potrzebne do rzeczywistego doboru części optycznej do BOM-u.

## Dane źródłowe

- results/v6_1/FOG_v6_1_detection_vs_residual.csv
- results/v6_1/FOG_v6_1_pol_nr_scale_sweep.csv
- results/v6_1/FOG_v6_1_requirement.csv
- lokalnie: FOG_v6_1_paired_raw.csv