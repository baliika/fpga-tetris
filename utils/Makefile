# Generate data files for the FPGA Tetris game
CXX=g++
CXX_FLAGS=-std=c++11 -O3 -Wall -Wextra -Werror -Wfatal-errors
CXX_DEFINES=

all: 
	${CXX} ${CXX_FLAGS} ${CXX_DEFINES} generate_colors.cpp -o generate_colors
	${CXX} ${CXX_FLAGS} ${CXX_DEFINES} generate_graphics.cpp -o generate_graphics
	${CXX} ${CXX_FLAGS} ${CXX_DEFINES} generate_melody.cpp -o generate_melody

clean:
	rm -rf generate_colors
	rm -rf generate_graphics
	rm -rf generate_melody
	rm -rf *.coe
	rm -rf *.html