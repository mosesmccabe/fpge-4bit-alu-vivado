`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/28/2026 06:16:56 AM
// Design Name: 
// Module Name: aul4_tb
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



module alu4_tb;
// Declare local testbench signals (stimulus variables)
    logic [3:0] A;
    logic[3:0] B;
    logic[1:0] SEL;
    
    logic[3:0] Y;
    logic      C;
    logic      Z;
    logic      N;
    logic      V;
    
     // Instantiate the Design Under Test (DUT)
    // connect the textbench signals to the alu4 DUT ports
    alu4 DUT(
        .A(A),
        .B(B),
        .SEL(SEL),
        .Y(Y), 
        .C(C),
        .Z(Z),
        .N(N),
        .V(V) 
    );
    
    // Generate the stimulus 
    initial begin
    
       // ADD, SEL =00
       
       // Test case 1: A=0100 B=0010 ? Y=0110 C=0 Z=0 N=0 V=0
            A=4'b0100; B=4'b0010; SEL =2'b00;  
        #10; // wait 10 ns
        
        // Test case 2: A=1101 B=1011 ? Y=1000 C=1 Z=0 N=1 V=0
            A=4'b1101; B=4'b1011; SEL =2'b00; 
        #10; // wait 10 ns
        
        // Test case 3: A=0101 B=0100 ? Y=1001 C=0 Z=0 N=1 V=1
            A=4'b0101; B=4'b0100; SEL =2'b00; 
        #10; // wait 10 ns
        
        // Test case 4: A=0000 B=0000 ? Y=0000 C=0 Z=1 N=0 V=0
            A=4'b0000; B=4'b0000; SEL =2'b00; 
        #10; // wait 10 ns
        
        
        
        // SUB, SEL=01
        
        // Test case 1: A=0111 B=0010 ? Y=0101 C=1 Z=0 N=0 V=0
            A=4'b0111; B=4'b0010; SEL =2'b01;
        #10; // wait 10 ns
        
        // Test case 2: A=0010 B=0101 ? Y=1101 C=0 Z=0 N=1 V=0
            A=4'b0010; B=4'b0101; SEL =2'b01; 
        #10; // wait 10 ns
        
        // Test case 3: A=1000 B=0001 ? Y=0111 C=1 Z=0 N=0 V=1
            A=4'b1000; B=4'b0001; SEL =2'b01; 
        #10; // wait 10 ns
        
        // Test case 4: A=0010 B=0111 ? Y=1011 C=0 Z=0 N=1 V=0
            A=4'b0010; B=4'b0111; SEL =2'b01;
        #10; // wait 10 ns
        
        // Test case 5: A=0101 B=0101 ? Y=0000 C=1 Z=1 N=0 V=0
            A=4'b0101; B=4'b0101; SEL =2'b01; 
        #10; // wait 10 ns
        
        // AND, SEL = 10
        
        // Test case 1: A=1000 B=1000 ? Y=1000 C=0 Z=0 N=1 V=0
            A=4'b1000; B=4'b1000; SEL =2'b10; 
        #10; // wait 10 ns
        
        // Test case 2: A=0000 B=0000 ? Y=0000 C=0 Z=1 N=0 V=0
            A=4'b0000; B=4'b0000; SEL =2'b10;
        #10; // wait 10 ns
        
        // OR, SEL = 11
        // case:  A=1000 B=0100 ? Y=1100 C=0 Z=0 N=1 V=0
            A=4'b1000; B=4'b0100; SEL =2'b11; 
        #10; // wait 10 ns
        
        
        $finish; // tells the simulator that the test is complete
    end
    
endmodule
