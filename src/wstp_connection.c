#include "wstp_connection.h"
/*#include <string.h>
#include <unistd.h>
*/
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
#define LINKPREFIXCLEARERROR(X) MLClearError(X)
#define LINKPREFIXENDPACKET(X) MLEndPacket(X)
#define LINKPREFIXFLUSH(X) MLFlush(X)
#define LINKPREFIXREADY(X) MLReady(X)
#define LINKPREFIXNEXTPACKET(X) MLNextPacket(X)
#define LINKPREFIXGETSTRING(X,Y) MLGetString(X,Y)
#define LINKPREFIXRELEASESTRING(X,Y) MLReleaseString(X,Y)
#define CONNECTION_STRING " -mathlink -linkmode launch -linkprotocol SharedMemory -linkname gtklink"

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
#define LINKPREFIXCLEARERROR(X) WSClearError(X)
#define LINKPREFIXENDPACKET(X) WSEndPacket(X)
#define LINKPREFIXFLUSH(X) WSFlush(X)
#define LINKPREFIXREADY(X) WSReady(X)
#define LINKPREFIXNEXTPACKET(X) WSNextPacket(X)
#define LINKPREFIXGETSTRING(X,Y) WSGetString(X,Y)
#define LINKPREFIXRELEASESTRING(X,Y) WSReleaseString(X,Y)
#define CONNECTION_STRING " -wstp -linklaunch -linkprotocol SharedMemory -linkname gtklink"


#endif

WstpConnection init_connection(const char* path) {
	
	int error = 0;
	WstpConnection connection;
	connection.active = 0;

	connection.env = LINKPREFIXINITIALIZE((LINKPREFIXENVIRONMENTPARAMETER)0);
	if(0 == connection.env) return connection;

	char  init_kernel[strlen(path) + strlen(CONNECTION_STRING) + 1];
	memcpy(init_kernel, path, strlen(path));
	memcpy(init_kernel + strlen(path), CONNECTION_STRING, strlen(CONNECTION_STRING) + 1);

	connection.link = LINKPREFIXOPENSTRING(connection.env, init_kernel, error);

	if(connection.link == 0 || error != WSEOK) return connection;
	if(0 == LINKPREFIXACTIVATE(connection.link)) return connection;
	connection.active=1;
	return connection;

}

void close_connection(WstpConnection* connection) {
	LINKPREFIXPUTMESSAGE(connection->link, LINKPREFIXTERMINATEMESSAGE);
	LINKPREFIXCLOSE(connection->link);
	LINKPREFIXDEINITIALIZE(connection->env);
	connection->active = 0;
}

int abort_calculation(WstpConnection* connection) {
	if(connection->active != 0) return LINKPREFIXPUTMESSAGE(connection->link, LINKPREFIXABORTMESSAGE);
	return 0;
}

char* handle_link_error(WstpConnection* connection) {
	
	if(connection->active == 0) return 0;

	int error = LINKPREFIXERROR(connection->link);
	if(error == LINKPREFIXEOK) return 0;

 
	char* error_string = LINKPREFIXERRORMESSAGE(connection->link);

	if(! LINKPREFIXCLEARERROR(connection->link))
		connection->active = 0;

	return error_string;
}

void evaluate(WstpConnection* connection, const char* input, void (*callback)(char*))
{
	// send input
	if(connection->active != 1) return;
	if(! LINKPREFIXPUTFUNCTION(connection->link, "EvaluatePacket", 1))	{ (*callback)(handle_link_error(connection)); return; }
	if(! LINKPREFIXPUTFUNCTION(connection->link, "ToExpression", 1))	{ (*callback)(handle_link_error(connection)); return; }
	if(! LINKPREFIXPUTSTRING(connection->link, input))	{ (*callback)(handle_link_error(connection)); return; }
	if(! LINKPREFIXENDPACKET(connection->link))	{ (*callback)(handle_link_error(connection)); return; }
	if(! LINKPREFIXFLUSH(connection->link))	{ (*callback)(handle_link_error(connection)); return; }

	int await = 0;

	// wait for answer
	char* str;
	while(await == 0) 
	{
		// check for abort
		if(connection->active = -1) {
			if(! abort_calculation(connection)) {
				// abort failed
				connection->active = 0;
				return;
			} else connection->active = 1;
		}

		// check if data can be read
		if(LINKPREFIXREADY(connection->link)) {
			switch(LINKPREFIXNEXTPACKET(connection->link)) {
				case BEGINDLGPKT:
					break;
				case CALLPKT:
					break;
				case DISPLAYENDPKT:
					break;
				case DISPLAYPKT:
					break;
				case ENDDLGPKT:
					break;
				case ENTEREXPRPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case ENTERTEXTPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case EVALUATEPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case INPUTNAMEPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case INPUTPKT:
					break;
				case INPUTSTRPKT:
					break;
				case MENUPKT:
					break;
				case MESSAGEPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case OUTPUTNAMEPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case RESUMEPKT:
					break;
				case RETURNEXPRPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					await++;
					break;
				case RETURNPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					await++;
					break;
				case RETURNTEXTPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					await++;
					break;
				case SUSPENDPKT:
					break;
				case SYNTAXPKT:
					break;
				case TEXTPKT:
					if(! LINKPREFIXGETSTRING(connection->link, str)) {
						(*callback)(handle_link_error(connection));
						if(connection->active == 0) return;
					}
					(*callback)(str);
					LINKPREFIXRELEASESTRING(connection->link, str);
					break;
				case ILLEGALPKT: 
					(*callback)((char*)"(* Unknown error from kernel: consider killing the computation *)");
					break; 
				default:
					(*callback)((char*)"(* Unknown packet from kernel: consider killing the computation *)");
			}
		}

		if(await != 0) break;
		usleep(200);
	}

	if(! abort_calculation(connection)) {
		connection->active = 0;
		return;
	}

	return;

}