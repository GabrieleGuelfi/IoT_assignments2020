#define NEW_PRINTF_SEMANTICS
#include "pipeline.h"
#include "printf.h"

configuration pipelineAppC {}

implementation {

/****** COMPONENTS *****/
	components MainC, pipelineC as App;
	components new AMSenderC(AM_MY_MSG);
	components new AMReceiverC(AM_MY_MSG);
	components new TimerMilliC();
	components ActiveMessageC;
	components SerialPrintfC;
	components RandomC;

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
	//Random interface
	App.Random -> RandomC;

}

