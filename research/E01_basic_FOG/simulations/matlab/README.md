# FOG-E01-MIS: pierwsza symulacja MATLAB (LASER / ASE)

**Status:** kod zaimplementowany, **oczekuje na uruchomienie i sprawdzenie w MATLAB R2023b**.  
**Przeznaczenie:** dydaktyczny model interferometru Sagnaca dla E01/1.4; nie odtwarza parametrów rzeczywistego sprzętu laboratoryjnego.  
**Wymagania:** podstawowy MATLAB R2023b (bez Simulinka i specjalistycznych toolboxów).  
**Gałąź repozytorium:** main.

## 1. Model fizyczny

Zastosowano wspólny, idealny sprzęgacz 2×2 (50:50), jedną cewkę, jeden modulator fazy przy końcu pętli i jeden idealny detektor w porcie **B**, ciemnym dla zerowej różnicy faz bez modulacji.

- Dwie przeciwbieżne fale CW/CCW pochodzą z tego samego źródła.
- Modulacja różnicowa: $\Delta\varphi_m(t)=\varphi_m(t)-\varphi_m(t-\tau)$.
- Sagnac: $\Delta\varphi_S(\lambda)=2\pi LD\Omega/(\lambda c)$.
- Widmowa moc portu B: $P_B(t)=\tfrac12\int S_{\rm in}(\lambda)[1-\cos(\Delta\varphi_S+\Delta\varphi_m)]\,d\lambda$.
- Detektor: $i_B(t)=R\,P_B(t)$ z **przyjętą stałą** responsywnością $R$.
- Idealny lock-in: amplituda $I_1=2\langle i_B(t)\cos(\omega_m(t-\tau/2))\rangle$.

Dla źródła LASER i ASE **nic poza widmem źródła się nie zmienia**, w szczególności: L, D, moc wejściowa, responsywność, modulator, opóźnienie, fotodioda i przetwarzanie. Zestaw wzorów i wyprowadzeń: [Etap 1.2](../../01_02_mathematical_derivation.md). Różnice źródeł: [Etap 1.3](../../01_03_laser_vs_ase.md).

## Najprostszy sposób: przełączasz źródło w skrypcie

Otwórz **[E01_start.m](E01_start.m)** w MATLAB R2023b. Na początku ustaw:

```matlab
SOURCE = "LASER";  % zamień na "ASE" lub "BOTH"
```

Kliknij **Run**. Otrzymasz dwa szczególnie ważne wykresy:

- **`03_photodiode.png`**: prąd fotodiody w czasie dla wybranego źródła (średni sygnał Sagnaca + losowe fluktuacje).
- **`07_source_noise.png`**: same fluktuacje względem przebiegu deterministycznego, w µA, oraz ich wartość skuteczna RMS. Tu łatwo zobaczyć, jak różnią się przyjęte modele LASER i ASE.

Nie zmieniamy cewki, modulatora ani sprzęgacza. Porównanie obu źródeł przy tym samym układzie uzyskasz wpisując `SOURCE = "BOTH"`.

### Dlaczego średnie przebiegi mogą wyglądać identycznie?

W idealnym zrównoważonym FOG obie fale są kopiami tego samego pola świetlnego i **średnia** moc po interferencji jest niemal taka sama dla lasera oraz ASE o porównywalnej mocy i centralnej długości fali. Samo podstawienie dwóch szerokości widma nie może wiarygodnie wygenerować dużej różnicy w średnim przebiegu.

Wprowadziliśmy oddzielny **statystyczny model źródła i detektora** w [E01_noise.m](E01_noise.m), obejmujący:
- dla ASE przybliżony nadmiarowy szum intensywności od dudnień składowych optycznych;
- dla lasera hipotetyczny parametr RIN (nie ma danych pomiarowych konkretnego lasera);
- dla obu źródeł przybliżony szum śrutowy fotodiody.

Domyślnie `cfg.noise_enabled = true`. Ustawienie `false` w [E01_config.m](E01_config.m) przywraca przebieg deterministyczny. Wszystkie szumy mają jawnie zadaną szerokość pasma elektrycznego i powtarzalne ziarno losowe.

