`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   draw_title  
// Project Name:  Tetris Game
// Description:   Logic for drawing various strings on the screen
//  
//////////////////////////////////////////////////////////////////////////////////
module draw_strings(
  input vga_clk,
  input rst,
  input [10:0] x,
  input [9:0] y,
  input [3:0] game_state,
  output [1:0] r,
  output [1:0] g,
  output [1:0] b,
  output dav
);

parameter STATE_LOGO = 4'b0000;

// Title
parameter T_WIDTH = 303;
parameter T_HEIGHT = 40;
parameter T_OFFSET_X = 248-2;
parameter T_OFFSET_Y = 45-1;
// Scoreboard
parameter S_WIDTH = 88;
parameter S_HEIGHT = 88;
parameter S_OFFSET_X = 415-2;
parameter S_OFFSET_Y = 138-1;
// Help
parameter H_WIDTH = 237;
parameter H_HEIGHT = 119;
parameter H_OFFSET_X = 415-2;
parameter H_OFFSET_Y = 260-1;

// Data valid
reg [1:0] davs;
always @ (posedge vga_clk)
begin
  if(rst)
    davs <= 0;
  else if((x >= (T_OFFSET_X) && x < (T_WIDTH+T_OFFSET_X)) && (y >= (T_OFFSET_Y) && y < (T_HEIGHT+T_OFFSET_Y)))
    davs <= 1;
  else if((x >= (S_OFFSET_X) && x < (S_WIDTH+S_OFFSET_X)) && (y >= (S_OFFSET_Y) && y < (S_HEIGHT+S_OFFSET_Y)))
    davs <= 2;
  else if((game_state == STATE_LOGO) &&(x >= (H_OFFSET_X) && x < (H_WIDTH+H_OFFSET_X)) && (y >= (H_OFFSET_Y) && y < (H_HEIGHT+H_OFFSET_Y)))
    davs <= 3;
  else
    davs <= 0;
end
assign dav = (davs != 0);

// Title address resolution
reg [13:0] t_addr;
always @ (posedge vga_clk)
begin
  if(rst) t_addr <= 0;
  else begin
    if(y >= (T_OFFSET_Y) && y < (T_HEIGHT+T_OFFSET_Y)) begin
      if(x > (T_OFFSET_X-1) && x <= (T_WIDTH+T_OFFSET_X-1))
        t_addr <= t_addr + 1;
    end else
      t_addr <= 0;
  end
end

// Scoreboard address resolution
reg [12:0] s_addr;
always @ (posedge vga_clk)
begin
  if(rst) s_addr <= 0;
  else begin
    if(y >= (S_OFFSET_Y) && y < (S_HEIGHT+S_OFFSET_Y)) begin
      if(x > (S_OFFSET_X-1) && x <= (S_WIDTH+S_OFFSET_X-1))
        s_addr <= s_addr + 1;
    end else
      s_addr <= 0;
  end
end

// Help address resolution
reg [14:0] h_addr;
always @ (posedge vga_clk)
begin
  if(rst) h_addr <= 0;
  else begin
    if(y >= (H_OFFSET_Y) && y < (H_HEIGHT+H_OFFSET_Y)) begin
      if(x > (H_OFFSET_X-1) && x <= (H_WIDTH+H_OFFSET_X-1))
        h_addr <= h_addr + 1;
    end else
      h_addr <= 0;
  end
end

wire [1:0] title_data;
wire [1:0] scoreboard_data;
wire [1:0] help_data;

titleBRAM titleBROM(
  .clka(vga_clk), // input clka
  .addra(t_addr), // input [13:0] addra
  .douta(title_data) // output [1:0] douta
);

stringsBROM stringsBROM(
  .clka(vga_clk), // input clka
  .addra(s_addr), // input [12:0] addra
  .douta(scoreboard_data) // output [1:0] douta
);

helpBRAM helpBROM(
  .clka(vga_clk), // input clka
  .addra(h_addr), // input [14:0] addra
  .douta(help_data) // output [1:0] douta
);

assign r = davs==1?title_data:(davs==2?scoreboard_data:help_data);
assign g = davs==1?title_data:(davs==2?scoreboard_data:help_data);
assign b = davs==1?title_data:(davs==2?scoreboard_data:help_data);

endmodule