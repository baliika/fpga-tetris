// Generate a HTML displaying the possible colors
// using only 2-2-2 bits per color channel

#include <iostream>
#include <iomanip>
#include <fstream>

int main(int argc, char * argv[]) {
  (void)argc;
  (void)argv;
  std::ofstream html("colors.html",std::ios::out|std::ios::trunc);
  html << "<html><head><style>"
          "body { background-color:#000000; }"
          "table td { border: 1px solid #ffffff; width:30px; height:30px;}"
          "</style></head><body>"
          "<table>";
  int bits[4]={0,85,170,255};
  for(int r=0;r<4;++r) {
    html << "<tr>";
    for(int g=0;g<4;++g) {
      for(int b=0;b<4;++b) {
        html << "<td style=\"background-color:#";
        html << std::setfill('0') << std::setw(2) << std::hex << bits[r];
        html << std::setfill('0') << std::setw(2) << std::hex << bits[g];
        html << std::setfill('0') << std::setw(2) << std::hex << bits[b];
        html << "\"></td>";
      }
    }
    html << "</tr>";
  }
  html << "</table></body>";
  html.close();
  return 0;
}