# 火山CodingPlan API 接口分析

## 基础信息
- **接口地址**: `https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage`
- **请求方法**: POST
- **内容类型**: `application/json`
- **请求体**: `{}` (空对象)

## 认证参数分析
### 原始Cookie字段列表
```
1. volc_platform_clear_user_locale=1
2. user_locale=zh
3. monitor_huoshan_web_id=9757832638104721526
4. connect.sid=s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY
5. i18next=zh
6. __spti=11_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC
7. __sptiho=4411_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC_bEv/KoxCOM4AcC
8. volcfe-uuid=d7f71d91-fb33-4afe-9899-699dc5b8ba32
9. signin_i18next=zh
10. hasUserBehavior=1
11. isIntranet=0
12. VOLCFE_im_uuid=1776526452271061348
13. digest=eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5YzBkZmFjYmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0.eyJhdWQiOlsiY29uc29sZS52b2xjZW5naW5lLmNvbSJdLCJleHAiOjE3NzY2OTkyNjAsImlhdCI6MTc3NjUyNjQ2MCwiaXNzIjoiaHR0cHM6Ly9zaWduaW4udm9sY2VuZ2luZS5jb20iLCJqdGkiOiI2N2RjNDA3MS0yNDRkLTRlYmUtODVmNy1kNjA2ZGIwZjQyMTQiLCJtc2ciOiJINHNJQUFBQUFBQUMvK0t5NW1KelM4MHN6aWdWVXM3UGkwK3hTRXN5dDBpelRFMHpzVEJQTmpGUE5ETXdUekZNdGpRME03QklNekJJa3ZoOG91ODhtOElmRUtuQktHVE94ZTZZbkp4Zm1sY2ljUDMzeGcvc1VsekYrWG5wT1ltWlJhV1pTbEJ6dGRpUzgzTno4L084a09RQUFRQUEvLzhDdEEzZmRnQUFBQT09IiwibmFtZSI6InNvbmdsYWlydWkiLCJzY29wZXMiOm51bGwsInN1YiI6IjIxMTQ3NDc4NjMiLCJ0b3BpYyI6InNpZ25pbl9jcmVkZW50aWFsIiwidHJuIjoidHJuOmlhbTo6MjExNDc0Nzg2Mzpyb290IiwidmVyc2lvbiI6InYxIiwiemlwIjoiZ3ppcCJ9.gHwryqgAXUoAl0eow5KAXRdKpQrgSOZgLnH9tGVOWQTaDM28BADV74OEcCnG4NKLOSDEW0O-zsAK5Kf9iKgXsmcaXK1G9bNyAyPy51kCDLZ8bsf8UjlnvvatCM-PIzLZ9MwRm7A-1jIC6VkctIQZvk-NCv_6TBaGjMXco2nFzee-9fqjInw8OofZzD9zwyB4cwG0xoe_kHthRmmOm03Vqu8VmsF9uHTO1HRmRlq5jT6d41T8t9ZWI4pEkPG8jE0R2LAX9l17aiFGWHn-XryLORIwnvZdfUdwo4mP470EaEac5wy7s6cxVDkn7M1kx4AGer-5EESjBcG3XmN8NTOUqQ
14. AccountID=2114747863
15. userInfo=eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5ZDM1YTQ4YmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0.eyJhY2NfaSI6MjExNDc0Nzg2MywiYXVkIjpbImNvbnNvbGUudm9sY2VuZ2luZS5jb20iXSwiZXhwIjoxNzc5MTE4NDYwLCJpIjoiMTFlMDQ2ZGQzYjNjMTFmMWE3YzQzNDM2YWMxMjAxN2UiLCJpZF9uIjoic29uZ2xhaXJ1aSIsIm1zZyI6bnVsbCwicGlkIjoiNjdkYzQwNzEtMjQ0ZC00ZWJlLTg1ZjctZDYwNmRiMGY0MjE0Iiwic3NfbiI6InNvbmdsYWlydWkiLCJ0IjoiQWNjb3VudCIsInRvcGljIjoic2lnbmluX3VzZXJfaW5mbyIsInZlcnNpb24iOiJ2MSIsInppcCI6IiJ9.ei9rI1WV2evBiQzqLlZdOaVXqiC6VMZYiQuvXfYlM1UceUpkSJB6pjLoBYlmvg76H74Spy_xCXoWpqNi2LY4DDaLq-DBC4d5Au7gD-3dV_MR868Io-cx1q2NeNg6xuu-CttZBEplQnj7jWQMKwFTZvWlOe5Df2bfQeLmAlxkxG6UjiZNghdNKnhLPE983wpcg-8t3gjc3J2teGj95LebWJQ4xWcC3ekviLuQv2HxNsw_JsMX3uqYRDLHNWbuvsN0KPRnJklKqaOrL8EMhCYiAKtEps0o_u3oB7OSU3uLwTw-Q7cawc6b6-1aMwlAC7H9UAXGJq-PTOAaOGaazu-iTA
16. gfkadpd=520918,36088
17. acw_tc=b738aca717765876856935206e723442e7e8ae3e8da50cd061505f7998
18. cdn_sec_tc=b738aca717765876856935206e723442e7e8ae3e8da50cd061505f7998
19. csrfToken=2f237a038f098f0ee7a4653b18389e09
20. p_c_check=1
21. vcloudWebId=61cdeb30-4702-4c9e-9658-2dde9627675f
22. monitor_session_id=5267646869118971021
23. monitor_session_id_flag=1
24. volc-design-locale=zh
25. s_v_web_id=202604191634472016268DA45F04FCC81B
26. referrer_title=
27. __tea_cache_tokens_3569={%22web_id%22:%227630122959579530779%22%2C%22user_unique_id%22:%2211_000J3CKcFHQPtPrMwlQ3ilQxfn2UtC%22%2C%22timestamp%22:1776587719731%2C%22_type_%22:%22default%22}
28. user_locale=zh
```

