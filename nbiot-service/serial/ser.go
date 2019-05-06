package serial

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"log"
	"strings"
	"time"

	"github.com/tarm/serial"
)

// SerialConnection is a serial connection
type SerialConnection struct {
	serialPort *serial.Port
	scanner    *bufio.Scanner
	verbose    bool
	serialRead *bytes.Buffer
}

// NewSerialConnection creates a new SerialConnection
func NewSerialConnection(device string, baud int, verbose bool) (*SerialConnection, error) {
	c := &serial.Config{Name: device, Baud: baud, ReadTimeout: time.Second * 5}
	s, err := serial.OpenPort(c)
	if err != nil {
		return nil, err
	}

	// Wrap serial connection in scanner
	scanner := bufio.NewScanner(s)
	if verbose {
		serialRead := bytes.NewBuffer(nil)
		scanner = bufio.NewScanner(io.TeeReader(s, serialRead))
		return &SerialConnection{
			serialPort: s,
			scanner:    scanner,
			verbose:    verbose,
			serialRead: serialRead,
		}, nil
	}

	return &SerialConnection{
		serialPort: s,
		scanner:    scanner,
		verbose:    verbose,
	}, nil
}

// SendAndReceive sends and recieves data, both regular commands and URCs
func (s *SerialConnection) SendAndReceive(cmd string) ([]string, []string, error) {
	if s.verbose {
		log.Printf("--> %s", cmd)
	}

	_, err := s.serialPort.Write([]byte(cmd + "\r\n"))
	if err != nil {
		return nil, nil, err
	}

	data, urcs, err := s.scanResponse()
	if s.verbose {
		log.Printf("<-- %s", s.serialRead.String())
		s.serialRead.Reset()
	}
	return data, urcs, err
}

// Close closes the serial connection
func (s *SerialConnection) Close() {
	s.serialPort.Close()
}

func (s *SerialConnection) splitURCResponse(cmds []string, err error) ([]string, []string, error) {
	var urcs []string
	var data []string
	for _, v := range cmds {
		if strings.HasPrefix(v, "+") {
			urcs = append(urcs, v)
			continue
		}
		if strings.TrimSpace(v) == "" {
			continue
		}
		data = append(data, v)
	}
	return data, urcs, err
}

func (s *SerialConnection) scanResponse() ([]string, []string, error) {
	var data []string

	// The scanner's ReadTimeout seems ineffective, so we take matters into our own hands.
	for deadline := time.Now().Add(time.Second); time.Now().Before(deadline); {
		for s.scanner.Scan() {
			line := s.scanner.Text()

			if line == "OK" {
				return s.splitURCResponse(data[1:], nil)
			}

			if line == "ERROR" {
				return s.splitURCResponse(data, fmt.Errorf("ERROR: '%v'", data))
			}

			if line == "ABORT" {
				return s.splitURCResponse(data, fmt.Errorf("ABORT: '%v'", data))
			}
			data = append(data, line)
		}
		if err := s.scanner.Err(); err != nil {
			return nil, nil, err
		}

		time.Sleep(100 * time.Millisecond)
	}

	return s.splitURCResponse(data, fmt.Errorf("Invalid response: '%v'", data))
}
