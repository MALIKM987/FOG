# Podsumowanie kierunku pracy po spotkaniu z promotorem

**Data zapisu:** 2026-10-15  
**Data samego spotkania:** niepotwierdzona w notatkach  
**Źródło zapisu:** relacja studenta po spotkaniu (nie protokół ani cytat promotora)  
**Status:** USTALENIA DO DALSZEGO OPRACOWANIA

## Kierunek

Zamiast zaczynać od kompletnego BOM i budowy, rozłożyć problem interferometrycznego żyroskopu światłowodowego na małe, możliwe do zrozumienia i przetestowania zagadnienia.

### Temat A: najprostszy układ optyczny

- Źródło światła → sprzęgacz → dwie przeciwbieżne fale → pętla światłowodowa z modulatorem fazy → interferencja → detekcja.
- Najpierw rozpatrywać układ **idealny, skalarny**, bez polaryzacji.
- Osobno przeanalizować: fazę Sagnaca, fazę modulatora, sygnał na detektorze, odczyt znaku obrotu.
- Dopiero później potwierdzić w symulacji zależności wyprowadzone teoretycznie.

### Temat B: laser vs źródło szerokopasmowe

- W laboratorium dostępne jest **źródło/generator ASE**; jego parametry nie są jeszcze zebrane.
- Wyjaśnić: czym jest spójność czasowa, dlaczego krótkospójne ASE może interferować w interferometrze Sagnaca, co daje szerokie widmo.
- Docelowo porównać oba źródła w **jednym osobnym modelu**, zmieniając źródło bez przebudowy interferometru.

## Ważna obserwacja dydaktyczna z rozmowy

Pytanie: „Skoro ten sam modulator działa na CW i CCW, to dlaczego fazy mają się różnić?”.

Wyjaśnienie: modulator zadaje tę samą funkcję fazy w chwili przejścia dowolnej fali, ale CW i CCW docierają do niego w różnych chwilach (dla modulatora przy jednym końcu cewki). Zatem odczytują różne wartości tej funkcji. Nie jest to przyspieszanie jednej fali i spowalnianie drugiej.

Punkt do wyjaśnienia w opracowaniu: wpływ lokalizacji modulatora w pętli i przesunięcia czasowego między przejściami.

## Otwarty zestaw pytań

1. Jakie dokładnie parametry ma dostępny generator ASE: długość centralna, szerokość widma, moc, charakterystyka spektralna, stabilność?
2. Jaki modulator fazy będzie docelowo dostępny i jakie ma pasmo?
3. Czy promotor oczekuje początkowo tylko charakterystyk deterministycznych, czy także modelu dodatkowej drogi pasożytniczej?
4. Jakie mierzalne metryki wybieramy do porównania źródeł?

**Następny krok:** uporządkować teorię i dopiero potem implementować nowy model symulacyjny. 
