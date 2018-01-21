#include "wstp_connection.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

#ifdef DEBUG
#define DEBUGMSG(...) fprintf(stderr, __VA_ARGS__)
#else
#define DEBUGMSG(...)
#endif

#ifdef MATHLINK

#include "mathlink.h"
#define WSTPLINK MLINK
#define WSTPENV MLENV
#define WSTPINITIALIZE(X) MLInitialize(X) 
#define WSTPENVIRONMENTPARAMETER MLParametersPointer
#define WSTPOPENSTRING(X, Y, Z) MLOpenString(X, Y, Z)
#define WSTPACTIVATE(X) MLActivate(X)
#define WSTPPUTMESSAGE(X,Y) MLPutMessage(X,Y)
#define WSTPPUTFUNCTION(X,Y,Z) MLPutFunction(X,Y,Z)
#define WSTPPUTSTRING(X,Y,Z) MLPutUTF8String(X,Y,Z)
#define WSTPCLOSE(X) MLClose(X)
#define WSTPDEINITIALIZE(X) MLDeinitialize(X)
#define WSTPTERMINATEMESSAGE MLTerminateMessage
#define WSTPABORTMESSAGE MLAbortMessage
#define WSTPERROR(X) MLError(X)
#define WSTPEOK MLEOK
#define WSTPERRORMESSAGE(X) MLErrorMessage(X)
#define WSTPRELEASEERRORMESSAGE(X,Y) /*MLReleaseErrorMessage(X,Y)*/
#define WSTPCLEARERROR(X) MLClearError(X)
#define WSTPENDPACKET(X) MLEndPacket(X)
#define WSTPFLUSH(X) MLFlush(X)
#define WSTPREADY(X) MLReady(X)
#define WSTPNEXTPACKET(X) MLNextPacket(X)
#define WSTPNEWPACKET(X) MLNewPacket(X)
#define WSTPGETSTRING(X,Y,Z1,Z2) MLGetUTF8String(X,Y,Z1,Z2)
#define WSTPGETINTEGER(X,Y) MLGetInteger(X,Y)
#define WSTPGETSYMBOL(X,Y,Z1,Z2) MLGetUTF8Symbol(X,Y,Z1,Z2)
#define WSTPRELEASESTRING(X,Y,Z) MLReleaseUTF8String(X,Y,Z)
#define WSTPRELEASESYMBOL(X,Y,Z) MLReleaseUTF8Symbol(X,Y,Z)

#define WSTPERRORTYPE int

#else

#include "wstp.h"
#define WSTPLINK WSLINK
#define WSTPENV WSENV
#define WSTPINITIALIZE(X) WSInitialize(X) 
#define WSTPENVIRONMENTPARAMETER WSEnvironmentParameter
#define WSTPOPENSTRING(X,Y,Z) WSOpenString(X,Y,Z)
#define WSTPACTIVATE(X) WSActivate(X)
#define WSTPPUTMESSAGE(X,Y) WSPutMessage(X,Y)
#define WSTPPUTFUNCTION(X,Y,Z) WSPutFunction(X,Y,Z)
#define WSTPPUTSTRING(X,Y,Z) WSPutUTF8String(X,Y,Z)
#define WSTPCLOSE(X) WSClose(X)
#define WSTPDEINITIALIZE(X) WSDeinitialize(X)
#define WSTPTERMINATEMESSAGE WSTerminateMessage
#define WSTPABORTMESSAGE WSAbortMessage
#define WSTPERROR(X) WSError(X)
#define WSTPEOK WSEOK
#define WSTPERRORMESSAGE(X) WSErrorMessage(X)
#define WSTPRELEASEERRORMESSAGE(X,Y) WSReleaseErrorMessage(X,Y)
#define WSTPCLEARERROR(X) WSClearError(X)
#define WSTPENDPACKET(X) WSEndPacket(X)
#define WSTPFLUSH(X) WSFlush(X)
#define WSTPREADY(X) WSReady(X)
#define WSTPNEXTPACKET(X) WSNextPacket(X)
#define WSTPNEWPACKET(X) WSNewPacket(X)
#define WSTPGETSTRING(X,Y,Z1,Z2) WSGetUTF8String(X,Y,Z1,Z2)
#define WSTPGETINTEGER(X,Y) WSGetInteger(X,Y)
#define WSTPGETSYMBOL(X,Y,Z1,Z2) WSGetUTF8Symbol(X,Y,Z1,Z2)
#define WSTPRELEASESTRING(X,Y,Z) WSReleaseUTF8String(X,Y,Z)
#define WSTPRELEASESYMBOL(X,Y,Z) WSReleaseUTF8Symbol(X,Y,Z)
#if WSINTERFACE > 4
#define WSTPERRORTYPE long
#else
#define WSTPERRORTYPE int
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
	
	WSTPERRORTYPE error = 0;
	
	WstpConnection* connection = (WstpConnection*) malloc(sizeof(WstpConnection));
	connection->active = 0;

	connection->env = WSTPINITIALIZE((WSTPENVIRONMENTPARAMETER)0);
	if((WSTPENV)0 == connection->env) return (void*)connection;

	connection->link = WSTPOPENSTRING(connection->env, path, &error);
	if(!connection->link || error != WSTPEOK) return (void*)connection;
	if(! WSTPACTIVATE(connection->link))  return (void*)connection;
	connection->active=1;


	return (void*)connection;

}

