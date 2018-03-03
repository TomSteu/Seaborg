### MODIFY ###


# Compiler and flags

CC=gcc
CFLAGS= -O3 -w
VALAC= valac
VALAFLAGS= --thread

# dependencies Mathematica WSTP / Mathlink libraries

WSTPDIR=/usr/local/Wolfram/Mathematica/11.2/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions/
WSTPLIB=WSTP64i4

# dependencies

VALADEP=gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo
VALAPKG=--pkg gtk+-3.0 --pkg gtksourceview-3.0 --pkg gdk-3.0 --pkg glib-2.0 --pkg libxml-2.0 --pkg librsvg-2.0 --pkg cairo



### DO NOT MODIFY ###

VALASRC = gui interfaces parameter string notebook cellcontainer idgenerator evaluationcell textcell addbutton contextmenu plotframe stack 

CSRC= wstp_connection

.PRECIOUS: ./build/src/%.c

.PHONY: all
all: $(patsubst %,./build/vala/%.o,$(VALASRC)) $(patsubst %,./build/%.o,$(CSRC))
	$(CC) $(CFLAGS) -L$(WSTPDIR) $^ -o ./bin/seaborg `pkg-config --libs $(VALADEP)` -l$(WSTPLIB)

./build/%.o: ./src/%.c
	$(CC) $(CFLAGS) -c $^ -o $@ -I./include/ -I$(WSTPDIR)

./build/vala/%.o: ./build/src/%.c
	$(CC) $(CFLAGS) `pkg-config --cflags $(VALADEP)` -c $^ -o $@ `pkg-config --libs $(VALADEP)`

./build/src/%.c: vala
	touch $@

.PHONY: vala
vala: $(patsubst %,./src/%.vala,$(VALASRC))
	$(VALAC) $(VALAFLAGS) $^ -d ./build -C $(VALAPKG)

.PHONY: clean
clean:
	rm -f ./build/vala/*.o
	rm -f ./build/src/*.c
	rm -f ./build/*.o
	rm -f ./bin/*
