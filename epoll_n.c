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
#include <signal.h>
#include <fcntl.h>
#include <errno.h>

static const int nconns = 128;
static const int nrepeats = 10000;
static long ncores;

static const char *msg;
static size_t msglen;

const char *prepmsg() {
	const char msg0[] = "GET /robgssp HTTP/1.1\r\n\r\n";
	int len = sizeof(msg0)-1;
	msglen = len * nrepeats;
	char *ret = malloc(msglen);

	for (int i = 0; i < nrepeats; ++i) {
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
	int nsocks = nconns / ncores;
	struct sockdata sdata[nsocks];
	int ep = epoll_create1(0);
	assert(ep != -1);

	for (int i = 0; i < nsocks; ++i) {
		int sock = socket(AF_INET, SOCK_STREAM, 0);
		int flags = fcntl(sock, F_GETFL) | O_NONBLOCK;
		fcntl(sock, F_SETFL, flags);
		
		assert(sock != -1);
		int ret = connect(sock, ai->ai_addr,
				sizeof(struct sockaddr_in));
		assert(ret == 0 || errno == EINPROGRESS);

		sdata[i] = (struct sockdata){ .sock = sock, .ind = 0 };

		struct epoll_event ev = { .events = EPOLLOUT,
					  .data.ptr = sdata+i };
		
		ret = epoll_ctl(ep, EPOLL_CTL_ADD, sock, &ev);
		assert(ret != -1);
	}

	struct epoll_event events[8];
	
	while (nsocks > 0) {
		int nevents = epoll_wait(ep, events, 8, -1);
		
		for (int i = 0; i < nevents; ++i) {
			struct sockdata *sd = events[i].data.ptr;
			ssize_t writ = write(sd->sock,
					     msg + sd->ind,
					     msglen - sd->ind);
			if (writ == -1) {
				err(1, "Socket failed");
			} else {
				sd->ind += writ;
				if (sd->ind == msglen) {
					epoll_ctl(ep, EPOLL_CTL_DEL, sd->sock, NULL);
					nsocks -= 1;
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
	ncores = sysconf(_SC_NPROCESSORS_ONLN);

	signal(SIGPIPE, SIG_IGN);
	
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

	for (long i = 0; i < ncores; ++i) {
		ret = pthread_join(threads[i], NULL);
		assert(ret == 0);
	}

	printf("Done\n");

	while (1) { pause(); }
}
