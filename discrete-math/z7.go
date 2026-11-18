package main

import (
    "bufio"
    "fmt"
    "math/rand"
    "os"
    "strings"
    "time"
    "unicode"
)

type AssocArray interface {
    Assign(string, int)
    Lookup(string) (int, bool)
}

type slNode struct {
    key     string
    val     int
    forward []*slNode
}

type skipList struct {
    head     *slNode
    level    int
    maxLevel int
    p        float32
}

func makeSkipList() AssocArray {
    rand.Seed(time.Now().UnixNano())
    ml := 8
    hdr := &slNode{"", 0, make([]*slNode, ml)}
    return &skipList{hdr, 1, ml, 0.5}
}

func (s *skipList) randomLevel() int {
    lvl := 1
    for rand.Float32() < s.p && lvl < s.maxLevel {
        lvl++
    }
    return lvl
}

func (s *skipList) Lookup(k string) (int, bool) {
    x := s.head
    for i := s.level - 1; i >= 0; i-- {
        for x.forward[i] != nil && x.forward[i].key < k {
            x = x.forward[i]
        }
    }
    x = x.forward[0]
    if x != nil && x.key == k {
        return x.val, true
    }
    return 0, false
}

func (s *skipList) Assign(k string, v int) {
    upd := make([]*slNode, s.maxLevel)
    x := s.head
    for i := s.level - 1; i >= 0; i-- {
        for x.forward[i] != nil && x.forward[i].key < k {
            x = x.forward[i]
        }
        upd[i] = x
    }
    x = x.forward[0]
    if x != nil && x.key == k {
        x.val = v
        return
    }
    nl := s.randomLevel()
    if nl > s.level {
        for i := s.level; i < nl; i++ {
            upd[i] = s.head
        }
        s.level = nl
    }
    nn := &slNode{k, v, make([]*slNode, nl)}
    for i := 0; i < nl; i++ {
        nn.forward[i] = upd[i].forward[i]
        upd[i].forward[i] = nn
    }
}

type avlNode struct {
    key         string
    val, height int
    left, right *avlNode
}

type avl struct{ root *avlNode }

func makeAVL() AssocArray { return &avl{} }

func height(n *avlNode) int {
    if n == nil {
        return 0
    }
    return n.height
}

func updateHeight(n *avlNode) {
    lh, rh := height(n.left), height(n.right)
    if lh > rh {
        n.height = lh + 1
    } else {
        n.height = rh + 1
    }
}

func rotateRight(y *avlNode) *avlNode {
    x := y.left
    y.left = x.right
    x.right = y
    updateHeight(y)
    updateHeight(x)
    return x
}

func rotateLeft(x *avlNode) *avlNode {
    y := x.right
    x.right = y.left
    y.left = x
    updateHeight(x)
    updateHeight(y)
    return y
}

func balance(n *avlNode) *avlNode {
    updateHeight(n)
    if height(n.left)-height(n.right) > 1 {
        if height(n.left.left) < height(n.left.right) {
            n.left = rotateLeft(n.left)
        }
        return rotateRight(n)
    }
    if height(n.right)-height(n.left) > 1 {
        if height(n.right.right) < height(n.right.left) {
            n.right = rotateRight(n.right)
        }
        return rotateLeft(n)
    }
    return n
}

func insertNode(n *avlNode, k string, v int) *avlNode {
    if n == nil {
        return &avlNode{k, v, 1, nil, nil}
    }
    if k < n.key {
        n.left = insertNode(n.left, k, v)
    } else if k > n.key {
        n.right = insertNode(n.right, k, v)
    } else {
        n.val = v
    }
    return balance(n)
}

func (t *avl) Assign(k string, v int) {
    t.root = insertNode(t.root, k, v)
}

func (t *avl) Lookup(k string) (int, bool) {
    n := t.root
    for n != nil {
        if k < n.key {
            n = n.left
        } else if k > n.key {
            n = n.right
        } else {
            return n.val, true
        }
    }
    return 0, false
}

func lex(sentence string, arr AssocArray) []int {
    var res []int
    s := []rune(sentence)
    next := 1
    for i := 0; i < len(s); {
        if unicode.IsLetter(s[i]) {
            j := i + 1
            for j < len(s) && (unicode.IsLetter(s[j]) || unicode.IsDigit(s[j])) {
                j++
            }
            id := string(s[i:j])
            v, ok := arr.Lookup(id)
            if !ok {
                arr.Assign(id, next)
                v = next
                next++
            }
            res = append(res, v)
            i = j
        } else {
            i++
        }
    }
    return res
}

func main() {
    reader := bufio.NewReader(os.Stdin)
    line, _ := reader.ReadString('\n')
    line = strings.TrimSpace(line)
    sl := makeSkipList()
    av := makeAVL()
    r1 := lex(line, sl)
    r2 := lex(line, av)
    fmt.Println("SkipList:", r1)
    fmt.Println("AVL:", r2)
}