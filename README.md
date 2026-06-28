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

`tb/cpu_tb.sv` loads hex-encoded programs into instruction and data memory using
`$readmemh`, drives clock and reset, and prints the CPU state on every cycle.

```bash
make sim
```

### Simulation Output

The following program tests LOAD, ADD, and STORE in sequence:

```
; Assembly program
LOAD r1, mem[0]     ; r1 = 5
LOAD r2, mem[1]     ; r2 = 3
ADD  r3, r1, r2     ; r3 = 8
STORE r3, mem[2]    ; mem[2] = 8
```

Encoded as hex in `sim/program.hex`:
```
8400
8810
0CA0
AC20
```

Simulation output:
```
PC: 0, Instruction: 8400, ALU result: 0, reg_write_en: 1, rd: 1, reg_write_data: 5
PC: 1, Instruction: 8810, ALU result: 0, reg_write_en: 1, rd: 2, reg_write_data: 3
PC: 2, Instruction: 0ca0, ALU result: 8, reg_write_en: 1, rd: 3, reg_write_data: 8
PC: 3, Instruction: ac20, ALU result: 0, reg_write_en: 0, rd: 3, reg_write_data: 0
--- Program complete ---
Final state: mem[2] = 8 (expected 8)
```

- PC=0: LOAD r1 ← mem[0] = 5 ✓
- PC=1: LOAD r2 ← mem[1] = 3 ✓
- PC=2: ADD  r3 = r1 + r2 = 8 ✓
- PC=3: STORE mem[2] = r3 = 8 ✓

---

## How to Run

### Prerequisites

```bash
sudo apt install iverilog make
```

### Simulate

```bash
git clone https://github.com/Udy1243/simple-cpu
cd simple-cpu
make sim
```

### Synthesize

```bash
make synth
```

---

## Synthesis

Synthesized with Yosys 0.52 targeting generic gate primitives (`synth -top cpu`).

| Metric | Value |
|--------|-------|
| Total cells | 1,758 |
| Flip-flops (`$_DFFE_`, `$_DFF_`) | 582 |
| Multiplexers (`$_MUX_`) | 541 |
| AND/OR/NOT gates | 595 |
| XOR/XNOR gates | 40 |

Netlist written to `syn/cpu_netlist.v`.

> Note: The high flip-flop count (582) is expected — data memory is implemented
> as registers (64 locations × 8 bits = 512 FFs), plus 64 FFs for the 8-register
> file and 6 FFs for the PC. In a real chip, data memory would be SRAM macros, not
> flip-flops, which would reduce the cell count dramatically.

---

## Tools & Technologies

| Category | Tool |
|----------|------|
| HDL | SystemVerilog |
| Simulation | iverilog 12.0 |
| Synthesis | Yosys 0.52 |
| Memory init | `$readmemh` (hex files) |
| Version control | Git |

---

## Project Status

- [x] ISA definition (7 instructions, 16-bit encoding)
- [x] ALU (ADD, SUB, AND, OR + zero flag)
- [x] Register file (8 × 8-bit, combinational reads, synchronous write)
- [x] Memory (instruction ROM + data RAM, single module)
- [x] Single-cycle top-level datapath (`cpu.sv`)
- [x] Testbench (LOAD, ADD, STORE verified with hex programs)
- [x] Synthesis (Yosys — 1,758 cells)
- [ ] Pipeline extension (future)
