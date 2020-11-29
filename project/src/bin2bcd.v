`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   bin2bcd 
// Project Name:  Tetris Game
// Description:   Binary to BCD (Binary Coded Decimal) conversion
//
//////////////////////////////////////////////////////////////////////////////////
module bin2bcd_serial #(
  parameter BINARY_BITS = 16, // # of bits of binary input
  parameter BCD_DIGITS = 5  // # of digits of BCD output
)
(
  input clk,
  input rst,
  input [BINARY_BITS-1:0] bin_in,
  output reg [4*BCD_DIGITS-1:0] bcd_out
);

reg [BINARY_BITS-1:0] store_in;
reg start;
always @ (posedge clk) begin
  if(rst) store_in <= 0;
  else if(start) start <= 0;
  else if(done && (store_in != bin_in)) begin
    start <= 1;
    store_in <= bin_in;
  end
end

// Wrapper to provide always good results
wire [4*BCD_DIGITS-1:0] internal_out;
wire done;
integer i;
always @ (posedge clk) begin
  if(done) begin
    for(i=0;i<4*BCD_DIGITS;i=i+1) begin
      bcd_out[i] <= internal_out[i];
    end
  end
end

// Binary input shift register and counter
reg [BINARY_BITS-1:0] binary_shift = 0;
reg [$clog2(BINARY_BITS):0] binary_count = 0;
assign done = binary_count == 0;

always @(posedge clk)
begin
  if(start) begin
    binary_shift <= store_in;
    binary_count <= BINARY_BITS;
  end else if (binary_count != 0) begin
    binary_shift <= { binary_shift[BINARY_BITS-2:0], 1'b0 };
    binary_count <= binary_count - 1'b1;
  end
end

wire [BCD_DIGITS:0] bcd_carry;
assign bcd_carry[0] = binary_shift[BINARY_BITS-1]; // MSB
wire clk_enable = start | ~done;

genvar j;
generate
  for (j = 0; j < BCD_DIGITS; j=j+1) begin: DIGITS
    bcd_digit digit (
      .clk(clk),
      .init(start),
      .mod_in(bcd_carry[j]),
      .mod_out(bcd_carry[j+1]),
      .digit(internal_out[4*j +: 4]),
      .ce(clk_enable)
    );
  end
endgenerate

endmodule

// Regarding the init signal: At first it seems that digit[0] should have an explicit clear ("& ~init")
// like the rest. However digit[0] loads mod_in unconditionaly, and since mod_out is masked
// by & ~init this ensures digit[0] of higher digits is cleared during the init cycle whilst not loosing
// a cycle in the conversion for synchronous clearing.
module bcd_digit (
  input clk,
  input ce,
  input init,
  input mod_in,
  output mod_out,
  output reg [3:0] digit
);

  wire fiveOrMore = digit >= 5;
  assign mod_out  = fiveOrMore & ~init;

  always @(posedge clk)
  begin
    if (ce) begin
      digit[0] <= mod_in;
      digit[1] <= ~init & (~mod_out ? digit[0] : ~digit[0]);
      digit[2] <= ~init & (~mod_out ? digit[1] : digit[1] == digit[0]);
      digit[3] <= ~init & (~mod_out ? digit[2] : digit[0] & digit[3]);
    end
  end

endmodule