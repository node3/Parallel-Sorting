# Creating a static library
TARGET = mysort 

# Libraries to use, objects to compile
SRCS = mysort.cpp pthread_sort.cpp cudasort.cu
SRCS_FILES = $(foreach F, $(SRCS), ./$(F))
#OBJS=$(SRCS:.c*=.o)
#COMMON_FILES = ./common/src/AOCL_Utils.cpp
CXX_FLAGS = -lpthread -lm -O3 -g -lcuda -lcudart

# Make it all!
all : mysort.o pthread_sort.o cudasort.o
#	nvcc  $(CXX_FLAGS) $(SRCS_FILES) $(COMMON_FILES) -c
	nvcc $(CXX_FLAGS) mysort.o pthread_sort.o cudasort.o -o $(TARGET)

mysort.o: mysort.cpp 
	nvcc $(CXX_FLAGS) mysort.cpp -c 
    
pthread_sort.o: pthread_sort.cpp 
	nvcc $(CXX_FLAGS) pthread_sort.cpp -c
    
cudasort.o: cudasort.cu 
	nvcc $(CXX_FLAGS) cudasort.cu -c

# Standard make targets
clean :
	@rm -f *.o $(TARGET)
