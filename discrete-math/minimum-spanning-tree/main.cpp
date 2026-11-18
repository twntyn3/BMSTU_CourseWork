#include <iostream>
#include <vector>
#include <tuple>
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <numeric>

using namespace std;

struct DSU {
    vector<int> parent;
    explicit DSU(int n) : parent(n) { iota(parent.begin(), parent.end(), 0); }
    int find(int u) { return parent[u] == u ? u : parent[u] = find(parent[u]); }
    bool unite(int u, int v) {
        u = find(u), v = find(v);
        return (u != v) ? (parent[v] = u, true) : false;
    }
};

int main() {
    int n; cin >> n;
    vector<pair<double, double>> points(n);
    for (auto& [x, y] : points) cin >> x >> y;

    vector<tuple<int, int, double>> edges;
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j) {
            auto [x1, y1] = points[i];
            auto [x2, y2] = points[j];
            double dx = x1 - x2, dy = y1 - y2;
            edges.emplace_back(i, j, sqrt(dx*dx + dy*dy));
        }

    sort(edges.begin(), edges.end(), [](auto& a, auto& b) {
        return get<2>(a) < get<2>(b);
    });

    DSU dsu(n);
    double total = 0;
    for (auto& [u, v, w] : edges)
        if (dsu.unite(u, v))
            if ((total += w) && (--n == 1)) break;

    cout << fixed << setprecision(2) << total << '\n';
}