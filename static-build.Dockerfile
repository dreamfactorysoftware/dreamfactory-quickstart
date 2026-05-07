###############################################################################
# DreamFactory Quickstart — Static Binary Build
#
# Produces a single self-contained binary: ./dreamfactory-linux-x86_64
# Contains: FrankenPHP + PHP 8.4 + Caddy + DreamFactory (app + admin UI)
#
# Build:   docker build -t dreamfactory-quickstart-static -f static-build.Dockerfile .
# Extract: docker cp $(docker create --name tmp dreamfactory-quickstart-static):/go/src/app/dist/frankenphp-linux-x86_64 dreamfactory && docker rm tmp
###############################################################################

# =============================================================================
# Stage 1: Prepare the DreamFactory application
# =============================================================================
FROM php:8.4-cli AS app-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip sqlite3 libsqlite3-dev libzip-dev libxml2-dev libcurl4-openssl-dev libpq-dev nodejs npm \
    && docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite zip soap bcmath \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ARG BRANCH=master
ARG INCLUDE_MCP=false
RUN git clone --depth 1 --branch $BRANCH \
    https://github.com/dreamfactorysoftware/dreamfactory.git /build/app && \
    rm -rf /build/app/.git

WORKDIR /build/app

# Overlay composer.json for the quickstart binary profile.
COPY composer.binary.json composer.json
COPY .build/df-mcp-server /build/df-mcp-server
COPY .build/local-packages /build/local-packages

RUN if [ "$INCLUDE_MCP" = "true" ]; then \
      test -f /build/df-mcp-server/composer.json; \
      php -r '$file="composer.json"; $json=json_decode(file_get_contents($file), true); $json["repositories"][]=["type"=>"path","url"=>"/build/df-mcp-server","options"=>["symlink"=>false]]; $json["require"]["dreamfactory/df-mcp-server"]="*"; file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL);'; \
    fi

RUN php -r '$file="composer.json"; $json=json_decode(file_get_contents($file), true); $versions=["dreamfactory/df-system"=>"0.6.4", "dreamfactory/df-admin-interface"=>"1.7.4"]; foreach (["df-system", "df-admin-interface"] as $package) { $path="/build/local-packages/".$package; if (is_file($path."/composer.json")) { $packageJson=json_decode(file_get_contents($path."/composer.json"), true); $name=$packageJson["name"]; array_unshift($json["repositories"], ["type"=>"path", "url"=>$path, "options"=>["symlink"=>false, "versions"=>[$name=>$versions[$name] ?? "999.999.999"]]]); $json["require"][$name]="*"; } } file_put_contents($file, json_encode($json, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES).PHP_EOL);'

# Pre-composer cleanup
RUN rm -f composer.lock bootstrap/cache/packages.php bootstrap/cache/services.php && \
    sed -i '/MongoDB.*MongoDBServiceProvider/d' config/app.php && \
    sed -i '/Add MongoDB Provider/d' config/app.php && \
    git config --global url."https://github.com/".insteadOf "git@github.com:"

RUN --mount=type=secret,id=github_token \
    if [ -s /run/secrets/github_token ]; then \
        composer config --global --auth github-oauth.github.com "$(cat /run/secrets/github_token)"; \
    fi

RUN COMPOSER_MEMORY_LIMIT=-1 composer update --no-dev --ignore-platform-reqs --no-scripts

# Patch MongoDB references out of df-core
RUN sed -i '/use MongoDB/d' vendor/dreamfactory/df-core/src/LaravelServiceProvider.php && \
    sed -i '/MongoDBServiceProvider/d' vendor/dreamfactory/df-core/src/LaravelServiceProvider.php

# Post-install steps
RUN composer dump-autoload --optimize && \
    php artisan package:discover --ansi

RUN mkdir -p /build/mcp-daemon && \
    if [ "$INCLUDE_MCP" = "true" ]; then \
      cd /build/df-mcp-server/daemon; \
      npm ci; \
      npm run build; \
      npm prune --omit=dev; \
      cp package.json package-lock.json /build/mcp-daemon/; \
      cp -a dist node_modules /build/mcp-daemon/; \
    fi

# Production .env
RUN cp .env-dist .env && \
    sed -i 's/^APP_ENV=.*/APP_ENV=production/' .env && \
    sed -i 's/^APP_DEBUG=.*/APP_DEBUG=false/' .env && \
    sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/' .env && \
    sed -i 's/^CACHE_DRIVER=.*/CACHE_DRIVER=file/' .env && \
    sed -i 's/^DF_INSTALL=.*/DF_INSTALL="binary quickstart"/' .env

# Create storage skeleton (will be copied to persistent path at runtime)
RUN mkdir -p storage/app storage/databases \
             storage/framework/cache/data storage/framework/sessions \
             storage/framework/views storage/logs bootstrap/cache

# Strip bloat
RUN rm -rf tests/ .git/ .github/ .docker/ docker-compose* Dockerfile* \
    && find vendor -type d \( -name "tests" -o -name "test" -o -name "Tests" -o -name "docs" -o -name ".git" \) -exec rm -rf {} + 2>/dev/null || true

