# Model FOG v6 - standard SMF, polaryzacja i depolaryzator

## Cel

v6 jest pierwszym etapem, w którym zwykła cewka jednomodowa nie jest traktowana jako idealnie zachowująca polaryzację.

Model zachowuje zweryfikowane elementy v5.1:

- 1 km cewki,
- modulację PZT 20 kHz,
- fotodiodę InGaAs i TIA,
- szumy fotodetektora,
- ADC,
- cyfrowy lock-in.

Dodana zostaje zależność interferencji od stanu polaryzacji.

## Bardzo ważne ograniczenie

v6 jest **modelem wrażliwościowym**, nie pełnym rozproszonym modelem propagacji Jonesa po 1 km włókna.

Parametry:

- `depol_residual`,
- `pol_nr_scale`,
- amplitudy i szybkości zmian `theta` i `delta`

nie są jeszcze danymi konkretnego elementu BOM.

Ich zadaniem jest odpowiedzieć:

**jak bardzo układ jest wrażliwy na niedoskonałą polaryzację i jak skuteczne musi być jej tłumienie, aby zwykłe SMF miało sens w prototypie?**

## Architektura

Na poziomie głównym pozostaje fizyczna architektura:

```text
Optical Source
      |
Optical Front End
K1 + polarizer + depolarizer
      |
Sagnac Interferometer
K2 + 1 km standard SMF + PZT
      |
Photoreceiver
      |
ADC AFE
      |
Digital Lock-In DSP
      |
Omega
```

Wewnątrz `Sagnac Interferometer` dodano subsystem:

`SMF Polarization`.

Dodatkowo logowane są:

- `V_pol(t)` - efektywna widzialność interferencji,
- `phi_pol(t)` - dodatkowa faza polaryzacyjna.

## Model Jones-equivalent

Wprowadzane są dwa parametry względnego stanu CW/CCW:

`theta(t)` - mieszanie osi polaryzacji,

`delta(t)` - względna faza dwójłomności.

Modelowany overlap:

```text
Gamma = cos^2(theta) + sin^2(theta) exp(j 2 delta)
```

Stąd:

`V_raw = |Gamma|`

oraz:

`phi_raw = arg(Gamma)`.

W implementacji zakres theta/delta jest ograniczony tak, aby część rzeczywista overlap pozostawała dodatnia i wystarczało stabilne `atan(Im/Re)`.

## Polaryzator

Nominalnie przyjęto:

`ER = 25 dB`.

Z tego wyznaczana jest robocza widzialność kalibracyjna:

`V_cal = (1-r)/(1+r)`

gdzie:

`r = 10^(-ER/10)`.

DSP jest kalibrowany do `V_cal`, dlatego sam stały ER nie powinien generować błędu skali w wariancie idealnej polaryzacji.

ER = 25 dB jest założeniem modelowym, nie zatwierdzonym jeszcze parametrem BOM.

## Depolaryzator

Wprowadzono parametr:

`depol_residual`.

Interpretacja modelowa:

- `1.0` - brak tłumienia wrażliwości polaryzacyjnej,
- `0.0` - idealne usunięcie badanego efektu,
- `0.1` - nominalny punkt badawczy v6.

Nie należy utożsamiać `depol_residual` bezpośrednio z DOP z karty katalogowej.

Widzialność:

```text
V_pol =
V_cal [1 - depol_residual (1 - V_raw)]
```

przy aktywnym modelu polaryzacji.

## Polarization phase bias

Nie cała faza overlap jest traktowana jako nieodwracalny błąd żyroskopu.

Model przyjmuje:

```text
phi_pol =
depol_residual * pol_nr_scale * phi_raw
```

z nominalnym:

`pol_nr_scale = 2e-4`.

To parametr fenomenologiczny.

Bez kalibracji eksperymentalnej nie wolno interpretować wynikowej wartości biasu v6 jako przewidywanej dokładności fizycznego FOG.

## Interferencja

v5:

```text
P ~ 1 + V cos(phi_S + delta_phi_m)
```

v6:

```text
P ~ 1 + V_pol(t)
        cos(phi_S + delta_phi_m + phi_pol(t))
```

