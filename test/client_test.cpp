#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include <stdbool.h>
#include <arpa/inet.h>

#include <cctype>
#include <math.h>

void dump_mem(uint8_t* mem, int size) {
    printf("\e[32m---- 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\e[0m\n");
    for (int i = 0; i < ceil(size / 16.0); i++) {
        printf("\e[32m%04x\e[0m ", i * 0x10);
        for (int j = 0; j < 16; j++) {
            int k = i * 16 + j;
            if (k >= size) { printf("   "); continue; }
            printf("%02x ", mem[k]);
        }
        for (int j = 0; j < 16; j++) {
            int k = i * 16 + j;
            if (k >= size) { putchar(' '); continue; }
            char c = mem[k];
            if (std::isprint(c)) {
                printf("%c", c);
            }
            else {
                printf("\e[32m.\e[0m");
            }
        }
        printf("\n");
    }
}

int main() {
    int sock = 0, client_fd;
    struct sockaddr_in server_addr;

    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("Socket creation error\n");
        return -1;
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8080);

    if (inet_pton(AF_INET, "127.0.0.1", &server_addr.sin_addr) <= 0) {
        printf("Invalid address\n");
        return -1;
    }

    if ((client_fd = connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr))) < 0) {
        printf("Connection failed\n");
        return -1;
    }

    int r;
    #define ASSERT(c, ft, tt) { if(!(c)) { puts(ft); } else { puts(tt); } }

    r = send(sock, "GET /doThing HTTP/1.0\r\n", 23, 0);
    ASSERT(r!=1, "Failed to send requestline", "Sucessfully send requestline");

    r = send(sock, "Host: localhost:8080\r\n", 22, 0);
    ASSERT(r!=1, "Failed to send host header", "Sucessfully send host header");

    r = send(sock, "\r\n", 2, 0);
    ASSERT(r!=1, "Failed to send header end", "Sucessfully send header end");

    char buff[1024];
    while (true) {
        r = read(sock, buff, 1024);
        if (r <= 0) { break; }
        printf("read %d bytes of data:\n", r);
        dump_mem((uint8_t*)buff, r);
        puts("");
    }

    printf("Stopping client\n");
    close(client_fd);
    return 0;
}
