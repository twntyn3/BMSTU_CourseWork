package main

import (
	"database/sql"
	"fmt"
	"log"
	"net"
	"net/smtp"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

// настройки

var (
	// MySQL
	dbUser = "iu9networkslabs"
	dbPass = os.Getenv("DB_PASSWORD")
	dbHost = "students.yss.su"
	dbPort = "3306"
	dbName = "iu9networkslabs"

	// SMTP (почта)
	smtpHost    = "smtp.mail.ru"             
	smtpPort    = "587"                     
	smtpUser    = os.Getenv("SMTP_USER") 
	smtpPass    = os.Getenv("SMTP_PASSWORD")
	smtpFrom    = os.Getenv("SMTP_FROM")
	mailSubject = "Лабораторный спам"   //тема
)



type Config struct {
	DBDsn    string
	SMTPHost string
	SMTPPort string
	SMTPUser string
	SMTPPass string
	SMTPFrom string
	Subject  string
}

type Recipient struct {
	Email string
	Name  string
	Desc  string
}

// собираем конфиг из констант
func loadConfig() Config {
	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=true&loc=Local",
		dbUser, dbPass, dbHost, dbPort, dbName,
	)

	return Config{
		DBDsn:    dsn,
		SMTPHost: smtpHost,
		SMTPPort: smtpPort,
		SMTPUser: smtpUser,
		SMTPPass: smtpPass,
		SMTPFrom: smtpFrom,
		Subject:  mailSubject,
	}
}

// подключаемся к MySQL
func openDB(dsn string) (*sql.DB, error) {
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, err
	}
	return db, nil
}

// берём максимум 2 получателей из listkhrmv
func loadRecipients(db *sql.DB) ([]Recipient, error) {
	rows, err := db.Query("SELECT email, name, `desc` FROM listkhrmv LIMIT 1")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var res []Recipient
	for rows.Next() {
		var r Recipient
		if err := rows.Scan(&r.Email, &r.Name, &r.Desc); err != nil {
			return nil, err
		}
		res = append(res, r)
	}
	return res, rows.Err()
}

// text в logskhrmv максимум 20 символов
func shortStatus(prefix, email string) string {
	msg := prefix + " " + email
	if len(msg) > 20 {
		msg = msg[:20]
	}
	return msg
}

// пишем запись в logskhrmv
func logStatus(db *sql.DB, text string) {
	_, err := db.Exec(
		"INSERT INTO logskhrmv(`time`, `date`, `text`) VALUES (CURRENT_TIME(), CURRENT_DATE(), ?)",
		text,
	)
	if err != nil {
		log.Printf("Ошибка записи в logskhrmv: %v", err)
	}
}

// отправляем HTML-письмо одному получателю

func sendOne(cfg Config, r Recipient) error {
	addr := net.JoinHostPort(cfg.SMTPHost, cfg.SMTPPort)

	auth := smtp.PlainAuth("", cfg.SMTPUser, cfg.SMTPPass, cfg.SMTPHost)

	headers := ""
	headers += fmt.Sprintf("From: %s\r\n", cfg.SMTPFrom)
	headers += fmt.Sprintf("To: %s\r\n", r.Email)
	headers += fmt.Sprintf("Subject: %s\r\n", cfg.Subject)
	headers += "MIME-Version: 1.0\r\n"
	headers += "Content-Type: text/html; charset=\"utf-8\"\r\n"
	headers += "\r\n"

	body := fmt.Sprintf(`<!DOCTYPE html>
<html>
  <body style="margin:0;padding:0;background-color:#121214;">
    <div style="background-color:#121214;padding:24px;
                font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
                color:#f5f5f7;">
      <h2 style="margin:0 0 16px 0;font-size:20px;font-weight:600;color:#f5f5f7;">
        Здравствуйте, %s!
      </h2>

      <p style="margin:0 0 16px 0;font-size:14px;color:#d0d0d5;">
        Это тестовое HTML-письмо для лабораторной работы по SMTP-рассылкам.
      </p>

      <table role="presentation" cellpadding="0" cellspacing="0"
             style="border-collapse:collapse;width:600px;
                    background-color:#1c1c1e;border-radius:12px;
                    border:1px solid #3a3a3c;overflow:hidden;">
        <tr>
          <td style="padding:16px;font-size:14px;color:#f5f5f7;">
            %s
          </td>
        </tr>
      </table>

      <p style="margin:16px 0 0 0;font-size:12px;color:#8e8e93;">
        
      </p>
    </div>
  </body>
</html>`, r.Name, r.Desc)

	msg := []byte(headers + body)

	return smtp.SendMail(addr, auth, cfg.SMTPFrom, []string{r.Email}, msg)
}

func main() {
	log.Println("Запуск рассылки (MySQL, HTML, до 2 адресов)...")

	cfg := loadConfig()

	db, err := openDB(cfg.DBDsn)
	if err != nil {
		log.Fatalf("Не удалось подключиться к БД: %v", err)
	}
	defer db.Close()

	recipients, err := loadRecipients(db)
	if err != nil {
		log.Fatalf("Ошибка выборки из listkhrmv: %v", err)
	}

	if len(recipients) == 0 {
		log.Println("Нет получателей в listkhrmv.")
		return
	}

	log.Printf("Будем слать %d письма(о)\n", len(recipients))

	for _, r := range recipients {
		log.Printf("Отправка на %s ...", r.Email)
		if err := sendOne(cfg, r); err != nil {
			log.Printf("ERR %s: %v", r.Email, err)
			logStatus(db, shortStatus("ERR", r.Email))
		} else {
			log.Printf("OK %s", r.Email)
			logStatus(db, shortStatus("OK", r.Email))
		}
	}

	log.Println("Готово.")
}
