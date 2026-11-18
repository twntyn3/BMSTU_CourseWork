package main

import (
    "bufio"
    "fmt"
    "os"
    "unicode"
)

func main() {
    reader := bufio.NewReader(os.Stdin)
    var expr []rune
    for {
        r, _, err := reader.ReadRune()
        if err != nil {
            break
        }
        if !unicode.IsSpace(r) {
            expr = append(expr, r)
        }
    }
    pos := 0
    seen := make(map[string]struct{})
    count := 0
    var parse func() string
    parse = func() string {
        if expr[pos] >= 'a' && expr[pos] <= 'z' {
            leaf := string(expr[pos])
            pos++
            return leaf
        }
        pos++
        op := expr[pos]
        pos++
        left := parse()
        right := parse()
        pos++
        key := string(op) + "(" + left + "," + right + ")"
        if _, ok := seen[key]; !ok {
            seen[key] = struct{}{}
            count++
        }
        return key
    }
    parse()
    fmt.Println(count)
}
