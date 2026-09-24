# FOG v5.1 - optymalizacja ADC i DSP

## Cel

v5.1 nie zmienia optyki ani modelu fotoodbiornika. Jest warstwą optymalizacyjną nad zweryfikowanym `FOG_v5.slx`.

Główne pytania:

1. czy 14 bit wystarcza do detekcji `0.0001 deg/s`,
2. jak silny jest koherentny bias zależny od fazy zegara ADC,
3. czy problem obserwowany przy `2 MS/s` pozostaje po dodaniu pełnego szumu,
4. czy obniżenie częstotliwości AAF poprawia ochronę przed aliasingiem bez pogorszenia czułości.

## v5.1A - detekcja vs liczba bitów

Testowane:

- 12 bit,
- 14 bit,
- 16 bit,
- `f_s = 1 MS/s`,
- `AAF = 150 kHz`,
- `Tavg = 10 ms`,
- `30` realizacji dla zera,
- `30` realizacji dla `0.0001 deg/s`.

Raportowane są:

- sigma zera,
- próg 3-sigma,
- mean i sigma sygnału,
- bias,
- RMSE,
- SNR,
- separacja klasy zero i sygnału w jednostkach sigma.

## v5.1B - sweep fazy zegara ADC

Testowana jest względna faza próbkowania:

`0, 0.125, 0.25, ..., 0.875 Ts`

dla:

- 500 kS/s,
- 1 MS/s,
- 2 MS/s.

ADC i referencja lock-in są przesuwane razem względem analogowego przebiegu. Pozwala to badać zmianę koherentnego błędu kwantyzacji bez celowego rozstrajania demodulatora.

Test wykonywany jest bez losowego szumu w trybie STANDARD:

`Ts_solver = 0.05 us`.

Dla każdej fazy mierzony jest błąd:

- przy `1 deg/s`,
- przy `0.0001 deg/s`.

Podsumowanie podaje:

- peak-to-peak błędu względem fazy,
- maksymalny bezwzględny błąd.

## v5.1C - częstotliwość ADC pod szumem

Testowane:

- 500 kS/s,
- 1 MS/s,
- 2 MS/s,
- 16 bit,
- AAF 150 kHz,
- 20 realizacji zero-rate na punkt.

Raportowane są:

- próbki na okres 20 kHz,
- łączne tłumienie TIA + AAF przy Nyquiście,
- bias,
- sigma,
- sigma w deg/h,
- faktor względem analogowego v4.1.

## v5.1D - sweep AAF

Testowane częstotliwości graniczne:

- 80 kHz,
- 100 kHz,
- 150 kHz,

dla:

- 16 bit,
- 1 MS/s,
- 20 realizacji zero-rate.

Raportowane są:

- moduł AAF przy 20 kHz,
- faza AAF przy 20 kHz,
- tłumienie TIA+AAF przy Nyquiście,
- bias,
- sigma,
- faktor względem analogowego v4.1.

## Co v5.1 ma rozstrzygnąć

Po walidacji chcemy wskazać roboczy zakres:

- minimalnej liczby bitów,
- minimalnej sensownej częstotliwości próbkowania,
- zalecanej częstotliwości AAF.

To nadal nie będzie wybór konkretnego układu ADC do BOM-u, ale już specyfikacja jego minimalnych parametrów.

## Decymacja

Decymacja nie jest jeszcze aktywnie implementowana w v5.1.

Powód: najpierw ustalamy poprawną konfigurację ADC + AAF + cyfrowego lock-in. Dopiero potem można bezpiecznie dodać redukcję częstotliwości po cyfrowym LPF i oszacować obciążenie MCU/FPGA.

## Pliki wynikowe

- `FOG_v5_1.slx`
- `FOG_v5_1_detection_vs_bits.csv`
- `FOG_v5_1_clock_phase_sweep.csv`
- `FOG_v5_1_clock_phase_summary.csv`
- `FOG_v5_1_fs_monte_carlo.csv`
- `FOG_v5_1_aaf_monte_carlo.csv`

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Roboczy wynik projektowy:
- minimum 14 bit,
- preferowane 16 bit,
- nominalnie 1 MS/s,
- AAF 100 kHz jako kandydat do dalszego modelu,
- synchronizacja ADC i referencji lock-in pozostaje istotna.

Szczegóły i ograniczenia statystyczne:
`docs/VALIDATION_V5_1.md`.
