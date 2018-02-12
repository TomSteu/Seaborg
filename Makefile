### MODIFY ###

CC=gcc
CCFLAGS= #-O3 -w 
WSTPDIR=/usr/local/Wolfram/Mathematica/11.2/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions/
WSTPLIB=WSTP64i4

### DO NOT MODIFY ###

VALADEP=gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo

.PHONY: all
all: wstp_connection.o ./build/gui.o ./build/interfaces.o ./build/idgenerator.o ./build/notebook.o ./build/cellcontainer.o ./build/evaluationcell.o ./build/textcell.o ./build/addbutton.o ./build/contextmenu.o ./build/plotframe.o ./build/parameter.o ./build/string.o
	$(CC) $(CCFLAGS) -L$(WSTPDIR)  ./build/gui.o ./build/interfaces.o ./build/idgenerator.o ./build/notebook.o ./build/cellcontainer.o ./build/evaluationcell.o ./build/textcell.o ./build/addbutton.o ./build/contextmenu.o ./build/plotframe.o ./build/parameter.o ./build/string.o ./build/wstp_connection.o -o ./bin/seaborg `pkg-config --libs $(VALADEP)` -l$(WSTPLIB)

./build/gui.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/gui.c -o ./build/gui.o `pkg-config --libs $(VALADEP)`

./build/interfaces.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/interfaces.c -o ./build/interfaces.o `pkg-config --libs $(VALADEP)`

./build/idgenerator.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/idgenerator.c -o ./build/idgenerator.o `pkg-config --libs $(VALADEP)`

./build/notebook.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/notebook.c -o ./build/notebook.o `pkg-config --libs $(VALADEP)`

./build/cellcontainer.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/cellcontainer.c -o ./build/cellcontainer.o `pkg-config --libs $(VALADEP)`

./build/evaluationcell.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/evaluationcell.c -o ./build/evaluationcell.o `pkg-config --libs $(VALADEP)`

./build/textcell.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/textcell.c -o ./build/textcell.o `pkg-config --libs $(VALADEP)`

./build/addbutton.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/addbutton.c -o ./build/addbutton.o `pkg-config --libs $(VALADEP)`

./build/contextmenu.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/contextmenu.c -o ./build/contextmenu.o `pkg-config --libs $(VALADEP)`

./build/plotframe.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/plotframe.c -o ./build/plotframe.o `pkg-config --libs $(VALADEP)`

./build/parameter.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/parameter.c -o ./build/parameter.o `pkg-config --libs $(VALADEP)`

./build/string.o: vala
	$(CC) $(CCFLAGS) `pkg-config --cflags $(VALADEP)` -c ./build/src/string.c -o ./build/string.o `pkg-config --libs $(VALADEP)`
	
.PHONY: vala
vala:
	valac --thread ./src/gui.vala ./src/interfaces.vala ./src/notebook.vala ./src/cellcontainer.vala  ./src/evaluationcell.vala  ./src/textcell.vala  ./src/addbutton.vala ./src/contextmenu.vala  ./src/plotframe.vala  ./src/idgenerator.vala  ./src/string.vala ./src/parameter.vala -d ./build/ -C --pkg gtk+-3.0 --pkg gtksourceview-3.0 --pkg gdk-3.0 --pkg glib-2.0 --pkg libxml-2.0 --pkg librsvg-2.0 --pkg cairo

wstp_connection.o: 
	$(CC) $(CCFLAGS) -c ./src/wstp_connection.c -o ./build/wstp_connection.o -I./include/ -I$(WSTPDIR) 

.PHONY: clean
clean:
	rm ./build/*.o

.PHONY: run
run:
	LD_LIBRARY_PATH=$(WSTPDIR):$(LD_LIBRARY_PATH) ./bin/seaborg