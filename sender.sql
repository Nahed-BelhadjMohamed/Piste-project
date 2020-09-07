
#include "contiki.h"
#include "lib/random.h"
#include "sys/ctimer.h"
#include "sys/etimer.h"
#include "net/uip.h"
#include "net/uip-ds6.h"
#include "net/uip-debug.h"

#include "node-id.h"

#include "simple-udp.h"
#include "servreg-hack.h"

#include <stdio.h>
#include <string.h>

#include "serial-ubidots.h"
#include "dev/i2cmaster.h"

#include "dev/tmp102.h"
#define SERVICE_ID 190
#define UDP_PORT 1234

#define SEND_INTERVAL		(2 * CLOCK_SECOND)
#define SEND_TIME		(random_rand() % (SEND_INTERVAL))

static struct simple_udp_connection unicast_connection;
static struct ubidots_msg_t msg;
static struct ubidots_msg_t *msgPtr = &msg;

/*---------------------------------------------------------------------------*/
PROCESS(unicast_sender_process, "Unicast sender example process");
AUTOSTART_PROCESSES(&unicast_sender_process);
/*---------------------------------------------------------------------------*/



static void
receiver(struct simple_udp_connection *c,
         const uip_ipaddr_t *sender_addr,
         uint16_t sender_port,
         const uip_ipaddr_t *receiver_addr,
         uint16_t receiver_port,
         const uint8_t *data,
         uint16_t datalen)
{
  printf("Data received on port %d from port %d with length %d\n",
         receiver_port, sender_port, datalen);
}
/*---------------------------------------------------------------------------*/



static void
set_global_address(void)
{
 uip_ipaddr_t ipaddr;
int i;
uint8_t state;
/* Initialize the IPv6 address as below */
uip_ip6addr(&ipaddr, 0xaaaa, 0, 0, 0, 0, 0, 0, 0);
/* Set the last 64 bits of an IP address based on the MAC address */
uip_ds6_set_addr_iid(&ipaddr, &uip_lladdr);
/* Add to our list addresses */
uip_ds6_addr_add(&ipaddr, 0, ADDR_AUTOCONF);
printf("IPv6 addresses: ");
for(i = 0; i < UIP_DS6_ADDR_NB; i++) {
state = uip_ds6_if.addr_list[i].state;
    if(uip_ds6_if.addr_list[i].isused &&

(state == ADDR_TENTATIVE || state == ADDR_PREFERRED)) {
uip_debug_ipaddr_print(&uip_ds6_if.addr_list[i].ipaddr);
printf("\n");
    }
  }
}




/*---------------------------------------------------------------------------*/
PROCESS_THREAD(unicast_sender_process, ev, data)
{
  static struct etimer periodic_timer;
  static struct etimer send_timer;
  uip_ipaddr_t *addr;

  PROCESS_BEGIN();

  servreg_hack_init();

  set_global_address();
int16_t temp;
tmp102_init();
//memcpy(msg.var_key, "545a202b76254223b5ffa65f", 40);
//printf("VAR %s\n", msg.var_key);

  simple_udp_register(&unicast_connection, UDP_PORT,
                      NULL, UDP_PORT, receiver);

  etimer_set(&periodic_timer, SEND_INTERVAL);
  while(1) {

    PROCESS_WAIT_EVENT_UNTIL(etimer_expired(&periodic_timer));
    etimer_reset(&periodic_timer);
    etimer_set(&send_timer, SEND_TIME);

    PROCESS_WAIT_EVENT_UNTIL(etimer_expired(&send_timer));
    addr = servreg_hack_lookup(SERVICE_ID);
    if(addr != NULL) {
      temp = tmp102_read_temp_x100();
char buf[20]="nahed";
msg.value[0] = (uint8_t)((temp & 0xFF00) >> 8);
msg.value[1] = (uint8_t)(temp & 0x00FF);
printf("Sending temperature reading -> %d via unicast to ", temp);
uip_debug_ipaddr_print(addr);
printf("\n");
//simple_udp_sendto(&unicast_connection, msgPtr, UBIDOTS_MSG_LEN, addr);
simple_udp_sendto(&unicast_connection, buf, strlen(buf) + 1, addr);
    } else {
      printf("Service %d not found\n", SERVICE_ID);
    }
  }

  PROCESS_END();
}
/*---------------------------------------------------------------------------*/
