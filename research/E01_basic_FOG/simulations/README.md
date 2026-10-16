# E01 – Symulacje

**Status: model MATLAB E01/1.4 zaimplementowany; test w MATLAB R2023b i zapis jego wyników jeszcze nie wykonane.**

- **[Interaktywny schemat Simulink](matlab/SIMULINK_MODEL.md)** – generator edytowalnego `.slx`, przełączanie źródła w modelu, jeden podsystem cewki CW/CCW, osobny lokalny test kompilacji.
- **[Model MATLAB E01/1.4](matlab/README.md)** – źródło przełączane **bezpośrednio w `E01_start.m`**, przebieg fotodiody wraz z modelowymi fluktuacjami ASE/lasera i fotodiody, osiem wykresów, CSV/JSON i testy. Dodatkowa droga pasożytnicza jest opcjonalna i domyślnie wyłączona.
- [Specyfikacja eksperymentu LASER/ASE](source_switching_plan.md) zawiera plan kontroli modelu.
- [Model matematyczny](../model.md) jest wspólnym punktem odniesienia.
- [Szablon raportu](../../templates/experiment_report.md) jest niezależny od użytego programu.

## Organizacja kodu

Nie zakładamy z góry narzędzia. Dla zaimplementowanego wariantu utworzono `matlab/`. Dla następnych badań dopiero przy pierwszym uruchomieniu tworzymy podkatalog odpowiadający środowisku, np. `matlab/`, `optisystem/`, `python/`, `ltspice/`. Nie tworzymy pustych folderów.

Każdy zestaw plików ma mieć:
- instrukcję odtworzenia, nazwę i wersję narzędzia;
- komplet parametrów i jednostek;
- jednoznaczne oznaczenie hipotetycznych danych źródła;
- odniesienie do wyniku oraz SHA commitu;
- opis różnic między symulacją a rzeczywistym urządzeniem.

Starsze symulacje pozostają w repozytorium w katalogach [matlab/](../../../matlab/), [docs/](../../../docs/) i [results/](../../../results/). Nie stanowią automatycznie nowej walidacji E01.

**Istnieje zaimplementowany kod przełączalnego modelu LASER/ASE. Nie przedstawiamy go jako zwalidowanego w MATLAB, dopóki nie przejdzie lokalnych testów.**
