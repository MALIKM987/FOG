# T1. Minimalny interferometr Sagnaca

**Status:** TEORIA / WYPROWADZENIE DO WERYFIKACJI  
**Cel:** uzyskać minimalny model deterministyczny, bez polaryzacji i szumów.

## 1. Elementy i przebieg

Źródło optyczne zasila sprzęgacz 2×2. Światło dzieli się na fale przeciwbieżne: CW i CCW. Obie pokonują tę samą cewkę i spotykają się ponownie na sprzęgaczu. Wybrany port wyjściowy podłączony jest do fotodiody. Jeden z odcinków przy końcu cewki zawiera modulator fazy.

Uwaga: idealny **układ z pętlą, modulatorem i laserem, ale bez sprzęgacza i fotodiody** nie jest kompletnym układem odczytu interferencji.

## 2. Faza Sagnaca

Dla N identycznych zwojów o polu A i osi obrotu prostopadłej do cewki:

```math
\Delta\varphi_S=\frac{8\pi NA\Omega}{\lambda c}
```

Przy A = πD²/4 i L = NπD otrzymujemy:

```math
\boxed{\Delta\varphi_S=\frac{2\pi LD}{\lambda c}\Omega=K_S\Omega}
```

gdzie: L [m] – długość nawiniętego włókna; D [m] – średnia średnica cewki; λ [m] – długość fali w próżni; c [m/s] – prędkość światła w próżni; Ω [rad/s] – składowa prędkości kątowej wzdłuż osi cewki.

Wzór zakłada stały efektywny promień zwojów. Dla zwojów o różnych polach należy użyć sumy pól.

### Referencyjna konfiguracja FOG

| Parametr | Wartość |
|---|---:|
| L | 1000 m |
| D | 0,160 m |
| λ | 1550 nm |
| Współczynnik grupowy n_g | 1,4682 (wartość modelowa) |
| K_S | ≈ 2,16345 rad/(rad/s) |
| Δφ_S przy Ω = 1 deg/s | ≈ 0,03776 rad |

To wartości referencyjne wcześniejszych modeli; nie są potwierdzeniem parametrów fizycznej cewki.

## 3. Długość drogi a opóźnienie w modulatorze

Czas przejścia przez cewkę:

```math
\tau=\frac{n_g L}{c}\approx4{,}897\ \mathrm{\mu s}.
```

**Ważne rozróżnienie:** opóźnienie grupowe (n_g) opisuje czasy przejścia sygnału/modulacji; współczynnik skali Sagnaca opisany powyżej nie jest prostym przemnożeniem przez n_g.

## 4. Zależność mocy wyjściowej od fazy

Dla **wybranego** portu idealnego interferometru można zapisać:

```math
P(t)=P_{dc}[1+V\cos(\Delta\varphi(t))].
```

P_dc zawiera poziom optyczny, straty oraz podział mocy; V∈[0,1] jest widzialnością prążków. Na przeciwnym porcie może wystąpić znak minus. Port i fazę odniesienia trzeba jednoznacznie określić w przyszłym modelu.

Bez modulacji: Δφ=Δφ_S. Charakterystyka cosinus jest parzysta, więc P(+Ω)=P(−Ω). Co więcej, przy zerze pochodna cosinusa znika – małe obroty są źle rozróżnialne na tle szumu.

## 5. Czego idealny model NIE dowodzi?

- Nie daje jeszcze rzeczywistej rozdzielczości, dokładności ani minimalnej wykrywalnej prędkości.
- Nie opisuje polaryzacji, dyspersji, rozpraszania wstecznego, szumu RIN, szumu śrutowego, elektroniki ani temperaturowego dryftu.
- Nie rozróżni jakości lasera i ASE **tylko dlatego, że mają inne widma**, jeśli oba dają tę samą średnią moc, a wzajemna różnica czasów obu dróg jest praktycznie zerowa.

## Źródła bazowe

- H. C. Lefèvre, *The fiber-optic gyroscope, a century after Sagnac’s experiment*, C. R. Physique 15 (2014), 851–858, https://doi.org/10.1016/j.crhy.2014.10.007
- H. C. Lefèvre, *Fundamentals of the Interferometric Fiber-Optic Gyroscope*, Optical Fiber Sensors (1996), https://doi.org/10.1364/OFS.1996.Tu3S1
