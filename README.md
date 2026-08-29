# FPGA 4-Bit ALU — SystemVerilog + Vivado + Basys 3

A 4-bit combinational Arithmetic Logic Unit (ALU) implemented in SystemVerilog, verified in AMD/Xilinx Vivado, and deployed to a Digilent Basys 3 FPGA board.

The ALU supports addition, subtraction, bitwise AND, and bitwise OR, with four processor-style status flags: carry/no-borrow (`C`), zero (`Z`), negative (`N`), and signed overflow (`V`).

This repository documents the complete flow from RTL design through simulation, synthesis, implementation, bitstream generation, and physical FPGA verification.

---

## Project Status

- [x] RTL design
- [x] Directed SystemVerilog testbench
- [x] Behavioral simulation
- [x] Status flag verification
- [x] Vivado synthesis
- [x] Synthesized schematic inspection
- [x] Basys 3 top-level wrapper
- [x] XDC pin constraints
- [x] Vivado implementation
- [x] Design Rule Check (DRC)
- [x] Bitstream generation
- [x] Basys 3 programming
- [x] Physical hardware verification
- [ ] Timing analysis
- [ ] Self-checking / exhaustive verification

---

## Target Hardware

- **Board:** Digilent Basys 3
- **FPGA:** AMD/Xilinx Artix-7
- **Vivado part:** `xc7a35tcpg236-1`

The Basys 3 slide switches provide the ALU inputs and the LEDs display the result and status flags.

---

## ALU Interface

| Signal | Width | Direction | Description |
|---|---:|---|---|
| `A` | 4 bits | Input | Operand A |
| `B` | 4 bits | Input | Operand B |
| `SEL` | 2 bits | Input | Operation select |
| `Y` | 4 bits | Output | ALU result |
| `C` | 1 bit | Output | Carry / no-borrow flag |
| `Z` | 1 bit | Output | Zero flag |
| `N` | 1 bit | Output | Negative flag |
| `V` | 1 bit | Output | Signed overflow flag |

---

## Operation Select

| `SEL` | Operation | Function |
|---|---|---|
| `00` | ADD | `A + B` |
| `01` | SUB | `A - B` |
| `10` | AND | `A & B` |
| `11` | OR | `A \| B` |

---

## Status Flags

### Carry / No-Borrow — `C`

For addition, `C` is the carry out of the 4-bit arithmetic result.

For subtraction:

```text
A - B = A + (~B) + 1
```

With this implementation:

```text
C = 1  -> no unsigned borrow
C = 0  -> unsigned borrow occurred
```

For AND and OR, `C` is defined as `0`.

### Zero — `Z`

```systemverilog
Z = (Y == 4'b0000);
```

### Negative — `N`

```systemverilog
N = Y[3];
```

### Signed Overflow — `V`

Addition:

```systemverilog
V = ~(A[3] ^ B[3]) & (Y[3] ^ A[3]);
```

Subtraction:

```systemverilog
V = (A[3] ^ B[3]) & (Y[3] ^ A[3]);
```

For AND and OR, `V` is defined as `0`.

---

## RTL Core

The ALU core is independent of the FPGA board so that it can be reused and verified separately.

```systemverilog
module alu4(
    input  logic [3:0] A,
    input  logic [3:0] B,
    input  logic [1:0] SEL,

    output logic [3:0] Y,
    output logic       C,
    output logic       Z,
    output logic       N,
    output logic       V
);

    always_comb begin
        Y = 4'b0000;
        C = 1'b0;
        V = 1'b0;

        case (SEL)
            2'b00: begin
                {C, Y} = {1'b0, A} + {1'b0, B};
                V = ~(A[3] ^ B[3]) & (Y[3] ^ A[3]);
            end

            2'b01: begin
                {C, Y} = {1'b0, A}
                       + {1'b0, ~B}
                       + 5'b00001;

                V = (A[3] ^ B[3]) & (Y[3] ^ A[3]);
            end

            2'b10: begin
                Y = A & B;
            end

            2'b11: begin
                Y = A | B;
            end
        endcase

        Z = (Y == 4'b0000);
        N = Y[3];
    end

endmodule
```

Default assignments are made before the `case` statement so that every combinational output has a defined value on every execution path and no unintended storage is required.

---

## Basys 3 Top-Level Wrapper

`alu4_top.sv` connects the Basys 3 board-level ports to the reusable ALU core:

```systemverilog
module alu4_top(
    input  logic [9:0] sw,
    output logic [7:0] led
);

    alu4 DUT (
        .A   (sw[3:0]),
        .B   (sw[7:4]),
        .SEL (sw[9:8]),

        .Y   (led[3:0]),
        .C   (led[4]),
        .Z   (led[5]),
        .N   (led[6]),
        .V   (led[7])
    );

endmodule
```

This separates reusable design logic from board-specific integration and makes debugging easier.

---

