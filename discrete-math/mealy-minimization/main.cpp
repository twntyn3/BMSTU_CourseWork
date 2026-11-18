#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <queue>
#include <unordered_map>
#include <algorithm>


using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n, m, q0;
    if (!(cin >> n >> m >> q0)) return 0;

    vector<vector<int>> to(n, vector<int>(m));
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < m; ++j) cin >> to[i][j];

    vector<vector<string>> out(n, vector<string>(m));
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < m; ++j) cin >> out[i][j];

    vector<int> reach(n);
    queue<int> q; q.push(q0); reach[q0] = 1;
    while (!q.empty()) {
        int v = q.front(); q.pop();
        for (int x : to[v])
            if (!reach[x]) { reach[x] = 1; q.push(x); }
    }

    vector<int> block(n, -1);
    unordered_map<string,int> id;
    int blocks = 0;
    for (int v = 0; v < n; ++v) if (reach[v]) {
        string key;
        for (int j = 0; j < m; ++j) key += out[v][j] + char(1);
        if (!id.count(key)) id[key] = blocks++;
        block[v] = id[key];
    }

    bool changed = true;
    vector<int> newblock(n);
    while (changed) {
        changed = false;
        unordered_map<string,int> nextId;
        int nxtCnt = 0;
        for (int v = 0; v < n; ++v) if (reach[v]) {
            string key;
            for (int j = 0; j < m; ++j) {
                int u = to[v][j];
                key += char(block[u] + 1); key += char(0);
            }
            key += '|';
            for (int j = 0; j < m; ++j) key += out[v][j] + char(1);
            if (!nextId.count(key)) nextId[key] = nxtCnt++;
            newblock[v] = nextId[key];
        }
        for (int v = 0; v < n; ++v) if (reach[v] && block[v] != newblock[v]) changed = true;
        block.swap(newblock);
        blocks = nxtCnt;
    }

    vector<int> canon(blocks, -1), order;
    queue<int> qb;
    int startB = block[q0];
    canon[startB] = 0; order.push_back(startB); qb.push(startB);
    while (!qb.empty()) {
        int b = qb.front(); qb.pop();
        int rep = -1;
        for (int v = 0; v < n && rep == -1; ++v)
            if (reach[v] && block[v]==b) rep=v;
        for (int j=0;j<m;++j){
            int nb = block[to[rep][j]];
            if (canon[nb]==-1){
                canon[nb] = canon.size();
                canon[nb] = order.size();
                order.push_back(nb);
                qb.push(nb);
            }
        }
    }
    cout << "digraph {\n  rankdir=LR;\n";
    for (int i=0;i<(int)order.size();++i)
        cout << "  " << i << " [shape=circle];\n";
    for (int idx=0; idx<(int)order.size(); ++idx) {
        int b = order[idx];
        int rep=-1;
        for(int v=0;v<n && rep==-1;++v)
            if(reach[v]&&block[v]==b) rep=v;
        for(int j=0;j<m;++j){
            int nb = block[to[rep][j]];
            cout << "  " << idx << " -> " << canon[nb]
                 << " [label=\"" << char('a'+j) << "(" << out[rep][j] << ")\"];\n";
        }
    }
    cout << "}\n";
    return 0;
}
