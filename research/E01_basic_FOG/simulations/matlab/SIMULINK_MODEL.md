# FOG-E01-MIS: graficzny model Simulink

**Status:** generator zapisywany w GitHub; model .slx powstaje dopiero po lokalnym uruchomieniu MATLAB R2023b. **Nie zweryfikowano jeszcze lokalnej kompilacji ani symulacji w MATLAB R2023b**.

**Generator:** [build_E01_simulink.m](build_E01_simulink.m)  
**Test lokalny:** [test_E01_simulink.m](test_E01_simulink.m)

## 1. Wygenerowanie i otwarcie modelu

Zaktualizuj repozytorium z PowerShell:

~~~powershell
git -C "C:\AGH\MAGISTER\Praca_Magisterska_Zyroskop\FOG" pull --ff-only origin main
~~~

Wklej do **MATLAB Command Window**:

~~~matlab
repo = "C:\AGH\MAGISTER\Praca_Magisterska_Zyroskop\FOG";
cd(repo);
addpath(fullfile(repo,"research","E01_basic_FOG","simulations","matlab"));
modelPath = build_E01_simulink();
~~~

Generator utworzy i otworzy **FOG_E01_SIMULINK.slx** w tym samym katalogu co skrypt generatora. Przy ponownym generowaniu dotychczasowy .slx zostanie zabezpieczony jako .slx.bak.

Później można otworzyć schemat bez ponownego generowania:

~~~matlab
open_system(fullfile(repo,"research","E01_basic_FOG","simulations", ...
    "matlab","FOG_E01_SIMULINK.slx"));
~~~

## Analizatory widma OSA bezpośrednio przy wyjściach obu źródeł

W grafie FOG znajdują się teraz dwa **oddzielne analizatory widma optycznego**:

- **`OSA LASER - analizator widma`** połączony z dodatkowym wyjściem widmowym LASER.
- **`OSA ASE - analizator widma`** połączony z dodatkowym wyjściem widmowym ASE.

Każde źródło ma trzy wyjścia. **Port 1** dostarcza do właściwego interferometru FOG obwiednię pola i uśredniony współczynnik Sagnaca. **Port 2** udostępnia wektor modelowanej gęstości mocy $S_\lambda$ w W/nm, a **port 3** powiązany wektor długości fali w nm. Porty 2 i 3 trafiają bezpośrednio do swojego bloku OSA. Dlatego analizatory wizualizują dane widmowe dostarczone przez źródło, a nie próbują odtworzyć widma optycznego za pomocą FFT sygnału o częstotliwości elektrycznej.

### Instalacja w istniejącym schemacie .slx, bez usuwania zmian

Najpierw zaktualizuj lokalne pliki skryptów (Git), następnie wykonaj w MATLAB R2023b:

~~~matlab
folder = "C:\AGH\MAGISTER\Praca_Magisterska_Zyroskop\FOG\research\E01_basic_FOG\simulations\matlab";
addpath(folder,"-begin");
rehash;
save_system('FOG_E01_SIMULINK');
add_E01_optical_analyzers();
~~~

Nie wywołuj ponownie `build_E01_simulink()`, jeżeli chcesz tylko dołożyć analizatory do istniejącego modelu. Operacja jest pomyślana jako **nieinwazyjne rozszerzenie**: dodaje brakujące wyjścia widmowe do źródeł, rysuje połączenia do nowych bloków i zapisuje obecny model.

Kliknij dwukrotnie **OSA LASER** lub **OSA ASE**, aby otworzyć wykres z polskimi podpisami. Widoczna jest długość fali [nm] i gęstość mocy widmowej [W/nm], wraz z mocą całkowitą i przybliżoną szerokością FWHM. Do wyświetlenia widma **nie trzeba uruchamiać symulacji**.

Sprawdzenie połączeń i samych wykresów:

~~~matlab
assert(test_E01_osa());
~~~

### Ważne ograniczenie fizyczne

To **OSA dla danych widmowych źródła**, a nie wirtualny spektrometr, który wylicza widmo na podstawie propagacji wszystkich optycznych częstotliwości. Nasz sygnał toru interferometru nadal jest **zredukowaną zespoloną obwiednią**, a nie pełnym polem optycznym. Gotowy blok DSP **Spectrum Analyzer** zastosowany na tym wyjściu pokazałby widmo częstotliwości elektrycznych (np. RIN), a nie szerokość linii optycznej lasera wokół 1550 nm.

