using System;
using System.IO;

FileStream r = new FileStream("/dev/zero", FileMode.Open, FileAccess.Read);
FileStream w = new FileStream("/dev/null", FileMode.Open, FileAccess.Write);
int len = 4096;
byte[] buf = new byte[len];

for(;;) {
	r.Read(buf, 0, len);
	w.Write(buf, 0, len);
}
