///usr/bin/true; exec /usr/bin/env go run -ldflags=-compressdwarf=false -gcflags "-N -l" "$0" "$@"
package main

import (
	"os"
)

func check(e error) {
    if e != nil {
        panic(e)
    }
}

func main() {
	r, err := os.Open("/dev/zero")
    check(err)
	w, err := os.Create("/dev/null")
	check(err)
	buf := make([]byte, 4096)
	for {
		_, err = r.Read(buf)
		_, err = w.Write(buf)
		check(err)
	}
}