## Basys 3 Mapping

### Inputs

| Basys 3 switches | ALU signal |
|---|---|
| `SW3:0` | `A[3:0]` |
| `SW7:4` | `B[3:0]` |
| `SW9:8` | `SEL[1:0]` |

### Outputs

| ALU signal | Basys 3 LEDs |
|---|---|
| `Y[3:0]` | `LD3:0` |
| `C` | `LD4` |
| `Z` | `LD5` |
| `N` | `LD6` |
| `V` | `LD7` |

---

## XDC Constraints

The XDC connects the logical `sw[]` and `led[]` ports to physical Basys 3 package pins and specifies the `LVCMOS33` I/O standard.

Example:

```tcl
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
```

The complete constraint file is located at:

```text
constraints/alu4_basys3.xdc
```

---

## Behavioral Verification

The SystemVerilog testbench applies 12 directed cases covering normal arithmetic, carry, borrow/no-borrow, zero, signed overflow, AND, and OR.

![ALU Behavioral Simulation](simulation/alu4_waveform.png)

All 12 directed simulation cases matched the expected outputs.

---

## Vivado Synthesis

The design was synthesized in Vivado.

![Vivado Synthesized Schematic](synthesis/alu4_schematic.png)

The synthesized design primarily used FPGA LUT resources and I/O buffers. No unintended latch or flip-flop storage was observed for the combinational ALU.

Vivado also optimized equivalent logic. For example:

```systemverilog
N = Y[3];
```

allows the same synthesized signal to drive both `Y[3]` and `N`.

---

## FPGA Implementation Flow

The complete hardware flow was completed successfully:

```text
SystemVerilog RTL
      |
      v
Behavioral Simulation
      |
      v
Synthesis
      |
      v
Implementation
      |
      v
Design Rule Check
      |
      v
Bitstream Generation
      |
      v
Program Basys 3
      |
      v
Physical Hardware Verification
```

The DRC completed with no violations before bitstream generation.

---

## Physical Basys 3 Verification

Eight representative hardware cases were tested with the slide switches and LEDs.

| Test | A | B | SEL | Expected result / flags | Hardware |
|---|---|---|---|---|---|
| Normal ADD | `0100` | `0010` | `00` | `Y=0110 C=0 Z=0 N=0 V=0` | PASS |
| ADD carry | `1101` | `1011` | `00` | `Y=1000 C=1 Z=0 N=1 V=0` | PASS |
| ADD overflow | `0101` | `0100` | `00` | `Y=1001 C=0 Z=0 N=1 V=1` | PASS |
| SUB negative | `0010` | `0101` | `01` | `Y=1101 C=0 Z=0 N=1 V=0` | PASS |
| SUB overflow | `1000` | `0001` | `01` | `Y=0111 C=1 Z=0 N=0 V=1` | PASS |
| SUB zero | `0101` | `0101` | `01` | `Y=0000 C=1 Z=1 N=0 V=0` | PASS |
| AND | `1000` | `1000` | `10` | `Y=1000 C=0 Z=0 N=1 V=0` | PASS |
| OR | `1000` | `0100` | `11` | `Y=1100 C=0 Z=0 N=1 V=0` | PASS |

The physical FPGA behavior matched the expected RTL behavior in all eight hardware tests.

---

## Repository Structure

```text
fpga-4bit-alu-vivado/
|
|-- README.md
|-- .gitignore
|
|-- rtl/
|   |-- alu4.sv
|   `-- alu4_top.sv
|
|-- tb/
|   `-- alu4_tb.sv
|
|-- constraints/
|   `-- alu4_basys3.xdc
|
|-- simulation/
|   `-- alu4_waveform.png
|
|-- synthesis/
|   `-- alu4_schematic.png
|
`-- hardware/
    `-- basys3_alu_test.jpg   # optional
```

---

## Tools

- SystemVerilog
- AMD/Xilinx Vivado
- Vivado Simulator / XSim
- Vivado Synthesis and Implementation
- Digilent Basys 3 FPGA board

---

## Engineering Lessons

This project reinforced:

- Multi-bit combinational RTL design
- Arithmetic width management
- Carry versus signed overflow
- Two's-complement subtraction
- ALU control and status flags
- Complete combinational assignments
- Latch avoidance
- Directed verification and waveform analysis
- RTL-to-LUT synthesis
- Hierarchical RTL design
- Reusable core vs. board-specific wrapper
- XDC physical pin constraints
- FPGA implementation and bitstream generation
- Hardware-level debugging
- Separation of logical behavior from physical pin mapping

---

## Future Improvements

- Create a self-checking testbench
- Exhaustively verify all `1024` combinations of `A`, `B`, and `SEL`
- Add SystemVerilog assertions
- Parameterize operand width
- Add XOR and additional ALU operations
- Run and document timing analysis
- Add seven-segment display output
- Explore a registered or pipelined ALU
