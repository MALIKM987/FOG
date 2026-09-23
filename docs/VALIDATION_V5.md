# Walidacja FOG v5 - ADC i cyfrowy lock-in

## Status

**Rdzeń v5 zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

Topologia cyfrowa działa poprawnie:

`Photoreceiver -> ADC AFE -> Digital Lock-In DSP`

Model poprawnie wykonuje próbkowanie, kwantyzację, cyfrową demodulację i filtrację. Walidacja ujawniła również dwa istotne zjawiska, które wymagają osobnego v5.1 przed uznaniem doboru ADC za ostateczny:

1. koherentny, niemonotoniczny błąd kwantyzacji dla bardzo małych sygnałów,
2. zależność biasu od częstotliwości próbkowania, szczególnie anomalię przy 2 MS/s.

## 1. Konfiguracja nominalna

- ADC: `16 bit`
- zakres: `0 ... 2 V`
- `f_s = 1 MS/s`
- LSB: `30.518 uV`
- AAF: Butterworth 4. rzędu, `150 kHz`
- cyfrowy LPF: Butterworth 4. rzędu, `300 Hz`
- modulacja: `20 kHz`

Model źródłowy zachowuje te założenia jako parametry projektowe, nie zatwierdzony BOM.

## 2. Headroom ADC

Dla `Omega = 1 deg/s`:

- minimum przed ADC: `0.577303 V`
- maksimum przed ADC: `1.620677 V`
- zapas do dolnego ograniczenia: `577.3 mV`
- zapas do górnego ograniczenia: `379.3 mV`

W nominalnym punkcie `0...2 V` nie występuje clipping.

## 3. Baseline 16 bit / 1 MS/s

Dla `Omega = 1 deg/s`, bez losowego szumu:

- `Omega_est = 0.999869155 deg/s`
- błąd: `-1.30845e-4 deg/s`
- STD w oknie: `1.642e-6 deg/s`

Dla porównania analogowy tor v4.1 w trybie STANDARD dawał błąd około:

`-4.31e-6 deg/s`.

Oznacza to, że w obecnym v5 dominujący dodatkowy bias jest związany z cyfryzacją / koherentną kwantyzacją / implementacją dyskretnego toru, a nie z częścią analogową.

## 4. Budżet kwantyzacji

| ADC | LSB [uV] | ASD kwantyzacji [nV/sqrtHz] | analog ASD [nV/sqrtHz] | przewidywany faktor szumu |
|---:|---:|---:|---:|---:|
| 8 bit | 7843 | 3201.9 | 84.68 | 37.83 |
| 10 bit | 1955 | 798.1 | 84.68 | 9.48 |
| 12 bit | 488.4 | 199.4 | 84.68 | 2.56 |
| 14 bit | 122.1 | 49.84 | 84.68 | 1.160 |
| 16 bit | 30.52 | 12.46 | 84.68 | 1.011 |

Analitycznie 14 bit powinno podnieść biały poziom szumu o około 16%, a 16 bit tylko o około 1%.

## 5. Deterministyczny sweep bitów

### Omega = 1 deg/s

- 8 bit: błąd `+8.14e-3 deg/s`
- 10 bit: `+3.56e-3 deg/s`
- 12 bit: `-3.29e-4 deg/s`
- 14 bit: `+1.22e-4 deg/s`
- 16 bit: `-1.31e-4 deg/s`

### Omega = 0.0001 deg/s

- 8 bit: sygnał praktycznie znika
- 10 bit: sygnał praktycznie znika
- 12 bit: sygnał praktycznie znika
- 14 bit: `Omega_est ~= 1.325e-4 deg/s`
- 16 bit: `Omega_est ~= 2.761e-5 deg/s`

Ten wynik **nie jest monotoniczny z liczbą bitów**. Nie oznacza to, że 16 bit jest gorsze od 14 bit.

Przy deterministycznym okresowym sygnale bez szumu błąd kwantyzacji jest skorelowany z sygnałem i zegarem ADC. Nie zachowuje się jak idealny biały szum. Zewnętrzny szum analogowy działa jak dither i zmienia statystykę kwantyzacji.

Dlatego dla małych prędkości ważniejszy jest Monte Carlo z pełnym szumem niż sam sweep deterministyczny.

## 6. Monte Carlo ADC

Dla `1 MS/s`, `Tavg = 10 ms`, po 30 realizacji:

| ADC | sigma [deg/s] | sigma [deg/h] | faktor vs analog v4.1 | predykcja |
|---:|---:|---:|---:|---:|
| 12 bit | 3.4675e-5 | 0.12483 | 1.734 | 2.558 |
| 14 bit | 2.3154e-5 | 0.08335 | 1.158 | 1.160 |
| 16 bit | 2.1459e-5 | 0.07725 | 1.073 | 1.011 |

14 bit bardzo dobrze zgadza się z prostą predykcją ASD.

Dla 16 bit różnica między wynikiem Monte Carlo i predykcją jest mała względem niepewności wynikającej z tylko 30 realizacji.

