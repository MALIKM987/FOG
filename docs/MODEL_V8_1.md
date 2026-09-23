# FOG v8.1 - integrated optical closed-loop

## Cel

v8.1 łączy dwie wcześniej osobno zweryfikowane części projektu:

- fizyczny tor optyczny / photoreceiver / ADC / digital lock-in z v6.x,
- closed-loop PI / phase-ramp feasibility z v8.

Model nie jest już samym basebandowym autopilotem. Residual używany przez regulator pochodzi z pełnego toru:

`SLD -> Front End -> Sagnac -> Photoreceiver -> ADC -> Digital Lock-In`.

## Top-level

Docelowy widok:

`Optical Source -> Optical Front End -> Sagnac Interferometer -> Photoreceiver -> ADC AFE -> Digital Lock-In DSP`

a następnie:

`Digital Lock-In DSP -> Closed Loop Controller -> Feedback Phase Actuator -> Sagnac Interferometer`.

## Feedback phase

Regulator steruje równoważną prędkością feedback `Omega_fb`.

Actuator przelicza ją na różnicową fazę:

`Delta_phi_fb = -K_sag * Omega_fb * pi/180`.

Jest to dokładny efekt idealnej rampy fazy spełniającej:

`phi_fb(t)-phi_fb(t-tau) = slope*tau`.

v8.1 nie wprowadza sztucznego stałego phase offset jako niezależnego zjawiska. Faza feedback jest interpretowana jako równoważny wynik serrodyne/phase-ramp.

## Co nadal nie jest modelowane

Sam kształt szybkiego resetu o wielokrotność 2pi nie jest wstawiany do optycznego toru czasowego.

Powody:

- realny reset zależy od konkretnego PZT/drivera,
- v8 pokazało reset currents rzędu setek mA dla low-Vpi fiber-PZT benchmarku,
- glitch musi zostać zmierzony eksperymentalnie.

v8.1 loguje wymaganą reset frequency dla wybranego aktuatora i korzysta z feasibility gate v8.

## Nominalny actuator candidate

Do integracji przyjęto benchmark:

- low-Vpi long-range all-fiber PZT,
- Vpi = 4.5 V design value,
- driver 50 Vpp,
- 5 pełnych cykli 2pi przed resetem,
- bandwidth = 20 kHz,
- capacitance = 0.18 uF benchmark.

Z v8:

- reset @20 deg/s około 4.89 kHz,
- wymagane BW dla 10% resetu około 17.11 kHz,
- ideal reset-limited range około 23.37 deg/s,
- reset peak current proxy około 0.396 A.

Controller limit w v8.1 jest więc ustawiony na około +/-23 deg/s, a nie sztuczne +/-25 deg/s.

## Digital control

- controller update = 10 kHz,
- Kp = 0.5,
- nominal PI bandwidth = 50 Hz,
- sweep integrated = 30 / 50 / 100 Hz,
- 32-bit NCO rate-word quantization,
- 1 MS/s NCO/DAC reference rate.

Nie dokładamy drugiego 300 Hz measurement LPF przed PI, ponieważ pełny `Digital Lock-In DSP` już zawiera swój zweryfikowany filtr 300 Hz.

## Physical optical assumptions

v8.1 zachowuje:

- 1 km standard SMF,
- physical Lyot residual proxy = 0.017452 z v6.2,
- polarizer ER 25 dB w modelu,
- 20 kHz dither, beta=1.84,
- 16-bit ADC / 1 MS/s,
- AAF 100 kHz,
- photoreceiver noise v4/v5.

## v8.1A - integrated controller sweep

Pełny optyczny model testuje step 20 deg/s dla PI:

- 30 Hz,
- 50 Hz,
- 100 Hz.

Raportuje:

- mean feedback,
- feedback error,
- residual mean/STD,
- settling 2%,
- reset frequency selected actuator,
- equivalent differential feedback phase.

## v8.1B - 1 i 20 deg/s

Nominalny PI 50 Hz jest sprawdzany dla:

- 1 deg/s,
- 20 deg/s.

Logowane są:

- feedback output,
- residual lock-in output,
- suma feedback + residual jako diagnostic closed-loop estimate,
- settling,
- phase slope,
- reset frequency.

## v8.1C - 0.0001 deg/s pod pełnym szumem

Monte Carlo:

- N=20 zero,
- N=20 signal,
- target 0.0001 deg/s,
- full photoreceiver noise,
- random static SMF polarization states,
- physical Lyot proxy 0.017452.

Główną metryką closed-loop jest feedback rate word, ponieważ w docelowym FOG prędkość jest odczytywana przede wszystkim z sygnału kompensacji.

Residual DSP jest raportowany osobno.

## Pliki wynikowe

- FOG_v8_1.slx
- FOG_v8_1_integrated_controller.csv
- FOG_v8_1_step_tests.csv
- FOG_v8_1_small_signal_mc.csv
- FOG_v8_1_selected_actuator.csv

## Kryterium walidacji

v8.1 można zamknąć, jeśli:

1. pełny model śledzi 1 deg/s bez znaczącego biasu,
2. pełny model śledzi 20 deg/s bez saturacji regulatora,
3. reset frequency pozostaje zgodna z selected actuator gate v8,
4. small-signal closed-loop nie degraduje dramatycznie wcześniejszej detekcji 0.0001 deg/s,
5. 30/50/100 Hz integrated sweep pozostaje stabilny przynajmniej wokół nominalnego 50 Hz.

## Status

Implementacja gotowa do lokalnej walidacji.