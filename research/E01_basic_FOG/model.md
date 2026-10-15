# E01 – Model fizyczny i matematyczny

**Status:** model koncepcyjny / teoria, niezweryfikowany jeszcze nową symulacją E01.

## 1. Definicja modelu

Jedno źródło → jeden idealny sprzęgacz 2×2 → dwie fale CW/CCW w jednej cewce → modulator przy jednym końcu → powrót do sprzęgacza → jeden wybrany port do fotodiody.

W Etapie 1.1 definiujemy porty sprzęgacza 2×2 następująco: A = źródło, B = fotodioda, C i D = dwa końce pętli (w pętli znajdują się modulator oraz cewka). Przy idealnym sprzęgaczu 50:50 port B jest ciemny dla zerowej różnicy faz, a port A jest portem jasnym, przez który światło może wracać ku źródłu. Modulator sterowany z zewnątrz zmienia fazę w czasie. Nie przyspiesza bezpośrednio propagacji jednej fali względem drugiej. Pełne fizyczne omówienie: [Etap 1.1](01_01_optical_path.md).

Punkt odniesienia: teoria [Sagnaca](../../theory/sagnac.md), [modulacji](../../theory/phase_modulation.md) i [źródeł](../../theory/optical_sources.md).

## 2. Założenia (pierwszy poziom)

- Obie wiązki pochodzą od tego samego źródła i przebiegają tę samą pętlę w przeciwnych kierunkach.
- Idealne sprzęgacze i faza skalarna; brak efektów polaryzacyjnych, temperaturowych i nieliniowości.
- Zewnętrzna prędkość kątowa Ω jest stała w czasie analizy.
- Zwoje mają jednakową średnią średnicę D, a oś obrotu jest prostopadła do cewki.
- Znormalizowaną odpowiedź wybranego portu definiuje model interferencji o określonej widzialności V.
- Dane źródła ASE z laboratorium są na razie nieznane; widma hipotetyczne oznaczamy jako przykładowe.

## 3. Wspólne parametry referencyjne

| Symbol | Wartość robocza | Jednostka | Status |
|---|---:|---|---|
| L | 1000 | m | z wcześniejszych symulacji |
| D | 0.160 | m | z wcześniejszych symulacji |
| λ₀ | 1550 | nm | przykład dla obu źródeł |
| n_g | 1.4682 | — | parametr modelu |
| Ω | zmienne | rad/s | wejście modelu |
| φ₀ | zmienne | rad | amplituda modulatora |
| f_m | zmienne | Hz | częstotliwość modulacji |

To nie są zatwierdzone parametry zakupowe ani udokumentowane pomiary laboratoryjne.

## 4. Efekt Sagnaca

Dla N zwojów obejmujących pole A każdy:

$$
\Delta\varphi_S=\frac{8\pi NA\Omega}{\lambda c}.
$$

Ponieważ $A=\pi D^2/4$ i $L=N\pi D$:

$$
\boxed{\Delta\varphi_S(\lambda)=\frac{2\pi LD}{\lambda c}\Omega}.
$$

Czułość fazowa dla λ=1550 nm, L=1000 m, D=0.16 m to około **2.163 rad/(rad/s)**, a przy Ω=1 deg/s faza Sagnaca wynosi około **0.0378 rad**.

## 5. Różnicowa modulacja fazy

Opóźnienie grupowe przejścia przez pętlę:

$$
\tau=\frac{n_g L}{c}\approx4.898\;\mu\mathrm{s}.
$$

Gdy modulator jest blisko końca pętli:

$$
\Delta\varphi_m(t)=\varphi_m(t)-\varphi_m(t-\tau).
$$

Dla sinusoidalnego sterowania $\varphi_m(t)=\varphi_0\sin(2\pi f_m t)$:

$$
\Delta\varphi_m(t)=2\varphi_0\sin(\pi f_m\tau)
\cos\left[2\pi f_m(t-\tau/2)\right].
$$

Pierwsza częstotliwość maksymalizująca amplitudę **różnicowej** modulacji dla zadanej φ₀ wynosi $f_m=1/(2\tau)$, około **102.1 kHz**. Nie przesądza to jeszcze o doborze konkretnego modulatora PZT ani o całkowitej optymalności układu.

## 6. Fotodioda i detekcja

Na porcie **B**, wybranym jako ciemny przy zerowej fazie, dla idealnego bezstratnego sprzęgacza 50:50:

$
P_B(t)=\frac{P_{\mathrm{in}}}{2}\left[1-V\cos\left(\Delta\varphi_S+\Delta\varphi_m(t)\right)\right].
$

$P_{\mathrm{in}}$ jest mocą wejściową, $V$ jest widzialnością interferencji. Dla idealnego $V=1$ i $\Delta\varphi=0$ zachodzi $P_B=0$. Moc na porcie A jest komplementarna w bezstratnym przypadku: $P_A(t)=P_{\mathrm{in}}-P_B(t)$. Oznaczenia odpowiadają [Etapowi 1.1](01_01_optical_path.md). W układzie rzeczywistym straty i asymetrie zmieniają wartości tych mocy.

Gdy modulator jest wyłączony, cosinus nie rozróżnia dodatniego i ujemnego Ω. Dla modulacji sinusoidalnej składowa po demodulacji synchronicznej może być proporcjonalna do $J_1(\beta)\sin(\Delta\varphi_S)$, gdzie $\beta=2\varphi_0|\sin(\pi f_m\tau)|$; stała i znak wymagają konwencji fazy odniesienia.

Idealną fotodiodę można opisać przez $i(t)=R(\lambda)P(t)$ w wąskopasmowym przybliżeniu. Dla szerokiego widma należy uwzględnić $R(\lambda)$ podczas całkowania po widmie.

## 7. LASER vs ASE

W modelu szerokopasmowym fotoprąd:

$$
i(t)=\int R(\lambda)W(\lambda)
\left\{1+V(\lambda)\cos\left[
\Delta\varphi_S(\lambda)+\Delta\varphi_m(\lambda,t)
\right]\right\}\,d\lambda.
$$

Widmo $W(\lambda)$ musi być poprawnie znormalizowane do przyjętej mocy. Ten zapis dotyczy oczekiwanej/deterministycznej odpowiedzi, **nie modeluje** szumu ASE ani wszystkich korelacji stochastycznych.

**Wniosek modelowy:** LASER i ASE mogą dawać podobne podstawowe sygnały w idealnym, zrównoważonym układzie. Różnice w odporności na interferencję pasożytniczą trzeba badać przy jawnie określonym niezrównoważeniu lub rozpraszaniu.

## 8. Walidacja do wykonania

- Test granicy Ω=0 i antysymetrii fazy względem Ω.
- Test φ_m=const i test modulacji przy $f_m=1/(2\tau)$.
- Test sygnału fotodiody dla Ω dodatniego i ujemnego.
- Test bilansu mocy i normalizacji widma w LASER/ASE.
- Dopiero następnie porównanie skutków opóźnienia drogi pasożytniczej.

**Status testów E01:** niezrealizowane. Istniejące modele w [matlab/](../../matlab/) nie są automatycznie dowodem wykonania powyższych testów dla E01.
