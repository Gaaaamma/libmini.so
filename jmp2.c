#include "libmini.h"

jmp_buf jb;
char msg1[] = "handler: SIGINT is member\n";
char msg2[] = "handler: SIGINT is not member\n";
char msg3[] = "main: SIGINT is member\n";
char msg4[] = "main: SIGINT is not member\n";

void handler(int sig) {
    sigset_t s;
    sigprocmask(0, 0, &s);
    if (sigismember(&s, 2)) {
        write(1, msg1, strlen(msg1));
    } else {
        write(1, msg2, strlen(msg2));
    }
    longjmp(jb, 1);
}

int main() {
    sigset_t s;
    signal(SIGINT, handler);
    if (setjmp(jb) == 1) {
        sigprocmask(0, 0, &s);
        if (sigismember(&s, 2)) {
            write(1, msg3, strlen(msg3));
        } else {
            write(1, msg4, strlen(msg4));
        }
    }
    while(1);

    return 0;
}