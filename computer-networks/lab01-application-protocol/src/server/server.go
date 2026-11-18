package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"github.com/mgutz/logxi/v1"
	"net"
	"sync"
	"time"
	"lab2seti/src/proto"
	
)

// Client -- состояние клиента.
type Client struct {
	logger    log.Logger
	conn      *net.TCPConn
	enc       *json.Encoder
	mu        sync.Mutex
	nextID    int
	reminders map[string]*time.Timer
	info      map[string]proto.ReminderInfo
}

// NewClient -- конструктор клиента.
func NewClient(conn *net.TCPConn) *Client {
	return &Client{
		logger:    log.New(fmt.Sprintf("client %s", conn.RemoteAddr().String())),
		conn:      conn,
		enc:       json.NewEncoder(conn),
		reminders: make(map[string]*time.Timer),
		info:      make(map[string]proto.ReminderInfo),
	}
}

// serve -- цикл обработки запросов от клиента.
func (c *Client) serve() {
	defer c.conn.Close()
	decoder := json.NewDecoder(c.conn)
	for {
		var req proto.Request
		if err := decoder.Decode(&req); err != nil {
			c.logger.Error("cannot decode message", "reason", err)
			break
		}
		c.logger.Info("received command", "command", req.Command)
		if c.handleRequest(&req) {
			c.logger.Info("shutting down connection")
			break
		}
	}
}

// handleRequest -- обработка запроса.
func (c *Client) handleRequest(req *proto.Request) bool {
	switch req.Command {
	case "quit":
		c.respond("ok", nil)
		return true

	case "set":
		var payload proto.SetPayload
		if req.Data == nil {
			c.respond("failed", "data field missing")
			return false
		}
		if err := json.Unmarshal(*req.Data, &payload); err != nil {
			c.respond("failed", "bad data")
			return false
		}
		if payload.AfterMS <= 0 || payload.Text == "" {
			c.respond("failed", "after_ms>0 and text required")
			return false
		}
		c.mu.Lock()
		c.nextID++
		id := fmt.Sprintf("r-%d", c.nextID)
		fireAt := time.Now().Add(time.Duration(payload.AfterMS) * time.Millisecond)
		info := proto.ReminderInfo{ID: id, Text: payload.Text, FireAt: fireAt.Format(time.RFC3339)}
		timer := time.AfterFunc(time.Duration(payload.AfterMS)*time.Millisecond, func() {
			c.sendNotify(proto.NotifyPayload{
				ID:      id,
				Text:    payload.Text,
				FiredAt: fireAt.Format(time.RFC3339),
			})
			c.mu.Lock()
			delete(c.reminders, id)
			delete(c.info, id)
			c.mu.Unlock()
		})

		//создаю таймер
		c.reminders[id] = timer
		c.info[id] = info
		c.mu.Unlock()
		c.respond("ok", proto.SetResult{ID: id, FireAt: fireAt.Format(time.RFC3339)})
		return false

	case "list":
		c.mu.Lock()
		list := make([]proto.ReminderInfo, 0, len(c.info))
		for _, v := range c.info {
			list = append(list, v)
		}
		c.mu.Unlock()
		c.respond("result", proto.ListResult{Reminders: list})
		return false

	default:
		c.respond("failed", "unknown command")
		return false
	}
}

// respond -- отправка ответа.
func (c *Client) respond(status string, data interface{}) {
	var raw json.RawMessage
	raw, _ = json.Marshal(data)
	c.enc.Encode(&proto.Response{Status: status, Data: &raw})
}

// sendNotify -- отдельный метод для уведомлений.
func (c *Client) sendNotify(data proto.NotifyPayload) {
	var raw json.RawMessage
	raw, _ = json.Marshal(data)
	c.enc.Encode(&proto.Response{Status: "notify", Data: &raw})
}

func main() {
	var addrStr string
	flag.StringVar(&addrStr, "addr", "185.102.139.161:6666", "ip:port")
	flag.Parse()

	if addr, err := net.ResolveTCPAddr("tcp", addrStr); err != nil {
		log.Error("bad address", "addr", addrStr)
	} else if listener, err := net.ListenTCP("tcp", addr); err != nil {
		log.Error("listen failed", "reason", err)
	} else {
		for {
			if conn, err := listener.AcceptTCP(); err != nil {
				log.Error("accept failed", "reason", err)
			} else {
				go NewClient(conn).serve()
			}
		}
	}
}
