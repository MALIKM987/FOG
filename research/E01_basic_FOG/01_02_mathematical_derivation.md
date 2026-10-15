# E01 / 1.2 – Wyprowadzenie modelu matematycznego FOG-E01-MIS

**Status:** OPRACOWANE ANALITYCZNIE; **nie przeprowadzono symulacji ani pomiarów E01**.  
**Data:** 2026-10-15.  
**Cel:** wyprowadzić przejście od amplitudy światła doprowadzonego do sprzęgacza 2×2 aż do prądu fotodiody i sygnału po idealnej demodulacji.

## 0. Konwencje i zakres ważności

Rozpatrujemy idealny sprzęgacz bezstratny 50:50, jednomodową cewkę o równej drodze dla CW i CCW, **model skalarny** (bez polaryzacji), punktowy modulator fazy przy jednym końcu cewki i początkowo **monochromatyczne** źródło. Źródło ASE uwzględnimy na końcu jako graniczne rozszerzenie spektralne, a jego dokładną fizykę w Etapie 1.3.

**Topologia portów:**

```text
                       A (źródło)       C
  E_in ---> port A ---> [ sprzęgacz ] ---> modulator ---> cewka ---+
             port B <---[    2 × 2  ] <--- port D <-----------------+
              |
          fotodioda

Przejście C -> D oznaczamy CW, a D -> C oznaczamy CCW.
```

Sprzęgacz obserwujemy **z obu stron**. Pole wejściowe $E_0$ pochodzi z portu A. Port B jest wybrany jako **ciemny przy zerowej różnicy faz**. Port A jest w tej idealizacji jasny, co oznacza możliwy powrót mocy do źródła.

**Konwencja obrotu:** definiujemy $\Delta\varphi \equiv \varphi_{\rm CCW}-\varphi_{\rm CW}$. Dodatnia $\Omega$ oznacza obrót, dla którego $\Delta\varphi_S>0$ zgodnie z umownie zorientowaną osią cewki. Konwencja znaku jest arbitralna; dla mocy bez demodulacji znak nie ma znaczenia, lecz dla demodulacji musi być stały.

W całym tekście używamy $j^2=-1$ oraz **amplitud mocy znormalizowanych**: $|E|^2=P$ [W]. To nie są amplitudy pola elektrycznego w V/m; normalizacja upraszcza rachunek mocy.

## 1. Światło jako zespolona amplituda

Dla monochromatycznej fali fizyczne pole elektryczne można symbolicznie przedstawić jako

$$
\mathcal E(t)=\operatorname{Re}\{\widetilde{\mathcal E}e^{j\omega_0t}\},
\qquad \omega_0=\frac{2\pi c}{\lambda}.
$$

Do rachunku portów stosujemy już **znormalizowaną amplitudę** $E_0=\sqrt{P_{\rm in}}e^{j\varphi_0}$, gdzie $P_{\rm in}$ jest mocą optyczną dochodzącą do portu A.

Rozdzielenie amplitud następuje na polach, a nie na samych mocach: dopiero po ich ponownym dodaniu obliczamy kwadraty modułów.

## 2. Dlaczego macierz sprzęgacza 50:50 wygląda tak?

W przyjętej konwencji współczynniki amplitud przejścia i sprzężenia to

$$
t=\frac{1}{\sqrt{2}},\qquad \kappa=\frac{j}{\sqrt{2}}.
$$

Są **zespolone**: przy sprzężeniu występuje względne przesunięcie fazowe 90°. Dla idealnego symetrycznego sprzęgacza:

$$
\boxed{
\begin{bmatrix}E_C^{(+)}\\ E_D^{(+)}\end{bmatrix}
=U
\begin{bmatrix}E_A^{(+)}\\ E_B^{(+)}\end{bmatrix},
\qquad
U=\frac{1}{\sqrt{2}}
\begin{bmatrix}1&j\\j&1\end{bmatrix}.
}
$$