Widma w OSA są profilami demonstracyjnymi z `E01_config.m` i `E01_source.m`: LASER FWHM 0,02 nm, ASE FWHM 20 nm i moc całkowita obu 1 mW. Nie są to pomiary laboratoriów. Jeżeli w przyszłości będziemy zmieniać widmo fizycznie w samym schemacie, konieczne będzie powiązanie modelu propagacji z tymi wyjściami widmowymi.

[show_E01_spectra.m](show_E01_spectra.m) nadal pozwala porównać oba widma na czterech wspólnych wykresach, ale nie jest wymagana do korzystania z dwóch bloków OSA.


## 2. Schemat fizyczny

~~~text
 [LASER] ────────┐
                 ├─ [WYBÓR ŹRÓDŁA] ── [SPRZĘGACZ 2×2] ──┐
 [ASE] ──────────┘                        |              |
                                         |  CW          | CCW
                                         v              v
                                       [CEWKA SMF: CW i CCW]
                                               ^
                          [MODULATOR FAZY] ----┤
                          [EFEKT SAGNACA] ----┘
                                               |
                                 [SPRZĘGACZ: REKOMBINACJA]
                                               |
                                         [FOTODIODA B]
                                               |
                                       [DEMODULACJA]
                                               |
                                         [OMEGA w °/s]
~~~

**Jest jedna fizyczna cewka:** podsystem „Cewka SMF - CW i CCW”, wewnątrz którego są matematyczne tory propagacji w przeciwnych kierunkach.

### Jak działa każdy podsystem?

| Blok | Modelowane zjawisko lub element |
|---|---|
| LASER / ASE | Dwa źródła o jednakowej mocy, ale różnych modelowych parametrach RIN i widmowo uśrednionym współczynniku Sagnaca |
| WYBOR ZRODLA | **Manual Switch**; podwójne kliknięcie przełącza górne źródło LASER na dolne ASE |
| Sprzegacz 2x2 - podzial | Podział pola: amplitudy mnożone przez 1/√2 oraz j/√2 |
| Modulator - dwa momenty | Wspólny modulator fazy obserwowany w chwilach t i t−τ |
| Faza Sagnaca | Faza proporcjonalna do obrotu, długości i średnicy cewki |
| Cewka SMF - CW i CCW | Fale C→D i D→C; pola zespolone mnożone przez exp(jφ) |
| Sprzegacz 2x2 - powrot | Interferencja fal przy ich powrocie do **przeciwnych portów** |
| Fotodioda - port B | Przejście z pola do mocy i prądu: i = R·|E_B|² |
| Demodulacja synchroniczna | Mnożenie przez sygnał referencyjny, filtracja i oszacowanie Ω |
| OSC - prad fotodiody / OSC - predkosc katowa | Obserwacja wyników w oscyloskopach |

## 3. Samodzielne uruchamianie

1. Podwójnie kliknij blok **WYBOR ZRODLA - kliknij 2x** (góra LASER, dół ASE).
2. Kliknij blok **Predkosc katowa [deg_s]** i wpisz np. 0, +1, -1 lub 10.
3. Naciśnij przycisk **Run** na pasku modelu Simulink.
4. Otwórz oscyloskopy **OSC - prad fotodiody** i **OSC - predkosc katowa**.
5. Zmień źródło i uruchom ponownie bez zmiany cewki czy modulatora.

Przebiegi mogą też zostać zapisane w wyjściach To Workspace: **E01_prad_fotodiody** i **E01_predkosc**.

Dane modelu pochodzą z [E01_config.m](E01_config.m). W szczególności długość cewki = 1000 m, średnica = 0,160 m, λ₀ = 1550 nm, a moc źródła = 1 mW. Są to **wartości demonstracyjne**, nie parametry potwierdzone laboratoryjnie.

## Jeden interaktywny wykres I(Ω), Rayleigh i Kerr w tym samym .slx

E01 zawiera rozszerzenia **tej samej cewki i tego samego toru optycznego**:
`Tor pasozytniczy - odbicie`, `Rayleigh - efektywne drogi`, `Kerr E0^2` oraz `Kerr gamma L asymetria`. Każde zjawisko ma osobny przełącznik `0=wyl 1=wl`. Źródła LASER i ASE podają swoje widma do OSA, a w torze interferometru odrębne efektywne współczynniki dla dodatkowych dróg.

### Rozbudowa istniejącego pliku, bez uruchamiania testu

~~~matlab
folder="C:\AGH\MAGISTER\Praca_Magisterska_Zyroskop\FOG\research\E01_basic_FOG\simulations\matlab";
addpath(folder,"-begin"); rehash;
save_system('FOG_E01_SIMULINK');
add_E01_parasitics();
add_E01_advanced_effects();
~~~

