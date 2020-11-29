// Generate the initialization data for the FPGA
// block RAMs, containing the graphics to be displayed:
// - VGA title
// - VGA numbers
// - VGA help
// - VGA statistics
// - SPI LCD logo

#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>

static void create_coe(const char * output_filename,
                       const std::vector<const char*> & input_filenames,
                       const bool direct=false) {
  std::ofstream coe(output_filename,std::ios::out|std::ios::trunc);
  coe << "memory_initialization_radix = 16;\r\n"
         "memory_initialization_vector = ";
  if(direct) coe << "\r\n";
  for(const char * filename : input_filenames) {
    std::ifstream csv(filename,std::ios::in);
    while(!csv.eof()) {
      std::string csv_line;
      csv >> csv_line;
      const char * csv_line_c = csv_line.c_str();
      const char * ptr = csv_line_c;
      for(std::size_t i=0;i<csv_line.length();++i) {
        if(!direct && (csv_line_c[i]==',' || (i+1) == csv_line.length())) {
          // Conversion
          int number = atoi(ptr);
          coe << "\r\n";
          switch(number) {
            case 0:
              coe << 0;
              break;
            case 85:
              coe << 1;
              break;
            case 170:
              coe << 2;
              break;
            case 255:
              coe << 3;
              break;
            default:
              throw std::runtime_error("Unexcepted input data");
              break;
          }
          ptr = csv_line_c + i + 1;
        } else if(direct) {
          // No conversion
          if(csv_line_c[i]==',')
            coe << "\r\n";
          else if(csv_line_c[i]!=' ')
            coe << csv_line_c[i];
        }
      }
    }
    csv.close();
  }
  coe << ";";
  coe.close();
}

int main(int argc, char * argv[]) {
  (void)argc;
  (void)argv;
  create_coe("title_brom.coe",{"data/title.csv"});
  create_coe("stats_brom.coe",{"data/stats.csv"});
  create_coe("help_brom.coe",{"data/help.csv"});
  create_coe("numbers_brom.coe",{"data/numbers/0.csv",
                                 "data/numbers/1.csv",
                                 "data/numbers/2.csv",
                                 "data/numbers/3.csv",
                                 "data/numbers/4.csv",
                                 "data/numbers/5.csv",
                                 "data/numbers/6.csv",
                                 "data/numbers/7.csv",
                                 "data/numbers/8.csv",
                                 "data/numbers/9.csv"});
  create_coe("spi_logo_brom.coe",{"data/spi_logo.csv"},true);
  return 0;
}