package main

import (
    "fmt"
    "reflect"
)

func add(a, b []int32, p int) []int32 {
    n := len(a)
    if len(b) > n {
        n = len(b)
    }
    placeholder := make([]int64, n+1)
    for i := range a {
        placeholder[i] += int64(a[i])
    }
    for i := range b {
        placeholder[i] += int64(b[i])
    }
    for i := 0; i < n; i++ {
        carry := placeholder[i] / int64(p)
        placeholder[i] %= int64(p)
        placeholder[i+1] += carry
    }
    outLen := n
    if placeholder[n] != 0 {
        outLen++
    }
    result := make([]int32, outLen)
    for i := 0; i < outLen; i++ {
        result[i] = int32(placeholder[i])
    }
    return result
}

func main() {
    a1 := []int32{9, 9, 9}
    b1 := []int32{1}
    r1 := add(a1, b1, 10)
    fmt.Println(r1, reflect.DeepEqual(r1, []int32{0, 0, 0, 1}))

    a2 := []int32{15, 15}
    b2 := []int32{1, 0, 1}
    r2 := add(a2, b2, 16)
    fmt.Println(r2, reflect.DeepEqual(r2, []int32{0, 0, 2}))

    a3 := []int32{1, 2, 3}
    b3 := []int32{4, 5, 6, 7}
    r3 := add(a3, b3, 1000)
    fmt.Println(r3, reflect.DeepEqual(r3, []int32{5, 7, 9, 7}))
}