Dzięki temu polaryzacja może wpływać jednocześnie na:

- kontrast,
- scale factor,
- zero-rate bias,
- stabilność wskazania.

## Konfiguracja cyfrowa

Po v5.1 do v6 przenosimy roboczo:

- ADC 16 bit,
- 1 MS/s,
- 0...2 V,
- f_mod = 20 kHz,
- cyfrowy LPF = 300 Hz,
- AAF = 100 kHz, Butterworth 4. rzędu.

AAF = 100 kHz pozostaje kandydatem roboczym, nie ostatecznym elementem BOM.

## v6A - test regresji idealnej polaryzacji

Ustawiane:

`pol_enable = 0`.

Wtedy:

- `V_pol = V_cal`,
- `phi_pol = 0`.

Test sprawdza, czy samo dodanie modelu polaryzacji nie psuje zweryfikowanego toru FOG.

## v6B - sweep skuteczności depolaryzatora

Testowane:

```text
1.0
0.5
0.2
0.1
0.05
0.0
```

Dla każdej wartości zapisywane są:

- średnia/minimum/STD widzialności,
- średnia/STD/maksimum fazy polaryzacyjnej,
- zero-rate mean i STD,
- wskazanie przy 1 deg/s,
- błąd skali.

Zmiany theta/delta są celowo przyspieszone, aby ich wpływ był widoczny w krótkiej symulacji. Częstotliwości nie reprezentują widma prawdziwej temperatury lub drgań cewki.

## v6C - Monte Carlo losowych stanów SMF

Dla jednej realizacji stan jest statyczny.

Pomiędzy realizacjami losowane są:

- `theta0` z zakresu około +/-30 stopni,
- `delta0` z zakresu około +/-0.5 rad.

Testowane residual:

- 1.0,
- 0.2,
- 0.1,
- 0.05.

Każdy przypadek ma 20 realizacji z pełnym szumem Photoreceivera.

Zapisywane są:

- mean,
- STD,
- RMS,
- mediana wartości bezwzględnej,
- 95 percentyl wartości bezwzględnej,
- maksimum,
- średnia widzialność.

## v6D - detekcja z losowym SMF

Dla nominalnego:

`depol_residual = 0.1`

badany jest ponownie sygnał:

`Omega = 0.0001 deg/s`.

Wykonywane są:

- 30 realizacji klasy zero,
- 30 realizacji klasy sygnałowej.

Celem jest sprawdzenie, czy czułość uzyskana w v5.1 przetrwa po dodaniu niepewności polaryzacyjnej.

## Pliki wynikowe

- `FOG_v6.slx`
- `FOG_v6_baseline.csv`
- `FOG_v6_depolarizer_sweep.csv`
- `FOG_v6_smf_monte_carlo.csv`
- `FOG_v6_detection_random_smf.csv`
- `FOG_v6_model_parameters.csv`

## Co rozstrzyga v6

v6 ma powiedzieć, czy koncepcja taniego prototypu z 1 km zwykłego SMF jest wystarczająco odporna na polaryzację **w ramach przyjętego modelu**.

Jeżeli nie:

1. zwiększamy skuteczność depolaryzacji,
2. kalibrujemy błąd polaryzacyjny,
3. rozważamy bardziej rozbudowany depolaryzator,
4. albo wracamy do większego udziału włókna PM.

## Następny krok po walidacji

Po v6 należy zdecydować, czy:

- potrzebne jest v6.1 z kalibracją / sweepem `pol_nr_scale`,
- czy można przejść do v7: temperatura i dryft.

## Status

**Model wrażliwościowy zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Najważniejszy wynik:
- `depol_residual = 0.1` daje dla `0.0001 deg/s` separację tylko około `2.42 sigma`,
- modelowy residual `0.05` obniża zero-rate sigma do około `0.0865 deg/h`,
- wpływ polaryzacji staje się dominującym ograniczeniem względem wcześniej zweryfikowanego toru ADC/Photoreceivera.

Wymagane v6.1 przed przejściem do temperatury:
- detection sweep residual,
- paired Monte Carlo,
- sweep `pol_nr_scale`.

Szczegóły: `docs/VALIDATION_V6.md`.
