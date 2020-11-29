`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   prbs 
// Project Name:  Tetris game
// Description:   PRBS generator, also used in DVB-T
//
//////////////////////////////////////////////////////////////////////////////////
module prbs(
  input clk,
  input rst,
  output reg [5:0] dout,
  output reg new
);

reg [14:0] prbs_shr;
reg [5:0] prbs_temp;
reg [2:0] cntr;
wire prbs_xor;
assign prbs_xor = prbs_shr[1]^prbs_shr[0];

always @ (posedge clk)
begin
  if(rst || (prbs_shr == 15'b000000000000000)) begin
    prbs_shr   <= 15'b100101010000000;
    dout      <= 0;
    prbs_temp    <= 0;
    cntr      <= 0;
  end else begin
    cntr      <= cntr +1;
    prbs_shr   <= {prbs_xor,prbs_shr[14:1]};
    prbs_temp   <= {prbs_xor,prbs_temp[5:1]};
    if(cntr == 7) begin
      dout <= prbs_temp;
      new  <= 1;
    end else
      new  <= 0;
  end
end

endmodule