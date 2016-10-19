CXXFLAGS = -Wall -Werror -std=c++11 -I./lua/src/lua

SRC = ftoken.cpp
# use obj files for C++ objects
OBJS = $(SRC:.cpp=.obj)

.PHONY: default
default: $(OBJS)

%.obj: %.cpp
	$(CXX) $< -o $@ $(CXXFLAGS)

clean:
	rm -f $(OBJS)
