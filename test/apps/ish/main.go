package main

import (
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"

	"github.com/flynn/flynn/discoverd/client"
	"github.com/flynn/flynn/pkg/shutdown"
)

/*
	ish: the Inexusable/Insecure/Internet SHell.
*/
func main() {
	defer shutdown.Exit()

	name := os.Getenv("NAME")
	port := os.Getenv("PORT")
	addr := ":" + port
	if name == "" {
		name = "ish-service"
	}

	log.Println("Application", name, "(an ish instance) running")

	l, err := net.Listen("tcp", addr)
	if err != nil {
		shutdown.Fatal(err)
	}
	defer l.Close()
	log.Println("Listening on", addr)

	hb, err := discoverd.AddServiceAndRegister(name, addr)
	if err != nil {
		shutdown.Fatal(err)
	}
	shutdown.BeforeExit(func() { hb.Close() })

	http.HandleFunc("/ish", ish)
	if err := http.Serve(l, nil); err != nil {
		shutdown.Fatal(err)
	}
}

func ish(resp http.ResponseWriter, req *http.Request) {
	if req.Method != "POST" {
		http.Error(resp, "405 Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	body, _ := ioutil.ReadAll(req.Body)

	cmd := exec.Command("/bin/sh", "-c", string(body)) // no bash in busybox
	cmd.Stdout = resp
	cmd.Stderr = resp
	cmd.Run()
}
