package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"
)

// execute script ./newsms with env vars set with NEWSMS_PHONE and NEWSMS_SMSTEXT
func sendSMS(phone, smstext string) error {
	// For demonstration, just print the parameters
	fmt.Printf("Sending SMS to %s: %s\n", phone, smstext)

	// execute script ./newsms with env vars set with NEWSMS_PHONE and NEWSMS_SMSTEXT

	cmd := exec.Command("./newsms.sh")
	cmd.Env = append(os.Environ(),
		"NEWSMS_PHONE="+phone,
		"NEWSMS_SMSTEXT="+smstext,
	)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Error executing newsms: %v, output: %s", err, string(output))
		return err
	}
	ts := time.Now().Format(time.RFC3339)
	log.Printf("[%s] newsms output: %s", ts, string(output))

	return nil
}

func sendSMSHandler(w http.ResponseWriter, r *http.Request) {
	// Parse query parameters
	username := r.URL.Query().Get("username")
	password := r.URL.Query().Get("password")
	phone := r.URL.Query().Get("phone")
	smstext := r.URL.Query().Get("smstext")

	// Basic validation
	if phone == "" || smstext == "" {
		http.Error(w, "Missing phone or smstext parameter", http.StatusBadRequest)
		return
	}

	ts := time.Now().Format(time.RFC3339)
	fmt.Printf("[%s] Received request: username=%s, password=%s, phone=%s, smstext=%s\n", ts, username, password, phone, smstext)
	sendSMS(phone, smstext)

	// For demonstration, just echo the parameters
	fmt.Fprintf(w, "Username: %s\nPassword: %s\nPhone: %s\nSMSText: %s\n", username, password, phone, smstext)
}

func main() {

	addr := ":60611"

	// addr from os args or default to :60611
	if len(os.Args) > 1 {
		// use os.Args[1] as addr
		addr = os.Args[1]
	}

	http.HandleFunc("/sendsms", sendSMSHandler)

	log.Printf("Starting server at %s...", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
