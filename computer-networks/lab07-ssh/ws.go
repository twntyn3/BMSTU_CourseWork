package main
//сокет(сервер)
import (
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true }, // для лабы
}

func wsHandler(cfg Config) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ws, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			return
		}
		defer ws.Close()

		sshc, err := NewSSHClient(cfg)
		if err != nil {
			_ = writeWS(ws, WSResponse{OK: false, Error: err.Error()})
			return
		}
		defer sshc.Close()

		cwd, err := sshc.PWD()
		if err != nil {
			_ = writeWS(ws, WSResponse{OK: false, Error: err.Error()})
			return
		}

		state := &State{CWD: cwd}

		_ = writeWS(ws, WSResponse{
			OK:     true,
			CWD:    cwd,
			Output: "Connected.\nCommands: ls, cd, pwd, mkdir, rm, rmdir, rmr, help\n",
		})

		for {
			var req WSRequest
			if err := ws.ReadJSON(&req); err != nil {
				return
			}
			out, newCwd, err := Execute(state, sshc, req.Cmd)
			if err != nil {
				_ = writeWS(ws, WSResponse{OK: false, CWD: state.CWD, Error: err.Error()})
				continue
			}
			if newCwd != "" {
				state.CWD = newCwd
			}
			_ = writeWS(ws, WSResponse{OK: true, CWD: state.CWD, Output: out})
		}
	}
}

func writeWS(c *websocket.Conn, resp WSResponse) error {
	_ = c.SetWriteDeadline(time.Now().Add(10 * time.Second))
	return c.WriteJSON(resp)
}
