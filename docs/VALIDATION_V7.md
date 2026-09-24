# Walidacja FOG v7 - temperatura, Shupe i thermal BOM

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v7 działa jako projektowy model termiczny. Wyznacza provisional former, wymagania na izolację, winding symmetry i tor pomiaru temperatury.

Najważniejsze ograniczenie pozostaje jawne: model obejmuje pure Shupe i uproszczony radialny transient, ale nie pełny thermo-mechanical stress / Mohr T-dot effect.

## 1. Uniform-temperature scale factor

Lokalne współczynniki temperaturowe scale factor:

| materiał | coeff [ppm/K] | dopuszczalny błąd sensora @20 deg/s [C] |
|---|---:|---:|
| Al6061-T6 | 24.159 | 0.207 |
| Invar36 | 1.859 | 2.689 |
| G10-FR4 | 9.559 | 0.523 |
| POM-C | 110.559 | 0.045 |
| fused silica benchmark | 1.109 | 4.507 |

Dla Invar36 zmiana od 25 C do -10 / +60 C daje około -65.1 / +65.0 ppm scale error przed kompensacją.

Przy 20 deg/s odpowiada to około +/-0.00130 deg/s, więc temperature scale-factor calibration pozostaje potrzebna, mimo niskiego CTE.

## 2. Screening materiału formera

Przy kryteriach:
- thermal budget = 0.12 deg/h,
- 1 C/min, tau_outer = 60 s,
- QAD/symmetric asymmetry proxy = 2%,
- CTE mismatch proxy <=5 ppm/K,
- Pt100 Class A dla uniform-scale correction,

tylko **Invar36** przechodzi wszystkie trzy kryteria.

| materiał | CTE mismatch [ppm/K] | QAD2% Shupe [deg/h] | wynik |
|---|---:|---:|---|
| Al6061-T6 | 23.05 | 0.00223 | fail CTE proxy |
| Invar36 | 0.75 | 0.05643 | PASS |
| G10-FR4 | 8.45 | 0.42739 | FAIL |
| POM-C | 109.45 | 0.45094 | FAIL |
| fused silica | 0 | 0.14098 | fail Shupe @tau60 |

### Ważna interpretacja

Aluminium daje bardzo mały pure-Shupe error dzięki wysokiej dyfuzyjności cieplnej, ale przegrywa obecny stress-risk proxy z powodu dużej różnicy CTE względem silica fiber.

Dlatego Invar36 jest **provisional material lock**, a nie finalnym dowodem, że aluminium jest gorsze w realnym FOG. v7.1 musi bezpośrednio zbadać thermo-mechanical stress przed ostatecznym zamknięciem materiału.

## 3. Shupe transient dla Invar36

### Ramp 1 C/min, asymmetry=2%

| tau_outer | max QAD proxy [deg/h] | wynik |
|---:|---:|---|
| 15 s | 0.1851 | FAIL |
| 30 s | 0.1051 | PASS |
| 60 s | 0.05643 | PASS |
| 120 s | 0.02931 | PASS |

Tau >=60 s daje około 2.1x margines względem budżetu 0.12 deg/h przy 1 C/min.

### Ramp 5 C/min, asymmetry=2%

| tau_outer | max QAD proxy [deg/h] | wynik |
|---:|---:|---|
| 15 s | 0.9254 | FAIL |
| 30 s | 0.5254 | FAIL |
| 60 s | 0.2821 | FAIL |
| 120 s | 0.1464 | FAIL |

Wniosek: przy szybkim transiencie 5 C/min sama izolacja i 2% asymetrii nie wystarczają. Potrzebna jest aktywna kompensacja albo lepsza symetria uzwojenia.

Bez kompensacji wymagany maksymalny asymmetry proxy wynosi:
- około 0.85% przy tau=60 s,
- około 1.64% przy tau=120 s.

To doprecyzowanie zostało wpisane do thermal BOM.

## 4. Dwuczujnikowa kompensacja

Test stress ramp 5 C/min, Invar36, tau_outer=60 s, filter tau=10 s:

