# T3. Źródła optyczne w interferometrycznym FOG: LASER i ASE

**Status:** TEORIA ZRÓDEŁ I MODELU WIDMOWEGO (bez walidacji eksperymentalnej).  
**Ostatnia aktualizacja:** 2026-10-15.  
**Powiązane badanie:** [E01 / 1.3](../research/E01_basic_FOG/01_03_laser_vs_ase.md).  
**Zakres:** układ skalarny, bez polaryzacji, jednokanałowa detekcja fotodiody, bez modelowania rzeczywistych parametrów urządzenia ASE z laboratorium.

> Kluczowa zasada: duża spójność źródła **nie jest konieczna** do uzyskania interferencji w zrównoważonym Sagnacu. ASE może zmniejszać niepożądane interferencje o istotnej różnicy dróg, ale niekoniecznie całkowity szum detekcji.

## 1. Co nazywamy źródłem optycznym?

Źródło dostarcza pole elektromagnetyczne opisane mocą optyczną, gęstością widmową, fluktuacjami amplitudy i fazy. **Laser** działa poprzez emisję wymuszoną z dodatnim sprzężeniem zwrotnym (rezonatorem), co zwykle prowadzi do wąskiego widma i dużej spójności. **ASE** (*Amplified Spontaneous Emission*) to spontaniczna emisja w ośrodku wzmacniającym (np. włóknie z erbem), wzmocniona bez wymogu laserowej oscylacji; ma zwykle szerokie widmo i losową fazę.

ASE nie należy nazywać „diodą szerokopasmową” bez identyfikacji konkretnego urządzenia. ASE, SLD (*superluminescent diode*) i laser to różne klasy źródeł. Dla tego eksperymentu rozpatrujemy przełączane **LASER vs ASE**, ponieważ taki generator ASE jest dostępny w laboratorium.

| Cecha | Laser wąskopasmowy | ASE |
|---|---|---|
| Typowy charakter widma | wąskie, lecz nie matematyczna delta | szerokie, profil zależny od ośrodka/filtracji |
| Czas spójności | często długi | krótki |
| Spójne interferencje pasożytnicze | mogą być istotne | często tłumione przy odpowiednio dużym opóźnieniu |
| Szum intensywności | zależny od typu i sterowania lasera | może występować excess RIN od dudnień spektralnych |
| Stabilność środka widma | zależna od lasera i stabilizacji | zależna od źródła ASE, temperatury, filtrów i wzmocnienia |
| Czy interferuje w zrównoważonym FOG? | tak | tak |

Nie należy z tej tabeli wnioskować o parametrach konkretnego generatora z laboratorium.

## 2. Widmo opisujemy w jednostkach Hz albo nm

Niech $S_\nu(\nu)$ [W/Hz] będzie gęstością mocy źródła w funkcji **częstotliwości** optycznej, a $S_\lambda(\lambda)$ [W/m] w funkcji **długości fali w próżni**.

$$
P_{\rm in}=\int S_\nu(\nu)\,d\nu
          =\int S_\lambda(\lambda)\,d\lambda,\qquad
\nu=\frac{c}{\lambda}.
$$

Ponieważ $d\nu/d\lambda=-c/\lambda^2$, gęstości łączy transformacja:

$$
\boxed{S_\nu(\nu)=S_\lambda(c/\nu)\frac{\lambda^2}{c},
\qquad \lambda=\frac{c}{\nu}.}
$$

**Uwaga:** przebieg Gaussa w nm nie jest dokładnie tym samym rozkładem co przebieg Gaussa w Hz. Zamiana jednostki na osi bez uwzględnienia jakobianu daje błędne wagi podczas całkowania.

Dla wąskiego zakresu wokół $\lambda_0$ przybliżenie szerokości jest następujące:

$$
\Delta\nu\approx\frac{c}{\lambda_0^2}\Delta\lambda.
$$

### Model laserowy

W najprostszym, **idealnym** przypadku przyjmujemy jedno $\lambda_0$ i $P_{\rm in}$, co odpowiada gęstości spektralnej o postaci delty Diraca. Realny laser ma skończoną szerokość linii, fluktuacje częstotliwości i charakterystykę szumu. Typ rzeczywistego lasera (DFB, wąskoliniowy itd.) i szerokość linii trzeba dobrać osobno, a nie zgadywać.

### Model ASE

Przyjmujemy znormalizowany rozkład $s_\lambda(\lambda)$ taki, że

$$
\int s_\lambda(\lambda)\,d\lambda=1,\qquad
S_\lambda(\lambda)=P_{\rm in}s_\lambda(\lambda).
$$

Na potrzeby **pierwszej ilustracji teoretycznej** można zastosować rozkład Gaussa o centralnej długości fali $\lambda_0$ i szerokości FWHM $\Delta\lambda$. Dopiero po uzyskaniu danych źródła laboratoryjnego podstawimy jego rzeczywiste widmo. Źródło ASE może mieć wyraźnie niesymetryczne widmo, wzgórki lub ograniczenia przez filtr.

## 3. Spójność czasowa – matematyczne uzasadnienie interferencji ASE

