`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Module Name:   draw_numbers 
// Project Name:  Tetris Game
// Description:   Logic for drawing numbers on the screen
//
//////////////////////////////////////////////////////////////////////////////////
module draw_numbers #(
  parameter BINARY_BITS=26,
  parameter BCD_DIGITS=8,
  parameter NUM_OFFSET_Y=138-1
)
(
  input vga_clk,
  input rst,
  input [10:0] x,
  input [9:0] y,
  input [BINARY_BITS-1:0] bin_in,
  output reg [11:0] addr,
  output reg dav
);

parameter DIGIT_WIDTH = 16;
parameter NUM_WIDTH = BCD_DIGITS*DIGIT_WIDTH;
parameter NUM_HEIGHT = 20;
parameter NUM_OFFSET_X = 527-2+(8-BCD_DIGITS)*DIGIT_WIDTH;

// Binary to BCD conversion
wire [4*BCD_DIGITS-1:0] bcd;
bin2bcd_serial #(
  .BINARY_BITS(BINARY_BITS),
  .BCD_DIGITS(BCD_DIGITS)
) bin2bcd (
  .clk(vga_clk), 
  .rst(rst), 
  .bin_in(bin_in), 
  .bcd_out(bcd)
);

// Generate DAV signal
always @ (posedge vga_clk)
begin
  if(rst)
    dav <= 0;
  else if((x >= (NUM_OFFSET_X) && x < (NUM_WIDTH+NUM_OFFSET_X)) && (y >= (NUM_OFFSET_Y) && y < (NUM_HEIGHT+NUM_OFFSET_Y)))
    dav <= 1;
  else
    dav <= 0;
end

reg [11:0] str_addr[BCD_DIGITS-1:0];
integer i;
integer j;
always @ (posedge vga_clk)
begin
  if(rst) begin
    for(i=0;i<BCD_DIGITS;i=i+1) begin
      str_addr[i] <= 0;
    end
  end else if(y==NUM_OFFSET_Y && x==0) begin // Line start > initialize string addresses
    for(i=0;i<BCD_DIGITS;i=i+1) begin
      for(j=0;j<10;j=j+1) begin
        if(bcd[4*i +: 4] == j)
          str_addr[i] <= j*320;
      end
    end
  end else begin
    for(i=0;i<BCD_DIGITS;i=i+1) begin
      if(((x>=(NUM_OFFSET_X-1+i*DIGIT_WIDTH)) && (x < (NUM_OFFSET_X+(i+1)*DIGIT_WIDTH-1))) && (y >= (NUM_OFFSET_Y) && y < (NUM_HEIGHT+NUM_OFFSET_Y)))
        str_addr[BCD_DIGITS-i-1] <= str_addr[BCD_DIGITS-i-1] + 1;
    end
  end
end

// Multiplex address to BROM
always @ (posedge vga_clk)
begin
  if(rst) addr <= 0;
  else begin
    for(i=0;i<BCD_DIGITS;i=i+1) begin
      if(x>= (NUM_OFFSET_X+i*DIGIT_WIDTH-1) && x < (NUM_OFFSET_X+(i+1)*DIGIT_WIDTH-1))
        addr <= str_addr[BCD_DIGITS-i-1];
    end
  end
end

endmodule