# FPGA 4-Bit ALU — SystemVerilog + Vivado

A 4-bit combinational Arithmetic Logic Unit (ALU) implemented in SystemVerilog and verified using AMD/Xilinx Vivado.

The ALU supports four operations:

- Addition
- Subtraction
- Bitwise AND
- Bitwise OR

It also generates four processor-style status flags:

- Carry (`C`)
- Zero (`Z`)
- Negative (`N`)
- Signed Overflow (`V`)

This repository includes the RTL source, SystemVerilog testbench, behavioral simulation results, and Vivado synthesized schematic.

---

## Project Overview

The purpose of this project is to practice the full FPGA design flow for a small combinational datapath:

1. Define the ALU behavior and status flags.
2. Implement the design in SystemVerilog.
3. Create directed testbench stimulus.
4. Verify operation using behavioral simulation.
5. Synthesize the RTL in Vivado.
6. Inspect how Vivado maps the design into FPGA resources.

The design is purely combinational and contains no clocked storage.

---

## ALU Interface

### Inputs

| Signal | Width | Description |
|---|---:|---|
| `A` | 4 bits | Operand A |
| `B` | 4 bits | Operand B |
| `SEL` | 2 bits | Operation select |

### Outputs

| Signal | Width | Description |
|---|---:|---|
| `Y` | 4 bits | ALU result |
| `C` | 1 bit | Carry / no-borrow flag |
| `Z` | 1 bit | Zero flag |
| `N` | 1 bit | Negative flag |
| `V` | 1 bit | Signed overflow flag |

---

## Operation Select

| `SEL` | Operation | Function |
|---|---|---|
| `00` | ADD | `A + B` |
| `01` | SUB | `A - B` |
| `10` | AND | `A & B` |
| `11` | OR | `A \| B` |

`SEL` acts as the ALU control input and determines which operation drives the output.

---

## Status Flags

### Carry — `C`

For addition, `C` is the carry out of the 4-bit arithmetic result.

For subtraction, the ALU uses two's-complement arithmetic:

```text
A - B = A + (~B) + 1
```

With this implementation:

```text
C = 1  ->  no unsigned borrow
C = 0  ->  unsigned borrow occurred
```

For AND and OR operations, `C` is defined as `0`.

### Zero — `Z`

The zero flag is asserted whenever the selected result equals zero:

```systemverilog
Z = (Y == 4'b0000);
```

### Negative — `N`

The negative flag is the most-significant bit of the 4-bit result:

```systemverilog
N = Y[3];
```

For a 4-bit two's-complement value, bit 3 is the sign bit.

### Signed Overflow — `V`

Signed overflow is different from carry-out.

For addition:

```systemverilog
V = ~(A[3] ^ B[3]) & (Y[3] ^ A[3]);
```

Overflow occurs when the operands have the same sign and the result has the opposite sign.

For subtraction:

```systemverilog
V = (A[3] ^ B[3]) & (Y[3] ^ A[3]);
```

Overflow occurs when `A` and `B` have different signs and the result sign differs from the sign of `A`.

For AND and OR operations, `V` is defined as `0`.

---

## RTL Implementation

