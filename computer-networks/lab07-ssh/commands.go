package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

type State struct {
	CWD string
}

func Execute(st *State, sshc *SSHClient, line string) (output string, newCwd string, err error) {
	line = strings.TrimSpace(line)
	if line == "" {
		return "", "", errors.New("empty command")
	}

	args := splitArgs(line)
	if len(args) == 0 {
		return "", "", errors.New("empty command")
	}

	cmd := strings.ToLower(args[0])
	rest := args[1:]

	switch cmd {
	case "help":
		return "Commands:\n  ls [path]\n  cd <dir>\n  pwd\n  mkdir <dir>\n  rm <file>\n  rmdir <dir>\n  rmr <dir>  (recursive remove)\n", "", nil

	case "pwd":
		return st.CWD + "\n", "", nil

	case "cd":
		if len(rest) != 1 {
			return "", "", errors.New("usage: cd <dir>")
		}
		target := resolvePath(st.CWD, rest[0])
		out, err := sshc.Run(fmt.Sprintf("cd %s && pwd", shQuote(target)))
		if err != nil {
			return "", "", err
		}
		newDir := trimSpace(out)
		return fmt.Sprintf("Entered %s\n", newDir), newDir, nil

	case "ls":
		target := st.CWD
		if len(rest) == 1 {
			target = resolvePath(st.CWD, rest[0])
		} else if len(rest) > 1 {
			return "", "", errors.New("usage: ls [path]")
		}


		// 1) печатаем Fetching
		// 2) выводим таблицу Type Size Name
		out, err := sshc.Run(fmt.Sprintf("cd %s && ls -lA -- %s", shQuote(st.CWD), shQuote(target)))
		if err != nil {
			return "", "", err
		}
		table := formatLsLong(out)
		return "Fetching...\nType Size Name\n" + table, "", nil

	case "mkdir":
		if len(rest) != 1 {
			return "", "", errors.New("usage: mkdir <dir>")
		}
		target := resolvePath(st.CWD, rest[0])
		_, err := sshc.Run(fmt.Sprintf("cd %s && mkdir -- %s", shQuote(st.CWD), shQuote(target)))
		if err != nil {
			return "", "", err
		}
		return "OK\n", "", nil

	case "rm":
		if len(rest) != 1 {
			return "", "", errors.New("usage: rm <file>")
		}
		target := resolvePath(st.CWD, rest[0])
		_, err := sshc.Run(fmt.Sprintf("cd %s && rm -f -- %s", shQuote(st.CWD), shQuote(target)))
		if err != nil {
			return "", "", err
		}
		return "OK\n", "", nil

	case "rmdir":
		if len(rest) != 1 {
			return "", "", errors.New("usage: rmdir <dir>")
		}
		target := resolvePath(st.CWD, rest[0])
		_, err := sshc.Run(fmt.Sprintf("cd %s && rmdir -- %s", shQuote(st.CWD), shQuote(target)))
		if err != nil {
			return "", "", err
		}
		return "OK\n", "", nil

	case "rmr":
		if len(rest) != 1 {
			return "", "", errors.New("usage: rmr <dir>")
		}
		target := resolvePath(st.CWD, rest[0])
		if err := removeRecursive(sshc, st.CWD, target); err != nil {
			return "", "", err
		}
		return "OK\n", "", nil

	default:
		return "", "", fmt.Errorf("unknown command: %s (try help)", cmd)
	}
}

// Рекурсивное удаление снизу вверх
func removeRecursive(sshc *SSHClient, baseCwd, dir string) error {
	ents, err := listEntries(sshc, baseCwd, dir)
	if err != nil {
		return err
	}

	for _, e := range ents {
		full := joinUnix(dir, e.Name)
		if e.IsDir {
			if err := removeRecursive(sshc, baseCwd, full); err != nil {
				return err
			}
			if _, err := sshc.Run(fmt.Sprintf("cd %s && rmdir -- %s", shQuote(baseCwd), shQuote(full))); err != nil {
				return err
			}
		} else {
			if _, err := sshc.Run(fmt.Sprintf("cd %s && rm -f -- %s", shQuote(baseCwd), shQuote(full))); err != nil {
				return err
			}
		}
	}

	_, err = sshc.Run(fmt.Sprintf("cd %s && rmdir -- %s", shQuote(baseCwd), shQuote(dir)))
	return err
}

type entry struct {
	Name  string
	IsDir bool
}

// ls -1Ap: директории заканчиваются "/", -A убирает
func listEntries(sshc *SSHClient, baseCwd, dir string) ([]entry, error) {
	out, err := sshc.Run(fmt.Sprintf("cd %s && ls -1Ap -- %s", shQuote(baseCwd), shQuote(dir)))
	if err != nil {
		return nil, err
	}

	lines := strings.Split(out, "\n")
	var res []entry
	for _, ln := range lines {
		ln = strings.TrimSpace(ln)
		if ln == "" {
			continue
		}
		isDir := strings.HasSuffix(ln, "/")
		name := strings.TrimSuffix(ln, "/")
		if name == "." || name == ".." {
			continue
		}
		res = append(res, entry{Name: name, IsDir: isDir})
	}
	return res, nil
}

// Превращаем вывод `ls -lA` в компактный Type Size Name
func formatLsLong(lsOut string) string {
	lines := strings.Split(lsOut, "\n")
	var b strings.Builder

	for _, ln := range lines {
		ln = strings.TrimSpace(ln)
		if ln == "" || strings.HasPrefix(ln, "total ") {
			continue
		}

		// тип: первый символ в правах (d, -, l)
		first := ln[0]
		typ := ""
		switch first {
		case 'd':
			typ = "<DIR>"
		case 'l':
			typ = "<LNK>"
		default:
			typ = "     " // файл — пусто как в примере
		}


		parts := strings.Fields(ln)
		if len(parts) < 9 {
			// fallback: просто строкой
			b.WriteString(ln + "\n")
			continue
		}

		sizeStr := parts[4]
		// name начинается с 8 индекса (0-based) в стандартном выводе ls -l
		name := strings.Join(parts[8:], " ")
		// если это symlink: "name -> target" оставим только name
		if i := strings.Index(name, " -> "); i >= 0 {
			name = name[:i]
		}

		// выравнивание похоже на то, что на скрине
		size, _ := strconv.ParseInt(sizeStr, 10, 64)
		fmt.Fprintf(&b, "%-5s %-6d %s\n", typ, size, name)
	}

	if b.Len() == 0 {
		return "(empty)\n"
	}
	return b.String()
}
