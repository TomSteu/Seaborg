##### MODIFY #####


### Compiler and flags ###

CC=gcc
CFLAGS= -O3 -w
VALAC= valac
VALAFLAGS= --thread


### Mathematica WSTP (former MathLink) libraries ###
# if the file is called mathlink rather than wstp, append -DMATHLINK to CFLAGS

# directory of WSTP library file
WSTPLIBDIR=/usr/local/Wolfram/Mathematica/11.2/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions/

# directory of wstp.h / mathlink.h file 
WSTPINCDIR=/usr/local/Wolfram/Mathematica/11.2/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions/

# name of library file
WSTPLIB=WSTP64i4


### Dependencies ###

# packages required by valac
VALAPKG= --pkg gtk+-3.0 --pkg gtksourceview-3.0 --pkg gdk-3.0 --pkg glib-2.0 --pkg libxml-2.0 --pkg librsvg-2.0 --pkg cairo

# include directories for C compilation
DEPINC= `pkg-config --cflags gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo`

# library list for C compilation
DEPLIBS= `pkg-config --libs gtk+-3.0 gtksourceview-3.0 gdk-3.0 glib-2.0 libxml-2.0 librsvg-2.0 cairo`



##### DO NOT MODIFY #####

VALASRC = gui interfaces parameter string notebook cellcontainer idgenerator evaluationcell textcell addbutton contextmenu plotframe stack 
CSRC= wstp_connection

.PRECIOUS: ./build/src/%.c

.PHONY: all
all: $(patsubst %,./build/vala/%.o,$(VALASRC)) $(patsubst %,./build/%.o,$(CSRC))
	$(CC) $(CFLAGS) -L$(WSTPLIBDIR) $^ -o ./bin/seaborg $(DEPLIBS) -l$(WSTPLIB)

./build/%.o: ./src/%.c
	$(CC) $(CFLAGS) -c $^ -o $@ -I./include/ -I$(WSTPINCDIR)

./build/vala/%.o: ./build/src/%.c
	$(CC) $(CFLAGS) $(DEPINC) -c $^ -o $@ $(DEPLIBS)

./build/src/%.c: vala
	touch $@

.PHONY: vala
vala: $(patsubst %,./src/%.vala,$(VALASRC))
	$(VALAC) $(VALAFLAGS) $^ -d ./build -C $(VALAPKG)

.PHONY: install-linux
install-linux:	
	printf '#!/bin/sh\ncd %s\nLD_LIBRARY_PATH=%s ./bin/seaborg' "$(shell pwd)" "$(WSTPLIBDIR)" > /usr/bin/seaborg
	chmod a+x /usr/bin/seaborg

.PHONY: clean
clean:
	rm -f ./build/vala/*.o
	rm -f ./build/src/*.c
	rm -f ./build/*.o
	rm -f ./bin/*
