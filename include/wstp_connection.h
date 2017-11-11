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

WstpConnection init_connection(const char*);

void close_connection(WstpConnection*);

int abort_calculation(WstpConnection*);

char* handle_link_error(WstpConnection*);

void evaluate(WstpConnection* connection, const char* input, void (*callback)(char*));

#endif // header guard