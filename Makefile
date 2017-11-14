### MODIFY ###

CC=gcc
CCFLAGS= -O3 -w
WSTPDIR=  /usr/local/Wolfram/Mathematica/11.1/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions
VALAC=valac
VALAFLAGS=

### DO NOT MODIFY ###

wstp_connection.o: 
	$(CC) $(CCFLAGS) -c ./src/wstp_connection.c -o ./build/wstp_connection.o -I./include/ -I$(WSTPDIR) 

.PHONY: all
all: wstp_connection.o
	
.PHONY: vala
vala:
	$(VALAC) $(VALAFLAGS) ./src/gui.vala ./src/cell.vala -C --pkg gtk+-3.0 --pkg gtksourceview-3.0

.PHONY: clean
clean:
	rm ./build/wstp_connection.o

.PHONY: test
test: 
	$(VALAC) $(VALAFLAGS) ./src/gui.vala ./src/cell.vala -o ./bin/seaborg  --pkg gtk+-3.0 --pkg gtksourceview-3.0
	./bin/seaborg