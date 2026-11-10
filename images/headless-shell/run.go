// chrome-run: 地図の撮影に使う Chromium を子プロセスで動かし、Chromium が 127.0.0.1 で開くデバッグのポートを、コンテナの外へ中継する。
// 公式のイメージの run.sh (bash と socat) の代わり。Chromium が終わったら、一緒に終わる (compose が起動し直す)
//
//	chrome-run [Chromium の追加の引数...]
package main

import (
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"sync"
)

const (
	listenAddr = ":9222"
	chromeAddr = "127.0.0.1:9223"
)

func main() {
	args := append([]string{
		"--no-sandbox",
		"--disable-dev-shm-usage",
		"--enable-unsafe-swiftshader",
		"--ignore-gpu-blocklist",
		"--use-gl=angle",
		"--use-angle=swiftshader",
		"--user-data-dir=/tmp/chrome",
		"--remote-debugging-address=127.0.0.1",
		"--remote-debugging-port=9223",
	}, os.Args[1:]...)
	cmd := exec.Command("/headless-shell/headless-shell", args...)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	go forward()
	err := cmd.Wait()
	fmt.Fprintln(os.Stderr, "chromium exited:", err)
	os.Exit(1)
}

func forward() {
	l, err := net.Listen("tcp", listenAddr)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	for {
		c, err := l.Accept()
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		go pipe(c)
	}
}

func pipe(c net.Conn) {
	defer c.Close()
	up, err := net.Dial("tcp", chromeAddr)
	if err != nil {
		return
	}
	defer up.Close()
	var wg sync.WaitGroup
	wg.Add(2)
	copyHalf := func(dst, src net.Conn) {
		defer wg.Done()
		_, _ = io.Copy(dst, src)
		if t, ok := dst.(*net.TCPConn); ok {
			_ = t.CloseWrite()
		}
	}
	go copyHalf(up, c)
	go copyHalf(c, up)
	wg.Wait()
}
