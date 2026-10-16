# Weryfikacja paczki

Data: **16.10.2026**. Środowisko: macOS ARM64, Python 3.12, **Icarus Verilog 12.0**. Kompilator tymczasowo zbudowano z oficjalnego wydania źródłowego; nie jest częścią paczki. Kompilacja obu testbenchów z `-g2012 -Wall` nie wypisała ostrzeżeń.

## Wykonane testy

1. **`tb_cpu` - PASS.** Wszystkie 256 kodów instrukcji, 16 wartości R0 i 16 wartości R1: **65536 przypadków na profil, dwa profile ISA**, łącznie 1572931 cykli zegara testowego. Sprawdza stany i dane po mikrocyklach, odczyt/zapis całej RAM, ignorowane bity rozkazów, niezdefiniowane instrukcje, przepełnienie ADD, zawijanie SUB, pełny iloczyn MUL, zawijanie PC, pauzy CPU i reset.
2. **`tb_toplevel` - PASS.** Rzeczywiste moduły top/CPU/sterowanie/debugger/UART, tylko BRAM zastąpiono modelem synchronicznym Write First. Program §3.5 liczy 6+5=B i zapisuje 0B do M[E]. Test weryfikuje cztery/jeden krok, drgania i przytrzymanie przycisku, rzeczywiście dekoduje UART przy ręcznym i automatycznym wyzwalaniu, sprawdza zrzut po kroku, reset bez wyczyszczenia RAM oraz okres automatycznych kroków. Stałe czasowe skrócono w instancji testowej.
3. **`verify_python.py` - PASS.** Rzeczywista klasa Cpu z niezmienionej kopii `lab1/cpu.py` oraz listy bajtów z kopii `lab1/scs.py`. **9 programów, 3 obiegi, 696 mikrocykli**. Porównano po każdym kroku: stan, R0/R1, PC, adres, dane zapisu i wszystkie 16 bajtów RAM. Dla `lab2_add_r1`/`lab2_mul` użyto jawnego adaptera nowych kodowań; pięć programów lab1 używa niezmienionej semantyki. Pole R pominięto ze względu na opisane różnice zatrzaskiwania odczytu w Pythonie i ciągłego odczytu BRAM.
4. **Kontrole plików.** Kopie `reference/cpu.py` i `reference/scs.py` są identyczne bajtowo ze źródłami w `lab1/`. Programy mają dokładnie 16 bajtów i poprawną składnię COE. Skrypty Tcl przeszły kontrolę kompletności składni w `tclsh`; nie zastępuje ona wykonania poleceń Vivado.

Surowy wynik uruchomienia wszystkich testów: [test_results.txt](test_results.txt). Sumy kontrolne źródeł: [source_sha256.txt](source_sha256.txt).

## Jak powtórzyć

W katalogu paczki, z Pythonem 3.9+ i narzędziami Icarus w PATH:

```text
python3 scripts/run_tests.py
```

Testy używają tymczasowych katalogów i nie modyfikują źródeł. W Vivado `scripts/simulate.tcl` uruchamia sam test CPU obu profili. Nie dodawaj `sim/mem_wrapper_model.v` razem z wygenerowanym `mem_wrapper`.

## Weryfikacja pozostająca na laboratorium

**Nie uruchomiono Vivado ani fizycznej ZYBO.** Nie wygenerowano rzeczywistego IP, wyników syntezy/implementacji, bitstreamu ani raportów timingu. W szczególności model RAM nie dowodzi poprawności wygenerowanej konfiguracji BMG i routingu. Sprawdzić:

- Vivado 2024.1: odtworzenie projektu, BMG Stand Alone / True Dual Port 8x16 / Always Enabled / Write First bez dodatkowych rejestrów, wrapper i hierarchię.
- Symulację w XSim, syntezę, implementację, DRC, wykorzystanie zasobów i pełne ograniczenia czasowe. CPU-BRAM ma półokresowe ścieżki 4 ns, które muszą spełnić setup/hold. Nie maskować ich wyjątkami.
- Wgranie na właściwą płytkę i PMOD, faktyczny UART 115200/8N1, ręczne/automatyczne kroki i logi obliczeń dla obu profili.

Skrypty BMG przejrzano według [AMD PG058 v8.4](https://docs.amd.com/api/khub/documents/V70n09duEdKgzrX2d1W97g/content), a kolejność syntezy/implementacji według [UG835 Vivado 2024.1](https://docs.amd.com/r/2024.1-English/ug835-vivado-tcl-commands/launch_runs). Szczegółowa procedura sprzętowa i dowody do zebrania: [przewodnik](../docs/VIVADO_KROK_PO_KROKU.md).

## Obsługa Windows 11

`OTWORZ_VIVADO.cmd` wybiera program, wykrywa Vivado i tworzy lub otwiera projekt. `OTWORZ_PUTTY.cmd` wyświetla listę COM i uruchamia wybrany port z parametrami 115200/8N1/None. Główny przewodnik to [README.md](../README.md); szczegóły techniczne są w `docs/`. Instrukcje są wyłącznie w Markdown.

`windows_project.tcl` sprawdzono w atrapie poleceń Vivado: tworzenie, ponowne otwarcie, ścieżki ze spacjami, odrzucanie niewłaściwych argumentów. Wszystkie sześć konfiguracji menu przechodzi tę kontrolę; atrapa nie generuje prawdziwego `.xpr`. Skrypty `.cmd` zapisano jako ASCII z końcami linii CRLF. Sprawdzono odwołania po zmianie nazw skryptów, kompletność Tcl oraz zawartość odświeżonego ZIP. **Nie wykonano skryptów w Windows/cmd.exe ani nie uruchomiono PuTTY/Vivado**. Wyniki funkcjonalnych testów CPU pozostają aktualne; nie zmieniono RTL ani programów.