**Osobno, domyślnie WYŁĄCZONY** jest wcześniejszy dydaktyczny model pojedynczego opóźnionego pola optycznego:
`cfg.parasitic_enabled = false`. Gdy włączysz go ręcznie, pokazujemy wpływ spójności na zakłócenie pasożytnicze, **nie** rozpraszanie Rayleigha w całym włóknie.

Dane są demonstracyjne: FWHM LASER 0,02 nm, FWHM ASE 20 nm, laser RIN −155 dB/Hz, detektor 0,8 MHz i moc wejściowa 1 mW. **Żaden z tych parametrów źródeł nie jest pomiarem laboratoryjnym.** Model ASE jest zredukowanym modelem statystycznym w paśmie elektrycznym, a nie bezpośrednią symulacją wszystkich losowych oscylacji pola optycznego.

## Dwa analizatory widma optycznego przy źródłach LASER i ASE

Schemat Simulink ma **dwa OSA połączone bezpośrednio z wyjściami widmowymi źródeł**:
`OSA LASER - analizator widma` oraz `OSA ASE - analizator widma`.

Jeżeli masz już otwarty model `FOG_E01_SIMULINK.slx`, **nie trzeba go generować od nowa**. Zapisz bieżące zmiany i dodaj analizatory:

~~~matlab
save_system('FOG_E01_SIMULINK');
add_E01_optical_analyzers();
~~~

Dwukrotne kliknięcie bloku pokazuje widmo optyczne źródła w **nm** i **W/nm**. Widma są opisane po polsku. Ten podgląd działa bez DSP System Toolbox, bo korzysta z zadanych przez źródło wektorów widmowych, a nie FFT z obwiedni elektrycznej.

Oba nowe analizatory są automatycznie dołączane również do modeli tworzonych przez [build_E01_simulink.m](build_E01_simulink.m). Szczegółowo: [SIMULINK_MODEL.md](SIMULINK_MODEL.md).

Istniejąca [show_E01_spectra.m](show_E01_spectra.m) nadal umożliwia osobne porównanie źródeł na wspólnych wykresach.

**Istotne:** aktualny model FOG nadal propaguje uproszczoną obwiednię optyczną. Analizatory wizualizują *widma zadane dla źródeł* (FWHM 0,02 nm LASER i 20 nm ASE, po 1 mW), nie widmo wyliczone z rzeczywistego sygnału optycznego po propagacji.


## Jeden interaktywny wykres prądu od prędkości kątowej

Zgodnie z zakresem eksperymentu E01 generujemy **tylko jeden wykres**: średni prąd fotodiody `I(Ω)` w µA względem prędkości kątowej w °/s. Każde źródło LASER i ASE ma pięć niezależnych warstw: **idealny**, **odbicie**, **Rayleigh**, **Kerr** i **wszystkie efekty**. Po kliknięciu nazwy warstwy w legendzie MATLAB ją pokazuje lub ukrywa **bez ponownego liczenia**.

### 1. Rozbuduj ten sam schemat Simulink (bez obliczania serii)

Po aktualizacji repozytorium `main` otwórz swój `FOG_E01_SIMULINK.slx`, zapisz ewentualne zmiany i uruchom:

~~~matlab
folder = "C:\AGH\MAGISTER\Praca_Magisterska_Zyroskop\FOG\research\E01_basic_FOG\simulations\matlab";
addpath(folder,"-begin");
rehash;
save_system('FOG_E01_SIMULINK');
add_E01_parasitics();       % pojedyncze odbicie, jesli go jeszcze nie ma
add_E01_advanced_effects(); % Rayleigh + Kerr w TYM SAMYM .slx
~~~

Funkcje dodają **bloki** i zapisują kopie bezpieczeństwa istniejącego schematu, nie uruchamiają pomiaru zależności prądu od Ω. Po zwykłym **Run** wykonuje się tylko jedna symulacja aktualnych ustawień. Do wyłączenia/zapalenia efektów w samym Simulinku służą `Odbicie 0=wyl 1=wl`, `Rayleigh 0=wyl 1=wl`, `Kerr 0=wyl 1=wl`.

