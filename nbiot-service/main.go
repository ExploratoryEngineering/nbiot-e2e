package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/telenordigital/nbiot-e2e/nbiot-service/serial"
	"github.com/telenordigital/nbiot-e2e/server/pb"

	"github.com/golang/protobuf/proto"
	"gopkg.in/src-d/go-git.v4"
)

func main() {
	logFile, err := os.OpenFile("/home/e2e/log/nbiot-service.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal("Unable to open log file:", err)
	}
	log.SetOutput(logFile)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)

	var (
		device  = flag.String("device", "/dev/ttyAMA0", "Serial device")
		baud    = flag.Int("baud", 9600, "Baud rate")
		verbose = flag.Bool("v", false, "Verbose output")
	)
	flag.Parse()

	e2eHash := gitHash("/home/e2e/Arduino/nbiot-e2e")
	log.Printf("nbiot-e2e git commit: %07x", e2eHash)

	for {
		run(*device, *baud, *verbose, e2eHash)
		time.Sleep(30 * time.Second)
	}
}

func run(device string, baud int, verbose bool, e2eHash uint32) {
	serialConn := openSerialConnection(device, baud, verbose)
	defer serialConn.Close()

	if !setUpModule(serialConn) {
		return
	}

	printIMSI(serialConn)
	printIMEI(serialConn)

	checkAPN(serialConn)

	for attempts := 0; !waitForDeviceOnline(serialConn); attempts++ {
		if attempts < 180 {
			printRSSI(signalStrength(serialConn))
			time.Sleep(time.Second)
		}
	}
	log.Println("Connected")

	checkAPN(serialConn)

	sequence := uint32(1)
	rssi := float32(99)
	for {
		msg := &pb.Message{
			Message: &pb.Message_PingMessage{
				PingMessage: &pb.PingMessage{
					Sequence: sequence,
					PrevRssi: rssi,
					E2EHash:  e2eHash,
				},
			},
		}

		b, err := proto.Marshal(msg)
		if err != nil {
			log.Println("Error marshaling:", err)
			time.Sleep(time.Minute)
			continue
		}

		if !sendPacket(serialConn, b) {
			return
		}

		sequence++
		rssi = signalStrength(serialConn)
		printRSSI(rssi)
		time.Sleep(time.Minute)
	}
}

func gitHash(gitDir string) uint32 {
	repo, err := git.PlainOpen(gitDir)
	if err != nil {
		log.Fatal("Error: ", err)
	}
	head, err := repo.Head()
	if err != nil {
		log.Fatal("Error: ", err)
	}
	e2eHash, err := strconv.ParseUint(head.Hash().String()[:7], 16, 32)
	if err != nil {
		log.Fatal("Error: ", err)
	}
	return uint32(e2eHash)
}

func openSerialConnection(device string, baud int, verbose bool) *serial.SerialConnection {
	for {
		serialConn, err := serial.NewSerialConnection(device, baud, verbose)
		if err == nil {
			return serialConn
		}
		log.Println("Unable to open serial port:", err)
		time.Sleep(5 * time.Second)
	}
}

func signalStrength(s *serial.SerialConnection) float32 {
	_, urc, err := s.SendAndReceive("AT+CSQ")
	if err != nil || len(urc) < 1 {
		log.Printf("unable to read RSSI: %v %v", err, urc)
		return 99
	}

	signalPower, err := strconv.ParseFloat(strings.Split(strings.Split(urc[0], " ")[1], ",")[0], 32)
	if err != nil {
		log.Println("Error:", err)
		return 99
	}

	if signalPower == 99 {
		return 99
	}

	return float32(2*signalPower - 113)
}

func printRSSI(rssi float32) {
	if rssi == 99 {
		log.Println("RSSI unknown")
	} else {
		log.Println("RSSI: ", rssi)
	}
}

func setUpModule(s *serial.SerialConnection) bool {
	if !checkSerial(s) {
		return false
	}
	if !disableAutoconnect(s) {
		return false
	}
	if !configAPN(s) {
		return false
	}
	if !enableAutoconnect(s) {
		return false
	}

	log.Println("Wait for device to come to its senses (see 3.6.4 in command spec)")
	time.Sleep(5 * time.Second)
	return true
}

