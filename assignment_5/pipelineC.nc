#include "pipeline.h"
#include "Timer.h"
#include "printf.h"

module pipelineC {

  uses {
		/****** INTERFACES *****/
		interface Boot; 
	
		//interfaces for communication
		interface Receive;
		interface AMSend;
		interface SplitControl;
		//interface for timer
		interface Timer<TMilli> as MilliTimer;
		//other interfaces, if needed
		interface Packet;
		//Random number
		interface Random;
  }

} implementation {

  message_t packet;

  void sendReq();  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
		my_msg_t* mm = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
		if (mm == NULL) {
			return;
		}
		mm->msg_value = (call Random.rand16()) % 101;
		mm->msg_topic = TOS_NODE_ID;
		dbg("radio_pack","Preparing the message... \n");
		
		if (call AMSend.send(1, &packet, sizeof(my_msg_t)) == SUCCESS) {
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
     		dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength	( &packet ) );
     		dbg_clear("radio_pack","\t Payload Sent\n" );
		}
	}        

  //***************** Boot interface ********************//
  event void Boot.booted() {
  	/* Fill it ... */
		dbg("boot","Application booted on node %u at time: %s.\n", TOS_NODE_ID, sim_time_string());
		call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
  	/* Fill it ... */
    if(err == SUCCESS) {
    	dbg("radio", "Radio on!\n");
			if (TOS_NODE_ID == 2 || TOS_NODE_ID == 3){
		    call MilliTimer.startPeriodic( 5000 );
		    dbg("timer", "MilliTimer started.\n");
  		}
    }
    else{
			dbgerror("radio_err", "SplitControl hasn't started, rebooting...\n");
			call SplitControl.start();
    }
  }
  
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
		dbg("timer", "Timer fired at %s.\n", sim_time_string());
		sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 */
 	if(err == SUCCESS){
		dbg("radio_pack","Packet sent\n");
	}
	else{
		dbgerror("radio_err", "Packet not sent, an error occurred.\n");
	}
  }
  

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 */
 	if (len != sizeof(my_msg_t)) {return buf;}
    else {
      	my_msg_t* mm = (my_msg_t*)payload;
	  	
	  	printf("{\"topic\": %u, \"value\": %u}\n", mm->msg_topic, mm->msg_value);
		printfflush();
  		
  		return buf;
	}
  }
  
}

