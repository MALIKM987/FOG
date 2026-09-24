# Walidacja FOG v6.3 - optical BOM lock

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v6.3 zamyka robocze wymagania materiałowe części optycznej. Nie oznacza to jeszcze, że każda pozycja może zostać natychmiast zamówiona: elementy laboratoryjne wymagają pomiaru, PZT driver wymaga znajomości obciążenia pojemnościowego, a materiał formy cewki pozostaje do v7.

## 1. Phase modulator / PZT

Model wymaga:
- phi0 = 3.037518 rad = 0.9669 pi,
- phase p-p = 6.075036 rad = 1.9337 pi.

Dla Vpi=20 V:
- wymagane Vpk = 19.337 V,
- wymagane Vpp = 38.675 V.

Driver 50 Vpp daje margines około 1.293x.

Maksymalne Vpi, które 50 Vpp może teoretycznie obsłużyć bez marginesu, wynosi około 25.86 V. Dlatego Vpi<=20 V pozostaje rozsądnym wymaganiem preferowanym.

## 2. PZT driver i pojemność

Przy Vpi=20 V i 20 kHz:

| Cpiezo | Ipk | Irms | reactive VA |
|---:|---:|---:|---:|
| 10 nF | 24.3 mA | 17.2 mA | 0.235 VA |
| 25 nF | 60.8 mA | 43.0 mA | 0.587 VA |
| 50 nF | 121.5 mA | 85.9 mA | 1.175 VA |
| 100 nF | 243.0 mA | 171.8 mA | 2.350 VA |
| 180 nF | 437.4 mA | 309.3 mA | 4.229 VA |

Wniosek: **nie wolno zamknąć konkretnego drivera wyłącznie po Vpp i bandwidth**. Najpierw trzeba znać pojemność / impedancję wybranego phase shiftera przy 20 kHz.

## 3. Źródło i headroom

Zweryfikowany model daje:
- 1.0 mW -> peak TIA około 1.634 V,
- 1.2 mW -> około 1.961 V,
- 2.5 mW -> około 4.085 V.

Dla ADC 0..2 V:
- maksimum dla 10% headroom: około 1.102 mW,
- maksimum dla 20% headroom: około 0.979 mW.

Dlatego roboczy cel 0.8-1.0 mW na K1 jest potwierdzony.

Jeżeli laboratoryjne SLD ma większą moc, należy dodać VOA / fixed attenuator zamiast kupować inne źródło.

## 4. Sprzęgacze

Sam błąd split ratio jest mało krytyczny:
- 45/55 -> kara około 0.0436 dB,
- 40/60 -> około 0.1773 dB.

Specyfikacja 50:50 +/-5% jest wystarczająca. W praktyce bardziej istotne są excess loss, PDL, directivity i spectral flatness.

## 5. Polaryzator

Dla ER:
- 25 dB -> calibrated visibility 0.99370, penalty około 0.630%,
- 30 dB -> 0.99800, penalty około 0.200%,
- 35 dB -> 0.99937, penalty około 0.063%.

Wniosek: minimum 25 dB pozostaje akceptowalne, ale >=30 dB jest wyraźnie lepszym celem zakupowym przy podobnym IL.

## 6. Cewka 1000 m SMF

Dla coating 242 um, core 155 mm, winding width 30 mm i fill=0.9:
- 111 zwojów na pełną warstwę,
- 18 warstw,
- około 1997.5 zwojów,
- outer diameter około 163.712 mm,
- length-weighted mean diameter = 159.3945 mm,
- zalecana minimalna średnica kołnierza około 173.712 mm.

Rzeczywisty K_sag wynosi 2.15527 rad/(rad/s), czyli około -0.378% względem modelowego 160 mm.

To nie jest problem fundamentalny: po wykonaniu cewki należy zmierzyć geometrię i użyć rzeczywistego K_sag w kalibracji. Materiał formera pozostaje otwarty do v7.

## 7. Roboczy BOM lock

### Dostępne w laboratorium, ale wymagają weryfikacji
- SLD/ASE source,
- K1,
- K2,
- InGaAs photodiode.

### Do zorganizowania / zakupu
- in-line fiber polarizer,
- około 6 m PM1550 PANDA do Lyota,
- fiber phase shifter / PZT,
- 1000 m standardowego SMF.

### Zależne od dalszego pomiaru
- PZT driver: po określeniu capacitance/load phase shiftera,
- VOA: tylko jeśli lab source przekracza około 1.1 mW na K1,
- external FC/APC connectors: zgodnie z finalną mechaniką.

### Proces / wykonanie
- Lyot 1.7 m + 3.4 m, 45 deg +/-0.5 deg,
- fusion splices,
- coil former i winding.

## 8. Procurement hotfix

Pierwsza wersja skryptu generowała procurement CSV tylko dla BUY / ORGANIZE, FABRICATE i PROCESS / LAB CAPABILITY, przez co pomijała CONDITIONAL BUY, BUILD / VERIFY, BUY AS NEEDED i PROCESS / CONSUMABLES.

Skrypt został poprawiony. Aktualny procurement plan obejmuje wszystkie pozycje inne niż LAB AVAILABLE - VERIFY.

## 9. Acceptance plan

Przed zamknięciem zakupów należy wykonać kolejno:
1. OSA źródła przed/po front-endzie,
2. moc źródła na K1,
3. ratio K1/K2,
4. spectral flatness K1/K2,
5. responsivity i liniowość fotodiody/TIA,
6. Vpi/phase gain PZT i beta przy 20 kHz,
7. ER/IL polaryzatora,
8. kąt spawu Lyota i test wyjścia,
9. długość/geometrię cewki,
10. insertion loss gotowej pętli.

## 10. Wniosek

v6.3 spełnia swój cel: mamy roboczą specyfikację materiałową i procedurę akceptacji.

Nie należy jeszcze kupować nowych: źródła, sprzęgaczy i fotodiody, dopóki laboratoryjne sztuki nie zostaną zmierzone.

Najważniejsze nierozstrzygnięte pozycje przed zakupem to:
- rzeczywiste widmo/moc SLD,
- parametry laboratoryjnych K1/K2,
- capacitance / electrical load wybranego PZT,
- materiał i konstrukcja thermal-low-stress coil former z v7.

## Dane źródłowe

- results/v6_3/FOG_v6_3_pzt_drive_sweep.csv
- results/v6_3/FOG_v6_3_pzt_driver_current.csv
- results/v6_3/FOG_v6_3_source_power_conditioning.csv
- results/v6_3/FOG_v6_3_coupler_ratio_sweep.csv
- results/v6_3/FOG_v6_3_polarizer_ER_sweep.csv
- results/v6_3/FOG_v6_3_coil_geometry.csv
- results/v6_3/FOG_v6_3_coil_layers.csv
- results/v6_3/FOG_v6_3_bom_lock.csv
- results/v6_3/FOG_v6_3_lab_acceptance_tests.csv
- results/v6_3/FOG_v6_3_procurement.csv