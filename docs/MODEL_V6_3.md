# FOG v6.3 - optical BOM lock

## Cel

v6.3 formalizuje zasadę, że symulacja ma prowadzić do wymagań sprzętowych, a nie tylko do modelu matematycznego.

Na wejściu wykorzystuje zweryfikowane wyniki v1-v6.2. Na wyjściu generuje:

- wymagania minimalne,
- wymagania preferowane,
- status: LAB VERIFY / BUY / FABRICATE / CONDITIONAL,
- tolerancje montażowe,
- plan testów odbiorczych,
- listę zakupową.

## Stan laboratorium przyjęty w v6.3

Z wcześniejszych ustaleń projektu:

- źródła światła są dostępne w laboratorium,
- sprzęgacze są dostępne w laboratorium,
- fotodiody są dostępne w laboratorium,
- modulator fazy / PZT trzeba zorganizować,
- polaryzator trzeba zorganizować,
- cewkę 1 km standardowego SMF trzeba zorganizować / wykonać,
- Lyot wymaga PM1550 fiber i kontrolowanego spawu osi.

Element dostępny w laboratorium nie jest automatycznie zaakceptowany. Musi przejść test v6.3.

## 1. PZT / fiber phase shifter

Model v2 wymaga przy 20 kHz:

- beta = 1.84 rad,
- phi0 około 3.04 rad,
- phase excursion p-p około 1.93 pi.

Dla modulatora o Vpi:

`Vpk = phi0/pi * Vpi`.

Przy Vpi = 20 V potrzebne jest około 19.3 Vpk, czyli około 38.7 Vpp.

Roboczy lock:

- 1550 nm,
- zakres modulacji co najmniej DC-20 kHz,
- preferowany margines pasma >=30 kHz,
- Vpi <=20 V preferowane,
- zakres fazy >=4 pi p-p minimum, preferowane >=8 pi,
- IL <=0.5 dB minimum, preferowane <=0.1 dB,
- PDL <=0.1 dB minimum, preferowane <=0.05 dB,
- niski RAM,
- RL >=55 dB, preferowane >=65 dB.

Benchmark Luna FPS-001 spełnia klasę: DC-20 kHz, >8 pi, Vpi <20 V, IL <0.1 dB, PDL <0.05 dB i RL >65 dB. 20 kHz jest jednak jego górną granicą, więc konkretna sztuka musi zostać zweryfikowana przy 20 kHz.

Driver:

- minimum wynikające z Vpi=20 V: około 39 Vpp,
- preferowane >=50 Vpp,
- minimum 20 kHz, preferowane >=30 kHz,
- wydajność prądowa musi być dobrana po zmierzeniu / odczytaniu pojemności piezo.

Skrypt generuje tabelę prądu dla 10-180 nF.

## 2. Źródło

Nie kupujemy nowego SLD przed pomiarem źródła laboratoryjnego.

Po v6.2 wymagamy:

- około 1550 nm,
- efektywna szerokość po całym front-endzie >=5 nm,
- preferowane gładkie widmo 30-50 nm,
- moc na wejściu K1 około 0.8-1.0 mW.

Z dotychczasowego power budget wynika, że około 1.1 mW jest górną granicą dla ~10% marginesu względem 2 V toru ADC/TIA.

Jeżeli dostępne SLD ma większą moc, dodajemy VOA / stały tłumik zamiast odrzucać źródło.

## 3. Sprzęgacze K1 i K2

Laboratoryjne sztuki muszą przejść pomiar.

Lock:

- 2x2 single-mode, bidirectional,
- 1550 nm,
- 50:50 +/-5%,
- excess loss <=0.3 dB,
- PDL <=0.15 dB,
- directivity / return loss >=55 dB, preferowane >=60 dB,
- szerokość wystarczająca, aby po K1/K2 nadal zostało >=5 nm efektywnego widma.

Preferowane dla nowego zakupu: klasa co najmniej +/-40 nm wokół 1550 nm lub szersza.

Sam błąd podziału 45:55 powoduje w modelu tylko około 0.044 dB kary mocy. Mimo tego trzymamy +/-5% z uwagi na symetrię i powtarzalność toru.

## 4. Polaryzator

Po v6/v6.2:

- minimum ER >=25 dB,
- preferowane ER >=30 dB,
- IL <=0.7 dB,
- RL >=55 dB, preferowane >=60 dB,
- 1550 nm i kompatybilność z PM1550 / fusion splice.

