# Single-Cycle CPU

A fully custom processor implemented in SystemVerilog — from ISA definition through RTL design, simulation, and testbench verification using iverilog. The CPU executes a hand-crafted 7-instruction ISA with dedicated ALU, register file, and hardware branch resolution, all within a single-cycle datapath.

---

## Overview

This project walks the full hardware design loop: define an ISA, implement the microarchitecture in RTL, write a testbench, and verify correctness using simulation. The design is intentionally minimal to keep every datapath signal traceable and the control logic auditable.

**Key features:**
- Custom 7-instruction ISA: `ADD`, `SUB`, `AND`, `OR`, `LOAD`, `STORE`, `BEQ`
- Single-cycle datapath — every instruction completes in one clock cycle
- 8 general-purpose 8-bit registers; 64-entry instruction and data memory
- Testbench loads programs via `$readmemh` (hex-encoded instruction and data memory)
- Verified across arithmetic, memory access, and branch instruction sequences

---

## ISA Reference

16-bit instructions, 8 registers (3-bit address), 8-bit data.

| Opcode | Instruction | Type | Operation |
|--------|-------------|------|-----------|
| `000` | `ADD Rd, Rs1, Rs2` | R-type | `Rd = Rs1 + Rs2` |
| `001` | `SUB Rd, Rs1, Rs2` | R-type | `Rd = Rs1 - Rs2` |
| `010` | `AND Rd, Rs1, Rs2` | R-type | `Rd = Rs1 & Rs2` |
| `011` | `OR  Rd, Rs1, Rs2` | R-type | `Rd = Rs1 \| Rs2` |
| `100` | `LOAD  Rd, imm`    | I-type | `Rd = MEM[imm]` |
| `101` | `STORE Rs, imm`    | I-type | `MEM[imm] = Rs` |
| `110` | `BEQ Rs1, Rs2, imm` | I-type | `if (Rs1 == Rs2) PC = PC + imm` |

**Instruction encoding:**

```
R-type: [15:13] opcode | [12:10] Rd | [9:7] Rs1 | [6:4] Rs2 | [3:0] unused
I-type: [15:13] opcode | [12:10] Rd/Rs | [9:4] imm | [3:1] Rs2 | [0] unused
```

---

## Architecture

### Datapath

```
         ┌──────────┐    ┌───────────────────┐
  PC ───►│  Instr   │───►│  Decode (cpu.sv)  │
         │  Memory  │    │  op, rd, rs1, rs2 │
         └──────────┘    └─────────┬─────────┘
                                   │
              ┌────────────────────▼────────────────────┐
              │            Register File                 │
              │   8 × 8-bit regs, 2 read / 1 write port │
              └──────────┬──────────────────────────────┘
                         │ operand_a, operand_b
                    ┌────▼────┐
                    │   ALU   │  ADD / SUB / AND / OR
                    │         │  + zero_flag
                    └────┬────┘
                         │ alu_result / reg_write_data
              ┌──────────▼──────────┐
              │     Data Memory     │  LOAD reads / STORE writes
              │   64 × 8-bit SRAM   │
              └─────────────────────┘
```

### Modules

| Module | File | Description |
|--------|------|-------------|
| Top-level CPU | `rtl/cpu.sv` | Wires all datapath components; decode and control logic inline |
| ALU | `rtl/alu.sv` | Executes ADD, SUB, AND, OR; outputs `zero_flag` |
| Register file | `rtl/register_file.sv` | 8 × 8-bit registers, combinational reads, sequential write |
| Memory | `rtl/memory.sv` | Instruction memory (read-only, 16-bit) + data memory (read/write, 8-bit) |
| Testbench | `tb/cpu_tb.sv` | Loads hex programs, drives clock/reset, prints per-cycle state |

---

## Verification

### Testbench

`tb/cpu_tb.sv` loads hex-encoded programs into instruction and data memory using `$readmemh`, drives clock and reset, and prints the CPU state on every cycle.

```bash
iverilog -g2012 -o sim/cpu_tb \
  tb/cpu_tb.sv \
  rtl/cpu.sv \
  rtl/alu.sv \
  rtl/register_file.sv \
  rtl/memory.sv

vvp sim/cpu_tb
```

### Test Programs

| Test | Instructions exercised | Expected outcome |
|------|------------------------|-----------------|
| Arithmetic + memory | `LOAD`, `ADD`, `STORE` | `mem[2] = mem[0] + mem[1]` |
| Branch taken | `BEQ` (equal operands) | PC jumps by immediate offset |
| Branch not taken | `BEQ` (unequal operands) | PC increments normally |

Programs are written as raw hex files (`sim/program.hex`, `sim/data.hex`), one word per line.

---

## How to Run

### Prerequisites

```bash
sudo apt install iverilog
```

### Simulate

```bash
git clone https://github.com/Udy1243/simple-cpu
cd simple-cpu
iverilog -g2012 -o sim/cpu_tb tb/cpu_tb.sv rtl/*.sv
vvp sim/cpu_tb
```

---

## Tools & Technologies

| Category | Tool |
|----------|------|
| HDL | SystemVerilog |
| Simulation | iverilog |
| Memory init | `$readmemh` (hex files) |
| Version control | Git |

---

## Project Status

- [x] ISA definition
- [x] ALU (ADD, SUB, AND, OR + zero flag)
- [x] Register file (8 × 8-bit, async active-low reset)
- [x] Memory (instruction ROM + data RAM, single module)
- [x] Single-cycle top-level datapath (`cpu.sv`)
- [x] Testbench (arithmetic, memory, branch tests)
- [ ] Synthesis (Yosys)
- [ ] Pipeline extension (future)
