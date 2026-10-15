# T2. Modulator fazy w FOG: skąd różnica między CW i CCW?

**Status:** TEORIA  
**Cel:** wyjaśnić mechanizm, który nie polega na nadawaniu różnej prędkości falom.

## 1. Jeden modulator i dwa różne momenty

Modulator elektrycznie zmienia *fazę* światła. W uproszczonym modelu każda fala, która przechodzi przez niego w chwili t, uzyskuje przesunięcie φ_m(t). Obie fale są traktowane jednakowo **w tej samej chwili**, lecz dochodzą do modulatora w różnych momentach:

- CW: modulator → cała pętla;
- CCW: cała pętla → modulator.

Jeśli odległość modulatora od jednego końca cewki jest pomijalna, odstęp między przejściami wynosi w przybliżeniu τ. Różnicowa faza modulacji (przy określonej konwencji znaku i przesunięciu początku czasu) to:

```math
\Delta\varphi_m(t)=\varphi_m(t)-\varphi_m(t-\tau).
```

**Kontrprzykłady:**
- Stałe ustawienie φ_m(t)=φ_0 ⇒ Δφ_m=0.
- Modulator w idealnym środku symetrycznej pętli ⇒ oba przejścia jednoczesne i brak różnicowej modulacji.
- Krótsza różnica czasów przejścia niż zakładana zmienia efektywną modulację.

To uproszczenie nie opisuje każdego typu modulatora, np. rozłożonego modulatora ze zjawiskami falowymi i własnym pasmem.

## 2. Przebieg sinusoidalny

Niech

```math
\varphi_m(t)=\varphi_0\sin(2\pi f_m t).
```

Wtedy

```math
\Delta\varphi_m(t)=2\varphi_0\sin(\pi f_m\tau)\cos[2\pi f_m(t-\tau/2)].
```

Różnicowa amplituda to

```math
\beta=2\varphi_0|\sin(\pi f_m\tau)|.
```

Pierwsze maksimum β przy zadanej φ_0 występuje dla częstotliwości

```math
f_{proper}=\frac{1}{2\tau}\approx102{,}1\ \mathrm{kHz}
```

dla L=1000 m i n_g=1,4682. To nie znaczy, że **każde** kryterium optymalności (RIN, amplituda pierwszej harmonicznej, pasmo PZT) ma maksimum dla tej samej amplitudy/frekwencji.

## 3. Detekcja z fazą Sagnaca

Faza wejściowa interferometru:

```math
\Delta\varphi(t)=\Delta\varphi_S+\Delta\varphi_m(t).
```

Moc optyczna zależy od wybranego portu. Dla modelu E01 **port B jest ciemny przy zerowej różnicy faz**, dlatego:

```math
P_B(t)=\frac{P_{in}}{2}\{1-V\cos[\Delta\varphi_S+\Delta\varphi_m(t)]\}.
```

Port jasny A ma znak **plus** przed cosinusem. Wyprowadzenie i konwencje: [E01 / 1.2](../research/E01_basic_FOG/01_02_mathematical_derivation.md).

Detektor zamienia moc na prąd. Po synchronizacji z sygnałem sterującym i odpowiednim uśrednieniu otrzymujemy człon nieparzysty względem fazy Sagnaca, proporcjonalny do:

```math
S_1\propto J_1(\beta)\sin(\Delta\varphi_S).
```

W pobliżu zera sin(Δφ_S)≈Δφ_S=K_S Ω, czyli znak demodulowanego sygnału pozwala rozróżnić kierunek obrotu (po ustaleniu konwencji znaku). Odpowiedź w otwartej pętli jest okresowa; liniowość ma ograniczony zakres.

## 4. Wyjaśnienie intuicyjne

Modulator jest jednym „pokrętłem”, którego ustawienie zmienia się w czasie. CW naciska pokrętło wcześniej, CCW później. Jeśli w tych dwóch momentach pokrętło wskazuje inne wartości, fale dostają inne przesunięcia fazy. **Nie zmieniamy prędkości obiegu CW względem CCW.** Zmiana fazy optycznej jest odrębną wielkością od zmiany prędkości propagacji.

## 5. Co sprawdzimy numerycznie?

1. Dla stałego sterowania Δφ_m(t)=0.
2. Dla sinusoidy wykres φ_m(t), φ_m(t−τ) i różnicy.
3. Wpływ położenia modulatora (dwa różne czasy dotarcia).
4. Wykres odpowiedzi detektora dla Ω=0 i ±Ω.
5. Demodulacja: amplituda i znak pierwszej harmonicznej.
6. Wpływ f_m i φ_0 na czułość oraz zakres liniowy.

## Literatura

- H. C. Lefèvre, *Fundamentals of the Interferometric Fiber-Optic Gyroscope* (1996), https://doi.org/10.1364/OFS.1996.Tu3S1
- *Efficient Modulation and Processing Method for Closed-Loop Fiber Optic Gyroscope with Piezoelectric Modulator* (2019), https://pmc.ncbi.nlm.nih.gov/articles/PMC6480926/ (szczególnie `f_b = 1/(2τ)`).
