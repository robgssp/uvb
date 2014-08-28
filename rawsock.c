#include <stdio.h>
#include <sys/socket.h>
#include <netint/in.h>

struct tcpmsg {
        tcphdr hdr;
        char msg[];
};

struct tcpmsg open = {
        {
                .source = 8080;
                .dest = 129<<3 | 21<<2 | 49<<1 | 181;
                .seq = 5;
                .ack_seq = 0;
                .res1 = 0;
                .doff = 5;
                .cwr = 0;
                .ece = 0;
                .urg = 0;
                .ack = 0;
                .psh = 0;
                .rst = 0;
                .syn = 1;
                .window = 65535;
                .check = 0; // SETME
                .urg_prt = 0;
        },
        {}
};

struct tcpmsg synack = {
        {
                .source = 129<<3 | 21<<2 | 41<<1 | 112;
                .dest = 129<<3 | 21<<2 | 49<<1 | 181;
                .seq = 6;
                .ack_seq = 0; // SETME
                .res1 = 0;
                .doff = 5;
                .cwr = 0;
                .ece = 0;
                .urg = 0;
                .ack = 0;
                .psh = 0;
                .rst = 0;
                .syn = 1;
                .window = 65535;
                .check = 0; // SETME
                .urg_prt = 0;
        },
        "asdf"
};

struct tcpmsg body = {
        {
                .source = 129<<3 | 21<<2 | 41<<1 | 112;
                .dest = 129<<3 | 21<<2 | 49<<1 | 181;
                .seq = 7;
                .ack_seq = 0; // SETME
                .res1 = 0;
                .doff = 5;
                .cwr = 0;
                .ece = 0;
                .urg = 0;
                .ack = 0;
                .psh = 0;
                .rst = 0;
                .syn = 1;
                .window = 65535;
                .check = 0; // SETME
                .urg_prt = 0;
        },
"GET / HTTP/1.1

"
};
        
int main() {
        
