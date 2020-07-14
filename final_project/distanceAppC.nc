#define NEW_PRINTF_SEMANTICS
#include "distance.h"
#include "printf.h"

configuration distanceAppC {}

implementation {

/****** COMPONENTS *****/
	components MainC, distanceC as App;
	components new AMSenderC(AM_MY_MSG);
	components new AMReceiverC(AM_MY_MSG);
	components new TimerMilliC();
	components ActiveMessageC;
	components SerialPrintfC;

/****** INTERFACES *****/

	//Boot interface
	App.Boot -> MainC.Boot;
	//Send and Receive interfaces
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	//Radio Control
	App.SplitControl -> ActiveMessageC;
	//Interfaces to access packet fields
	App.Packet -> AMSenderC;
	//Timer interface
	App.MilliTimer -> TimerMilliC;

}

