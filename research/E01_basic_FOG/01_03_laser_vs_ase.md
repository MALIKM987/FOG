# E01 / 1.3 – Porównanie źródła laserowego i ASE w minimalnym FOG

**Model:** FOG-E01-MIS — Minimalny Interferometr Sagnaca.  
**Status:** teoria i plan weryfikacji; **nie uruchomiono jeszcze symulacji E01**.  
**Data:** 2026-10-15.  
**Źródło danych laboratoryjnych:** wiadomość studenta o dostępności generatora ASE w laboratorium; brak potwierdzonego modelu urządzenia, widma lub pomiaru.

## 1. Główne pytanie badawcze

Czy przy stałym sprzęgaczu, modulatorze, cewce i fotodiodzie można **podmienić wyłącznie źródło optyczne** pomiędzy LASER i ASE, zachowując sygnał użyteczny Sagnaca, a jednocześnie ograniczając część zakłóceń spójnych?

To pytanie ma trzy oddzielne części:
1. **Działanie podstawowe:** czy światło obu źródeł interferuje w zrównoważonym Sagnacu?
2. **Spójność:** jaki wpływ ma szerokość widma na dodatkowe, opóźnione pole pasożytnicze?
3. **Dokładność:** czy potencjalna redukcja zakłóceń spójnych równoważy dodatkowe RIN oraz wahania widma?

**Wniosek na dziś:** matematyka uzasadnia odpowiedź „tak” w punkcie 1, prawdopodobne zmniejszenie widzialności opóźnionego zaburzenia w punkcie 2; punkt 3 **pozostaje otwarty**.

## 2. Niezmienny układ optyczny

```text
                  +---- [źródło LASER / ASE]  <-- podmieniamy TYLKO źródło
                  |
                  v
       [idealny sprzęgacz 2×2] ------> [modulator fazy] ----+
                  ^                                        |
                  |                                        v
                  +------------- [cewka FOG] <-------------+
                  |
        [port B -> fotodioda]
```

Konwencja portów i fizyka CW/CCW: [E01 / 1.1](01_01_optical_path.md) oraz [E01 / 1.2](01_02_mathematical_derivation.md). Ten rysunek jest funkcjonalnym skrótem połączeń, nie instrukcją montażową.

**Nie zmienia się:** długość i średnica cewki, położenie modulatora, częstotliwość sterowania, sprawność sprzęgacza, fotodioda, algorytm odczytu i wybrany port B. Zmienna jest tylko charakterystyka źródła: widmo, moc, a przy modelu szumów także odpowiednie statystyki.

## 3. Intuicja: dlaczego „losowe światło” ASE może interferować?

Fale CW i CCW są dwiema kopiami tego samego światła, rozdzielonymi na sprzęgaczu. Ich wspólny czas propagacji przez 1 km włókna może wynosić około 4,9 mikrosekundy, ale decydująca jest **różnica** pomiędzy czasami CW a CCW. W idealnym nieruchomym FOG wynosi ona zero.

Nawet gdy pierwotne pole ASE bardzo szybko zmienia fazę, obie kopie tego samego fragmentu pola nadal mogą zostać porównane na końcu pętli. Widzialność zależy od korelacji dla wzajemnego opóźnienia $\delta t$, a nie od samej długości cewki.

W teorii [T3: źródła optyczne](../../theory/optical_sources.md) zapisano:

$$
\gamma(\delta t)=
\frac{\int S_\nu(\nu)e^{j2\pi\nu\delta t}\,d\nu}
{\int S_\nu(\nu)\,d\nu}.
$$

Ponieważ $\gamma(0)=1$, idealnie zrównoważony Sagnac zachowuje interferencję zarówno dla lasera, jak i ASE.

## 4. Co daje zmiana szerokości widma?

Zwiększenie szerokości widma zwykle **skraca czas spójności**. Dla pojedynczej dodatkowej drogi o niezerowym opóźnieniu $\delta t_p$ interferencja pasożytnicza jest w idealizacji proporcjonalna do $|\gamma(\delta t_p)|$.

Do ilustracji wykorzystamy przykład ASE o $\lambda_0=1550$ nm i $\Delta\lambda_{\rm FWHM}=20$ nm. Parametry są **hipotetyczne**; nie są oznaczeniem urządzenia laboratoryjnego.

Dla takiego widma gaussowskiego w częstotliwości:

$$
|\gamma(\delta t)|=\exp\left[-\frac{(\pi\Delta\nu\,\delta t)^2}{4\ln2}\right],
\qquad \Delta\nu\approx\frac{c\Delta\lambda}{\lambda_0^2}.
$$

Daje to orientacyjnie:
- $\Delta\nu \simeq 2,5$ THz;
- szerokość do poziomu $|\gamma|=1/2$ dla $|\delta t|\simeq0,177$ ps;
- różnica fazowa Sagnaca przy $\Omega=1^\circ$/s dla cewki 1000 m / 160 mm odpowiada wzajemnemu opóźnieniu około $3,1\cdot10^{-17}$ s, czyli dużo mniejszemu.

**Ważne:** powyższe „0,177 ps” dotyczy konkretnej definicji połowy modułu spójności i wyidealizowanego Gaussa, a nie uniwersalnej „długości spójności ASE”.

