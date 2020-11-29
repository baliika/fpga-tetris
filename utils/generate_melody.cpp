// Generate the note player melody and DDS phase increment
// table, such that:
// - the first 128 bytes are devoted to the melody
//   (i.e. between 0x00-0x7F)
// - the rest of the block RAM is used for the phase increments
//   (i.e. between 0x80-0xFF)

#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <vector>
#include <cmath>
#include <unordered_map>

static int add_melody(std::ofstream & coe) {
  std::ifstream melody("data/melody.txt",std::ios::in);
  std::unordered_map<std::string,int> notes{
             {"C0",0},
             {"C#0",1},
             {"D0",2},
             {"E0",3},
             {"F0",4},
             {"G0",5},
             {"A0",6},
             {"B0",7},
             {"C1",8},
             {"C#1",9},
             {"D1",10},
             {"S",11},
             {"X",12}};
  std::size_t bytes_used = 0;
  while(!melody.eof()) {
    std::string melody_line;
    std::getline(melody,melody_line);
    if(melody_line[0] != '-') {
      std::size_t delimiter_pos = melody_line.find(" ");
      if(delimiter_pos == std::string::npos) {
          throw std::runtime_error("Unexpected input");
      }
      int note = notes[melody_line.substr(0, delimiter_pos)];
      int length = static_cast<int>(std::stod(melody_line.substr(delimiter_pos+1))/0.25 - 1.0);
      int binary = note | (length << 4);
      coe << std::setfill('0') << std::setw(2) << std::hex << binary << "\r\n";
      ++bytes_used;
    }
  }
  melody.close();
  std::cout << bytes_used << std::endl;
  return bytes_used;
}

static void add_phase_increments(std::ofstream & coe) {
  const double f_clk = 50000000.0;
  const double f_sampling = f_clk / 2048.0;
  const double f_resolution = static_cast<double>(1<<16);
  std::vector<double> notes{261.6,277.2,293.7,329.6,349.2,392.0,440.0,466.2,523.3,554.4,587.3};
  for(auto & note : notes) {
    const int increment = static_cast<int>(round(note * f_resolution / f_sampling));
    if(note != notes[0]) coe << "\r\n";
    coe << std::hex << increment;
  }
}

int main(int argc, char * argv[]) {
  (void)argc;
  (void)argv;
  std::ofstream coe("note_brom.coe",std::ios::out|std::ios::trunc);
  coe << "memory_initialization_radix = 16;\r\n"
         "memory_initialization_vector = \r\n";
  // Melody
  const int bytes_used = add_melody(coe);
  // Padding between Melody and the Phase register increments
  for(int i=0;i<(128-bytes_used);++i) {
    coe << "00\r\n";
  }
  // Phase register increments
  add_phase_increments(coe);
  coe << ";";
  coe.close();
  return 0;
}