Benchmark klasy OZ Optics ma >30 dB ER, IL <0.7 dB i return loss lepszy niż -60 dB, więc wymagania są osiągalne katalogowo.

## 5. Depolaryzator Lyota

Lock z v6.2:

- PM1550 PANDA, beat length <=5 mm @1550 nm,
- L1 = 1.7 m,
- L2 = 3.4 m,
- aktywnie 5.1 m,
- zakup około 6 m,
- osie 45 deg,
- target procesu +/-0.5 deg,
- modelowy limit safe około +/-0.7 deg.

## 6. Cewka 1 km SMF

v6.3 dodaje projekt mechaniczny do BOM.

Benchmark fiber:

- G.652.D / SMF-28 class,
- około 242-250 um coating,
- attenuation <=0.25 dB/km @1550 nm.

Pierwsza geometria spool:

- core diameter 155 mm,
- winding width 30 mm,
- packing fill 0.90.

Skrypt wyznacza liczbę warstw, liczbę zwojów, outer diameter i length-weighted mean diameter. Celem jest zachowanie średnicy efektywnej około 160 mm użytej w modelu Sagnaca.

Materiał spool nie jest jeszcze zamykany. To zrobi v7 na podstawie modelu termicznego.

## 7. Fotodioda i TIA

Fotodioda jest dostępna w laboratorium, ale musi spełnić:

- InGaAs,
- responsivity >=0.8 A/W @1550 nm,
- liniowość dla co najmniej 100 uW,
- dark current preferencyjnie <=10 nA.

TIA:

- około 20 kOhm,
- bandwidth >=200 kHz,
- wyjście kompatybilne z 0..2 V ADC.

## 8. Połączenia

Wewnątrz pętli preferowane są fusion splices.

Roboczo:

- target <=0.05 dB na splice,
- brak zwykłych PC connectors wewnątrz pętli,
- FC/APC tylko na granicach serwisowych,
- PM splice z kontrolą osi dla Lyota.

## 9. Wymóg pomiaru przed zakupem

v6.3 generuje osobny acceptance plan.

Najważniejsze testy:

1. OSA źródła przed i po front-endzie,
2. power meter dla mocy na K1,
3. ratio i loss K1/K2,
4. responsivity i liniowość fotodiody,
5. Vpi / phase gain PZT,
6. beta przy 20 kHz,
7. ER/IL polaryzatora,
8. kąt spawu Lyota,
9. długość i geometria cewki,
10. insertion loss gotowej pętli.

## 10. Wyniki skryptu

- FOG_v6_3_pzt_drive_sweep.csv
- FOG_v6_3_pzt_driver_current.csv
- FOG_v6_3_source_power_conditioning.csv
- FOG_v6_3_coupler_ratio_sweep.csv
- FOG_v6_3_polarizer_ER_sweep.csv
- FOG_v6_3_coil_geometry.csv
- FOG_v6_3_coil_layers.csv
- FOG_v6_3_bom_lock.csv
- FOG_v6_3_lab_acceptance_tests.csv
- FOG_v6_3_procurement.csv
- FOG_v6_3.slx, jeśli lokalnie istnieje model v6.x.

## 11. Kryterium zakończenia v6.3

v6.3 zostanie zamknięte po lokalnym uruchomieniu skryptu i sprawdzeniu wygenerowanego BOM-u.

Elementy laboratoryjne nie mogą zostać oznaczone PASS bez pomiaru rzeczywistej sztuki.

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Najważniejsze wyniki:
- PZT: phi0 = 3.0375 rad, phase p-p = 1.9337 pi,
- dla Vpi=20 V wymagane około 38.7 Vpp,
- driver 50 Vpp daje około 1.29x marginesu napięciowego,
- target source = 0.8-1.0 mW na K1; powyżej około 1.10 mW potrzebne ograniczenie mocy,
- 45/55 coupler daje tylko około 0.044 dB kary,
- polarizer minimum 25 dB ER, preferowane >=30 dB,
- geometria 1 km SMF: 18 warstw, około 1997 zwojów, efektywna średnica około 159.395 mm,
- procurement i acceptance-test plan zostały wygenerowane.

Ważne:
- konkretnego PZT drivera nie wybieramy przed poznaniem capacitance / load phase shiftera,
- materiał coil former pozostaje do v7,
- źródło, K1/K2 i photodiode z laboratorium muszą przejść test odbiorczy.

Szczegóły: `docs/VALIDATION_V6_3.md`.