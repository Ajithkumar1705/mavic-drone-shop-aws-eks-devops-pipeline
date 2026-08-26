# Mavic Drone Shop — Handoff to DevOps

**From:** Application development
**To:** DevOps / Platform
**Status:** Feature-complete, needs containerization, CI/CD, infra, and monitoring before this goes anywhere near production.

This document is what you'd realistically get handed (maybe as a README, maybe verbally in a hallway) before being asked to "make this deployable." Everything below was pulled directly from the actual source code, not guessed — verify against the code if anything looks off.

---

## Services overview

| Service | Language/Runtime | Purpose | Talks to |
|---|---|---|---|
| `web` | Nginx (reverse proxy) + AngularJS static files | Frontend, routes API calls to backend services | catalogue, user, cart, shipping, payment, ratings |
| `cart` | Node.js | Shopping cart | redis, catalogue |
| `catalogue` | Node.js | Product listing/search | mongodb |
| `user` | Node.js | Accounts, auth, order history | mongodb, redis |
| `payment` | Python | Checkout, publishes order events | cart, user, rabbitmq |
| `shipping` | Java (Spring Boot, Maven build) | Shipping cost calculation | mysql, cart |
| `ratings` | PHP | Product ratings | catalogue, mysql |
| `dispatch` | Go | Consumes order events, simulates fulfillment | rabbitmq |

**Data tier:** MongoDB (catalogue, users), MySQL (ratings, shipping — includes a GeoIP dataset under `mysql/scripts/`), Redis (cart sessions), RabbitMQ (order dispatch queue)

---

## Per-service requirements (env vars, ports, dependencies)

### `web`
- Reverse proxy config needs to be templated — it expects these to resolve to the other services: `CATALOGUE_HOST`, `USER_HOST`, `CART_HOST`, `SHIPPING_HOST`, `PAYMENT_HOST`, `RATINGS_HOST`
- `ratings` is proxied on port 80, everything else on port 8080
- Serves static files from `web/static/` — no build step (no package.json, no bundler), just plain HTML/CSS/JS

### `cart`
- Port: `CART_SERVER_PORT` (default `8080`)
- Env: `REDIS_HOST` (default `redis`), `CATALOGUE_HOST` (default `catalogue`)
- Entry point: `server.js`, deps in `package.json`

### `catalogue`
- Port: `CATALOGUE_SERVER_PORT` (default `8080`)
- Env: `MONGO_URL` (default `mongodb://mongodb:27017/catalogue`), `GO_SLOW` (artificial latency, testing only — don't set in prod)
- Entry point: `server.js`
- **Note:** database is seeded from `mongo/catalogue.js` — ask the dev team how/when this runs; it's not baked into the service itself

### `user`
- Port: `USER_SERVER_PORT` (default `8080`)
- Env: `MONGO_URL` (default `mongodb://mongodb:27017/users`), `REDIS_HOST` (default `redis`)
- Entry point: `server.js`

### `payment`
- Port: `SHOP_PAYMENT_PORT` (default `8080`)
- Env: `CART_HOST` (default `cart`), `USER_HOST` (default `user`), `PAYMENT_GATEWAY` (default `https://paypal.com/` — placeholder, not a real integration), `PAYMENT_DELAY_MS` (testing only), `AMQP_HOST` (default `rabbitmq`, read from `rabbitmq.py`)
- Entry point: `payment.py`, deps in `requirements.txt`
- **Important:** publishes to a RabbitMQ exchange — the exchange name in `rabbitmq.py` must match what `dispatch` (Go service) is bound to, or orders silently vanish. Check both before changing either.

### `shipping`
- Port: `8080` (hardcoded, not env-configurable currently — flag this if it matters for your setup)
- Env: `CART_ENDPOINT` (was hardcoded to `cart:8080`, now your job to templatize), `DB_HOST` (was hardcoded to `mysql`)
- Build: Maven project (`pom.xml`), Java 8 target
- **Note:** needs a JDK to build, JRE-only to run — two-stage build is appropriate here

### `ratings`
- Port: `80` (Apache)
- Env: `CATALOGUE_URL` (default `http://catalogue:8080`), `PDO_URL` (default `mysql:host=mysql;dbname=ratings;charset=utf8mb4`)
- Build: PHP with Composer dependencies (`composer.json`)

### `dispatch`
- No HTTP port — background worker only
- Connects to RabbitMQ (connection string currently assumes host `rabbitmq`, check `main.go` for exact defaults)
- Build: Go module, no external config files — `go.mod`/`go.sum` generated at build time currently, consider vendoring or committing these for reproducible builds

---

## Data layer notes
- `mongo/catalogue.js`, `mongo/users.js` — seed scripts, MongoDB's official image auto-runs anything placed in `/docker-entrypoint-initdb.d/` **only on first startup with an empty data volume**. Your container build needs to account for this.
- `mysql/scripts/` — schema + seed SQL, same "only runs once" caveat applies
- `mysql` also ships a real MaxMind GeoIP dataset for shipping cost lookups — expect this to make the MySQL image larger than a typical microservice DB image

---

## Things I'd flag if I were reviewing this for production readiness
- No liveness/readiness endpoints implemented on any service — you'll likely want to add basic health checks at the infra level (e.g. TCP checks) until the app team adds real `/health` endpoints
- No structured logging — services log to stdout in plain text, not JSON. Worth raising with dev team before building log parsing/alerting on top of it
- `payment`'s `PAYMENT_GATEWAY` is a placeholder URL, not a real payment integration — don't treat this as PCI-relevant infrastructure
- No secrets management currently — DB connection strings assume no auth (default Mongo/MySQL/Redis setups). You'll need to decide how credentials get injected once you add auth to the data tier

---

## What's explicitly NOT included here (your territory)
Dockerfiles, docker-compose, Kubernetes manifests/Helm charts, Terraform, CI/CD pipelines, monitoring/logging stack, ingress/TLS, secrets management, autoscaling config.
