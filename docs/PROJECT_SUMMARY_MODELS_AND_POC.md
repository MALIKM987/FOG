# Podsumowanie modeli matematycznych i projektu POC FOG

## 1. Cel projektu

Projekt dotyczy interferometrycznego żyroskopu światłowodowego (IFOG) opartego na efekcie Sagnaca, z cyfrową demodulacją, kompensacją błędów oraz przygotowaniem do budowy fizycznego POC.

Założenia robocze:
- lambda około 1550 nm,
- cewka około 1000 m standardowego SMF,
- średnica efektywna około 159.4 mm,
- modulacja fazy 20 kHz, beta około 1.84 rad,
- InGaAs photodiode + TIA,
- ADC nominalnie 16 bit / 1 MS/s,
- digital lock-in,
- docelowo closed-loop z phase-ramp feedback.

## 2. Rdzeń matematyczny

Faza Sagnaca:
`Delta_phi_S = (2*pi*L*D/(lambda*c))*Omega`.

Dla aktualnej geometrii:
- K_sag około 2.1553 rad/(rad/s),
- tau około 4.897 us.

Modulacja pojedynczym phase shifterem:
`Delta_phi_m(t)=phi_m(t)-phi_m(t-tau)`

oraz:
`beta = 2*phi0*|sin(pi*f_mod*tau)|`.

Przy 20 kHz i beta=1.84:
`phi0 około 3.04 rad`.

## 3. Ewolucja modeli

### v1
Deterministyczny Sagnac + interferencja + lock-in + linear/asin readout.

### v2 / v2.1
Rzeczywisty delay CW/CCW i phase shifter. Poprawiono lock-in i czas uśredniania.

### v3 / v3.1
Bilans mocy i straty optyczne oraz test zbieżności solvera.

### v4 / v4.1
Photodiode/TIA noise: shot, dark, Johnson, op-amp. Monte Carlo i zależność od czasu uśredniania.

### v5 / v5.1
ADC, AAF, sampling, quantization, fully digital lock-in. Wynik roboczy: 16 bit / 1 MS/s, minimum 14 bit, AAF około 100 kHz jako kandydat.

### v6 / v6.1
Standard SMF, polarization visibility/phase sensitivity, threshold wymaganej kontroli polaryzacji.

### v6.2
Fizyczny Lyot depolarizer: PM fiber, spectrum, Jones/Stokes, DOP proxy. Wybrany wariant: L1=1.7 m, L2=3.4 m, około 6 m PM1550 do zakupu, 45 deg +/-0.5 deg.

### v6.3
Optical BOM lock: source, couplers, polarizer, phase shifter, coil geometry, photodiode/TIA i plan acceptance tests.

### v7
Uniform thermal drift + pure Shupe + former screening + two-sensor temperature compensation. Provisional former: Invar36.

### v7.1
Thermo-mechanical stress / T-dot / winding / potting gate. Model przygotowany, ale wymaga lokalnego uruchomienia i późniejszej kalibracji prototypem.

### v8
Closed-loop feasibility: phase-ramp/reset, actuator bandwidth, Vpi, driver, NCO/DAC, PI.

### v8.1
Integrated optical closed-loop: pełny optical chain -> RX -> ADC -> DSP -> PI/NCO -> feedback actuator -> Sagnac.

## 4. Najważniejsze wyniki

- v1: asin correction usuwa większość nieliniowości open-loop.
- v3: przy 1 mW źródła peak detector power około 90.8 uW.
- v4: modelowany RX noise około 47.7 uV RMS; shot noise dominuje przy przyjętych założeniach.
- v4.1: zero-rate sigma około 0.0549 deg/h przy 20 ms averaging.
- v5.1: 14 bit jest pierwszym sensownym minimum; 16 bit preferowane.
- v6.1: modelowy residual około 0.05 daje >3 sigma punktowo; 0.025 jest bezpieczniejszym celem modelowym.
- v6.2: Lyot 1.7 m + 3.4 m daje residual proxy około 0.01745.
- v6.3: geometria 1000 m SMF -> około 18 warstw, ~1997 zwojów, mean diameter ~159.395 mm.
- v7: Invar36 przechodzi obecny combined thermal screening; fast ramps wymagają aktywnej kompensacji.
- v8: low-Vpi long-range PZT candidate przechodzi ideal reset feasibility, high-Vpi class nie przechodzi +/-20 deg/s przy 50 Vpp.
- v8.1: full optical closed-loop śledzi 1 i 20 deg/s; nominalne 50 Hz PI daje ~14.1 ms settling; small-signal test 0.0001 deg/s daje ~6.42 sigma w konkretnym modelu i oknie 20 ms.

## 5. Roboczy POC

Architektura:
`SLD -> K1 -> polarizer / Lyot -> K2 -> 1 km SMF loop + phase shifter -> K2 -> K1 -> InGaAs PD -> TIA -> AAF -> ADC -> digital lock-in`.

Closed-loop:
`digital lock-in residual -> PI/NCO -> DAC/driver -> feedback phase actuator -> Sagnac`.

## 6. Optical BOM - wymagania robocze

- source: 1550 nm, najpierw zmierzyć źródło laboratoryjne; target około 0.8-1.0 mW na K1,
- K1/K2: 2x2 SM, 50:50 +/-5%, low excess loss / PDL,
- polarizer: ER >=25 dB, preferred >=30 dB,
- Lyot: PM1550 PANDA, beat length <=5 mm; 1.7 m + 3.4 m; target splice 45 deg +/-0.5 deg,
- coil: 1000 m G.652.D / SMF-28 class,
- photodiode: InGaAs, R >=0.8 A/W,
- TIA: około 20 kOhm, >=200 kHz,
- ADC: 16 bit preferred, 1 MS/s,
- AAF: około 100 kHz,
- phase shifter open-loop: beta=1.84 @20 kHz.

## 7. Thermal / mechanical requirements

- provisional former: Invar36,
- symmetric/quadrupolar winding,
- two temperature sensors INNER/OUTER,
- Pt100/Pt1000 Class A minimum, AA preferred, 4-wire,
- thermal enclosure tau >=60 s with active compensation,
- filtered temperature-noise target <=0.01 C RMS, preferred <=0.005 C RMS,
- final adhesive/potting NOT locked before thermal-ramp measurement.

## 8. Closed-loop requirements

Nominalny candidate z v8/v8.1:
- low-Vpi long-range all-fiber PZT benchmark,
- Vpi design ~4.5 V,
- driver ~50 Vpp,
- 5 x 2pi cycles before reset,
- 20 kHz actuator BW,
- reset ~4.89 kHz at 20 deg/s,
- required ideal reset BW ~17.1 kHz,
- capacitance benchmark ~0.18 uF,
- reset-current proxy ~0.4 A,
- NCO 32 bit preferred,
- DAC >=1 MS/s, 16 bit preferred,
- PI nominal around 50 Hz.

## 9. Co jest jeszcze otwarte

- real spectrum/power lab SLD,
- real K1/K2 parameters,
- real PD/TIA linearity/noise,
- real Vpi/phase range/capacitance/frequency response phase shiftera,
- real reset glitch i driver current,
- final former/potting after thermo-mechanical calibration,
- long-term bias stability / Allan-type measurements on hardware.

## 10. Zasada dalszej pracy

Od v8.1 dalszy rozwój powinien przede wszystkim kalibrować modele danymi z pierwszego prototypu:

`model -> requirement -> hardware -> measurement -> calibrated model -> final BOM`.