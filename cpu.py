
class Cpu:
  def __init__(self, mem, undefined_cb=None):
    self.mem = mem
    self.undefined_cb = undefined_cb
    self.reset()
    self.__opcode_h = 0
    self.__opcode_l = 0
  
  def reset(self):
    self.state = 0
    self.mem_address = 0
    self.mem_data_r = 0
    self.mem_data_w = 0
    self.pc = 0
    self.r0 = 0
    self.r1 = 0
    self.opcode = 0
    
  
  def next_cycle(self):
    if self.state == 0:
      self.state = 1
      self.mem_address = self.pc
      self.mem_data_r = self.mem[self.mem_address]
    elif self.state == 1:
      self.state = 2
      self.opcode = self.mem_data_r
      self.pc = self.pc + 1
      
    elif self.state == 2:
      self.state = 3
      self.__opcode_h = (self.opcode & 0xF0) >> 4
      self.__opcode_l = self.opcode & 0x0F
      # jmp and data processing (opcode bit 7 is 0)
      if self.__opcode_h == 0x0:
        self.pc = self.__opcode_l
      elif self.__opcode_h == 0x2:
        self.r0 = self.r0 + self.r1
      # multiplication: r1:r0 = r0 * r1 (r1 - upper 4 bits, r0 - lower 4 bits)
      elif self.__opcode_h == 0x3:
        product = self.r0 * self.r1
        self.r0 = product & 0x0F
        self.r1 = (product >> 4) & 0x0F

      # load and store (opcode bit 7 is 1)
      elif self.__opcode_h == 0x8:
        self.r0 = self.__opcode_l
      elif self.__opcode_h == 0x9:
        self.r1 = self.__opcode_l
      elif self.__opcode_h == 0xA:
        self.r0 = self.r1
      elif self.__opcode_h == 0xB:
        self.r1 = self.r0
      elif self.__opcode_h == 0xC:
        self.mem_address = self.__opcode_l
        self.mem_data_r = self.mem[self.mem_address]
      elif self.__opcode_h == 0xD:
        self.mem_address = self.__opcode_l
        self.mem_data_r = self.mem[self.mem_address]
      elif self.__opcode_h == 0xE:
        self.mem_address = self.__opcode_l
        self.mem_data_w = self.r0
      elif self.__opcode_h == 0xF:
        self.mem_address = self.__opcode_l
        self.mem_data_w = self.r1

      # undefined instruction - mem_address still holds its address from state 0
      else:
        if self.undefined_cb is not None:
          self.undefined_cb(self.mem_address)

    elif self.state == 3:
      self.state = 0
      if self.__opcode_h == 0xC:
        self.r0 = self.mem_data_r
      elif self.__opcode_h == 0xD:
        self.r1 = self.mem_data_r
      elif self.__opcode_h == 0xE:
        self.mem[self.mem_address] = self.mem_data_w
      elif self.__opcode_h == 0xF:
        self.mem[self.mem_address] = self.mem_data_w
    else:
      print(f'something went wrong, state should not be >3')
    
    # trim register values because the cpu is 4-bit
    self.r0 = self.r0 & 0xF
    self.r1 = self.r1 & 0xF
    
    self.debug_dump()
    

  def __intlist_to_hex_str(self,intlist):
    return f"{' '.join(f'{n:02X}' for n in intlist)}"

  def debug_dump(self):
    print(f"c={self.state:X} r0={self.r0:X} r1={self.r1:X} \
pc={self.pc:X} A={self.mem_address:X} R={self.mem_data_r:02X} \
W={self.mem_data_w:02X} M: {self.__intlist_to_hex_str(self.mem)}")
    