Znaki $+$ oznaczają kierunek od portów A/B do pętli C/D. Macierz $U$ jest unitarna: $U^\dagger U=I$, więc nie powoduje strat mocy.

Gdy $E_A^{(+)}=E_0$ i $E_B^{(+)}=0$:

$$
\boxed{
E_C^{(+)}=\frac{E_0}{\sqrt{2}},\qquad
E_D^{(+)}=\frac{jE_0}{\sqrt{2}}.
}
$$

Zatem $P_C=P_D=P_{\rm in}/2$. Sygnały mają równą moc, ale faza początkowa w jednym torze różni się o 90°. W rachunku pętli te przesunięcia trzeba zachować: nie wolno po prostu sumować połówek mocy.

## 3. Fale wracają do *odwrotnych* portów

Fala rozpoczynająca bieg w C dociera po obiegu do D (CW). Fala rozpoczynająca w D dociera do C (CCW). Nie wolno podłączać matematycznie C do C i D do D.

Niech fazy całego przejścia po obiegu wynoszą $\varphi_{\rm CW}$ i $\varphi_{\rm CCW}$. Wtedy amplitudy wracające do sprzęgacza to

$$
E_C^{(-)}=E_D^{(+)}e^{j\varphi_{\rm CCW}}
=\frac{jE_0}{\sqrt{2}}e^{j\varphi_{\rm CCW}},
$$

$$
E_D^{(-)}=E_C^{(+)}e^{j\varphi_{\rm CW}}
=\frac{E_0}{\sqrt{2}}e^{j\varphi_{\rm CW}}.
$$

Ze wzajemności idealnego sprzęgacza, w użytej konwencji otrzymujemy także dla kierunku powrotnego:

$$
\begin{bmatrix}E_A^{(-)}\\E_B^{(-)}\end{bmatrix}
=U\begin{bmatrix}E_C^{(-)}\\E_D^{(-)}\end{bmatrix}.
$$

Stąd bezpośrednio:

$$
\boxed{
E_A^{(-)}=\frac{jE_0}{2}
\left(e^{j\varphi_{\rm CCW}}+e^{j\varphi_{\rm CW}}\right),
}
$$

$$
\boxed{
E_B^{(-)}=\frac{E_0}{2}
\left(e^{j\varphi_{\rm CW}}-e^{j\varphi_{\rm CCW}}\right).
}
$$

To fundamentalna część dowodu: w porcie B występuje **różnica amplitud**, a w porcie A ich suma.

## 4. Interferencja: od amplitud do mocy

Definiujemy różnicę faz

$$
\Delta\varphi=\varphi_{\rm CCW}-\varphi_{\rm CW}.
$$

Dla wybranego portu B:

$$
P_B=|E_B^{(-)}|^2
=\frac{P_{\rm in}}{4}
\left|e^{j\varphi_{\rm CW}}-e^{j\varphi_{\rm CCW}}\right|^2.
$$

Korzystamy z tożsamości

$$
|e^{jx}-e^{jy}|^2=2-2\cos(x-y).
$$

Po podstawieniu:

$$
\boxed{
P_B=\frac{P_{\rm in}}{2}\left(1-\cos\Delta\varphi\right)
=P_{\rm in}\sin^2\frac{\Delta\varphi}{2}.
}
$$

Dla drugiego portu:

$$
\boxed{
P_A=\frac{P_{\rm in}}{2}\left(1+\cos\Delta\varphi\right)
=P_{\rm in}\cos^2\frac{\Delta\varphi}{2}.
}
$$

Wniosek kontrolny: **$P_A+P_B=P_{\rm in}$** dla każdego $\Delta\varphi$, bo idealna pętla i sprzęgacz nie tracą mocy.

| $\Delta\varphi$ | $P_B/P_{\rm in}$ | $P_A/P_{\rm in}$ |
|---|---:|---:|
| 0 | 0 | 1 |
| $\pi/2$ | 0,5 | 0,5 |
| $\pi$ | 1 | 0,0 |
| $-\pi/2$ | 0,5 | 0,5 |

