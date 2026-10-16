# Programy, skrypty i testy

To dokument techniczny. Procedura uruchomienia na **Windows 11** znajduje się w [głównym README](../README.md); projekt otwiera `OTWORZ_VIVADO.cmd`. Poniższe polecenia są opcjonalne i nie są potrzebne do startu dwuklikiem.

## Ręczne uruchamianie skryptów Vivado na Windows

Polecenia poniżej wpisuj w **Wierszu polecenia Windows (`cmd.exe`)**. Dostosuj ścieżkę do instalacji Vivado. W PowerShell składnia wywoływania plików `.bat` jest inna; najprościej użyj opisanego tu `cmd.exe`.

Nowy projekt oraz budowa bitstreamu dla programu 6+5 w profilu lab2:

```bat
cd /d C:\lab2\fpga_package
call "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/build_project.tcl -tclargs load_store 1
```

Tylko utworzenie projektu:

```bat
call "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/create_project.tcl -tclargs lab2_add_r1 1
```

Budowa istniejącego projektu:

```bat
call "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source scripts/build_bitstream.tcl -tclargs build/lab2_add_r1_lab2/scs.xpr
```

Skrypt tworzenia nie nadpisuje istniejącego projektu. Można go otworzyć przez File -> Project -> Open lub skrypt `OTWORZ_VIVADO.cmd`. Zmiany Veriloga, COE albo parametru ISA wymagają ponownej budowy i Program Device. Skrypt budowy regeneruje pamięć, uruchamia syntezę przed implementacją i zapisuje raporty w `build/<program>_<profil>/reports/`.

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

Wykonano testy w **Icarus Verilog 12.0**: pełna regresja CPU obu ISA, integracja przycisków/RAM/UART i porównanie z oryginalnym Pythonem. [Raport i log](../evidence/TESTY.md) opisują zakres. **Vivado, wygenerowany IP, synteza, implementacja, timing i fizyczna płytka pozostają do sprawdzenia na stanowisku**; funkcjonalny model BRAM nie potwierdza rzeczywistego IP. Skrypty przeglądnięto względem instrukcji i dokumentacji AMD. Szczególnie sprawdź timing półokresowych ścieżek CPU-BRAM (4 ns).

Do odtworzenia testów potrzebne są Python 3.9+ oraz Icarus Verilog (`iverilog`, `vvp`) w PATH:

```text
python scripts/run_tests.py
```

Można wskazać narzędzia opcjami `--iverilog <ścieżka>` i `--vvp <ścieżka>`. Generowanie plików programów i tabel, bez symulatora HDL:

```text
python scripts/prepare_programs.py
```

`prepare_programs.py` parsuje listy z kopii `scs.py` bez uruchamiania terminala POSIX i wykonuje oryginalną klasę Cpu. Dla dwóch nowych kodowań profilu lab2 stosuje jawny adapter opisany w skrypcie. Pięć testów lab1 używa niezmienionego Cpu.
