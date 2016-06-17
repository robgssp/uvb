epoll: epoll.c
	gcc -ggdb -std=gnu11 -pthread $< -o $@

epoll_n: epoll_n.c
	gcc -ggdb -std=gnu11 -pthread $< -o $@
