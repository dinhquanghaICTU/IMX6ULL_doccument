#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>

#define BROKER_IP   "192.168.0.100"
#define BROKER_PORT 1883
#define CLIENT_ID   "imx6ull_led1"
#define TOPIC       "test/topic"

#define LED_TRIGGER    "/sys/class/leds/led1/trigger"
#define LED_BRIGHTNESS "/sys/class/leds/led1/brightness"

#define BUF_SIZE 1024

static int put_remaining_length(unsigned char *buf, int len)
{
    int i = 0;

    do {
        unsigned char encoded = len % 128;
        len /= 128;
        if (len > 0)
            encoded |= 128;
        buf[i++] = encoded;
    } while (len > 0);

    return i;
}

static int put_string(unsigned char *buf, const char *s)
{
    int len = strlen(s);

    buf[0] = (unsigned char)(len >> 8);
    buf[1] = (unsigned char)(len & 0xff);
    memcpy(buf + 2, s, len);

    return len + 2;
}

static int read_exact(int fd, unsigned char *buf, int len)
{
    int total = 0;

    while (total < len) {
        int n = read(fd, buf + total, len - total);
        if (n <= 0)
            return -1;
        total += n;
    }

    return 0;
}

static int read_remaining_length(int fd, int *out_len)
{
    int multiplier = 1;
    int value = 0;
    unsigned char encoded;

    do {
        if (read_exact(fd, &encoded, 1) < 0)
            return -1;

        value += (encoded & 127) * multiplier;
        multiplier *= 128;

        if (multiplier > 128 * 128 * 128)
            return -1;
    } while (encoded & 128);

    *out_len = value;
    return 0;
}

static int mqtt_read_packet(int fd, unsigned char *type,
                            unsigned char *buf, int *len)
{
    if (read_exact(fd, type, 1) < 0)
        return -1;

    if (read_remaining_length(fd, len) < 0)
        return -1;

    if (*len > BUF_SIZE)
        return -1;

    if (read_exact(fd, buf, *len) < 0)
        return -1;

    return 0;
}

static int write_text_file(const char *path, const char *value)
{
    int fd = open(path, O_WRONLY);
    ssize_t written;
    size_t len;

    if (fd < 0) {
        perror(path);
        return -1;
    }

    len = strlen(value);
    written = write(fd, value, len);
    close(fd);

    if (written != (ssize_t)len) {
        perror("write");
        return -1;
    }

    return 0;
}

static int read_text_file(const char *path, char *buf, size_t size)
{
    int fd = open(path, O_RDONLY);
    ssize_t n;

    if (fd < 0) {
        perror(path);
        return -1;
    }

    n = read(fd, buf, size - 1);
    close(fd);

    if (n < 0) {
        perror("read");
        return -1;
    }

    buf[n] = '\0';
    return 0;
}

static int led_manual_mode(void)
{
    return write_text_file(LED_TRIGGER, "none\n");
}

static int led_set(int on)
{
    if (led_manual_mode() < 0)
        return -1;

    return write_text_file(LED_BRIGHTNESS, on ? "1\n" : "0\n");
}

static int led_toggle(void)
{
    char buf[32];
    int is_on;

    if (read_text_file(LED_BRIGHTNESS, buf, sizeof(buf)) < 0)
        return -1;

    is_on = atoi(buf) > 0;
    return led_set(!is_on);
}

static int led_blink(void)
{
    return write_text_file(LED_TRIGGER, "heartbeat\n");
}

static void trim_message(char *s)
{
    size_t len;

    while (*s == ' ' || *s == '\t' || *s == '\r' || *s == '\n')
        memmove(s, s + 1, strlen(s));

    len = strlen(s);
    while (len > 0 &&
           (s[len - 1] == ' ' || s[len - 1] == '\t' ||
            s[len - 1] == '\r' || s[len - 1] == '\n')) {
        s[len - 1] = '\0';
        len--;
    }
}

static void lowercase(char *s)
{
    while (*s) {
        if (*s >= 'A' && *s <= 'Z')
            *s = *s - 'A' + 'a';
        s++;
    }
}

static void handle_command(const char *topic, const char *msg, int msg_len)
{
    char cmd[256];
    char state[64];
    int copy_len = msg_len;

    if (copy_len >= (int)sizeof(cmd))
        copy_len = sizeof(cmd) - 1;

    memcpy(cmd, msg, copy_len);
    cmd[copy_len] = '\0';
    trim_message(cmd);
    lowercase(cmd);

    printf("MQTT message on topic '%s': %s\n", topic, cmd);

    if (strcmp(cmd, "led on") == 0 || strcmp(cmd, "on") == 0) {
        if (led_set(1) == 0)
            printf("LED1: on\n");
    } else if (strcmp(cmd, "led off") == 0 || strcmp(cmd, "off") == 0) {
        if (led_set(0) == 0)
            printf("LED1: off\n");
    } else if (strcmp(cmd, "led toggle") == 0 || strcmp(cmd, "toggle") == 0) {
        if (led_toggle() == 0)
            printf("LED1: toggled\n");
    } else if (strcmp(cmd, "led blink") == 0 || strcmp(cmd, "blink") == 0) {
        if (led_blink() == 0)
            printf("LED1: heartbeat\n");
    } else if (strcmp(cmd, "status") == 0) {
        if (read_text_file(LED_BRIGHTNESS, state, sizeof(state)) == 0)
            printf("LED1 brightness: %s", state);
    } else {
        printf("Unknown command: %s\n", cmd);
    }

    fflush(stdout);
}

