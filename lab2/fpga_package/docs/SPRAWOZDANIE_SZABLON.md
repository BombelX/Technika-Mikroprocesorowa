# Laboratorium 2 - SCS na FPGA

Autorzy: **[uzupełnić]** · Grupa: **[uzupełnić]** · Data pomiarów: **[uzupełnić]**

Pola „obserwacja” uzupełniamy dopiero na podstawie rzeczywistego terminala, raportów i płytki. Wartości oczekiwane poniżej są punktem odniesienia, nie wynikami pomiaru sprzętu.

## 1. Cel i stanowisko

Implementacja czterobitowego procesora SCS na FPGA oraz sprawdzenie przesłań, skoków, ADD, SUB i MUL względem modelu Python. Dodatkowo wybór celu ADD przez bit4 kodu zgodnie z §3.6 instrukcji.

| Parametr | Wartość na stanowisku |
|---|---|
| Model / rewizja płytki, układ FPGA | [sprawdzić oznaczenie; paczka: oryginalna ZYBO, xc7z010clg400-1] |
| Vivado / system operacyjny | [wersja; materiały wymagają 2024.1] |
| Terminal / COM | [program, port Pmod] |
| Łącze szeregowe | 115200, 8N1, bez kontroli przepływu |
| Wersja źródeł / commit | [uzupełnić] |
| Programy i profile ISA | [wymienić wykonane] |

**Dowód:** zdjęcie S01 podłączenia dwóch USB; screen S02 projektu.

## 2. Budowa systemu

CPU ma R0/R1/PC po 4 bity, `opcode` 8 bitów i `state` 2 bity. Wspólna przestrzeń kodu i danych zawiera 16 bajtów; jest to organizacja von Neumanna. Dwa porty BRAM służą CPU i debuggerowi, nie oznaczają architektury Harvard. Cechy RISC: stała długość 8 bitów, obliczenia na rejestrach i dostęp do RAM przez LDR/STR. Nie ma potokowania ani rejestru flag.

W tej paczce CPU, UART i sterowanie używają jednego zegara 125 MHz z zezwoleniami kroków. PortA BRAM pracuje na opadającym zboczu, portB na narastającym. Ręczny przycisk daje jeden krok lub cztery kroki, a automatyka jeden krok/s. Instrukcja trwa zawsze cztery kroki, więc w trybie 1 Hz trwa 4 s. Debugger przed nadawaniem zapisuje rejestry i skanuje RAM; BTN0 nie odtwarza COE.

**Dowód:** schemat pamięci S03, parametry 8x16 / Write First / Always Enabled i brak dodatkowego rejestru wyjściowego; S04 COE.

## 3. Etapy instrukcji

| Stan przed | Stan po | Działanie |
|---:|---:|---|
| 0 | 1 | Wystawienie PC jako adresu rozkazu |
| 1 | 2 | Pobranie opcode i zwiększenie PC |
| 2 | 3 | Dekodowanie, wykonanie ALU/MOV/JMP, wystawienie adresu LDR/STR |
| 3 | 0 | Zakończenie LDR lub impuls zapisu STR |

**Dowód:** S05/S14 cztery kroki jednej instrukcji. Opis zaobserwowanych wartości: **[uzupełnić]**.

## 4. Kodowanie rozszerzeń

| Kod | Profil Python0 | Profil lab2=1 |
|---|---|---|
| 20 | R0=(R0+R1) mod 16 | tak samo |
| 30 | R1:R0=R0*R1 | R1=(R0+R1) mod 16 |
| 40 | R0=(R0-R1) mod 16 | tak samo |
| 50 | brak operacji danych | R1:R0=R0*R1 |

Przyczyna profili: kod30 był użyty przez Python do MUL, a wymaganie lab2 rezerwuje go dla ADD do R1. Parametr sprzętu jest stały w bitstreamie. ADD wybiera cel bitem 4; MUL w profilu lab2 przeniesiono na 50. Dolny półbajt tych operacji jest ignorowany. LDR zapisuje dolne 4 bity odczytu, a STR zapisuje bajt 0x0R.

Bazowo wspierane klasy: bezwzględny skok bezwarunkowy, MOV stała-rejestr i rejestr-rejestr, LDR pamięć-rejestr, STR rejestr-pamięć, ADD do R0. Brak skoków warunkowych, stosu i pojedynczego przesłania pamięć-pamięć. Rozszerzenia opisano w tabeli.

**Dowód:** S20 dekoder, profil i właściwe COE; S21 cel ADD; S22 nowa operacja.

## 5. Program wymagany §3.5

Program `load_store`: `80 90 EE 86 DD 20 EE 00`, dane M[D]=05. Początkowe M[E]=11 pozwala obserwować wyzerowanie komórki.

