# Architektura i zgodność z symulatorem

Źródła semantyki: `lab1/cpu.py`, rzeczywiste bajty programów `lab1/scs.py`, oryginalny `lab2/cpu_src/src/cpu.v`, dokumentacja rdzenia `lab2/scs_trm_2.01_pl.pdf` (s. 2-7) oraz instrukcja `lab2/lab-scs-tm2526_20251020.pdf` (szczególnie §3.5-3.6). Instrukcja laboratoryjna ma pierwszeństwo przy wykonaniu wymaganego rozszerzenia ADD.

## Dwa profile ISA: konieczna kolizja kodu 30

W Pythonie `30` oznacza mnożenie. W §3.6 lab2 wynik ADD trzeba wybierać **bitem 4**: zatem `20` dodaje do R0, a `30` musi dodawać do R1. Jedna nierozróżnialna instrukcja `30` nie może jednocześnie realizować obu zachowań. Parametr syntezy `ISA_LAB2` w module `toplevel` i `cpu` rozwiązuje tę kolizję:

| Górny półbajt | `ISA_LAB2=0`: zgodność lab1 | `ISA_LAB2=1`: wymagania lab2 |
|---|---|---|
| `0` | `PC = imm4` | to samo |
| `1` | niezdefiniowana | to samo |
| `2` | `R0 = (R0 + R1) & F` | to samo |
| `3` | `R1:R0 = R0 * R1` | **`R1 = (R0 + R1) & F`** |
| `4` | `R0 = (R0 - R1) & F` | to samo |
| `5` | niezdefiniowana | **`R1:R0 = R0 * R1`** |
| `6`, `7` | niezdefiniowana | to samo |
| `8` | `R0 = imm4` | to samo |
| `9` | `R1 = imm4` | to samo |
| `A` | `R0 = R1` | to samo |
| `B` | `R1 = R0` | to samo |
| `C` | `R0 = RAM[addr4] & F` | to samo |
| `D` | `R1 = RAM[addr4] & F` | to samo |
| `E` | `RAM[addr4] = {0, R0}` | to samo |
| `F` | `RAM[addr4] = {0, R1}` | to samo |

Dolny półbajt dla ADD/MUL/SUB i MOV rejestr-rejestr jest ignorowany, tak jak w `cpu.py`: przykładowo `30` i `3F` mają tę samą semantykę w danym profilu. Niezdefiniowane instrukcje trwają cztery kroki, zwiększają PC podczas pobrania, ale nie zmieniają rejestrów danych i pamięci. Hardware nie emituje komunikatu wywołania Pythonowego `undefined_cb`.

Parametr jest stały w bitstreamie: zmiana SW[3] nie przełącza ISA. Przełącznik SW[3] pozostaje niewykorzystany. LD3 wskazuje profil skompilowanego projektu: 0 = Python, 1 = lab2. Do §3.6 użyć profilu lab2 oraz odpowiadających mu programów; programy bez kodów `3?`/`5?` działają identycznie w obu profilach.

## Rejestry, pamięć i arytmetyka

- R0 i R1: po 4 bity; PC: 4 bity; rejestr rozkazu `opcode`: 8 bitów; `state`: 2 bity.
- Wspólna pamięć instrukcji i danych ma 16 komórek po 8 bitów. Jest to organizacja von Neumanna z instrukcjami typu load/store i uproszczonym zestawem o cechach RISC.
- ADD i SUB zachowują dolne cztery bity. `F + 1 = 0`, `0 - 1 = F`. Nie ma flag C/Z/N/V.
- MUL oblicza pełne 8 bitów: R0 otrzymuje dolny półbajt, R1 górny. `6 * 7 = 2A`, `F * F = E1`. Oba wyniki korzystają z wartości wejściowych sprzed instrukcji.
- LDR odrzuca górny półbajt RAM. STR zapisuje cały bajt z górnym półbajtem zerowym.
- PC w sprzęcie zawija `F -> 0`, zgodnie z architekturą 4-bitową. `cpu.py` nie maskuje PC, więc program bez skoku przy końcu pamięci może tam doprowadzić do `IndexError`; tego błędu symulatora sprzęt nie kopiuje. Bezpośrednie porównanie z oryginalnym Pythonem trzeba zakończyć przed niedozwolonym pobraniem, albo jawnie znormalizować PC do 4 bitów w modelu porównawczym.

## Cztery kroki każdej instrukcji

`c` jest **stanem po wykonaniu kroku**, tak jak w Pythonie. Po resecie `c=0`; kolejne wykonane kroki pokazują `1,2,3,0`.

| Stan przed krokiem | Stan po kroku | Czynność |
|---|---|---|
| 0 | 1 | Wystawienie adresu PC do pobrania rozkazu |
| 1 | 2 | Zapis bajtu z RAM do `opcode`, inkrementacja PC |
| 2 | 3 | Dekodowanie, ALU/MOV/JMP albo wystawienie adresu i danych LDR/STR |
| 3 | 0 | Zakończenie LDR albo impuls zapisu STR; koniec instrukcji |

