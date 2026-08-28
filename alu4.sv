`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2026 05:14:53 AM
// Design Name: 
// Module Name: alu4
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu4(
    input logic[3:0] A,
    input logic[3:0] B,
    input logic[1:0] SEL,
    
    output logic[3:0] Y,
    output logic      C,
    output logic      Z,
    output logic      N,
    output logic      V
    );
    
    always_comb begin
        //defaults
        Y = 4'b0000;
        C = 1'b0;
        V = 1'b0;
        
        case(SEL)
            // SEL = 00 -> ADD
            2'b00: begin 
                {C,Y} = {1'b0, A} + {1'b0, B};
                V = ~(A[3] ^ B[3]) & (Y[3] ^ A[3]); 
            end
            // SEL = 01 -> SUB
            2'b01: begin
                {C,Y} = {1'b0, A} + {1'b0, ~B} + 5'b00001;
                V = (A[3] ^ B[3]) & (Y[3] ^ A[3]); 
            end
            // SEL = 10 = AND
            2'b10: begin
                Y = A & B;
            end
            // SEL = 11 -> OR
            2'b11: begin
                Y = A | B;
            end
        endcase
        
        Z = (Y == 4'b0000);
        N = Y[3];
        
    end
endmodule
