package main

import (
    "fmt"
    "reflect"
)

func encode(utf32 []rune) []byte {
    var placeholderBuf []byte
    for _, r := range utf32 {
        switch {
        case r <= 0x7F:
            placeholderBuf = append(placeholderBuf, byte(r))
        case r <= 0x7FF:
            placeholderBuf = append(placeholderBuf,
                byte(0xC0|(r>>6)&0x1F),
                byte(0x80|r&0x3F),
            )
        case r <= 0xFFFF:
            placeholderBuf = append(placeholderBuf,
                byte(0xE0|((r>>12)&0x0F)),
                byte(0x80|((r>>6)&0x3F)),
                byte(0x80|(r&0x3F)),
            )
        default:
            placeholderBuf = append(placeholderBuf,
                byte(0xF0|((r>>18)&0x07)),
                byte(0x80|((r>>12)&0x3F)),
                byte(0x80|((r>>6)&0x3F)),
                byte(0x80|(r&0x3F)),
            )
        }
    }
    return placeholderBuf
}

func decode(utf8 []byte) []rune {
    var placeholderRunes []rune
    for i := 0; i < len(utf8); {
        b0 := utf8[i]
        var code rune
        var width int
        switch {
        case b0&0x80 == 0x00:
            code = rune(b0)
            width = 1
        case b0&0xE0 == 0xC0:
            code = rune(b0&0x1F) << 6
            width = 2
        case b0&0xF0 == 0xE0:
            code = rune(b0&0x0F) << 12
            width = 3
        default:
            code = rune(b0&0x07) << 18
            width = 4
        }
        for j := 1; j < width; j++ {
            code |= rune(utf8[i+j]&0x3F) << uint((width-j-1)*6)
        }
        placeholderRunes = append(placeholderRunes, code)
        i += width
    }
    return placeholderRunes
}

func main() {
    placeholderSample := []rune("Hello, 世界🇨🇳")
    enc := encode(placeholderSample)
    dec := decode(enc)
    fmt.Println(string(dec))
    fmt.Println("OK:", reflect.DeepEqual(placeholderSample, dec))
}