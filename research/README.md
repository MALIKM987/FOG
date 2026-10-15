# Badania i eksperymenty

Tutaj znajduje się zapis kolejnych **pytań badawczych**, nie lista narzędzi. Badanie może wykorzystywać dowolny symulator, analizę analityczną i/lub pomiary fizyczne.

| ID | Nazwa | Status | Cel |
|---|---|---|---|
| [E01](E01_basic_FOG/README.md) | Basic FOG | **KONCEPCJA** | Minimalna pętla Sagnaca: źródło LASER/ASE, sprzęgacz, modulator, cewka, fotodioda |

Następne eksperymenty dodajemy dopiero po ich zdefiniowaniu. Nie tworzymy katalogów E02, E03 na zapas.

## Wspólne pliki

- [Rejestr decyzji](decisions.md) – co zaakceptowano, a co pozostaje do sprawdzenia.
- [Szablon eksperymentu](templates/experiment_report.md) – jednolity raport niezależny od środowiska.
- [Podstawy teoretyczne](../theory/README.md) – wspólne równania i ich pochodzenie.

## Zasady eksperymentów

1. Pytanie badawcze i hipoteza są określone przed uruchomieniem.
2. Każde uruchomienie wskazuje wersję kodu/modelu, program oraz wersję programu, konfigurację i jednostki.
3. Dane wejściowe oddzielamy od skryptu i od wyników, gdzie to możliwe.
4. Wynik numeryczny ≠ wynik pomiaru stanowiskowego. Podajemy ograniczenia.
5. Stosujemy formaty wymiany CSV/JSON i zachowujemy pliki natywne narzędzi.
6. Nie wymuszamy MATLAB-a, OptiSystem, Pythona, LTspice ani innych programów; podkatalogi tworzymy w miarę potrzeb.

**Stan starszych modeli:** historyczne modele v1–v8.1 pozostają w [matlab/](../matlab/), [docs/](../docs/) i [results/](../results/) i nie są przenoszone do `legacy/` automatycznie.
