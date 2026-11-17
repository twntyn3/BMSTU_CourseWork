package tpl

import (

    "html/template"
    "strings"
)
const Page = `
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{{.Title}}</title>
<style>
body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;margin:0;padding:24px;background:#0b0f14;color:#e6edf3}
h1{margin:0 0 16px;font-size:20px}
.meta{color:#9ca3af;font-size:12px;margin-bottom:16px}
table{width:100%;border-collapse:collapse;background:#0f172a;border:1px solid #1f2937;border-radius:12px;overflow:hidden}
th,td{padding:10px 12px;border-bottom:1px solid #1f2937;text-align:left}
th{background:#111827;color:#cbd5e1;font-weight:600}
tr:hover{background:#0b1222}
a{color:#93c5fd;text-decoration:none}
a:hover{text-decoration:underline}
.bad{color:#f87171}
.good{color:#34d399}
</style>
</head>
<body>
<h1>{{.Title}}</h1>
<p class="meta">Источник: {{.Source}}</p>

{{if .Crypto}}
<table>
  <thead>
    <tr>
      <th>#</th>
      <th>Криптовалюта</th>
      <th>Цена</th>
      <th>Изм. 24ч</th>
      <th>Объём 24ч</th>
      <th>Капитализация</th>
    </tr>
  </thead>
  <tbody>
  {{range $i, $c := .Crypto}}
    <tr>
      <td>{{add $i 1}}</td>
      <td>{{if $c.Link}}<a href="{{$c.Link}}" target="_blank" rel="noopener">{{$c.Name}}{{if $c.Symbol}} ({{$c.Symbol}}){{end}}</a>{{else}}{{$c.Name}}{{if $c.Symbol}} ({{$c.Symbol}}){{end}}{{end}}</td>
      <td>{{$c.Price}}</td>
      <td><span class="{{trend $c.Change24h}}">{{$c.Change24h}}</span></td>
      <td>{{$c.Volume24h}}</td>
      <td>{{$c.MarketCap}}</td>
    </tr>
  {{end}}
  </tbody>
</table>
{{else}}
  <p>Данные не найдены.</p>
{{end}}

</body>
</html>
`

func Must() *template.Template {
    return template.Must(template.New("page").
        Funcs(template.FuncMap{
            "add": func(i, j int) int { return i + j },
            "trend": func(s string) string {
                ls := s
                if len(ls) > 0 {
                    ls = ls[:1]
                }
                if strings.HasPrefix(s, "-") {
                    return "bad"
                }
                if strings.HasPrefix(s, "+") {
                    return "good"
                }
                return ""
            },
        }).
        Parse(Page))
}

