#ifndef WSTP_CONNECTION_H
#define WSTP_CONNECTION_H

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
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

int check_connection(void* con);

int try_abort(void* con);

int try_reset_after_abort(void* con);

void* init_connection(const char* path);

void close_connection(void*);

int abort_calculation(void*);

const char* handle_link_error(void*);

void evaluate(void* con, const char* input, void (*callback)(char*, void*), void* callback_data);

#endif // header guard