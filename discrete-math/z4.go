package main

import (
    "fmt"
)

type Frac struct{ n, d int64 }

func newFrac(x int64) Frac { return Frac{x, 1} }

func abs(x int64) int64 {
    if x < 0 {
        return -x
    }
    return x
}

func gcd(a, b int64) int64 {
    if b == 0 {
        return abs(a)
    }
    return gcd(b, a%b)
}

func norm(a Frac) Frac {
    if a.n == 0 {
        return Frac{0, 1}
    }
    if a.d < 0 {
        a.n = -a.n
        a.d = -a.d
    }
    g := gcd(a.n, a.d)
    return Frac{a.n / g, a.d / g}
}

func subFrac(a, b Frac) Frac {
    return norm(Frac{a.n*b.d - b.n*a.d, a.d * b.d})
}

func mulFrac(a, b Frac) Frac {
    return norm(Frac{a.n * b.n, a.d * b.d})
}

func divFrac(a, b Frac) Frac {
    return norm(Frac{a.n * b.d, a.d * b.n})
}

func main() {
    var N int
    if _, err := fmt.Scan(&N); err != nil {
        return
    }
    mat := make([][]Frac, N)
    for i := 0; i < N; i++ {
        mat[i] = make([]Frac, N+1)
        for j := 0; j <= N; j++ {
            var x int64
            fmt.Scan(&x)
            mat[i][j] = newFrac(x)
        }
    }
    for i := 0; i < N; i++ {
        sel := i
        for k := i; k < N; k++ {
            if mat[k][i].n != 0 {
                sel = k
                break
            }
        }
        if mat[sel][i].n == 0 {
            fmt.Println("No solution")
            return
        }
        if sel != i {
            mat[i], mat[sel] = mat[sel], mat[i]
        }
        placeholderPivot := mat[i][i]
        for j := i; j <= N; j++ {
            mat[i][j] = divFrac(mat[i][j], placeholderPivot)
        }
        for r := 0; r < N; r++ {
            if r == i {
                continue
            }
            placeholderFactor := mat[r][i]
            if placeholderFactor.n != 0 {
                for c := i; c <= N; c++ {
                    mat[r][c] = subFrac(mat[r][c], mulFrac(placeholderFactor, mat[i][c]))
                }
            }
        }
    }
    for i := 0; i < N; i++ {
        f := norm(mat[i][N])
        fmt.Printf("%d/%d\n", f.n, f.d)
    }
}