Ta tabela ujawnia zarazem problem: **bez modulacji nie rozróżniamy $+\Delta\varphi$ i $-\Delta\varphi$**. W zerze $\partial P_B/\partial\Delta\varphi =0$, więc bez biasu małe obroty dają zmianę drugiego rzędu.

**Uwaga:** wzory te dotyczą dokładnie zdefiniowanych portów A/B. Inny wybór portu pomiarowego daje pozornie inny znak $\pm\cos$, ale opisuje ten sam interferometr.

## 5. Faza Sagnaca zależy od obrotu, a nie od modulatora

Dla cewki o N identycznych zwojach o powierzchni $A_{\rm zw}$:

$$
\Delta t_S=\frac{4 N A_{\rm zw}}{c^2}\Omega,\qquad
\Delta\varphi_S=\omega_0\Delta t_S.
$$

Dla $L=N\pi D$ oraz $A_{\rm zw}=\pi D^2/4$:

$$
\boxed{
\Delta\varphi_S=\frac{2\pi L D}{\lambda c}\Omega
=K_S\Omega,\qquad K_S=\frac{2\pi L D}{\lambda c}.
}
$$

Używamy składowej $\Omega$ wzdłuż osi cewki i długości fali w próżni. Dla zwojów o różnym polu należy sumować pola, nie przyjmować bez dowodu wspólnej średnicy.

### Parametry do późniejszej symulacji (robocze)

| Parametr | Wartość | Znaczenie |
|---|---:|---|
| $L$ | 1000 m | długość światłowodu |
| $D$ | 0,160 m | średnia średnica |
| $\lambda_0$ | 1550 nm | przykład, nie wybór źródła |
| $n_g$ | 1,4682 | współczynnik grupowy dla opóźnienia |

Z samych wzorów otrzymujemy w przybliżeniu $K_S=2{,}1635$ rad/(rad/s), a przy $\Omega=1^\circ/$s: $\Delta\varphi_S\approx0{,}0378$ rad. **Nie jest to wynik nowej symulacji E01 ani pomiaru.**

## 6. Wspólny modulator w różnych chwilach

Przyjmujemy, że CW mija modulator przy wejściu do pętli, czyli w przybliżeniu w chwili $t-\tau$, a CCW mija go przy wyjściu z pętli, około chwili $t$. Rozważamy wspólny moment ponownego złożenia fal.

Wówczas dla naszej konwencji $\Delta\varphi=\varphi_{\rm CCW}-\varphi_{\rm CW}$:

$$
\boxed{
\Delta\varphi_m(t)=\varphi_m(t)-\varphi_m(t-\tau),
\qquad \tau=\frac{n_g L}{c}.
}
$$

Nie oznacza to, że modulator przyspiesza CW albo opóźnia CCW. Nadaje *inną wartość fazy*, ponieważ spotyka fale w innych chwilach. Przy stałym $\varphi_m$ różnicowa modulacja dokładnie zanika.

Dla sinusoidy:

$$
\varphi_m(t)=\varphi_0\sin(\omega_m t),\qquad \omega_m=2\pi f_m.
$$

Korzystając z $\sin x-\sin y=2\sin\frac{x-y}{2}\cos\frac{x+y}{2}$:

$$
\boxed{
\Delta\varphi_m(t)=2\varphi_0\sin(\pi f_m\tau)
\cos\left[2\pi f_m\left(t-\frac{\tau}{2}\right)\right].
}
$$

Niech $\beta=2\varphi_0\sin(\pi f_m\tau)$ oznacza **podpisaną** amplitudę różnicową (jej moduł jest dodatnią głębokością modulacji). Pierwsza dodatnia częstotliwość maksymalizująca $|\beta|$ dla ustalonego $\varphi_0$ to

$$
\boxed{f_{\rm proper}=\frac{1}{2\tau}.}
$$

