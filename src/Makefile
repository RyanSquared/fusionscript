CXXFLAGS = -Wall -Werror -std=c++11

SRC = ftoken.cpp
# use obj files for C++ objects
OBJS = $(SRC:.cpp=.obj)

.PHONY: default
default: $(OBJS)

%.obj: %.cpp
	$(CXX) $< -o $@

clean:
	rm -f $(OBJS)
