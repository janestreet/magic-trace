///usr/bin/env -S clang -gdwarf-4 "$0" -o /tmp/demo && exec /tmp/demo "$@"
#include <unistd.h>
#include <fcntl.h>

int main(void)
{
    int r = open("/dev/zero", O_RDONLY);
    int w = open("/dev/null", O_WRONLY);
    char buf[4096] = {0};
    for (;;)
    {
        ssize_t bytes_read = read(r, buf, sizeof(buf));
        if (bytes_read < 0)
            break;
        if (write(w, buf, (size_t)bytes_read) < 0)
            break;
    }
    return 0;
}
