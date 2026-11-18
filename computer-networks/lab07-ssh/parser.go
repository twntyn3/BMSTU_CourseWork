package main
//конфигурация + общ утилиты
import (
	"os"
	"path"
	"strings"
	"strconv"
)

type Config struct {
	HTTPAddr string

	SSHHost    string
	SSHPort    int
	SSHUser    string
	SSHPass    string
	SSHKeyPath string
}

type WSRequest struct {
	Cmd string `json:"cmd"`
}

type WSResponse struct {
	OK     bool   `json:"ok"`
	CWD    string `json:"cwd,omitempty"`
	Output string `json:"output,omitempty"`
	Error  string `json:"error,omitempty"`
}

func loadConfig() Config {
	return Config{
		HTTPAddr: getenv("HTTP_ADDR", ":8080"),

		SSHHost:    getenv("SSH_HOST", "95.165.83.33"),
		SSHPort:    getenvInt("SSH_PORT", 2222),
		SSHUser:    getenv("SSH_USER", ""),
		SSHPass:    getenv("SSH_PASS", ""),
		SSHKeyPath: getenv("SSH_KEY", ""),
	}
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func getenvInt(k string, def int) int {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

func splitArgs(s string) []string {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	var out []string
	var cur strings.Builder
	inQuotes := false

	for i := 0; i < len(s); i++ {
		ch := s[i]
		switch ch {
		case '"':
			inQuotes = !inQuotes
		case ' ', '\t':
			if inQuotes {
				cur.WriteByte(ch)
			} else if cur.Len() > 0 {
				out = append(out, cur.String())
				cur.Reset()
			}
		default:
			cur.WriteByte(ch)
		}
	}
	if cur.Len() > 0 {
		out = append(out, cur.String())
	}
	return out
}

func resolvePath(cwd, arg string) string {
	arg = strings.TrimSpace(arg)
	if arg == "" {
		return cwd
	}
	if strings.HasPrefix(arg, "/") {
		return path.Clean(arg)
	}
	return path.Clean(path.Join(cwd, arg))
}

func joinUnix(a, b string) string {
	if a == "" {
		return b
	}
	if a == "/" {
		return "/" + b
	}
	return path.Join(a, b)
}

func shQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func trimSpace(s string) string {
	return strings.TrimSpace(strings.ReplaceAll(s, "\r\n", "\n"))
}
