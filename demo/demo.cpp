///usr/bin/env -S clang++ "$0" -o /tmp/demo && exec /tmp/demo "$@"
#include <fstream>

using namespace std;

int main()
{
    ifstream r;
    ofstream w;
    r.open("/dev/zero", ios::binary);
    w.open("/dev/null", ios::binary);
    char buf[4096] = {0};
    for (;;)
    {
        r.read(buf, sizeof(buf));
        w.write(buf, sizeof(buf));
    }
    return 0;
}
