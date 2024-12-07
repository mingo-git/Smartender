# Smartender

## Deployment:

### 1. Image bauen:
```bash
docker build -t gcr.io/gothic-sequence-443115-v5/smartender:latest .               
```

### 2. Image pushen:
```bash
docker push gcr.io/gothic-sequence-443115-v5/smartender:latest
```

### 3. Befehl um das neuste Image zu deployen:
```bash
cloud run services update smartender --image gcr.io/gothic-sequence-443115-v5/smartender:latest --region europe-west3
```****