# Don't embed Caddyfile — FrankenPHP cd's into the embed dir at startup and
# would auto-load it, overriding the --listen flag from php-server. The wrapper
# script uses php-server mode which serves public/ + PHP routing without Caddyfile.

# Embed the wrapper script
COPY bin/dreamfactory-ctl /build/app/bin/dreamfactory-ctl
RUN chmod +x /build/app/bin/dreamfactory-ctl

# =============================================================================
# Stage 2: Prepare the SQL Server ODBC runtime bundle
# =============================================================================
FROM debian:bookworm-slim AS odbc-runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg unixodbc \
    && mkdir -p /usr/share/keyrings \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" \
      > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && mkdir -p /odbc-runtime/microsoft /odbc-runtime/lib \
    && cp -a /opt/microsoft/msodbcsql18 /odbc-runtime/microsoft/ \
    && ldd /opt/microsoft/msodbcsql18/lib64/libmsodbcsql-*.so* \
      | awk '/=> \// {print $(NF-1)} /^\// {print $1}' \
      | sort -u \
      | while read -r lib; do \
          case "$lib" in \
            /lib*/ld-linux*|/lib*/libc.so*|/lib*/libpthread.so*|/lib*/libdl.so*|/lib*/libm.so*|/lib*/libresolv.so*|/lib*/librt.so*|/lib*/libutil.so*) ;; \
            *) cp -L "$lib" /odbc-runtime/lib/ ;; \
          esac; \
        done \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 3: Prepare the bundled Node runtime used by the MCP daemon
# =============================================================================
FROM node:20-bookworm-slim AS node-runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -p /node-runtime/bin /node-runtime/lib \
    && cp -L /usr/local/bin/node /node-runtime/bin/node \
    && ldd /usr/local/bin/node \
      | awk '/=> \// {print $(NF-1)} /^\// {print $1}' \
      | sort -u \
      | while read -r lib; do \
          case "$lib" in \
            /lib*/ld-linux*|/lib*/libc.so*|/lib*/libpthread.so*|/lib*/libdl.so*|/lib*/libm.so*|/lib*/libresolv.so*|/lib*/librt.so*|/lib*/libutil.so*) ;; \
            *) cp -L "$lib" /node-runtime/lib/ ;; \
          esac; \
        done

# =============================================================================
# Stage 4: Compile the static FrankenPHP binary with embedded app
# =============================================================================
FROM --platform=linux/amd64 dunglas/frankenphp:static-builder-gnu

# Pin PHP 8.4 — 8.5 emits PDO MySQL deprecation warnings that DF hasn't caught up to
ENV PHP_VERSION=8.4

# UPX can make the embedded binary smaller, but --best is a long and fragile
# step for internal iteration. Leave it off by default; release builds can opt in.
ARG ENABLE_UPX=false

# Copy prepared app into the embed directory
COPY --from=app-builder /build/app /go/src/app/dist/app

WORKDIR /go/src/app

# Note: 'zip' extension omitted — libzip pulls bzip2/lzma/zstd that the
# static-builder doesn't bundle, causing linker failures. Composer ran in
# stage 1 with host's zip, so vendor/ is intact.
# PHP_EXTENSION_LIBS adds static libs that curl needs (libssh2 + zstd).
# build-static.sh runs an embed sanity check after producing the binary; that
# check link-tests with libldap which isn't bundled, so it fails — but the
# actual frankenphp binary (with embedded app.tar) is already at
# dist/static-php-cli/buildroot/bin/frankenphp. Only tolerate that failure if
# the expected binary was produced.
RUN --mount=type=secret,id=github_token \
    export PHP_EXTENSIONS="bcmath,ctype,curl,dom,fileinfo,filter,mbstring,mbregex,opcache,openssl,pdo_mysql,pdo_pgsql,pdo_sqlite,pdo_sqlsrv,phar,session,simplexml,soap,sqlsrv,tokenizer,xml,xmlreader,xmlwriter" \
    PHP_EXTENSION_LIBS="libavif,nghttp2,nghttp3,ngtcp2,watcher,libssh2,zstd,onig" \
    EMBED=dist/app/; \
    rm -f /go/src/app/dist/static-php-cli/buildroot/bin/frankenphp; \
    if [ -s /run/secrets/github_token ]; then \
        export GITHUB_TOKEN="$(cat /run/secrets/github_token)"; \
    fi; \
    if [ "$ENABLE_UPX" = "true" ]; then \
        ./build-static.sh; \
    else \
        NO_COMPRESS=1 ./build-static.sh; \
    fi || test -f /go/src/app/dist/static-php-cli/buildroot/bin/frankenphp
RUN test -f /go/src/app/dist/static-php-cli/buildroot/bin/frankenphp \
    && cp /go/src/app/dist/static-php-cli/buildroot/bin/frankenphp /go/src/app/dist/frankenphp-linux-x86_64 \
    && /go/src/app/dist/frankenphp-linux-x86_64 version
COPY --from=odbc-runtime /odbc-runtime /go/src/app/dist/odbc-runtime
COPY --from=node-runtime /node-runtime /go/src/app/dist/node-runtime
COPY --from=app-builder /build/mcp-daemon /go/src/app/dist/mcp-daemon