func printIMSI(s *serial.SerialConnection) {
	res, _, err := s.SendAndReceive("AT+CIMI")
	if err != nil {
		log.Printf("Error: %v", err)
		return
	}
	log.Println("IMSI:", res[0])
}

func printIMEI(s *serial.SerialConnection) {
	_, urc, err := s.SendAndReceive("AT+CGSN=1")
	if err != nil {
		log.Printf("Error: %v", err)
		return
	}
	imei := strings.Split(urc[0], " ")[1]
	log.Println("IMEI:", imei)
}

func checkSerial(s *serial.SerialConnection) bool {
	_, _, err := s.SendAndReceive("AT")
	if err != nil {
		log.Println("Error:", err)
		return false
	}
	log.Println("Device responds OK")
	return true
}

func disableAutoconnect(s *serial.SerialConnection) bool {
	log.Println("Disabling autoconnect...")
	res, _, err := s.SendAndReceive("AT+NCONFIG=\"AUTOCONNECT\",\"FALSE\"")
	if err != nil {
		log.Printf("Error: %v (%v)", err, strings.Join(res, " | "))
		return false
	}
	log.Println("Autoconnect disabled")
	return rebootModule(s)
}

func configAPN(s *serial.SerialConnection) bool {
	log.Println("Configuring mda.ee APN...")
	_, _, err := s.SendAndReceive("AT+CGDCONT=0,\"IP\",\"mda.ee\"")
	if err != nil {
		log.Printf("Error: %v", err)
	}
	log.Println("APN configured")
	return true
}

func enableAutoconnect(s *serial.SerialConnection) bool {
	log.Println("Enabling autoconnect...")
	res, _, err := s.SendAndReceive("AT+NCONFIG=\"AUTOCONNECT\",\"TRUE\"")
	if err != nil {
		log.Printf("Error: %v (%v)", err, strings.Join(res, " | "))
		return false
	}
	log.Println("Autoconnect enabled")
	return rebootModule(s)
}

func rebootModule(s *serial.SerialConnection) bool {
	log.Println("Rebooting device...")
	res, _, err := s.SendAndReceive("AT+NRB")
	if err != nil {
		log.Printf("Error rebooting: %v", strings.Join(res, " | "))
		return false
	}
	log.Println("Rebooted OK")
	return true
}

func checkAPN(s *serial.SerialConnection) bool {
	log.Println("Checking APN...")
	_, urc, err := s.SendAndReceive("AT+CGDCONT?")
	if err != nil {
		log.Printf("Error: %v", err)
	}
	log.Println("APN:", urc)
	return true
}

func waitForDeviceOnline(s *serial.SerialConnection) bool {
	log.Println("Check for IP address...")
	retries := 0
	for retries < 10 {
		time.Sleep(time.Second * 5)
		res, urc, err := s.SendAndReceive("AT+CGPADDR")
		if err != nil {
			log.Printf("Error: %v (%v)", err, strings.Join(res, " | "))
			return false
		}
		for _, v := range urc {
			if strings.HasPrefix(v, "+CGPADDR") {
				parts := strings.Split(v, ":")
				if len(parts) < 2 {
					log.Printf("Did not get a properly formatted response from module (%s)", v)
					return false
				}
				ip := strings.TrimSpace(parts[1])
				if ip != "0" {
					log.Printf("Device is online with IP %s", ip)
					return true
				}
			}
		}
		log.Printf("Module reports status %s", strings.Join(urc, " | "))
		retries++
	}
	return false
}

func sendPacket(s *serial.SerialConnection, b []byte) bool {
	_, _, err := s.SendAndReceive("AT+NSOCR=\"DGRAM\",17,12345,1")
	if err != nil {
		log.Printf("Error creating socket: %v", err)
		return false
	}
	_, _, err = s.SendAndReceive(fmt.Sprintf("AT+NSOST=0,\"172.16.15.14\",1234,%d,%q", len(b), hex.EncodeToString(b)))
	if err != nil {
		log.Printf("Error sending packet: %v", err)
		return false
	}
	_, _, err = s.SendAndReceive("AT+NSOCL=0")
	if err != nil {
		log.Printf("Error closing socket: %v", err)
		return false
	}
	log.Println("sent message")
	return true
}
