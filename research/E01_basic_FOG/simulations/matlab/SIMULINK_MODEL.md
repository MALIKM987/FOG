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

## Podgląd obu widm bez przebudowy modelu

Otwórz aktualny schemat Simulink, **zapisz niezapisane zmiany** i w MATLAB wpisz:

~~~matlab
save_system('FOG_E01_SIMULINK');
show_E01_spectra();       % Natychmiast otwiera wykresy obu źródeł
add_E01_spectrum_view();  % Dodaje do obecnego .slx klikalny blok widm
~~~

**Nie uruchamiaj ponownie `build_E01_simulink()` tylko po to, by zobaczyć widma.** Generator celowo odmawia nadpisania schematu, który ma niezapisane zmiany. Dodanie bloku `WIDMA LASER I ASE - kliknij 2x` do otwartego, zapisanego modelu nie usuwa istniejących podsystemów i połączeń.

Nowo wygenerowane modele dostają taki blok automatycznie. Dwukrotne kliknięcie otwiera polskie wykresy za pomocą oficjalnego callbacku `OpenFcn` w Simulinku.

[show_E01_spectra.m](show_E01_spectra.m) rysuje **cztery ujęcia**:

1. Wspólna oś długości fali: laser jako wąski pik, ASE jako szerokie widmo.
2. Zbliżenie do okolic 1550 nm, tak aby było widać szczegóły lasera.
3. Bezwzględna gęstość mocy `W/nm` na osi logarytmicznej.
4. Moc skumulowana `mW` pokazująca, że oba źródła mają tę samą moc całkowitą.

**To podgląd matematycznych widm z `E01_config.m` i `E01_source.m`, a nie odczyt widma z rzeczywistego urządzenia ani analizator widma optycznego dla przebiegów w Simulinku.** Nasz schemat Simulink wciąż propaguje zredukowaną obwiednię pola, nie każdą składową widmową jako niezależny sygnał.

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

RIN jest uproszczonym dyskretnym modelem fluktuacji mocy. Nie symulujemy dokładnie elektroniki odbiorczej, szumu śrutowego, depolaryzatora, birefringencji, strat, rozpraszania Rayleigha ani pasożytniczych odbić. W konsekwencji z tego pierwszego schematu **nie wyznaczamy jeszcze rzeczywistej dokładności, ARW ani bias stability**.

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
