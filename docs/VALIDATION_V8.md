# Walidacja FOG v8 - closed-loop feasibility / actuator / DAC

## Status

**Zweryfikowany lokalnie w MATLAB/Simulink R2023b Update 7.**

v8 poprawnie zamknęło model baseband closed-loop oraz wymagania phase-ramp/reset dla pełnej skali +/-20 deg/s.

## 1. Phase-ramp scale

- K_sag = 2.155265614 rad/(rad/s)
- tau = 4.897388 us
- slope = 7680.927 rad/s per deg/s
- 2pi phase rate = 1222.458 Hz per deg/s
- przy 20 deg/s: 24.449 kHz

## 2. Reset bandwidth

| phase span | reset @20 deg/s | required BW for 10% reset |
|---:|---:|---:|
| 1 x 2pi | 24.449 kHz | 85.572 kHz |
| 2 x 2pi | 12.225 kHz | 42.786 kHz |
| 4 x 2pi | 6.112 kHz | 21.393 kHz |
| 8 x 2pi | 3.056 kHz | 10.697 kHz |

## 3. Actuator feasibility

High-Vpi 20 kHz fiber PZT, Vpi=20 V, 50 Vpp:
- only 1 usable 2pi cycle
- ideal reset-limited range only about 4.67 deg/s
- FAIL for +/-20 deg/s.

Low-Vpi 20 kHz long-range fiber PZT benchmark, Vpi=4.5 V, 50 Vpp:
- 5 usable 2pi cycles
- reset ~4.89 kHz at 20 deg/s
- required BW ~17.11 kHz
- ideal range ~23.37 deg/s
- PASS in ideal reset model
- modeled linear-ramp current ~39.6 mA
- modeled reset peak current ~396 mA for 0.18 uF and 10% reset.

Fast LiNbO3 class passes with enormous bandwidth margin.

## 4. PZT driver trade-off

Examples:
- Vpi 4.5 V, 40 Vpp -> about 18.70 deg/s, FAIL full scale
- Vpi 4.5 V, 50 Vpp -> about 23.37 deg/s, PASS
- Vpi 10 V, 100 Vpp -> about 23.37 deg/s, PASS
- Vpi 20 V, even 150 Vpp -> about 14.02 deg/s, FAIL in the assumed 20 kHz / 10% reset model.

Therefore voltage range and Vpi must be considered together with actuator bandwidth.

## 5. NCO / DAC

At 1 MS/s:
- 24-bit phase accumulator LSB ~4.88e-5 deg/s
- 28-bit ~3.05e-6 deg/s
- 32-bit ~1.90e-7 deg/s.

At 20 deg/s and 1 MS/s there are about 40.9 DAC updates per optical 2pi interval.

Working digital requirement:
- >=1 MS/s update
- >=28-bit NCO minimum
- 32-bit preferred
- waveform DAC >=14-bit minimum, 16-bit preferred.

## 6. Baseband PI

All tested 10/30/50/100 Hz controller points were stable without saturation for 1 and 20 deg/s.

Nominal 50 Hz:
- settling ~15.4 ms
- residual RMS about 4.94e-5 deg/s at 1 deg/s
- residual RMS about 5.22e-5 deg/s at 20 deg/s in the injected-noise baseband test.

100 Hz is faster (~7 ms) but shows higher noise RMS.

50 Hz remains the working compromise.

## 7. Simulink baseline

For a 20 deg/s step with 50 Hz PI:
- feedback mean = 20 deg/s
- residual mean = 0
- phase slope = -1.5362e5 rad/s
- raw 2pi phase rate = 24.449 kHz.

The generated FOG_v8.slx is intentionally a control/feasibility model, not the full optical interferometer.

## 8. Design conclusion

v8 changes the BOM conclusion:

- FPS-001/high-Vpi class remains useful for open-loop/dither but is not sufficient for full +/-20 deg/s closed-loop with the assumed 50 Vpp driver.
- low-Vpi long-range fiber-PZT class is potentially sufficient and is the preferred all-fiber closed-loop candidate pending reset-current/glitch tests.
- LiNbO3 remains the fast fallback.

## 9. Next step

v8.1 should integrate the controller into the previously validated optical chain:

source -> front-end -> Sagnac + feedback phase -> photoreceiver -> ADC -> digital lock-in -> PI -> feedback actuator.

The integrated model should verify deterministic 1/20 deg/s tracking and low-rate/noise behavior with the actual optical detector/DSP path.

## Data

- results/v8/FOG_v8_phase_ramp_requirement.csv
- results/v8/FOG_v8_actuator_feasibility.csv
- results/v8/FOG_v8_pzt_driver_tradeoff.csv
- results/v8/FOG_v8_nco_requirements.csv
- results/v8/FOG_v8_dac_quantization.csv
- results/v8/FOG_v8_controller_sweep.csv
- results/v8/FOG_v8_simulink_baseline.csv
- results/v8/FOG_v8_closed_loop_bom.csv
- results/v8/FOG_v8_acceptance_tests.csv