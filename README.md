Seaborg
=======

Seaborg is meant as an alternative notebook interface for the Mathematica kernel, using GTK+3.

## Requirements
Seaborg is written in Vala and hence requires a running version of valac to transcompile into C code. Furthermore GTK+ 3.22 or later and all its dependencies are required, as well as librsvg and gtksourceview. 

## Installation

### Ubuntu

Install dependencies and build tools:
```
sudo apt install build-essential git valac libgtksourceview-3.0-dev librsvg2-dev
```

Find a place for the installation, and then clone the repository
```
git clone https://github.com/TomSteu/Seaborg
```

In order to establish a connection the mathematica kernel, you need to build against the WTSP link library (former MathLink). In order to do so, you must edit the Makefile and set:
* the variable `WSTPLIBDIR` to the parent directory of the WSTP dynamic link library
* the variable `WSTPINCDIR` to the parent directory of the wstp.h header
* the variable `WSTPLIB` to the name of the WSTP dynamic link library

If you use an older version of mathematica, the connection protocol and all files are called MathLink instead. You can still build in this case, but include the option `-DMATHLINK` to `CFLAGS`.

After finishing to edit the Makefile, you may build the code:
```
make all
```

You may add the launch script via:
```
sudo make install-linux
```