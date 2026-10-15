# S1. Specyfikacja osobnego symulatora: laser / ASE

**Status:** PLAN, NIE ZAIMPLEMENTOWANO W TYM ZADANIU  
**Cel:** nowy, samodzielny model obserwacyjny, bez zmian istniejących plików FOG v1–v8.1.

**Uzasadnienie, teoria i hipotezy H1–H4:** [Etap 1.3 – LASER kontra ASE](../01_03_laser_vs_ase.md) oraz [T3 – źródła optyczne](../../../theory/optical_sources.md).

## 1. Architektura

```text
       [SELECT SOURCE: LASER | ASE]
                    |
        [widmo S(lambda), P0]
                    |
               [sprzęgacz]
                 /      \
          CW -> /        \ <- CCW
              /   CEWKA  \
             [modulator] |
                  \      /
               [sprzęgacz]
                    |
                [fotodioda]
                    |
          [próbkowanie / lock-in]
                    |
             [wykresy i raport]
```

*To uproszczony schemat funkcjonalny. W implementacji należy dopracować topologię portów i położenie modulatora.*

Pętla, jej długość, geometria, czasy propagacji, funkcja sterowania oraz tor odbiorczy muszą pozostać wspólne obu trybom. Jedyne przełączenie: **model źródła**.

## 2. Wejścia interaktywne / parametry

| Nazwa | Start | Uwagi |
|---|---|---|
| `source_type` | LASER / ASE | podstawowy przełącznik |
| `lambda0_nm` | 1550 | długość środkowa; niekoniecznie identyczna z ważoną średnią |
| `laser_linewidth` | do zdefiniowania | węższe niż ASE; nie równe zeru przy modelu rzeczywistym |
| `ase_fwhm_nm` | 20 (TESTOWO) | liczba przykładowa, NIE dane urządzenia z laboratorium |
| `spectrum_file` | brak | później profil ASE z analizatora widma |
| `P0_mW` | do ustalenia | ta sama moc wejściowa w porównaniu |
| `L_m` | 1000 | długość włókna |
| `D_m` | 0.160 | średnica cewki |
| `ng` | 1.4682 | opóźnienie grupowe |
| `Omega_deg_s` | 0, ±1, ±10 | przykładowe punkty |
| `fm_Hz` | 1/(2τ) | sterowanie modulatora |
| `phi0_rad` | np. 1 | amplituda **samego modulatora**, różna od β |
| `V` | 1 (idealnie) | widzialność bez polaryzacji |
| `parasitic_delay_s` | wyłączony | osobny test spójności |
| `parasitic_field_fraction` | 0 | umowny poziom dodatkowego pola, nie prawo Rayleigha |

Parametry przykładowe to **propozycje**, nie wyniki pomiaru. W pierwszym teście laser idealnie monochromatyczny może być modelem delty Diraca; przy skończonej linewidth trzeba jawnie dobrać linię widmową (np. lorentzowską) i rozdzielczość numeryczną. W obu trybach zachować tę samą moc $P_{in}=\int S_{in}(\lambda)d\lambda$ i ten sam port B ze znakiem minus przed cosinusem.

## 3. Trzy poziomy fizyki

**Poziom A: idealny mono-/wielospektralny (E01-H1).** W obu trybach zsumować ważoną odpowiedź interferometru po widmie. Nie dodawać szumu; w idealnej równowadze obie odpowiedzi mogą prawie się pokrywać.

**Poziom B: kontrolowane niezrównoważenie optyczne (E01-H2).** Dodać *jawnie oznaczoną* niewielką drogę interferencyjną o różnym czasie propagacji, aby zbadać spadek widzialności zależny od szerokości widma. Wynik traktować jako demonstrację **spójności**, nie realistyczną predykcję dokładności FOG.

**Poziom C: model stochastyczny (E01-H4).** Dopiero po walidacji A i B: szum źródła, fotodiody, elektroniczny; wyraźne założenia dotyczące korelacji i PSD. Wiele źródeł ASE ma inne RIN niż laser, dlatego nie wystarczy dodać takiej samej białej próbki szumu do obu.

## 4. Obowiązkowe wykresy

1. Wspólne osie: znormalizowane widma LASER i ASE oraz rzeczywiste S(λ).
2. Fazy φ_m(t), φ_m(t−τ), Δφ_m(t).
3. Moc na fotodiodzie P(t), dla Ω=0, Ω>0 i Ω<0.
4. Wynik demodulacji synchronicznej i znak estymowanej Ω.
5. Charakterystyka sygnału demodulowanego względem Ω.
6. Kontrast zakłócenia vs dodatkowe opóźnienie drogi, osobno laser i ASE.
7. Poziom C (później): estymator vs czas, odchylenie, PSD/Allan z odpowiednią definicją.

## 5. Kryteria ukończenia pierwszego modelu

- [ ] Jeden przełącznik LASER/ASE, bez zmian pozostałego toru.
- [ ] Dane źródła oddzielone od algorytmu FOG.
- [ ] Walidacja Ω=0, +Ω i −Ω.
- [ ] Potwierdzenie \(K_S=2\pi LD/(\lambda c)\) w granicy wąskiego widma.
- [ ] Porównanie idealne bez sugerowania, że ASE „wygrywa” samo z siebie.
- [ ] Osobne wykresy wpływu spójności z oznaczeniem modelu zastępczego.
- [ ] Zachowane konfiguracje, kod, wynik i commit SHA.
- [ ] Sprawdzone jednostki, konwencje znaków i stałe widmo źródła.
- [ ] Wersja w MATLAB/Simulink R2023b możliwa do uruchomienia jedną instrukcją.

## 6. Weryfikacja analityczna

Przed zaufaniem symulacji sprawdzić:
- Δφ_S(Ω=0)=0.
- Δφ_S(−Ω)=−Δφ_S(+Ω).
- Dla φ_m=const: Δφ_m=0.
- Dla f_m=1/τ i sinusoidy: β=0.
- Dla f_m=1/(2τ): β=2φ_0.
- Dla zerowego niezrównoważenia optycznego widzialność spektralna ≈1.
- Dla rosnącej różnicy drogi porównać spójność źródła laserowego i ASE.

**Notatka implementacyjna:** użytkownik preferuje uruchamianie modeli i wykresów automatycznie w MATLAB R2023b; osobny folder symulacji jest lepszy niż edycja istniejących `FOG_v*.slx`.
