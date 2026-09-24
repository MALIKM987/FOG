# FOG v4 - walidacja, próba 1

## Status

**Nieudana walidacja. Wyniki tej próby nie są wynikami fizycznymi modelu v4.**

Pierwsze uruchomienie wykazało:

- `Omega = 1 deg/s -> 0 deg/s`,
- `Iphoto_sim = NaN`,
- `Vnoise_sim = 10.517 uV RMS` przy teorii `47.697 uV RMS`,
- wszystkie punkty Monte Carlo dawały dokładnie `0 deg/s`.

## Diagnoza

Inspekcja zapisanego `FOG_v4.slx` wykazała przerwanie fizycznego toru na poziomie głównym:

`Optical Front End -> Photoreceiver -> Lock-In DSP`

Po przebudowie wnętrza subsystemu `Photoreceiver` funkcją `Simulink.SubSystem.deleteContents` zostały skasowane i odtworzone bloki portów subsystemu.

Istniejące linie na poziomie nadrzędnym nie zostały automatycznie poprawnie związane z nowymi portami. W zapisanym modelu występowały wiszące segmenty:

- linia z `Optical Front End/2` nie miała docelowego portu `Photoreceiver/1`,
- linia do `Lock-In DSP/1` nie miała źródła `Photoreceiver/1`.

To całkowicie odłączyło fotoodbiornik od toru optycznego i DSP.

## Dlaczego wynik RMS wyniósł około 10.5 uV

Po odłączeniu wejścia fotoodbiornika nie występował rzeczywisty fotoprąd, więc dynamiczny photo-shot noise nie był generowany.

Pozostały głównie:

- Johnson noise Rf: około 10.20 uV RMS,
- op-amp voltage equivalent noise: około 2.24 uV RMS,
- dużo mniejsze składniki.

Ich RSS jest bliski zaobserwowanym `10.52 uV RMS`.

To dodatkowo potwierdza diagnozę topologiczną.

## Poprawka

Skrypt `matlab/v4/FOG_start_v4.m` został poprawiony.

Przed przebudową subsystemu skrypt jawnie usuwa połączenia:

- `Optical Front End/2 -> Photoreceiver/1`,
- `Photoreceiver/1 -> Lock-In DSP/1`.

Po utworzeniu nowych portów połączenia są tworzone ponownie.

Dodano również samokontrolę:

- wejście `Photoreceiver` musi mieć linię,
- wyjście `V_TIA` musi mieć linię.

Jeśli którykolwiek z tych warunków nie jest spełniony, skrypt kończy się błędem zamiast produkować pozornie poprawne wyniki.

## Wniosek

Pierwsza próba v4 nie waliduje modelu szumowego. Należy ponownie uruchomić poprawiony skrypt i zastąpić wyniki dopiero po poprawnej walidacji.
