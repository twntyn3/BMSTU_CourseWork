package proto

import "encoding/json"

// Request -- запрос клиента к серверу.
type Request struct {
	// Command может быть:
	// * "quit" - завершить соединение;
	// * "set"  - поставить напоминание;
	// * "list" - получить список активных напоминаний.
	Command string `json:"command"`

	// Если Command == "set", в Data лежит SetPayload.
	// Если "list" или "quit" — Data пустое.
	Data *json.RawMessage `json:"data"`
}

// Response -- ответ сервера клиенту.
type Response struct {
	// Status может быть:
	// * "ok"     - успешное выполнение команды ("quit", "set");
	// * "failed" - ошибка (сообщение в Data);
	// * "result" - результат (например, список напоминаний);
	// * "notify" - асинхронное уведомление от сервера.
	Status string `json:"status"`
	Data   *json.RawMessage `json:"data"`
}

// SetPayload -- данные для команды "set".
type SetPayload struct {
	AfterMS int64  `json:"after_ms"` // миллисекунды до срабатывания (>0)
	Text    string `json:"text"`     // текст напоминания
}

// NotifyPayload -- данные уведомления от сервера.
type NotifyPayload struct {
	ID      string `json:"id"`
	Text    string `json:"text"`
	FiredAt string `json:"fired_at"` // время срабатывания (RFC3339)
}

// ReminderInfo -- элемент списка.
type ReminderInfo struct {
	ID     string `json:"id"`
	Text   string `json:"text"`
	FireAt string `json:"fire_at"`
}

// ListResult -- результат команды "list".
type ListResult struct {
	Reminders []ReminderInfo `json:"reminders"`
}

// SetResult -- результат команды "set".
type SetResult struct {
	ID     string `json:"id"`
	FireAt string `json:"fire_at"`
}
