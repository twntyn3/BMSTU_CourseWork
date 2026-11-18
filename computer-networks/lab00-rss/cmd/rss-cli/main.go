package main

import (
	"fmt"
	"log"
	"time"

	"github.com/mmcdole/gofeed"
)

func main() {
	url := "https://news.rambler.ru/rss/Magadan/"

	fp := gofeed.NewParser()
	feed, err := fp.ParseURL(url)
	if err != nil {
		log.Fatalf("Ошибка чтения RSS: %v", err)
	}

	// Информация о канале
	fmt.Printf("Title       : %s\n", feed.Title)
	fmt.Printf("Description : %s\n", feed.Description)
	fmt.Printf("Link        : %s\n", feed.Link)
	fmt.Printf("Items       : %d\n\n", len(feed.Items))

	// Перебор элементов
	for i, item := range feed.Items {
		var pub string
		if item.PublishedParsed != nil {
			pub = item.PublishedParsed.Format(time.RFC1123)
		} else {
			pub = item.Published
		}

		fmt.Printf("Item Number : %d\n", i)
		fmt.Printf("Title       : %s\n", item.Title)
		fmt.Printf("Link        : %s\n", item.Link)
		fmt.Printf("Published   : %s\n", pub)
		fmt.Printf("Description : %s\n", item.Description)
		fmt.Println()
	}

}
