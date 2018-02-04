### MODIFY ###

CC=gcc
CCFLAGS= #-O3 -w 
WSTPDIR=/usr/local/Wolfram/Mathematica/11.2/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions/
WSTPLIB=WSTP64i4

### DO NOT MODIFY ###

.PHONY: all
all: wstp_connection.o vala
	$(CC) $(CCFLAGS) `pkg-config --cflags gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo` -c ./build/src/cell.c -o ./build/cell.o `pkg-config --libs gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo`
	$(CC) $(CCFLAGS) `pkg-config --cflags gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo` -c ./build/src/gui.c -o ./build/gui.o `pkg-config --libs gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo`
	$(CC) $(CCFLAGS) `pkg-config --cflags gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo` -c ./build/src/string.c -o ./build/string.o `pkg-config --libs gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo`
	$(CC) $(CCFLAGS) `pkg-config --cflags gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo` -c ./build/src/parameter.c -o ./build/parameter.o `pkg-config --libs gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo`
	$(CC) $(CCFLAGS) -L$(WSTPDIR)  ./build/cell.o ./build/gui.o ./build/string.o ./build/parameter.o ./build/wstp_connection.o -o ./bin/seaborg `pkg-config --libs gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo` -l$(WSTPLIB)
	
.PHONY: vala
vala:
	valac --thread ./src/gui.vala ./src/cell.vala ./src/string.vala ./src/parameter.vala -d ./build/ -C --pkg gtk+-3.0 --pkg gtksourceview-3.0 --pkg gdk-3.0 --pkg glib-2.0 --pkg libxml-2.0 --pkg librsvg-2.0 --pkg cairo

wstp_connection.o: 
	$(CC) $(CCFLAGS) -c ./src/wstp_connection.c -o ./build/wstp_connection.o -I./include/ -I$(WSTPDIR) 

.PHONY: clean
clean:
	rm ./build/wstp_connection.o

.PHONY: run
run:
	LD_LIBRARY_PATH=$(WSTPDIR):$(LD_LIBRARY_PATH) ./bin/seaborg