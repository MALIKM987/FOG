# FOG v6.2 - fizyczny model depolaryzatora Lyota pod BOM

## Cel

v6.2 zmienia kierunek pracy z samej walidacji matematycznej na projektowanie pod konkretne materiały.

Nie pytamy już tylko, czy fenomenologiczny residual = 0.025 działa. Pytamy:

- jakiej szerokości widma wymaga źródło,
- jakiego beat length wymaga PM fiber,
- jakie długości dwóch odcinków PM należy przygotować,
- jak dokładny musi być spaw 45 stopni,
- ile PM fiber trzeba realnie kupić,
- czy fizyczny projekt spełnia modelowy próg z v6.1.

## Podstawa fizyczna

Lyot depolarizer jest modelowany jako dwie sekcje liniowo dwójłomnego PM fiber.

Nominalnie:

- L2 = 2 L1,
- osie drugiej sekcji są obrócone o 45 stopni,
- źródło ma szerokie widmo,
- wyjściowy Stokes jest uśredniany po widmie.

Dla każdej długości fali model propaguje Jones vector przez obie sekcje, następnie integruje parametry Stokesa po widmie źródła i wyznacza DOP.

Badany jest worst-case DOP po banku 54 wejściowych stanów polaryzacji.

## Szybki estymator długości

Do wstępnego screeningu stosowany jest znany warunek:

`Ldp = lambda0 * Lbeat / Delta_lambda`

gdzie:

- lambda0 - długość centralna,
- Lbeat - beat length PM fiber,
- Delta_lambda - efektywna szerokość widma.

Pełna decyzja jest jednak oparta na numerycznej integracji Jones/Stokes.

## Referencyjny PM fiber

Do v6.2 przyjęto konserwatywnie klasę PM1550-HP / PM1550-XP:

- praca około 1550 nm,
- beat length <= 5 mm @1550 nm.

Do obliczeń używany jest worst-case 5 mm.

## Referencyjne klasy SLD

Skrypt zawiera benchmarki aktualnych klas źródeł 1550 nm:

- 30 nm minimum / 33 nm typical,
- 45 nm minimum / 50 nm typical,
- 85 nm minimum / 90 nm typical,
- 100 nm minimum / 110 nm typical.

Źródła te służą jako odniesienie do wymagań, a nie automatyczna rekomendacja zakupu.

Jeśli laboratorium ma już źródło, należy najpierw zmierzyć jego widmo i moc.

## Krytyczna uwaga o szerokości widma

Sama całkowita szerokość 3-dB może być myląca, jeśli widmo ma kilka wąskich pików.

Dlatego v6.2 dodaje konserwatywny guard:

`effective_guard_bw = 8 nm`.

Jest to celowo znacznie mniej niż typowe 30-110 nm dla szerokopasmowych SLD.

## Projekt badany jako bezpieczny punkt

Pierwszy konserwatywny wariant:

- L1 = 1.7 m,
- L2 = 3.4 m,
- łącznie 5.1 m aktywnego PM fiber,
- zakupowo 6 m PM fiber,
- beat length <= 5 mm @1550 nm,
- spaw osi 45 stopni,
- projektowa tolerancja osi +/-0.5 stopnia.

Ten wariant jest celowo dłuższy niż minimum dla gładkiego widma 30-50 nm.

## Dlaczego nie od razu 0.5 m + 1 m

Dla gładkiego szerokiego widma krótsza para może wystarczyć.

Jeśli jednak realne widmo zawiera wąski komponent koherentny, minimalna długość gwałtownie rośnie.

Skrypt dlatego porównuje:

- 0.5 + 1.0 m,
- 1.0 + 2.0 m,
- 1.2 + 2.4 m,
- 1.5 + 3.0 m,
- 1.7 + 3.4 m.

## Tolerancja spawu 45 stopni

v6.2 wykonuje osobny sweep błędu osi od 0 do 2 stopni.

Po pełnej dekoherencji błąd kąta staje się jednym z dominujących ograniczeń. To oznacza, że BOM musi obejmować nie tylko PM fiber, ale także proces spawania z kontrolą osi.

Roboczy cel procesu:

`45 deg +/-0.5 deg`.

Dokładna granica zostanie wyznaczona przez lokalną walidację v6.2.

## Most do v6.1

v6.1 dało dwa cele:

- punktowo: residual <= 0.05,
- bezpieczniej: residual <= 0.025.

W v6.2 przyjęto konserwatywny proxy:

`depol_residual_proxy = worst-case DOP_out`.

Nie jest to ścisła tożsamość fizyczna.

To most projektowy potrzebny do przełożenia fizycznego depolaryzatora na istniejący model FOG.

Po zbudowaniu elementu proxy trzeba skalibrować pomiarem.

## Testy

### v6.2A

Depolarizing length estimate dla różnych efektywnych szerokości widma.

### v6.2B

Minimalna długość krótkiej sekcji L1 dla progów 5% i 2.5%, z tolerancją:

- +/-0.5 stopnia kąta,
- ratio 1.95 / 2.00 / 2.05.

### v6.2C

Benchmark aktualnych klas SLD.

### v6.2D

Guard dla efektywnego komponentu 8 nm.

### v6.2E

Sweep błędu spawu 45 stopni.

### v6.2F

Minimalna efektywna szerokość widma dla wybranego projektu.

### v6.2G

Wybrany fizyczny projekt jest mapowany na residual proxy i opcjonalnie ponownie sprawdzany w FOG_v6.

### v6.2H

Automatyczne wymagania BOM.

## Pliki wynikowe

- FOG_v6_2_depolarizing_length_estimate.csv
- FOG_v6_2_length_vs_bandwidth.csv
- FOG_v6_2_source_benchmark.csv
- FOG_v6_2_effective8nm_guard.csv
- FOG_v6_2_splice_angle_sweep.csv
- FOG_v6_2_bandwidth_requirement.csv
- FOG_v6_2_bom_requirements.csv
- FOG_v6_2_selected_design.csv
- opcjonalnie FOG_v6_2.slx
- opcjonalnie FOG_v6_2_fog_verification.csv

## Zasada materiałowa od v6.2

Każdy kolejny etap symulacji powinien generować nie tylko wynik fizyczny, ale także:

1. parametr, który ma być zmierzony przed zakupem,
2. minimalne wymaganie katalogowe,
3. wariant preferowany,
4. margines tolerancji montażowej,
5. informację czy element jest już w laboratorium czy trzeba go zorganizować.

Ta zasada zostaje przyjęta dla v7 i dalszych wersji.

## Status

**Zweryfikowany w MATLAB/Simulink R2023b Update 7.**

Najważniejsze wyniki:
- 8 nm guard: minimum około L1=1.05 m, L2=2.10 m dla proxy 2.5%,
- wariant 1.2 m + 2.4 m już przechodzi bezpieczny próg przy 8 nm,
- wybrany wariant 1.7 m + 3.4 m daje residual proxy około 0.01745,
- minimalna efektywna szerokość widma dla wybranego wariantu wynosi około 5 nm,
- modelowy limit błędu spawu dla progu 2.5% wynosi około +/-0.7 deg,
- pełny FOG z fizycznym proxy daje około 3.48 sigma dla 0.0001 deg/s.

Wymagania BOM i interpretacja:
`docs/VALIDATION_V6_2.md`.