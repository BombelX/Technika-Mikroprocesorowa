import sys
import termios
import fcntl
import os
from cpu import Cpu

def init_nonblocking_input():
    fd = sys.stdin.fileno()

    # Save original terminal settings
    original_termios = termios.tcgetattr(fd)
    new_termios = termios.tcgetattr(fd)

    # Turn off canonical mode and echo
    new_termios[3] &= ~(termios.ICANON | termios.ECHO)
    termios.tcsetattr(fd, termios.TCSANOW, new_termios)

    # Set stdin to non-blocking
    flags = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

    return original_termios

def restore_input(original_termios):
    fd = sys.stdin.fileno()
    termios.tcsetattr(fd, termios.TCSANOW, original_termios)

def read_key():
    try:
        return sys.stdin.read(1)
    except IOError:
        return None
        

base_program = [\
  0x80, \
  0x90, \
  0x81, \
  0x92, \
  0xA0, \
  0x00, \
  0x00, \
  0x00, \
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

load_store_program = [
  0x80,  
  0x90,  
  0xEE,  
  0x86,  
  0xDD,  
  0x20,  
  0xEE,  
  0x00,  
  0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00]


    # mov R0, #0
    # mov R1, #0
    # mov R0, #0
    # str R0, 14
    # mov R0, #6
    # ldr R1, 13
    # add R0, R1
    # str R0, 14
    # jmp 0

    # 10 A # 11 B # 12 C # 13 D # 14 E # 15 F



# load_store_program with an instruction the cpu does not know
undefined_program = [
  0x80,  # 00: mov r0, #0
  0x90,  # 01: mov r1, #0
  0xEE,  # 02: str r0, [14]
  0x86,  # 03: mov r0, #6
  0x50,  # 04: undefined (0x30 is mul now)
  0xDD,  # 05: ldr r1, [13]
  0x20,  # 06: add r0, r1
  0xEE,  # 07: str r0, [14]
  0x00,  # 08: jmp #0
  0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00]

# 0x30 demo: r1:r0 = r0 * r1, 6 * 7 = 42 = 0x2A
mul_program = [
  0xCC,  # 00: ldr r0, [12]
  0xDD,  # 01: ldr r1, [13]
  0x30,  # 02: mul r0, r1    - r1 = 0x2, r0 = 0xA
  0xEE,  # 03: str r0, [14]  - lower part
  0xFF,  # 04: str r1, [15]  - upper part
  0x00,  # 05: jmp #0
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x07, 0x00, 0x00]

programs = {
    'base': base_program,
    'load_store': load_store_program,
    'undefined': undefined_program,
    'mul': mul_program,
}

def undefined(address):
    print(f'Undefined instruction at address 0x{address:02X}')

if __name__ == "__main__":
    # python3 scs.py [base|load_store|undefined|mul]
    name = sys.argv[1] if len(sys.argv) > 1 else 'load_store'
    cpu = Cpu(programs[name], undefined)

    print("Press any key ('q' to quit, space for clock, d for debug dump)...")

    original_settings = init_nonblocking_input()
    try:
        while True:
            key = read_key()
            if key:
                # print(f"Key pressed: {repr(key)}") # uncomment to see what's pressed
                if key == 'q':
                    break
                if key == 'd':
                    cpu.debug_dump()
                if key == ' ':
                    cpu.next_cycle()
    finally:
        restore_input(original_settings)
        print("\nExit.")
