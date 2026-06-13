package handlers

import (
	"io"
	"net"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"time"

	"github.com/gofiber/fiber/v2"
)

var proxyClient = func() *http.Client {
	jar, _ := cookiejar.New(nil)
	return &http.Client{
		Jar:     jar,
		Timeout: 15 * time.Second,
	}
}()

// isProxyAllowed blocks SSRF: loopback, private, and link-local IPs are rejected.
// Hostnames (including IDN) are allowed — DNS resolution happens inside proxyClient.Do.
func isProxyAllowed(u *url.URL) bool {
	if u.Scheme != "https" && u.Scheme != "http" {
		return false
	}
	host := u.Hostname()
	ip := net.ParseIP(host)
	if ip == nil {
		return true // domain name — allow
	}
	return !ip.IsLoopback() && !ip.IsPrivate() && !ip.IsLinkLocalUnicast() && !ip.IsLinkLocalMulticast()
}

// ProxyImage proxies external images that use cookie-based redirect protection (Bitrix CMS)
// or have non-ASCII (IDN/Cyrillic) hostnames that Dart's Uri cannot parse.
// GET /proxy/image?url=https://rskrf.ru/...
func ProxyImage(c *fiber.Ctx) error {
	rawURL := c.Query("url")
	if rawURL == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "url query param required"})
	}

	parsed, err := url.Parse(rawURL)
	if err != nil || !parsed.IsAbs() {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid url"})
	}

	if !isProxyAllowed(parsed) {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "host not allowed"})
	}

	req, err := http.NewRequestWithContext(c.UserContext(), http.MethodGet, rawURL, nil)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to build request"})
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36")
	req.Header.Set("Accept", "image/webp,image/apng,image/*,*/*;q=0.8")
	req.Header.Set("Referer", parsed.Scheme+"://"+parsed.Host+"/")

	resp, err := proxyClient.Do(req)
	if err != nil {
		return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": err.Error()})
	}
	defer resp.Body.Close()

	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "image/jpeg"
	}
	c.Set("Content-Type", contentType)
	c.Set("Cache-Control", "public, max-age=86400")

	c.Status(resp.StatusCode)
	_, err = io.Copy(c.Response().BodyWriter(), resp.Body)
	return err
}
