package main
//клиентский файл
import (
	"fmt"
	"net"
	"os"
	"time"

	"golang.org/x/crypto/ssh"
)

type SSHClient struct {
	c *ssh.Client
}

func NewSSHClient(cfg Config) (*SSHClient, error) {
	var auths []ssh.AuthMethod

	if cfg.SSHPass != "" {
		auths = append(auths, ssh.Password(cfg.SSHPass))
	}
	if cfg.SSHKeyPath != "" {
		key, err := os.ReadFile(cfg.SSHKeyPath)
		if err != nil {
			return nil, fmt.Errorf("read key: %w", err)
		}
		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return nil, fmt.Errorf("parse key: %w", err)
		}
		auths = append(auths, ssh.PublicKeys(signer))
	}

	if len(auths) == 0 {
		return nil, fmt.Errorf("no auth method: set SSH_PASS or SSH_KEY")
	}

	sshCfg := &ssh.ClientConfig{
		User:            cfg.SSHUser,
		Auth:            auths,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         10 * time.Second,
	}

	addr := fmt.Sprintf("%s:%d", cfg.SSHHost, cfg.SSHPort)

	d := net.Dialer{Timeout: 10 * time.Second}
	raw, err := d.Dial("tcp", addr)
	if err != nil {
		return nil, fmt.Errorf("tcp dial: %w", err)
	}

	cc, chans, reqs, err := ssh.NewClientConn(raw, addr, sshCfg)
	if err != nil {
		_ = raw.Close()
		return nil, fmt.Errorf("ssh handshake: %w", err)
	}

	return &SSHClient{c: ssh.NewClient(cc, chans, reqs)}, nil
}

func (s *SSHClient) Close() {
	if s.c != nil {
		_ = s.c.Close()
	}
}

func (s *SSHClient) Run(cmd string) (string, error) {
	sess, err := s.c.NewSession()
	if err != nil {
		return "", err
	}
	defer sess.Close()

	out, err := sess.CombinedOutput(cmd)
	if err != nil {
		return string(out), fmt.Errorf("remote command failed: %w; output: %s", err, string(out))
	}
	return string(out), nil
}

func (s *SSHClient) PWD() (string, error) {
	out, err := s.Run("pwd")
	if err != nil {
		return "", err
	}
	return trimSpace(out), nil
}
