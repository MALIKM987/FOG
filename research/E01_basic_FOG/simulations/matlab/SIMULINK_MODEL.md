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

## 4. Wyprowadzenie matematyczne

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

## 5. Ważne ograniczenia modelu

To **model optycznych zespolonych obwiedni**, a nie symulacja nośnej światła o częstotliwości około 193 THz. LASER i ASE różnią się źródłowym RIN i przybliżonym efektywnym współczynnikiem skali; pełne optyczne widmo ASE nie jest propagowane jako tysiące losowych fal.

RIN jest uproszczonym dyskretnym modelem fluktuacji mocy. Nie symulujemy dokładnie elektroniki odbiorczej, szumu śrutowego, depolaryzatora, birefringencji, strat, rozpraszania Rayleigha ani pasożytniczych odbić. W konsekwencji z tego pierwszego schematu **nie wyznaczamy jeszcze rzeczywistej dokładności, ARW ani bias stability**.

Jedna cewka jest reprezentowana przez dwie ścieżki matematyczne, ale jej parametry są wspólne. W ten sposób modelujemy wzajemność dróg i efekt Sagnaca bez tworzenia dwóch fizycznych cewek.

## 6. Test po wygenerowaniu

Uruchom w MATLAB:

~~~matlab
assert(test_E01_simulink());
~~~

Test powinien skompilować schemat i wykonać symulacje dla obu źródeł, sprawdzając skończoność i zmianę przebiegu fotodiody. To **lokalny test implementacyjny**, nie pomiar.

## 7. Porównanie ze skryptowym E01

Poprzedni [run_E01.m](run_E01.m) wytwarza osiem wykresów PNG z matematycznego modelu uśredniającego widmo i z modelem szumów. Nowy **FOG_E01_SIMULINK.slx** jest natomiast **interaktywnym schematem blokowym** z dostępem do wnętrza elementów optycznych. Modele mają spójne założenia podstawowe, lecz inne szczegóły uproszczeń źródła i przetwarzania.

Oba są niezależne od historycznych modeli FOG_v1–v8.1 i nie modyfikują ich.