Nowe schematy generowane przez `build_E01_simulink()` zawierają te elementy automatycznie. Jeśli model ma stary przycisk `POMIAR prad od Omega - kliknij 2x`, użyj `disable_E01_auto_sweep()`: stary callback nie będzie sam uruchamiał symulacji.

### 2. Wyłącznie na Twoje polecenie wygeneruj jeden wykres

~~~matlab
wyniki = E01_current_layers(101);
~~~

Stara komenda `sweep_E01_simulink(21)` również wyświetla obecnie **tylko ten sam jeden interaktywny wykres**. Nie wykonuje już 84 startów silnika Simulink. Matematyczno-widmowy model I(Ω) oblicza średni prąd z równań źródła, Sagnaca i modulacji oraz dodatkowych dróg, **a nie z 84 eksportowanych próbek .slx**. Używa tej samej konfiguracji E01 i pokazuje przebiegi dla ustalonych wariantów modelu. Wariant pełny służy do badań porównawczych; nie jest walidacją ilościową sprzętu.

Wyniki: jeden interaktywny `.fig` i jeden `.csv` w nowym katalogu `results/EXP_E01_I_vs_Omega_.../`. W legendzie klikaj warstwę, aby ją ukryć lub przywrócić. Przed uruchomieniem możesz zmienić `E01_config.m`.

### Fizyka, uproszczenia i widma źródeł

- **Kerr:** efektywna różnicowa faza `gamma_nonlin * L * P * asymetria_CW_CCW`. Przy idealnej równowadze mocy wkład Kerra znika. To nie propagacja NLSE.
- **Odbicie:** dodatkowa droga o regulowanym opóźnieniu `cfg.parasitic_delay_ps`, udziale mocy i fazie. Interferencja jest uśredniana po widmie LASER/ASE.
- **Rayleigh:** skończony zbiór 48 hipotetycznych słabych dróg o wspólnych losowych fazach dla obu źródeł, opóźnieniach i łącznej mocy. **Nie jest** to zwalidowany model rozproszonego Rayleigha w 1000 m SMF.
- **Źródła:** `E01_source.m` obsługuje widma `GAUSSIAN`, `LORENTZIAN` i opcjonalnie widmo pomiarowe `CSV` (kolumny: `lambda_nm,S_W_per_nm`). Przy porównaniu oba profile są normowane do jednakowej mocy źródła.

Na tym etapie celowo **pomijamy polaryzację i szczegółowe straty optyczne**. Wyjściowa charakterystyka średniego prądu nie zastępuje charakterystyki dokładności żyroskopu ani oceny RIN, shot noise, ARW czy bias stability. Schemat Simulink korzysta z uproszczonego ekwiwalentu zespolonego pola dla Rayleigha, a wykres widmowo uśrednia wszystkie podane efektywne ścieżki; są to zgodne koncepcyjnie, ale nie identyczne numerycznie poziomy przybliżenia.


## Graficzny model Simulink (osobna wersja .slx)

Jeżeli chcesz **schemat z elementami optycznymi, a nie sam skrypt z wykresami**, przejdź do [SIMULINK_MODEL.md](SIMULINK_MODEL.md). Generator [build_E01_simulink.m](build_E01_simulink.m) tworzy lokalnie edytowalny **FOG_E01_SIMULINK.slx**. Zawiera źródło LASER/ASE z przełącznikiem, sprzęgacz 2×2, **jedną cewkę CW/CCW**, modulator, fotodiodę, demodulację i oscyloskopy. Wymaga MATLAB R2023b i Simulink; test uruchomieniowy jest osobny: [test_E01_simulink.m](test_E01_simulink.m).

## 2. Pliki

| Plik | Zadanie |
|---|---|
| **[E01_start.m](E01_start.m)** | **Główny skrypt: jedna linia do przełączenia LASER/ASE i przycisk Run** |
| [E01_config.m](E01_config.m) | Parametry cewki, obu źródeł, pasma i szumów |
| [E01_source.m](E01_source.m) | Widmo LASER/ASE w W/nm i wagi całkowania |
| [E01_model.m](E01_model.m) | Fazy, idealna i średnia moc/prąd oraz szumowy przebieg detektora |
| [E01_noise.m](E01_noise.m) | Zredukowany model fizyczny excess RIN ASE, RIN lasera i szumu śrutowego |
| [run_E01.m](run_E01.m) | Przełącznik źródła, osiem wykresów, eksport CSV/JSON |
| [test_E01.m](test_E01.m) | Testy numeryczne kontrolujące równania i znaki |

