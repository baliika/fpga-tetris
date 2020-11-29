`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   toplevel 
// Project Name:  Tetris game
// Description:   Top level module for Tetris Game
//
//////////////////////////////////////////////////////////////////////////////////
module toplevel(
  // General
  input clk, //50MHz
  input rstn,
  // SPI interface
  output spi_sdcard_csn,
  output spi_flash_csn,
  output spi_lcd_csn,
  output spi_mosi,
  output spi_miso,
  output spi_clk,
  // CPLD interface
  output cpld_rstn,
  output cpld_mosi,
  output cpld_clk,
  output cpld_load,
  input  cpld_miso,
  // PS/2 interface
  input ps2_clk,
  input ps2_data,
  // Audio output
  output pwm_out,
  // VGA interface
  output vga_hs,
  output vga_vs,
  output [1:0] vga_red,
  output [1:0] vga_green,
  output [1:0] vga_blue
);

// Game states
parameter STATE_LOGO      = 4'b0000;
parameter STATE_NEWBLOCK  = 4'b0001;
parameter STATE_MOVING    = 4'b0010;
parameter STATE_EVAL      = 4'b0011;
parameter STATE_PREROTATE = 4'b0100;
parameter STATE_FALL      = 4'b0101;
parameter STATE_RIGHT     = 4'b0110;
parameter STATE_LEFT      = 4'b0111;
parameter STATE_ROTATE    = 4'b1000;
parameter STATE_GAMEOVER  = 4'b1001;
// Game point increment
parameter GAME_POINT_INCREMENT = 100;
// Game speed
parameter GAME_SPEED_MIN  = 1;
parameter GAME_SPEED_MAX  = 9;
  
// Global wirings
wire rst;
assign rst = ~rstn;
wire [5:0] game_prbs;    // PRBS wiring
wire [4:0] buttons_cpld; // Onboard Game buttons {Left, Right, Down, Up, Select}
wire [8:0] buttons_ps2;  // PS/2 buttons

// Game actions
wire action_rotate;
assign action_rotate = buttons_cpld[0] | buttons_ps2[5];
wire action_right;
assign action_right = buttons_cpld[3] | buttons_ps2[1];
wire action_left;
assign action_left = buttons_cpld[4] | buttons_ps2[2];
wire action_down;
assign action_down = buttons_cpld[2] | buttons_ps2[3];
wire action_enter;
assign action_enter = buttons_cpld[0] | buttons_ps2[0];
wire action_up;
assign action_up = buttons_cpld[1] | buttons_ps2[4];
wire action_music;
assign action_music = buttons_ps2[7];
wire action_pause;
assign action_pause = buttons_ps2[8];
wire action_exit;
assign action_exit = buttons_ps2[6];
wire action_fall; // Rategen wiring
reg action_drop; // User drop

// Building blocks & Graphics
reg [7:0] building_blocks[6:0];
reg [11:0] game_area_init[5:0];
initial $readmemh("data/graphics_buildingblocks.txt", building_blocks);
initial $readmemh("data/graphics_gamearea.txt", game_area_init);

// Game area
reg [11:0] game_area[19:0];
reg [11:0] game_area_newblock[3:0];
reg [11:0] game_area_backup[3:0];
// Game state
(* KEEP = "TRUE" *) reg [3:0] gamestate;
reg framebuffer_game_update;
// Position
reg [2:0] rel_cntr;
reg [4:0] abs_cntr;
reg [4:0] cntr_top;
reg [3:0] cntr_left;
// Collision detection
reg collision;
reg check;
reg checked;
// Player points & achievements
reg [25:0] gamepoints;
reg [25:0] gamepoints_inc;
reg [25:0] gamelines;
reg [3:0] gamespeed; // 1 > 9
// Misc counter
reg [7:0] cntr_event;
// Next Block
reg [2:0] block_id;
reg [2:0] next_block_id;
// Frame borders
wire gameborder_left;
wire gameborder_right;
assign gameborder_left  = |(game_area_newblock[0][11]|game_area_newblock[1][11]|game_area_newblock[2][11]|game_area_newblock[3][11]);
assign gameborder_right = |(game_area_newblock[0][0]|game_area_newblock[1][0]|game_area_newblock[2][0]|game_area_newblock[3][0]);

integer i;

always @ (posedge clk)
begin
  if(rst) begin
    action_drop <= 0;
    gamespeed <= 1;
    gamestate <= STATE_LOGO;
    framebuffer_game_update <= 1;
    check <= 0;
    gamepoints <= 0;
    gamelines <= 0;
  end else if(framebuffer_game_update)
    framebuffer_game_update <= 0;
  else if(check) begin
    rel_cntr <= rel_cntr +1;
    abs_cntr <= abs_cntr +1;
    if(~collision && (rel_cntr <4) && (abs_cntr <20)) begin
      if(game_area[abs_cntr]&game_area_newblock[rel_cntr])
        collision <= 1;
    end else if((abs_cntr == 20) && (rel_cntr <4) && (game_area_newblock[rel_cntr]!=0))
      collision <= 1;
    else begin
      checked <= 1;
      check <= 0;
    end
  end else begin
    case(gamestate)
      STATE_LOGO: begin
        if(action_enter) begin
          for(i=0;i<20;i=i+1) begin
            game_area[i] <= 0;
          end
          gamepoints <= 0;
          gamelines <= 0;
          checked <= 0;
          framebuffer_game_update <= 1;
          gamestate  <= STATE_NEWBLOCK;
          for(i=0;i<20;i=i+1)
            game_area[i] <= 0;
        end else if(action_up && gamespeed < GAME_SPEED_MAX)
          gamespeed <= gamespeed + 1;
        else if(action_down && gamespeed > GAME_SPEED_MIN)
          gamespeed <= gamespeed - 1;
        else if((game_prbs[2:0] < 7) && (game_prbs[5:3] < 7)) begin
          block_id <= game_prbs[2:0];
          next_block_id <= game_prbs[5:3];
        end
      end
      STATE_NEWBLOCK: begin
        if(~checked) begin
          action_drop <= 0;
          cntr_left <= 4;
          cntr_top <= 0;
          rel_cntr <= 0;
          abs_cntr <= 0;
          game_area_newblock[0] <= {4'h00,building_blocks[block_id][3:0],4'h00};
          game_area_newblock[1] <= {4'h00,building_blocks[block_id][7:4],4'h00};
          game_area_newblock[2] <= 0;
          game_area_newblock[3] <= 0;
          check <= 1;
          collision <= 0;
        end else if(collision) begin
          gamestate <= STATE_GAMEOVER;
          framebuffer_game_update <= 1;
        end else if (checked) begin
          framebuffer_game_update <= 1;
          gamestate <= STATE_MOVING;
        end
      end
      STATE_MOVING: begin
        checked   <= 0;
        if(action_fall)
          gamestate <= STATE_FALL;
        else if(action_right && ~gameborder_right)
          gamestate <= STATE_RIGHT;
        else if(action_left && ~gameborder_left)
          gamestate <= STATE_LEFT;
        else if(action_rotate) begin
          gamestate <= STATE_PREROTATE;
          cntr_event <= 0;
          for(i=0;i<4;i=i+1) begin
            game_area_backup[i] <= game_area_newblock[i];
          end
        end else if(action_down)
          action_drop <= 1;
        else if(action_exit) begin
          gamestate <= STATE_LOGO;
          framebuffer_game_update <= 1;
        end
      end
      STATE_FALL: begin
        if(~checked) begin
          if(cntr_top < 19) begin
            collision <= 0;
            check <= 1;
          end else if(cntr_top == 19 && game_area_newblock[0]!=0) begin
            collision <= 1;
            checked <= 1;
          end
          rel_cntr <= 0;
          abs_cntr <= cntr_top+1;
        end else if(collision) begin  // Collision either with gamespace or game border bottom
          // Update gamepsace
          for(i=0;i<20;i=i+1) begin
            if(i>=cntr_top && (i-cntr_top) < 4)
              game_area[i] <= game_area[i] | game_area_newblock[i-cntr_top];
          end
          framebuffer_game_update <= 1;
          gamestate <= STATE_EVAL;
          cntr_event <= 0;
          abs_cntr <= 0;
        end else begin
          cntr_top <= cntr_top + 1;
          framebuffer_game_update <= 1;
          gamestate <= STATE_MOVING;
        end
      end
      STATE_LEFT: begin
        if(~checked) begin
          collision <= 0;
          check <= 1;
          rel_cntr <= 0;
          abs_cntr <= cntr_top;
          for(i=0;i<4;i=i+1) begin
            game_area_newblock[i] <= {game_area_newblock[i][10:0],1'b0};
          end
        end else begin
          if(collision) begin
            for(i=0;i<4;i=i+1)
              game_area_newblock[i] <= {1'b0,game_area_newblock[i][11:1]};
          end else
            cntr_left <= cntr_left - 1;
          framebuffer_game_update <= 1;
          gamestate <= STATE_MOVING;
        end
      end
      STATE_RIGHT: begin
        if(~checked) begin
          collision <= 0;
          check <= 1;
          rel_cntr <= 0;
          abs_cntr <= cntr_top;
          for(i=0;i<4;i=i+1) begin
            game_area_newblock[i] <= {1'b0,game_area_newblock[i][11:1]};
          end
        end else begin
          if(collision) begin
            for(i=0;i<4;i=i+1)
              game_area_newblock[i] <= {game_area_newblock[i][10:0],1'b0};
          end else
            cntr_left <= cntr_left+1;
            framebuffer_game_update <= 1;
            gamestate   <= STATE_MOVING;
        end
      end
      STATE_EVAL: begin
        if(abs_cntr == 20) begin
          if(game_prbs[2:0]<7) begin
            block_id <= next_block_id;
            next_block_id <= game_prbs[2:0];
            framebuffer_game_update <= 1;
            gamestate <= STATE_NEWBLOCK;
            checked <= 0;
          end
        end else begin
          abs_cntr <= abs_cntr +1;
          if(game_area[abs_cntr]==12'hFFF) begin
            gamelines <= gamelines + 1;
            gamepoints_inc <= {gamepoints_inc,1'b0};  // 100 200 400 800: Tetris 
            gamepoints <= gamepoints + gamepoints_inc;  
            for(i=19;i>0;i=i-1) begin
              if(i<=abs_cntr)
                game_area[i] <= game_area[i-1];
            end
            game_area[0]<=12'h000;
          end else
            gamepoints_inc <= GAME_POINT_INCREMENT;
        end
      end
      STATE_PREROTATE: begin
        if(cntr_event < cntr_left) begin // Move object to Top Left Corner
          for(i=0;i<4;i=i+1)
            game_area_newblock[i] <= {game_area_newblock[i][10:0],1'b0};
          cntr_event <= cntr_event +1;
        end else begin 
          //  | 0x11 0x10 0x9 0x8 |    >>      | 3x11  2x11  1x11  0x11 |
          //  | 1x11 1x10 1x9 1x8 |            | 3x10  2x10  1x10  0x10 |
          //  | 2x11 2x10 2x9 2x8 |            | 3x9   2x9   1x9   0x9  |
          //  | 3x11 3x10 3x9 3x8 |            | 3x8   2x8   1x8   0x8  |
          game_area_newblock[0] <= {game_area_newblock[3][11],game_area_newblock[2][11],game_area_newblock[1][11],game_area_newblock[0][11],8'h00};
          game_area_newblock[1] <= {game_area_newblock[3][10],game_area_newblock[2][10],game_area_newblock[1][10],game_area_newblock[0][10],8'h00};        
          game_area_newblock[2] <= {game_area_newblock[3][9],game_area_newblock[2][9],game_area_newblock[1][9],game_area_newblock[0][9],8'h00};
          game_area_newblock[3] <= {game_area_newblock[3][8],game_area_newblock[2][8],game_area_newblock[1][8],game_area_newblock[0][8],8'h00};
          cntr_event <= 0;
          checked <= 0;
          gamestate <= STATE_ROTATE;
        end
      end
      STATE_GAMEOVER: begin
        if(action_enter) begin
          gamestate <= STATE_LOGO;
          framebuffer_game_update <= 1;
        end  
      end
      STATE_ROTATE: begin
        if(game_area_newblock[0]==12'h000) begin // Top row is empty
          for(i=0;i<3;i=i+1) begin
            game_area_newblock[i] <= game_area_newblock[i+1];
          end
          game_area_newblock[3] <= 12'h000;
        end else if(~gameborder_left && (cntr_event == 0)) begin // Left column is empty
          for(i=0;i<4;i=i+1) begin
            game_area_newblock[i] <= {game_area_newblock[i][10:0],1'b0};
          end
        end else if(cntr_event < cntr_left) begin // Object is in the top left corner > shifting right > if applicable
          cntr_event <= cntr_event +1;
          if(~gameborder_right) begin
            for(i=0;i<4;i=i+1) begin
              game_area_newblock[i] <= {1'b0,game_area_newblock[i][11:1]};
            end
          end else begin // Revert changes
            gamestate <= STATE_MOVING;
            for(i=0;i<4;i=i+1) begin
              game_area_newblock[i] <= game_area_backup[i];
            end
          end
        end else begin // Shifting down > if applicable
          if(~checked) begin
            collision <= 0;
            check <= 1;
            rel_cntr <= 0;
            abs_cntr <= cntr_top;
          end else if(collision) begin // Revert changes
            gamestate <= STATE_MOVING;
            for(i=0;i<4;i=i+1) begin
              game_area_newblock[i] <= game_area_backup[i];
            end
          end else begin // Successful rotate
            gamestate <= STATE_MOVING;
            framebuffer_game_update <= 1;
          end
        end
      end
    endcase
  end
end

// Addressing Gamepspace
wire [4:0] game_area_lcd_addr;
reg [11:0] game_area_lcd_data;
wire [4:0] game_area_vga_addr;
reg [11:0] game_area_vga_data;

// Supply data from gamespace to LCD & VGA
always @ (posedge clk)
begin
  if(rst) begin
    game_area_lcd_data <= 0;
    game_area_vga_data <= 0;
  end else begin
    // Supply data to LCD
    if(game_area_lcd_addr >= cntr_top && (game_area_lcd_addr-cntr_top)<4)
      game_area_lcd_data <= game_area[game_area_lcd_addr] | game_area_newblock[game_area_lcd_addr-cntr_top];
    else
      game_area_lcd_data <= game_area[game_area_lcd_addr];
    // Supply data to VGA
    if(gamestate != STATE_LOGO) begin
      if(game_area_vga_addr >= cntr_top && (game_area_vga_addr-cntr_top)<4)
        game_area_vga_data <= game_area[game_area_vga_addr] | game_area_newblock[game_area_vga_addr-cntr_top];
      else
        game_area_vga_data <= game_area[game_area_vga_addr];
    end else begin // Logo graphics
      if(game_area_vga_addr >= 0 && game_area_vga_addr < 10)
        game_area_vga_data <= 0;
      else if(game_area_vga_addr >= 10 && game_area_vga_addr < 16)
        game_area_vga_data <= game_area_init[game_area_vga_addr-10];
      else if(game_area_vga_addr >= 16 && game_area_vga_addr < 20)
        game_area_vga_data <= 12'hFFF;
    end
  end
end

// Frame buffer - LCD IF wiring
wire [9:0] lcdif_framebuff_addr;
wire [7:0] lcdif_framebuff_out;
wire lcdif_framebuff_update;
frame_buffer frameBuffer (
  .clk(clk), 
  .rst(rst), 
  .frame_out(lcdif_framebuff_out), 
  .frame_addr(lcdif_framebuff_addr), 
  .game_area_data(game_area_lcd_data),
  .game_area_addr(game_area_lcd_addr),
  .gamestate(gamestate),
  .update_buffer(framebuffer_game_update),
  .update_lcd(lcdif_framebuff_update)
);

// Command FIFO - LCD interface wiring
wire [8:0] cmd_lcdif_data;
wire cmd_lcdif_we;
wire cmd_lcdif_full;
// LCD IF
lcd_if lcdIF (
  .clk(clk), 
  .rst(rst), 
  .frame_addr(lcdif_framebuff_addr), 
  .frame_update(lcdif_framebuff_update), 
  .frame_din(lcdif_framebuff_out), 
  .cmd_full(cmd_lcdif_full), 
  .cmd_dout(cmd_lcdif_data), 
  .cmd_wr_en(cmd_lcdif_we)
);

// VGA Interface
vga vgaIF (
  .clk(clk),
  .rst(rst),
  .game_state(gamestate),
  .game_area_data(game_area_vga_data),
  .game_area_addr(game_area_vga_addr),
  .game_block_next(building_blocks[next_block_id]),
  .game_points(gamepoints),
  .game_lines(gamelines),
  .game_level(gamespeed),
  .vga_hs(vga_hs), 
  .vga_vs(vga_vs), 
  .vga_red(vga_red), 
  .vga_green(vga_green), 
  .vga_blue(vga_blue)
);

// SPI - CMD FIFO connecting wires
wire spi_cmd_rd;
wire [8:0] spi_cmd_dout;
wire spi_cmd_empty;
//Command Fifo
cmd_fifo cmdFifo (
  .clk(clk),
  .srst(rst), 
  .din(cmd_lcdif_data),
  .wr_en(cmd_lcdif_we),
  .full(),
  .rd_en(spi_cmd_rd), 
  .dout(spi_cmd_dout),
  .empty(spi_cmd_empty), 
  .almost_empty(),
  .almost_full(cmd_lcdif_full)
);

// SPI Interface
spi spi (
  .clk(clk), 
  .rst(rst), 
  .spi_sdcard_csn(spi_sdcard_csn), 
  .spi_flash_csn(spi_flash_csn), 
  .spi_lcd_csn(spi_lcd_csn), 
  .spi_clk(spi_clk), 
  .spi_mosi(spi_mosi), 
  .spi_datacommand(spi_miso), 
  .cmd_empty(spi_cmd_empty), 
  .cmd_din(spi_cmd_dout), 
  .cmd_rd(spi_cmd_rd)
);

// PRBS
prbs prbs (
  .clk(clk), 
  .rst(rst), 
  .dout(game_prbs),
  .new()
);

// Rategen
rategen rategen (
  .clk(clk), 
  .rst(rst), 
  .en(action_fall),
  .speed(gamespeed),
  .drop(action_drop)
);

// PS/2 interface
wire [7:0] ps2_debug;
ps2 ps2IF (
  .clk(clk), 
  .rst(rst), 
  .ps2_clk(ps2_clk), 
  .ps2_data(ps2_data), 
  .buttons(buttons_ps2),
  .ps2_debug(ps2_debug)
);

// CPLD Interface
cpld_if cpldIF (
  .clk(clk), 
  .rst(rst), 
  .num(gamestate == STATE_LOGO?gamespeed:gamelines[7:0]), 
  .buttons(buttons_cpld), 
  .cpld_rstn(cpld_rstn), 
  .cpld_clk(cpld_clk), 
  .cpld_load(cpld_load), 
  .cpld_mosi(cpld_mosi), 
  .cpld_miso(cpld_miso)
);

// Note player
noteplayer notePlayer (
  .clk(clk), 
  .rst(rst), 
  .en(action_music), 
  .pwm_out(pwm_out),
  .speed(gamespeed)
);

endmodule