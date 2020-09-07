
#include "contiki.h"
#include "lib/random.h"
#include "sys/ctimer.h"
#include "sys/etimer.h"
#include "net/uip.h"
#include "net/uip-ds6.h"
#include "net/uip-debug.h"

#include "simple-udp.h"
#include "servreg-hack.h"
#define SERVICE_ID1 190
//#define SERVICE_ID2 191
#include "net/rpl/rpl.h"

#include <stdio.h>
#include <string.h>

#define VAR_LEN 40

#define UDP_PORT_TEMP 1234
#define UDP_PORT_ACCEL 5678



static struct simple_udp_connection unicast_connection;

/*---------------------------------------------------------------------------*/
PROCESS(unicast_receiver_process, "Unicast receiver example process");
AUTOSTART_PROCESSES(&unicast_receiver_process);
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

char ch[40];

printf("Data received from ");
uip_debug_ipaddr_print(sender_addr);
printf(" on port %d from port %d\n",receiver_port, sender_port);
if ((receiver_port == UDP_PORT_TEMP) ){



memcpy(ch, data, VAR_LEN);
ch[VAR_LEN] = "\0";
printf("Variable -> %s\n", ch);

}
}
/*---------------------------------------------------------------------------*/
static uip_ipaddr_t *
set_global_address(void)
{
  static uip_ipaddr_t ipaddr;
  int i;
  uint8_t state;

  uip_ip6addr(&ipaddr, 0xaaaa, 0, 0, 0, 0, 0, 0, 0);
  uip_ds6_set_addr_iid(&ipaddr, &uip_lladdr);
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

  return &ipaddr;
}
/*---------------------------------------------------------------------------*/
static void
create_rpl_dag(uip_ipaddr_t *ipaddr)
{
  struct uip_ds6_addr *root_if;
root_if = uip_ds6_addr_lookup(ipaddr);
if(root_if != NULL) {
rpl_dag_t *dag;
uip_ipaddr_t prefix;
rpl_set_root(RPL_DEFAULT_INSTANCE, ipaddr);
dag = rpl_get_any_dag();
uip_ip6addr(&prefix, 0xaaaa, 0, 0, 0, 0, 0, 0, 0);
rpl_set_prefix(dag, &prefix, 64);
PRINTF("created a new RPL dag\n");
  } else {
    PRINTF("failed to create a new RPL DAG\n");
  }
}
/*---------------------------------------------------------------------------*/
PROCESS_THREAD(unicast_receiver_process, ev, data)
{
  uip_ipaddr_t *ipaddr;

  PROCESS_BEGIN();

  servreg_hack_init();

  ipaddr = set_global_address();

  create_rpl_dag(ipaddr);
 


servreg_hack_register(SERVICE_ID1, ipaddr);

simple_udp_register(&unicast_connection, UDP_PORT_TEMP,
NULL, UDP_PORT_TEMP, receiver);


  while(1) {
    PROCESS_WAIT_EVENT();
  }
  PROCESS_END();
}
/*---------------------------------------------------------------------------*/