Spójność opisuje statystyczne podobieństwo pola optycznego w dwóch chwilach. Dla stacjonarnego światła i odpowiednich założeń twierdzenia Wienera–Chinczyna znormalizowana funkcja korelacji pierwszego rzędu jest transformacją Fouriera widma:

$$
\boxed{
\gamma(\delta t)=
\frac{\int S_\nu(\nu)e^{j2\pi\nu\delta t}\,d\nu}
     {\int S_\nu(\nu)\,d\nu}.
}
$$

$|\gamma(\delta t)|\le1$ i $\gamma(0)=1$. Dla dwóch kopii tego samego źródła o równej mocy i pełnej zgodności polaryzacji $|\gamma|$ wyznacza graniczną widzialność interferencji przy wzajemnym opóźnieniu $\delta t$. Przy nierównych mocach i stratach trzeba uwzględnić dodatkowy czynnik kontrastu. W Etapie E01 pomijamy polaryzację.

**Najważniejsze rozróżnienie:** czas przejścia przez cewkę $\tau\simeq n_gL/c$ (około 4,9 mikrosekundy dla przykładowego 1 km) **nie jest** opóźnieniem pomiędzy kopiami światła interferującymi na wyjściu. Obie fale pokonują niemal cały ten sam czas. O wzajemnej spójności decyduje **różnica** czasów CW i CCW, a nie sam wspólny czas propagacji.

Gdy FOG spoczywa idealnie, $\delta t_{\rm CW-CCW}\simeq0$, stąd $|\gamma|\simeq1$ nawet dla ASE. Dla obracającego się FOG:

$$
\delta t_S=\frac{4\sum_{k=1}^N A_k}{c^2}\Omega
\quad\text{(przybliżenie pierwszego rzędu).}
$$

Dla L=1000 m, D=0,160 m i $\Omega=1$ deg/s mamy $\delta t_S\simeq3{,}1\times10^{-17}$ s. To o wiele mniej niż przykładowy czas spójności ASE opisany poniżej.

## 4. Co znaczy „krótki czas spójności” i jaki przyjmujemy próg?

Czas spójności można definiować na różne sposoby (np. szerokość funkcji korelacji, całka z $|\gamma|^2$, poziom 1/e). Dlatego reguła $\tau_c\sim1/\Delta\nu$ wyraża **skalę czasu**, a nie uniwersalną dokładną wartość.

Jeżeli widmo **w częstotliwości** ma profil Gaussa o FWHM $\Delta\nu$:

$$
S_\nu(\nu)\propto
\exp\left[-4\ln2\frac{(\nu-\nu_0)^2}{(\Delta\nu)^2}\right],
$$

wtedy moduł funkcji spójności wynosi:

$$
\boxed{
|\gamma(\delta t)|=
\exp\left[-\frac{(\pi\Delta\nu\,\delta t)^2}{4\ln2}\right].
}
$$

Przyjmując **jawnie zdefiniowany** próg $|\gamma(\tau_{1/2})|=1/2$:

$$
\boxed{\tau_{1/2}=\frac{2\ln2}{\pi\Delta\nu}\approx\frac{0{,}441}{\Delta\nu}.}
$$

### Przykład tylko do zrozumienia skali

Dla $\lambda_0=1550$ nm i **hipotetycznego** $\Delta\lambda=20$ nm:

- $\Delta\nu\approx2{,}50$ THz.
- Skala $1/\Delta\nu\approx0{,}40$ ps.
- Dla *gaussowskiego widma w częstotliwości* $\tau_{1/2}\approx0{,}177$ ps.
- Odpowiadająca temu droga różnicowa w światłowodzie przy $n_g=1{,}4682$ ma rząd $c\tau_{1/2}/n_g\approx36$ µm.

Nie są to parametry ASE z laboratorium, ani dokładne przewidywanie zysku w FOG. Szczególnie ostatni wynik odpowiada wyłącznie przyjętemu progowi i wyidealizowanemu kształtowi widma.

## 5. Czemu szerokie widmo pomaga na niepożądane odbicia?

W rzeczywistym torze powstają dodatkowe kopie sygnału przez:
- odbicia Fresnela na złączach/końcówkach;
- niepożądane odbicia lub sprzężenia od komponentów;
- rozpraszanie wsteczne Rayleigha wzdłuż włókna.

Mogą one docierać z innymi opóźnieniami niż pola użyteczne. Kontrast danego **pojedynczego modelowego** toru pasożytniczego o opóźnieniu $\delta t_p$ w przybliżeniu skaluje się z $|\gamma(\delta t_p)|$. Wąskopasmowy laser może utrzymać spójność dla znacznie większego $\delta t_p$ niż szerokopasmowe ASE.

To **nie znaczy**, że ASE usuwa rozpraszanie Rayleigha, wszystkie odbicia, każdy spójny kanał pasożytniczy ani całe przesunięcie zera FOG. Dokładny rozkład opóźnień i faz zależy od rzeczywistej topologii i własności komponentów.

## 6. Co zyskujemy i co tracimy przy ASE?

### Korzyści mogące wystąpić

