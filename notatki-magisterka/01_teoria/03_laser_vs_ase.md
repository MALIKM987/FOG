# T3. Źródło laserowe a źródło ASE

**Status:** TEORIA + HIPOTEZY DO SPRAWDZENIA  
**Cel:** porównanie przy identycznym torze optycznym i porównywalnej mocy dochodzącej do detektora.

## 1. Co podmieniamy?

- **LASER:** źródło o wąskim widmie wokół λ₀; nie zakładamy bez uzasadnienia idealnej monochromatyczności prawdziwego lasera.
- **ASE:** wzmocniona emisja spontaniczna o szerokim widmie; dokładny kształt należy ustalić dla generatora z laboratorium.

Zamiana źródła nie zmienia geometrii ani modulatora. Dla uczciwego porównania ustalamy warunki porównania: równą moc **na wejściu interferometru** oraz osobno wariant równych mocy przy detektorze.

## 2. Czy ASE może interferować?

Tak. W idealnym Sagnacu obie fale pochodzą z **tego samego źródła** i pokonują praktycznie równe drogi optyczne. Kluczowa jest *wzajemna spójność sygnałów po rozdzieleniu*, a nie „długotrwała stała faza całego ASE”.

Dla widma gęstości mocy S(ν) znormalizowana wzajemna funkcja spójności dla opóźnienia δt może być opisana (idealny przypadek stacjonarny) przez:

```math
\gamma(\delta t)=
\frac{\int S(\nu)e^{i2\pi\nu\delta t}\,d\nu}
{\int S(\nu)\,d\nu}.
```

Wartość |γ(δt)| ogranicza widzialność interferencji. Przy δt≈0 nawet szerokie widmo może dawać dużą widzialność. Gdy pojawia się dodatkowa droga pasożytnicza ze znacznym opóźnieniem δt_p, jej widzialność maleje szybciej dla szerokiego widma.

Nie należy utożsamiać szerokości widma w **nm** z szerokością częstotliwości w **Hz**; transformacja wymaga ν=c/λ i odpowiedniego Jacobianu dla gęstości widmowych.

## 3. Rozszerzenie modelu mocy

W przybliżeniu niezależnych składowych spektralnych z odpowiednią wagą:

```math
P(t)=\int W(\lambda)\left[1+V(\lambda)
\cos(\Delta\varphi_S(\lambda)+\Delta\varphi_m(\lambda,t))\right]d\lambda.
```

W(λ) oznacza rozkład mocy uwzględniający transmisję układu; sygnał prądowy wymaga jeszcze czułości widmowej fotodiody R(λ). Model wyznacza **średnią deterministyczną**; sama całka NIE odtwarza statystyki RIN, szumu śrutowego ani fazowych fluktuacji lasera.

### Uwaga o Δφ_S dla źródła szerokopasmowego

```math
\Delta\varphi_S(\lambda)=\frac{2\pi LD\Omega}{\lambda c}.
```

Zmiana długości fali zmienia współczynnik skali. Widmo ASE i jego stabilność mogą więc wpływać na kalibrację.

## 4. Dlaczego używa się ASE / źródeł szerokopasmowych?

Ograniczają spójną interferencję części niepożądanych odbić i wstecznego rozpraszania Rayleigha z falą użyteczną, gdy drogi znacznie się różnią. Nie usuwają **całego** rozpraszania Rayleigha ani wszystkich błędów FOG. Same też mają charakterystyczny szum intensywności i wymagają kontroli widma.

W idealnym modelu bez zakłóceń oba źródła mogą dawać **praktycznie identyczny odczyt**. Aby pokazać zaletę małej spójności, trzeba dodać kontrolowaną drogę pasożytniczą, np. opóźnienie δt_p oraz niewielką amplitudę pola. To **model dydaktyczny** zastępczego zakłócenia, nie pełna fizyka rozpraszania we włóknie.

## 5. Co pozostaje do ustalenia dla źródła z laboratorium?

- Producent, model, typ i zakres przestrajania generatora ASE.
- λ środkowa / średnia, szerokość FWHM widma, dostępność pliku widma z OSA.
- Moc i długoterminowa stabilność.
- Dane o względnym szumie intensywności (RIN), jeśli dostępne.
- Odpowiedź widmowa fotodiody oraz straty komponentów.

**Nie wolno** zastępować tych danych przykładowym widmem 20 nm i nazywać go widmem laboratoryjnym.

## 6. Hipotezy

H-A: w idealnym zrównoważonym interferometrze przełączenie LASER↔ASE przy podobnej mocy nie musi znacznie zmieniać podstawowego sygnału Sagnaca.

H-B: przy dołożonej drodze pasożytniczej o istotnej różnicy czasu propagacji, szerokie widmo ASE może zmniejszać kontrast zakłócenia.

H-C: przewaga pod względem odporności na zakłócenia spójne nie oznacza automatycznie lepszej czułości całego toru, bo znaczenie mają RIN, fotoprąd, widmo i elektronika.

## Literatura

- H. C. Lefèvre, *The fiber-optic gyroscope, a century after Sagnac’s experiment* (2014), https://doi.org/10.1016/j.crhy.2014.10.007
- *Miniaturization of Interferometric Optical Gyroscopes: A Review* (2023), IEEE Xplore: https://ieeexplore.ieee.org/document/10301584
- *Fiber-optic gyroscopes: from design to production* (2011), https://doi.org/10.1364/AO.50.00E152
