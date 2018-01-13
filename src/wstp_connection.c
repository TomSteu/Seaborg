#include "wstp_connection.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>


#ifdef MATHLINK

#include "mathlink.h"
#define LINKPREFIXLINK MLINK
#define LINKPREFIXENV MLENV
#define LINKPREFIXINITIALIZE(X) MLInitialize(X) 
#define LINKPREFIXENVIRONMENTPARAMETER MLEnvironmentParameter
#define LINKPREFIXOPENSTRING(X, Y, Z) MLOpenString(X, Y, Z)
#define LINKPREFIXACTIVATE(X) MLActivate(X)
#define LINKPREFIXPUTMESSAGE(X,Y) MLPutMessage(X,Y)
#define LINKPREFIXPUTFUNCTION(X,Y,Z) MLPutFunction(X,Y,Z)
#define LINKPREFIXPUTSTRING(X,Y) MLPutString(X,Y)
#define LINKPREFIXCLOSE(X) MLClose(X)
#define LINKPREFIXDEINITIALIZE(X) MLDeinitialize(X)
#define LINKPREFIXTERMINATEMESSAGE MLTerminateMessage
#define LINKPREFIXABORTMESSAGE MLAbortMessage
#define LINKPREFIXERROR(X) MLError(X)
#define LINKPREFIXEOK MLEOK
#define LINKPREFIXERRORMESSAGE(X) MLErrorMessage(X)
#define LINKPREFIXRELEASEERRORMESSAGE(X,Y) MLReleaseErrorMessage(X,Y)
#define LINKPREFIXCLEARERROR(X) MLClearError(X)
#define LINKPREFIXENDPACKET(X) MLEndPacket(X)
#define LINKPREFIXFLUSH(X) MLFlush(X)
#define LINKPREFIXREADY(X) MLReady(X)
#define LINKPREFIXNEXTPACKET(X) MLNextPacket(X)
#define LINKPREFIXGETSTRING(X,Y) MLGetString(X,Y)
#define LINKPREFIXRELEASESTRING(X,Y) MLReleaseString(X,Y)

#define LINKPREFIXERRORTYPE int

#else

#include "wstp.h"
#define LINKPREFIXLINK WSLINK
#define LINKPREFIXENV WSENV
#define LINKPREFIXINITIALIZE(X) WSInitialize(X) 
#define LINKPREFIXENVIRONMENTPARAMETER WSEnvironmentParameter
#define LINKPREFIXOPENSTRING(X,Y,Z) WSOpenString(X,Y,Z)
#define LINKPREFIXACTIVATE(X) WSActivate(X)
#define LINKPREFIXPUTMESSAGE(X,Y) WSPutMessage(X,Y)
#define LINKPREFIXPUTFUNCTION(X,Y,Z) WSPutFunction(X,Y,Z)
#define LINKPREFIXPUTSTRING(X,Y) WSPutString(X,Y)
#define LINKPREFIXCLOSE(X) WSClose(X)
#define LINKPREFIXDEINITIALIZE(X) WSDeinitialize(X)
#define LINKPREFIXTERMINATEMESSAGE WSTerminateMessage
#define LINKPREFIXABORTMESSAGE WSAbortMessage
#define LINKPREFIXERROR(X) WSError(X)
#define LINKPREFIXEOK WSEOK
#define LINKPREFIXERRORMESSAGE(X) WSErrorMessage(X)
#define LINKPREFIXRELEASEERRORMESSAGE(X,Y) WSReleaseErrorMessage(X,Y)
#define LINKPREFIXCLEARERROR(X) WSClearError(X)
#define LINKPREFIXENDPACKET(X) WSEndPacket(X)
#define LINKPREFIXFLUSH(X) WSFlush(X)
#define LINKPREFIXREADY(X) WSReady(X)
#define LINKPREFIXNEXTPACKET(X) WSNextPacket(X)
#define LINKPREFIXGETSTRING(X,Y) WSGetString(X,Y)
#define LINKPREFIXRELEASESTRING(X,Y) WSReleaseString(X,Y)
#if WSINTERFACE > 4
#define LINKPREFIXERRORTYPE long
#else
#define LINKPREFIXERRORTYPE int
#endif


#endif

int check_connection(void* con) {
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return -1;
	return connection->active;
}

int try_abort(void* con) {
	
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return -1;

	if(connection->active == 1) {
		connection->active=2;
	}

	return connection->active;

}

int try_reset_after_abort(void* con) {

	WstpConnection* connection = (WstpConnection*) con;
	
	if(!connection)
		return -1;

	if(connection->active==2) connection->active = 1;

	return connection->active;
}

void* init_connection(const char* path) {
	
	LINKPREFIXERRORTYPE error = 0;
	
	WstpConnection* connection = (WstpConnection*) malloc(sizeof(WstpConnection));
	connection->active = 0;

	connection->env = LINKPREFIXINITIALIZE((LINKPREFIXENVIRONMENTPARAMETER)0);
	if((LINKPREFIXENV)0 == connection->env) return (void*)connection;

	connection->link = LINKPREFIXOPENSTRING(connection->env, path, &error);
	if(!connection->link || error != LINKPREFIXEOK) return (void*)connection;
	if(! LINKPREFIXACTIVATE(connection->link))  return (void*)connection;
	connection->active=1;

	return (void*)connection;

}

void close_connection(void* con) {
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return;
	LINKPREFIXPUTMESSAGE(connection->link, LINKPREFIXTERMINATEMESSAGE);
	LINKPREFIXCLOSE(connection->link);
	LINKPREFIXDEINITIALIZE(connection->env);
	connection->active = 0;
	free(connection);
}

