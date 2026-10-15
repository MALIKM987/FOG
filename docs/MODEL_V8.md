# FOG v8 - closed-loop feasibility, actuator i DAC BOM

## Cel

v8 sprawdza, czy przejście z open-loop do closed-loop ma sens dla naszej cewki i czy zmienia wymagania zakupowe modulatora fazy.

Nie zastępuje v7.1. Oba etapy są niezależne:

- v7.1 domyka thermo-mechanical construction gate,
- v8 domyka closed-loop actuator / DAC / controller feasibility.

## 1. Fizyczna zasada feedback

Feedback phase musi być nieodwracalny dla dwóch fal CW/CCW. Stałe przesunięcie fazy nie wystarcza.

Dla rampy fazy:

`phi_fb(t) = slope * t`

otrzymujemy:

`Delta_phi_fb = slope * tau`.

Warunek kompensacji:

`K_sag * Omega_rad_s + slope*tau = 0`.

Dla naszej geometrii około 159.395 mm i 1 km:

- K_sag około 2.1553 rad/(rad/s),
- tau około 4.897 us,
- phase-ramp slope około 7681 rad/s na 1 deg/s,
- 2pi optical phase rate około 1222.46 Hz na 1 deg/s,
- przy 20 deg/s około 24.45 kHz.

To ostatnie jest kluczowe dla doboru modulatora.

## 2. Serrodyne / reset

Jeśli modulator ma skończony zakres fazy, rampa musi być resetowana o całkowitą wielokrotność 2pi.

Dla N pełnych cykli 2pi przed resetem:

`f_reset = f_2pi / N`.

v8 przyjmuje projektowo, że reset powinien zajmować nie więcej niż 10% okresu. Używając przybliżenia rise-time:

`t_r ~= 0.35/BW`

dostajemy wymagane pasmo:

`BW >= 0.35*f_reset/0.10`.

To jest kryterium inżynierskie, nie dokładny model rezonansów PZT.

## 3. Dlaczego Vpi samo nie wystarcza

Liczba dostępnych pełnych cykli fazy jest ograniczona przez:

`N = floor(Vpp_driver / (2 Vpi))`.

Przykład:

- Vpi=20 V, driver=50 Vpp -> tylko 1 pełny cykl 2pi,
- Vpi=4.5 V, driver=50 Vpp -> 5 pełnych cykli.

Większy zakres fazy obniża reset frequency i może uratować wolniejszy PZT.

## 4. Current fiber-PZT benchmarks

### FPS-001 class

Current benchmark:

- DC-20 kHz,
- Vpi <20 V,
- phase range >8pi,
- very low IL/PDL/RAM.

Z driverem tylko 50 Vpp jest jednak ograniczony przez dostępny zakres napięcia, a nie katalogowy mechaniczny phase range.

### FPS-002 class

Current low-Vpi/long-range benchmark:

- DC-20 kHz,
- 2.5-4.5 V typ Vpi small frame,
- >65pi phase range,
- piezo capacitance około 0.18 uF.

To jest znacznie ciekawszy kandydat closed-loop niż high-Vpi FPS-001, ale reset current i rezonanse muszą być zmierzone.

### Fast LiNbO3 class

Jeżeli fiber PZT nie przejdzie reset testu, szybki LiNbO3 phase modulator ma ogromny zapas bandwidth i niskie Vpi, ale zwykle wnosi większe insertion loss, wyższy koszt i bardziej rygorystyczną polaryzację.

## 5. NCO / DAC

Closed-loop readout powinien opierać się na cyfrowym phase accumulator / frequency word, a nie na samej rozdzielczości napięciowej DAC.

v8 liczy:

- rate-word LSB dla 24/28/32-bit accumulator,
- samples per optical 2pi phase interval przy 20 deg/s,
- DAC voltage/phase LSB dla 12/14/16 bit.

Roboczo:

- >=1 MS/s DAC update,
- >=14 bit waveform DAC minimum, 16 bit preferred,
- >=28 bit phase accumulator minimum, 32 bit preferred.

## 6. Baseband controller

Model controllera jest celowo wolniejszy od phase-ramp waveform.

Nominalnie:

- controller update 10 kHz,
- measurement LPF 300 Hz,
- actuator baseband response 2 kHz,
- Kp=0.5,
- PI bandwidth sweep 10/30/50/100 Hz,
- feedback command limit +/-25 deg/s.

Symulowany jest step 1 deg/s i 20 deg/s z ekwiwalentnym rate noise.

To rozdziela dynamikę regulatora od szybkiego problemu resetu phase ramp.

## 7. FOG_v8.slx

Skrypt generuje uproszczony, jawny model baseband closed-loop:

`Rotation -> residual -> measurement LPF -> PI -> limit -> actuator -> feedback`

oraz loguje:

- true Omega,
- residual Omega,
- feedback Omega,
- phase-ramp slope,
- ideal 2pi reset frequency.

Model ten nie duplikuje pełnej optyki v6/v7, bo ta została już osobno zweryfikowana. Jego zadaniem jest projekt feedback architecture.

## 8. BOM outputs

v8 generuje wymagania dla:

- closed-loop phase actuator,
- actuator driver,
- DAC,
- NCO / DDS accumulator,
- controller update rate,
- command range,
- reset waveform,
- common clock.

## 9. Acceptance gate

Przed zakupowym lockiem closed-loop trzeba zmierzyć:

- Vpi konkretnego modulatora,
- phase range,
- ramp linearity,
- reset glitch,
- current podczas resetu,
- full-scale equivalent phase rate,
- closed-loop step 1 i 20 deg/s.

## 10. Znaczenie dla pierwszego POC

v8 nie powinno opóźniać pierwszego open-loop POC.

Jeśli closed-loop wymaga innego modulatora, open-loop PZT nadal pozostaje wartościowy do:

- uruchomienia interferometru,
- dither modulation,
- kalibracji,
- diagnostyki.

## Pliki wynikowe

- FOG_v8_phase_ramp_requirement.csv
- FOG_v8_actuator_feasibility.csv
- FOG_v8_pzt_driver_tradeoff.csv
- FOG_v8_nco_requirements.csv
- FOG_v8_dac_quantization.csv
- FOG_v8_controller_sweep.csv
- FOG_v8_simulink_baseline.csv
- FOG_v8_closed_loop_bom.csv
- FOG_v8_acceptance_tests.csv
- FOG_v8.slx

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Wynik:
- 20 deg/s -> 24.449 kHz raw 2pi phase rate,
- high-Vpi 20 kHz / 50 Vpp fiber PZT fails full-scale reset criterion,
- low-Vpi 4.5 V / 50 Vpp long-range fiber PZT passes ideal reset model with ~23.37 deg/s range,
- estimated reset peak current ~0.396 A for 0.18 uF benchmark,
- 1 MS/s + 32-bit NCO gives rate-word resolution ~1.9e-7 deg/s,
- nominal baseband PI = 50 Hz, settling ~15.4 ms.

Szczegóły: `docs/VALIDATION_V8.md`.

Następny krok: v8.1 integrated optical closed-loop.