## 5. Model detekcji źródła szerokopasmowego

Przy zdefiniowanym w E01 **ciemnym porcie B** średni fotoprąd:

$$
\boxed{
\overline i_B(t)=\frac12\int R(\lambda)S_{\rm in}(\lambda)
\left[1-V(\lambda)\cos\left(
\frac{2\pi LD\,\Omega}{\lambda c}
+\Delta\varphi_m(\lambda,t)\right)\right]\,d\lambda.
}
$$

$S_{\rm in}(\lambda)$ [W/m] to gęstość widmowa mocy, $P_{\rm in}=\int S_{\rm in}(\lambda)d\lambda$, $R(\lambda)$ [A/W] to responsywność detektora. W początkowym modelu przyjmiemy $V=1$, stałe $n_g$ i zaniedbamy straty.

W granicy monochromatycznej wracamy do równania portu B wyprowadzonego w [Etapie 1.2](01_02_mathematical_derivation.md).

**Całkowanie po widmie to model średniej odpowiedzi.** Nie generuje ono automatycznie realizacji pola losowego ASE, RIN ani realistycznego szumu fotodiody.

## 6. Hipotezy do symulacji

| ID | Hipoteza | Co musi pokazać model? | Warunek |
|---|---|---|---|
| E01-H1 | LASER i ASE dają użyteczną interferencję w idealnym FOG | podobny średni przebieg portu B i zgodny znak po demodulacji | identyczna moc, geometria i sterowanie |
| E01-H2 | ASE zmniejsza widzialność odpowiednio opóźnionego zakłócenia | wykres $|\gamma(\delta t_p)|$ i odpowiedzi dodatkowej ścieżki | jawny model opóźnienia; nie twierdzimy, że to pełny Rayleigh |
| E01-H3 | Błąd współczynnika skali może zależeć od średniej efektywnej długości fali | wrażliwość sygnału na przesunięcie widma ASE | model widmowy z prawidłowymi wagami |
| E01-H4 | Niski poziom zakłóceń spójnych nie dowodzi mniejszego szumu całkowitego | dopiero osobny model statystyczny RIN i detektora | późniejszy etap, bez przedwczesnych ocen dokładności |

## 7. Porządek dalszej pracy

**Symulacja E01/1.4, poziom A:** dwie charakterystyki źródła, idealna cewka i modulator, fotodioda, demodulacja. Widma poprawnie normalizowane do jednakowej mocy źródła. Wzorcowo porównamy wyniki $0$, $+\Omega$ i $-\Omega$.

**Poziom B:** odrębny wariant dydaktyczny z kontrolowanym opóźnieniem pasożytniczym. Zbadamy, jak szerokość widma zmienia jego kontrast. To **nie** jest jeszcze model rzeczywistego rozpraszania Rayleigha.

**Poziom C (dopiero później):** szumy, w tym RIN i fotoprąd, możliwe wahania średniej długości fali, realne widmo laboratoryjne. Do tego czasu nie oceniamy ARW, stabilności biasu ani dokładności urządzenia.

Prowadzimy jeden model fizyczny, a wybór LASER/ASE jest parametrem źródła. Nie tworzymy dwóch niezależnych interferometrów.

## 8. Informacje potrzebne o generatorze ASE w laboratorium

- Producent i model (lub zdjęcie tabliczki/karty urządzenia).
- Zakres długości fali, szerokość pasma FWHM, centralna/średnia długość fali.
- Moc wyjściowa, rodzaj złącza i opcje regulacji.
- Eksport widma z analizatora OSA, jeśli możliwy.
- Stabilność mocy i widma, ewentualnie parametry RIN z dokumentacji.
- Dostępna fotodioda i jej zakres spektralny.

Dopóki nie mamy danych, parametry hipotetyczne muszą być opatrzone adnotacją **DEMO**.

## 9. Kryterium zakończenia E01/1.3

- [x] Wyjaśniono, dlaczego ASE może interferować w FOG.
- [x] Ustalono związek funkcji spójności z widmem.
- [x] Odróżniono opóźnienie wspólnej cewki od różnicy czasów CW/CCW.
- [x] Ustalono model średniego fotoprądu dla źródła szerokopasmowego.
- [x] Sformułowano hipotezy i trzy poziomy przyszłej symulacji.
- [ ] Weryfikacja parametrów rzeczywistego generatora ASE (wymagana później).
- [ ] Numeryczna walidacja hipotez H1–H4 (jeszcze nie wykonano).

## 10. Literatura

- **[L1]** H. C. Lefèvre, 2014, https://doi.org/10.1016/j.crhy.2014.10.007
- **[L8]** F. Hakimi i J. D. Moores, 2013, https://doi.org/10.1049/el.2012.3371
- **[L9]** Y. Liu i in., 2024, https://doi.org/10.1364/AO.522560
- **[L10]** Y. Li i in., 2019, https://doi.org/10.1016/j.optcom.2019.01.075
- Podstawy korelacji spektralnej: https://opg.optica.org/abstract.cfm?uri=ETOP-2001-IATLI222

**Uwaga:** teoria i przykładowe obliczenia nie stanowią wyniku laboratoryjnego; metryki źródeł i ich interpretację należy zweryfikować w pełnych publikacjach przed ostatecznym cytowaniem.