### 必需参数初步筛选
根据常规WEB认证逻辑，以下参数是可能必需的：

#### Cookie 字段
1. **connect.sid**: 会话ID，核心认证凭证
2. **digest**: JWT令牌，包含认证信息和过期时间
3. **userInfo**: JWT令牌，包含用户信息
4. **AccountID**: 账号ID
5. **csrfToken**: CSRF防护令牌

#### 请求头字段
1. **x-csrf-token**: 必须和Cookie中的csrfToken值一致
2. **content-type**: 必须为 `application/json`
3. **referer**: 可能需要，防止跨站请求伪造
4. **origin**: 可能需要

### 过期时间分析
从JWT令牌中解析过期时间：
1. **digest令牌**: 
   - 签发时间(iat): 1776526460 → 2026-04-18 12:54:20
   - 过期时间(exp): 1776699260 → 2026-04-20 12:54:20
   - **有效期**: 48小时 (2天)

2. **userInfo令牌**:
   - 签发时间(iat): 未直接显示但和digest相近
   - 过期时间(exp): 1779118460 → 2026-05-18 12:54:20
   - **有效期**: 30天

### 最小有效请求预测
```bash
curl 'https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage?' \
  -H 'content-type: application/json' \
  -H 'referer: https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application' \
  -H 'origin: https://console.volcengine.com' \
  -H 'x-csrf-token: 2f237a038f098f0ee7a4653b18389e09' \
  -b 'connect.sid=s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY; digest=eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5YzBkZmFjYmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0.eyJhdWQiOlsiY29uc29sZS52b2xjZW5naW5lLmNvbSJdLCJleHAiOjE3NzY2OTkyNjAsImlhdCI6MTc3NjUyNjQ2MCwiaXNzIjoiaHR0cHM6Ly9zaWduaW4udm9sY2VuZ2luZS5jb20iLCJqdGkiOiI2N2RjNDA3MS0yNDRkLTRlYmUtODVmNy1kNjA2ZGIwZjQyMTQiLCJtc2ciOiJINHNJQUFBQUFBQUMvK0t5NW1KelM4MHN6aWdWVXM3UGkwK3hTRXN5dDBpelRFMHpzVEJQTmpGUE5ETXdUekZNdGpRME03QklNekJJa3ZoOG91ODhtOElmRUtuQktHVE94ZTZZbkp4Zm1sY2ljUDMzeGcvc1VsekYrWG5wT1ltWlJhV1pTbEJ6dGRpUzgzTno4L084a09RQUFRQUEvLzhDdEEzZmRnQUFBQT09IiwibmFtZSI6InNvbmdsYWlydWkiLCJzY29wZXMiOm51bGwsInN1YiI6IjIxMTQ3NDc4NjMiLCJ0b3BpYyI6InNpZ25pbl9jcmVkZW50aWFsIiwidHJuIjoidHJuOmlhbTo6MjExNDc0Nzg2Mzpyb290IiwidmVyc2lvbiI6InYxIiwiemlwIjoiZ3ppcCJ9.gHwryqgAXUoAl0eow5KAXRdKpQrgSOZgLnH9tGVOWQTaDM28BADV74OEcCnG4NKLOSDEW0O-zsAK5Kf9iKgXsmcaXK1G9bNyAyPy51kCDLZ8bsf8UjlnvvatCM-PIzLZ9MwRm7A-1jIC6VkctIQZvk-NCv_6TBaGjMXco2nFzee-9fqjInw8OofZzD9zwyB4cwG0xoe_kHthRmmOm03Vqu8VmsF9uHTO1HRmRlq5jT6d41T8t9ZWI4pEkPG8jE0R2LAX9l17aiFGWHn-XryLORIwnvZdfUdwo4mP470EaEac5wy7s6cxVDkn7M1kx4AGer-5EESjBcG3XmN8NTOUqQ; csrfToken=2f237a038f098f0ee7a4653b18389e09' \
  --data-raw '{}'
```

### 验证计划
我们需要逐步剔除参数，找到最小有效集：
1. 先测试完整请求是否有效
2. 逐步移除非关键cookie字段
3. 测试移除不必要的请求头
4. 最终确定最小必需参数