Instrukcja zawsze wymaga czterech **zezwoleń kroku CPU**. Nie ma potoku ani równoległego pobierania kolejnej instrukcji. W dostarczonym topie sprzęt fizycznie jest taktowany zegarem 125 MHz, lecz stan CPU zmienia się wyłącznie przy `clk_enable`. Automatyczne zezwolenie ma 1 Hz, więc wykonanie instrukcji trwa 4 s (0,25 instrukcji/s). Nie należy opisywać częstotliwości fizycznego zegara jako szybkości wykonywania instrukcji w ustawionym trybie 1 Hz.

## Zegary i porty pamięci

Oryginalne moduły `clocknx`, `prescaler`, `debouncer`, `pulsegen` zostały zastąpione sterowaniem synchronicznym. Nie są potrzebne w tym projekcie i nie należy dodawać ich razem z nowymi źródłami.

- CPU, synchronizatory, obsługa przycisków, debugger i UART pracują na narastającym zboczu `CLK_IN` (125 MHz).
- Port A `mem_wrapper` pracuje na `~CLK_IN`: transakcja następuje na opadającym zboczu zegara głównego. CPU ma pół okresu (4 ns) na wystawienie adresu/danych, a pamięć pół okresu na zwrócenie danych. Pamięć musi mieć jeden synchroniczny odczyt bez dodatkowego rejestru wyjściowego (`Primitives Output Register` wyłączone), zgodnie z PDF.
- Port B pracuje na `CLK_IN` i służy wyłącznie do odczytu debuggera. Tryb RAM: True Dual Port, 16 x 8, Always Enabled, Write First.
- `mem_we` trwa dokładnie jeden okres zegara głównego po zakończeniu STR. Dzięki temu zatrzymany CPU nie powtarza zapisu przez całą przerwę między ręcznymi krokami.
- Reset jest asynchronicznie aktywowany BTN0 i synchronicznie zwalniany przez dwa przerzutniki. Wejścia przycisków i przełączników są synchronizowane. Nie ma kombinacyjnego multipleksera zegarów wybieranego SW.

Nie dodawać wyjątków `set_false_path` dla CPU-RAM ani nie wyłączać DRC zegarów, żeby ukryć problemy z timingiem. W Vivado trzeba zweryfikować timing ścieżek półokresowych; jest to część weryfikacji projektu sprzętowego, której nie potwierdza sam test funkcjonalny.

## Sterowanie płytką i UART

| Element | Zachowanie |
|---|---|
| BTN0 | Zeruje CPU, sterowanie i debugger; **nie przywraca obrazu RAM** |
| BTN1 | Ręcznie zleca zrzut, gdy SW2=0 |
| BTN2 | Zleca krok albo pełną instrukcję w trybie ręcznym |
| BTN3 | Niewykorzystany |
| SW0=0 | Jedno naciśnięcie BTN2 daje cztery kroki, w odstępach 50 ms |
| SW0=1 | Jedno naciśnięcie BTN2 daje jeden krok |
| SW1=0 | Tryb ręczny |
| SW1=1 | Jeden krok na sekundę; BTN2 nie generuje dodatkowych kroków |
| SW2=0 | Debug wyzwalany BTN1 |
| SW2=1 | Debug automatycznie po każdym kroku |
| SW3 | Niewykorzystany |
| LD0 | Zmienia stan po każdym kroku CPU |
| LD1 | Zrzut/pakiet UART w toku |
| LD2 | Odfiltrowany stan BTN2 |
| LD3 | Wskazanie `ISA_LAB2` |
| JE[5] | TX do PMOD USB-UART, jak w oryginalnym `toplevel.v` |

Przyciski muszą utrzymać stabilny stan przez około 10 ms. Przytrzymanie przycisku generuje jedno zdarzenie; kolejne wymaga zwolnienia. Nie zmieniać trybu SW0/SW1 w środku instrukcji: zmiana trybu anuluje pozostałe kroki bieżącej serii; nie cofa już wykonanych kroków. Nowa seria czterech kroków rozpoczyna się od bieżącego `c`, więc do demonstracji zaczynać od BTN0.

UART: 115200 baud, 8N1, bez kontroli przepływu. Sprzętowy dzielnik 1085 okresów daje ok. 115207,4 baud (błąd ok. 0,0064%). Linia ma ten sam format co w lab1 i PDF:

```text
c=0 r0=B r1=5 pc=7 A=E R=0B W=0B M: 80 90 EE 86 DD 20 EE 00 00 00 00 00 00 05 0B 00
```

