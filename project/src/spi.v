`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   spi
// Project Name:  Tetris game
// Description:   SPI interface for the SPI LCD
//
//////////////////////////////////////////////////////////////////////////////////
module spi(
  // General
  input clk,
  input rst,
  // SPI interfacing
  output spi_sdcard_csn,
  output spi_flash_csn,
  output spi_lcd_csn,
  output spi_clk,
  output spi_mosi,
  output spi_datacommand,
  // Command FIFO interfacing
  input cmd_empty,
  input [8:0] cmd_din,
  output cmd_rd
);

// SPI state machine
parameter SPI_IDLE = 2'b00;
parameter SPI_SENDING = 2'b01;
parameter SPI_SENT = 2'b11;

reg [7:0] shr;
reg [3:0] cntr;
reg [1:0] spi_state;
// SPI interfacing
reg spi_sclk;
reg spi_cs;
reg spi_dc;

always @ (posedge clk)
begin
  if(rst) begin
    spi_sclk <= 0;
    spi_cs <= 1;
    spi_dc <= 0;
    cntr <= 0;
    spi_state <= SPI_IDLE;
    shr <= 8'h00;
  end else begin
    case(spi_state)
      SPI_IDLE: begin
        if(cmd_state == CMD_STORE) begin
          spi_dc <= cmd_din[8];
          spi_cs <= 0;
          spi_state <= SPI_SENDING;
          spi_sclk <= 0;
          shr <= cmd_din[7:0];
          cntr <= 0;
        end
      end
      SPI_SENDING: begin
        cntr <= cntr +1;
        if(cntr[0]==0) // rising edge, no data change
          spi_sclk <= 1;
        else begin // falling edge, data change
          spi_sclk <= 0;
          shr <= {shr[6:0],1'b0};
        end
        // After last cycle
        if(cntr == 15) begin
          spi_state <= SPI_SENT;
        end
      end
      SPI_SENT: begin
        spi_cs <= 1;
        spi_state <= SPI_IDLE;
      end
      default: begin
      end
    endcase
  end
end

// SPI lines
assign spi_lcd_csn = spi_cs;
assign spi_clk = spi_sclk;
assign spi_mosi = shr[7];
assign spi_datacommand = spi_dc;

// SPI other /CS lines pulled up
assign spi_sdcard_csn = 1;
assign spi_flash_csn = 1;

// Command FIFO interfacing
parameter CMD_IDLE = 2'b00;
parameter CMD_READ = 2'b01;
parameter CMD_STORE = 2'b10;
reg cmd_read;
reg [1:0] cmd_state;

always @ (posedge clk)
begin
  if(rst) begin
    cmd_read <= 0;
    cmd_state <= CMD_IDLE;
  end else begin
    case (cmd_state)
      CMD_IDLE: begin
        if((spi_state == SPI_IDLE || spi_state == SPI_SENT) && ~cmd_empty) begin
          cmd_read <= 1;
          cmd_state <= CMD_READ;
        end
      end
      CMD_READ: begin
        cmd_read <= 0;
        cmd_state <= CMD_STORE;
      end
      CMD_STORE: begin
        cmd_state <= CMD_IDLE;
      end
      default: begin end
    endcase
  end
end

assign cmd_rd = cmd_read;

endmodule