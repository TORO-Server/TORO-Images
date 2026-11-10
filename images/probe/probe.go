// probe: シェルも wget も無いイメージの healthcheck。HTTP の GET をして、2xx / 3xx なら 0 で終わる。
//
//	probe http://127.0.0.1:2019/config/
//
// net/http を使わないので、実行ファイルは 2 MB に収まる。宛先はコンテナの中だけなので、平文で足りる (Chromium は HTTP/1.1 だけを受ける)
package main

import (
	"bufio"
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"
	"time"
)

func main() {
	if len(os.Args) != 2 {
		fail("usage: probe http://host:port/path")
	}
	u, err := url.Parse(os.Args[1])
	if err != nil || u.Scheme != "http" || u.Host == "" {
		fail("probe: not an http URL: " + os.Args[1])
	}
	deadline := time.Now().Add(3 * time.Second)
	conn, err := net.DialTimeout("tcp", u.Host, 3*time.Second)
	if err != nil {
		fail(err.Error())
	}
	defer conn.Close()
	_ = conn.SetDeadline(deadline)
	if _, err := fmt.Fprintf(conn, "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", u.RequestURI(), u.Host); err != nil {
		fail(err.Error())
	}
	status, err := bufio.NewReader(conn).ReadString('\n')
	if err != nil {
		fail(err.Error())
	}
	parts := strings.Fields(status)
	if len(parts) < 2 || (parts[1][0] != '2' && parts[1][0] != '3') {
		fail("probe: " + strings.TrimSpace(status))
	}
}

func fail(msg string) {
	fmt.Fprintln(os.Stderr, msg)
	os.Exit(1)
}
