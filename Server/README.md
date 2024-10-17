# START THE SERVER

`docker-compose up --build`

## Routes

### Neuen Nutzer registrieren

`localhost:8080/client/register`

**Headers:**

| Headers | HeaderContent |
| ------: | ------------: |
|       / |             / |

**Request-Body:**

```json
{
 "username": "john-doe",
 "password": "securePassword123",
 "email": "john-doe@example.com"
}
```

**Response-Body:**

```json
{
    "message": "Successfully logged in"
}
```

### Nutzer einloggen

`localhost:8080/client/login`

**Headers:**

| Headers | HeaderContent |
| ------: | ------------: |
|       / |             / |

**Body:**

```json
{
 "username": "john-doe",
 "password": "securePassword123"
}
```

**Response-Body:**

```json
{
    "message": "Successfully logged in",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Mjk0MzIzNjEsInVzZXJfaWQiOiI1In0.nkpxPoxrfEP5YDNa4budxLRa12xk1YC1ASrp4wdxY74"
}
```

### Template

`localhost:8080/`

**Headers:**

|       Headers |                              HeaderContent |
| ------------: | -----------------------------------------: |
| Authorization | `"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6..."` |

**Body:**

```json
{
}
```

**Response-Body:**

```json
{
}
```
