import subprocess
import tempfile
import time
import yaml
from curl_cffi import requests

HYSTERIA2_URL = "hysteria2://AramaMama1488@194.31.204.53:6001?sni=www.bing.com&insecure=1"
SOCKS5 = "socks5://127.0.0.1:1080"

config = {
    "server": "194.31.204.53:6001",
    "auth": "AramaMama1488",
    "tls": {"sni": "www.bing.com", "insecure": True},
    "socks5": {"listen": "127.0.0.1:1080"},
}

tmp = tempfile.NamedTemporaryFile("w", suffix=".yml", delete=False)
yaml.dump(config, tmp)
tmp.close()

proc = subprocess.Popen(["hysteria", "client", "-c", tmp.name])
time.sleep(2)

try:
    r = requests.get(
        "https://api.ipify.org?format=json",
        proxies={"https": SOCKS5, "http": SOCKS5},
        impersonate="chrome124",
        timeout=10,
    )
    print(r.json())
finally:
    proc.terminate()