The ALU is implemented using `always_comb` and blocking assignments because the design is purely combinational.

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
        // Safe defaults for combinational logic
        Y = 4'b0000;
        C = 1'b0;
        V = 1'b0;

        case (SEL)

            // ADD
            2'b00: begin
                {C, Y} = {1'b0, A} + {1'b0, B};
                V = ~(A[3] ^ B[3]) & (Y[3] ^ A[3]);
            end

            // SUB
            2'b01: begin
                {C, Y} = {1'b0, A}
                       + {1'b0, ~B}
                       + 5'b00001;

                V = (A[3] ^ B[3]) & (Y[3] ^ A[3]);
            end

            // AND
            2'b10: begin
                Y = A & B;
            end

            // OR
            2'b11: begin
                Y = A | B;
            end

        endcase

        Z = (Y == 4'b0000);
        N = Y[3];
    end

endmodule
```

The default assignments at the beginning of the `always_comb` block ensure that the combinational outputs receive defined values on every execution path and prevent unintended latch inference.

---

## Arithmetic Width

Adding two 4-bit operands can require a 5-bit result.

For example:

```text
1101 + 0101 = 1_0010
```

If only a 4-bit destination were used, the upper carry bit would be lost.

The operands are therefore explicitly extended:

```systemverilog
{C, Y} = {1'b0, A} + {1'b0, B};
```

This preserves both the lower four result bits (`Y`) and the fifth carry bit (`C`).

---

## Subtraction Architecture

A separate subtractor is not required.

Subtraction is implemented using the identity:

```text
A - B = A + (~B) + 1
```

The RTL uses:

```systemverilog
{C, Y} = {1'b0, A}
       + {1'b0, ~B}
       + 5'b00001;
```

This is the two's-complement form of subtraction and allows addition and subtraction to use closely related arithmetic logic.

---

## Verification

The testbench drives only the DUT inputs:

```text
A
B
SEL
```

and observes the DUT outputs:

```text
Y
C
Z
N
V
```

The design was checked using 12 directed behavioral-simulation cases covering normal operation and important corner cases.

### ADD Test Cases

| A | B | Y | C | Z | N | V | Purpose |
|---|---|---|---|---|---|---|---|
| `0100` | `0010` | `0110` | 0 | 0 | 0 | 0 | Normal addition |
| `1101` | `1011` | `1000` | 1 | 0 | 1 | 0 | Carry without signed overflow |
| `0101` | `0100` | `1001` | 0 | 0 | 1 | 1 | Signed overflow |
| `0000` | `0000` | `0000` | 0 | 1 | 0 | 0 | Zero result |

### SUB Test Cases

| A | B | Y | C | Z | N | V | Purpose |
|---|---|---|---|---|---|---|---|
| `0111` | `0010` | `0101` | 1 | 0 | 0 | 0 | Positive result |
| `0010` | `0101` | `1101` | 0 | 0 | 1 | 0 | Negative result / borrow |
| `1000` | `0001` | `0111` | 1 | 0 | 0 | 1 | Signed overflow |
| `0010` | `0111` | `1011` | 0 | 0 | 1 | 0 | Negative result |
| `0101` | `0101` | `0000` | 1 | 1 | 0 | 0 | Zero result |

### Logical Test Cases

| Operation | A | B | Y | C | Z | N | V |
|---|---|---|---|---|---|---|---|
| AND | `1000` | `1000` | `1000` | 0 | 0 | 1 | 0 |
| AND | `0000` | `0000` | `0000` | 0 | 1 | 0 | 0 |
| OR | `1000` | `0100` | `1100` | 0 | 0 | 1 | 0 |

All 12 directed test cases matched the expected behavior.

---

## Behavioral Simulation

Vivado/XSim was used to verify the RTL before synthesis.

The waveform shows `A`, `B`, `SEL`, `Y`, `C`, `Z`, `N`, and `V` across the directed test vectors.

![ALU Behavioral Simulation](simulation/alu4_waveform.png)

One important overflow case is:

```text
A   = 0101  (+5)
B   = 0100  (+4)
SEL = 00    (ADD)

Y = 1001
C = 0
Z = 0
N = 1
V = 1
```

The mathematical result is `+9`, but the signed 4-bit range is only `-8` to `+7`. Because `+9` cannot be represented, the 4-bit result wraps to `1001` and the signed-overflow flag is asserted.

---

## Vivado Synthesis

The RTL was synthesized in Vivado and the synthesized schematic was inspected.

![Vivado Synthesized Schematic](synthesis/alu4_schematic.png)

The synthesized design contains primarily:

- Input buffers (`IBUF`)
- Lookup tables (`LUT3`, `LUT4`, `LUT6`)
- Output buffers (`OBUF`)

No flip-flops or latch storage elements were observed in the synthesized schematic, which is consistent with the intended combinational design.

Vivado optimized the behavioral RTL into FPGA logic rather than preserving separate textbook blocks for ADD, SUB, AND, OR, and a final multiplexer.

---

## Example Synthesis Optimization

The RTL contains:

```systemverilog
N = Y[3];
```

Vivado recognizes that `N` is exactly the same signal as the most-significant bit of `Y`.

Conceptually:

```text
result bit 3 ----+----> Y[3]
                 |
                 +----> N
```

A separate negative-flag circuit is therefore unnecessary.

This is an example of synthesis recognizing equivalent logic and sharing the same internal signal.

---

## RTL vs. Synthesized Hardware

Conceptually, the RTL looks like multiple operations feeding a selection structure:

```text
          +-------+
A, B ---->|  ADD  |---+
          +-------+   |
                      |
          +-------+   |
A, B ---->|  SUB  |---|
          +-------+   |
                      +----> selection ----> Y
          +-------+   |
A, B ---->|  AND  |---|
          +-------+   |
                      |
          +-------+   |
A, B ---->|  OR   |---+
          +-------+

SEL controls the selected operation.
```

The synthesized FPGA implementation is closer to:

```text
A -----+
       |
B -----+----> Optimized LUT Network ----> Y
       |                                  C
SEL ---+                                  Z
                                          N
                                          V
```

The important engineering lesson is:

> RTL describes the required hardware behavior. Synthesis determines an optimized implementation using the resources available in the target FPGA.

---

## Repository Structure

```text
fpga-4bit-alu-vivado/
|
|-- README.md
|
|-- rtl/
|   `-- alu4.sv
|
|-- tb/
|   `-- alu4_tb.sv
|
|-- simulation/
|   `-- alu4_waveform.png
|
`-- synthesis/
    `-- alu4_schematic.png
```

---

## Tools

- SystemVerilog
- AMD/Xilinx Vivado
- Vivado Simulator / XSim
- Vivado Synthesis

---

## Concepts Learned

This project reinforced several FPGA and digital-design concepts:

- Multi-bit combinational RTL design
- Arithmetic result-width management
- Carry-out versus signed overflow
- Two's-complement subtraction
- ALU control and datapath organization
- Processor-style status flags
- Complete combinational assignments
- Avoiding unintended latch inference
- Directed testbench development
- Waveform-based functional verification
- RTL-to-LUT synthesis
- FPGA synthesis optimization
- Difference between behavioral RTL and synthesized FPGA hardware

---

## Project Status

- [x] RTL design
- [x] Directed testbench
- [x] Behavioral simulation
- [x] Status flag verification
- [x] Vivado synthesis
- [x] Synthesized schematic inspection

