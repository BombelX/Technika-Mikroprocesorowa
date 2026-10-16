# SCS: paczka na laboratorium 2

Komplet źródeł do **oryginalnej Digilent ZYBO / XC7Z010-1CLG400C**, zegar 125 MHz, **Vivado 2024.1**. Skrypty tworzą projekt `.xpr`, pamięć Block Memory Generator i wrapper, a następnie mogą wygenerować `.bit`. Paczka działa samodzielnie po skopiowaniu całego katalogu; nie wymaga board files ani Pythona na komputerze z Vivado. **Nie zawiera gotowego bitstreamu.**

Zacznij od [dokładnego przewodnika laboratoryjnego](docs/VIVADO_KROK_PO_KROKU.md): podłączenie, każde okno i kliknięcie Vivado, programowanie, UART, testy oraz screeny S01-S22. [Szablon sprawozdania](docs/SPRAWOZDANIE_SZABLON.md) zawiera miejsca na rzeczywiste pomiary. [Architektura](docs/ARCHITEKTURA.md) wyjaśnia kodowanie instrukcji i różnice względem materiałów.

## Najszybsze uruchomienie na stanowisku

1. Wypakuj katalog np. do `C:/lab2/fpga_package`. Sprawdź, że stanowisko ma oryginalną ZYBO, a nie ZYBO Z7.
2. Podłącz USB **PROG/UART** do programowania i osobne USB **Pmod USBUART na JE** do terminala. Włącz zasilanie zgodnie z przewodnikiem.
3. W Vivado otwórz **Window -> Tcl Console**. Wklej po dostosowaniu ścieżki:

   ```tcl
   set PROGRAM base
   set ISA_LAB2 0
   source {C:/lab2/fpga_package/scripts/create_project.tcl}
   source {C:/lab2/fpga_package/scripts/simulate.tcl}
   ```

4. Sprawdź `PASS tb_cpu` w konsoli, zamknij symulację **File -> Close Simulation**, a następnie wpisz:

   ```tcl
   source {C:/lab2/fpga_package/scripts/build_bitstream.tcl}
   ```

5. Sprawdź raporty w `build/base_python/reports/`, w tym timing obu zboczy zegara. **Open Hardware Manager -> Open Target -> Auto Connect -> Program Device -> xc7z010_1**. Wybierz `build/base_python/scs.runs/impl_1/toplevel.bit`, kliknij **Program**.
6. Terminal: **port COM Pmod**, **115200, 8N1, Flow control None**. Ustaw `SW[3:0]=0000`, naciśnij BTN0, potem BTN1. Odczytaj stan i RAM. Każdy BTN2 wykonuje pełną instrukcję; odczekaj sekundę i BTN1 pobierz kolejny zrzut.
7. Po teście `base` utwórz kolejno projekty `load_store`, `mul`, `sub` z profilem 0. Do wymagań rozszerzenia ADD utwórz **`load_store`, `lab2_add_r1`, `lab2_mul` z profilem 1**. Każdy projekt ponownie zbuduj i wgraj. Szczegóły i oczekiwane wyniki są w przewodniku.

Przy ponownym `create_project.tcl` istniejący projekt nie jest nadpisywany. Otwórz jego `.xpr` przez **File -> Project -> Open** i uruchom `build_bitstream.tcl`, albo utwórz inny wariant. Przed zmianą programu/ISA zamknij aktywną symulację. Skrypt tworzenia zamyka poprzedni projekt, więc najpierw zapisz jego edycje.

Z terminala **Vivado 2024.1 Tcl Shell**, w katalogu paczki, można utworzyć i zbudować nowy projekt jednym poleceniem:

```text
vivado -mode batch -source scripts/build_project.tcl -tclargs load_store 0
```

Sam projekt, bez syntezy:

```text
vivado -mode batch -source scripts/create_project.tcl -tclargs lab2_add_r1 1
```

Budowa istniejącego projektu:

```text
vivado -mode batch -source scripts/build_bitstream.tcl -tclargs build/lab2_add_r1_lab2/scs.xpr
```

## Dwa profile: konflikt wymagania lab2 z Pythonem

Instrukcja lab2 §3.6 wymaga wyboru celu ADD bitem 4, więc `20` zapisuje sumę do R0, a `30` do R1. W Waszym `lab1/cpu.py` kod `30` jest już mnożeniem. Dlatego parametr syntezy `ISA_LAB2` jawnie wybiera kodowanie:

| Kod | Profil 0: Python | Profil 1: lab2 |
|---|---|---|
| `20` | ADD -> R0 | ADD -> R0 |
| `30` | MUL -> R1:R0 | ADD -> R1 |
| `40` | SUB -> R0 | SUB -> R0 |
| `50` | niezdefiniowany | MUL -> R1:R0 |

Pozostałe instrukcje pozostają zgodne z Pythonem. LD3 pokazuje skompilowany profil; SW3 go nie zmienia. Parametr i program muszą do siebie pasować. Dla ADD/MUL/SUB dolny półbajt kodu jest ignorowany. Nieznane kody nie zmieniają danych; sprzęt nie wywołuje Pythonowego `undefined_cb`.

