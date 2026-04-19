#!/bin/bash

# 火山CodingPlan API测试脚本
# 用于验证最小有效认证参数

BASE_URL="https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage"

# 测试1: 完整原始请求
echo "=== 测试1: 完整原始请求 ==="
curl "$BASE_URL" \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: zh' \
  -H 'content-type: application/json' \
  -b 'volc_platform_clear_user_locale=1; user_locale=zh; monitor_huoshan_web_id=9757832638104721526; connect.sid=s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY; connect.sid=s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY; i18next=zh; __spti=11_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC; __sptiho=4411_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC_bEv/KoxCOM4AcC; __spti=11_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC; __sptiho=4411_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC_bEv/KoxCOM4AcC; volcfe-uuid=d7f71d91-fb33-4afe-9899-699dc5b8ba32; signin_i18next=zh; hasUserBehavior=1; isIntranet=0; VOLCFE_im_uuid=1776526452271061348; digest=eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5YzBkZmFjYmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0.eyJhdWQiOlsiY29uc29sZS52b2xjZW5naW5lLmNvbSJdLCJleHAiOjE3NzY2OTkyNjAsImlhdCI6MTc3NjUyNjQ2MCwiaXNzIjoiaHR0cHM6Ly9zaWduaW4udm9sY2VuZ2luZS5jb20iLCJqdGkiOiI2N2RjNDA3MS0yNDRkLTRlYmUtODVmNy1kNjA2ZGIwZjQyMTQiLCJtc2ciOiJINHNJQUFBQUFBQUMvK0t5NW1KelM4MHN6aWdWVXM3UGkwK3hTRXN5dDBpelRFMHpzVEJQTmpGUE5ETXdUekZNdGpRME03QklNekJJa3ZoOG91ODhtOElmRUtuQktHVE94ZTZZbkp4Zm1sY2ljUDMzeGcvc1VsekYrWG5wT1ltWlJhV1pTbEJ6dGRpUzgzTno4L084a09RQUFRQUEvLzhDdEEzZmRnQUFBQT09IiwibmFtZSI6InNvbmdsYWlydWkiLCJzY29wZXMiOm51bGwsInN1YiI6IjIxMTQ3NDc4NjMiLCJ0b3BpYyI6InNpZ25pbl9jcmVkZW50aWFsIiwidHJuIjoidHJuOmlhbTo6MjExNDc0Nzg2Mzpyb290IiwidmVyc2lvbiI6InYxIiwiemlwIjoiZ3ppcCJ9.gHwryqgAXUoAl0eow5KAXRdKpQrgSOZgLnH9tGVOWQTaDM28BADV74OEcCnG4NKLOSDEW0O-zsAK5Kf9iKgXsmcaXK1G9bNyAyPy51kCDLZ8bsf8UjlnvvatCM-PIzLZ9MwRm7A-1jIC6VkctIQZvk-NCv_6TBaGjMXco2nFzee-9fqjInw8OofZzD9zwyB4cwG0xoe_kHthRmmOm03Vqu8VmsF9uHTO1HRmRlq5jT6d41T8t9ZWI4pEkPG8jE0R2LAX9l17aiFGWHn-XryLORIwnvZdfUdwo4mP470EaEac5wy7s6cxVDkn7M1kx4AGer-5EESjBcG3XmN8NTOUqQ; AccountID=2114747863; AccountID=2114747863; userInfo=eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5ZDM1YTQ4YmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0.eyJhY2NfaSI6MjExNDc0Nzg2MywiYXVkIjpbImNvbnNvbGUudm9sY2VuZ2luZS5jb20iXSwiZXhwIjoxNzc5MTE4NDYwLCJpIjoiMTFlMDQ2ZGQzYjNjMTFmMWE3YzQzNDM2YWMxMjAxN2UiLCJpZF9uIjoic29uZ2xhaXJ1aSIsIm1zZyI6bnVsbCwicGlkIjoiNjdkYzQwNzEtMjQ0ZC00ZWJlLTg1ZjctZDYwNmRiMGY0MjE0Iiwic3NfbiI6InNvbmdsYWlydWkiLCJ0IjoiQWNjb3VudCIsInRvcGljIjoic2lnbmluX3VzZXJfaW5mbyIsInZlcnNpb24iOiJ2MSIsInppcCI6IiJ9.ei9rI1WV2evBiQzqLlZdOaVXqiC6VMZYiQuvXfYlM1UceUpkSJB6pjLoBYlmvg76H74Spy_xCXoWpqNi2LY4DDaLq-DBC4d5Au7gD-3dV_MR868Io-cx1q2NeNg6xuu-CttZBEplQnj7jWQMKwFTZvWlOe5Df2bfQeLmAlxkxG6UjiZNghdNKnhLPE983wpcg-8t3gjc3J2teGj95LebWJQ4xWcC3ekviLuQv2HxNsw_JsMX3uqYRDLHNWbuvsN0KPRnJklKqaOrL8EMhCYiAKtEps0o_u3oB7OSU3uLwTw-Q7cawc6b6-1aMwlAC7H9UAXGJq-PTOAaOGaazu-iTA; gfkadpd=520918,36088; acw_tc=b738aca717765876856935206e723442e7e8ae3e8da50cd061505f7998; cdn_sec_tc=b738aca717765876856935206e723442e7e8ae3e8da50cd061505f7998; csrfToken=2f237a038f098f0ee7a4653b18389e09; csrfToken=2f237a038f098f0ee7a4653b18389e09; p_c_check=1; vcloudWebId=61cdeb30-4702-4c9e-9658-2dde9627675f; monitor_session_id=5267646869118971021; monitor_session_id_flag=1; volc-design-locale=zh; s_v_web_id=202604191634472016268DA45F04FCC81B; s_v_web_id=202604191634472016268DA45F04FCC81B; referrer_title=; __tea_cache_tokens_3569={%22web_id%22:%227630122959579530779%22%2C%22user_unique_id%22:%2211_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC%22%2C%22timestamp%22:1776587719731%2C%22_type_%22:%22default%22}; user_locale=zh' \
  -H 'origin: https://console.volcengine.com' \
  -H 'priority: u=1, i' \
  -H 'referer: https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application' \
  -H 'sec-ch-ua: "Google Chrome";v="147", "Not.A/Brand";v="8", "Chromium";v="147"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36' \
  -H 'x-csrf-token: 2f237a038f098f0ee7a4653b18389e09' \
  -H 'x-web-id: U2FsdGVkX1+FfkkkM6AfxOm5bOZvoJhbwwbugyu4sjlHOfq9B/kQXwkgx+HuMNdb' \
  --data-raw '{}'

