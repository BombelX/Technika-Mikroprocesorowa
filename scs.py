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

load_store_program = [\
  0x80, \
  0x90, \
  0x80, \
  0xEE, \
  0x86, \
  0xDD, \
  0x20, \
  0xEE, \
  0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x11, 0x00]


multiplication_program = [\
  0x83, \
  0x94, \
  0x30, \
  0x00, \
  0x00, \
  0x00, \
  0x00, \
  0x00, \
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

error_program = [\
  0x83, \
  0x94, \
  0x70, \
  0x00, \
  0x00, \
  0x00, \
  0x00, \
  0x00, \
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

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

if __name__ == "__main__":
    cpu = Cpu(error_program)

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
