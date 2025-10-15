package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
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
	log.Printf("newsms output: %s", string(output))

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

	sendSMS(phone, smstext)

	// For demonstration, just echo the parameters
	fmt.Fprintf(w, "Username: %s\nPassword: %s\nPhone: %s\nSMSText: %s\n", username, password, phone, smstext)
}

func main() {
	http.HandleFunc("/sendsms", sendSMSHandler)
	addr := ":60611"
	log.Printf("Starting server at %s...", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
