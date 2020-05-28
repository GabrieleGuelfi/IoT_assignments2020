#ifndef PIPELINE_H
#define PIPELINE_H

#include "printf.h"

//payload of the msg
typedef nx_struct my_msg {
	nx_uint16_t msg_value;
	nx_uint8_t msg_topic;
} my_msg_t;

enum {
	AM_MY_MSG = 6,
};

#endif
