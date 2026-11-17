package parse

import (
    "net/url"
    "regexp"
    "strings"

    "golang.org/x/net/html"
)

var priceLike = regexp.MustCompile(`[\d\s][\d\s.,]*(?:\$|€|₽|BYN|USDT|USD|руб|byn)?`)

func ExtractMyfinCrypto(doc *html.Node, base *url.URL, limit int) []Crypto {
    var tables []*html.Node

    var walk func(*html.Node)
    walk = func(n *html.Node) {
        if n.Type == html.ElementNode && strings.EqualFold(n.Data, "table") {
            tables = append(tables, n)
        }
        for c := n.FirstChild; c != nil; c = c.NextSibling {
            walk(c)
        }
    }
    walk(doc)

    if len(tables) == 0 {
        return nil
    }

    var cryptoTable *html.Node
    containsPriceHeader := func(t *html.Node) bool {
        heads := tableHeaders(t)
        hline := strings.ToLower(strings.Join(heads, "|"))
        return strings.Contains(hline, "цен") || strings.Contains(hline, "price")
    }
    for _, t := range tables {
        if containsPriceHeader(t) {
            cryptoTable = t
            break
        }
    }
    if cryptoTable == nil {
        cryptoTable = tables[0]
    }

    rows := tableRows(cryptoTable)
    out := make([]Crypto, 0, limit)

    for _, tr := range rows {
        cells := rowCells(tr)
        if len(cells) < 2 {
            continue
        }
        txt := make([]string, len(cells))
        for i := range cells {
            txt[i] = strings.TrimSpace(TextContent(cells[i]))
        }
        if allEmpty(txt) || isHeaderRow(cells) {
            continue
        }
        hasPrice := false
        for _, t := range txt {
            if priceLike.MatchString(t) {
                hasPrice = true
                break
            }
        }
        if !hasPrice {
            continue
        }

        name, symbol, link := extractNameSymbolLink(cells[0], base)
        price := txt[1]
        change := pickCellText(cells, 2)
        volume := pickCellText(cells, 3)
        mcap := pickCellText(cells, 4)

        if name == "" && symbol == "" {
            name, symbol = splitNameSymbol(txt[0])
        }
        if name == "" && symbol == "" && price == "" {
            continue
        }

        out = append(out, Crypto{
            Name:      name,
            Symbol:    symbol,
            Price:     price,
            Change24h: strings.TrimSpace(change),
            Volume24h: strings.TrimSpace(volume),
            MarketCap: strings.TrimSpace(mcap),
            Link:      link,
        })
        if limit > 0 && len(out) >= limit {
            break
        }
    }
    return out
}

func allEmpty(s []string) bool {
    for _, v := range s {
        if strings.TrimSpace(v) != "" {
            return false
        }
    }
    return true
}

func isHeaderRow(cells []*html.Node) bool {
    for _, c := range cells {
        if c.Type == html.ElementNode && strings.EqualFold(c.Data, "th") {
            return true
        }
    }
    return false
}

