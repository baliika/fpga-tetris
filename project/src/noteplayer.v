`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Module Name:   noteplayer 
// Project Name:  Tetris Game
// Description:   Note player: it supplies the melody of the Tetris game via a
//                piezoelectric buzzer. The melody speeds up as the game difficulty
//                is increased.
//
//////////////////////////////////////////////////////////////////////////////////
module noteplayer(
  input clk,
  input rst,
  input en,
  input [3:0] speed,
  output pwm_out
);

// BPM compare
parameter BPM_CMP_GAMESPEED_1 = 5000000-1;
parameter BPM_CMP_GAMESPEED_2 = 4750000-1;
parameter BPM_CMP_GAMESPEED_3 = 4500000-1;
parameter BPM_CMP_GAMESPEED_4 = 4250000-1;
parameter BPM_CMP_GAMESPEED_5 = 4000000-1;
parameter BPM_CMP_GAMESPEED_6 = 3750000-1;
parameter BPM_CMP_GAMESPEED_7 = 3500000-1;
parameter BPM_CMP_GAMESPEED_8 = 3250000-1;
parameter BPM_CMP_GAMESPEED_9 = 3000000-1;

reg [22:0] bpm_compare;
always @ (*)
begin
  case(speed)
    1: bpm_compare <= BPM_CMP_GAMESPEED_1;
    2: bpm_compare <= BPM_CMP_GAMESPEED_2;
    3: bpm_compare <= BPM_CMP_GAMESPEED_3;
    4: bpm_compare <= BPM_CMP_GAMESPEED_4;
    5: bpm_compare <= BPM_CMP_GAMESPEED_5;
    6: bpm_compare <= BPM_CMP_GAMESPEED_6;
    7: bpm_compare <= BPM_CMP_GAMESPEED_7;
    8: bpm_compare <= BPM_CMP_GAMESPEED_8;
    9: bpm_compare <= BPM_CMP_GAMESPEED_9;
    default: bpm_compare <= BPM_CMP_GAMESPEED_1;
  endcase
end

// Creating sampling frequency (fs)
reg [10:0] f_cntr;
always @ (posedge clk)
begin
  if(rst) f_cntr <= 0;
  else f_cntr <= f_cntr +1;
end
wire f_sample;
assign f_sample = (f_cntr==11'b01111111111); //24.414kHz

// Creating note frequency
reg [22:0] bpm_cntr;
wire bpm;
always @ (posedge clk)
begin
  if(rst || bpm) bpm_cntr <= 0;
  else bpm_cntr <= bpm_cntr + 1;
end
assign bpm = (bpm_cntr >= bpm_compare);

// Melody player
reg [7:0] melody_cntr;
reg [4:0] note_cntr;
reg [10:0] note_inc;
wire [10:0] note_next;
wire [7:0] note_inc_addr;
wire [10:0] note_inc_wire;
assign note_inc_addr = {4'b1000,note_next[3:0]};

// Note table
//  C   261.6 Hz > 0
//  C#  277.2 Hz > 1
//  D   293.7 Hz > 2
//  E   329.6 Hz > 3
//  F   349.2 Hz > 4
//  G   392.0 Hz > 5
//  A   440.0 Hz > 6
//  B   466.2 Hz > 7
//  C   523.3 Hz > 8
//  C#  554.4 Hz > 9
//  D   587.3 Hz > 10
parameter NOTE_BREAK = 11;
parameter NOTE_END = 12;

// Melody table
// 0 > ...
noteBRAM noteROM (
  .clka(clk),
  .addra(melody_cntr),
  .douta(note_next),
  .clkb(clk),
  .addrb(note_inc_addr),
  .doutb(note_inc_wire)
);
always @ (posedge clk)
begin
  if(rst || ~en) begin
    melody_cntr <= 0;
    note_cntr <= 0;
    note_inc <= 0;
  end else if(bpm) begin
    if(note_cntr == 31) begin
      if(note_next[3:0] == NOTE_BREAK) begin
        melody_cntr <= melody_cntr + 1;
        note_inc <= 0;
      end else if(note_next[3:0] == NOTE_END) begin
        melody_cntr <= 0;
        note_inc <= 0;
      end else begin
        melody_cntr <= melody_cntr + 1;
        note_inc <= note_inc_wire;
      end
      note_cntr <= note_next[7:4];
    end else begin
      note_cntr <= note_cntr-1;
    end
  end
end

// PWM Square wave
reg [15:0] phase_register; // 16-bit sampling resolution
always @ (posedge clk)
begin
  if(rst) begin
    phase_register <= 0;
  end else if(f_sample) begin
    phase_register <= phase_register+note_inc;
  end
end
// 50% duty cycle square wave OR zero
assign pwm_out = ((note_inc!=0)?(phase_register[15]&f_cntr[0]):0);

endmodule