package main

import (
    "context"
    "errors"
    "html/template"
    "net/http"
    "net/url"
    "os"
    "os/signal"
    "strconv"
    "strings"
    "syscall"
    "time"

    log "github.com/mgutz/logxi/v1"

    // ЗАМЕНИ на свой module path из go.mod, если он другой!
    "example.com/http-scraper/internal/fetch"
    "example.com/http-scraper/internal/parse"
    "example.com/http-scraper/internal/tpl"
)

var (
    logger = log.New("srv")
    tmpl   *template.Template
    client *http.Client
)

type pageData struct {
    Title  string
    Source string
    Crypto []parse.Crypto
}

func main() {
    tmpl = tpl.Must()
    client = fetch.NewClient()

    mux := http.NewServeMux()
    mux.HandleFunc("/", handleIndex)

    // /inspect — выводит заголовки всех таблиц и первые строки (для отладки парсинга)
    mux.HandleFunc("/inspect", func(w http.ResponseWriter, r *http.Request) {
        src := strings.TrimSpace(r.URL.Query().Get("src"))
        if src == "" {
            src = "https://myfin.by/crypto-rates"
        }
        u, err := url.Parse(src)
        if err != nil || (u.Scheme != "https" && u.Scheme != "http") {
            http.Error(w, "bad src", http.StatusBadRequest)
            return
        }

        reqCtx, cancel := context.WithTimeout(r.Context(), 12*time.Second)
        defer cancel()

        data, ct, err := fetch.Get(reqCtx, client, u.String(), 5<<20)
        if err != nil {
            http.Error(w, "upstream error: "+err.Error(), http.StatusBadGateway)
            return
        }
        if !strings.Contains(strings.ToLower(ct), "text/html") {
            http.Error(w, "not html: "+ct, http.StatusUnsupportedMediaType)
            return
        }

        doc, err := parse.ParseHTML(data)
        if err != nil {
            http.Error(w, "parse error: "+err.Error(), http.StatusBadGateway)
            return
        }

        previews := parse.InspectTables(doc, 3)

        w.Header().Set("Content-Type", "text/plain; charset=utf-8")
        if len(previews) == 0 {
            w.Write([]byte("tables: 0\n"))
            return
        }
        for _, p := range previews {
            w.Write([]byte("TABLE #" + strconv.Itoa(p.Index) + "\n"))
            if len(p.Headers) > 0 {
                w.Write([]byte("  headers: " + strings.Join(p.Headers, " | ") + "\n"))
            } else {
                w.Write([]byte("  headers: (none)\n"))
            }
            for i, row := range p.Rows {
                w.Write([]byte("  row " + strconv.Itoa(i) + ": " + strings.Join(row, " | ") + "\n"))
            }
            w.Write([]byte("\n"))
        }
    })

    mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    })

    srv := &http.Server{
        Addr:              ":8080",
        Handler:           logging(mux),
        ReadTimeout:       10 * time.Second,
        WriteTimeout:      20 * time.Second,
        ReadHeaderTimeout: 5 * time.Second,
        IdleTimeout:       60 * time.Second,
    }

    go func() {
        logger.Info("listening", "addr", srv.Addr)
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            logger.Error("server error", "err", err)
            os.Exit(1)
        }
    }()

    stop := make(chan os.Signal, 1)
    signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
    <-stop

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    logger.Info("shutting down...")
    _ = srv.Shutdown(ctx)
    logger.Info("bye")
}

func handleIndex(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    src := strings.TrimSpace(r.URL.Query().Get("src"))
    if src == "" {
        src = "https://myfin.by/crypto-rates"
    }
    u, err := url.Parse(src)
    if err != nil || (u.Scheme != "https" && u.Scheme != "http") {
        http.Error(w, "bad src", http.StatusBadRequest)
        return
    }
    logger.Info("fetch", "src", u.String(), "remote", r.RemoteAddr)

    reqCtx, cancel := context.WithTimeout(ctx, 12*time.Second)
    defer cancel()

    data, ct, err := fetch.Get(reqCtx, client, u.String(), 5<<20)
    if err != nil {
        logger.Warn("fetch failed", "err", err)
        http.Error(w, "upstream error: "+err.Error(), http.StatusBadGateway)
        return
    }

    // ?debug=1 — показать начало HTML, чтобы глазами увидеть разметку
    if r.URL.Query().Get("debug") == "1" {
        w.Header().Set("Content-Type", "text/plain; charset=utf-8")
        max := 3000
        if len(data) < max {
            max = len(data)
        }
        w.Write([]byte("Content-Type: " + ct + "\n\n"))
        w.Write(data[:max])
        return
    }

    if !strings.Contains(strings.ToLower(ct), "text/html") {
        logger.Warn("unexpected content-type", "ct", ct)
        http.Error(w, "not html", http.StatusUnsupportedMediaType)
        return
    }

    doc, err := parse.ParseHTML(data)
    if err != nil {
        logger.Warn("html parse error", "err", err)
        http.Error(w, "parse error", http.StatusBadGateway)
        return
    }

    coins := parse.ExtractMyfinCrypto(doc, u, 100)

    w.Header().Set("Content-Type", "text/html; charset=utf-8")
    if err := tmpl.Execute(w, pageData{
        Title:  "Курсы криптовалют (myfin.by)",
        Source: u.Host,
        Crypto: coins,
    }); err != nil {
        logger.Error("template error", "err", err)
    }
}

// middleware-логгер
func logging(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        ww := &wr{ResponseWriter: w, code: 200}
        next.ServeHTTP(ww, r)
        logger.Info("req",
            "method", r.Method,
            "path", r.URL.Path,
            "status", ww.code,
            "dur", time.Since(start),
            "ua", r.UserAgent(),
            "ip", r.RemoteAddr,
        )
    })
}

type wr struct {
    http.ResponseWriter
    code int
}

func (w *wr) WriteHeader(statusCode int) {
    w.code = statusCode
    w.ResponseWriter.WriteHeader(statusCode)
}