void close_connection(void* con) {
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return;
	WSTPPUTMESSAGE(connection->link, WSTPTERMINATEMESSAGE);
	WSTPCLOSE(connection->link);
	WSTPDEINITIALIZE(connection->env);
	connection->active = 0;
	free(connection);
}

int abort_calculation(void* con) {
	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return 0;
	if(connection->active) return WSTPPUTMESSAGE(connection->link, WSTPABORTMESSAGE);
	return 0;
}

const char* handle_link_error(void* con) {

	WstpConnection* connection = (WstpConnection*) con;
	if(!connection)
		return NULL;
	
	if(connection->active == 0) return NULL;

	int error = WSTPERROR(connection->link);
	if(error == WSTPEOK) return NULL;

 
	const char* error_string = WSTPERRORMESSAGE(connection->link);

	if(! WSTPCLEARERROR(connection->link))
		connection->active = 0;

	return error_string;
}


void evaluate(void* con, const char* input, void (*callback)(char*, void*, unsigned long, int), void* callback_data)
{
	WstpConnection* connection = (WstpConnection*) con;
	
	// stamp to do stuff in order
	unsigned long stamp=1;
	
	if(!connection) {
		(*callback)((char*)0, callback_data, stamp++, 1);
		return;
	}

	// if abort was sent but got stuck
	if(connection->active == 2) {
		connection->active = 1;
		(*callback)((char*)0, callback_data, stamp++, 1);
		return;
	}

	// send input
	if(connection->active != 1) return; 
	if(! WSTPPUTFUNCTION(connection->link, "EnterExpressionPacket", 1)) {
		(*callback)((char*) handle_link_error((void*) connection), callback_data, stamp++, 1); 
		return; 
	}
	if(! WSTPPUTFUNCTION(connection->link, "ToExpression", 1)) { 
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data, stamp++, 1);
		 if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
		return;
	}
	if(! WSTPPUTSTRING(connection->link, input, strlen(input)))	{
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data, stamp++, 1);
		 if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
		return;
	}
	if(! WSTPENDPACKET(connection->link))	{
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data, stamp++, 1);
		 if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
		return;
	}
	if(! WSTPFLUSH(connection->link))	{
		char* err = (char*) handle_link_error(connection);
		(*callback)(err, callback_data, stamp++, 1);
		 if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
		return;
	} 
	DEBUGMSG( "WSTP: packet sent: %s\n", input);

	int inti;
	int bytes, chars;
	char* err;
	char* str;
	
	//check for unregistered errors
	err = (char*) handle_link_error(connection);
	if(err != NULL) {
		DEBUGMSG("WSTP: Error mid-connection: %s\n", err);
		(*callback)(err, callback_data, stamp++, 1);
		 if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
		 return;
	}
	while(1) {
		
		usleep(200);
		
		//check for abort
		if(connection->active == 2) {
			if(! abort_calculation(connection)) {
				// abort failed
				connection->active = 0;
				(*callback)((char*)0, callback_data, stamp++, 1);
				return;
			} else connection->active = 1;
		}

		// flush before requesting status
		if(! WSTPFLUSH(connection->link)) {
			DEBUGMSG("WSTP: Error flushing mid-connection\n");
			char* err = (char*) handle_link_error(connection);
			(*callback)(err, callback_data, stamp++, 1);
		 	if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
			return;
		} 
		if(! WSTPREADY(connection->link))
			continue;
		switch(WSTPNEXTPACKET(connection->link)) {
				case INPUTNAMEPKT: 
					DEBUGMSG( "WSTP: package received: INPUTNAMEPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					DEBUGMSG( "WSTP: INPUTNAMEPKT value: %s\n", str);
					//(*callback)(str, callback_data, stamp++, 0);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case OUTPUTNAMEPKT: 
					DEBUGMSG( "WSTP: package received: OUTPUTNAMEPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					DEBUGMSG("WSTP: OUTPUTNAMEPKT value: %s\n", str);
					(*callback)(str, callback_data, stamp++, 0);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case RETURNEXPRPKT: 
					DEBUGMSG( "WSTP: package received: RETURNEXPRPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, 1);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						return;
						break;
					}
					DEBUGMSG( "WSTP: RETURNEXPRPKT value: %s\n", str);
					(*callback)(str, callback_data, stamp++, 1);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					return;
					break;
				case RETURNPKT: 
					DEBUGMSG( "WSTP: package received: RETURNPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						err = (char*) handle_link_error(connection);
						DEBUGMSG( "WSTP: RETURNPKT error: %s\n", err);
						(*callback)(err, callback_data, stamp++, 1);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						return;
						break;
					} 
					(*callback)(str, callback_data, stamp++, 1);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					DEBUGMSG( "WSTP: RETURNPKT value: %s \n", str);
					return;
					break;
				case BEGINDLGPKT:
					DEBUGMSG( "WSTP: package received: BEGINDLGPKT\n" );
					if(!WSTPGETINTEGER(connection->link, &inti)) {
						DEBUGMSG( "WSTP: Error receiving integer\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;					
					}
					DEBUGMSG("WSTP: BEGINDLGPKT integer: %i\n", inti);
					break;
				case CALLPKT: 
					DEBUGMSG( "WSTP: package received: CALLPKT\n" );
					break;
				case DISPLAYENDPKT: 
					DEBUGMSG( "WSTP: package received: DISPLAYENDPKT\n" );
					break;
				case DISPLAYPKT: 
					DEBUGMSG( "WSTP: package received: DISPLAYPKT\n" );
					break;
				case ENDDLGPKT: 
					DEBUGMSG( "WSTP: package received: ENDDLGPKT\n" );
					break;
				case ENTEREXPRPKT: 
					DEBUGMSG( "WSTP: package received: ENTEREXPRPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					(*callback)(str, callback_data, stamp++, 0);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case ENTERTEXTPKT: 
					DEBUGMSG( "WSTP: package received: ENTERTEXTPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					(*callback)(str, callback_data, stamp++, 0);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case EVALUATEPKT: 
					DEBUGMSG( "WSTP: package received: EVALUATEPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					(*callback)(str, callback_data, stamp++, 0);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case INPUTPKT: 
					DEBUGMSG( "WSTP: package received: INPUTPKT\n" );
					break;
				case INPUTSTRPKT: 
					DEBUGMSG( "WSTP: package received: INPUTSTRPKT\n" );
					break;
				case MENUPKT: 
					DEBUGMSG( "WSTP: package received: MENUPKT\n" );
					if(! WSTPGETINTEGER(connection->link, &inti)) {
						DEBUGMSG( "WSTP: Error receiving integer\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					DEBUGMSG( "WSTP: MENUPKT : %i\n", inti );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++,(connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					DEBUGMSG("WSTP: MENUPKT title: %s", str);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case MESSAGEPKT:
					DEBUGMSG( "WSTP: package received: MESSAGEPKT\n" );
					if(! WSTPGETSYMBOL(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving symbol\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					//(*callback)(str, callback_data, stamp++, 0);
					DEBUGMSG("WSTP: MESSAGEPKT symbol: %s\n", str);
					WSTPRELEASESYMBOL(connection->link, (const char*) str, bytes);
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					//(*callback)(str, callback_data, stamp++, 0);
					DEBUGMSG("WSTP: MESSAGEPKT string: %s\n", str);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case RESUMEPKT: 
					DEBUGMSG( "WSTP: package received: RESUMEPKT\n" );
					break;
				case RETURNTEXTPKT: 
					DEBUGMSG( "WSTP: package received: RETURNTEXTPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						return;
						break;
					}
					(*callback)(str, callback_data, stamp++, 1);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					return;
					break;
				case SUSPENDPKT: 
					DEBUGMSG( "WSTP: package received: SUSPENDPKT\n" );
					break;
				case SYNTAXPKT: 
					DEBUGMSG( "WSTP: package received: SYNTAXPKT\n" );
					if(! WSTPGETINTEGER(connection->link, &inti)) {
						DEBUGMSG( "WSTP: Error receiving integer\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					DEBUGMSG( "WSTP: SYNTAXPKT position: %i\n", inti);
					break;
				case TEXTPKT: 
					DEBUGMSG( "WSTP: package received: TEXTPKT\n" );
					if(! WSTPGETSTRING(connection->link, (const unsigned char**) &str, &bytes, &chars)) {
						DEBUGMSG( "WSTP: Error receiving string\n" );
						err = (char*) handle_link_error(connection);
						(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 				if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
						if(connection->active == 0) return;
						break;
					}
					(*callback)(str, callback_data, stamp++, 0);
					WSTPRELEASESTRING(connection->link, (const char*) str, bytes);
					break;
				case ILLEGALPKT: 
					DEBUGMSG( "WSTP: package received: ILLEGALPKT\n" );
					(*callback)((char*)"(* kernel error *)", callback_data, stamp++, 1);
					return;
					break; 
				default:
					DEBUGMSG( "WSTP: package received: unknown\n" );
					(*callback)((char*)"(* Unknown packet from kernel *)", callback_data, stamp++, 0);
					break;
			}
			// skip tp the end of current packet
			if(! WSTPNEWPACKET(connection->link)) {
				DEBUGMSG( "WSTP: Error skipping to end of packet\n");
				err = (char*) handle_link_error(connection);
				(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
		 		if(err) WSTPRELEASEERRORMESSAGE(connection->link, err);
				if(connection->active == 0) return;
			}

			// check for unregistered errors
			err = (char*) handle_link_error(connection);
			if(err) {
				(*callback)(err, callback_data, stamp++, (connection->active == 0)?1:0);
				DEBUGMSG("Error finishing packet: %s\n", err);
				WSTPRELEASEERRORMESSAGE(connection->link, err);
				if(connection->active == 0) return;
			}
	}

	(*callback)((char*)0, callback_data, stamp++, 1);
	return;

}