def set(inst, msb, lsb, value):
    """
    Set the value of a specific field in an instruction.

    Args:
        inst (int): The instruction to modify.
        msb (int): The most significant bit of the field.
        lsb (int): The least significant bit of the field.
        value (int): The value to set the field to.

    Returns:
        int: The modified instruction.
    """
    mask = ((1 << (msb - lsb + 1)) - 1) << lsb
    inst &= ~mask
    inst |= (value & ((1 << (msb - lsb + 1)) - 1)) << lsb
    return inst

def get(inst, msb, lsb):
    """
    Get the value of a specific field in an instruction.

    Args:
        inst (int): The instruction to read from.
        msb (int): The most significant bit of the field.
        lsb (int): The least significant bit of the field.

    Returns:
        int: The value of the field.
    """
    mask = ((1 << (msb - lsb + 1)) - 1) << lsb
    return (inst & mask) >> lsb

def set_addr_config(rs1, rs2, rs3, idx):
  inst = 0
  inst = set(inst, 31, 27, rs3)
  inst = set(inst, 24, 20, rs2)
  inst = set(inst, 19, 15, rs1)
  inst = set(inst, 8, 7, idx)
  inst = set(inst, 6, 0, 0b0001011)
  inst = f"0x{inst:08x}"
  return inst

if __name__ == "__main__":
  print(set_addr_config(28, 29, 30, 0))
  print(set_addr_config(28, 29, 30, 1))
  print(set_addr_config(28, 29, 30, 2))
