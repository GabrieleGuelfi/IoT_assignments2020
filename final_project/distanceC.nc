#include "distance.h"
#include "Timer.h"
#include "printf.h"

module distanceC {

  uses {
		/****** INTERFACES *****/
		interface Boot; 
	
		//interfaces for communication
		interface Receive;
		interface AMSend;
		interface SplitControl;
		interface Packet;
		//interface for timer
		interface Timer<TMilli> as MilliTimer;
  }

} implementation {

	message_t packet; 
	bool locked;
	
  //***************** Boot interface ********************//
	event void Boot.booted() {
		call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS) {		
	    call MilliTimer.startPeriodic( 500 );
    }
    else{
			call SplitControl.start();
    }
  }
  
  
  event void SplitControl.stopDone(error_t err){

  }

  //***************** MilliTimer interface ********************//
	event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * Every mote broadcast its own ID.
	 */
		my_msg_t* mm = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
		if (mm == NULL) {
			return;
		}
		mm->ID = TOS_NODE_ID;
		
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t)) == SUCCESS) {
			locked = TRUE;
		}
	}
	 
  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	//This event is triggered when a message is sent
		if (&packet == buf) {
				locked = FALSE;
		}
	}

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * Print the message on the serial port.
	 */
	 	
		if (len != sizeof(my_msg_t)) {return buf;}
	  else {
			my_msg_t* mm = (my_msg_t*)payload;
			printf("{\"value1\": %u, \"value2\": %u}\n", mm->ID, TOS_NODE_ID);
			printfflush();
			return buf;
		}
  }
  
}

