import requests
import json

# Вставляешь свой JSON с куками
raw_cookies = [
  {
    "domain": ".kuper.ru",
    "expirationDate": 1814354627,
    "hostOnly": False,
    "httpOnly": False,
    "name": "_pk_id.6.ef9f",
    "path": "/",
    "sameSite": "lax",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "81bf826241835710.1780399427."
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1795740425,
    "hostOnly": False,
    "httpOnly": False,
    "name": "_sv",
    "path": "/",
    "sameSite": "strict",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "SV1.011eaf99-0377-4aea-ac21-a8576786b72a.1780186368"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811724665,
    "hostOnly": False,
    "httpOnly": False,
    "name": "_ym_d",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "1780188665"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1780471428,
    "hostOnly": False,
    "httpOnly": False,
    "name": "_ym_isad",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "1"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811724665,
    "hostOnly": False,
    "httpOnly": False,
    "name": "_ym_uid",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "1780188665763027497"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811935449,
    "hostOnly": False,
    "httpOnly": False,
    "name": "adtech_uid",
    "path": "/",
    "sameSite": "unspecified",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "e4967d65-d877-4993-b86c-e7da61744c5d%3Akuper.ru"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1814983074.005287,
    "hostOnly": False,
    "httpOnly": False,
    "name": "directCrm-session",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "%7B%22deviceGuid%22%3A%22af80f01a-37b1-4a08-b657-50df09528f27%22%7D"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1814959427.590033,
    "hostOnly": False,
    "httpOnly": False,
    "name": "iap.uid",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "9f72391bd3da477c8a980c2443d88172"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1814983074.00392,
    "hostOnly": False,
    "httpOnly": False,
    "name": "mindboxDeviceUUID",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "af80f01a-37b1-4a08-b657-50df09528f27"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/_next/data/3-NIEMISkBVTQ_9uQfJ_y/SPARMiddleVolga",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/_next/data/tF9_0Yx2lrgcS_pFdWhee/SPARMiddleVolga",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/_next/data/tF9_0Yx2lrgcS_pFdWhee",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/SPARMiddleVolga/c",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/SPARMiddleVolga",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/job",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "hostOnly": False,
    "httpOnly": False,
    "name": "mobile-web-supernova",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "False"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1795975073,
    "hostOnly": False,
    "httpOnly": False,
    "name": "popmechanic_sbjs_migrations",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "popmechanic_1418474375998%3D1%7C%7C%7C1471519752600%3D1%7C%7C%7C1471519752605%3D1"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811959072,
    "hostOnly": False,
    "httpOnly": False,
    "name": "rl_anonymous_id",
    "path": "/",
    "sameSite": "lax",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "RS_ENC_v3_ImE5MjJjNmUyLWQwZWEtNDliZC04ZmJhLTNiY2MzZjk3YzQ1NCI%3D"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811959072,
    "hostOnly": False,
    "httpOnly": False,
    "name": "rl_page_init_referrer",
    "path": "/",
    "sameSite": "lax",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "RS_ENC_v3_Imh0dHBzOi8va3VwZXIucnUvY2F0ZWdvcmllcy9rYW50c3RvdmFyaS9wcm9kdWt0eS1waXRhbmlpYSI%3D"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811959072,
    "hostOnly": False,
    "httpOnly": False,
    "name": "rl_page_init_referring_domain",
    "path": "/",
    "sameSite": "lax",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "RS_ENC_v3_Imt1cGVyLnJ1Ig%3D%3D"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811959072,
    "hostOnly": False,
    "httpOnly": False,
    "name": "rl_session",
    "path": "/",
    "sameSite": "lax",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "RS_ENC_v3_eyJhdXRvVHJhY2siOnRydWUsInRpbWVvdXQiOjE4MDAwMDAsImV4cGlyZXNBdCI6MTc4MDQyNDg3Mjk2OCwiaWQiOjE3ODA0MjI4OTU5OTYsInNlc3Npb25TdGFydCI6ZmFsc2V9"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811959072,
    "hostOnly": False,
    "httpOnly": False,
    "name": "rl_trait",
    "path": "/",
    "sameSite": "lax",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "RS_ENC_v3_eyJldmVudFRlbmFudCI6InNiZXJtYXJrZXQiLCJvcGVuTW9kZSI6IndlYiIsImVtYmVkZGluZ1BsYXRmb3JtIjoid2ViIiwic2Vzc2lvbklkIjoiMTc4MDQyMjg5OTkzMDE3NDY5NjkwMjUiLCJzaGlwcGluZ01ldGhvZEtpbmQiOiJieV9jb3VyaWVyIiwiY29tcGFueUlkIjoiIiwicmVsZWFzZSI6InIyNi0wNS0yOC05NzMtYzY3YTBhZjQiLCJ0YXJnZXREZXZpY2UiOiJtb2JpbGUiLCJzdG9yZUlkIjo5NjAsInN0b3JlVXVpZCI6ImNlODU4ZDhiLTU4NWUtNDg1My05YmM0LTBhNmY3N2VlMjg5NyIsInJldGFpbGVySWQiOjEyMiwib3JkZXJJZCI6IlI4MjE5NDQyNzgifQ%3D%3D"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811952333.039574,
    "hostOnly": False,
    "httpOnly": False,
    "name": "t3_sid_7588506",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "s1.953499816.1780399428085.1780416333039.1.26.6.1.."
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1811935449.957651,
    "hostOnly": False,
    "httpOnly": False,
    "name": "top100_id",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "t1.7588506.178565644.1780399428083"
  },
  {
    "domain": ".kuper.ru",
    "expirationDate": 1814748425,
    "hostOnly": False,
    "httpOnly": False,
    "name": "uxs_uid",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "3f23f780-5c8a-11f1-b086-4f06cb93011a"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1811935428,
    "hostOnly": True,
    "httpOnly": False,
    "name": "__ldr_auto_key",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "ab573054-c6c8-4625-af88-f179c8a248c2"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1783015071.140831,
    "hostOnly": True,
    "httpOnly": False,
    "name": "_808db7ba1248",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "%5B%7B%22source%22%3A%22kuper.ru%22%2C%22medium%22%3A%22referral%22%2C%22cookie_changed_at%22%3A1780423071%7D%2C%7B%22source%22%3A%22%28direct%29%22%2C%22medium%22%3A%22%28none%29%22%2C%22cookie_changed_at%22%3A1780337959%7D%2C%7B%22source%22%3A%22www.google.com%22%2C%22medium%22%3A%22referral%22%2C%22cookie_changed_at%22%3A1780255760%7D%5D"
  },
  {
    "domain": "kuper.ru",
    "hostOnly": True,
    "httpOnly": True,
    "name": "_Instamart_session",
    "path": "/",
    "sameSite": "lax",
    "secure": True,
    "session": True,
    "storeId": "0",
    "value": "a2F0UVg4c0xkaVcvWk8wNld4T3doUDdUTEdNQmNjNnBVazVRNU9qWGhTOGhvaXByREUybTk2MExLeGtjdVR1WVdnY2hvWGZ4d3ZsMSt2aUx2S3pTenozTWlROTFFc0xoa2JGNFFaK0JtRk9mZWRLMzZBQk40YjdGenhFTC9rOXZNMGViRkxid2E2TmZOWGloeHp4QVpOL3hxOExEOWwrNVJjRk9QWElUeEh3aVp0NmpZSVd2eGFidWdqeXFGYWdHbmR4aUFLRlFpQ3FlUlVJelpzZVhJeWU1OFUrVlE4MklLQ2ZGUDVaM05LVERKUHE1NGg3YkNGQzhYWlhEcytRLy9DMTlpTVNRVmpFU0JhYno0Y1kxVnc9PS0tZGJOcnZyL3YzaklTS0tHL0QySE95dz09--17ff77102188c2c7a6f0269a7a6948c9c2f4cff1"
  },
  {
    "domain": "kuper.ru",
    "hostOnly": True,
    "httpOnly": False,
    "name": "cookies_consented",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "yes"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1811724418.044974,
    "hostOnly": True,
    "httpOnly": False,
    "name": "external_analytics_anonymous_id",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "a922c6e2-d0ea-49bd-8fba-3bcc3f97c454"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1811728723,
    "hostOnly": True,
    "httpOnly": False,
    "name": "ignore_resemble_b2b_tag",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "True"
  },
  {
    "domain": "kuper.ru",
    "hostOnly": True,
    "httpOnly": False,
    "name": "OnboardingState",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "{%22state%22:{%22viewedOnboardingKeys%22:[]}%2C%22version%22:0}"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1780424871,
    "hostOnly": True,
    "httpOnly": False,
    "name": "sessionId",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": False,
    "storeId": "0",
    "value": "17804228999301746969025"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1814980914.219679,
    "hostOnly": True,
    "httpOnly": False,
    "name": "spid",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "1780188418489_c4b8cf31f02a077657281016e3b40d59_qfbr0xkgdbsl6adi"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1814980914.218791,
    "hostOnly": True,
    "httpOnly": False,
    "name": "spjs",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "1780420913073_0650eef6_013526a2_34cca3b5a1d718ab098de56684ecf555_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"
  },
  {
    "domain": "kuper.ru",
    "expirationDate": 1814980914.219552,
    "hostOnly": True,
    "httpOnly": False,
    "name": "spsc",
    "path": "/",
    "sameSite": "no_restriction",
    "secure": True,
    "session": False,
    "storeId": "0",
    "value": "1780420913073_8e27f91b534c05bc3555af012d3316ea_KGiOgsAvkvbnTlaQh2avlu3oAq6xmKFA87KKhvWfM4gZhJcZXHcL-h5tqgw2yJleZ"
  },
  {
    "domain": "kuper.ru",
    "hostOnly": True,
    "httpOnly": False,
    "name": "ssr-breakpoint",
    "path": "/",
    "sameSite": "unspecified",
    "secure": False,
    "session": True,
    "storeId": "0",
    "value": "md"
  }
]

