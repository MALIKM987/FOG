# FOG v6.1 - próg wymaganej kontroli polaryzacji

## Cel

v6 wykazało, że dla modelowego:

`depol_residual = 0.1`

detekcja:

`0.0001 deg/s = 0.36 deg/h`

ma separację tylko około `2.42 sigma`.

v6.1 ma zamienić ten wynik w praktyczne wymaganie modelowe:

**jak mały musi być residual wpływu polaryzacji, aby standardowe SMF zachowało detekcję 3-sigma i 4-sigma?**

## Założenia

v6.1 nie zmienia fizycznej topologii v6.

Pozostają:

- 1 km standardowego SMF,
- polarizer ER = 25 dB jako założenie,
- ADC 16 bit,
- 1 MS/s,
- AAF 100 kHz,
- modulacja 20 kHz,
- cyfrowy lock-in.

Parametry:

- `depol_residual`,
- `pol_nr_scale`

pozostają fenomenologiczne.

Nie należy utożsamiać `depol_residual` bezpośrednio z katalogowym DOP.

## v6.1A - paired detection sweep

Testowane residual:

- 0.100,
- 0.075,
- 0.050,
- 0.025,
- 0.000.

Dla każdego punktu:

- 30 par zero/signal,
- `Omega_signal = 0.0001 deg/s`,
- te same stany SMF dla wszystkich residual,
- ten sam bank seedów szumu dla wszystkich residual,
- w parze zero/signal używany jest ten sam stan SMF i ten sam seed szumu.

Dzięki temu różnice między residual nie są maskowane przez losowanie innego zestawu przypadków.

### Dwie metryki

Raportowane są dwie różne miary.

### 1. Unpaired class separation

```text
|mean(signal)-mean(zero)| /
sqrt((sigma_zero^2 + sigma_signal^2)/2)
```

To jest główne kryterium detekcji.

Nie korzysta z anulowania common-mode w parze i lepiej reprezentuje rozróżnienie dwóch populacji pomiarów.

### 2. Paired delta

Dodatkowo liczona jest:

`Omega_signal_run - Omega_zero_run`

dla identycznego stanu SMF i identycznego seeda.

Ta metryka służy do oceny scale factor i części wspólnej błędu. Nie jest używana jako podstawowe kryterium minimalnej wykrywalnej prędkości.

## Kryteria

Wyznaczamy:

- największy **testowany** residual spełniający >= 3 sigma,
- największy testowany residual spełniający >= 4 sigma,
- interpolowany próg 3 sigma,
- interpolowany próg 4 sigma.

Interpolacja jest liniowa między sąsiednimi punktami sweepu i ma charakter pomocniczy.

Jeżeli wynik nie jest monotoniczny, należy opierać wymaganie na największym faktycznie przetestowanym residual, a nie na interpolacji.

## v6.1B - sweep pol_nr_scale

Przy:

`depol_residual = 0.05`

testowane:

- 0,
- 0.5e-4,
- 1e-4,
- 2e-4,
- 4e-4,
- 8e-4.

Dla każdego punktu:

- 20 realizacji,
- te same stany SMF,
- ten sam bank seedów,
- zero-rate.

Raportowane:

- mean,
- STD,
- STD w deg/h,
- RMS,
- P95 |Omega|,
- maximum |Omega|.

Cel:

sprawdzić, czy wymaganie dotyczące residual jest stabilne względem przyjętej skali nieodwracalnej fazy polaryzacyjnej.

## v6.1C - requirement

Skrypt tworzy:

`FOG_v6_1_requirement.csv`

z roboczym wymaganiem modelowym:

- największy testowany residual dla 3 sigma,
- największy testowany residual dla 4 sigma,
- interpolowane progi,
- założenia ADC, AAF, ER i `pol_nr_scale`.

To nie jest jeszcze specyfikacja katalogowa depolaryzatora.

## Pliki wynikowe

- `FOG_v6_1.slx`
- `FOG_v6_1_detection_vs_residual.csv`
- `FOG_v6_1_paired_raw.csv`
- `FOG_v6_1_pol_nr_scale_sweep.csv`
- `FOG_v6_1_requirement.csv`

## Kryterium zakończenia

v6.1 można uznać za zakończone, jeżeli:

1. sweep residual daje czytelne przejście przez 3 sigma,
2. możliwe jest wskazanie roboczego residual dla >=3 sigma,
3. preferencyjnie istnieje też punkt >=4 sigma,
4. sweep `pol_nr_scale` pokazuje, jak mocno próg zależy od fenomenologicznej fazy.

Po tym można przejść do v7, pamiętając, że rzeczywiste przełożenie residual na konkretny depolaryzator wymaga pomiaru.

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Wynik:
- largest tested residual dla punktowego >=3 sigma: 0.05,
- interpolowany próg 3 sigma: 0.06143,
- interpolowany próg 4 sigma: 0.01618,
- konserwatywny punkt z bootstrap 95% lower bound >3 sigma: 0.025,
- przy residual=0.05 pol_nr_scale od około 4e-4 zaczyna wyraźnie pogarszać zero-rate noise.

Szczegóły: docs/VALIDATION_V6_1.md.
