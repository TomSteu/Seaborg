#ifndef WSTP_CONNECTION_H
#define WSTP_CONNECTION_H

#ifdef MATHLINK

#include <mathlink.h>
#define LINKPREFIXLINK MLINK
#define LINKPREFIXENV MLENV

#else

#include <wstp.h>
#define LINKPREFIXLINK WSLINK
#define LINKPREFIXENV WSENV

#endif

typedef struct {
	int active;
	LINKPREFIXLINK link;
	LINKPREFIXENV env;
} WstpConnection;

void* init_connection(const char*);

void close_connection(void*);

int abort_calculation(void*);

char* handle_link_error(void*);

void evaluate(void* con, const char* input, void (*callback)(char*));

#endif // header guard