## 3. Uruchomienie

W MATLAB-ie przejdź do katalogu głównego sklonowanego repozytorium `FOG` i wklej:

```matlab
run(fullfile("research","E01_basic_FOG","simulations","matlab","E01_start.m"));  % Edit SOURCE in this script
```

Alternatywnie, po `addpath` możesz uruchomić wariant z konsoli:

```matlab
addpath(fullfile(pwd,"research","E01_basic_FOG","simulations","matlab"));
assert(test_E01());
out = run_E01("LASER");
out = run_E01("ASE");
```

Program domyślnie zapisuje obrazy i pliki CSV w **oddzielnych katalogach dla każdego źródła**, np. `results/EXP_E01_laser_source_noise_demo/` i `results/EXP_E01_ase_source_noise_demo/`. Katalogi powstają **lokalnie podczas wykonania**. Nie zakładamy, że wyniki już zostały wykonane lub są zapisane w GitHubie.

W razie potrzeby wskaż własny katalog:

```matlab
out = run_E01("BOTH", "C:\FOG_E01_wyniki");
```

Aby zmienić geometrię, moc i częstotliwość modulacji, edytuj [E01_config.m](E01_config.m), zachowując wartości w odpowiednich jednostkach.

## 4. Co jest widoczne?

W wyniku uruchomienia otrzymasz osiem ilustracji:

1. `01_spectra.png` – dwa widma i rzeczywiste skale mocy widmowej (laser wąski, ASE szerokie).
2. `02_modulator.png` – faza w obu chwilach przejścia i różnica faz.
3. **`03_photodiode.png` – losowy przebieg prądu fotodiody wybranego źródła** dla $\Omega=-1,0,+1$ deg/s, z linią idealnego odniesienia przy włączonym modelu pola pasożytniczego.
4. `04_laser_vs_ase.png` – zaszumiony prąd dla obu źródeł (górny panel) oraz **idealna** charakterystyka demodulacji (dolny panel).
5. `05_coherence_surrogate.png` – funkcja $|\gamma(\delta t_p)|$ dla **dodatkowej, hipotetycznej** drogi pasożytniczej.
6. `06_linear_estimate.png` – idealizowana estymacja liniowa i jej nieliniowość poza pobliżem zera.
7. **`07_source_noise.png`** – rzeczywista skala dodanych modelowych fluktuacji (µA i RMS).
8. **`08_noisy_lockin.png`** – demodulowany prąd ze skończonego zaszumionego przebiegu, porównany z odpowiedzią deterministyczną (oraz różnica w nA).

### Jak interpretować każdy wykres?