static int tcp_connect(void)
{
    int sock;
    struct sockaddr_in addr;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("socket");
        return -1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(BROKER_PORT);

    if (inet_pton(AF_INET, BROKER_IP, &addr.sin_addr) != 1) {
        perror("inet_pton");
        close(sock);
        return -1;
    }

    if (connect(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("connect");
        close(sock);
        return -1;
    }

    return sock;
}

static int mqtt_connect(int sock)
{
    unsigned char pkt[BUF_SIZE];
    unsigned char type;
    unsigned char payload[BUF_SIZE];
    int pos = 0;
    int rem_len;
    int len;

    pkt[pos++] = 0x10;

    rem_len = 10 + 2 + strlen(CLIENT_ID);
    pos += put_remaining_length(pkt + pos, rem_len);

    pos += put_string(pkt + pos, "MQTT");
    pkt[pos++] = 4;
    pkt[pos++] = 2;
    pkt[pos++] = 0;
    pkt[pos++] = 60;
    pos += put_string(pkt + pos, CLIENT_ID);

    if (write(sock, pkt, pos) != pos)
        return -1;

    if (mqtt_read_packet(sock, &type, payload, &len) < 0)
        return -1;

    if (type != 0x20 || len < 2 || payload[1] != 0x00) {
        printf("MQTT CONNACK failed\n");
        return -1;
    }

    return 0;
}

static int mqtt_subscribe(int sock)
{
    unsigned char pkt[BUF_SIZE];
    unsigned char type;
    unsigned char payload[BUF_SIZE];
    int pos = 0;
    int rem_len;
    int len;

    pkt[pos++] = 0x82;

    rem_len = 2 + 2 + strlen(TOPIC) + 1;
    pos += put_remaining_length(pkt + pos, rem_len);

    pkt[pos++] = 0;
    pkt[pos++] = 1;

    pos += put_string(pkt + pos, TOPIC);
    pkt[pos++] = 0;

    if (write(sock, pkt, pos) != pos)
        return -1;

    if (mqtt_read_packet(sock, &type, payload, &len) < 0)
        return -1;

    if (type != 0x90) {
        printf("MQTT SUBACK failed\n");
        return -1;
    }

    return 0;
}

static void handle_publish(unsigned char fixed_type, unsigned char *buf, int len)
{
    char topic[128];
    int topic_len;
    int pos;
    int payload_len;
    int qos;

    if (len < 2)
        return;

    topic_len = (buf[0] << 8) | buf[1];
    pos = 2 + topic_len;

    if (topic_len >= (int)sizeof(topic) || pos > len)
        return;

    memcpy(topic, buf + 2, topic_len);
    topic[topic_len] = '\0';

    qos = (fixed_type >> 1) & 0x03;
    if (qos > 0)
        pos += 2;

    if (pos > len)
        return;

    payload_len = len - pos;
    handle_command(topic, (const char *)(buf + pos), payload_len);
}

static int mqtt_loop(int sock)
{
    unsigned char type;
    unsigned char buf[BUF_SIZE];
    int len;

    while (1) {
        fd_set rfds;
        struct timeval tv;
        int ret;

        FD_ZERO(&rfds);
        FD_SET(sock, &rfds);

        tv.tv_sec = 30;
        tv.tv_usec = 0;

        ret = select(sock + 1, &rfds, NULL, NULL, &tv);
        if (ret < 0)
            return -1;

        if (ret == 0) {
            unsigned char pingreq[] = {0xC0, 0x00};
            if (write(sock, pingreq, sizeof(pingreq)) != sizeof(pingreq))
                return -1;
            continue;
        }

        if (mqtt_read_packet(sock, &type, buf, &len) < 0)
            return -1;

        if ((type & 0xF0) == 0x30)
            handle_publish(type, buf, len);
    }
}

int main(void)
{
    led_manual_mode();

    while (1) {
        int sock;

        printf("Connecting to MQTT broker %s:%d...\n", BROKER_IP, BROKER_PORT);
        fflush(stdout);

        sock = tcp_connect();
        if (sock < 0) {
            sleep(2);
            continue;
        }

        if (mqtt_connect(sock) < 0) {
            close(sock);
            sleep(2);
            continue;
        }

        if (mqtt_subscribe(sock) < 0) {
            close(sock);
            sleep(2);
            continue;
        }

        printf("Subscribed to topic: %s\n", TOPIC);
        fflush(stdout);

        mqtt_loop(sock);

        printf("MQTT disconnected, reconnecting...\n");
        close(sock);
        sleep(2);
    }

    return 0;
}
