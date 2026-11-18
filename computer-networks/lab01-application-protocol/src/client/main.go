package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"strconv"
	"strings"

	"github.com/skorobogatov/input"

	"lab2seti/src/proto"
)

// sendRequest -- вспомогательная функция.
func sendRequest(enc *json.Encoder, cmd string, data interface{}) {
	var raw json.RawMessage
	raw, _ = json.Marshal(data)
	_ = enc.Encode(&proto.Request{Command: cmd, Data: &raw}) // Encode сам добавит перевод строки
}

// readLoop -- фоновое чтение всех сообщений сервера.
func readLoop(dec *json.Decoder) {
	for {
		var resp proto.Response
		if err := dec.Decode(&resp); err != nil {
			fmt.Println("decode error:", err)
			return
		}

		switch resp.Status {
		case "ok":
			// Если это ответ на set, в Data может быть SetResult
			if resp.Data != nil {
				var setRes proto.SetResult
				if json.Unmarshal(*resp.Data, &setRes) == nil && setRes.ID != "" {
					fmt.Printf("set ok: id=%s fire_at=%s\n", setRes.ID, setRes.FireAt)
					break
				}
			}
			fmt.Println("ok")

		case "failed":
			var msg string
			if resp.Data != nil && json.Unmarshal(*resp.Data, &msg) == nil && msg != "" {
				fmt.Println("failed:", msg)
			} else {
				fmt.Println("failed")
			}

		case "result":
			// результат для list
			var list proto.ListResult
			if resp.Data != nil && json.Unmarshal(*resp.Data, &list) == nil {
				if len(list.Reminders) == 0 {
					fmt.Println("(no reminders)")
				}
				for _, r := range list.Reminders {
					fmt.Printf("id=%s text=%q fire_at=%s\n", r.ID, r.Text, r.FireAt)
				}
			} else {
				fmt.Println("result (malformed)")
			}

		case "notify":
			// асинхронное уведомление от сервера
			var note proto.NotifyPayload
			if resp.Data != nil && json.Unmarshal(*resp.Data, &note) == nil {
				fmt.Printf("NOTIFY: %s (%s) at %s\n", note.Text, note.ID, note.FiredAt)
			} else {
				fmt.Println("notify (malformed)")
			}

		default:
			fmt.Printf("error: server reports unknown status %q\n", resp.Status)
		}
	}
}

// interact -- цикл взаимодействия (отправка команд).
func interact(conn *net.TCPConn) {
	defer conn.Close()
	enc := json.NewEncoder(conn)
	dec := json.NewDecoder(conn)

	// Фоновое чтение всех ответов/уведомлений
	go readLoop(dec)

	for {
		fmt.Printf("command = ")
		cmd := strings.TrimSpace(input.Gets())

		switch cmd {
		case "quit":
			sendRequest(enc, "quit", nil)
			return

		case "set":
			// читаем after_ms строкой и парсим — так не конфликтует с input.Gets()
			fmt.Printf("after_ms = ")
			rawMS := strings.TrimSpace(input.Gets())
			ms, err := strconv.ParseInt(rawMS, 10, 64)
			if err != nil || ms <= 0 {
				fmt.Println("ms must be a positive integer")
				continue
			}
			fmt.Printf("text = ")
			text := strings.TrimSpace(input.Gets())
			if text == "" {
				fmt.Println("text cannot be empty")
				continue
			}
			sendRequest(enc, "set", &proto.SetPayload{
				AfterMS: ms,
				Text:    text,
			})

		case "list":
			sendRequest(enc, "list", nil)

		default:
			fmt.Println("unknown command (use: set, list, quit)")
		}
	}
}

func main() {
	var addrStr string
	flag.StringVar(&addrStr, "addr", "185.102.139.161:6666", "ip:port")
	flag.Parse()

	if addr, err := net.ResolveTCPAddr("tcp", addrStr); err != nil {
		fmt.Println("bad address:", err)
	} else if conn, err := net.DialTCP("tcp", nil, addr); err != nil {
		fmt.Println("connect error:", err)
	} else {
		interact(conn)
	}
}