int abort_calculation(void* con) {
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return 0;
	if(connection->active) return LINKPREFIXPUTMESSAGE(connection->link, LINKPREFIXABORTMESSAGE);
	return 0;
}

const char* handle_link_error(void* con) {

	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return NULL;
	
	if(connection->active == 0) return 0;

	int error = LINKPREFIXERROR(connection->link);
	if(error == LINKPREFIXEOK) return 0;

 
	const char* error_string = LINKPREFIXERRORMESSAGE(connection->link);

	if(! LINKPREFIXCLEARERROR(connection->link))
		connection->active = 0;

	return error_string;
}

void evaluate(void* con, const char* input, void (*callback)(char*, void*), void* callback_data)
{
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return;

	// if abort was sent but got stuck
	if(connection->active == 2) {
		connection->active = 1;
		return;
	}

	// send input
	if(connection->active != 1) return; fprintf(stderr, "WSTP: connection ready to send: %s\n", input);
	if(! LINKPREFIXPUTFUNCTION(connection->link, "EvaluatePacket", 1)) {
		(*callback)((char*) handle_link_error((void*) connection), callback_data); 
		return; 
	}
	if(! LINKPREFIXPUTFUNCTION(connection->link, "ToExpression", 1)) { 
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data);
		 if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
		return;
	}
	if(! LINKPREFIXPUTSTRING(connection->link, input))	{
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data);
		 if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
		return;
	}
	if(! LINKPREFIXENDPACKET(connection->link))	{
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data);
		 if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
		return;
	}
	if(! LINKPREFIXFLUSH(connection->link))	{
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data);
		 if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
		return;
	} fprintf(stderr, "WSTP: package sent\n" );

	int await = 0;

	// wait for answer
	char* str;
	char* err;
	while(await == 0) 
	{
		// check for abort
		if(connection->active == 2) {
			if(! abort_calculation(connection)) {
				// abort failed
				connection->active = 0;
				return;
			} else connection->active = 1;
		}

		// check if data can be read
		if(LINKPREFIXREADY(connection->link)) { 
			switch(LINKPREFIXNEXTPACKET(connection->link)) {
				case BEGINDLGPKT: fprintf(stderr, "WSTP: package received: BEGINDLGPKT\n" );
					break;
				case CALLPKT: fprintf(stderr, "WSTP: package received: CALLPKT\n" );
					break;
				case DISPLAYENDPKT: fprintf(stderr, "WSTP: package received: DISPLAYENDPKT\n" );
					break;
				case DISPLAYPKT: fprintf(stderr, "WSTP: package received: DISPLAYPKT\n" );
					break;
				case ENDDLGPKT: fprintf(stderr, "WSTP: package received: ENDDLGPKT\n" );
					break;
				case ENTEREXPRPKT: fprintf(stderr, "WSTP: package received: ENTEREXPRPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case ENTERTEXTPKT: fprintf(stderr, "WSTP: package received: ENTERTEXTPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case EVALUATEPKT: fprintf(stderr, "WSTP: package received: EVALUATEPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case INPUTNAMEPKT: fprintf(stderr, "WSTP: package received: INPUTNAMEPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case INPUTPKT: fprintf(stderr, "WSTP: package received: INPUTPKT\n" );
					break;
				case INPUTSTRPKT: fprintf(stderr, "WSTP: package received: INPUTSTRPKT\n" );
					break;
				case MENUPKT: fprintf(stderr, "WSTP: package received: MENUPKT\n" );
					break;
				case MESSAGEPKT: fprintf(stderr, "WSTP: package received: MESSAGEPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case OUTPUTNAMEPKT: fprintf(stderr, "WSTP: package received: OUTPUTNAMEPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case RESUMEPKT: fprintf(stderr, "WSTP: package received: RESUMEPKT\n" );
					break;
				case RETURNEXPRPKT: fprintf(stderr, "WSTP: package received: RETURNEXPRPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					await++;
					break;
				case RETURNPKT: fprintf(stderr, "WSTP: package received: RETURNPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						fprintf(stderr, "WSTP: RETURNPKT: error extracting string \n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					await++;
					fprintf(stderr, "WSTP: RETURNPKT: finished \n" );
					break;
				case RETURNTEXTPKT: fprintf(stderr, "WSTP: package received: RETURNTEXTPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					await++;
					break;
				case SUSPENDPKT: fprintf(stderr, "WSTP: package received: SUSPENDPKT\n" );
					break;
				case SYNTAXPKT: fprintf(stderr, "WSTP: package received: SYNTAXPKT\n" );
					break;
				case TEXTPKT: fprintf(stderr, "WSTP: package received: TEXTPKT\n" );
					if(! LINKPREFIXGETSTRING(connection->link, (const char**) &str)) {
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data);
		 				if(err) LINKPREFIXRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
					}
					(*callback)(str, callback_data);
					LINKPREFIXRELEASESTRING(connection->link, (const char*) str);
					break;
				case ILLEGALPKT: fprintf(stderr, "WSTP: package received: ILLEGALPKT\n" );
					(*callback)((char*)"(* Unknown error from kernel: consider killing the computation *)", callback_data);
					break; 
				default: fprintf(stderr, "WSTP: package received: unknown\n" );
					(*callback)((char*)"(* Unknown packet from kernel: consider killing the computation *)", callback_data);
			}
		}

		if(await != 0) {fprintf(stderr, "WSTP: leaving loop \n" ); break;}
		usleep(200);
	}

	if(! abort_calculation(connection)) {
		connection->active = 0;
		return;
	}

	return;

}