def cookies_to_dict(cookies, domain_filter="kuper.ru"):
    """Фильтрует куки по домену и возвращает простой словарь"""
    result = {}
    for cookie in cookies:
        if cookie["domain"].lstrip(".") == domain_filter:
            result[cookie["name"]] = cookie["value"]
    return result

cookies = cookies_to_dict(raw_cookies)

session = requests.Session()
session.cookies.update(cookies)

headers = {
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36",
    "accept": "application/json, text/plain, */*",
    "accept-language": "ru-RU,ru;q=0.9,en-US;q=0.8",
    "content-type": "application/json",
    "client-id": "SbermarketPlatformWeb",
    "client-token": "7ba97b6f4049436dab90c789f946ee2f",
    "x-csrf-token": "b7LPkEfu3JEZ1AUSKI00Nk/VUft1k4utSEJhNpTRgbKQvT44ksZmqY1f4OiniI9DLh6O+N3BfJq5LPe0ghSw2Q==",
    "origin": "https://kuper.ru",
    "referer": "https://kuper.ru/SPARMiddleVolga/steyk-iz-grudki-indeyki-indilayt-ohlazhdyonnyy-525-g",
    "sbm-forward-tenant": "sbermarket",
}

payload = {
    "context": {
        "device": {"platform": "WEB"},
        "user": {"geo": {}, "ext": {"anonymous_id": cookies.get("external_analytics_anonymous_id")}},
        "site": {
            "domain": "",
            "ext": {
                "store_id": 166800,
                "tenant_id": 0,
                "tenant_name": "sbermarket",
                "skus": ["119494"]
            }
        }
    },
    "ext": {"place": "product_card"}
}

response = session.get(
    "https://kuper.ru/api/v3/stores/241478/departments/katalog-fs2/gotovaya-eda?offers_limit=10&page=1&per_page=3",
    headers=headers,
)

print(response.status_code)
print(json.dumps(response.json(), ensure_ascii=False, indent=2))