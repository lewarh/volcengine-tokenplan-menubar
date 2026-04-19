# JWT令牌解析与过期时间分析

## Digest 令牌解析
### Header
```json
{
  "alg": "RS256",
  "kid": "a9c0dfacbfb411f089c000163e0708bd"
}
```

### Payload
```json
{
  "aud": ["console.volcengine.com"],
  "exp": 1776699260,
  "iat": 1776526460,
  "iss": "https://signin.volcengine.com",
  "jti": "67dc4071-244d-4ebe-85f7-d606db0f4214",
  "msg": "H4sIAAAAAAAC/+Ky5mJzS80szigVUs7Pi0+xSEsyt0izTE0zsTBPNjFPNDMwTzFMtjQ0M7BIMzBIkvh8ou88m8IfEKnBKGToxe6YnxJfmlcicP33xg/sUlzF+XnpOYmZRaWZSlBztdiS83Nz8/O8kOQAAAQA//8CtA3fdgAAAA==",
  "name": "songlairui",
  "scopes": null,
  "sub": "2114747863",
  "topic": "signin_credential",
  "trn": "trn:iam::2114747863:root",
  "version": "v1",
  "zip": "gzip"
}
```

### 时间信息
- **签发时间(iat)**: 1776526460 → 2026-04-18 12:54:20 (UTC+8)
- **过期时间(exp)**: 1776699260 → 2026-04-20 12:54:20 (UTC+8)
- **有效时长**: 48小时 (2天)

## UserInfo 令牌解析
### Header
```json
{
  "alg": "RS256",
  "kid": "a9d35a48bfb411f089c000163e0708bd"
}
```

### Payload
```json
{
  "acc_i": 2114747863,
  "aud": ["console.volcengine.com"],
  "exp": 1779118460,
  "i": "11e046dd3b3c11f1a7c43436ac12017e",
  "id_n": "songlairui",
  "msg": null,
  "pid": "67dc4071-244d-4ebe-85f7-d606db0f4214",
  "ss_n": "songlairui",
  "t": "Account",
  "topic": "signin_user_info",
  "version": "v1",
  "zip": ""
}
```

### 时间信息
- **过期时间(exp)**: 1779118460 → 2026-05-18 12:54:20 (UTC+8)
- **有效时长**: 30天

## 认证机制分析
1. **短期凭证**: `digest` 令牌有效期2天，是核心认证凭证
2. **长期凭证**: `userInfo` 令牌有效期30天，包含用户基本信息
3. **会话机制**: `connect.sid` 是会话ID，可能和digest绑定
4. **CSRF防护**: `csrfToken` 用于防止跨站请求伪造，和会话绑定

## 过期策略推测
- 每次登录会重新签发新的digest令牌，有效期重置为2天
- userInfo令牌有效期30天，可能用于保持登录状态
- 当digest过期后，可能可以用userInfo或者refresh token来刷新
- 完全过期后需要重新登录
