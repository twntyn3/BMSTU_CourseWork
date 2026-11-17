package parse

import (
    "net/url"
    "strings"

    "golang.org/x/net/html"
)

// --- helpers ---

// appaGetImg ищет <img src> или background-image:url(...) в style
func appaGetImg(n *html.Node, base *url.URL) string {
    // <img src="...">
    if n.Type == html.ElementNode && strings.EqualFold(n.Data, "img") {
        if src, ok := attr(n, "src"); ok {
            return resolve(base, src)
        }
    }
    // style="background-image:url(...)"
    if v, ok := attr(n, "style"); ok {
        low := strings.ToLower(v)
        if i := strings.Index(low, "url("); i != -1 {
            if j := strings.Index(low[i+4:], ")"); j != -1 {
                raw := strings.Trim(low[i+4:i+4+j], `"' `)
                return resolve(base, raw)
            }
        }
    }
    for c := n.FirstChild; c != nil; c = c.NextSibling {
        if u := appaGetImg(c, base); u != "" {
            return u
        }
    }
    return ""
}

// appaGetDate вытаскивает дату из <time> или из элемента с классом, содержащим "date"
func appaGetDate(n *html.Node) string {
    if n.Type == html.ElementNode && strings.EqualFold(n.Data, "time") {
        if dt, ok := attr(n, "datetime"); ok && dt != "" {
            return strings.TrimSpace(dt)
        }
        if t := TextContent(n); t != "" {
            return t
        }
    }
    if hasClass(n, "date") {
        if t := TextContent(n); t != "" {
            return t
        }
    }
    for c := n.FirstChild; c != nil; c = c.NextSibling {
        if t := appaGetDate(c); t != "" {
            return t
        }
    }
    return ""
}

// --- основной парсер под news.ap-pa.ru ---

// ExtractAppaItems снимает новости с https://news.ap-pa.ru/ (эвристики по тегам/классам)
func ExtractAppaItems(doc *html.Node, base *url.URL, limit int) []Item {
    items := make([]Item, 0, limit)

    emitFromNode := func(card *html.Node) {
        if len(items) >= limit || card == nil {
            return
        }
        // заголовок и ссылка: ищем h1/h2/h3 > a, иначе любой <a> с осмысленным текстом
        var title, href string
        var findTitle func(*html.Node)
        findTitle = func(n *html.Node) {
            if title != "" && href != "" {
                return
            }
            if n.Type == html.ElementNode && (n.Data == "h1" || n.Data == "h2" || n.Data == "h3") {
                for c := n.FirstChild; c != nil; c = c.NextSibling {
                    if c.Type == html.ElementNode && strings.EqualFold(c.Data, "a") {
                        if h, ok := attr(c, "href"); ok {
                            href = resolve(base, h)
                            title = TextContent(c)
                            return
                        }
                    }
                }
            }
            if n.Type == html.ElementNode && strings.EqualFold(n.Data, "a") && title == "" {
                if h, ok := attr(n, "href"); ok {
                    if tt := TextContent(n); len(tt) >= 3 {
                        href = resolve(base, h)
                        title = tt
                    }
                }
            }
            for c := n.FirstChild; c != nil; c = c.NextSibling {
                findTitle(c)
            }
        }
        findTitle(card)
        if title == "" {
            return
        }
        items = append(items, Item{
            Title: title,
            Href:  href,
            Img:   appaGetImg(card, base),
            Date:  appaGetDate(card),
        })
    }

    // обходим DOM и ищем контейнеры типа article/section/div с классами post/news/card/entry
    var walk func(*html.Node)
    walk = func(n *html.Node) {
        if len(items) >= limit {
            return
        }
        if n.Type == html.ElementNode {
            tag := strings.ToLower(n.Data)
            if tag == "article" || tag == "section" || tag == "div" {
                if hasClass(n, "post") || hasClass(n, "news") || hasClass(n, "card") || hasClass(n, "entry") {
                    emitFromNode(n)
                }
            }
        }
        for c := n.FirstChild; c != nil && len(items) < limit; c = c.NextSibling {
            walk(c)
        }
    }
    walk(doc)

    return items
}

