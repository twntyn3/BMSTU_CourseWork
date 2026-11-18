#include <iostream>
#include <vector>
#include <stack>
#include <set>
#include <algorithm>

using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int a, b;
    cin >> a >> b;

    vector<vector<int>> g(a), r(a);
    while (b--) {
        int x, y;
        cin >> x >> y;
        g[x].push_back(y);
        r[y].push_back(x);
    }

    vector<char> z(a);
    vector<int> o, c(a, -1), p;
    stack<int> q;

    auto f = [&](int s) {
        q.push(s);
        while (!q.empty()) {
            int t = q.top();
            if (!z[t]) {
                z[t] = 1;
                for (int h : g[t])
                    if (!z[h]) q.push(h);
            } else {
                q.pop();
                o.push_back(t);
            }
        }
    };

    for (int i = 0; i < a; ++i)
        if (!z[i]) f(i);

    fill(z.begin(), z.end(), 0);
    int j = 0;

    auto bck = [&](int s) {
        q.push(s);
        while (!q.empty()) {
            int t = q.top();
            q.pop();
            if (z[t]) continue;
            z[t] = 1;
            c[t] = j;
            for (int h : r[t])
                if (!z[h]) q.push(h);
        }
    };

    for (int i = a - 1; i >= 0; --i)
        if (!z[o[i]]) {
            bck(o[i]);
            ++j;
        }

    vector<set<int>> con(j);
    for (int i = 0; i < a; ++i)
        for (int h : g[i])
            if (c[i] != c[h])
                con[c[h]].insert(c[i]);

    vector<int> res(j, -1);
    for (int i = 0; i < a; ++i)
        if (res[c[i]] == -1 || i < res[c[i]])
            res[c[i]] = i;

    vector<int> out;
    for (int i = 0; i < j; ++i)
        if (con[i].empty())
            out.push_back(res[i]);

    sort(out.begin(), out.end());
    for (int x : out)
        cout << x << ' ';
    cout << '\n';
}
