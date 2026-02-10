# Docker Stack Module

> Framework-specific knowledge for Docker (Dockerfile patterns, docker-compose, volumes, common errors). Add to your project's `debugging.md` or `tech-stack.md`.

## Dockerfile Patterns

### Node.js Multi-Stage Build (Production)

```dockerfile
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Copy package files first (cache layer)
COPY package.json package-lock.json* ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 3: Production
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Don't run as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser

# Copy only what's needed
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

USER appuser

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

### Next.js Optimized Build

```dockerfile
FROM node:20-alpine AS base

# Stage 1: Dependencies
FROM base AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# Stage 2: Build
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# Stage 3: Production
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy the standalone output
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

**Prerequisite:** Add `output: 'standalone'` to `next.config.js`:
```javascript
module.exports = {
  output: 'standalone',
}
```

### Python (FastAPI/Flask)

```dockerfile
FROM python:3.12-slim AS base

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Don't run as root
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Docker Compose for Development

### Full-Stack Example

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules  # Anonymous volume — prevents overwriting container's node_modules
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: myapp
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql  # Run on first start
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

  # Optional: Database admin UI
  pgadmin:
    image: dpage/pgadmin4
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin
    depends_on:
      - db

volumes:
  pgdata:
  redisdata:
```

### Development Dockerfile

```dockerfile
# Dockerfile.dev
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

EXPOSE 3000

# Use dev server with hot reload
CMD ["npm", "run", "dev"]
```

## Volume Mounts

### Types

| Type | Syntax | Use Case |
|------|--------|----------|
| Bind mount | `./src:/app/src` | Live code editing (development) |
| Named volume | `pgdata:/var/lib/postgresql/data` | Persistent data (databases) |
| Anonymous volume | `/app/node_modules` | Prevent host override of container paths |

### The node_modules Problem

**The #1 Docker + Node.js issue.**

When you bind-mount your project directory (`.:/app`), the host's `node_modules` overwrites the container's `node_modules`. If you're on macOS/Windows but the container is Linux, native modules break.

```yaml
# FIX: Anonymous volume for node_modules
services:
  app:
    volumes:
      - .:/app                # Bind mount for live editing
      - /app/node_modules     # Anonymous volume — keeps container's node_modules
```

**Gotcha:** After adding a new dependency, you must rebuild:
```bash
docker compose up --build
# Or just the service:
docker compose build app && docker compose up app
```

### Volume Permissions

**Symptom:** `EACCES: permission denied` when writing to a mounted volume.

**Cause:** The container user (e.g., UID 1001) doesn't match the host user that owns the directory.

**Fixes:**

```dockerfile
# Option 1: Match UIDs (set at build time or runtime)
ARG UID=1000
ARG GID=1000
RUN addgroup --system --gid ${GID} appgroup
RUN adduser --system --uid ${UID} --ingroup appgroup appuser
USER appuser
```

```yaml
# Option 2: Set user in docker-compose
services:
  app:
    user: "${UID:-1000}:${GID:-1000}"
```

```bash
# Option 3: Fix host directory permissions
chmod -R 777 ./data  # Nuclear option (not recommended for production)
```

## Environment Variables

### Methods (in order of precedence)

```yaml
services:
  app:
    # Method 1: Inline
    environment:
      - DATABASE_URL=postgresql://localhost:5432/db
      - NODE_ENV=development

    # Method 2: From file
    env_file:
      - .env
      - .env.local  # Overrides .env values

    # Method 3: From host environment (pass-through)
    environment:
      - API_KEY  # Passes through host's API_KEY value
```

### .dockerignore

Always create a `.dockerignore` to prevent copying unnecessary files:

```
node_modules
.next
.git
.env*.local
*.md
.DS_Store
dist
coverage
.nyc_output
```

**Why it matters:** Without `.dockerignore`, `COPY . .` copies everything, including multi-GB `node_modules` directories and `.git` history. This makes builds slow and images huge.

## Healthchecks

```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s  # Grace period during startup
```

```dockerfile
# In Dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
  CMD curl -f http://localhost:3000/api/health || exit 1
```