echo -e "\n\n=== 测试2: 最小化请求 ==="
curl "$BASE_URL" \
  -H 'content-type: application/json' \
  -H 'referer: https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application' \
  -H 'origin: https://console.volcengine.com' \
  -H 'x-csrf-token: 2f237a038f098f0ee7a4653b18389e09' \
  -b 'connect.sid=s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY; digest=eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5YzBkZmFjYmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0.eyJhdWQiOlsiY29uc29sZS52b2xjZW5naW5lLmNvbSJdLCJleHAiOjE3NzY2OTkyNjAsImlhdCI6MTc3NjUyNjQ2MCwiaXNzIjoiaHR0cHM6Ly9zaWduaW4udm9sY2VuZ2luZS5jb20iLCJqdGkiOiI2N2RjNDA3MS0yNDRkLTRlYmUtODVmNy1kNjA2ZGIwZjQyMTQiLCJtc2ciOiJINHNJQUFBQUFBQUMvK0t5NW1KelM4MHN6aWdWVXM3UGkwK3hTRXN5dDBpelRFMHpzVEJQTmpGUE5ETXdUekZNdGpRME03QklNekJJa3ZoOG91ODhtOElmRUtuQktHVE94ZTZZbkp4Zm1sY2ljUDMzeGcvc1VsekYrWG5wT1ltWlJhV1pTbEJ6dGRpUzgzTno4L084a09RQUFRQUEvLzhDdEEzZmRnQUFBQT09IiwibmFtZSI6InNvbmdsYWlydWkiLCJzY29wZXMiOm51bGwsInN1YiI6IjIxMTQ3NDc4NjMiLCJ0b3BpYyI6InNpZ25pbl9jcmVkZW50aWFsIiwidHJuIjoidHJuOmlhbTo6MjExNDc0Nzg2Mzpyb290IiwidmVyc2lvbiI6InYxIiwiemlwIjoiZ3ppcCJ9.gHwryqgAXUoAl0eow5KAXRdKpQrgSOZgLnH9tGVOWQTaDM28BADV74OEcCnG4NKLOSDEW0O-zsAK5Kf9iKgXsmcaXK1G9bNyAyPy51kCDLZ8bsf8UjlnvvatCM-PIzLZ9MwRm7A-1jIC6VkctIQZvk-NCv_6TBaGjMXco2nFzee-9fqjInw8OofZzD9zwyB4cwG0xoe_kHthRmmOm03Vqu8VmsF9uHTO1HRmRlq5jT6d41T8t9ZWI4pEkPG8jE0R2LAX9l17aiFGWHn-XryLORIwnvZdfUdwo4mP470EaEac5wy7s6cxVDkn7M1kx4AGer-5EESjBcG3XmN8NTOUqQ; csrfToken=2f237a038f098f0ee7a4653b18389e09' \
  --data-raw '{}'

echo -e "\n\n=== 测试3: 仅核心认证参数 ==="
curl "$BASE_URL" \
  -H 'content-type: application/json' \
  -H 'x-csrf-token: 2f237a038f098f0ee7a4653b18389e09' \
  -b 'connect.sid=s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY; csrfToken=2f237a038f098f0ee7a4653b18389e09' \
  --data-raw '{}'