- Mniejsza spójność przy niezerowej różnicy dróg może ograniczyć część niepożądanej interferencji (odbić i rozpraszania).
- Użyteczna interferencja w niemal zrównoważonym Sagnacu pozostaje możliwa.

### Koszty i ograniczenia

- **Excess RIN:** fluktuacje intensywności źródeł szerokopasmowych związane m.in. z losowymi dudnieniami składowych spektralnych. W praktyce mogą istotnie ograniczać krótkoczasową czułość żyroskopu (por. [L8], [L10]).
- **Stabilność widma / długości średniej:** współczynnik skali zależy od $\lambda$, zatem dryft efektywnej długości fali wpływa na kalibrację (por. [L9]).
- **Widmowa charakterystyka układu:** sprzęgacz, transmisja włókna, modulator i responsywność fotodiody mogą zależeć od długości fali.
- **Złożoność modelowania:** dla ASE sumujemy odpowiedź po widmie; średnia deterministyczna nie wystarczy do oceny całkowitego szumu.

Również laser może mieć istotny szum intensywności i fluktuacje częstotliwości. Nie istnieje bezwarunkowe „lepsze źródło”: należy określić wymagania wobec dokładności, stabilności, kosztu i dostępnych urządzeń.

## 7. Prawidłowy model średniego sygnału na fotodiodzie

W E01 zdefiniowaliśmy port **B** jako ciemny przy zerowej fazie. Dla idealnego sprzęgacza 50:50 i pojedynczego źródła monochromatycznego:

$$
P_B(t)=\frac{P_{\rm in}}{2}
\left[1-\cos\bigl(\Delta\varphi_S+\Delta\varphi_m(t)\bigr)\right].
$$

W przypadku ASE rozkład mocy wejściowej to $S_{\rm in}(\lambda)$ [W/m] i odpowiednio znormalizowana moc $P_{\rm in}=\int S_{\rm in}(\lambda)d\lambda$. Przy pominięciu strat i polaryzacji **średni fotoprąd** wynosi:

$$
\boxed{
\overline i_B(t)=\frac12\int
R(\lambda)S_{\rm in}(\lambda)
\left[1-V(\lambda)\cos\left(
\frac{2\pi LD\,\Omega}{\lambda c}
+\Delta\varphi_m(\lambda,t)
\right)\right]\,d\lambda.
}
$$

W idealnym modelu $V(\lambda)=1$. Jeżeli dla części widma modulator wnosi inną fazę, trzeba ten fakt uwzględnić jawnie. Użycie $n_g(\lambda)$ pozwoli później opisać dyspersję; w E01 zaczynamy od stałego $n_g$.

**Zastrzeżenie fizyczne:** całka reprezentuje średnią odpowiedź (prążki składowych widmowych). **Nie jest** realizacją pola losowego ASE i sama nie wytwarza jego RIN, szumu śrutowego ani zaburzeń fazowych.

## 8. Czego nauczy nas pierwsza symulacja, a czego nie?

Minimalna symulacja LASER/ASE może wiarygodnie pokazać:
1. Normalizację widm i ich szerokości.
2. Podobieństwo średnich sygnałów interferencyjnych w idealnym zrównoważonym FOG.
3. Zależność fazy Sagnaca od długości fali.
4. Zależność kontrastu interferencji **modelowej ścieżki pasożytniczej** od $\delta t_p$.

Bez osobnego modelu szumowego nie wolno z niej wyciągać wniosków o:
- rzeczywistym bias stability, ARW, Allan deviation lub RIN;
- rzeczywistej dokładności prototypu;
- pełnym tłumieniu rozpraszania Rayleigha;
- przewadze konkretnego generatora ASE z laboratorium.

## 9. Bibliografia i stan weryfikacji

Bibliografia centralna: [bibliography/sources.md](../bibliography/sources.md) i [references.bib](../bibliography/references.bib).

- **[L1]** H. C. Lefèvre (2014), ogólna fizyka i architektura FOG: https://doi.org/10.1016/j.crhy.2014.10.007
- **[L5]** J. Nayak (2011), ograniczenia i dobór komponentów: https://doi.org/10.1364/AO.50.00E152
- **[L8]** F. Hakimi, J. D. Moores (2013), excess RIN w szerokopasmowych FOG: https://doi.org/10.1049/el.2012.3371
- **[L9]** Y. Liu, J. Yan, Y. Tan, X. Chen (2024), stabilność średniej długości fali a współczynnik skali: https://doi.org/10.1364/AO.522560
- **[L10]** Y. Li i in. (2019), suppressja excess RIN i przykład ASE w otwartopętlowym IFOG z SMF: https://doi.org/10.1016/j.optcom.2019.01.075
- Metoda matematyczna spójności: *On Teaching Temporal Coherence and the Wiener Khintchin Theorem at a Senior/Graduate Level* (2001), https://opg.optica.org/abstract.cfm?uri=ETOP-2001-IATLI222 (publikacja wskazana do dalszego przejrzenia).

**Status literatury:** metryki L8–L10 sprawdzone na stronach wydawców, szczegóły równań i stron należy zweryfikować podczas redakcji pracy.