| Nr | Pytanie, na które odpowiada wykres | Jak czytać wynik? |
|---|---|---|
| **01: Widma źródeł** | Czym LASER różni się od ASE? | Wąski pik lasera oznacza moc skupioną w małym zakresie długości fali. ASE ma moc rozłożoną szerzej. Oba widma w symulacji mają **tę samą całkowitą moc**; wyższy pik nie oznacza większej mocy całkowitej. |
| **02: Modulator** | Dlaczego jeden modulator tworzy różnicę faz? | Porównaj fazę w chwili `t`, fazę opóźnioną o `τ` i ich różnicę. Fale widzą inne nastawy modulatora, ale żadna nie porusza się przez to szybciej. |
| **03: Fotodioda** | Co rejestrujemy elektrycznie? | To prąd fotodiody dla różnych znaków obrotu. Szybka zmiana związana jest ze sterowaniem fazy; drobne losowe wahania pochodzą z **modelowych** szumów optycznych i śrutowych. Sam przebieg prądu nie jest jeszcze prędkością w °/s. |
| **04: Porównanie LASER/ASE** | Czy źródło zmienia odczyt FOG? | Górna część pokazuje prąd **z modelowym szumem** przy +1 °/s. Dolna część pokazuje **idealną**, pozbawioną szumów charakterystykę demodulacji. Nakładanie się krzywych dolnych jest oczekiwane w idealnym zrównoważonym FOG. |
| **05: Spójność** | Dlaczego ASE może ograniczać zakłócenia od odbić? | Im mniejszy moduł `|γ(Δt)|` przy dodatkowym opóźnieniu, tym słabiej dana opóźniona kopia światła może interferować z sygnałem użytecznym. To **model pojedynczej drogi**, nie symulacja całego rozpraszania Rayleigha. |
| **06: Liniowość odczytu** | W jakim zakresie przybliżenie daje poprawną prędkość? | Krzywa pokrywająca się z prostą oznacza zgodność oszacowania i wartości rzeczywistej. Odchylenie przy większych obrotach wynika z nieliniowej charakterystyki interferometru w otwartej pętli. |
| **07: Szum źródła** | Dlaczego LASER i ASE mogą dawać różne fluktuacje? | Górny wykres pokazuje różnicę między prądem zaszumionym a prądem bez szumu. Dolny przedstawia wartość skuteczną (RMS) tej różnicy. Wielkość szumu zależy od **przyjętych parametrów RIN**, nie od zmierzonych parametrów urządzenia. |
| **08: Zaszumiona demodulacja** | Jak szum przenosi się na oszacowanie obrotu? | Górny wykres porównuje demodulację z zaszumionych próbek i wynik deterministyczny. Dolny pokazuje odchyłkę w nA po uśrednieniu przez określoną liczbę okresów. Pojedyncza realizacja nie wystarczy do wyznaczenia dokładności żyroskopu. |

**Ważne przy porównaniach:** jeżeli dwa przebiegi średnie LASER i ASE prawie się pokrywają, to nie jest błąd. FOG wykorzystuje dwie kopie światła z jednego źródła pokonujące prawie równe drogi. Zauważalne różnice mogą pojawić się w **szumie** lub w zachowaniu dodatkowych **niepożądanych dróg optycznych**, ale nie należy ich wymuszać przez zmianę geometrii między wariantami.

CSV `spectrum_*.csv` przechowuje widmo i wagi, `waveform_*.csv` przebiegi czasowe wraz z **osobnymi kolumnami idealnego i obserwowanego prądu**, `sweep_*.csv` charakterystykę odczytu i `coherence_*.csv` moduł korelacji. Plik `config.json` zawiera parametry i wersję MATLAB-a.

## 5. Parametry demonstracyjne (nie są to pomiary)

| Wielkość | Wartość |
|---|---:|
| $L$ | 1000 m |
| $D$ | 0,160 m |
| $\lambda_0$ | 1550 nm |
| $n_g$ | 1,4682 |
| $P_{\rm in}$ | 1 mW |
| Laser, FWHM | **0,02 nm, tylko DEMO** |
| ASE, FWHM | **20 nm, tylko DEMO** |
| Responsywność | 0,9 A/W, stała |
| $f_m$ | $1/(2\tau)$, około 102,095 kHz |
| $\varphi_0$ | 0,92 rad (różnicowo $\beta=1,84$ rad) |
| Liczba próbek widma | 801 na źródło |
| Czas obserwacji | 16 okresów modulacji |
| Dodatkowy tor optyczny | **wyłączony domyślnie**; włączany opcjonalnie |
| Dodatkowe opóźnienie | 1 ps (DEMO) |
| Moc pola pasożytniczego | 0,04% mocy wejściowej (DEMO) |
| Faza pola pasożytniczego | 0,8 rad (DEMO) |
| Model RIN ASE | 2/(M·B_eff), M=1 (skalarne założenie demonstracyjne) |
| Model RIN lasera | −155 dB/Hz (parametr przykładowy) |
| Pasmo elektryczne detektora | 800 kHz (model idealnego filtru) |
| Model szumu śrutowego | wariancja 2qI·B_e |

Szerokości widmowe **nie są** danymi producentów. Zastosowano niezależne siatki dla wąskiego lasera i szerokiego ASE, z całkowaniem metodą trapezów. To chroni przed problemem pominięcia wąskiej linii lasera na grubej siatce ASE.

## 6. Co pokazuje, a czego NIE pokazuje, model?

