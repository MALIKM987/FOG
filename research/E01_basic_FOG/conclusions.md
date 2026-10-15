# E01 – Wnioski i otwarte zagadnienia

**Status:** KONCEPCJA / WNIOSKI TEORETYCZNE; **Etap 1.1 opracowany teoretycznie**.  
**Wyniki symulacji przypisane do E01:** BRAK.  
**Wyniki pomiarów przypisane do E01:** BRAK.

[Etap 1.1 – analiza toru optycznego](01_01_optical_path.md) opisuje porty, drogę CW/CCW oraz sygnał detektora. Wnioski nie oznaczają potwierdzenia eksperymentalnego.

## Wnioski teoretyczne

1. Efekt Sagnaca powstaje dzięki przeciwnym kierunkom propagacji w obracającej się pętli; nie jest wytwarzany przez modulator fazy.
2. Idealna, niemodulowana odpowiedź portu interferometrycznego typu cosinus jest parzysta względem Ω i ma zerowe nachylenie przy zerowej fazie.
3. Jeden modulator fazy może dawać różnicową fazę, bo fale CW i CCW przechodzą przez niego **w różnych chwilach**. Nie oznacza to przyspieszania jednej fali względem drugiej.
4. Źródło ASE może interferować w zrównoważonym interferometrze Sagnaca mimo szerokiego widma, gdy wzajemna różnica opóźnień obu dróg jest mała.
5. Aby porównać odporność LASER i ASE na zakłócenia spójne, potrzebny jest model kontrolowanej drogi pasożytniczej lub bardziej realistycznego rozpraszania; nie wolno wyciągać takich wniosków z samej charakterystyki idealnej.

## Do sprawdzenia

- [x] Przyjęto **idealny** schemat portów sprzęgacza: A=źródło, B=fotodioda (port ciemny dla Δφ=0), C/D=pętla. Fizyczne połączenia należy sprawdzić po wyborze sprzęgacza.
- [ ] Długość cewki, geometria i rzeczywiste opóźnienie.
- [ ] Parametry źródła ASE dostępnego w laboratorium.
- [ ] Dostępny modulator i jego pasmo oraz charakterystyka sterowania.
- [ ] Zakres fizyki i metryki porównania dla pierwszej symulacji.
- [ ] Testy i wykresy opisane w [planie symulacji](simulations/source_switching_plan.md).

Nie przedstawiamy tych punktów jako uzyskanych wyników do pracy magisterskiej, dopóki nie zostaną zweryfikowane.
