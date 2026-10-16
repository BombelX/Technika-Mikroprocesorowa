# Lab 2: Vivado i ZYBO na Windows 11

**Na pierwsze uruchomienie: `OTWORZ_VIVADO.cmd`, opcja 1, potem przełączniki `0100`.** Poniżej cała kolejność. Nie trzeba ręcznie tworzyć projektu, dodawać Veriloga, wybierać pinów ani budować schematu pamięci.

## Który plik do czego służy?

| Plik | Działanie |
|---|---|
| **README.md** | Ta instrukcja: czytaj od punktu 1 do 7 |
| **OTWORZ_VIVADO.cmd** | Uruchom dwuklikiem w Windows; tworzy lub otwiera projekt Vivado |
| **OTWORZ_PUTTY.cmd** | Uruchom dwuklikiem w Windows; otwiera wybrany COM w PuTTY |

Pliki `.cmd` są programami uruchamiającymi narzędzia. Cała instrukcja jest w Markdown. Na pierwsze uruchomienie potrzebujesz tylko tych trzech plików oraz pozostałych katalogów paczki, które skrypty wykorzystują automatycznie.

## 1. Przygotuj komputer i dwa kable

1. Komputer ma mieć **pełne Vivado 2024.1** z obsługą **Zynq-7000** oraz PuTTY. Samo **Vivado Lab Edition** nie wystarczy do syntezy tej paczki. Nie potrzeba Pythona ani WSL.
2. Kliknij ZIP prawym przyciskiem -> **Wyodrębnij wszystkie** / **Extract All**. Umieść cały folder pod **`C:\lab2\fpga_package`**. W nim muszą być `OTWORZ_VIVADO.cmd`, `rtl`, `scripts` i `programs`. Nie uruchamiaj skryptu wewnątrz podglądu ZIP. Wybierz krótki katalog poza OneDrive, bez polskich liter i nawiasów.
3. Upewnij się, że to **oryginalna ZYBO**, układ **XC7Z010**, nie ZYBO Z7. Ta paczka ma piny oryginalnej płytki. Płytka zawiera FPGA; nasz Verilog tworzy w nim procesor.
4. Przy wyłączonym zasilaniu sprawdź Pmod USBUART w **JE**, zgodnie ze zdjęciem stanowiska. Przygotowana płytka powinna mieć go już poprawnie osadzonego. Jeśli trzeba go wpiąć, dopasuj GND/VCC i RXD do JE8 według [pełnego przewodnika](docs/VIVADO_KROK_PO_KROKU.md#2-podłączenie-płytki-dwa-usb-o-różnych-zadaniach).
5. Podłącz **kabel nr 1: ZYBO PROG/UART -> USB komputera**. To programator.
6. Podłącz **kabel nr 2: USB na małym Pmod w JE -> USB komputera**. To tekst do PuTTY. Wbudowany port UART z kabla nr 1 nie odbiera zrzutów tego projektu.
7. Sprawdź źródło zasilania **JP7** zgodnie z opisem na płytce: USB, jeśli zasilasz przez USB. Włącz **SW4**, osobny włącznik zasilania. Powinna świecić **PGOOD**. Cztery małe przełączniki SW0...SW3 opisujemy dopiero niżej.

**Zdjęcie do sprawozdania:** płytka, Pmod i oba kable.

## 2. Otwórz projekt dwuklikiem

1. Zamknij poprzednie okno Vivado po zapisaniu pracy.
2. W Eksploratorze dwukrotnie kliknij **`OTWORZ_VIVADO.cmd`**. Jeżeli Windows ukrywa rozszerzenia, plik może być widoczny jako `OTWORZ_VIVADO`.
3. Skrypt szuka `vivado.bat` w typowych katalogach Vivado 2024.1 i w PATH. Jeśli go nie znajdzie, poprosi o ścieżkę. Można ją odczytać: prawy przycisk na skrócie Vivado -> **Właściwości -> Element docelowy**. Wklej samą ścieżkę kończącą się na `bin\vivado.bat`, np. `D:\Xilinx\Vivado\2024.1\bin\vivado.bat`, i Enter.
4. W menu skryptu naciśnij **1**. Nic więcej nie konfiguruj. To program wymagany w lab2: oblicza 6+5 i zapisuje wynik w RAM. Profil lab2 jest już wybrany.
5. Poczekaj, aż otworzy się Vivado i skończy tworzyć pamięć. W **Tcl Console** powinno pojawić się **`WINDOWS PROJECT READY`**. To pierwszy punkt kontrolny: brak błędów, projekt utworzony. Czarne okno skryptu pozostaw otwarte.
6. W **Sources** top ma nazwę `toplevel`, a pamięć `mem1: mem_wrapper` nie może mieć znaku zapytania. W **Project Summary** część to **`xc7z010clg400-1`**.

Przy pierwszym uruchomieniu skrypt **tworzy prawdziwy projekt w Waszym Vivado**. Przy kolejnych otwiera istniejący:

```text
C:\lab2\fpga_package\build\load_store_lab2\scs.xpr
```

Można go później otworzyć przez **Vivado -> File -> Project -> Open**. Nie przenoś samego `.xpr`: projekt korzysta z reszty folderu paczki. Przed podłączeniem płytki można już utworzyć projekt i zbudować bitstream.

**Screen:** część FPGA i kompletna hierarchia Sources.

## 3. Zbuduj plik, który wgrywa się na płytkę

1. W lewym pasku Vivado kliknij **Generate Bitstream**.
2. Jeżeli pyta o zapis: **Save**. Jeżeli pyta o syntezę/implementację: **Yes**. W **Launch Runs** pozostaw proponowane zasoby i **OK**.
3. Poczekaj na **Bitstream Generation Completed**. Może to potrwać kilka lub kilkanaście minut.
4. W tym oknie wybierz **Open Implemented Design -> OK**. Jeśli wcześniej je zamknąłeś, wybierz **Open Implemented Design** z lewego paska.
5. Otwórz **Reports -> Timing -> Report Timing Summary**, zatwierdź **OK**. W raporcie sprawdź brak naruszeń setup/hold i brak nieograniczonych istotnych ścieżek. Jeżeli raport zgłasza niespełnione wymagania, pokaż go prowadzącemu przed wgraniem. Szczegóły oceny są w pełnym przewodniku.
6. Plik do wgrania dla opcji 1 powinien być tutaj:

   ```text
   C:\lab2\fpga_package\build\load_store_lab2\scs.runs\impl_1\toplevel.bit
   ```

**Screen:** zakończona budowa i Timing Summary. Veriloga nie wgrywa się bezpośrednio: Vivado przekształca go wraz z programem COE w ten plik `.bit`.

## 4. Wgraj na ZYBO

1. W lewym pasku kliknij **Open Hardware Manager -> Open Target -> Auto Connect**.
2. Powinno pojawić się urządzenie **`xc7z010_1`**. Jeśli nie ma go na liście, sprawdź włączone zasilanie i kabel **PROG/UART**. Gdy Windows nie rozpoznaje programatora, potrzebne są sterowniki kabla z instalacji Vivado.
3. Kliknij **Program Device -> xc7z010_1**.
4. W **Bitstream file** sprawdź plik z poprzedniej sekcji. Jeśli wskazany jest inny, użyj przycisku **...** i wybierz właściwy `toplevel.bit`. Plik `.ltx` nie jest potrzebny.
5. Kliknij **Program** i poczekaj na zakończenie. Powinna zaświecić dioda **DONE**. Dla opcji 1 będzie też świecić **LD3**, bo wybraliśmy profil lab2.

**Screen:** Hardware Manager po zaprogramowaniu.

## 5. Znajdź właściwy COM i otwórz PuTTY

1. Kliknij prawym na **Start Windows -> Menedżer urządzeń -> Porty (COM i LPT)**.
2. Odszukaj port od **Pmod**. Jeśli nie wiesz który: odłącz od komputera **tylko kabel nr 2**, zobacz, który `COM` zniknął, i podłącz go ponownie. Odczytaj jego aktualny numer. Przykład: **COM11**; Wasz numer może być inny.
3. Jeśli nowy port nie pojawia się, sprawdź kabel z transmisją danych i sterownik Pmod. Zanotuj urządzenie z żółtym wykrzyknikiem i pokaż prowadzącemu; wybieranie losowego COM tego nie naprawi.
4. Otwórz **PuTTY**. W **Session** zaznacz **Serial**. Wpisz swój COM do **Serial line**, a **115200** do **Speed**.
5. Z lewej wybierz **Connection -> Serial**. Ustaw **Data bits: 8**, **Stop bits: 1**, **Parity: None**, **Flow control: None**.
6. Do sprawozdania włącz **Session -> Logging -> All session output**, wybierz własny plik logu.
7. Wróć do **Session**. Opcjonalnie w **Saved Sessions** wpisz `ZYBO` i **Save**. Kliknij **Open**.

Skrót na kolejne uruchomienia: **`OTWORZ_PUTTY.cmd`**, wpisz rozpoznany COM i Enter. Skrypt uruchomi PuTTY z właściwymi parametrami; logowanie włącz ręcznie z menu PuTTY. Wymaga zainstalowanego PuTTY, wpisu w PATH albo `putty.exe` obok skryptu.

Puste okno przed wykonaniem kroku jest normalne. Projekt wysyła zrzuty po naciśnięciu przycisku lub po kroku automatycznym. **Nie ma logowania ani obsługi komend wpisywanych na klawiaturze PuTTY.**

**Screen:** ustawienia COM i transmisji.

## 6. Te cztery przełączniki: ustaw dokładnie 0100

Odczytuj kolejno **SW3, SW2, SW1, SW0** z nadruków na płytce. Nie zakładaj, że pierwszy od lewej na obróconej płytce to SW3.

| Przełącznik | Ustaw na start |
|---|---|
| **SW3** | **0 / dół** |
| **SW2** | **1 / góra** |
| **SW1** | **0 / dół** |
| **SW0** | **0 / dół** |

Czyli **`0100`**. Teraz:

1. Naciśnij i zwolnij **BTN0**. To reset procesora; nie przycisk PROG ani przyciski PS.
2. Odczekaj sekundę.
3. Naciśnij **BTN2** na około 0,1 s i zwolnij. Poczekaj sekundę.
4. W PuTTY powinny pojawić się **cztery wiersze**, ze stanami `c=1`, `c=2`, `c=3`, `c=0`. To **jedna instrukcja**. Do tabeli wyników bierz ostatni wiersz, `c=0`.
5. Powtarzaj BTN2, po każdym naciśnięciu czekając sekundę. Nie zmieniaj przełączników w trakcie wykonywania instrukcji.

### Co ma wyjść w opcji 1

Licz od resetu. Każde naciśnięcie BTN2 wykonuje kolejny wiersz tabeli. Wszystkie liczby w kolumnach wyników są szesnastkowe.

| Naciśnięcie BTN2 | Co wykonano | Ostatni wiersz, `c=0` |
|---:|---|---|
| 1 | MOV R0,#0 | `r0=0 r1=0 pc=1` |
| 2 | MOV R1,#0 | `r0=0 r1=0 pc=2` |
| 3 | STR R0,[E] | komórka `M[E]=00` |
| 4 | MOV R0,#6 | `r0=6 r1=0 pc=4` |
| 5 | LDR R1,[D] | `r0=6 r1=5 pc=5` |
| 6 | ADD R0,R1 | **`r0=B r1=5 pc=6`** |
| 7 | STR R0,[E] | **`M[E]=0B`, `pc=7`** |
| 8 | JMP0 | `pc=0`, wynik nadal w `M[E]` |

Po naciśnięciu nr 7 końcówka zrzutu pamięci ma postać **`... 05 0B 00`**. `M:` wypisuje komórki od 0 do F, więc E to przedostatni bajt. `B` oznacza 11 dziesiętnie, czyli 6+5.

**Screeny:** wynik po naciśnięciu 6 oraz po 7. Zachowaj też pełny log PuTTY.

### Kiedy 0101, 0000 i 0110?

| SW3..SW0 | Do czego | Co naciskać |
|---|---|---|
| **0100** | Najprostsze testowanie instrukcja po instrukcji | BTN2 -> 4 kroki i 4 wiersze |
| **0101** | Pokazanie czterech faz osobno | BTN2 -> 1 krok i 1 wiersz; 4 naciśnięcia kończą instrukcję |
| **0000** | Czysta tabela: jeden zrzut po całej instrukcji | BTN2 -> poczekaj sekundę -> BTN1 |
| **0110** | Samoczynna demonstracja | 1 krok i wiersz/s; instrukcja trwa 4 s |
| **1010** | Nie używaj jako ustawienia startowego | Włącza kroki automatyczne, ale nie automatyczne zrzuty |

**BTN0 reset, BTN1 ręczny odczyt przy SW2=0, BTN2 ręczny krok przy SW1=0.** Przed zmianą trybu zatrzymaj test; po zmianie naciśnij BTN0, aby od nowa liczyć instrukcje. Reset nie przywraca pamięci z COE. Gdy potrzeba identycznego stanu początkowego RAM, ponów **Program Device** i BTN0.

## 7. Następne programy do sprawozdania

Zapisz pracę, zamknij Vivado i uruchom ponownie `OTWORZ_VIVADO.cmd`. Wybierz opcję poniżej. Dla każdego nowego projektu ponów **Generate Bitstream -> sprawdzenie raportów -> Program Device**, ustaw `0100`, BTN0 i wykonaj podaną liczbę naciśnięć BTN2. Plik `.bit` pochodzi z aktualnego projektu; sprawdź ścieżkę w oknie programowania.

| Opcja | Projekt | Co pokazać po ilu naciśnięciach BTN2 |
|---:|---|---|
| 1 | `load_store_lab2` | po 6: R0=B,R1=5; po 7: M[E]=0B |
| 2 | `mul_python` | po 3: R1=2,R0=A; po 5: M[E]=02,M[F]=0A |
| 3 | `sub_python` | po 3: R0=1,R1=6; po 4: M[E]=01 |
| 4 | `lab2_add_r1_lab2` | po 6: **R0=6,R1=B**; po 7: M[E]=0B |
| 5 | `lab2_mul_lab2` | po 3: **R1:R0=2A**; po 5: M[E]=02,M[F]=0A |
| 6 | `base_python` | po 5: R0=2,R1=2; po 6: PC=0 |

Opcje **1 i 4** pokazują wymagany przez lab2 wybór rejestru wyniku ADD. Opcja **5** pokazuje dodatkową instrukcję MUL. Opcje **2 i 3** są porównaniem z oryginalnym Pythonem. Przewodnik szczegółowy wyjaśnia konieczne dwa kodowania instrukcji `30`; menu dobiera je za Was.

## 8. Co paczka przygotowuje i co trzeba sprawdzić

| Oczekiwanie | Co jest przygotowane |
|---|---|
| Bez ręcznego tworzenia projektu i RAM | Tak: `OTWORZ_VIVADO.cmd` uruchamia automatyczne tworzenie i otwiera GUI |
| Później otwieram zwykłe `.xpr` | Tak: powstaje lokalnie po pierwszym uruchomieniu |
| Bez ręcznego pisania Veriloga i programów | Tak: komplet źródeł, COE i ustawień jest w paczce |
| Podłączam płytkę i odbieram zrzuty w PuTTY | Po zbudowaniu i wgraniu `.bit`, z dwoma kablami i właściwym COM; tekst wywołuje BTN2 |
| Fabrycznie gotowy, sprawdzony `.bit` | Jeszcze nie: tutaj nie ma Vivado ani fizycznej płytki |
| Po odłączeniu zasilania tylko uruchamiam PuTTY | Trzeba ponownie wgrać `.bit` przez Program Device; ta instrukcja używa JTAG |

Nie można obiecać potwierdzonego działania Windows/Vivado/płytki na podstawie samych symulacji RTL. Przygotowano przenośne źródła, automatyzację i oczekiwane wyniki; testy RTL przeszły. Skrypty `.cmd`, rzeczywisty IP i timing trzeba sprawdzić na stanowisku. W razie błędu zatrzymaj się na opisanym punkcie kontrolnym i zachowaj tekst z Tcl Console.

**Dokumentacja sprawdzona dla Windows:** [AMD UG973: Vivado2024.1, Windows11 22H2/23H2](https://docs.amd.com/r/2024.1-English/ug973-vivado-release-notes-install-license/Supported-Operating-Systems), [AMD: otwieranie `.xpr`](https://docs.amd.com/r/2024.1-English/ug835-vivado-tcl-commands/open_project), [PuTTY: port szeregowy i parametry `-sercfg`](https://www.puttyssh.org/0.83/htmldoc/Chapter3.html#using-cmdline-sercfg). Nowsze wydania Windows11 nie są wymienione w tabeli wsparcia Vivado2024.1; nie wymaga to zmiany kodu CPU, a działanie instalacji należy potwierdzić na używanym stanowisku.

## Dodatkowa dokumentacja i pliki

W codziennej pracy zaczynaj od tego README. Pozostałe dokumenty służą konkretnym zadaniom:

| Dokument | Zastosowanie |
|---|---|
| [Szczegółowa obsługa Vivado](docs/VIVADO_KROK_PO_KROKU.md) | Ręczne odtworzenie projektu, konfiguracja IP, diagnostyka i screeny S01-S22 |
| [Szablon sprawozdania](docs/SPRAWOZDANIE_SZABLON.md) | Tabele do uzupełnienia rzeczywistymi wynikami |
| [Architektura](docs/ARCHITEKTURA.md) | CPU, instrukcje, profile ISA i różnice względem Pythona |
| [Programy i skrypty](docs/PROGRAMY_I_SKRYPTY.md) | Oczekiwane wyniki, komendy Tcl i opcjonalne testy z Windows |
| [Wyniki testów](evidence/TESTY.md) | Co sprawdzono w symulacji i co pozostaje do sprawdzenia na płytce |

Katalogi `rtl/` i `constraints/` zawierają sprzęt i piny; `programs/` programy COE i oczekiwane stany; `scripts/` narzędzia pomocnicze; `sim/` testbenche; `reference/` niezmieniony Python z lab1. `build/` powstaje po uruchomieniu Vivado. Nie trzeba otwierać ani edytować tych plików do pierwszego testu.
