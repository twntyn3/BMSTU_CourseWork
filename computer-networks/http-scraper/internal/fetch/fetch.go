package fetch

import (
    "context"
    "errors"
    "io"
    "net"
    "net/http"
    "time"
)

var ErrTooLarge = errors.New("response too large")

func NewClient() *http.Client {
    tr := &http.Transport{
        Proxy:                 http.ProxyFromEnvironment,
        DisableKeepAlives:     false,
        MaxIdleConns:          100,
        IdleConnTimeout:       30 * time.Second,
        TLSHandshakeTimeout:   10 * time.Second,
        ExpectContinueTimeout: 1 * time.Second,
        DialContext: (&net.Dialer{
            Timeout:   5 * time.Second,
            KeepAlive: 30 * time.Second,
        }).DialContext,
    }
    return &http.Client{
        Timeout:   12 * time.Second,
        Transport: tr,
    }
}

func Get(ctx context.Context, c *http.Client, url string, maxBytes int64) ([]byte, string, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return nil, "", err
    }
    // добавили «человеческие» заголовки
    req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36")
    req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
    req.Header.Set("Accept-Language", "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7")

    resp, err := c.Do(req)
    if err != nil {
        return nil, "", err
    }
    defer resp.Body.Close()

    if resp.StatusCode < 200 || resp.StatusCode >= 300 {
        return nil, "", errors.New(resp.Status)
    }

    lr := &io.LimitedReader{R: resp.Body, N: maxBytes}
    data, err := io.ReadAll(lr)
    if err != nil {
        return nil, "", err
    }
    if lr.N == 0 {
        return nil, "", ErrTooLarge
    }
    return data, resp.Header.Get("Content-Type"), nil
}

