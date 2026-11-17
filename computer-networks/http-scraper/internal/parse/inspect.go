package parse

import (
    "strings"

    "golang.org/x/net/html"
)

type TablePreview struct {
    Index   int
    Headers []string
    Rows    [][]string
}

func tableHeaders(table *html.Node) []string {
    var heads []string
    var walk func(*html.Node)
    walk = func(n *html.Node) {
        if n.Type == html.ElementNode && strings.EqualFold(n.Data, "th") {
            heads = append(heads, TextContent(n))
        }
        for c := n.FirstChild; c != nil; c = c.NextSibling {
            walk(c)
        }
    }
    walk(table)
    return heads
}

func tableRows(table *html.Node) []*html.Node {
    var rows []*html.Node
    var walk func(*html.Node)
    walk = func(n *html.Node) {
        if n.Type == html.ElementNode && strings.EqualFold(n.Data, "tr") {
            rows = append(rows, n)
            return
        }
        for c := n.FirstChild; c != nil; c = c.NextSibling {
            walk(c)
        }
    }
    walk(table)
    return rows
}

func rowCells(tr *html.Node) []*html.Node {
    var cells []*html.Node
    for c := tr.FirstChild; c != nil; c = c.NextSibling {
        if c.Type == html.ElementNode && (strings.EqualFold(c.Data, "td") || strings.EqualFold(c.Data, "th")) {
            cells = append(cells, c)
        }
    }
    return cells
}

func pickCellText(cells []*html.Node, idx int) string {
    if idx < 0 || idx >= len(cells) {
        return ""
    }
    return TextContent(cells[idx])
}

func InspectTables(doc *html.Node, maxRows int) []TablePreview {
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

    out := make([]TablePreview, 0, len(tables))
    for i, t := range tables {
        pr := TablePreview{
            Index:   i,
            Headers: tableHeaders(t),
        }
        rs := tableRows(t)
        for j, tr := range rs {
            if j >= maxRows {
                break
            }
            cells := rowCells(tr)
            row := make([]string, len(cells))
            for k := range cells {
                row[k] = TextContent(cells[k])
            }
            pr.Rows = append(pr.Rows, row)
        }
        out = append(out, pr)
    }
    return out
}

