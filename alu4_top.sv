module alu4_top(
    input  logic [9:0] sw,   // inputs: A, B, SEL
    output logic [7:0] led   // outputs: Y, C, Z, N, V
);

    alu4 DUT (
        .A   (sw[3:0]),      // SW3:0 -> A
        .B   (sw[7:4]),      // SW7:4 -> B
        .SEL (sw[9:8]),      // SW9:8 -> SEL

        .Y   (led[3:0]),     // Y -> LD3:0
        .C   (led[4]),       // C -> LD4
        .Z   (led[5]),       // Z -> LD5
        .N   (led[6]),       // N -> LD6
        .V   (led[7])        // V -> LD7
    );

endmodule
