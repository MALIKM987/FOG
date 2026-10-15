# E01 – Symulacje

**Status: KONCEPCJA – brak nowych uruchomień w ramach E01.**

- [Specyfikacja eksperymentu LASER/ASE](source_switching_plan.md) zawiera plan kontroli modelu.
- [Model matematyczny](../model.md) jest wspólnym punktem odniesienia.
- [Szablon raportu](../../templates/experiment_report.md) jest niezależny od użytego programu.

## Organizacja kodu

Nie zakładamy z góry narzędzia. Dopiero przy pierwszym uruchomieniu tworzymy podkatalog odpowiadający środowisku, np. `matlab/`, `optisystem/`, `python/`, `ltspice/`. Nie tworzymy pustych folderów.

Każdy zestaw plików ma mieć:
- instrukcję odtworzenia, nazwę i wersję narzędzia;
- komplet parametrów i jednostek;
- jednoznaczne oznaczenie hipotetycznych danych źródła;
- odniesienie do wyniku oraz SHA commitu;
- opis różnic między symulacją a rzeczywistym urządzeniem.

Starsze symulacje pozostają w repozytorium w katalogach [matlab/](../../../matlab/), [docs/](../../../docs/) i [results/](../../../results/). Nie stanowią automatycznie nowej walidacji E01.

**Nie istnieje jeszcze przełączalny model LASER/ASE należący do E01.**
