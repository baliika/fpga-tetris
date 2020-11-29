`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Module Name:   ps2 
// Project Name:  Tetris Game
// Description:   PS/2 interface: it interprets the PS/2 keyboard scancodes
//                for enabling a regular keyboard gameplay.
//
//////////////////////////////////////////////////////////////////////////////////
module ps2(
  // General
  input clk,
  input rst,
  // PS/2 outer interface
  input ps2_clk,
  input ps2_data,
  // PS/2 inner interface
  output reg [8:0] buttons, // {P, M, Esc, Space, Up, Down, Left, Right, Enter}
  output [7:0] ps2_debug
);

// Scan codes
parameter SCAN_CODE_RELEASE = 8'hF0;
parameter SCAN_CODE_EXTENDER = 8'hE0;
parameter SCAN_CODE_ENTER = 8'h5A;    // w/o EXT
parameter SCAN_CODE_LEFT = 8'h6B;     // w EXT
parameter SCAN_CODE_RIGHT = 8'h74;    // w EXT
parameter SCAN_CODE_UP = 8'h75;       // w EXT  
parameter SCAN_CODE_DOWN = 8'h72;     // w EXT
parameter SCAN_CODE_SPACE = 8'h29;    // w/o EXT
parameter SCAN_CODE_P = 8'h4D;        // w/o EXT
parameter SCAN_CODE_M = 8'h3A;        // w/o EXT
parameter SCAN_CODE_ESC = 8'h76;      // w/o EXT

// Delay PS/2 clock
reg [3:0] ps2_clk_dl;
always @ (posedge clk)
begin
  if(rst)
    ps2_clk_dl <= 4'hFF;
  else
    ps2_clk_dl <= {ps2_clk,ps2_clk_dl[3:1]};
end

reg [3:0] cntr;
reg [10:0] shr;
reg ps2_clk_prev;
always @ (posedge clk)
begin
  if(rst) begin
    cntr <= 0;
    shr <= 0;
    ps2_clk_prev <= 1;
  end else if(ps2_clk_prev != ps2_clk_dl[0]) begin // Edge detection
    ps2_clk_prev <= ps2_clk_dl[0];
    if(ps2_clk_dl[0] == 0) begin // Negative edge
      shr <= {ps2_data,shr[10:1]};
      if(cntr == 11)
        cntr <= 1;
      else
        cntr <= cntr +1;
    end
  end
end

// Processing stage
reg [3:0] cntr_prev;
reg dav;
reg [1:0] state;
// Available states
parameter STATE_IDLE = 2'b01;
parameter STATE_RELEASE = 2'b11;
parameter STATE_EXTENDER = 2'b00;
// Real data part of transmitted bits
wire [7:0] byte_real;
assign byte_real = shr[8:1];
wire en;
assign en = (cntr_prev != cntr);
// Received a full byte
wire byte_received;
assign byte_received = (cntr == 11);
always @ (posedge clk)
begin
  if(rst) begin
    cntr_prev <= 0;
    buttons  <= 0;
    state <= STATE_IDLE;
  end else if(buttons[6:0]!=0) buttons[6:0] <= 0;
  else if(en) begin
    cntr_prev <= cntr;
    if(byte_received) begin // Data Valid
      case(state)
        STATE_IDLE: begin
          if(byte_real == SCAN_CODE_EXTENDER) // For Directional keys  
            state <= STATE_EXTENDER;
          else if(byte_real == SCAN_CODE_RELEASE) // For Enter & Space
            state <= STATE_RELEASE;
        end
        STATE_EXTENDER: begin
          if(byte_real == SCAN_CODE_RELEASE)
            state <= STATE_RELEASE;
          else
            state <= STATE_IDLE;
        end
        STATE_RELEASE: begin
          if(byte_real == SCAN_CODE_ENTER)
            buttons[0] <= 1;
          else if(byte_real == SCAN_CODE_RIGHT)
            buttons[1] <= 1;
          else if(byte_real == SCAN_CODE_LEFT)
            buttons[2] <= 1;
          else if(byte_real == SCAN_CODE_DOWN)
            buttons[3] <= 1;
          else if(byte_real == SCAN_CODE_UP)
            buttons[4] <= 1;
          else if(byte_real == SCAN_CODE_SPACE)
            buttons[5] <= 1;
          else if(byte_real == SCAN_CODE_M)
            buttons[7] <= buttons[7]^1;
          else if(byte_real == SCAN_CODE_P)
            buttons[8] <= buttons[8]^1;
          else if(byte_real == SCAN_CODE_ESC)
            buttons[6] <= 1;
          state <= STATE_IDLE;
        end
      endcase;
    end
  end
end

// Debug
assign ps2_debug = cntr; //shr[8:1];

endmodule
