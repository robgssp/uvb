#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/epoll.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <assert.h>
#include <err.h>
#include <pthread.h>

static const int nconns = 128;
static long ncores;
static int ep;

static const char *msg;
static size_t msglen;

const char *prepmsg() {
	const char msg0[] = "GET /robgssp HTTP/1.1\r\n\r\n";
	int len = sizeof(msg0)-1;
	msglen = len * 1000;
	char *ret = malloc(msglen);

	for (int i = 0; i < 1000; ++i) {
		memcpy(ret+len*i, msg0, len);
	}

	return ret;
}

struct sockdata {
	int sock;
	size_t ind;
};

static void *attack(void *arg) {
	int ret;
	struct addrinfo *ai = arg;
	const int nsocks = nconns / ncores;
	struct sockdata sdata[nsocks];

	for (int i = 0; i < nsocks; ++i) {
		int sock = socket(AF_INET, SOCK_STREAM, 0);
		assert(sock != -1);
		int ret = connect(sock, ai->ai_addr,
				sizeof(struct sockaddr_in));
		printf("Connected!\n");
		assert(ret == 0);
		sdata[i] = (struct sockdata){ .sock = sock, .ind = 0 };

		struct epoll_event ev = { .events = EPOLLOUT,
					  .data.ptr = sdata+i };
		
		ret = epoll_ctl(ep, EPOLL_CTL_ADD, sock, &ev);
		assert(ret != -1);
	}

	struct epoll_event events[8];
	while (1) {
		int nevents = epoll_wait(ep, events, 8, -1);

		for (int i = 0; i < nevents; ++i) {
			struct sockdata *sd = events[i].data.ptr;
			ssize_t writ = write(sd->sock,
					     msg + sd->ind,
					     msglen - sd->ind);
			if (writ == -1) {
				warn("Socket failed");
			} else {
				sd->ind += writ;
				if (sd->ind == msglen) {
					sd->ind = 0;
				}
			}
		}
	}
		
}

int main(int argc, char **argv) {
	int ret;
	if (argc != 3) {
		fprintf(stderr, "usage: epoll <host> <port>");
		return 1;
	}

	msg = prepmsg();
	printf("output: %.*s", msglen, msg);
	ncores = sysconf(_SC_NPROCESSORS_ONLN);

	ep = epoll_create1(0);
	assert(ep != -1);
	
	struct addrinfo *res, hint =
		{ .ai_family = AF_INET,
		  .ai_socktype = SOCK_STREAM };

	ret = getaddrinfo(argv[1], argv[2], &hint, &res);
	if (ret != 0) {
		errx(1, "getaddrinfo failed\n");
	}

	pthread_t threads[ncores];

	for (long i = 0; i < ncores; ++i) {
		ret = pthread_create(threads+i, 0, attack, res);
		assert(ret == 0);
	}

	while (1) { pause(); }
}