**For lightweight images (Alpine) without curl:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1
```

### Health Endpoint Pattern

```typescript
// app/api/health/route.ts (Next.js)
export async function GET() {
  try {
    // Check critical dependencies
    await db.$queryRaw`SELECT 1`
    return Response.json({ status: 'healthy', timestamp: new Date().toISOString() })
  } catch (error) {
    return Response.json({ status: 'unhealthy', error: String(error) }, { status: 503 })
  }
}
```

## Common Errors

### `COPY failed: file not found in build context`

**Cause:** The file doesn't exist or is excluded by `.dockerignore`.

**Fix:** Check the file path relative to the build context (the directory in `docker build -t myapp .`). Check `.dockerignore` isn't excluding it.

### COPY Order for Layer Caching

Docker caches each layer. When a layer changes, all subsequent layers are rebuilt. Order COPY statements from least-frequently-changed to most:

```dockerfile
# GOOD: Dependencies change less often than source code
COPY package.json package-lock.json* ./    # Layer 1: Rarely changes
RUN npm ci                                  # Layer 2: Cached if package.json unchanged
COPY . .                                    # Layer 3: Changes often, but layers 1-2 cached

# BAD: Any file change invalidates the npm install cache
COPY . .                                    # Layer 1: Changes constantly
RUN npm ci                                  # Layer 2: Always re-runs (previous layer changed)
```

### `Error: ENOSPC: no space left on device`

Docker's build cache and dangling images eat disk space:

```bash
# See disk usage
docker system df

# Clean up
docker system prune          # Remove stopped containers, unused networks, dangling images
docker system prune -a       # Also remove unused images (not just dangling)
docker builder prune          # Clear build cache
docker volume prune           # Remove unused volumes (WARNING: removes data)
```

### `exec format error`

**Cause:** Image was built for a different CPU architecture (e.g., built on Apple Silicon M1/M2, running on AMD64 server).

**Fix:**
```bash
# Build for specific platform
docker build --platform linux/amd64 -t myapp .

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .
```

### Container exits immediately

**Cause:** The main process (CMD) exits or crashes.

**Debug:**
```bash
# Check logs
docker logs <container-id>

# Run interactively to debug
docker run -it myapp /bin/sh

# Override CMD to keep container alive
docker run -it myapp /bin/sh -c "tail -f /dev/null"
```

### `Cannot connect to the Docker daemon`

```bash
# Check Docker is running
docker info

# On Linux, ensure user is in docker group
sudo usermod -aG docker $USER
# Then log out and back in

# On macOS/Windows, start Docker Desktop
```

### Port already in use

```bash
# Find what's using the port
lsof -i :3000        # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Use a different host port in docker-compose
ports:
  - "3001:3000"  # Map host:3001 to container:3000
```

### Database connection refused from app container

**Cause:** App is trying to connect to `localhost`, but in Docker, each container has its own network. `localhost` inside the app container is the app container itself, not the database.

**Fix:** Use the service name as hostname:
```yaml
# docker-compose.yml
services:
  app:
    environment:
      # Use the service name "db", not "localhost"
      DATABASE_URL: postgresql://postgres:postgres@db:5432/myapp
  db:
    image: postgres:16
```

## Best Practices

### Image Size

```bash
# Check image size
docker images

# Compare base images:
# node:20          ~1GB  (Debian, includes build tools)
# node:20-slim     ~200MB (Debian minimal)
# node:20-alpine   ~130MB (Alpine Linux, smallest)
```

Use Alpine for production unless you need specific Debian packages. Multi-stage builds keep final images small by excluding build tools.

### Docker Compose Profiles

```yaml
services:
  app:
    # Always starts

  db:
    # Always starts

  pgadmin:
    profiles: ["debug"]  # Only starts with --profile debug

  seed:
    profiles: ["setup"]  # Only starts with --profile setup
    command: npx prisma db seed
```

```bash
docker compose up                          # Starts app + db
docker compose --profile debug up          # Starts app + db + pgadmin
docker compose --profile setup run seed    # Runs seed script
```

### Multi-Service Startup Order

`depends_on` only waits for the container to start, not for the service to be ready. Use healthchecks:

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy      # Waits for healthcheck to pass
      redis:
        condition: service_started      # Just waits for container start
```

### Production Checklist

- [ ] Multi-stage build to minimize image size
- [ ] Non-root user in the final stage
- [ ] `.dockerignore` excludes `node_modules`, `.git`, `.env`
- [ ] COPY order optimized for layer caching (dependencies before source)
- [ ] Healthcheck defined
- [ ] No secrets in the image (use environment variables or secrets management)
- [ ] Platform specified for deployment target (`--platform linux/amd64`)
- [ ] Image tagged with version, not just `latest`