Oba instalatory zostawiają aktualny układ i wykonują kopie bezpieczeństwa przy modyfikacji istniejącego zapisanego modelu. Samo utworzenie modelu `build_E01_simulink()` również wstawia efekty, ale **nie uruchamia pomiarów zakresowych**.

W starszej wersji był przycisk `POMIAR prad od Omega - kliknij 2x`, który automatycznie wykonywał 84 uruchomienia. Teraz takie zachowanie jest usunięte. Aby wyłączyć callback w zapisanym starszym `.slx`, użyj jednorazowo:

~~~matlab
save_system('FOG_E01_SIMULINK');
disable_E01_auto_sweep();
~~~

### WYKRES: wyłącznie średni prąd fotodiody od prędkości kątowej

~~~matlab
wyniki=E01_current_layers(101);
~~~

To **jeden wykres** i 10 niezależnych warstw: LASER/ASE × (idealny, odbicie, Rayleigh, Kerr, wszystkie). Klikanie etykiet w legendzie przełącza widoczność warstw, nie wywołuje nowej symulacji. Pliki: jeden edytowalny wykres `.fig` oraz jeden `.csv` z wartościami prądu [µA] i prędkości [°/s].

Funkcja korzysta z **widmowo uśrednionego rozwiązania analitycznego** obecnego uproszczonego E01, w którym przy sinusoidalnej modulacji średni fotoprąd jest obliczany po spektrum przy użyciu współczynnika `J0(beta)` i fazy Sagnaca. Wersja `sweep_E01_simulink(nPoints)` deleguje obecnie do tej samej funkcji i **nie uruchamia 84 symulacji silnika .slx**. Zwykły **Run** w `.slx` nadal wykonuje jedną symulację w dziedzinie czasu z aktualnie włączonymi efektami. Użytkownik uruchamia eksperyment sam.

**Ograniczenia:** dodatkowe odbicie reprezentuje jedną drogę; Rayleigh to skończony zestaw modelowych opóźnionych ścieżek (domyślnie 48), nie rozwiązanie rozproszonego pola Rayleigha w kilometrze włókna; Kerr to efektywne różnicowe przesunięcie fazy zależne od nierównowagi mocy CW/CCW, a nie pełna propagacja nieliniowa. Model widmowy wykresu uwzględnia iloczyny krzyżowe hipotetycznych odbić, natomiast schemat Simulink używa ich zredukowanego odpowiednika koherentnego i tła niespójnego: **wyniki wykresu i próbki czasowe Simulinka nie są identycznymi implementacjami wszystkich przybliżeń**. Oba służą badaniu tendencji, nie certyfikacji właściwości urządzenia.

Źródła korzystają z `E01_source.m`: profile `GAUSSIAN`, `LORENTZIAN` albo opcjonalny rzeczywisty profil `CSV` (`lambda_nm,S_W_per_nm`) przy równej mocy całkowitej. Przed interpretacją ilościową w pracy potrzebna jest walidacja w MATLAB R2023b i pomiary laboratoryjne. Polaryzacja i szczegółowy bilans strat są na razie świadomie pominięte.


## 4. Dlaczego prawie nie widać różnicy LASER/ASE na fotodiodzie?

**Średni przebieg Sagnaca będzie niemal identyczny.** Obie przeciwbieżne fale powstają z tego samego źródła i pokonują zrównoważoną drogę. Duży sygnał po modulacji fazowej maskuje niewielkie źródłowe fluktuacje mocy, dlatego porównywanie tylko oscyloskopu `OSC - prad fotodiody` jest niewystarczające.

W generatorze udostępniono dodatkowy podsystem **`Diagnostyka szumu fotodiody`**. Oblicza w każdej chwili idealny fotoprąd z bieżących faz CW i CCW:

$
i_{B,\mathrm{ideal}}(t)=\frac{RP_{\rm in}}2
\left[1-\cos(\varphi_{\rm CCW}(t)-\varphi_{\rm CW}(t))\right],
$

a następnie resztę $\delta i_B(t)=i_{B,\mathrm{model}}(t)-i_{B,\mathrm{ideal}}(t)$, wyświetlaną w **µA**. Tę resztę obejrzysz w nowym oscyloskopie:

**`OSC - fluktuacje fotodiody [uA]`**

W modelu Simulink fluktuacje są **tylko przykładowym szumem intensywności źródeł (RIN)**, bez pełnego modelowania szumu śrutowego czy polaryzacji.

### Automatyczne porównanie obu źródeł

Po wygenerowaniu modelu `.slx` wykonaj:

~~~matlab
raport = compare_E01_simulink();
~~~

