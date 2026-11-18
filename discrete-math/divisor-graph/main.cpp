#include <iostream>
#include <cmath>
#include <algorithm>
#include <cstdint>
using namespace std;

int main() {
    uint64_t x;
    cin >> x;

    uint64_t divisors[5000];
    int dcount = 0;

    for (uint64_t i = 1; i * i <= x; i++) {
        if (x % i == 0) {
            divisors[dcount++] = i;
            if (i != x / i) {
                divisors[dcount++] = x / i;
            }
        }
    }

    sort(divisors, divisors + dcount, [](uint64_t a, uint64_t b) {
        return a > b;
    });

    bool found_x = false;
    for (int i = 0; i < dcount; ++i) {
        if (divisors[i] == x) {
            found_x = true;
            break;
        }
    }
    if (!found_x) {
        divisors[dcount++] = x;
    }

    uint64_t from[10000];
    uint64_t to[10000];
    int edgcount = 0;

    for (int i = 0; i < dcount; ++i) {
        uint64_t u = divisors[i];
        for (int j = 0; j < dcount; ++j) {
            uint64_t v = divisors[j];
            if (u == v) continue;
            if (u % v != 0) continue;

            bool has_middle = false;
            for (int k = 0; k < dcount; ++k) {
                uint64_t w = divisors[k];
                if (w == u || w == v) continue;
                if (u % w == 0 && w % v == 0) {
                    has_middle = true;
                    break;
                }
            }

            if (!has_middle) {
                uint64_t a = u, b = v;
                if (a > b) swap(a, b);
                bool duplicate = false;
                for (int k = 0; k < edgcount; ++k) {
                    if (from[k] == a && to[k] == b) {
                        duplicate = true;
                        break;
                    }
                }
                if (!duplicate) {
                    from[edgcount] = a;
                    to[edgcount] = b;
                    edgcount++;
                }
            }
        }
    }

    cout << "graph {\n";
    for (int i = 0; i < dcount; ++i) {
        cout << "    " << divisors[i] << ";\n";
    }
    for (int i = 0; i < edgcount; ++i) {
        cout << "    " << from[i] << " -- " << to[i] << ";\n";
    }
    cout << "}\n";

    return 0;
}
