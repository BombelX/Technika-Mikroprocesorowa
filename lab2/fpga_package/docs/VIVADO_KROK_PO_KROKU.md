# Lab 2: instrukcja stanowiskowa Vivado i zbierania wyników

Instrukcja do **Vivado 2024.1** i **oryginalnej Digilent ZYBO z XC7Z010-1CLG400C**. W Vivado nazwa części to `xc7z010clg400-1`. Oznaczenie `xc7z010_1` w Hardware Manager oznacza wykryte urządzenie. Materiały zajęć wskazują ZYBO na s. 2, wybór płytki na s. 9 i urządzenie na s. 20; dostarczony XDC ma nagłówek „ZYBO Rev B”. Oficjalny [manual ZYBO](https://digilent.com/reference/_media/zybo/zybo_rm.pdf), s. 2, potwierdza część. **ZYBO Z7-10/Z7-20 wymaga innego doboru płytki i pinów.** Sprawdź napis na rzeczywistej płytce przed rozpoczęciem.

Ta paczka zawiera opis sprzętu CPU w Verilogu i programy procesora w plikach COE. Są to dwa różne poziomy: Verilog określa dostępne instrukcje, a COE określa wykonywany program. Do FPGA wgrywamy wynikowy plik `.bit`, w którym są zarówno sprzęt, jak i początkowa zawartość RAM. Vivado nie uruchamia pliku Python na płytce.

W paczce poprawiono także sterowanie względem oryginalnego projektu: CPU/UART pracują od wspólnego zegara 125 MHz, a ręczne kroki i tryb 1 Hz są impulsami zezwolenia `clk_enable`, zamiast przełączanych zegarów z przycisków. Znaczenie SW0...SW2 pozostaje zgodne z zajęciami. Debugger zapamiętuje stan przed wysłaniem tekstu. Wskaźnik LD3 pokazuje wariant ISA. Przy porównywaniu schematu z PDF zaznacz te różnice w sprawozdaniu.

## 1. Co przygotować przed laboratorium

1. Skopiuj całą paczkę `fpga_package` na komputer stanowiskowy, np. do `C:/lab2/fpga_package`. Krótka ścieżka ułatwi pracę. Zachowaj strukturę katalogów.
2. Uruchom **Vivado 2024.1** na komputerze laboratoryjnym. Upewnij się, że instalacja zawiera rodzinę **Zynq-7000**. Materiały dopuszczają darmową edycję Vivado ML Standard, s. 2.
3. Przygotuj PuTTY lub Tera Term, dwa przewody USB z transmisją danych oraz Pmod USBUART podłączony do JE.
4. Utwórz katalog wyników, np. `C:/lab2/wyniki`, oraz plik notatek z nazwiskami, datą, numerem stanowiska, modelem płytki, wersją Vivado i wybranym wariantem ISA.
5. Przeczytaj różnicę między trybem Python i lab2 w README paczki. W Pythonie kod `3x` oznacza mnożenie, a zadanie ze s. 25 materiałów wymaga użycia bitu 4 kodu dodawania do wyboru rejestru. Jedno kodowanie `30` nie może jednocześnie znaczyć obu tych rzeczy. Przed każdą demonstracją zanotuj wariant ISA i nazwę COE.

**Do sprawozdania:** zapisz wersję Vivado i zdjęcie oznaczenia płytki; nie wpisuj modelu wyłącznie na podstawie nazwy projektu.

## 2. Podłączenie płytki: dwa USB o różnych zadaniach

1. Wyłącz płytkę jej przełącznikiem zasilania **SW4**. To osobny przełącznik, inny niż cztery wejścia programu `SW[3:0]`.
2. Sprawdź ustawienie źródła zasilania przy **JP7** zgodnie z opisem na laminacie. Przy zasilaniu z USB programatora wybierz USB; przy zasilaczu stanowiskowym pozostaw poprawną konfigurację stanowiska. Włącznik SW4 załącza zasilacze, a **LD11 / PGOOD** sygnalizuje poprawne napięcia. Te oznaczenia dotyczą oryginalnej ZYBO ([manual ZYBO](https://digilent.com/reference/_media/zybo/zybo_rm.pdf), s. 4).
3. Pierwszy kabel USB podłącz do **PROG/UART, J11** na ZYBO i komputera. Służy do programowania FPGA przez JTAG.
4. Pmod USBUART powinien być osadzony w **JE** tak jak na zdjęciu na s. 5 instrukcji zajęć. Drugi kabel USB podłącz do Pmod i tego samego komputera. Ten kabel odbiera tekst debuggera.
5. Jeśli moduł trzeba dopiero wpiąć, zrób to przy wyłączonej płytce. W tej konfiguracji nadajnik FPGA to `je[5]`, czyli **JE8 / pin FPGA U17**; powinien trafić na **RXD Pmod**. Sześciopinowy Pmod zajmuje rząd JE7...JE12, a jego pin 2 jest naprzeciw JE8. Sprawdź oznaczenia GND i VCC, zamiast zgadywać orientację na podstawie położenia złącza USB. Dowody: `toplevel.v`, dostarczony XDC i [manual ZYBO](https://digilent.com/reference/_media/zybo/zybo_rm.pdf), tabela 9 na s. 25. [Manual Pmod USBUART](https://digilent.com/reference/_media/pmod%3Apmod%3Apmodusbuart_rm.pdf), s. 2, opisuje pin 2 jako RXD i zaleca **JP1=LCL**, gdy urządzenie docelowe jest zasilane oddzielnie.
6. Ustaw wejścia programu `SW[3:0]` na `0000`. Przy standardowej orientacji płytki „0” jest w dół; posługuj się przede wszystkim numerami SW nadrukowanymi na płytce.
7. Włącz SW4. Sprawdź PGOOD. Nie wciskaj przycisku **PROG** ani przycisków PS jako zamienników `BTN0`: w ćwiczeniu używamy czterech przycisków PL oznaczonych BTN0...BTN3.

**Zdjęcie S01:** cała płytka, Pmod na JE, oba kable USB i świecące PGOOD. Oznacz w podpisie kabel JTAG i kabel terminala.

## 3. Utworzenie projektu z paczki - zalecana ścieżka

Użyj skryptów opisanych w głównym README paczki. Skrypt tworzy projekt, dodaje poprawione źródła i XDC oraz generuje blok pamięci. Nie dodawaj równocześnie oryginalnego i poprawionego `cpu.v`: dwa moduły o nazwie `cpu` spowodują konflikt.

1. Otwórz Vivado. Jeżeli konsoli nie widać, wybierz **Window -> Tcl Console**.
2. W konsoli przejdź do wypakowanej paczki poleceniem `cd {C:/lab2/fpga_package}`. Nawiasy klamrowe chronią ścieżki ze spacjami.
3. Dla pierwszego uruchomienia wpisz kolejno w Tcl Console:

   ```tcl
   set PROGRAM base
   set ISA_LAB2 0
   source {C:/lab2/fpga_package/scripts/create_project.tcl}
   ```

   W kolejnych projektach zmieniasz `PROGRAM` i `ISA_LAB2` przed `source`. Wartość 0 oznacza wariant Python, 1 wariant lab2. Użyj ścieżki, pod którą rzeczywiście wypakowano paczkę.
4. Po zakończeniu sprawdź **Project Summary -> Project Part**: `xc7z010clg400-1`. Przy projekcie utworzonym przez część FPGA pole **Board** może być puste - jest to poprawne, jeśli część i XDC są prawidłowe.
5. W **Sources -> Hierarchy** sprawdź, że modułem głównym jest `toplevel`, pod nim są `cpu1`, debugger i `mem1: mem_wrapper`. Pamięć nie może mieć znaku zapytania oznaczającego brak definicji.
6. W **IP Integrator -> Open Block Design** otwórz `mem`. Sprawdź dwa zewnętrzne porty `BRAM_PORTA_0` i `BRAM_PORTB_0`. Możesz dwukrotnie kliknąć pamięć, aby obejrzeć konfigurację opisaną w sekcji 4.
7. Zapisz projekt **Ctrl+S**. Pierwszy projekt znajduje się w `build/base_python/scs.xpr`; następne mają ścieżkę `build/<PROGRAM>_<python|lab2>/scs.xpr`. Otwieraj później ten plik `.xpr`; oryginalny katalog paczki pozostaw dostępny, ponieważ źródła mogą być dołączone przez odwołania.
8. Budowę możesz uruchomić przyciskiem **Generate Bitstream** z sekcji 6 albo po otwarciu projektu wpisać w konsoli `source {C:/lab2/fpga_package/scripts/build_bitstream.tcl}`. Symulację uruchamia osobny skrypt `scripts/simulate.tcl`, zgodnie z README.

Alternatywa z **Vivado 2024.1 Tcl Shell** lub terminala z dostępnym poleceniem Vivado, po przejściu do paczki:

```text
vivado -mode batch -source scripts/create_project.tcl -tclargs base 0
```

To polecenie odtwarza projekt; generację bitstreamu uruchom osobno według README. Zwykły terminal bez skonfigurowanej ścieżki do Vivado może nie rozpoznać polecenia.

**Screen S02:** Project Summary z częścią FPGA oraz Sources z kompletną hierarchią. **Screen S03:** schemat `mem`, szerokość 8 bitów, głębokość 16, oba porty. **Screen S04:** Other Options z wybranym COE i notatka o ISA.

## 4. Odtworzenie projektu ręcznie, zgodnie z materiałami

Ta ścieżka jest przydatna, jeśli prowadzący wymaga pokazania etapów z instrukcji. Jeśli projekt utworzono skryptem, nie twórz drugiej pamięci o tej samej nazwie. Poniższe kroki odtwarzają s. 6-19 instrukcji zajęć.

### 4.1. Kreator projektu

1. W ekranie startowym kliknij **Create Project**, ewentualnie **File -> Project -> New**.
2. Kliknij **Next**, wpisz nazwę i katalog projektu. Zaznacz **Create project subdirectory**. Kliknij **Next**.
3. Wybierz **RTL Project**. Odznacz **Do not specify sources at this time**. Kliknij **Next**.
4. W **Add Sources -> Add Files** dodaj wszystkie pliki Verilog z katalogu źródeł tej paczki, bez plików testbench. Ustaw **Target language: Verilog**, **Simulator language: Mixed**. Możesz zaznaczyć **Copy sources into project**; przy tej opcji edytuj później kopie widoczne w Vivado, bo to one są kompilowane. Kliknij **Next**.
5. **Add Existing IP** pomiń przyciskiem **Next**.
6. W **Add Constraints -> Add Files** wybierz XDC z paczki. Kliknij **Next**.
7. W **Default Part -> Boards** ustaw **Vendor: digilentinc.com**, **Name: Zybo**, a następnie **kliknij cały wiersz Zybo, żeby był podświetlony**. Sam filtr nazwy nie wybiera płytki. Jeżeli definicji płytki brak, zainstaluj ją przez dostępne opcje katalogu płytek/Refresh lub wybierz w zakładce **Parts** dokładnie `xc7z010clg400-1`. XDC nadal musi być dodany.
8. W podsumowaniu ponownie sprawdź część i kliknij **Finish**.
9. W Sources zaznacz `toplevel`, prawy przycisk -> **Set as Top**, jeżeli nie jest już modułem głównym.
10. Wybór ISA ustaw przez parametr `ISA_LAB2` modułu głównego. W Tcl Console wpisz `set_property generic {ISA_LAB2=0} [get_filesets sources_1]` dla wariantu Python albo `set_property generic {ISA_LAB2=1} [get_filesets sources_1]` dla lab2. Parametr 0 to zgodność kodowania z Pythonem; 1 to wariant zadania lab2. Sama zmiana COE nie zmienia dekodera sprzętowego.

### 4.2. Pamięć w IP Integrator

1. W **Flow Navigator -> IP Integrator -> Create Block Design** wpisz **Design name: mem** i kliknij **OK**.
2. W Diagram kliknij **Add IP** (`+`), wyszukaj **Block Memory Generator** i dodaj go dwuklikiem. Domyślna nazwa bloku: `blk_mem_gen_0`.
3. Dwukrotnie kliknij blok, ewentualnie prawy przycisk -> **Customize Block**.
4. W zakładce **Basic** ustaw **Mode: Stand Alone** i **Memory Type: True Dual Port RAM**.
5. W **Port A Options** ustaw:
   - **Write Width: 8**, **Read Width: 8**;
   - **Write Depth: 16**, **Read Depth: 16**;
   - **Operating Mode: Write First**;
   - **Enable Port Type: Always Enabled**;
   - **Primitives Output Register: odznaczone**; dodatkowy wyjściowy rejestr rdzenia także wyłączony, jeśli jest pokazany.
6. W **Port B Options** sprawdź szerokość 8 i głębokość 16, ustaw **Always Enabled**, wyłącz **Primitives Output Register** i ewentualny dodatkowy rejestr wyjściowy. Zachowaj **Write First**.
7. W **Other Options** zaznacz **Load Init File**. Kliknij **Browse** i wybierz COE odpowiedniego programu. Na pierwsze uruchomienie wybierz bazowy program MOV/JMP. Kliknij **OK**.
8. Na schemacie kliknij prawym przyciskiem interfejs **BRAM_PORTA** -> **Make External**. Powtórz dla **BRAM_PORTB**. Oczekiwane nazwy zewnętrzne to `BRAM_PORTA_0` i `BRAM_PORTB_0`, bo takich nazw używa `toplevel.v`.
9. Zapisz **Ctrl+S**. Kliknij **Validate Design** z menu kontekstowego schematu lub odpowiedniej ikony. Wyjaśnij wszystkie błędy przed dalszym krokiem.
10. W **Sources** kliknij prawym na `mem.bd` -> **Generate Output Products**, jeśli Vivado tego wymaga. Następnie prawym na `mem` -> **Create HDL Wrapper** -> **Let Vivado manage wrapper and auto-update** -> **OK**.
11. Sprawdź, że `mem1` jest rozpoznany i nie ma znaku zapytania. **Topem ma pozostać `toplevel`, a nie `mem_wrapper`.**

Przy otwartym schemacie możesz potwierdzić ustawienia także w Tcl Console:

```tcl
get_property CONFIG.use_bram_block [get_bd_cells blk_mem_gen_0]
get_property CONFIG.Memory_Type [get_bd_cells blk_mem_gen_0]
get_property CONFIG.Write_Width_A [get_bd_cells blk_mem_gen_0]
get_property CONFIG.Write_Depth_A [get_bd_cells blk_mem_gen_0]
get_property CONFIG.Coe_File [get_bd_cells blk_mem_gen_0]
```

Oczekuj kolejno `Stand_Alone`, `True_Dual_Port_RAM`, `8`, `16` i ścieżki wybranego COE. Domyślny tryb IP Integrator to **BRAM Controller**, dlatego sam wybór True Dual Port nie zastępuje ustawienia Stand Alone. Opis trybów i mapowanie nazw parametrów zawiera [AMD PG058, Block Memory Generator v8.4](https://docs.amd.com/api/khub/documents/V70n09duEdKgzrX2d1W97g/content), s. 95-98.

RAM ma 16 bajtowych lokacji wspólnych dla kodu i danych. Dane CPU mają 4 bity, więc LDR bierze dolny półbajt. Port A obsługuje CPU, port B debugger. RAM jest synchroniczny mimo wyłączonego dodatkowego rejestru wyjściowego. W paczce port A pracuje na odwróconym `CLK_IN`, a port B na `CLK_IN`; zmiany CPU następują przy impulsach zezwolenia. Oryginał w materiałach używał portu A na odwróconym, wolnym zegarze CPU. Nie zastępuj konfiguracji pamięcią z inną latencją bez zmiany CPU.

## 5. Symulacja przed wgraniem

1. Po utworzeniu projektu uruchom `source {C:/lab2/fpga_package/scripts/simulate.tcl}` w Tcl Console, zgodnie z README. Jeżeli chcesz samodzielnie obejrzeć przebiegi, wykonaj również poniższe kroki GUI. Skrypt może już uruchomić symulację; nie otwieraj drugiej równolegle.
2. Sprawdź w **Sources -> Simulation Sources**, który testbench jest ustawiony jako top symulacji. Top syntezy pozostaje `toplevel`.
3. W **Flow Navigator -> Simulation -> Run Simulation -> Run Behavioral Simulation** uruchom symulację. W konsoli sprawdź podsumowanie PASS/FAIL testbench. Sama obecność przebiegów nie oznacza zaliczenia testu.
4. W **Scopes** wybierz CPU, a w **Objects** dodaj do wykresu przez **Add to Wave Window**: zegar, `clk_enable`, reset, `dbg_state`, `dbg_pc`, `dbg_r0`, `dbg_r1`, adres i dane pamięci oraz `mem_we`. Przy symulacji integracji dodaj `step_tick` z `toplevel`. Dla danych ustaw prawym przyciskiem **Radix -> Hexadecimal**.
5. Jeżeli skrypt zdążył już zakończyć symulację, po dodaniu sygnałów kliknij **Restart**, aby rozpocząć od czasu 0 i zarejestrować ich przebiegi. Użyj **Run All**, a następnie **Zoom Fit**. Znajdź jedną pełną instrukcję: cztery aktywne impulsy `clk_enable` i stany 0 -> 1 -> 2 -> 3 -> 0. Zaznacz moment zmiany wyniku. W trybie CE pomiędzy krokami nadal występują zbocza zegara głównego, ale CPU wtedy nie przechodzi do kolejnego stanu. Testbench samego CPU może używać zezwolenia stale aktywnego i wtedy każdy takt przesuwa stan.
6. Zanotuj nazwę testu, wariant ISA i wynik. Testy zgodności Python/Verilog odpal według README; nie utożsamiaj czterech taktów Veriloga z jedną iteracją instrukcji bez uwzględnienia stanów.

**Screen S05:** przebiegi pełnej instrukcji z widocznymi nazwami sygnałów i wartościami. **Screen S06:** podsumowanie testów. Podstawowy sposób uruchomienia i obsługi symulatora opisuje [AMD UG900 dla Vivado 2024.1](https://docs.amd.com/r/2024.1-English/ug900-vivado-logic-simulation).

## 6. Synteza, implementacja i bitstream

1. W **Flow Navigator -> Program and Debug -> Generate Bitstream** kliknij **Generate Bitstream**.
2. Na pytanie o zapis kliknij **Save**. Na pytanie o brakujące etapy syntezy/implementacji kliknij **Yes**. Zatwierdź przydział zasobów komputera w **Launch Runs**.
3. Poczekaj na zakończenie. W międzyczasie skonfiguruj terminal, ale nie edytuj aktywnie kompilowanych źródeł.
4. Otwórz **Design Runs**. `synth_1` oraz `impl_1` powinny być zakończone, a etap zapisu bitstreamu kompletny. Obejrzyj **Messages**; czerwone błędy wymagają poprawy, ostrzeżenia zapisz i oceń.
5. Po komunikacie **Bitstream Generation Completed** wybierz **Open Implemented Design** lub otwórz go z Flow Navigator. W **Reports -> Timing -> Report Timing Summary** sprawdź, czy wymagania czasowe są spełnione i czy istotne ścieżki nie są nieograniczone. W **Reports -> Report Utilization** zapisz liczbę LUT, FF, BRAM i DSP. W **DRC** sprawdź brak błędów blokujących.
6. Zapisz raporty do katalogu wyników. Sprawdź ścieżki pomiędzy CPU i BRAM, także relację przeciwległych zboczy zegara głównego; sam sukces generacji `.bit` nie dowodzi poprawnego opisania wszystkich relacji czasowych. W paczce usunięto dzielone/przełączane zegary z oryginału, ale wynik raportowania nadal trzeba sprawdzić. Nie ukrywaj problemów przez obniżanie poziomu błędów DRC.
7. Zanotuj pełną ścieżkę i datę `.bit` z katalogu wynikowego `*.runs/impl_1/` lub wskazanego przez skrypt. Przy wielu projektach wybieraj wynik właściwego wariantu ISA i COE.

**Screen S07:** zakończone Design Runs oraz Timing Summary z WNS/TNS. **Screen S08:** Utilization i ewentualne istotne ostrzeżenia. Opis generowania i programowania zawiera [AMD UG908 dla Vivado 2024.1](https://docs.amd.com/r/2024.1-English/ug908-vivado-programming-debugging).

## 7. Wgranie konfiguracji do FPGA

1. Sprawdź zasilanie płytki i kabel **PROG/UART**.
2. W **Flow Navigator -> Open Hardware Manager -> Open Target -> Auto Connect** połącz się ze stanowiskiem. W układzie lokalnym Vivado uruchamia lokalny serwer sprzętowy; alternatywne połączenie przez kreator opisuje [AMD: Opening a New Hardware Target](https://docs.amd.com/r/2024.1-English/ug908-vivado-programming-debugging/Opening-a-New-Hardware-Target).
3. W panelu **Hardware** sprawdź, że wykryto **xc7z010_1**. Jeśli widzisz inną rodzinę/rozmiar, porównaj rzeczywistą płytkę z ustawieniami projektu przed programowaniem.
4. Kliknij **Program Device -> xc7z010_1**, ewentualnie prawym na urządzeniu -> **Program Device**.
5. W **Bitstream file** wybierz wygenerowany `.bit`. Domyślna ścieżka jest poprawna tylko wtedy, gdy pochodzi z bieżącego projektu i ostatniej kompilacji. Plik debug probes `.ltx` nie jest wymagany dla debuggera UART użytego w tym ćwiczeniu.
6. Kliknij **Program**. Poczekaj na zakończenie i stan **Programmed**. Sprawdź diodę **DONE**.
7. Ustaw `SW[3:0]=0000`, naciśnij i zwolnij **BTN0**, aby ustawić CPU i debugger w znanym stanie.

Programowanie `.bit` przez JTAG ładuje konfigurację do FPGA. Po wyłączeniu zasilania trzeba wgrać ją ponownie. `BTN0` resetuje CPU i debugger, ale **nie przywraca danych BRAM z COE**. Aby powtórzyć test z identycznej początkowej pamięci, ponów **Program Device**, a potem BTN0.

**Screen S09:** Program Device z nazwą właściwego `.bit`. **Screen S10:** wykryte `xc7z010_1` i stan Programmed; dodatkowo zdjęcie DONE.

## 8. Terminal UART i pierwszy wiarygodny odczyt

1. W Windows otwórz **Menedżer urządzeń -> Porty (COM i LPT)**. Znajdź port USB Serial odpowiadający Pmod. Gdy jest kilka portów, odłącz wyłącznie kabel USB Pmod, sprawdź, który port zniknie, i podłącz go z powrotem. Nie wybieraj portu tylko dlatego, że ma najmniejszy numer.
2. W PuTTY, w **Session**, wybierz **Connection type: Serial**. W **Serial line** wpisz znalezione `COMxx`, a **Speed: 115200**.
3. W **Connection -> Serial** ustaw **Data bits: 8**, **Stop bits: 1**, **Parity: None**, **Flow control: None**. Kontrola RTS/CTS powinna być wyłączona.
4. W **Session -> Logging** wybierz **All session output**, wskaż plik tekstowy w katalogu wyników, np. `start_python_uart.txt`. W Tera Term odpowiedniki to ustawienia portu szeregowego i **File -> Log**.
5. Kliknij **Open**. Terminal może być pusty do chwili żądania zrzutu; to normalne.
6. Na płytce ustaw **SW[3:0]=0000**: zegar ręczny, pełne instrukcje, zrzut ręczny. Naciśnij BTN0, zwolnij, odczekaj około sekundy. Naciśnij krótko **BTN1**. Oczekuj linii zaczynającej się od `c=0 r0=0 r1=0 pc=0` i kończącej zrzutem 16 bajtów pamięci.
7. Porównaj `M:` z COE. Wartości `A`, `R`, `W` przed pierwszym taktem zależą również od inicjalizacji magistral w konkretnej wersji RTL; pierwszy odczyt ma przede wszystkim potwierdzić CPU po resecie i właściwą zawartość RAM.

**Screen S11:** parametry portu i numer COM. **Screen S12:** pierwszy czytelny zrzut i zgodne `M:`. Log tekstowy jest wygodniejszy do porównań niż sam screen.

### 8.1. Sterowanie w trakcie testów

Zapis `SW[3:0]` oznacza kolejno SW3, SW2, SW1, SW0. Dla uniknięcia pomyłki sprawdzaj każdy numer na płytce.

| Element | Ustawienie / działanie |
|---|---|
| BTN0 | Reset CPU i debuggera; RAM zachowuje zmiany |
| BTN1 | Ręczne żądanie zrzutu UART, gdy SW2=0 |
| BTN2 | Podanie ręcznego zegara; działa przy SW1=0 |
| SW0=0 | Paczka czterech taktów, czyli jedna instrukcja |
| SW0=1 | Jeden takt na naciśnięcie BTN2 |
| SW1=0 | Zegar ręczny |
| SW1=1 | Zegar automatyczny około 1 Hz, czyli około 4 s na instrukcję |
| SW2=0 | Zrzut wywołuje BTN1 |
| SW2=1 | Zrzuty wyzwala zegar CPU |
| SW3 / BTN3 | Nieużywane w funkcjonalnym sterowaniu tego projektu |
| LD0 | Zmiana stanu przy każdym kroku CPU; wskaźnik aktywności, nie fizyczny zegar 125 MHz |
| LD1 | Zajętość nadawania debuggera |
| LD2 | Odfiltrowany stan BTN2 |
| LD3 | Wariant ISA: zgaszona Python, zapalona lab2 |

Do tabel porównawczych używaj **0000** albo **0001**. Naciśnij przycisk przynajmniej około 0,05 s, zwolnij BTN2, odczekaj około sekundy, potem BTN1 i zaczekaj na cały wiersz. Domyślnie przyciski mają filtr około 10 ms, a cztery kroki paczki są oddalone o około 50 ms i kończą się po około 150 ms. Zapas sekundy ułatwia spokojne notowanie. Debugger paczki zatrzaskuje rejestry i szybko skanuje BRAM, a następnie wysyła zapamiętane dane. Nie naciskaj kolejnego kroku podczas odczytu, aby kolejne wiersze łatwo przypisać do instrukcji. Oryginalny debugger z materiałów wypisywał żywe sygnały bez takiego bufora.

Ustawienia `0100` i `0101` z instrukcji zajęć włączają automatyczny zrzut po taktach; są dobre do szybkiej obserwacji. Przy `0100` jedno naciśnięcie może wygenerować kilka wierszy, bo instrukcja zawiera cztery takty. `0110` daje automatyczny zegar i zrzut, lecz jedna instrukcja nadal trwa cztery takty.

### 8.2. Znaczenie pól zrzutu

| Pole | Znaczenie |
|---|---|
| `c` | Stan maszyny CPU 0...3; jeden takt przechodzi do następnego stanu |
| `r0`, `r1` | 4-bitowe rejestry danych, zapis szesnastkowy |
| `pc` | Licznik programu; podczas większości wykonywania wskazuje kolejną instrukcję |
| `A` | Bieżący adres na magistrali pamięci |
| `R` | Bajt odczytany z pamięci |
| `W` | Bajt na magistrali zapisu; sama jego wartość nie dowodzi, że właśnie nastąpił zapis |
| `M:` | 16 bajtów pamięci w kolejności adresów 0...15 |

## 9. Kolejność demonstracji i oczekiwane wyniki

### 9.1. Program startowy: potwierdzenie działania całego toru

Użyj programu `base` z bajtami `80 90 81 92 A0 00`, dopełnionymi zerami do 16 komórek. Wybierz wariant Python albo lab2 - te instrukcje są wspólne.

1. Wgraj `.bit`, ustaw `0000`, naciśnij BTN0, następnie BTN1. Zapisz stan początkowy.
2. Powtarzaj: BTN2, zwolnij, zaczekaj około sekundy, BTN1, zapisz wiersz.
3. Po kolejnych pełnych instrukcjach oczekuj:

| Wykonana instrukcja | R0 | R1 | PC po instrukcji |
|---|---:|---:|---:|
| reset | 0 | 0 | 0 |
| `mov r0,#0` | 0 | 0 | 1 |
| `mov r1,#0` | 0 | 0 | 2 |
| `mov r0,#1` | 1 | 0 | 3 |
| `mov r1,#2` | 1 | 2 | 4 |
| `mov r0,r1` | 2 | 2 | 5 |
| `jmp 0` | 2 | 2 | 0 |

4. Dla jednej instrukcji przełącz na `0001`, zresetuj CPU i po każdym BTN2 poproś o odczyt BTN1. Pokaż przejścia `c`: 0 -> 1 -> 2 -> 3 -> 0. Wnioskiem ma być różnica między cyklem zegarowym a instrukcją.

**Screen S13:** kilka kolejnych stabilnych stanów programu startowego. **Screen S14:** cztery takty jednej instrukcji; podpisz fazy na podstawie RTL: wystawienie adresu, pobranie kodu i inkrementacja PC, dekodowanie/wykonanie, zakończenie odczytu lub przygotowanie zapisu.

### 9.2. Program wymagany na s. 23 materiałów

Program ma wyzerować R0, R1 i `M[14]`, wczytać 6 do R0, dodać wartość z `M[13]=5`, zapisać wynik do `M[14]` i wykonać skok na początek. Bazowe dodawanie jest rejestr-rejestr, dlatego wartość pamięci trzeba wcześniej wczytać instrukcją LDR.

1. Wybierz program **`load_store`**, tj. `set PROGRAM load_store`, `set ISA_LAB2 0`, utwórz projekt i przebuduj/wgraj `.bit` według sekcji 10. Przy tym programie wariant 1 również obsługuje użyte instrukcje.
2. Sprawdź, że zrzut początkowy pokazuje `M[13] = 05`. To adres dziesiętny 13, czyli **D** w zapisie szesnastkowym; komórka wyniku ma adres dziesiętny 14, czyli **E**.
3. W trybie `0000` wykonuj instrukcje pojedynczo, zapisując po każdej `PC/R0/R1/M[D]/M[E]`.
4. Po STR zerującym `M[E]` potwierdź `M[E]=00`.
5. Po LDR i MOV potwierdź właściwe argumenty: R0=6, R1=5. Po ADD oczekuj **R0=B, R1=5**. Po STR oczekuj **M[E]=0B**. To 11 dziesiętnie.
6. Po skoku potwierdź PC=0 i rozpoczęcie kolejnej iteracji. Nie traktuj wyczyszczenia `M[E]` na początku następnej iteracji jako błędu programu.
7. Pokaż działanie prowadzącemu, zapisz w notatkach, co zostało zaprezentowane.

**Screen S15:** COE z instrukcjami i danymi. **Screen S16:** wynik B po ADD. **Screen S17:** zapis 0B w `M[E]` i początek następnej iteracji. W tabeli sprawozdania umieść także kody maszynowe z konkretnego COE.

### 9.3. Zgodność rozszerzeń z Pythonem

1. Wybierz **wariant Python**, `set ISA_LAB2 0`, i program `mul` albo `sub`; przebuduj i zaprogramuj układ.
2. W programie **`mul`** kolejne instrukcje to `CC DD 30 EF FE 00`. Sprawdź początkowo `M[C]=06` i `M[D]=07`. Po dwóch LDR oczekuj R0=6, R1=7. Po `30` iloczyn 42 dziesiętnie, czyli `2A`, daje **R1=2, R0=A**. Po `EF` dolny półbajt trafia do **M[F]=0A**, a po `FE` górny do **M[E]=02**. Komentarze przy STR w `lab1/scs.py` zamieniają adresy 14/15; rzeczywisty adres wynika z dolnego półbajtu kodu, więc w tym teście poprawna kolejność wyniku w pamięci jest E:02, F:0A.
3. W programie **`sub`** początek to `CC DD 40 EE 00`. Sprawdź `M[C]=07`, `M[D]=06`. Po LDR/LDR i `40` oczekuj **R0=1, R1=6**, a po STR **M[E]=01**. Komentarz sugerujący inny wynik w Pythonie jest nieaktualny; liczą się bajty i wykonanie.
4. Dodatkowo uruchom **`sub_underflow`**: `83 95 40 EE 04` ustawia R0=3, R1=5, wykonuje SUB, zapisuje wynik do M[E] i zatrzymuje się w pętli JMP4. Wynik -2 daje **R0=E, R1=5, M[E]=0E** modulo 16. Program **`overflow`**, `8F 91 20 EE 04`, pokazuje F+1 -> **R0=0, R1=1, M[E]=00**. To dodatkowe przypadki względem oryginalnych `mul`/`sub` z lab1; oba mogą działać w wariancie Python i lab2.
5. Porównaj stany z wynikiem symulatora Python dla identycznych bajtów. Porównuj stabilny stan po pełnych instrukcjach i rzeczywiste zmiany RAM. CPU na płytce ma 4-bitowy PC; szczególne przypadki związane z końcem pamięci interpretuj zgodnie z ograniczeniami opisanymi w README.

W katalogu `programs` każdemu programowi towarzyszą `NAZWA.instructions.csv` ze stanem po pełnych instrukcjach i `NAZWA.trace.json` z kolejnymi mikrocyklami. Użyj ich jako wzorca przy sporządzaniu tabeli; kolumna `cycle` podaje liczbę kroków CPU, nie liczbę wszystkich zboczy 125 MHz.

**Screen S18:** mnożenie 6*7 z oboma półbajtami wyniku i oznaczeniem wariantu Python. **Screen S19:** odejmowanie 7-6, a opcjonalnie także zawinięcie wyniku 3-5, wraz z odpowiadającym stanem Pythona.

### 9.4. Rozszerzenie ADD wymagane na s. 25

1. Wybierz **wariant lab2**, `set ISA_LAB2 1`, i program `lab2_add_r1`, a do mnożenia `lab2_mul`. Zmiana ISA wymaga syntezy nowego sprzętu; nie wystarczy podmiana bajtu w RAM.
2. W tym wariancie `20` oznacza **ADD do R0**, a `30` oznacza **ADD do R1**. Oba obliczają sumę R0+R1; bit 4 wybiera cel. Mnożenie jest przeniesione na `50`, a odejmowanie pozostaje na `40`.
3. Pokaż dwa przypadki z argumentami 6 i 5. Program `load_store` z ISA_LAB2=1 używa `20` i daje **R0=B, R1=5**, a po STR **M[E]=0B**. Program `lab2_add_r1` ma bajty `80 90 EE 86 DD 30 FE 00` oraz początkowo `M[D]=05`, `M[E]=11`. Przeprowadź jego kroki: zerowanie R0, zerowanie R1, zapis zera do M[E], ustawienie R0=6, wczytanie R1=5, `30` -> **R0=6, R1=B**, `FE` -> **M[E]=0B**, skok na początek. Dane 11 na początku są celowe: widać, że program faktycznie czyści komórkę.
4. Pokaż co najmniej jedną dodatkową operację wymaganą przez instrukcję zajęć: mnożenie `50` albo odejmowanie `40`. Paczka wspiera obie. `lab2_mul` jest kopią programu `mul` z kodem `30` zastąpionym przez `50`; oczekiwany wynik pozostaje **R1:R0=2A**, potem **M[E]=02, M[F]=0A**.
5. Zapisz kod dekodera i wyniki jako dowód, że wybór rejestru zależy od bitu 4. Prowadzącemu wyjaśnij konflikt kodowania z Pythonem i zastosowane dwa warianty.

**Screen S20:** fragment dekodera ADD z wyborem bitu 4 i parametr ISA. **Screen S21:** dwa wyniki dla `20` i `30`. **Screen S22:** dodatkowa instrukcja w wariancie lab2.

## 10. Zmiana programu lub sprzętu: co trzeba ponowić

### Zmiana programu COE w GUI

1. **Flow Navigator -> IP Integrator -> Open Block Design -> mem**.
2. Dwukrotnie kliknij pamięć -> **Other Options**.
3. Wybierz **Browse**, aby wskazać inny COE, albo **Edit**, aby zmienić wartości w edytorze Vivado. Przy edycji zgodnej z materiałami: **Save -> Validate -> Close**, potem **OK** w ustawieniach IP.
4. **Ctrl+S**. Jeśli Vivado proponuje regenerację output products, wykonaj ją. W razie potrzeby prawy przycisk na `mem.bd` -> **Generate Output Products**.
5. Kliknij **Generate Bitstream**. Potwierdź ponowne uruchomienie zależnych etapów. Jeżeli Vivado nie wykrywa zmiany po ręcznej podmianie zawartości COE, ponownie otwórz właściwości IP i wskaż plik; sprawdź, czy edytowana była właściwa kopia pliku.
6. Ponów **Program Device**, sprawdź datę `.bit`, ustaw tryb ręczny i BTN0. Porównaj `M:` z nowym COE przed krokami CPU.

Każdy COE musi mieć `memory_initialization_radix=16;`, `memory_initialization_vector=`, 16 bajtów i średnik po ostatniej wartości. Sprawdź, czy kod i dane mieszczą się w 16 lokacjach i czy program nie nadpisuje własnych instrukcji.

### Zmiana Veriloga albo parametru ISA

1. Zamknij aktywną symulację. Zmień właściwy plik w Sources albo parametr projektu.
2. Ponów testy symulacyjne.
3. Ponownie **Generate Bitstream**, a następnie **Program Device**. Sprawdź, że wynik nie pochodzi ze starego wariantu.
4. Zarchiwizuj COE, wariant ISA, log UART i raporty pod wspólną nazwą testu.

## 11. Problemy, które najczęściej zatrzymują ćwiczenie

| Objaw | Sprawdzenie i działanie |
|---|---|
| Brak sprzętu w Auto Connect | PGOOD, kabel danych w PROG/UART, urządzenie USB/sterownik programatora; zamknij połączenie innego programu z JTAG i ponów Open Target. Sprawdź lokalny serwer i wersję Vivado. |
| Jest COM, ale nie ma FPGA | Prawdopodobnie podłączony tylko Pmod USBUART; JTAG potrzebuje osobnego kabla w PROG/UART. |
| FPGA jest Programmed, terminal pusty | Właściwy COM Pmod, kabel drugi USB, 115200/8N1/flow none; SW2=0 -> BTN1; BTN0 po wgraniu; sprawdź osadzenie Pmod przy JE8. |
| Losowe znaki zamiast tekstu | Parametry terminala, właściwa płytka/125 MHz i pin zegara L16, właściwy plik bitstream. |
| `mem_wrapper` ze znakiem zapytania | Nazwa BD `mem`, wrapper utworzony i dołączony, oba interfejsy z właściwymi nazwami, output products wygenerowane. |
| Brak portu BRAM lub inna szerokość | Stand Alone, True Dual Port, 8x16, oba porty Make External; porównaj nazwy z instancją `mem1`. |
| Błąd DRC NSTD/UCIO | Niewłaściwy/brakujący XDC, różne nazwy portów, niewłaściwy top. Użyj poprawionego `toplevel` z czterema BTN PL. Nie wyłączaj sprawdzeń DRC. |
| Jeden krok daje kilka wierszy | SW2=1 włącza zrzut po taktach; SW0=0 generuje cztery takty. Do pojedynczego stabilnego odczytu użyj 0000 i osobno BTN1. |
| Przycisk pozornie nie reaguje drugi raz | Zwolnij przycisk, odczekaj około sekundy, nie ponawiaj w trakcie paczki impulsów i filtracji. |
| M[E] po resecie nadal ma wynik | Reset CPU nie resetuje BRAM. Wgraj ponownie `.bit` dla odtworzenia COE. |
| Stary program po zmianie COE | Wskazano inny plik/kopię, nie wygenerowano IP, pominięto przebudowę albo wgrano stary `.bit`; sprawdź po kolei te cztery etapy. |
| `30` daje inną operację niż oczekiwana | Konflikt wariantu ISA: Python -> MUL, lab2 -> ADD_R1. Dobierz razem parametr sprzętu i COE. |
| Wynik mnożenia wydaje się za mały | Sprawdź oba rejestry: wynik to `R1:R0`, a nie wyłącznie R0. |
| Jedna linia UART pokazuje sprzeczne fazy | Sprawdź, czy wgrano paczkę z buforowaniem zrzutu, a nie stary debugger. Do weryfikacji zatrzymaj kroki, odczekaj i poproś o odczyt BTN1. |

## 12. Co zebrać do sprawozdania

Nie trzeba umieszczać wszystkich proponowanych screenów. Wybierz czytelne dowody i dołącz logi jako dane źródłowe. Każdy podpis powinien zawierać **program COE, wariant ISA, moment obserwacji i oczekiwany wynik**.

Minimalny zestaw dowodów:

1. Zdjęcie podłączenia: ZYBO, JE/Pmod, dwa USB, zasilanie.
2. Projekt: część FPGA i hierarchia; schemat pamięci oraz COE.
3. Symulacja: cztery takty instrukcji i podsumowanie testów.
4. Budowa: zakończone Design Runs, raport czasowy i zużycie zasobów; odnotowane istotne ostrzeżenia.
5. Programowanie: Hardware Manager z urządzeniem i wgranym `.bit`.
6. Działanie: program bazowy, 6+5 i zapis do M[E], ADD do obu rejestrów w wariancie lab2, MUL i SUB zgodne z wariantem ISA.
7. Tabela porównania Python/Verilog/płytka, uwzględniająca zawijanie 4-bitowe i wynik mnożenia w dwóch rejestrach.

Zakres merytoryczny wymagany na s. 25 instrukcji:

- **Cykle:** cztery takty zegara składają się na jedną instrukcję; przy zegarze CPU około 1 Hz przepustowość to około 0,25 instrukcji/s. Rozróżnij zegar wejściowy 125 MHz i zegar CPU wybierany w systemie.
- **Organizacja pamięci:** von Neumann - wspólna przestrzeń kodu i danych, 16x8 bitów. Dwa porty BRAM służą CPU i debuggerowi; nie tworzą rozdzielnych pamięci Harvard.
- **Charakter instrukcji:** prosta architektura o cechach RISC: stałe instrukcje 8-bitowe, mały zestaw, obliczenia na rejestrach, wymiana z pamięcią przez LDR/STR. Uzasadnij na konkretnych cechach, bez utożsamiania RISC wyłącznie z liczbą taktów.
- **Szerokości:** R0/R1/PC i adresy po 4 bity, opcode i magistrale danych pamięci po 8 bitów, stan CPU 2 bity. Brak oddzielnego rejestru flag w udostępnionym rdzeniu.
- **Klasy instrukcji:** skok bezwarunkowy bezwzględny; MOV natychmiastowy i rejestr-rejestr; LDR pamięć-rejestr; STR rejestr-pamięć. Brak pojedynczej instrukcji pamięć-pamięć. Bazowo ADD do R0; rozszerzenia opisz osobno z kodowaniem wybranego wariantu.
- **Rejestry wewnętrzne:** R0/R1 przechowują dane, PC adres kolejnej instrukcji, opcode pobrany rozkaz, state fazę. Wyjścia magistrali i mem_we także są realizowane jako stan w RTL, ale nie są rejestrami widocznymi dla programisty.
- **Wydajność:** brak potokowania; jedna instrukcja przechodzi po kolei przez cztery stany, również JMP/MOV/ADD/MUL/SUB. Nazwy i czynności faz uzasadnij kodem CPU. Zapis do synchronicznej BRAM jest zatwierdzany na właściwym zboczu jej zegara.
- **Weryfikacja rozszerzeń:** pokaż zmianę dekodera, kody instrukcji, argumenty, wyniki normalne i co najmniej jeden przypadek przepełnienia/zawinięcia. Oddziel wyniki z symulacji od obserwacji rzeczywistej płytki.

Na koniec zachowaj cały projekt i paczkę źródeł, użyte COE, skrypty, raporty, logi terminala i wybrane obrazy. Dopiero te obserwacje stanowią wyniki laboratoryjne; przygotowana paczka i przewidywane wartości są punktem odniesienia.

## Źródła i granice sprawdzenia

- Materiały stanowiskowe: `lab2/lab-scs-tm2526_20251020.pdf`, zwłaszcza s. 2-5, 6-24 i wymagania s. 25. To źródło nazw klikanych opcji i kolejności budowania pamięci w Vivado 2024.1.
- Dokumentacja rdzenia: `lab2/scs_trm_2.01_pl.pdf`, s. 2-7; oryginalne pliki `lab2/cpu_src/src/toplevel.v`, `cpu.v`, `dbgu.v`, `clocknx.v`, `prescaler.v` i `other/Constraints.xdc`; jako źródło rozszerzeń kod `lab1/cpu.py`.
- [Digilent ZYBO Reference Manual](https://digilent.com/reference/_media/zybo/zybo_rm.pdf): model FPGA, zasilanie, piny zegara/JE i rozdzielenie PL/PS. Dostarczone XDC odpowiada oryginalnej ZYBO, a nie rodzinie Z7.
- [Digilent Pmod USBUART Reference Manual](https://digilent.com/reference/_media/pmod%3Apmod%3Apmodusbuart_rm.pdf): RXD i ustawienie zasilania modułu.
- [AMD UG908, Vivado 2024.1](https://docs.amd.com/r/2024.1-English/ug908-vivado-programming-debugging) i [Opening a New Hardware Target](https://docs.amd.com/r/2024.1-English/ug908-vivado-programming-debugging/Opening-a-New-Hardware-Target): konfiguracja/programowanie i Hardware Manager.
- [AMD UG900, Vivado 2024.1](https://docs.amd.com/r/2024.1-English/ug900-vivado-logic-simulation): symulacja i analizowanie przebiegów.
- [AMD PG058, Block Memory Generator v8.4](https://docs.amd.com/api/khub/documents/V70n09duEdKgzrX2d1W97g/content), s. 95-98: tryb Stand Alone i nazwy parametrów pamięci. [AMD UG835, launch_runs w 2024.1](https://docs.amd.com/r/2024.1-English/ug835-vivado-tcl-commands/launch_runs): przy użyciu Tcl uruchomienie implementacji wymaga zakończonego nadrzędnego przebiegu syntezy.

Przy opracowaniu instrukcji nie potwierdzono modelu fizycznej płytki stanowiskowej ani nie wykonano na niej programowania. Model wynika z lokalnych materiałów i oficjalnej dokumentacji. Nazwy opcji mogą nieznacznie różnić się w innych wersjach Vivado; instrukcja jest dopasowana do wymaganej wersji 2024.1. Ewentualne wyniki syntezy i sprzętowe należy dopisać po rzeczywistym wykonaniu ćwiczenia.
