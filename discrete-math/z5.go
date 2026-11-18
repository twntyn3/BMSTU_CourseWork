package main

import (
    "bufio"
    "fmt"
    "os"
    "unicode"
)

var placeholderOps = map[string]func(int, int) int{
    "+": func(a, b int) int { return a + b },
    "-": func(a, b int) int { return a - b },
    "*": func(a, b int) int { return a * b },
}

type placeholderCtx struct {
    tok []string
    pos int
}

func (p *placeholderCtx) eval() int {
    switch s := p.tok[p.pos]; s {
    case "(":
        p.pos++
        op := p.tok[p.pos]
        p.pos++
        x := p.eval()
        y := p.eval()
        p.pos++
        return placeholderOps[op](x, y)
    default:
        p.pos++
        return int(s[0] - '0')
    }
}

func main() {
    reader := bufio.NewReader(os.Stdin)
    var input string
    for {
        line, err := reader.ReadString('\n')
        input += line
        if err != nil {
            break
        }
    }
    var tok []string
    for _, r := range input {
        switch {
        case r == '(' || r == ')' || r == '+' || r == '-' || r == '*':
            tok = append(tok, string(r))
        case unicode.IsDigit(r):
            tok = append(tok, string(r))
        }
    }
    ctx := placeholderCtx{tok: tok}
    fmt.Println(ctx.eval())
}
