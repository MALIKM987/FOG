# Analiza sześciu publikacji FOG na potrzeby eksperymentu laboratoryjnego

Data opracowania: 10.11.2026. Na podstawie sześciu przesłanych PDF-ów (pełne teksty) i wcześniejszego modelu projektowego. Notatki są autorskim streszczeniem technicznym, a **nie tłumaczeniem 1:1**. Każde równanie przeznaczone do pracy dyplomowej trzeba zweryfikować w oryginale.

## 1. Fizyka: Lefèvre (1997), Lefèvre (2014)

W interferometrze dwie fale propagują się po tej samej zamkniętej drodze w przeciwnych kierunkach. Podczas obrotu pojawia się różnica czasu propagacji, a zatem różnica faz. Dla cewki o całkowitej długości światłowodu L i średniej średnicy D:

`Delta_phi_S = (2*pi*L*D/(lambda*c))*Omega`.

Przy doborze geometrii trzeba rozróżnić średnicę cewki od długości rozwiniętego włókna. Faza jest bardzo mała przy niewielkich prędkościach; sam niemodulowany kosinus odpowiedzi interferometrycznej ma małe nachylenie blisko zera i nie rozróżnia znaków. Stąd konieczność modulacji fazy i demodulacji synchronicznej.

Lefèvre 2014 podkreśla wzajemność propagacji, rolę polaryzacji, ograniczanie błędów spójnych przez szerokie widmo i korzyści ze źródeł ASE. Nie dowodzi to jednak, że dowolne źródło ASE lub brak polaryzatora zawsze wystarczą.

## 2. Minimalny eksperyment z PZT: Skalský i in. (2019)

Źródło: [Sensors 19, 1710](https://doi.org/10.3390/s19071710).

Autorzy opisują zbudowany IFOG z cewką SMF-28 długości 770 m, średnicą ok. 160 mm, erbowym szerokopasmowym SFS, depolaryzatorem Lyota, polaryzatorem i piezoelektrycznym modulatorem fazy.

Ważne fragmenty oryginału:
- sekcja 2.1, równania (1)-(2): odpowiedź interferometru i open-loop po modulacji;
- sekcja 3.1, rys. 3, strony 7-8: tor optyczny, źródło SFS i odcinki PM do depolaryzatora (1 m + 2 m, osie 45°);
- sekcja 3.2, rys. 5, strony 8-9: fotodioda InGaAs, wzmacniacz transimpedancyjny, filtry analogowe, ADC i DSP;
- sekcja 4: porównanie pracy open-loop i closed-loop, wyniki eksperymentów obrotowych.

Dla naszego POC adaptujemy **tylko tor open-loop**: detektor InGaAs → TIA → AAF → ADC → cyfrowy lock-in oraz generator PZT. Ich demonstracja closed-loop jest późniejszą możliwością rozbudowy. Modulacji 132 kHz z ich cewki nie można przenieść bezpośrednio do naszej cewki; zależy od opóźnienia propagacji i charakterystyki PZT.

## 3. Alternatywny model toru analogowego: Pérez i in. (2016)

Źródło: [Sensors 16, 604](https://doi.org/10.3390/s16050604).

Autorzy projektują i symulują zamkniętopętlowy FOG z cewką 300 m SMF-28, średnicą 80 mm i źródłem SLD 1310 nm. Sekcja 2.2 i rysunki 2-6 pokazują tor fotodiody, TIA, filtry, analogowy mnożnik/demodulator AD630, filtry dolnoprzepustowe oraz pętlę kompensacji serrodyne. Wyniki uzyskano w OptSim, Multisim i Simulink.

**Co wykorzystać:** topologię odbiornika, zasadę detekcji synchronicznej, sposób podziału na sygnał modulacji i sygnał po demodulacji, sposób analizowania kolejnych punktów pomiarowych.

**Czego nie przenosić bez zmian:** konkretnego źródła 1310 nm, częstotliwości około 340,83 kHz, liczb czułości oraz sprzężenia serrodyne do naszego PZT 20 kHz.

## 4. Depolaryzacja i ASE bez klasycznego polaryzatora: Wang i in. (IEEE, 2014)

Źródło: [IEEE Photonics Journal 6, art. 7100208](https://doi.org/10.1109/JPHOT.2014.2299212).

Eksperyment obejmuje ASE o centrum 1550 nm i szerokości ok. 70 nm, cewkę SMF 2097 m oraz cztery depolaryzatory. Głównym warunkiem jest mały stopień polaryzacji (DOP) na wejściu sprzęgacza cewki i odpowiednia symetria drogi optycznej. Dlatego depolaryzator blisko wejścia pętli jest ważniejszy niż sam depolaryzator źródła. Pokazano redukcję błędu polaryzacyjnego przez kompensację dwóch niekoherentnych składowych ortogonalnych (rys. 1-4, strony 3-6). W badaniu podano dryft zera 0,016 stopnia/h.

**Wniosek dla nas:** możliwy wariant bez polaryzatora, ale wymaga zaprojektowania kilku odcinków PM / Lyota i pomiaru polaryzacji. Nie utożsamiać „ASE jest niepolaryzowane” ze spełnieniem tych warunków w całym układzie.

## 5. Porty interferometru: Wang i in. (Optics Express, 2014)

Źródło: [Optics Express 22, 4908–4919](https://doi.org/10.1364/OE.22.004908).

Analizuje wpływ niewzajemności polaryzacyjnej na dwa porty odbioru. W klasycznej topologii drugi port może mieć znaczne błędy polaryzacyjne. Odpowiednio zaprojektowana kompensacja optyczna może pozwolić korzystać również z tego portu, a w szczególnym wariancie ograniczyć liczbę sprzęgaczy. Rys. 1 porównuje schematy konwencjonalne i kompensowane; rys. 5 przedstawia testy stabilności. Autorzy wykorzystali ASE 1550 nm i cewkę 2097 m.

**Wniosek dla nas:** najpierw utrzymać prostą, klasyczną topologię dwóch sprzęgaczy; kompensację portów badać osobno, po uruchomieniu pomiaru fazy.

## 6. Decyzje konstrukcyjne na etap E01 / POC

1. Cewka: nominalnie ok. 1000 m zwykłego SMF, średnica ok. 160 mm (parametry są założeniami naszego modelu, nie gotowym BOM-em).
2. Źródło: laboratoryjne ASE ok. 1550 nm; przed ostatecznym doborem toru zmierzyć moc, widmo oraz jeśli możliwe DOP.
3. Modulator: PZT w jednej gałęzi przy końcu cewki; sprawdzić rzeczywiste Vpi, pojemność i przenoszenie przy częstotliwości modulacji.
4. Elektronika: InGaAs → TIA → filtr antyaliasingowy → ADC → cyfrowa demodulacja synchroniczna → zapis wyniku. Rozdzielić napięciowo i masowo obwody PZT od odbiornika.
5. Pierwszy dowód działania: obserwować harmoniczną przy włączonym PZT, następnie wykonać pomiary dla spoczynku oraz obrotu w obu kierunkach **ze znaną prędkością odniesienia**. Sama reakcja na zmianę sterowania PZT nie dowodzi efektu Sagnaca.
6. Rozbudowa: polaryzator/depolaryzatory, model polaryzacji, kontrola RIN/temperatury, dopiero potem closed-loop.

Wiązanie z kodem i raportami projektowymi: `docs/PROJECT_SUMMARY_MODELS_AND_POC.md`, `docs/MODEL_V4.md`, `docs/MODEL_V5_1.md` oraz `research/E01_basic_FOG/`.
