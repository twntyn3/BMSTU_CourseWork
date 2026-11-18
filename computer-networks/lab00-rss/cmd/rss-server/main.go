package main

import (
	"fmt"
	"html/template"
	"log"
	"net/http"
	"strings"

	"github.com/mmcdole/gofeed"
)

// объявляю переменные на уровне пакета
var (
	fp      = gofeed.NewParser()
	feed, _ = fp.ParseURL("https://news.rambler.ru/rss/Magadan/") //скачиваю и парсю данные по юрлу
)

func HomeRouterHandler(w http.ResponseWriter, r *http.Request) {
	_ = r.ParseForm() // анализ аргументов
	fmt.Println("path:", r.URL.Path)
	fmt.Println("scheme:", r.URL.Scheme)
	for k, v := range r.Form {
		fmt.Println("key:", k, "val:", strings.Join(v, ""))
	}

	// HTML-шаблон внутри кода
	//{{range .Items}} ... {{end}} — цикл по элементам
	tp := `
<!DOCTYPE html>
<html>

<body>
	<h1>{{.Title}}</h1>
	<ul>
		{{range .Items}}
			<p>{{.Title}}</p>
			{{if .Description}}
				<p>{{.Description}}</p>
			{{end}}
			<p><a href="{{.Link}}" target="_blank">Подробнее...</a></p>
		{{end}}
	</ul>
</body>
</html>`

	t, err := template.New("page").Parse(tp)
	if err != nil {
		fmt.Fprintln(w, "template error:", err)
		return
	}
	_ = t.Execute(w, feed)
}

func main() {
	http.HandleFunc("/", HomeRouterHandler)  // установим роутер
	err := http.ListenAndServe(":9666", nil) // слушаем порт
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