| sample period | sensor noise | P95 residual [deg/h] | wynik |
|---:|---:|---:|---|
| 0.5 s | 0.005 C | 0.0685 | PASS |
| 0.5 s | 0.010 C | 0.1185 | PASS, mały margines |
| 1 s | 0.005 C | 0.0654 | PASS |
| 1 s | 0.010 C | 0.1151 | PASS, mały margines |
| 2 s | 0.010 C | 0.1008 | PASS |
| 5 s | 0.010 C | 0.0869 | PASS |

Dla 0.03 C i 0.05 C RMS wszystkie testowane sample periods przekraczają budżet.

### Wniosek

- <=0.01 C RMS po filtracji jest minimalnym wymaganiem modelowym,
- <=0.005 C RMS jest preferowanym celem z wyraźniejszym marginesem,
- około 1 Hz jest w pełni wystarczające; szybsze próbkowanie nie poprawia wyniku, bo pochodna temperatury wzmacnia szum.

## 5. Klasa Pt100

Dla samej uniform-scale compensation wszystkie testowane klasy przechodzą:
- Class AA: +/-0.1425 C @25 C,
- Class A: +/-0.20 C,
- Class B: +/-0.425 C.

Zatem absolutna klasa Pt100 nie jest ograniczeniem scale-factor dla Invar36.

Roboczo pozostaje:
- Class A jako minimum projektowe,
- Class AA preferred,
- 4-wire preferred,
- dużo ważniejszy dla Shupe compensation jest szum różnicowy toru <=0.01 C RMS, preferowane <=0.005 C RMS.

## 6. Thermal BOM po walidacji

### Former
Provisional: Invar36 lub materiał o podobnym CTE i zweryfikowanej odpowiedzi termicznej.

### Enclosure
- tau_outer >=60 s z aktywną kompensacją,
- >=120 s daje dodatkowy margines, ale przy 5 C/min i 2% asymetrii nadal nie wystarcza bez kompensacji.

### Sensory
- dwa RTD: INNER + OUTER,
- Pt100/Pt1000 Class A minimum, AA preferred,
- 4-wire.

### Readout
- 2 kanały,
- około 1 Hz wystarcza,
- <=0.01 C RMS po filtrze 10 s minimum,
- <=0.005 C RMS preferred.

### Winding
- symmetric / quadrupolar,
- <=2% asymmetry proxy jest akceptowane tylko z aktywną kompensacją dla szybkich transientów,
- bez kompensacji 5 C/min: <=0.85% przy tau60 lub <=1.64% przy tau120.

### Potting / adhesive
Pozostaje OPEN do v7.1.

## 7. Co v7 rozstrzyga, a czego nie

Rozstrzygnięte:
- provisional former = Invar36,
- thermal enclosure wymagane,
- dwa sensory temperatury,
- wymagania noise/sample rate,
- aktywna kompensacja dla szybkich zmian temperatury,
- quadrupolar/symmetric winding requirement.

Nie rozstrzygnięte:
- finalny klej/potting,
- winding tension,
- photoelastic stress coefficient całej konstrukcji,
- czy aluminium po mechanicznym odsprzęgnięciu nie okaże się lepsze od Invaru.

## 8. Następny etap v7.1

v7.1 powinno modelować thermo-mechanical stress / Mohr T-dot effect i porównać co najmniej Invar36 oraz aluminium z różnymi metodami mocowania włókna.

Powinno wyprowadzić do BOM-u:
- dopuszczalny winding tension,
- wymagany sposób mocowania,
- klasę/CTE/moduł kleju lub decyzję o braku pełnego pottingu,
- wpływ grubości warstwy kleju,
- finalny materiał formera.

## Dane źródłowe

- results/v7/FOG_v7_uniform_temperature_sweep.csv
- results/v7/FOG_v7_shupe_transient_sweep.csv
- results/v7/FOG_v7_former_material_screening.csv
- results/v7/FOG_v7_temperature_sensor_sweep.csv
- results/v7/FOG_v7_pt100_class_check.csv
- results/v7/FOG_v7_thermal_bom.csv
- results/v7/FOG_v7_thermal_acceptance_tests.csv