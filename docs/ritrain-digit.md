# RItrain-DIGIT TeSS Setup

This guide describes the RItrain-DIGIT-specific setup and operational tasks for this TeSS fork. For general Docker guidance, see the [Docker guide](docker.md).

## Architecture

The application and its supporting services run with Docker Compose. For the general architecture see [README](../README.md#architecture-overview). For RItrain-DIGIT, there are three deployment modes:

* **Development** — mounts the working tree into the application container and exposes Rails app directly at `http://localhost:3000`; no Nginx, custom hostname, or TLS certificate is needed. Code changes are available immediately, and uploaded files are stored in the repository's `public/system` directory (which is ignored by Git).
* **Local-domain development** — also mounts the working tree into the application container, but adds Nginx with HTTPS and a local hostname — it is intended to test EGI authentication which is limited to some domains. This configuration needs a valid certificate for a domain.
* **Production** — the application runs from a Docker image that must be rebuilt when application code changes. Uploaded files are stored separately in the persistent Docker volume named `uploads`. It uses Nginx with HTTPS, a public domain backed up with valid certificate renewed periodically by Certbot. In production, Nginx terminates HTTPS and forwards requests to Puma through a Unix socket shared by Nginx and the application. This Compose configuration publishes HTTP on port `80` for ACME challenges and HTTPS on port `443`. Certbot obtains and renews the production certificate using the HTTP webroot challenge.

## Prerequisites

- Git, Docker Engine, and the Docker Compose plugin.
- **For production:** a DNS name pointing to the host, ports `80` and `443` available, and a contact email address for Let's Encrypt.

The default hostname in this repository is `registry.hopto.org`. Set `TESS_BASE_HOST` in `.env` for the production or local-domain setup, and set `CERTBOT_EMAIL` for production. Standard development uses `localhost:3000` and does not require a hostname or certificate.

## Configuration

### Hostname and TLS

1. Create the environment and application configuration files:

```sh
cp env.sample .env
cp config/tess.example.yml config/tess.yml
cp config/secrets.example.yml config/secrets.yml
cp config/ingestion.example.yml config/ingestion.yml
```

Edit `.env` and replace placeholder credentials with deployment-specific values; it holds only Docker and infrastructure settings. Application settings live in the other two files:

- `tess.yml` controls TeSS features and branding, the EGI LLM endpoint and model (`egi_llm`), and the settings of the custom ingestors (`ingestors`).
- `secrets.yml` holds application secrets and external service credentials, including the EGI Check-in credentials (`egi`) and the EGI LLM API key (`egi_llm_api_key`). The EGI login button is shown only when `egi.client_id` is set.

2. Configure domains (skip if doing development deployment):
   * **For local-domain development**, set `TESS_BASE_HOST` to the hostname in your local hosts file and make a matching certificate available as described below. Ensure port `443` is not used.
   * **For production**, set `TESS_BASE_HOST` in `.env` to the hostname that points to the deployment host and `CERTBOT_EMAIL` to an address for Let's Encrypt account and expiry notices. Ensure DNS points to the host and inbound ports `80` and `443` are available.

3. **For production**, Nginx serves the ACME HTTP challenge from `certbot/www` and redirects other HTTP requests to HTTPS. Certbot stores certificates in `certbot/letsencrypt`. Both directories are kept in Git with `.gitkeep`; their runtime contents are ignored.

## Running the application

### Development

The development Compose configuration mounts the working tree into the application container. Following the further steps from [Docker guide: Configuration](docker.md#configuration), set up dependencies and the database, then start the services:

```sh
docker compose run app bundle install
docker compose run app bundle exec rake db:setup
docker compose run app yarn install
docker compose up -d
```

Open `http://localhost:3000` in a browser. The development stack also includes Adminer, available at `http://localhost:8080` from the Docker host. Development does not start Nginx or require HTTPS.

### Development with a local domain and HTTPS

This separate Compose setup keeps the code live-mounted but serves it through Nginx. Rails SSL enforcement is enabled in this stack, while it is disabled in standard development. Add the configured domain to your local hosts file, for example:

```text
127.0.0.1 registry.hopto.org
```

Set `TESS_BASE_HOST` in `.env` to the same hostname. A certificate matching that hostname must exist at `certbot/letsencrypt/live/<TESS_BASE_HOST>/fullchain.pem` and `certbot/letsencrypt/live/<TESS_BASE_HOST>/privkey.pem`. The repository's ignored certificate storage can be populated from an existing certificate; for a different local hostname, use a locally trusted certificate.

Start the local-domain stack:

```sh
docker compose -f docker-compose-dev-domain.yml run --rm app bundle install
docker compose -f docker-compose-dev-domain.yml run --rm app bundle exec rake db:setup
docker compose -f docker-compose-dev-domain.yml run --rm app yarn install
docker compose -f docker-compose-dev-domain.yml up -d --build
```

Open `https://<TESS_BASE_HOST>`. This stack uses its own Compose project and separate Adminer/Solr host ports (`8081` and `8985`) so it can run alongside standard development.

### Production

Build and start the production services:

```sh
docker compose -f docker-compose-prod.yml up -d --build
```

Certbot requests the certificate automatically after the stack starts. Nginx serves the ACME challenge over HTTP during initial issuance, then enables HTTPS when the certificate is available. The Certbot container renews the certificate periodically, and Nginx reloads its configuration when certificate files change. Keep ports `80` and `443` reachable from the internet and back up `certbot/letsencrypt`.

On the first deployment, initialize the database:

```sh
docker compose -f docker-compose-prod.yml exec app bundle exec rake db:setup DISABLE_DATABASE_ENVIRONMENT_CHECK=1
```

For later releases, rebuild and start the updated services, then apply database migrations:

```sh
docker compose -f docker-compose-prod.yml build app
docker compose -f docker-compose-prod.yml up -d --no-build --force-recreate
docker compose -f docker-compose-prod.yml exec app bundle exec rake db:migrate
```

Uploaded files are kept in the `uploads` volume when application containers are replaced. Back up this volume separately as described below.

Nginx and Puma share the `puma-socket` volume for app traffic; no application TCP port is published in production.

### Import training materials

To fetch the training materials, run:

```sh
docker exec -it ritrain-app bundle exec rake tess:automated_ingestion
```

## Backups and restores

The Git-ignored `backup` directory is intended for database dumps and uploaded-file archives. Keep copies of backups outside the host as well; data stored only on the deployment host is not protected against host failure.

### Back up the database

The `backup_database.sh` script handles both database backups and restores. It detects the environment from a running app container; alternatively, pass `production` or `development` explicitly. If no running app container is found, it defaults to `production`, so specify the environment when operating on a stopped stack. The database backup is created in custom PostgreSQL dump format (`.dump`).

```sh
./scripts/backup_database.sh backup backup/2026-10-20/tess_20261020_081849.dump
```

If the dump path is omitted, the script creates a timestamped file under `backup/`. For development, pass `development` instead of `production`.

### Back up uploaded files

The `backup_uploads.sh` script backs up the application's `public/system` directory. It uses the same environment detection and optional environment argument as the database script, including the `production` default when no app container is running.

```sh
./scripts/backup_uploads.sh backup backup/2026-10-20/uploads.tar.gz
```

If the archive path is omitted, the script creates a timestamped archive under `backup/`.

### Restore

> **Warning:** Restoring a database replaces the entire configured database. Restoring uploaded files deletes the current contents of `public/system` before extracting the archive. Verify the target environment and take a fresh backup before proceeding.

Restore a database dump with `backup_database.sh`:

```sh
./scripts/backup_database.sh restore backup/2026-10-20/tess_20261020_081849.dump production
```

Beside restoring database, the script stops and starts services automatically, does reindexing, etc. The target Compose services must be available, and `.env` must be configured in the repository root.

Restore uploaded files from an archive with:

```sh
./scripts/backup_uploads.sh restore backup/2026-10-20/uploads.tar.gz
```

Use the same environment for both the database and uploads operations to restore a consistent backup set.