Skrypt [compare_E01_simulink.m](compare_E01_simulink.m) sam symuluje LASER i ASE przy tych samych pozostałych parametrach oraz otwiera **trzy wykresy z polskimi podpisami**:

1. Prądy fotodiody (prawie pokrywające się średnie sygnały).
2. Wyizolowane modelowe fluktuacje fotodiody dla LASER i ASE.
3. Porównanie RMS tych fluktuacji w µA.

Skrypt drukuje także wartości RMS w Command Window. Zostawia stan przełącznika źródła taki, jaki był przed porównaniem.

**Rzeczywisty sens porównania:** w wybranym zestawie **demonstracyjnych** parametrów, szerokopasmowy szum dudnień ASE może być większy niż przyjęty RIN lasera. Nie jest to dowód, że laser jest lepszy od ASE jako źródło FOG: korzyści wynikające z krótkiego czasu spójności ASE dotyczą głównie części *zakłóceń koherentnych*. Te wymagają osobnego modelu dodatkowych dróg optycznych i **nie są jeszcze zasymulowane w nowym `.slx`**.

**Uwaga dotycząca wersji lokalnej:** jeżeli w Twoim PowerShell pojawiło się `Your local changes ... would be overwritten by merge`, Git nie zaktualizował kodu. Najpierw wykonaj bezpieczną procedurę zachowania plików i `git pull`; nie kasuj lokalnych wyników ani ustawień. Przed wygenerowaniem nowego modelu zamknij stary schemat Simulinka.

## 5. Wyprowadzenie matematyczne

Macierz sprzęgacza:

$$
\begin{bmatrix}E_C\\ E_D\end{bmatrix}
=\frac{1}{\sqrt2}\begin{bmatrix}1&j\\j&1\end{bmatrix}
\begin{bmatrix}E_A\\0\end{bmatrix}.
$$

Fazy dla dwóch kierunków:

$$
\varphi_{\rm CW}=\varphi_m(t-\tau)-\frac{\Delta\varphi_S}{2},
\qquad
\varphi_{\rm CCW}=\varphi_m(t)+\frac{\Delta\varphi_S}{2}.
$$

Ponowne połączenie na porcie B:

$$
E_B=\frac{jE_C^{\rm powrot}+E_D^{\rm powrot}}{\sqrt2},
\qquad i_B=R|E_B|^2.
$$

Pierwsza harmoniczna prądu po demodulacji małosygnałowej jest skalowana współczynnikiem Sagnaca wybranego źródła. Więcej: [E01/1.2](../../01_02_mathematical_derivation.md).

## 6. Ważne ograniczenia modelu

To **model optycznych zespolonych obwiedni**, a nie symulacja nośnej światła o częstotliwości około 193 THz. LASER i ASE różnią się źródłowym RIN i przybliżonym efektywnym współczynnikiem skali; pełne optyczne widmo ASE nie jest propagowane jako tysiące losowych fal.

RIN jest uproszczonym dyskretnym modelem fluktuacji mocy. Nie symulujemy dokładnie elektroniki odbiorczej, szumu śrutowego, depolaryzatora, birefringencji, strat ani pełnego rozproszonego Rayleigha. Efektywne odbicia, modelowe ścieżki Rayleigha i nieliniowa faza Kerra są rozszerzeniami jakościowymi, nie sprzętowo skalibrowanymi efektami. W konsekwencji z tego schematu **nie wyznaczamy jeszcze rzeczywistej dokładności, ARW ani bias stability**.

Jedna cewka jest reprezentowana przez dwie ścieżki matematyczne, ale jej parametry są wspólne. W ten sposób modelujemy wzajemność dróg i efekt Sagnaca bez tworzenia dwóch fizycznych cewek.

## 7. Test po wygenerowaniu

Uruchom w MATLAB:

~~~matlab
assert(test_E01_simulink());
~~~

Test powinien skompilować schemat i wykonać symulacje dla obu źródeł, sprawdzając skończoność i zmianę przebiegu fotodiody. To **lokalny test implementacyjny**, nie pomiar.

## 8. Porównanie ze skryptowym E01

Poprzedni [run_E01.m](run_E01.m) wytwarza osiem wykresów PNG z matematycznego modelu uśredniającego widmo i z modelem szumów. Nowy **FOG_E01_SIMULINK.slx** jest natomiast **interaktywnym schematem blokowym** z dostępem do wnętrza elementów optycznych. Modele mają spójne założenia podstawowe, lecz inne szczegóły uproszczeń źródła i przetwarzania.

Oba są niezależne od historycznych modeli FOG_v1–v8.1 i nie modyfikują ich.
