# fpge-4bit-alu-vivado
4-bit combinational ALU implemented in SystemVerilog and verified in Vivado. Supports ADD, SUB, AND, and OR operations with carry, zero, negative, and signed-overflow flags. Includes RTL source, testbench, simulation waveforms, and synthesized schematic.

# Repository Structure

fpga-4bit-alu-vivado/
README.md
rtl
│   └── alu4.sv
│
├── tb/
│   └── alu4_tb.sv
│
├── simulation/
│   └── alu4_waveform.png
│
└── synthesis/
    └── alu4_schematic.png


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

The project includes the RTL source, SystemVerilog testbench, behavioral simulation results, and Vivado synthesized schematic.

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

The `SEL` input acts as the ALU control signal and determines which operation drives the result.

---

## Status Flags

### Carry — `C`

For addition, `C` represents the carry out of the 4-bit arithmetic operation.

For subtraction implemented using two's complement:

```text
A - B = A + (~B) + 1
```

the final carry is interpreted as:

```text
C = 1 → no unsigned borrow
C = 0 → unsigned borrow occurred
```
For AND and OR operations, C is defined as 0. 

### Zero - 'Z'

The zero flag is asserted whenever the ALU result is zero:

```text
Z = (Y == 4'b0000);
```
### Negative — N

The negative flag is the most-significant bit of the result:

```text
N = Y[3];
```

For a 4-bit two's-complement value, bit 3 is the sign bit.

### Signed Overflow — V

Signed overflow is different from carry.

For addition:

```test
V = ~(A[3] ^ B[3]) & (Y[3] ^ A[3]);
```
Overflow occurs when operands have the same sign but the result has the opposite sign.

For subtraction:
```text
V = (A[3] ^ B[3]) & (Y[3] ^ A[3]);
```
Overflow occurs when the operands have different signs and the result sign differs from the sign of A.

For AND and OR operations, V is defined as 0.

## RTL Implementation

The ALU is implemented as purely combinational logic using  always_comb.

```text
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

        // Default values prevent unintended latch inference
        Y = 4'b0000;
        C = 1'b0;
        V = 1'b0;

        case (SEL)

            // ADD
            2'b00: begin
                {C,Y} = {1'b0,A} + {1'b0,B};

                V = ~(A[3] ^ B[3]) &
                     (Y[3] ^ A[3]);
            end

            // SUB
            2'b01: begin
                {C,Y} = {1'b0,A}
                      + {1'b0,~B}
                      + 5'b00001;

                V = (A[3] ^ B[3]) &
                    (Y[3] ^ A[3]);
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