**Prawidłowe obserwacje:** interferencja w zrównoważonej pętli; wpływ sinusoidalnej modulacji; znak obrotu po idealnym lock-in; spektralne uśrednianie sygnału; różnica spójności źródeł przy zewnętrznym opóźnieniu.

**Dodatkowy tor jest modelem fenomenologicznym:** do pola detektora dodajemy jedno opóźnione pole pasożytnicze o zadanej amplitudzie i fazie, całkujemy jego interferencję po widmie i obserwujemy, jak krótszy czas spójności ASE zmniejsza wpływ tego pola. Nie jest to pełny, bilansujący wszystkie porty model sieci rozpraszającej, więc z tego wariantu nie wyznaczamy absolutnego bilansu mocy ani dokładności prototypu.

**Model NIE obejmuje:** polaryzacji, depolaryzatora, rozpraszania Rayleigha w całej cewce, strat sprzęgacza i włókna, widmowej odpowiedzi fotodiody, dyspersji, szczegółowej statystyki losowego pola optycznego ASE, rzeczywistych zmierzonych widm i PSD RIN, nieliniowości i pasma TIA, ADC, dryftu i sprzętowej kalibracji. Zaimplementowany RIN i szum śrutowy są przybliżeniem na poziomie elektrycznej obwiedni detekcji.

**Szczególnie ważne:** wykres spójności jest *oddzielną analizą modelowej drogi pasożytniczej*, a nie zasymulowanym rozpraszaniem Rayleigha w całym FOG. Nie należy na jego podstawie podawać wartości ARW lub bias stability.

## Awaria zapisu wykresów w MATLAB R2023b

Jeżeli pojawi się błąd Java `OutputHelperProcessingException` lub `NullPointerException` podczas `exportgraphics`, problem dotyczy eksportu grafiki, **nie musi** dotyczyć modelu FOG.

Od aktualizacji `run_E01.m` program najpierw używa `print(...,'-dpng','-r160')`; dopiero w razie awarii próbuje `exportgraphics` i zapis `.fig`. Nieudany eksport pojedynczego obrazu nie powinien zatrzymywać dalszego obliczenia i eksportu CSV.

**Istotne:** jeżeli Command Window wypisuje dawny komunikat `SOURCE SWITCH DEMO (no polarization / noise)`, MATLAB uruchamia **starszą** kopię funkcji. Po aktualizacji `main` sprawdź w MATLAB:

~~~matlab
folder = "C:\AGH\MAGISTER\Praca_Magisterska_Zyroskop\FOG\research\E01_basic_FOG\simulations\matlab";
addpath(folder,"-begin");
clear run_E01 E01_start E01_config
rehash
which run_E01 -all
assert(contains(fileread(which("run_E01")), "print(fig,pngPath"));
~~~

Wynik `which` powinien wskazać dokładnie powyższy katalog. Jeśli `assert` zgłasza błąd, nie używasz jeszcze zaktualizowanego skryptu. W przypadku lokalnych zmian w repozytorium `git pull --ff-only` może odmówić aktualizacji; sprawdź `git status` i nie kasuj swoich zmian przez `reset --hard`.

**Inny program:** `E01_start.m` uruchamia skrypt z wykresami, a [build_E01_simulink.m](build_E01_simulink.m) tworzy **graficzny model Simulink .slx**.

## 7. Etap weryfikacji

Testy [test_E01.m](test_E01.m) wymagają wykonania w MATLAB-ie. Równania zaimplementowane w E01 zweryfikowano dodatkowo niezależnym obliczeniem numerycznym, ale **nie uruchomiono w tym środowisku MATLAB-a**, więc syntaktyczna i wykonawcza zgodność MATLAB R2023b pozostaje do lokalnego potwierdzenia.

Osiągnięty cel implementacyjny: źródło można przełączyć **jedną linijką w E01_start.m**; oba warianty zachowują ten sam model cewki, sprzęgacza, modulatora i toru detekcji. Opcjonalny pojedynczy tor pasożytniczy jest identyczny w obu wariantach. Jego obecność jest fizycznym powodem mocniej różniących się przebiegów.

W kolejnych podetapach rozpoczniemy walidację i analizę wrażliwości. Nie przenosimy tutaj wcześniejszych wyników v1–v8.1 bez osobnego uzasadnienia.
