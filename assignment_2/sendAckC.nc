/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

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
		interface PacketAcknowledgements;
		//interface used to perform sensor reading (to get the value from a sensor)
		interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
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
		counter++;
		mm->msg_counter = counter;
		mm->msg_type = REQ;
		dbg("radio_pack","Preparing the message... \n");
		
		call PacketAcknowledgements.requestAck(&packet);
		if (call AMSend.send(2, &packet, sizeof(my_msg_t)) == SUCCESS) {
			dbg("radio_send", "Packet passed to lower layer successfully!\n");
     	dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength	( &packet ) );
     	dbg_clear("radio_pack","\t Payload Sent\n" );
	 		dbg_clear("radio_pack", "\t\t counter: %hu \n", mm->msg_counter);
	 		dbg_clear("radio_pack", "\t\t type: %hhu \n", mm->msg_type);
		}
	}        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read done.
  	 */
		call Read.read();
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
			if (TOS_NODE_ID == 1){
		    call MilliTimer.startPeriodic( 1000 );
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
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if(err == SUCCESS){
		 if(call PacketAcknowledgements.wasAcked(buf)){
		 	if(TOS_NODE_ID == 1) {
		 		dbg("radio_ack", "Ack received! :)\n");
		 		call MilliTimer.stop();
		 		dbg("timer", "Stopped timer\n");
		 	}
		 	else{
		 		dbg("radio_ack", "Data sent correctly.\n");
		 	}
		 }
		 else{
		 	dbgerror("radio_ack", "Ack was not received, time out!\n");
		 	
		 	if(TOS_NODE_ID == 2){
		 		dbgerror("radio_ack", "Try to send data again...\n");
		 		sendResp();
		 	}
		 }
		}
		else{
			if(TOS_NODE_ID == 1){
				dbgerror("radio_err", "REQ packet not sent, an error occurred.\n");
			}
			else{
				dbgerror("radio_err", "RESP packet not sent. Try to send it again...\n");
				sendResp();
			}
		}
  }
  

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 	if (len != sizeof(my_msg_t)) {return buf;}
    else {
      my_msg_t* mm = (my_msg_t*)payload;
			dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
      dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength(buf));
      dbg("radio_pack", ">>>Pack \n");
      dbg_clear("radio_pack","\t\t Payload Received\n" );
      dbg_clear("radio_pack", "\t\t counter: %hu \n", mm->msg_counter);
      dbg_clear("radio_pack", "\t\t type: %hhu \n", mm->msg_type);
      if(mm->msg_type == REQ){
      	rec_id = mm->msg_counter;
      	sendResp();
      }
      else{
      	dbg_clear("radio_pack", "\t\t value: %u \n", mm->value);
      }
      return buf;
		}
 	}
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	 	if(result == SUCCESS){
		 	my_msg_t* mm = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
			if (mm == NULL) {return;}
			mm->msg_counter = rec_id;
			mm->msg_type = RESP;
			mm->value = data;
			dbg("radio_pack","Preparing the message... \n");
		
			call PacketAcknowledgements.requestAck(&packet);
			if (call AMSend.send(1, &packet, sizeof(my_msg_t)) == SUCCESS) {
				dbg("radio_send", "Packet passed to lower layer successfully!\n");
		   	dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength	( &packet ) );
		   	dbg_clear("radio_pack","\t Payload Sent\n" );
		 		dbg_clear("radio_pack", "\t\t counter: %hu \n", mm->msg_counter);
		 		dbg_clear("radio_pack", "\t\t type: %hhu \n", mm->msg_type);
		 		dbg_clear("radio_pack", "\t\t value: %u \n", mm->value);
			}
		}
		else{
			dbgerror("fksensor_err", "Error receiving data from fake sensor!\n");
			sendResp();
		}
	}
}