Dla przykładowych parametrów $\tau\approx4{,}898\,\mu$s i $f_{\rm proper}\approx102{,}1$ kHz. To maksimum różnicowej fazy przy danej amplitudzie sterowania, **nie ogólna optymalizacja rzeczywistego modulatora**.

## 7. Całkowita faza i fotodioda

W modelu skalarnym:

$$
\Delta\varphi(t)=K_S\Omega+\Delta\varphi_m(t).
$$

Moc zarejestrowana na porcie B:

$$
\boxed{
P_B(t)=\frac{P_{\rm in}}{2}
\bigl[1-\cos(K_S\Omega+\beta\cos\theta(t))\bigr],
\quad \theta(t)=\omega_m(t-\tau/2).
}
$$

W modelu monochromatycznym i bez szumów prąd idealnej fotodiody jest równy

$$
\boxed{i_B(t)=R(\lambda_0)P_B(t),}
$$

gdzie $R(\lambda_0)$ [A/W] jest responsywnością fotodiody. Fotodioda nie rozróżnia faz bez wcześniejszej interferencji i nie podaje bezpośrednio prędkości obrotowej.

## 8. Idealna demodulacja synchroniczna: dlaczego wraca znak obrotu?

Chcemy wiedzieć, czy wirujemy w prawo czy w lewo. Wprowadzamy znany przebieg fazy i **korelujemy** prąd fotodiody z sygnałem odniesienia $\cos\theta(t)$.

Dla całkowitej liczby okresów $M$ i idealnego uśredniania trwającego $T=M/f_m$ definiujemy amplitudę pierwszej harmonicznej:

$$
I_1=\frac{2}{T}\int_{t_0}^{t_0+T}i_B(t)\cos\theta(t)\,dt

$$

Przez rozwinięcie Jacobi–Angera otrzymujemy współczynnik pierwszej harmonicznej (pozostałe harmoniczne są ortogonalne):

$$
\boxed{
I_1=R(\lambda_0)P_{\rm in}J_1(\beta)\sin(K_S\Omega).
}
$$

$J_1$ to funkcja Bessela pierwszego rodzaju rzędu 1. Gdy $|K_S\Omega|\ll1$:

$$
\boxed{
I_1\approx R(\lambda_0)P_{\rm in}J_1(\beta)\,K_S\Omega.
}
$$

Stąd **znak** $I_1$ jest zgodny ze znakiem $\Omega$ dla dodatniego $J_1(\beta)$ i przyjętego odniesienia. Należy pamiętać, że faza referencji i ujemne $\beta$ mogą odwracać znak; nie wolno na tej podstawie samodzielnie zmieniać definicji kierunku obrotu.

**Znaczenie praktyczne:** po demodulacji w pobliżu zera odczyt jest liniowy i ma niezerowe nachylenie. Bez modulacji $J_1(0)=0$, a zatem $I_1=0$. Open-loop pozostaje jednak okresowy i nieliniowy poza niewielkim zakresem.

Warunki idealizacji: stała moc źródła, brak przesunięcia referencji względem rzeczywistego przebiegu oraz całkowite uśrednianie okresów. W realnym układzie stosuje się filtrację i kalibrację.

## 9. Co z LASER i ASE? Granica modelu E01/1.2

Dotychczasowe wyprowadzenie dotyczy **jednej częstotliwości optycznej**. Nie należy wprowadzać dla światła ASE jednej, stabilnej globalnej fazy optycznej.

Dla szerokopasmowego źródła opisanego wejściową gęstością mocy $S_{\rm in}(\lambda)$ [W/m] i idealnie niezależnych wkładów widmowych średni prąd opisuje rozszerzenie:

$$
\boxed{
i_B(t)=\frac12\int R(\lambda)S_{\rm in}(\lambda)
\left[1-\cos\bigl(\Delta\varphi_S(\lambda)+\Delta\varphi_m(\lambda,t)\bigr)\right]\,d\lambda.
}
$$

