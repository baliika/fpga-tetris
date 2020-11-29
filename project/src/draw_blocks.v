`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   draw_blocks 
// Project Name:  Tetris Game
// Description:   Logic for drawing the game space
//
//////////////////////////////////////////////////////////////////////////////////
module draw_blocks(
  input vga_clk,
  input rst,
  input [10:0] x,
  input [9:0] y,
  input [3:0] game_state,
  input [11:0] game_area_data,
  output reg [4:0] game_area_addr,
  input [7:0] game_block_next,
  output reg [1:0] r,
  output reg [1:0] g,
  output reg [1:0] b,
  output reg dav
);

parameter STATE_LOGO = 4'b0000;

// Game area reader
reg valid_line;
always @ (posedge vga_clk)
begin
  if(rst) begin
    valid_line <= 0;
    game_area_addr <= 0;
  end else begin
    if((y>=129) && (y<=146)) begin
      game_area_addr <= 0;
      valid_line <= 1;
    end else if((y>=150) && (y<=167)) begin
      game_area_addr <= 1;
      valid_line <= 1;
    end else if((y>=171) && (y<=188)) begin
      game_area_addr <= 2;
      valid_line <= 1;
    end else if((y>=192) && (y<=209)) begin
      game_area_addr <= 3;
      valid_line <= 1;
    end else if((y>=213) && (y<=230)) begin
      game_area_addr <= 4;
      valid_line <= 1;
    end else if((y>=234) && (y<=251)) begin
      game_area_addr <= 5;
      valid_line <= 1;
    end else if((y>=255) && (y<=272)) begin
      game_area_addr <= 6;
      valid_line <= 1;
    end else if((y>=276) && (y<=293)) begin
      game_area_addr <= 7;
      valid_line <= 1;
    end else if((y>=297) && (y<=314)) begin
      game_area_addr <= 8;
      valid_line <= 1;
    end else if((y>=318) && (y<=335)) begin
      game_area_addr <= 9;
      valid_line <= 1;
    end else if((y>=339) && (y<=356)) begin
      game_area_addr <= 10;
      valid_line <= 1;
    end else if((y>=360) && (y<=377)) begin
      game_area_addr <= 11;
      valid_line <= 1;
    end else if((y>=381) && (y<=398)) begin
      game_area_addr <= 12;
      valid_line <= 1;
    end else if((y>=402) && (y<=419)) begin
      game_area_addr <= 13;
      valid_line <= 1;
    end else if((y>=423) && (y<=440)) begin
      game_area_addr <= 14;
      valid_line <= 1;
    end else if((y>=444) && (y<=461)) begin
      game_area_addr <= 15;
      valid_line <= 1;
    end else if((y>=465) && (y<=482)) begin
      game_area_addr <= 16;
      valid_line <= 1;
    end else if((y>=486) && (y<=503)) begin
      game_area_addr <= 17;
      valid_line <= 1;
    end else if((y>=507) && (y<=524)) begin
      game_area_addr <= 18;
      valid_line <= 1;
    end else if((y>=528) && (y<=545)) begin
      game_area_addr <= 19;
      valid_line <= 1;
    end else
      valid_line <= 0;
  end
end

// Valid line data multiplexer
wire [11:0] game_area_mx;
assign game_area_mx = valid_line?game_area_data:12'h000;

// Next block reader
reg [3:0] nextblock_mx;
always @ (posedge vga_clk)
begin
  if(rst) begin
    nextblock_mx <= 0;
  end else if(game_state !=STATE_LOGO) begin  // Next block would flicker
    if((y>=272) && (y<=289))
      nextblock_mx <= (game_block_next==8'hCC)?6:game_block_next[3:0];
    else if((y>=293) && (y<=310))
      nextblock_mx <= (game_block_next==8'hCC)?6:game_block_next[7:4];
    else
      nextblock_mx <= 0;
  end else
    nextblock_mx <= 0;
end

// Pixel adaptation
integer i;
always @ (posedge vga_clk)
begin
  if(rst) begin
    r <= 0;
    g <= 0;
    b <= 0;
    dav <= 0;
  end else begin
    // Game stage
    if((game_area_mx[11]!=0) && ((x>=(140)) && (x<=(157)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[10]!=0) && ((x>=(161)) && (x<=(178)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[9]!=0) && ((x>=(182)) && (x<=(199)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[8]!=0) && ((x>=(203)) && (x<=(220)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[7]!=0) && ((x>=(224)) && (x<=(241)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[6]!=0) && ((x>=(245)) && (x<=(262)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[5]!=0) && ((x>=(266)) && (x<=(283)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[4]!=0) && ((x>=(287)) && (x<=(304)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[3]!=0) && ((x>=(308)) && (x<=(325)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[2]!=0) && ((x>=(329)) && (x<=(346)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[1]!=0) && ((x>=(350)) && (x<=(367)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((game_area_mx[0]!=0) && ((x>=(371)) && (x<=(388)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    // Next Block
    end else if((nextblock_mx[3]!=0) && ((x>=(492)) && (x<=(509)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((nextblock_mx[2]!=0) && ((x>=(513)) && (x<=(530)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((nextblock_mx[1]!=0) && ((x>=(534)) && (x<=(551)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    end else if((nextblock_mx[0]!=0) && ((x>=(555)) && (x<=(572)))) begin
      r <= 2'b11;
      g <= 2'b11;
      b <= 2'b11;
      dav <= 1;
    // Otherwise
    end else
      dav <= 0;
  end
end

endmodule
