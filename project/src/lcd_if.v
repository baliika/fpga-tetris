`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:  lcd_if 
// Project Name: Tetris game
// Description:  LCD Interface: it fills the Command FIFO with initialization
//               commands and pixels to be displayed
//
//////////////////////////////////////////////////////////////////////////////////
module lcd_if(
  // General
  input clk,
  input rst,
  // Game logic
  output [9:0] frame_addr,
  input frame_update,
  input [7:0] frame_din,
  // Command FIFO interface
  input cmd_full,
  output [8:0] cmd_dout,
  output cmd_wr_en
);

// States
parameter WAIT = 3'b000;
parameter INIT = 3'b001;
parameter IDLE = 3'b011;
parameter CLEAR = 3'b010;
parameter UPDATE = 3'b100;
// Hold-time
parameter HOLDOFF_TIME = 250000-1; // ~5ms

reg [2:0] state;
reg [17:0] cntr;
reg [2:0] page_cntr;
// Game Logic registers
reg [9:0] addr;
// CMD Fifo registers
reg fifo_wr;
reg [8:0] fifo_dout;
reg [7:0] commands[15:0];
initial begin
  // Initial commands
  commands[0] <= 8'h40; // The first display row is the 0th
  commands[1] <= 8'hA0; // Normal column addressing
  commands[2] <= 8'hC8; // Reverse row addressing
  commands[3] <= 8'hA4; // Show SRAM content
  commands[4] <= 8'hA6; // Disable inverse display
  commands[5] <= 8'hA2; // LCD bias: 1/9
  commands[6] <= 8'h2F; // Turn on power supply
  commands[7] <= 8'h27; // Contrast (1-3)
  commands[8] <= 8'h81;
  commands[9] <= 8'h10;
  commands[10] <= 8'hFA; // Temperature compensation (1-2)
  commands[11] <= 8'h90;
  commands[12] <= 8'hAF; // Turn on display
  // General commands
  commands[13] <= 8'hB0; // Row address (lower 4 bits: page address (0-7))
  commands[14] <= 8'h00; // Column address (lower 4 bits: lower 4 bits of the column address)
  commands[15] <= 8'h10; // Column address (lower 4 bits: upper 4 bits of the column address)
end

always @ (posedge clk) begin
  if(rst)  begin
    state <= WAIT;
    cntr <= 0;
    fifo_wr <= 0;
    fifo_dout <= 0;
    addr <= 0;
  end else begin
    case(state)
      WAIT: begin
        if(cntr == HOLDOFF_TIME) begin
          state <= INIT;
          fifo_wr <= 1;
          cntr <= 1;
          fifo_dout <= {1'b0,commands[0]};
        end else
          cntr <= cntr+1;
      end
      INIT: begin
        fifo_dout <= {1'b0,commands[cntr]};
        if(cntr == 12) begin
          state <= UPDATE;
          page_cntr <= 0;
          cntr <= 0;
        end else
          cntr <= cntr+1;
      end
      CLEAR: begin
        if(~cmd_full) begin
          cntr <= cntr+1;
          if(cntr==0)
            fifo_dout <= {1'b0,(commands[13]|page_cntr)}; // Set row address
          else if(cntr==1)
            fifo_dout <= {1'b0,(commands[14]|4'hE)}; // Set column address (lower 4 bits)
          else if(cntr==2)
            fifo_dout <= {1'b0,(commands[15]|4'h1)}; // Set column address (upper 4 bits)
          else if(cntr < 105) begin
            fifo_dout <= {1'b1,8'h00}; // 3-104
            if(cntr == 104) begin
              page_cntr <= page_cntr+1;
              if(page_cntr == 7) begin
                state <= IDLE;
              end
              cntr <= 0;
            end
          end
        end
      end
      IDLE: begin
        if(frame_update && ~cmd_full) begin
          state <= UPDATE;
          page_cntr <= 0;
          cntr <= 0;
          fifo_wr <= 1;
          addr <= 0;
        end else
          fifo_wr <= 0;
      end
      UPDATE: begin
        if(~cmd_full) begin
          cntr <= cntr+1;
          if(cntr==0)
            fifo_dout <= {1'b0,(commands[13]|page_cntr)}; // Set row address
          else if(cntr==1)
            fifo_dout <= {1'b0,(commands[14]|4'hE)}; // Set column address (lower 4 bits)
          else if(cntr==2) begin
            fifo_dout <= {1'b0,(commands[15]|4'h1)}; // Set column address (upper 4 bits)
            addr <= addr+1;
          end else if(cntr < 105) begin
            fifo_dout <= {1'b1, frame_din};
            if(cntr == 104) begin
              page_cntr <= page_cntr+1;
              if(page_cntr == 7) begin
                state <= IDLE;
              end
              cntr <= 0;
            end else
              addr <= addr +1;
          end
        end
      end
      default: begin
      end
    endcase
  end
end

// Frame bufer
assign frame_addr = addr;
// Command FIFO
assign cmd_wr_en = (fifo_wr & ~cmd_full);
assign cmd_dout  = fifo_dout;

endmodule