Tutaj $\int S_{\rm in}(\lambda)d\lambda=P_{\rm in}$, a $R(\lambda)$ jest czułością spektralną. Zapis ten dotyczy *średniej odpowiedzi*; nie jest jeszcze modelem fluktuacji ASE, szumu RIN, odbić czy rozpraszania Rayleigha.

Wniosek: **zmiana LASER/ASE nie wymaga zmiany sprzęgacza i geometrii modelu.** Zmienia się opis statystyczny i widmowy źródła. Szczegółowe porównanie spójności należy do Etapu 1.3.

## 10. Lista sprawdzeń zanim powstanie pierwsza symulacja

Kontrole **analityczne** (wynikają z powyższych równań, nie z uruchomionej symulacji):

- [x] Sprzęgacz jest unitarny: $U^\dagger U=I$.
- [x] Bezstratny bilans: $P_A+P_B=P_{\rm in}$.
- [x] $\Delta\varphi=0$ daje ciemny port B i jasny port A.
- [x] $\Delta\varphi=\pi$ daje jasny port B i ciemny port A.
- [x] $P_B(+\Delta\varphi)=P_B(-\Delta\varphi)$ bez modulacji.
- [x] Stała faza modulatora daje $\Delta\varphi_m=0$.
- [x] Przy $f_m=1/(2\tau)$ zachodzi $|\beta|=2|\varphi_0|$.
- [x] $I_1(\Omega)$ jest funkcją nieparzystą przy ustalonym $\beta$.

Do **późniejszego sprawdzenia numerycznego**:
- [ ] Porównanie macierzy sprzęgacza z obliczeniami mocy dla faz z kilku punktów.
- [ ] Zgodność obliczonej pierwszej harmonicznej z funkcją Bessela.
- [ ] Test znaków $\Omega$ oraz opóźnienia CW/CCW.
- [ ] Przejście do szerokiego widma i poprawna normalizacja w nm vs Hz.
- [ ] Dla rzeczywistej topologii potwierdzenie portów zgodnie z instrukcją producenta.

## 11. Źródła i poziom pewności

**Wyprowadzenia (od macierzy do mocy oraz od cosinusa do pierwszej harmonicznej)** są rachunkami wykonanymi dla modelu E01 i wynikają z przyjętych wyżej założeń; nie są dosłownymi cytatami z publikacji.

- H. C. Lefèvre, *Fundamentals of the Interferometric Fiber-Optic Gyroscope*, Optical Fiber Sensors 1996, Tu3S1, https://doi.org/10.1364/OFS.1996.Tu3S1 – podstawy interferometrii Sagnaca.
- M. Skalský, Z. Havránek, J. Fialka, *Efficient Modulation and Processing Method for Closed-Loop Fiber Optic Gyroscope with Piezoelectric Modulator*, Sensors 19(7), 1710 (2019), https://doi.org/10.3390/s19071710 – sekcja 2.1 oraz wzory (1)-(2), opis częstotliwości proper i asymetrii położenia modulatora.
- A. Kolkiran, G. S. Agarwal, *Heisenberg limited Sagnac interferometry*, *Optics Express* 15(11), 6798–6808 (2007), https://doi.org/10.1364/OE.15.006798 – sekcja 3.1, rozdzielacz 50:50 i pola interferujące. **Autorzy i metryka zweryfikowane na stronie Optica.**

## 12. Ograniczenia

Model nie opisuje: polaryzacji, dyspersji i zależności $n_g$ od $\lambda$, odbić do źródła, strat sprzęgacza i cewki, działania izolatora/cyrkulatora, rozpraszania Rayleigha, niedoskonałości PZT, TIA, ADC, szumu śrutowego ani szumów źródła. Wyniki to **relacje teoretyczne**, nie dowód dokładności rzeczywistego FOG.

**Kolejny krok:** E01/1.3 – LASER vs ASE: model widmowy i spójność, a następnie E01/1.4 – symulacja z jednym przełącznikiem źródła.