## Programy i wartości do porównania

W `programs/` każdy program ma `.coe` do Vivado, `.hex` do symulacji, `.instructions.csv` ze stanem po każdej instrukcji i `.trace.json` po każdym mikrocyklu. Wartości w CSV są szesnastkowe; pełne bajty programu zawiera `manifest.json`.

| PROGRAM | ISA_LAB2 | Co sprawdzić przed skokiem kończącym pętlę |
|---|---:|---|
| `base` | 0 lub 1 | MOV/JMP; R0=2, R1=2, następnie PC=0 |
| `load_store` | 0 lub 1 | M[D]=05, wyzerowanie M[E], 6+5=B, M[E]=0B |
| `undefined` | 0 | `50` pominięte, potem 6+5=B i M[E]=0B |
| `mul` | 0 | 6*7=2A; R1=2, R0=A; M[E]=02, M[F]=0A |
| `sub` | 0 lub 1 | 7-6=1, M[E]=01 |
| `overflow` | 0 lub 1 | F+1=0, R1=1, M[E]=00 |
| `sub_underflow` | 0 lub 1 | 3-5=E modulo16, R1=5, M[E]=0E |
| `lab2_add_r1` | 1 | 6+5 -> R1=B, R0=6, M[E]=0B |
| `lab2_mul` | 1 | mnożenie pod kodem50; wynik jak w `mul` |

Pięć oryginalnych programów zachowuje dokładnie bajty z `lab1/scs.py`. Komentarze tego źródła mają pomyłki: `EF` zapisuje R0 do **F**, `FE` R1 do **E**, a program `sub` liczy **7-6=1**. Oczekiwane wyniki wylicza faktyczny kod. Kopie źródeł Pythona w `reference/` są niezmienionym punktem odniesienia.

`BTN0` resetuje CPU i debugger, ale zachowuje RAM. Ponowne **Program Device** przywraca początkowy obraz COE. Kod i dane współdzielą 16 bajtów; STR może nadpisać instrukcję. Sprzętowy 4-bitowy PC zawija F->0, podczas gdy oryginalny Python nie maskuje PC. Programy w paczce mają skoki przed wyjściem poza pamięć. Pole `R` debuggera nie musi być identyczne z Pythonem: BRAM stale odczytuje adres, a Python zapamiętuje odczyt w wybranych stanach.

## Weryfikacja

Wykonano testy w **Icarus Verilog 12.0**: pełna regresja CPU obu ISA, integracja przycisków/RAM/UART i porównanie z oryginalnym Pythonem. [Raport i log](evidence/TESTY.md) opisują zakres. **Vivado, wygenerowany IP, synteza, implementacja, timing i fizyczna płytka pozostają do sprawdzenia na stanowisku**; funkcjonalny model BRAM nie potwierdza rzeczywistego IP. Skrypty przeglądnięto względem instrukcji i dokumentacji AMD. Szczególnie sprawdź timing półokresowych ścieżek CPU-BRAM (4 ns).

Do odtworzenia testów potrzebne są Python 3.9+ oraz Icarus Verilog (`iverilog`, `vvp`) w PATH:

```text
python3 scripts/run_tests.py
```

Na Windows polecenie Pythona może nazywać się `python`. Można wskazać narzędzia opcjami `--iverilog <ścieżka>` i `--vvp <ścieżka>`. Generowanie plików programów i tabel, bez symulatora HDL:

```text
python3 scripts/prepare_programs.py
```

`prepare_programs.py` parsuje listy z kopii `scs.py` bez uruchamiania terminala POSIX i wykonuje oryginalną klasę Cpu. Dla dwóch nowych kodowań profilu lab2 stosuje jawny adapter opisany w skrypcie. Pięć testów lab1 używa niezmienionego Cpu.

## Zawartość

- `rtl/`: CPU, top, filtr wejść, debugger i nadajnik UART; dodawaj wyłącznie te źródła, bez starych modułów o tych samych nazwach.
- `constraints/zybo.xdc`: piny z dostarczonego XDC, zegar 8ns, wyjątki tylko dla asynchronicznych wejść i wyjść LED/UART.
- `scripts/`: odtwarzanie projektu/BD, budowa, symulacja, programy i testy.
- `sim/`: pełny test CPU, test integracji oraz model RAM **wyłącznie do symulacji poza BD**.
- `programs/`, `reference/`, `docs/`, `evidence/`: programy, źródła porównawcze, przewodnik i wyniki testów.
- `build/`: generowane projekty i raporty, pomijane przez Git i archiwum źródłowe.

Projekt laboratoryjny został rozszerzony o sterowanie zezwoleniami przy jednym zegarze i zatrzaskiwanie zrzutu. Schemat CPU/RAM, ISA i obsługa przycisków pozostają opisane w [architekturze](docs/ARCHITEKTURA.md). Prawa do bazowego SCS i licencja MIT: [LICENSE](LICENSE).