Debugger zatrzaskuje rejestry, odczytuje wszystkie 16 komórek i wysyła zapisany obraz. Opóźnienie automatycznego wyzwolenia pozwala zakończyć fizyczny zapis STR przed zrzutem. W standardowych trybach kroki CPU są oddalone o co najmniej 50 ms, a zrzut trwa około 7,5 ms, więc pamięć jest skanowana pomiędzy krokami. Wyzwolenia w czasie `LD1=1` są pomijane; do ręcznego odczytu czekać na zgaśnięcie LD1. CPU nie jest sprzętowo wstrzymywany przez debugger; w niestandardowym, przyspieszonym taktowaniu skan pamięci nie jest atomowy.

Fizyczna RAM stale aktualizuje wyjście `R`, a Python przechowuje `mem_data_r` tylko podczas wybranych kroków. Po STR tryb Write First pokazuje zapisany bajt na `R`, podczas gdy Python może nadal pokazywać poprzednio odczytany bajt. Zgodność obliczeń należy oceniać przez R0/R1/PC/stany i RAM, uwzględniając moment próbkowania magistral. Nie należy wymagać identycznego `R` po każdym zboczu głównego zegara.

Ponowne naciśnięcie BTN0 nie usuwa wyników z RAM. Aby odzyskać dokładny początkowy obraz `.coe`, ponownie zaprogramować urządzenie bitstreamem. Jest to także powód, dla którego program §3.5 jawnie czyści komórkę E na początku pętli.

## Korekty komentarzy lab1 bez zmiany bajtów

W `mul_program` bajt `EF` oznacza `STR R0,[F]`, a `FE` oznacza `STR R1,[E]`; istniejące komentarze zamieniają adresy. Oryginalny program dla `6*7=2A` daje zatem **RAM[E]=02, RAM[F]=0A**. To wynik zgodny z kodem, choć odwrotny wobec tych komentarzy. W `sub_program` komórki C,D zawierają odpowiednio `07,06`, zatem oczekiwany wynik to `1`. Komentarz przy `40` wspominający `R1=2,R0=A` jest pozostałością mnożenia i nie opisuje odejmowania.

## Testy do uruchomienia

`sim/tb_cpu.v` jest samosprawdzającym testem obu profili: wszystkie 256 kodów rozkazu dla 16 x 16 par R0/R1, razem 65 536 przypadków na profil. Porównuje stan, rejestry, adres, dane zapisu, impuls WE i całą RAM po każdym kroku. Obejmuje ignorowane bity, niezdefiniowane rozkazy, przepełnienie ADD, ujemny SUB, maksymalny MUL, LDR z wysokim półbajtem, STR do obszaru kodu, pauzę `clk_enable`, zawijanie PC oraz reset poza granicą instrukcji.

`sim/tb_toplevel.v` uruchamia rzeczywiste RTL sterowania/debuggera/UART z modelem synchronicznego BRAM `sim/mem_wrapper_model.v`. Sprawdza program §3.5 (`RAM[E]=0B`), dokładnie cztery lub jeden krok po naciśnięciu, przytrzymanie/drgania BTN2, dekoduje po 86 bajtów rzeczywistego TX przy ręcznym i automatycznym wyzwoleniu oraz sprawdza dane zrzutu i próbkowanie stanu po kroku, reset z zachowaniem RAM oraz licznik trybu automatycznego. Parametry czasu są skrócone tylko w instancji testowej.

**Model `mem_wrapper_model.v` służy wyłącznie symulacji integracyjnej poza projektem z wygenerowanym BD. Nie dodawać go do syntezy ani do tej samej biblioteki symulacji co prawdziwy `mem_wrapper`.** Test CPU jest samowystarczalny i może być uruchomiony w Vivado bez modelu integracyjnego.

Przykład przy dostępnym Icarus Verilog (z katalogu paczki):

```sh
iverilog -g2012 -s tb_cpu -o /tmp/scs_cpu.vvp rtl/cpu.v sim/tb_cpu.v
vvp /tmp/scs_cpu.vvp
iverilog -g2012 -s tb_toplevel -o /tmp/scs_top.vvp rtl/*.v sim/mem_wrapper_model.v sim/tb_toplevel.v
vvp /tmp/scs_top.vvp
```

Komunikat `PASS` jest wynikiem testu symulacyjnego; do potwierdzenia pracy w FPGA wymagane są jeszcze synteza, implementacja, timing, programowanie i pomiary na rzeczywistej płytce.

Weryfikacja wykonana 16.10.2026: Icarus Verilog 12.0, kompilacja `-g2012 -Wall` bez ostrzeżeń dla obu testów. Oba testy zakończyły się kodem 0 i poniższymi komunikatami:

```text
PASS tb_cpu: 65536 opcode/register cases x 2 ISA profiles, 1572931 master cycles; PC rollover, pauses, reset
PASS tb_toplevel: 3.5 program, 4/1-step controls, debounce, manual/automatic UART decoded, reset RAM retention, automatic timer
```
