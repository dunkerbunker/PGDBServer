# Database Management Cheatsheet

This guide covers common administrative tasks for your DigitalOcean Database Infrastructure.

---

## 1. Whitelisting a New IP Address

Since the database is protected by `iptables`, you must manually whitelist your local IP (or any new server IP) to allow connections to Postgres (5432) and Redis (6379).

### Check your current IP
From your local machine, run:
```bash
curl icanhazip.com
```

### Apply the whitelist rule on the droplet
SSH into your droplet and run (replace `<YOUR_IP>`):
```bash
# Adds your IP to the top of the DOCKER-USER chain
sudo iptables -I DOCKER-USER 1 -s <YOUR_IP> -p tcp -m multiport --dports 5432,6379 -j ACCEPT
```

> [!NOTE]
> These rules are reset if the server reboots or Docker restarts unless you save them. To make them permanent, update the `FE_SERVER_IP` in `.env` and run `sudo ./scripts/setup_firewall.sh`.

---

## 2. Managing Database Users (Postgres)

All commands below assume you are running them inside the `postgres_db` container.

### Create a New User and Database
```bash
docker exec -it postgres_db psql -U postgres -c "CREATE ROLE new_user WITH LOGIN CREATEDB PASSWORD 'strong_password';"
docker exec -it postgres_db psql -U postgres -c "CREATE DATABASE new_database;"
docker exec -it postgres_db psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE new_database TO new_user;"
```

### Update a Password
```bash
docker exec -it postgres_db psql -U postgres -c "ALTER ROLE username WITH PASSWORD 'new_password';"
```

### Fix Prisma "Shadow Database" Permission Errors
Prisma Migrate requires the `CREATEDB` privilege.
```bash
docker exec -it postgres_db psql -U postgres -c "ALTER ROLE username CREATEDB;"
```

### Dedicated Schemas (Best Practice)
To isolate your application tables from the `public` schema:
```bash
# 1. Create the schema in the specific database
docker exec -it postgres_db psql -U postgres -d your_database -c "CREATE SCHEMA mls; ALTER SCHEMA mls OWNER TO your_user;"

# 2. Set the search path so the user uses the schema by default
docker exec -it postgres_db psql -U postgres -c "ALTER ROLE your_user SET search_path TO mls, public;"
```
*(Make sure your `DATABASE_URL` ends with `?schema=mls`)*

---

## 3. Redis Management

### Test Redis Connection
```bash
docker exec -it redis_cache redis-cli -a <REDIS_PASSWORD> ping
```

---

## 4. Troubleshooting

### View Container Logs
```bash
docker compose logs -f db    # Postgres logs
docker compose logs -f redis # Redis logs
```

### Restart Infrastructure
```bash
docker compose restart
# After restarting, re-run the firewall script if you updated .env
sudo ./scripts/setup_firewall.sh
```
