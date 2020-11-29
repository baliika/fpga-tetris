`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   draw_frames 
// Project Name:  Tetris Game
// Description:   Logic for drawing borders around the different elements:
//                - game space
//                - next building block
//                - user statistics
//                - instructions
//  
//////////////////////////////////////////////////////////////////////////////////
module draw_frames(
  input vga_clk,
  input rst,
  input [10:0] x,
  input [9:0] y,
  input [3:0] game_state,
  output reg [1:0] r,
  output reg [1:0] g,
  output reg [1:0] b,
  output reg dav
);

parameter STATE_LOGO = 4'b0000;

always @ (posedge vga_clk)
begin
  if(rst) begin
    r <= 0;
    g <= 0;
    b <= 0;
    dav <= 0;
  // Main frame
  end else if((y == 125 || y == 549) && (x >= 136 && x <= 392)) begin // Top & Bottom Horizontal @ line 126 |  from 138 to 394
    r <= 0;
    g <= 2'b11;
    b <= 2'b11;
    dav <= 1;
  end else if((x == 136 || x == 392) && (y >= 125 && y <= 549)) begin // Left & Right Horizontal
    r <= 0;
    g <= 2'b11;
    b <= 2'b11;
    dav <= 1;
  // Scores Side frames
  end else if((y == 125 || y == 235) && (x >= 404 && x <= 660)) begin // Top & Bottom Horizontal
    r <= 2'b11;
    g <= 2'b10;
    b <= 2'b00;
    dav <= 1;
  end else if((x == 404 || x == 660) && (y >= 125 && y <= 235)) begin // Left & Right Horizontal
    r <= 2'b11;
    g <= 2'b10;
    b <= 2'b00;
    dav <= 1;
  // Next element frame
  end else if((game_state != STATE_LOGO) && (y == 247 || y == 335) && (x >= 404 && x <= 660)) begin // Top & Bottom Horizontal
    r <= 2'b11;
    g <= 2'b00;
    b <= 2'b01;
    dav <= 1;
  end else if((game_state != STATE_LOGO) && (x == 404 || x == 660) && (y >= 247 && y <= 335)) begin // Left & Right Horizontal
    r <= 2'b11;
    g <= 2'b00;
    b <= 2'b01;
    dav <= 1;
  // Help frame
  end else if((game_state == STATE_LOGO) && (y == 247 || y == 389) && (x >= 404 && x <= 660)) begin // Top & Bottom Horizontal
    r <= 2'b11;
    g <= 2'b00;
    b <= 2'b01;
    dav <= 1;
  end else if((game_state == STATE_LOGO) && (x == 404 || x == 660) && (y >= 247 && y <= 389)) begin // Left & Right Horizontal
    r <= 2'b11;
    g <= 2'b00;
    b <= 2'b01;
    dav <= 1;
  end else begin
    dav <= 0;
  end
end

endmodule
