# Walidacja FOG v8.1 - integrated optical closed-loop

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v8.1 zamyka pętlę przez pełny tor optyczny: source/front-end/Sagnac/photoreceiver/ADC/digital lock-in/PI/NCO/feedback actuator.

## 1. Integrated controller sweep @20 deg/s

| PI BW | feedback mean [deg/s] | feedback error [deg/s] | residual mean [deg/s] | residual STD [deg/s] | settling 2% |
|---:|---:|---:|---:|---:|---:|
| 30 Hz | 19.998673 | -1.327e-3 | 1.615e-3 | 1.553e-3 | 24.7 ms |
| 50 Hz | 19.999919 | -8.108e-5 | 1.851e-6 | 5.066e-6 | 14.1 ms |
| 100 Hz | 20.000004 | +3.941e-6 | 1.595e-9 | 1.657e-6 | 12.9 ms |

Interpretacja:
- 30 Hz jest wyraźnie zbyt wolne dla krótkiego okna testu i pozostawia istotny residual.
- 50 Hz działa stabilnie i daje bardzo mały residual.
- 100 Hz również działa stabilnie i w deterministic/no-noise sweep daje najmniejszy residual, ale v8 baseband pokazało większą podatność na szum dla wyższego BW.

Nominalny 50 Hz pozostaje rozsądnym kompromisem między settling i noise.

## 2. Full optical step tests

PI = 50 Hz:

### 1 deg/s
- feedback = 0.999917876 deg/s
- feedback error = -8.212e-5 deg/s
- residual mean = 1.335e-6 deg/s
- closed-loop estimate = 0.999919217 deg/s
- estimate error = -8.078e-5 deg/s
- settling = 14.1 ms
- selected actuator reset = 0.24447 kHz
- phase slope = -7680.30 rad/s.

### 20 deg/s
- feedback = 19.999918918 deg/s
- feedback error = -8.108e-5 deg/s
- residual mean = 1.851e-6 deg/s
- closed-loop estimate = 19.999920779 deg/s
- estimate error = -7.922e-5 deg/s
- settling = 14.1 ms
- selected actuator reset = 4.88981 kHz
- phase slope = -1.53618e5 rad/s.

## 3. Small-signal closed-loop Monte Carlo

Warunki:
- N=20 zero + N=20 signal,
- target = 0.0001 deg/s,
- full photoreceiver noise,
- random static SMF polarization,
- Lyot residual proxy = 0.017452,
- 20 ms averaging window after settling.

Wynik feedback rate word:
- zero mean = -5.533e-6 deg/s,
- zero sigma = 1.455e-5 deg/s = 0.05238 deg/h,
- signal mean = 9.8869e-5 deg/s,
- signal sigma = 1.7831e-5 deg/s,
- signal bias = -1.131e-6 deg/s,
- zero/signal separation = **6.415 sigma**.

To jest bardzo mocny wynik w ramach modelu. Należy jednak pamiętać, że:
- N=20 jest umiarkowaną statystyką,
- okno uśredniania wynosi 20 ms, więc nie należy porównywać 1:1 z wcześniejszymi testami 10 ms,
- reset glitch wybranego fizycznego PZT nie jest jeszcze wprowadzony do optycznego przebiegu czasowego.

## 4. Residual channel

Residual DSP po zamknięciu pętli pozostaje mały:
- zero residual mean ~3.49e-6 deg/s, STD ~6.11e-6 deg/s,
- signal residual mean ~2.87e-6 deg/s, STD ~6.96e-6 deg/s.

To potwierdza, że prędkość jest rzeczywiście przeniesiona głównie do feedback rate word, zgodnie z ideą closed-loop FOG.

## 5. Selected actuator bridge

Nominalny kandydat:
- low-Vpi long-range all-fiber PZT benchmark,
- Vpi = 4.5 V,
- driver = 50 Vpp,
- 5 pełnych 2pi przed resetem,
- BW = 20 kHz,
- ideal reset-limited Omega max = 23.372 deg/s,
- reset @20 deg/s = 4.8898 kHz,
- required BW = 17.114 kHz,
- capacitance benchmark = 0.18 uF,
- linear ramp current ~39.6 mA,
- reset peak current proxy ~396 mA,
- 32-bit NCO, rate-word LSB ~1.905e-7 deg/s.

## 6. Wniosek projektowy

v8.1 potwierdza, że architektura full optical closed-loop jest wykonalna w modelu i nie degraduje small-signal detection.

Najważniejsze ryzyko przestaje leżeć w regulatorze, ADC czy samym torze optycznym. Pozostaje w **fizycznej realizacji phase-ramp/reset**:
- realne Vpi,
- realny phase range,
- current/slew drivera,
- reset glitch,
- rezonanse PZT.

Dlatego kolejny krok nie powinien być kolejnym coraz bardziej idealizowanym symulatorem regulatora. Powinien być pomiarem konkretnego aktuatora i drivera oraz pierwszym open/closed-loop POC.

## Dane

- results/v8_1/FOG_v8_1_integrated_controller.csv
- results/v8_1/FOG_v8_1_step_tests.csv
- results/v8_1/FOG_v8_1_small_signal_mc.csv
- results/v8_1/FOG_v8_1_selected_actuator.csv