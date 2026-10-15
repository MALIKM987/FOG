# Brudnopis pracy magisterskiej: interferometryczny żyroskop światłowodowy

> **Status: dokumentacja robocza (nie tekst gotowej pracy).** Aktualizacja: 2026-10-15. Materiał wymaga kontroli merytorycznej, potwierdzenia z promotorem i prawidłowego cytowania źródeł.

## Po co to robimy?

To laboratorium wiedzy dla FOG: zapisujemy tu **każdą istotną decyzję, wyprowadzenie, hipotezę, konfigurację eksperymentu i interpretację wyników**, aby docelowe pisanie pracy magisterskiej polegało przede wszystkim na weryfikacji, uporządkowaniu i redakcji, a nie rekonstruowaniu wcześniejszych ustaleń.

Dokumentacja jest **oddzielona od kodu symulatorów**. Nie zmienia dotychczasowych modeli FOG v1/v2/v3.

## Nawigacja

| Sekcja | Plik | Zawartość |
|---|---|---|
| Kontekst | [Ustalenia po spotkaniu](00_dziennik/2026-10-15_podsumowanie.md) | Zakres i założenia wynikające z rozmowy użytkownika |
| Teoria 1 | [Minimalny interferometr Sagnaca](01_teoria/01_interferometr_sagnaca.md) | Dwie fale, czas przejścia, przesunięcie fazowe i fotodioda |
| Teoria 2 | [Modulator fazy i demodulacja](01_teoria/02_modulacja_fazy.md) | Dlaczego CW i CCW otrzymują różne fazy |
| Teoria 3 | [Laser i źródło ASE](01_teoria/03_laser_vs_ase.md) | Szerokość widma, spójność, zakłócenia |
| Symulacje | [Specyfikacja osobnego modelu](02_symulacje/model-przelaczane-zrodlo.md) | Jeden interferometr, wybór LASER/ASE |
| Symulacje | [Szablon eksperymentu](02_symulacje/szablon-eksperymentu.md) | Warunki, wyniki i odtwarzalność |
| Decyzje | [Rejestr decyzji i pytań](03_decyzje/rejestr.md) | Co uzgodniono i co wymaga potwierdzenia |
| Literatura | [Bibliografia](04_literatura/zrodla.md) | Zweryfikowane adresy publikacji i zadania czytelnicze |
| Redakcja | [Mapa przyszłej pracy](05_redakcja/mapa-rozdzialow.md) | Powiązanie treści z przyszłymi rozdziałami |

## Obowiązkowy format każdej nowej informacji

1. **Teza / obserwacja:** co stwierdzamy?
2. **Podstawa:** dowód matematyczny, publikacja, pomiar, symulacja lub ustalenie z promotorem.
3. **Założenia i ograniczenia:** kiedy stwierdzenie jest prawdziwe?
4. **Status:** `USTALONE`, `TEORIA`, `DO_WERYFIKACJI`, `WYNIK_SYMULACJI`, `WYNIK_POMIARU`.
5. **Ślad:** odnośnik do DOI/URL, nazwy skryptu, wersji modelu lub SHA commitu i danych wejściowych.
6. **Wniosek i dalszy krok:** co ten materiał oznacza dla FOG?

**Zasada:** nie przedstawiamy symulacji jako pomiaru, hipotezy jako faktu, ani notatki z rozmowy jako dosłownej wypowiedzi promotora.

## Praktyczny przebieg pracy

- Nowy temat: osobna notatka Markdown ze statusem i źródłami.
- Nowa symulacja: kod/model + karta eksperymentu + konfiguracja + wykresy + wyniki liczbowe + commit SHA.
- Nowy pomiar: stanowisko, przyrządy, kalibracja, jednostki, warunki, surowe dane, obróbka.
- Nowa decyzja: identyfikator D-xxx w [rejestrze](03_decyzje/rejestr.md).
- Przeniesienie do pracy: skorzystać z [mapy rozdziałów](05_redakcja/mapa-rozdzialow.md) i sprawdzić cytowania.

## Czego na razie świadomie NIE modelujemy?

Polaryzacji, depolaryzatorów, dwójłomności, rzeczywistego profilu modulatora, pełnego rozpraszania Rayleigha, termiki, elektroniki wejściowej i szumów fizycznych. Rozszerzenia te wymagają oddzielnych eksperymentów.

## Uwaga o poufności

Repozytorium `MALIKM987/FOG` jest **publiczne**. Nie umieszczać tu prywatnej korespondencji, nieopublikowanych danych pomiarowych bez zgody laboratorium ani haseł lub tokenów.
