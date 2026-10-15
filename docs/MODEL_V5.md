# Model FOG v5 - ADC i cyfrowy lock-in

## Cel

v5 dodaje pierwszy jawny cyfrowy tor pomiarowy do zweryfikowanego modelu FOG.

Na poziomie głównym architektura zmienia się z:

```text
Photoreceiver -> Lock-In DSP
```

na:

```text
Photoreceiver -> ADC AFE -> Digital Lock-In DSP
```

Model nadal zachowuje hierarchię fizyczną. Szczegółowe równania i elementy znajdują się wewnątrz podsystemów.

## Nominalna konfiguracja ADC

Założenia projektowe v5:

| Parametr | Wartość |
|---|---:|
| Zakres ADC | 0 ... 2 V |
| Rozdzielczość nominalna | 16 bit |
| Częstotliwość próbkowania | 1 MS/s |
| LSB 16 bit | około 30.5 uV |
| Anti-alias LPF | Butterworth 4. rzędu |
| f_c anti-alias | 150 kHz |
| Digital lock-in LPF | Butterworth 4. rzędu |
| f_c digital LPF | 300 Hz |
| f_mod | 20 kHz |

Parametry nie są jeszcze zatwierdzonym BOM-em.

## ADC AFE

Podsystem `ADC AFE` zawiera:

1. analogowy filtr antyaliasingowy,
2. ograniczenie sygnału do zakresu ADC,
3. sample-and-hold,
4. kwantyzację N-bit.

Model używa:

`q_ADC = V_FS / (2^N - 1)`.

Dla 16 bit i 2 V:

`q_ADC ~= 30.5 uV`.

## Anti-alias filter

AAF jest analogowym Butterworthem 4. rzędu z:

`f_c = 150 kHz`.

Jego moduł i faza przy 20 kHz są jawnie uwzględniane w normalizacji i fazie referencji lock-in.

Łączna korekcja fazy obejmuje:

- TIA,
- AAF.

## Digital Lock-In DSP

Referencja Sagnaca jest:

1. kompensowana o analogowe opóźnienie fazowe,
2. próbkowana z tym samym `T_s` co ADC,
3. mnożona cyfrowo przez próbki ADC.

Filtr wyjściowy jest cyfrowym Butterworthem 4. rzędu.

Dla stabilności numerycznej przy `f_c << f_s` został zrealizowany jako dwie sekcje drugiego rzędu SOS.

Po filtrze pozostają:

- normalizacja amplitudy,
- ograniczenie wejścia `asin`,
- `asin`,
- przeliczenie fazy Sagnaca na deg/s.

## Budżet szumu kwantyzacji

Dla idealnego ADC RMS błędu kwantyzacji:

`V_q,rms = q/sqrt(12)`.

Przy założeniu białego błędu kwantyzacji jego jednostronna ASD:

`e_q = q/sqrt(6 f_s)`.

v5 generuje tabelę dla:

- 8 bit,
- 10 bit,
- 12 bit,
- 14 bit,
- 16 bit.

Tabela porównuje kwantyzację z analogowym szumem Photoreceivera przy częstotliwości modulacji.

## Test v5A - nominalny baseline

Warunki:

- 16 bit,
- 1 MS/s,
- brak losowego szumu,
- solver STANDARD `T_s = 0.05 us`,
- `Omega = 1 deg/s`.

Sprawdzane są:

- błąd Omega,
- zakres sygnału przed ADC,
- minimalny i maksymalny kodowany poziom,
- zapas do 0 V i 2 V.

## Test v5B - sweep rozdzielczości

Testowane:

- 8,
- 10,
- 12,
- 14,
- 16 bit.

Dla każdego ADC mierzony jest deterministyczny błąd dla:

- `1 deg/s`,
- `0.0001 deg/s`.

Celem jest określenie, od ilu bitów kwantyzacja przestaje być dominującym ograniczeniem.

## Test v5C - sweep częstotliwości próbkowania

Testowane:

- 100 kS/s,
- 200 kS/s,
- 500 kS/s,
- 1 MS/s,
- 2 MS/s.

Zapisywane są:

- liczba próbek na okres modulacji 20 kHz,
- tłumienie AAF przy Nyquiście,
- łączne tłumienie TIA + AAF przy Nyquiście,
- błąd Omega.

Niska liczba próbek na okres może dawać poprawny wynik deterministyczny, ale nadal mieć niewystarczające zabezpieczenie przeciw aliasingowi. Dlatego metryki Nyquista są raportowane osobno.

## Test v5D - Monte Carlo ADC

Dla:

- 12 bit,
- 14 bit,
- 16 bit,
- 1 MS/s,
- `Tavg = 10 ms`,

wykonywane jest po 30 realizacji zero-rate.

Wynik porównywany jest ze zweryfikowaną analogową wartością v4.1:

`sigma_analog(10 ms) ~= 1.9999e-5 deg/s`.

Porównywane są:

- zmierzony wzrost sigma,
- prosty analityczny wzrost szumu wynikający z ASD kwantyzacji.

## Kryterium doboru ADC

Wstępne kryterium:

ADC jest wystarczający, jeżeli:

1. nie powoduje clippingu,
2. błąd deterministyczny jest dużo mniejszy od zakładanego błędu pomiarowego,
3. wzrost sigma względem analogowego v4.1 jest mały,
4. filtracja analogowa przy Nyquiście ogranicza aliasing,
5. liczba próbek na okres modulacji daje stabilną demodulację.

## Pliki wynikowe

- `FOG_v5.slx`
- `FOG_v5_baseline.csv`
- `FOG_v5_adc_noise_budget.csv`
- `FOG_v5_bit_sweep.csv`
- `FOG_v5_fs_sweep.csv`
- `FOG_v5_adc_monte_carlo.csv`

## Status

**Rdzeń zweryfikowany w MATLAB/Simulink R2023b Update 7. Dobór ADC pozostaje prowizoryczny do v5.1.**

Wyniki wskazują:

- brak clippingu dla 0..2 V,
- 14 bit jako pierwszy sensowny kandydat,
- 16 bit jako nominalny wariant o małym wkładzie kwantyzacji,
- 1 MS/s jako rozsądny nominalny punkt dla AAF 150 kHz,
- nieakceptowalne 100 kS/s,
- otwarty problem koherentnego biasu kwantyzacji / fs, szczególnie przy 2 MS/s.

Szczegóły: `docs/VALIDATION_V5.md`.
