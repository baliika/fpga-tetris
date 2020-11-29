`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   rategen 
// Project Name:  Tetris game
// Description:   Rate generator: it manages the speed of the falling blocks and
//                the rate of the game melody
//
//////////////////////////////////////////////////////////////////////////////////
module rategen(
  input clk,
  input rst,
  input drop,
  input [3:0] speed,
  output en
);

//Compare values
parameter CLK_DIV_GAMESPEED_1 = 50000000-1;
parameter CLK_DIV_GAMESPEED_2 = 45000000-1;
parameter CLK_DIV_GAMESPEED_3 = 40000000-1;
parameter CLK_DIV_GAMESPEED_4 = 35000000-1;
parameter CLK_DIV_GAMESPEED_5 = 30000000-1;
parameter CLK_DIV_GAMESPEED_6 = 25000000-1;
parameter CLK_DIV_GAMESPEED_7 = 20000000-1;
parameter CLK_DIV_GAMESPEED_8 = 15000000-1;
parameter CLK_DIV_GAMESPEED_9 = 10000000-1;
parameter CLK_DIV_DROP        = 5000000-1;

reg [25:0] compare;
always @ (*)
begin
  case(speed)
    1: compare <= CLK_DIV_GAMESPEED_1;
    2: compare <= CLK_DIV_GAMESPEED_2;
    3: compare <= CLK_DIV_GAMESPEED_3;
    4: compare <= CLK_DIV_GAMESPEED_4;
    5: compare <= CLK_DIV_GAMESPEED_5;
    6: compare <= CLK_DIV_GAMESPEED_6;
    7: compare <= CLK_DIV_GAMESPEED_7;
    8: compare <= CLK_DIV_GAMESPEED_8;
    9: compare <= CLK_DIV_GAMESPEED_9;
    default: compare <= CLK_DIV_GAMESPEED_1;
  endcase
end

reg [25:0] cntr;
always @ (posedge clk) begin
  if(rst) begin
    cntr <= 0;
  end else begin
    if(~drop && (cntr >= compare))
      cntr <= 0;
    else if(drop && (cntr >= CLK_DIV_DROP))
      cntr <= 0;
    else
      cntr <= cntr+1;
  end
end

assign en = drop?(cntr == CLK_DIV_DROP):(cntr == compare);

endmodule