| Instrukcja | Kod | Oczekiwane R0 | R1 | PC | M[E] | Obserwacja / log |
|---|---|---|---|---|---|---|
| MOV R0,#0 | 80 | 0 | 0 | 1 | 11 | [uzupełnić] |
| MOV R1,#0 | 90 | 0 | 0 | 2 | 11 | [uzupełnić] |
| STR R0,[E] | EE | 0 | 0 | 3 | 00 | [uzupełnić] |
| MOV R0,#6 | 86 | 6 | 0 | 4 | 00 | [uzupełnić] |
| LDR R1,[D] | DD | 6 | 5 | 5 | 00 | [uzupełnić] |
| ADD R0,R1 | 20 | B | 5 | 6 | 00 | [uzupełnić] |
| STR R0,[E] | EE | B | 5 | 7 | 0B | [uzupełnić] |
| JMP0 | 00 | B | 5 | 0 | 0B | [uzupełnić] |

Wartości w tabelach są szesnastkowe. W kolejnej pętli STR ponownie zeruje M[E]. **Dowody:** S15-S17 i log UART.

## 6. Porównanie rozszerzeń

| Test / profil | Oczekiwane przed skokiem | Python / model odniesienia | Symulacja RTL | Płytka / log |
|---|---|---|---|---|
| base/0 | R0=2,R1=2,PC=0 po JMP | [plikCSV] | [wynik] | [uzupełnić] |
| load_store/0 | R0=B,R1=5,M[E]=0B | [plikCSV] | [wynik] | [uzupełnić] |
| undefined/0 | 50 bez zmian danych; potem M[E]=0B | [plikCSV] | [wynik] | [uzupełnić] |
| mul/0 | R1:R0=2A,M[E]=02,M[F]=0A | [plikCSV] | [wynik] | [uzupełnić] |
| sub/0 | 7-6=1,M[E]=01 | [plikCSV] | [wynik] | [uzupełnić] |
| overflow/0 | F+1=0,M[E]=00 | [plikCSV] | [wynik] | [uzupełnić] |
| sub_underflow/0 | 3-5=E,M[E]=0E | [plikCSV] | [wynik] | [uzupełnić] |
| load_store/1 | ADD 20: R0=B,R1=5 | model wspólnych instrukcji | [wynik] | [uzupełnić] |
| lab2_add_r1/1 | ADD 30: R0=6,R1=B,M[E]=0B | adapter nowego kodowania | [wynik] | [uzupełnić] |
| lab2_mul/1 | MUL 50: R1:R0=2A,M[E]=02,M[F]=0A | adapter nowego kodowania | [wynik] | [uzupełnić] |

Gotowe oczekiwane stany po instrukcjach: `programs/*.instructions.csv`; po mikrocyklach: `*.trace.json`. Porównywać stan, rejestry, PC i RAM; pole R może różnić się po STR, ponieważ Python zatrzaskuje wybrane odczyty, a BRAM stale czyta bieżący adres. Sprzęt zawija PC F->0; Python nie maskuje PC. Wbudowane programy skaczą przed niedozwolonym pobraniem.

Komentarze Pythona przy MUL zamieniają adresy EF/FE, a komentarz przy SUB podaje dawny wynik MUL. Przyjęto faktyczne bajty programu. **Dowody:** S18-S22, logi UART i źródłowe CSV.

## 7. Synteza i wyniki sprzętowe

| Program/profil | Data bitstreamu | WNS/TNS | Hold/WHS/THS | LUT/FF/BRAM/DSP | DRC | LogUART |
|---|---|---|---|---|---|---|
| [uzupełnić] | [uzupełnić] | [uzupełnić] | [uzupełnić] | [uzupełnić] | [uzupełnić] | [uzupełnić] |

Opisać ostrzeżenia, brakujące ograniczenia i ocenę ścieżek CPU-BRAM pomiędzy przeciwnymi zboczami 125 MHz. **Dowody:** S07-S10. Nie wpisywać wyniku sprzętowego na podstawie samego PASS w symulacji.

## 8. Wnioski

- Które operacje sprawdzono na płytce i jakie wyniki potwierdzono: **[uzupełnić]**.
- Czy zaobserwowano cztery kroki dla każdej instrukcji i zawijanie arytmetyki: **[uzupełnić]**.
- Czy wykazano wybór celu ADD bitem 4 oraz działanie nowej instrukcji: **[uzupełnić]**.
- Różnice symulatora i sprzętu oraz istotne ograniczenia: **[uzupełnić]**.

Załączniki: wybrane screeny, pełne logi UART, COE, raporty Vivado, wersja źródeł. Wykonanie zaprezentowano prowadzącemu: **[kiedy/co]**.
