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

## 2. Pliki

| Plik | Zadanie |
|---|---|
| [E01_config.m](E01_config.m) | Parametry modelu i symulacji |
| [E01_source.m](E01_source.m) | Widmo LASER/ASE w W/nm i wagi całkowania |
| [E01_model.m](E01_model.m) | Fazy Sagnaca i modulatora, średnia moc, prąd, lock-in, spójność |
| [run_E01.m](run_E01.m) | Przełącznik źródła, sześć wykresów, eksport CSV/JSON |
| [test_E01.m](test_E01.m) | Testy numeryczne kontrolujące równania i znaki |

## 3. Uruchomienie

W MATLAB-ie przejdź do katalogu głównego sklonowanego repozytorium `FOG` i wklej:

```matlab
addpath(fullfile(pwd,"research","E01_basic_FOG","simulations","matlab"));
assert(test_E01());     % Weryfikacja implementacji modelu
out = run_E01("BOTH"); % Na wykresach jednocześnie laser i ASE
```

Możesz uruchomić tylko jeden wariant:

```matlab
out = run_E01("LASER");
out = run_E01("ASE");
```

Program domyślnie zapisuje obrazy i pliki CSV do folderu `research/E01_basic_FOG/results/EXP_E01_ideal_demo/` utworzonego **lokalnie podczas wykonania**. Nie zakładamy, że wyniki już zostały wykonane lub są zapisane w GitHubie.

W razie potrzeby wskaż własny katalog:

```matlab
out = run_E01("BOTH", "C:\FOG_E01_wyniki");
```

Aby zmienić geometrię, moc i częstotliwość modulacji, edytuj [E01_config.m](E01_config.m), zachowując wartości w odpowiednich jednostkach.

## 4. Co jest widoczne?

W wyniku uruchomienia otrzymasz sześć ilustracji:

1. `01_spectra.png` – dwa widma i rzeczywiste skale mocy widmowej (laser wąski, ASE szerokie).
2. `02_modulator.png` – faza w obu chwilach przejścia i różnica faz.
3. `03_photodiode.png` – sygnały fotodiody dla $\Omega=-1,0,+1$ deg/s.
4. `04_laser_vs_ase.png` – porównanie sygnałów fotodiody i charakterystyk lock-in.
5. `05_coherence_surrogate.png` – funkcja $|\gamma(\delta t_p)|$ dla **dodatkowej, hipotetycznej** drogi pasożytniczej.
6. `06_linear_estimate.png` – idealizowana estymacja liniowa i jej nieliniowość poza pobliżem zera.

CSV `spectrum_*.csv` przechowuje widmo i wagi, `waveform_*.csv` przebiegi czasowe, `sweep_*.csv` charakterystykę odczytu i `coherence_*.csv` moduł korelacji. Plik `config.json` zawiera parametry i wersję MATLAB-a.

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

Szerokości widmowe **nie są** danymi producentów. Zastosowano niezależne siatki dla wąskiego lasera i szerokiego ASE, z całkowaniem metodą trapezów. To chroni przed problemem pominięcia wąskiej linii lasera na grubej siatce ASE.

## 6. Co pokazuje, a czego NIE pokazuje, model?

**Prawidłowe obserwacje:** interferencja w zrównoważonej pętli; wpływ sinusoidalnej modulacji; znak obrotu po idealnym lock-in; spektralne uśrednianie sygnału; różnica spójności źródeł przy zewnętrznym opóźnieniu.

**Model NIE obejmuje:** polaryzacji, depolaryzatora, Rayleigha w pełnej cewce, strat sprzęgacza i włókna, responsywności widmowej, dyspersji, szumów ASE/lasera (w tym RIN), szumu śrutowego, TIA, ADC, dryftu, czasu integracji rzeczywistego pomiaru ani sprzętowej kalibracji.

**Szczególnie ważne:** wykres spójności jest *oddzielną analizą modelowej drogi pasożytniczej*, a nie zasymulowanym rozpraszaniem Rayleigha w całym FOG. Nie należy na jego podstawie podawać wartości ARW lub bias stability.

## 7. Etap weryfikacji

Testy [test_E01.m](test_E01.m) wymagają wykonania w MATLAB-ie. Równania zaimplementowane w E01 zweryfikowano dodatkowo niezależnym obliczeniem numerycznym, ale **nie uruchomiono w tym środowisku MATLAB-a**, więc syntaktyczna i wykonawcza zgodność MATLAB R2023b pozostaje do lokalnego potwierdzenia.

Osiągnięty cel implementacyjny: źródło można przełączyć jednym parametrem; oba warianty zachowują ten sam model cewki i toru detekcji.

W kolejnych podetapach rozpoczniemy walidację i analizę wrażliwości. Nie przenosimy tutaj wcześniejszych wyników v1–v8.1 bez osobnego uzasadnienia.
