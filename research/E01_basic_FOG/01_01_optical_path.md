# E01 / 1.1 — Fizyczna zasada działania minimalnego FOG

**Identyfikator modelu:** \`FOG-E01-MIS\` (Minimalny Interferometr Sagnaca).  
**Status:** OPRACOWANIE TEORETYCZNE, bez symulacji i pomiarów E01.  
**Data:** 2026-10-15.  
**Główny cel:** wyjaśnić *jak* światło przechodzi przez układ złożony z pięciu elementów optycznych i *dlaczego* obrót wpływa na sygnał elektryczny.

## 1. Co dokładnie budujemy koncepcyjnie?

Interferometryczny żyroskop światłowodowy (**IFOG**) z jedną pętlą pomiarową, jednym sprzęgaczem 2×2, jednym modulatorem fazy, jednym źródłem i jednym detektorem. Dwa kierunki propagacji w pętli to CW (*clockwise*, zgodnie z ruchem wskazówek zegara) i CCW (*counter-clockwise*, przeciwnie).

Elementy funkcjonalne:
1. **Źródło światła**: na początku rozważamy LASER lub szerokopasmowe ASE, ale na tym etapie **nie przesądzamy wyboru**.
2. **Sprzęgacz 2×2**: rozdziela światło na dwa wyjścia oraz umożliwia ponowne złożenie fal wracających.
3. **Cewka światłowodowa**: dwie fale biegną tą samą drogą, ale w przeciwnych kierunkach; jej obrót daje fazę Sagnaca.
4. **Modulator fazy**: element włączony **blisko jednego końca cewki**, otrzymujący elektryczny sygnał sterujący.
5. **Fotodioda**: detektor mocy optycznej, nie bezpośredni miernik fazy.

**Dodatkowa konieczność funkcjonalna:** zewnętrzny sygnał sterujący modulatorem oraz sposób obserwacji/porównania prądu detektora z tym sterowaniem. Na tym etapie **nie projektujemy** jeszcze generatora, fotowzmacniacza TIA, ADC ani cyfrowej demodulacji.

## 2. Jak podłączone są porty sprzęgacza?

Wyobraźmy sobie idealny, wzajemny sprzęgacz z portami oznaczonymi A, B (po lewej) oraz C, D (po prawej).

\`\`\`text
   ŹRÓDŁO ─── A ┌─────────────────┐ C ── MODULATOR ─┐
                │  SPRZĘGACZ 2×2  │                 │
 FOTODIODA ── B └─────────────────┘ D ──────────────┤
                                    ▲               │
                                    └── CEWKA ◄─────┘
\`\`\`

*Schemat wyłącznie topologiczny; połączenie jest jednym obwodem od C do D przez modulator i cewkę. CW i CCW pokonują tę samą trasę w przeciwnych kierunkach.*

- Źródło podajemy na A, detektor przyłączamy do B.
- C i D łączymy **przez modulator i cewkę** w jeden tor (pętlę Sagnaca).
- Sprzęgacz dzieli światło z A na dwa kierunki obiegu pętli.
- Fale wracają z pętli do C i D, a sprzęgacz kieruje interferującą energię do portów A i B.

**Istotna subtelność:** dla idealnego symetrycznego sprzęgacza 50:50 i zerowej różnicy faz port B jest *ciemny*, a światło wraca w stronę portu A (źródła). Na porcie B sygnał rośnie, gdy pojawia się różnica faz. Ten wybór portu pozwala konsekwentnie przyjąć w modelu znak „minus” w odpowiedzi interferometrycznej. Port A pozostaje portem jasnym przy zerowej różnicy faz. W rzeczywistym stanowisku powrót do źródła może być problemem i czasem wymaga izolatora/cyrkulatora albo dodatkowej topologii; na tym etapie go pomijamy.

Nie należy mylić **sprzęgacza** z **modulatorem**. Sprzęgacz dzieli i łączy pola optyczne; modulator zmienia fazę w czasie.

## 3. Pełna podróż światła, krok po kroku

**Chwila 1: emisja.** Źródło wprowadza do światłowodu strumień światła. Wariant LASER ma stosunkowo wąskie widmo, ASE szerokie. Obydwa warianty należy w późniejszych badaniach porównywać przy jasno określonej mocy i widmie.

**Chwila 2: podział w sprzęgaczu.** W idealnym sprzęgaczu 50:50 połowa mocy idzie w jedną gałąź, a druga połowa w drugą (z uwzględnieniem właściwych faz amplitud). Nie są to dwa niezależne źródła; to **dwie składowe utworzone z jednego sygnału źródłowego**.

**Chwila 3: propagacja w przeciwnych kierunkach.** Jedna składowa wchodzi do modulatora, a następnie przechodzi przez cewkę; druga najpierw przechodzi przez cewkę, a modulator napotyka dopiero na jej końcu. Którą falę nazwiemy CW, zależy od przyjętej orientacji rysunku.

**Chwila 4: efekt obrotu.** Przy braku obrotu idealne przeciwbieżne propagacje mają ten sam czas obiegu; faza Sagnaca jest zerowa. Kiedy **cały czujnik/cewka obraca się** względem układu inercjalnego, pojawia się niezerowa różnica faz Sagnaca. Żaden wewnętrzny element nie musi kręcić się względem obudowy.

**Chwila 5: faza od modulatora.** Wspólny modulator zmienia się w czasie. CW i CCW mijają go w **różnych chwilach**, więc otrzymują inne wartości fazy. Nie jest to selektywne przyspieszanie jednej wiązki przez modulator.

**Chwila 6: ponowne złożenie.** Światło wraca do sprzęgacza, a jego pola interferują. Na porcie detektora B natężenie zależy od sumy różnicy faz Sagnaca i różnicowej fazy modulatora.

**Chwila 7: detekcja.** Fotodioda wytwarza prąd zależny od docierającej mocy. Aby wyznaczyć **znak** i niewielką wartość obrotu, docelowo porównujemy modulowany prąd z sygnałem referencyjnym sterowania (np. demodulacja synchroniczna). Sama fotodioda nie podaje wyniku w deg/s.

## 4. Dlaczego sama cewka wykrywa obrót?

Przy jednym obiegu wokół pola A, idealna różnica czasów propagacji fal w przeciwnych kierunkach, w pierwszym rzędzie względem Ω, wynosi

$$
\Delta t_S = \frac{4 A\,\Omega}{c^2}.
$$

Dla N jednakowych zwojów zamiast A występuje suma pól $N A$. Dla cewki o długości L i średniej średnicy D:

$$
\boxed{\Delta\varphi_S=\frac{2\pi L D}{\lambda c}\,\Omega.}
$$

- $\Omega$ [rad/s] — składowa prędkości kątowej wzdłuż osi cewki;
- $L$ [m] — długość włókna nawiniętego na cewkę;
- $D$ [m] — średnia średnica zwojów;
- $\lambda$ [m] — długość fali w próżni;
- $c$ [m/s] — prędkość światła w próżni.

Współczynnik skali fazy zależy od **łącznej sumy pól zwojów**, a przy jednakowej średnicy można użyć podanego wzoru. Jest to przybliżenie idealnej jednorodnej cewki, nie model wszystkich błędów fizycznych.

Przykład **modelowy, a nie pomiar:** L=1000 m, D=160 mm, λ=1550 nm → dla Ω=1°/s: około 0,0378 rad różnicy faz. Sama wartość jest bardzo mała, więc odczyt wymaga odpowiedniego punktu pracy / modulacji.

## 5. Dlaczego modulator jest przy końcu pętli?

Załóżmy czas propagacji przez cewkę

$$
\tau \approx \frac{n_g L}{c},
$$

gdzie $n_g$ jest grupowym współczynnikiem załamania. Dla modelowych L=1000 m i $n_g=1{,}4682$: $\tau\approx4{,}898\ \mu\mathrm{s}$.

Modulator ma pewną **chwilową nastawę** $\varphi_m(t)$ (np. sinusoidalnie zmienną). Fala mijająca modulator teraz dostaje inną fazę niż fala, która mija go po niemal całym czasie $\tau$. Dlatego przy modulatorze tuż przy końcu pętli:

$$
\boxed{\Delta\varphi_m(t)=\varphi_m(t)-\varphi_m(t-\tau)}
$$

(zależnie od oznaczenia kierunków i chwili obserwacji znak może być odwrócony). To jest **różnica faz na wyjściu**, a nie zmiana prędkości poruszania się światła wzdłuż cewki.

Przykład intuicyjny:
- jeśli modulator ma niezmiennie +0,5 rad, obie fale dostają +0,5 rad → różnica dodana przez modulator = 0;
- jeśli przy pierwszym przejściu nadaje +0,5 rad, a przy drugim −0,5 rad, powstaje różnica 1 rad;
- gdyby pojedynczy idealny modulator był dokładnie w symetrycznym środku pętli, obie fale mijałyby go w tym samym momencie i jego **różnicowe** działanie zanikałoby.

Sam **Sagnac** występuje również bez modulatora. Modulator służy do **lepszego odczytu**, a nie do „wytwarzania obrotu”.

## 6. Dlaczego fotodioda widzi obrót pośrednio?

Fotodioda nie mierzy fazy optycznej. Mierzy moc po interferencji. Dla portu B wybranego jako **port ciemny przy Δφ=0** i idealnego sprzęgacza 50:50 (bez strat), można użyć:

$$
P_B(t)=\frac{P_{\mathrm{in}}}{2}\bigl[1-\cos(\Delta\varphi_S+\Delta\varphi_m(t))\bigr].
$$

Dla $P_{\mathrm{in}}$ będącej mocą doprowadzoną do idealnego sprzęgacza, $0\le P_B\le P_{\mathrm{in}}$. Port A ma komplementarną charakterystykę:

$$
P_A(t)=\frac{P_{\mathrm{in}}}{2}\bigl[1+\cos(\Delta\varphi_S+\Delta\varphi_m(t))\bigr].
$$

Przy Ω=0 i **bez modulacji** port B jest ciemny. Przy małym obrocie jego średnia moc rośnie, ale **tak samo dla +Ω i −Ω**, gdyż cosinus jest funkcją parzystą. Ponadto przy Δφ=0 charakterystyka ma zerowe nachylenie.

Modulator nadaje znany przebieg fazy, dzięki któremu po **demodulacji synchronicznej** można otrzymać sygnał zmieniający znak wraz z kierunkiem obrotu. W pierwszym etapie ustalamy jedynie fizykę tego mechanizmu, bez implementowania elektroniki.

Modelowy prąd fotodiody dla monochromatycznego światła:

$$
i_D(t)=R(\lambda)\,P_B(t),
$$

gdzie $R$ [A/W] jest responsywnością detektora. Rzeczywiste $R$ może zależeć od $\lambda$. Fotodioda z TIA i DSP to **późniejszy poziom szczegółowości**.

## 7. Dlaczego już teraz rozważamy LASER i ASE?

Dwa pola interferujące pochodzą od **jednego** źródła. Przy idealnie zrównoważonych drogach propagacji nakładają się mimo szerokiego widma ASE. Nie jest potrzebna tak wysoka spójność czasowa jak przy interferowaniu niezależnych sygnałów o znacznie różnych drogach.

**LASER:** węższe widmo, zwykle większa spójność; wygodny jako punkt odniesienia matematycznego, ale światło po odbiciach i rozpraszaniu może spójnie nakładać się z sygnałem głównym.

**ASE:** szerokie widmo i krótszy czas spójności; może tłumić *część* niepożądanych interferencji pasożytniczych, lecz wprowadza własne kwestie RIN i stabilności widmowej.

**Na tym etapie nie wybieramy źródła.** Nie znamy jeszcze karty ani zmierzonego widma generatora ASE w laboratorium. W modelu idealnym oba źródła mogą dać porównywalny sygnał użyteczny. Uzasadnienie przewagi ASE wymaga rozpatrzenia **konkretnego mechanizmu zakłócającego**, nie samego wykresu idealnego sygnału.

## 8. Gdzie jest granica fizycznej poprawności E01?

Świadomie pomijamy: polaryzację, dwójłomność, depolaryzator, dyspersję i profil grupowego opóźnienia źródła, rzeczywiste odbicia i backscattering, optyczne straty, szumy źródła i fotodiody, TIA/ADC, dryft temperaturowy i błędy mechanicze. W eksperymencie szerokopasmowym będziemy musieli w następnym kroku opisać całkowanie po widmie.

To **model dydaktyczny**. Nie daje bezpośrednio rozdzielczości, dokładności ani deklarowanej klasy metrologicznej FOG.

## 9. Co jest wynikiem ukończenia Etapu 1.1?

**Gotowe teoretycznie:**
- [x] Zidentyfikowano pięć elementów funkcjonalnych.
- [x] Wybrano poglądową topologię portów jednego sprzęgacza 2×2.
- [x] Wyjaśniono przebieg obu fal.
- [x] Oddzielono fazę Sagnaca od modulacji i odczytu fotodiody.
- [x] Rozróżniono układ rzeczywisty i model skalarny bez polaryzacji.
- [x] Sformułowano rolę LASER/ASE bez przedwczesnego rozstrzygnięcia.

**Otwarte do dalszego etapu:**
- [ ] Ścisłe wyprowadzenie amplitud zespolonych dla portów A i B (sprzęgacz idealny 50:50).
- [ ] Ustalenie jednoznacznego znaku fazy oraz odniesienia demodulacji.
- [ ] Sprawdzenie i opis rzeczywistego widma źródła ASE.
- [ ] Zamiana modelu punktowej modulacji na możliwy do wykonania element.
- [ ] Uruchomienie osobnej symulacji E01.

## 10. Literatura i odnośniki

Odnośniki do źródeł z centralnej bibliografii:
- [L1] Lefèvre, przegląd IFOG i zasady Sagnaca: https://doi.org/10.1016/j.crhy.2014.10.007
- [L2] Lefèvre, *Fundamentals of the Interferometric Fiber-Optic Gyroscope*: https://doi.org/10.1364/OFS.1996.Tu3S1
- [L3] Skalský i in., modulacja i opóźnienie przeciwbieżnych fal: https://doi.org/10.3390/s19071710
- [L5] Nayak, źródła błędów i źródła optyczne FOG: https://doi.org/10.1364/AO.50.00E152
- Dodatkowy opis ideowego układu i wzorów (model obejmuje również elementy celowo pomijane w E01): https://www.mdpi.com/1424-8220/16/5/604

**Uwaga bibliograficzna:** wskazano publikacje i powiązane zagadnienia; dokładne numery stron oraz pełne dowody z cytowanych źródeł trzeba sprawdzić przed wykorzystaniem w gotowej pracy.

Kolejny krok: **E01/1.2 – ścisłe wyprowadzenie modelu matematycznego**, najpierw sprzęgacz + pola zespolone, potem Sagnac, modulator i detektor. Dopiero po kontroli analitycznej przejść do symulacji.