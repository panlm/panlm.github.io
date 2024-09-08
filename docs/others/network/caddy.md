---
title: caddy
description: a fast, multi-platform web server with automatic HTTPS.
created: 2024-09-06 23:26:53.318
last_modified: 2024-09-06
tags:
  - draft
---

# caddy

## install
homepage: https://webinstall.dev/caddy/
refer: https://github.com/ollama/ollama/issues/849#issuecomment-1773697189
```
curl https://webi.sh/caddy | sh

```
- or
```sh
brew install caddy

```

## sample 
### tls and acme_server
Caddyfile
```
{
	pki {
		ca home {
			name "My Home CA"
		}
	}
}

api.panlm.com {
	acme_server {
		ca home
	}
	tls {
		issuer internal {
			ca home
		}
	}
	handle {
		reverse_proxy localhost:11434
	}
}

localhost {
	handle {
		reverse_proxy localhost:11434
	}
}

```


### basic-http-auth-
- save your plain text password in password.txt
```sh
caddy hash-password < ./password.txt

```
- forward
```
localhost {
	handle {
		basic_auth {
			apitoken $214$ccccc
		}
		reverse_proxy localhost:11434
	}
}

```

