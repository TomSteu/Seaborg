### MODIFY ###

CC=gcc
CCFLAGS= -O3 -w
WSTPDIR=/usr/local/Wolfram/Mathematica/11.1/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions/
WSTPLIB=WSTP64i4

### DO NOT MODIFY ###

.PHONY: all
all: wstp_connection.o vala
	$(CC) $(CCFLAGS) `pkg-config --cflags gtk+-3.0 gtksourceview-3.0` -c ./build/src/cell.c -o ./build/cell.o `pkg-config --libs gtk+-3.0 gtksourceview-3.0`
	$(CC) $(CCFLAGS) `pkg-config --cflags gtk+-3.0 gtksourceview-3.0` -c ./build/src/gui.c -o ./build/gui.o `pkg-config --libs gtk+-3.0 gtksourceview-3.0`
	$(CC) $(CCFLAGS) -L$(WSTPDIR)  ./build/cell.o ./build/gui.o ./build/wstp_connection.o -o ./bin/seaborg `pkg-config --libs gtk+-3.0 gtksourceview-3.0` -l$(WSTPLIB)
	
.PHONY: vala
vala:
	valac --thread ./src/gui.vala ./src/cell.vala -d ./build/ -C --pkg gtk+-3.0 --pkg gtksourceview-3.0

wstp_connection.o: 
	$(CC) $(CCFLAGS) -c ./src/wstp_connection.c -o ./build/wstp_connection.o -I./include/ -I$(WSTPDIR) 

.PHONY: clean
clean:
	rm ./build/wstp_connection.o

.PHONY: run
run: 
	LD_LIBRARY_PATH=$(WSTPDIR):$(LD_LIBRARY_PATH) ./bin/seaborg