#include <iostream>
#include <queue>
#include <vector>
#include <algorithm>
#include <cstring>
using namespace std;

vector<vector<int>> adj;
vector<bool> visited;
vector<int> comp;

struct Edge {
    int u, v;
};

void bfs(int start, int& comp_size, int& comp_edges, int& min_node, const vector<vector<int>>& adj) {
    queue<int> q;
    q.push(start);
    visited[start] = true;
    comp_size = 1;
    comp_edges = 0;
    min_node = start;

    while (!q.empty()) {
        int u = q.front();
        q.pop();

        for (int v : adj[u]) {
            comp_edges++;
            if (!visited[v]) {
                visited[v] = true;
                comp_size++;
                min_node = min(min_node, v);
                q.push(v);
            }
        }
    }
    comp_edges /= 2;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int N, M;
    cin >> N >> M;

    adj.resize(N);
    visited.resize(N, false);
    comp.resize(N, 0);

    vector<Edge> edges(M);
    for (int i = 0; i < M; ++i) {
        int u, v;
        cin >> u >> v;
        adj[u].push_back(v);
        adj[v].push_back(u);
        edges[i] = {u, v};
    }

    fill(visited.begin(), visited.end(), false);
    int max_size = 0, max_edges = 0, best_min_node = N;

    for (int i = 0; i < N; ++i) {
        if (!visited[i]) {
            int comp_size, comp_edges, min_node;
            bfs(i, comp_size, comp_edges, min_node, adj);

            if (comp_size > max_size ||
                (comp_size == max_size && comp_edges > max_edges) ||
                (comp_size == max_size && comp_edges == max_edges && min_node < best_min_node)) {
                max_size = comp_size;
                max_edges = comp_edges;
                best_min_node = min_node;
            }
        }
    }

    fill(visited.begin(), visited.end(), false);
    queue<int> q;
    q.push(best_min_node);
    visited[best_min_node] = true;

    while (!q.empty()) {
        int u = q.front();
        q.pop();
        comp[u] = 1;
        for (int v : adj[u]) {
            if (!visited[v]) {
                visited[v] = true;
                q.push(v);
            }
        }
    }

    cout << "graph {\n";
    for (int i = 0; i < N; ++i) {
        if (comp[i]) {
            cout << "  " << i << " [color = red];\n";
        } else {
            cout << "  " << i << ";\n";
        }
    }
    for (const Edge& e : edges) {
        if (comp[e.u] && comp[e.v]) {
            cout << "  " << e.u << " -- " << e.v << " [color = red];\n";
        } else {
            cout << "  " << e.u << " -- " << e.v << ";\n";
        }
    }
    cout << "}\n";

    return 0;
}