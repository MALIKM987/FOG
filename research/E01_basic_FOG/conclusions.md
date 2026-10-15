# E01 – Wnioski i otwarte zagadnienia

**Status:** KONCEPCJA / WNIOSKI TEORETYCZNE; **Etapy 1.1 i 1.2 opracowane teoretycznie**.  
**Wyniki symulacji przypisane do E01:** BRAK.  
**Wyniki pomiarów przypisane do E01:** BRAK.

[Etap 1.1 – analiza toru optycznego](01_01_optical_path.md) opisuje porty, drogę CW/CCW oraz sygnał detektora. [Etap 1.2 – wyprowadzenie analityczne](01_02_mathematical_derivation.md) daje ścisły model amplitud sprzęgacza i prądu fotodiody. Wnioski nie oznaczają potwierdzenia eksperymentalnego.

## Wnioski teoretyczne

1. Efekt Sagnaca powstaje dzięki przeciwnym kierunkom propagacji w obracającej się pętli; nie jest wytwarzany przez modulator fazy.
2. Idealna, niemodulowana odpowiedź portu interferometrycznego typu cosinus jest parzysta względem Ω i ma zerowe nachylenie przy zerowej fazie.
3. Jeden modulator fazy może dawać różnicową fazę, bo fale CW i CCW przechodzą przez niego **w różnych chwilach**. Nie oznacza to przyspieszania jednej fali względem drugiej.
4. Źródło ASE może interferować w zrównoważonym interferometrze Sagnaca mimo szerokiego widma, gdy wzajemna różnica opóźnień obu dróg jest mała.
5. Aby porównać odporność LASER i ASE na zakłócenia spójne, potrzebny jest model kontrolowanej drogi pasożytniczej lub bardziej realistycznego rozpraszania; nie wolno wyciągać takich wniosków z samej charakterystyki idealnej.

6. Dla idealnego sprzęgacza 50:50 dowiedziono w modelu $P_A+P_B=P_{\rm in}$, a wybrany port B ma $P_B=P_{\rm in}[1-\cos\Delta\varphi]/2$.
7. Pierwsza harmoniczna po idealnej demodulacji jest proporcjonalna do $J_1(\beta)\sin(K_S\Omega)$. Dzięki temu jej znak umożliwia wykrycie kierunku obrotu w zakresie małych kątów fazy.

## Do sprawdzenia

- [x] Przyjęto **idealny** schemat portów sprzęgacza: A=źródło, B=fotodioda (port ciemny dla Δφ=0), C/D=pętla. Fizyczne połączenia należy sprawdzić po wyborze sprzęgacza.
- [ ] Długość cewki, geometria i rzeczywiste opóźnienie.
- [ ] Parametry źródła ASE dostępnego w laboratorium.
- [ ] Dostępny modulator i jego pasmo oraz charakterystyka sterowania.
- [ ] Zakres fizyki i metryki porównania dla pierwszej symulacji.
- [ ] Testy i wykresy opisane w [planie symulacji](simulations/source_switching_plan.md).

Nie przedstawiamy tych punktów jako uzyskanych wyników do pracy magisterskiej, dopóki nie zostaną zweryfikowane.
