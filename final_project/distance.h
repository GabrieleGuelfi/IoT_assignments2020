#ifndef DISTANCE_H
#define DISTANCE_H

#include "printf.h"

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t ID;
} my_msg_t;

enum {
	AM_MY_MSG = 6,
};

#endif
