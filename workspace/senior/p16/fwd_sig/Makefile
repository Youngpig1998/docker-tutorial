all: c-init-sig image
c-init-sig: c-init-sig.c
	gcc -o c-init-sig c-init-sig.c

image: c-init-sig
	docker build -t youngpig/fwd_sig:v1 .
clean: 
	rm -f *.o c-init-sig
	docker rmi youngpig/fwd_sig:v1
