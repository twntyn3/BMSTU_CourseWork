package parse

import (
    "bytes"
    "net/url"
    "strings"

    "golang.org/x/net/html"
)

// ===== модели =====

// Crypto — строка из таблицы криптовалют
type Crypto struct {
    Name      string // Название (например "Bitcoin")
    Symbol    string // Символ (BTC)
    Price     string // Цена (как текст)
    Change24h string // Изменение за 24ч
    Volume24h string // Объём 24ч
    MarketCap string // Капитализация
    Link      string // Ссылка на страницу монеты
}

// Item — универсальный элемент (для новостных списков, если понадобится)
type Item struct {
    Title string
    Href  string
    Img   string
    Date  string
}

// ===== базовые утилиты =====

func ParseHTML(data []byte) (*html.Node, error) {
    return html.Parse(bytes.NewReader(data))
}

func TextContent(n *html.Node) string {
    var b strings.Builder
    var walk func(*html.Node)
    walk = func(n *html.Node) {
        if n.Type == html.TextNode {
            b.WriteString(n.Data)
        }
        for c := n.FirstChild; c != nil; c = c.NextSibling {
            walk(c)
        }
    }
    walk(n)
    // нормализуем пробелы
    return strings.TrimSpace(strings.Join(strings.Fields(b.String()), " "))
}

func attr(n *html.Node, key string) (string, bool) {
    for _, a := range n.Attr {
        if strings.EqualFold(a.Key, key) {
            return a.Val, true
        }
    }
    return "", false
}

func hasClass(n *html.Node, needle string) bool {
    v, ok := attr(n, "class")
    if !ok {
        return false
    }
    needle = strings.ToLower(needle)
    for _, c := range strings.Fields(strings.ToLower(v)) {
        if strings.Contains(c, needle) {
            return true
        }
    }
    return false
}

func resolve(base *url.URL, href string) string {
    u, err := url.Parse(href)
    if err != nil {
        return ""
    }
    return base.ResolveReference(u).String()
}

// ===== универсальный сбор ссылок (может пригодиться) =====

func ExtractItems(doc *html.Node, base *url.URL, limit int) []Item {
    items := make([]Item, 0, limit)
    var visit func(*html.Node)
    visit = func(n *html.Node) {
        if n.Type == html.ElementNode && strings.EqualFold(n.Data, "a") {
            if href, ok := attr(n, "href"); ok {
                title := TextContent(n)
                if len(title) >= 3 {
                    it := Item{
                        Title: title,
                        Href:  resolve(base, href),
                    }
                    for c := n.FirstChild; c != nil; c = c.NextSibling {
                        if c.Type == html.ElementNode && strings.EqualFold(c.Data, "img") {
                            if src, ok := attr(c, "src"); ok {
                                it.Img = resolve(base, src)
                                break
                            }
                        }
                    }
                    items = append(items, it)
                    if limit > 0 && len(items) >= limit {
                        return
                    }
                }
            }
        }
        for c := n.FirstChild; c != nil && (limit == 0 || len(items) < limit); c = c.NextSibling {
            visit(c)
        }
    }
    visit(doc)
    return items
}

// ===== Хелперы, НУЖНЫЕ myfin.go =====

// extractNameSymbolLink ищет внутри <td> ссылку <a>, возвращает абсолютный href,
// а текст <a> (или ячейки) разбивает на имя и тикер.
func extractNameSymbolLink(td *html.Node, base *url.URL) (name, symbol, link string) {
    // сначала пытаемся найти <a>
    var findA func(*html.Node)
    findA = func(n *html.Node) {
        if n.Type == html.ElementNode && strings.EqualFold(n.Data, "a") {
            if h, ok := attr(n, "href"); ok {
                link = resolve(base, h)
            }
            txt := TextContent(n)
            name, symbol = splitNameSymbol(txt)
        }
        for c := n.FirstChild; c != nil; c = c.NextSibling {
            findA(c)
        }
    }
    findA(td)

    // если <a> не нашли — берём текст всей ячейки
    if name == "" && symbol == "" {
        txt := TextContent(td)
        name, symbol = splitNameSymbol(txt)
    }
    return
}

// splitNameSymbol разбивает строку вида "Bitcoin (BTC)" → ("Bitcoin","BTC").
// Если строка короткая и UPPERCASE — считаем это тикером ("BTC").
// Иначе — это имя монеты.
func splitNameSymbol(s string) (name, symbol string) {
    s = strings.TrimSpace(s)
    if s == "" {
        return "", ""
    }
    // формат "Name (SYMBOL)"
    if i := strings.Index(s, "("); i != -1 && strings.HasSuffix(s, ")") && i < len(s)-1 {
        name = strings.TrimSpace(s[:i])
        symbol = strings.Trim(strings.TrimSpace(s[i+1:len(s)-1]), " ")
        return
    }
    // короткая UPPERCASE-строка — символ
    if len(s) <= 5 && strings.ToUpper(s) == s {
        return "", s
    }
    // иначе — просто имя
    return s, ""
}

