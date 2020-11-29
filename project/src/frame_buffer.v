`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   frame_buffer
// Project Name:  Tetris game
// Description:   Frame buffer & Frame updater: it maps the current game space to
//                the SPI LCD's pixel space.
//
//////////////////////////////////////////////////////////////////////////////////
module frame_buffer(
  // General
  input clk,
  input rst,
  // LCD interface wiring
  output [7:0] frame_out,
  input [9:0] frame_addr,
  output reg update_lcd,
  // Game logic interfacing
  input [11:0] game_area_data,
  output reg [4:0] game_area_addr,
  input [3:0] gamestate,
  input update_buffer
);

// Game states that needs to be adapted
parameter STATE_LOGO = 3'b000;
parameter STATE_NEWBLOCK = 3'b001;
parameter STATE_MOVING = 3'b010;

// Block RAM read & write access
wire [10:0] readport_addr;
wire [7:0] readport_data;
wire [10:0] writeport_addr;
reg writeport_wea;
reg [7:0] writeport_data;
reg [7:0] graphics_blocks[15:0];
initial $readmemh("data/graphics_blocks.txt", graphics_blocks);

// Frame buffer updater
reg [9:0] write_addr; // actual frame buffer address
reg [9:0] read_addr; // actual frame buffer address
reg [2:0] page; // actual page number
reg [6:0] column; // gamecolumn in page
reg [2:0] square; // Square width counter
reg [2:0] gamestate_stored; //actual gamestate stored
reg processing;
reg waiting;

always @ (posedge clk) begin
  if(rst) begin
    // General
    processing <= 0;
    waiting <= 0;
    update_lcd <= 0;
    // BRAM
    writeport_wea <= 0;
    writeport_data <= 0;
    read_addr <= 0;
  end else if(update_lcd) update_lcd <= 0;
  else if(waiting) waiting <= 0;
  else if(update_buffer) begin
    // Store gamestate
    gamestate_stored  <= gamestate;
    read_addr <= 0;
    write_addr <= -1;
    page <= 0;
    column <= 0;
    square <= 0;
    processing <= 1;
  end else if(processing) begin
    if(gamestate_stored == STATE_LOGO) begin
      writeport_data <= readport_data;
      read_addr <= read_addr+1;
      write_addr <= write_addr+1;
      writeport_wea <= 1;
      if(write_addr == 815) begin
        processing <= 0;
        update_lcd <= 1;
        writeport_wea <= 0;
      end
    end else if(gamestate_stored == STATE_MOVING || gamestate_stored == STATE_NEWBLOCK) begin
      // Address resolution
      if(column == 0 && square ==2) begin
        square <= 0;
        if(page==7) begin
          page <= 0;
          write_addr <= column+1; // Skip white + skip 1 from the next block
          column <= column+2; // Skip white + skip 1 from the next block
          game_area_addr <= 19;
          waiting <= 1;
        end else begin
          page <= page+1;
          write_addr <= write_addr+100;
        end
        writeport_wea <= 0;
      end else if(column!=0 && square ==5) begin
        square <= 0;
        if(page==7) begin
          if(write_addr == 815) begin
            processing <= 0;
            update_lcd <= 1;
          end else begin
            page <= 0;
            write_addr <= column+4;
            column <= column+5;
            game_area_addr <= game_area_addr-1;
            waiting <= 1;
          end
        end else begin
          page <= page+1;
          write_addr <= write_addr+97;
        end
        writeport_wea <= 0;
      end else begin
        write_addr <= write_addr+1;
        square <= square+1;
        writeport_wea <= 1;
      end
      // Pixel adaptation
      if(column==0 || square == 0)
        writeport_data <= 8'h00;
      else begin
        case(page)
          0: writeport_data <= (game_area_data[11]?graphics_blocks[0] :8'h00) | (game_area_data[10]?graphics_blocks[1] :8'h00);
          1: writeport_data <= (game_area_data[10]?graphics_blocks[2] :8'h00) | (game_area_data[9] ?graphics_blocks[3] :8'h00);
          2: writeport_data <= (game_area_data[8] ?graphics_blocks[4] :8'h00) | (game_area_data[7] ?graphics_blocks[5] :8'h00);
          3: writeport_data <= (game_area_data[7] ?graphics_blocks[6] :8'h00) | (game_area_data[6] ?graphics_blocks[7] :8'h00);
          4: writeport_data <= (game_area_data[5] ?graphics_blocks[8] :8'h00) | (game_area_data[4] ?graphics_blocks[9] :8'h00);
          5: writeport_data <= (game_area_data[4] ?graphics_blocks[10]:8'h00) | (game_area_data[3] ?graphics_blocks[11]:8'h00) | (game_area_data[2]?graphics_blocks[12]:8'h00);
          6: writeport_data <= (game_area_data[2] ?graphics_blocks[13]:8'h00) | (game_area_data[1] ?graphics_blocks[14]:8'h00);
          7: writeport_data <= (game_area_data[0] ?graphics_blocks[15]:8'h00);
        endcase
      end
    end
  end
end

assign readport_addr = processing? {1'b0,read_addr} : {1'b1,frame_addr};
assign writeport_addr = {1'b1,write_addr}; 

// Frame buffer & Graphics
frameBRAM frameBRAM (
  // Write port
  .clka(clk), // input clka
  .wea(writeport_wea), // input [0:0] wea
  .addra(writeport_addr), // input [10:0] addra
  .dina(writeport_data), // input [7:0] dina
  // Read port
  .clkb(clk), // input clkb
  .addrb(readport_addr), // input [10:0] addrb
  .doutb(readport_data) // output [7:0] doutb
);

assign frame_out = readport_data;

endmodule