12 bit nie zachowuje się jak idealny biały model kwantyzacji. Kwantyzacja jest zbyt gruba względem analogowego ditheru i błąd pozostaje częściowo deterministyczny / skorelowany.

Orientacyjne 95% przedziały ufności dla sigma przy N=30:

- 12 bit: około `0.099 ... 0.168 deg/h`
- 14 bit: około `0.066 ... 0.112 deg/h`
- 16 bit: około `0.062 ... 0.104 deg/h`

Zatem różnicy 14 vs 16 bit nie należy jeszcze interpretować z nadmierną precyzją.

## 7. Roboczy próg 3-sigma z Monte Carlo

Z bieżących sigma:

- 12 bit: około `0.374 deg/h`
- 14 bit: około `0.250 deg/h`
- 16 bit: około `0.232 deg/h`

Analogowe v4.1 przy 10 ms:

- około `0.216 deg/h`.

Dla testowego sygnału `0.0001 deg/s = 0.36 deg/h` daje to orientacyjnie:

- 12 bit: poniżej 3-sigma,
- 14 bit: powyżej 3-sigma,
- 16 bit: powyżej 3-sigma.

To wskazuje, że 12 bit jest słabym kandydatem do obecnego celu małych prędkości, a 14-16 bit wymagają dalszej walidacji.

## 8. Sweep częstotliwości próbkowania

| fs [kS/s] | próbki / 20 kHz | TIA+AAF przy Nyquiście [dB] | błąd Omega [deg/s] |
|---:|---:|---:|---:|
| 100 | 5 | -0.26 | +0.805 |
| 200 | 10 | -1.14 | -7.59e-5 |
| 500 | 25 | -21.91 | -1.19e-4 |
| 1000 | 50 | -50.43 | -1.31e-4 |
| 2000 | 100 | -80.06 | +3.70e-4 |

### 100 kS/s

Jest nieakceptowalne w obecnej architekturze:

- tylko 5 próbek na okres modulacji,
- Nyquist = 50 kHz,
- AAF 150 kHz praktycznie nie tłumi przy Nyquiście,
- interferometryczny sygnał zawiera harmoniczne modulacji, które mogą aliasować do pasma pierwszej harmonicznej.

Duży błąd `+0.805 deg/s` jest zgodny z takim mechanizmem.

### 200 kS/s

Deterministycznie wynik jest dobry, ale filtr antyaliasingowy tłumi przy Nyquiście tylko około `1.14 dB` razem z TIA. Nie jest to bezpieczna konfiguracja dla rzeczywistego szerokopasmowego szumu.

### 500 kS/s

25 próbek/okres i około `-21.9 dB` przy Nyquiście. To konfiguracja możliwa do dalszego badania, ale ochrona przed aliasingiem nadal jest umiarkowana.

### 1 MS/s

50 próbek/okres i około `-50.4 dB` łącznego tłumienia przy Nyquiście. To rozsądny nominalny punkt v5.

### 2 MS/s

Ma najlepszy zapas antyaliasingowy, ale występuje błąd deterministyczny `+3.70e-4 deg/s`.

Ponieważ błąd nie maleje monotonicznie z fs, należy zbadać:

- koherentną relację zegara próbkowania do 20 kHz,
- fazę próbkowania,
- okresowy błąd kwantyzacji,
- wpływ współczynników cyfrowego LPF.

Nie należy interpretować 2 MS/s jako fizycznie gorszego ADC bez tego testu.

## 9. Wniosek projektowy v5

Na obecnym etapie:

- 8 i 10 bit można odrzucić dla zakładanej czułości,
- 12 bit jest wyraźnie gorsze i graniczne dla `0.0001 deg/s`,
- 14 bit jest pierwszym sensownym kandydatem,
- 16 bit pozostaje nominalnym wariantem modelu i daje najmniejszy oczekiwany wkład kwantyzacji,
- `1 MS/s` pozostaje rozsądną nominalną częstotliwością dla AAF = 150 kHz.

Nie jest to jeszcze wybór konkretnego ADC do BOM-u.

## 10. Następny krok v5.1

Przed przejściem do polaryzacji SMF warto wykonać krótką optymalizację cyfrowego toru:

1. Monte Carlo detekcji `0.0001 deg/s` dla 12/14/16 bit.
2. Więcej realizacji dla 14/16 bit.
3. Sweep fazy zegara ADC względem modulacji.
4. Sweep `f_s` pod szumem, szczególnie 500 kS/s, 1 MS/s, 2 MS/s.
5. Sweep AAF np. 80, 100, 150 kHz.
6. Dopiero po tym ustalić minimalną rozdzielczość i częstotliwość ADC.

## Dane źródłowe

- `results/v5/FOG_v5_baseline.csv`
- `results/v5/FOG_v5_adc_noise_budget.csv`
- `results/v5/FOG_v5_bit_sweep.csv`
- `results/v5/FOG_v5_fs_sweep.csv`
- `results/v5/FOG_v5_adc_monte_carlo.csv`
