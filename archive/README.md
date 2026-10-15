# Archive – materiały nieaktywne

Ten katalog służy do przechowywania **materiałów zastąpionych nową organizacją**, które nie są już miejscem bieżących prac.

## Przeniesione

- [notatki-magisterka/](notatki-magisterka/README.md) – dawny indeks brudnopisu, zastąpiony przez `theory/`, `research/`, `bibliography/` i `thesis/`. Oryginalne wersje notatek są zachowane w historii Git; zaktualizowane treści znajdują się w docelowych katalogach.

## Co nie należy do archiwum?

- [theory/](../theory/README.md), [research/](../research/README.md), [bibliography/](../bibliography/README.md) i [thesis/](../thesis/README.md) to aktualna organizacja projektu.
- Starsze modele MATLAB/Simulink i ich dokumentacja (`matlab/`, `models/`, `results/`, `data/`, `docs/`) pozostają w obecnych ścieżkach. Nadal stanowią **odtwarzalny materiał badawczy**: ich kod, dane i wzajemne odwołania wymagają zachowania dotychczasowego układu. Nie należy nazywać tych katalogów „nieużywanymi” bez audytu zależności i potwierdzenia.

## Zasady porządkowania

1. Archiwizacja wymaga ustalenia, że plik/katalog nie jest wykorzystywany w aktualnym procesie ani jako zależność uruchamianych modeli.
2. Przenosimy źródła i materiały z zachowaniem integralności danych; najpierw tworzymy docelową kopię, potem usuwamy starą.
3. Aktualizujemy linki, ścieżki skryptów i indeksy, jeśli dojdzie do zmiany lokalizacji.
4. Nie usuwamy historii Git i nie używamy `force push`.
5. W przypadku niejasnej zależności wolimy zachować plik w pierwotnej lokalizacji.
