#include "Timer.h"
#include "RadioLeds.h"

module RadioLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}

implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;

	event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	if (TOS_NODE_ID == 1) {
      	call MilliTimer.startPeriodic(1000);
      }
      else if (TOS_NODE_ID == 2) {
      	call MilliTimer.startPeriodic(1000/3);
      }
      else if (TOS_NODE_ID == 3) {
      	call MilliTimer.startPeriodic(200);
      }
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

	event void MilliTimer.fired() {
    counter++;
    if (locked) {
      return;
    }
    else {
      radio_msg_t* rm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
      if (rm == NULL) {
				return;
      }
			rm->counter = counter;
			rm->sender_id = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
				locked = TRUE;
      }
    }
  }
  
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(radio_msg_t)) {
    	return bufPtr;
    }
    else {
      radio_msg_t* rm = (radio_msg_t*)payload;
      if (rm->counter%10 == 0) {
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2Off();
      }
      else {
				if (rm->sender_id == 1) {
					call Leds.led0Toggle();
				}
				else if (rm->sender_id == 2) {
					call Leds.led1Toggle();
				}
				else if (rm->sender_id == 3) {
					call Leds.led2Toggle();
				}
      }
      return bufPtr;
    }
  }
  
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

  
}
