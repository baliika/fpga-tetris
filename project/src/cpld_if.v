`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   cpld_if 
// Project Name:  Tetris game
// Description:   CPLD interface: interfacing logic between the FPGA and the
//                CPLD
//
//////////////////////////////////////////////////////////////////////////////////
module cpld_if(
  input clk,
  input rst,
  input [7:0] num,
  output [4:0] buttons,
  output cpld_rstn,
  output cpld_clk,
  output cpld_load,
  output cpld_mosi,
  input cpld_miso
);

reg [15:0] cntr;
always @ (posedge clk)
begin
  if(rst) cntr <= 0;
  else cntr <= cntr +1;
end

wire [3:0] dig_data;
assign dig_data = (cntr[15]? num[7:4]:num[3:0]);
reg [7:0] seg_data;

// 8-segment encoding
//      0
//     ---
//  5 |   | 1
//     --- <--6
//  4 |   | 2
//     ---
//      3  o <-- 7
//
always @(dig_data)
begin
  case (dig_data)
    4'b0001 : seg_data <= 8'b11111001;  // 1
    4'b0010 : seg_data <= 8'b10100100;  // 2
    4'b0011 : seg_data <= 8'b10110000;  // 3
    4'b0100 : seg_data <= 8'b10011001;  // 4
    4'b0101 : seg_data <= 8'b10010010;  // 5
    4'b0110 : seg_data <= 8'b10000010;  // 6
    4'b0111 : seg_data <= 8'b11111000;  // 8
    4'b1000 : seg_data <= 8'b10000000;  // 8
    4'b1001 : seg_data <= 8'b10010000;  // 9
    4'b1010 : seg_data <= 8'b10001000;  // A
    4'b1011 : seg_data <= 8'b10000011;  // b
    4'b1100 : seg_data <= 8'b11000110;  // C
    4'b1101 : seg_data <= 8'b10100001;  // d
    4'b1110 : seg_data <= 8'b10000110;  // E
    4'b1111 : seg_data <= 8'b10001110;  // F
    default : seg_data <= 8'b11000000;  // 0
  endcase
end

wire cpld_clk_fall;
assign cpld_clk_fall = (cntr[10:0]==11'b11111111111);

// MOSI processing
reg [15:0] mosi_shr;
reg [4:0]  btns_pre;
always @ (posedge clk)
begin
  if(rst)
    mosi_shr <= 0;
  else if (cntr[14:0]==15'h7fff)
    mosi_shr <= {~seg_data,3'b000,btns_pre};
  else if(cpld_clk_fall)
    mosi_shr <= {1'b0, mosi_shr[15:1]};
end

// MISO processing
reg [15:0] miso_shr;
always @ (posedge clk)
begin
  if(rst) begin
    miso_shr <= 0;
    btns_pre <= 0;
  end else if ((cntr[14:0]==15'h7fff) && (miso_shr[7:3]!=5'b11111))
    btns_pre <= {miso_shr[7:3]}; //= [Left, Right, Down, Up, Select]
  else if(cpld_clk_fall)
    miso_shr <= {miso_shr[14:0],cpld_miso};
end

// Debouncing buttons
integer i;
reg [4:0] btns_prev;
reg [4:0] btns_out;
always @ (posedge clk)
begin
  if(rst) begin
    btns_out <= 0;
    btns_prev <= 0;
  end else begin
    btns_prev <= btns_pre;
    for(i=0;i<5;i = i+1) begin
      if(btns_out[i]) btns_out[i] <= 0;
      else if((btns_prev[i]^btns_pre[i]) && btns_pre[i]) btns_out[i] <= 1;
    end
  end
end

// Outputs
assign cpld_mosi = mosi_shr[0];
assign cpld_clk  = cntr[10];
assign cpld_load = (cntr[14:11] == 15);
assign cpld_rstn = ~rst;
assign buttons   = btns_out;

endmodule
