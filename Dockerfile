# DomainDetective self-host: Caddy front (static SPA under /tools/ + SPA fallback) + dotnet API.
FROM mcr.microsoft.com/dotnet/sdk:10.0
WORKDIR /src
COPY . .
RUN dotnet publish DomainDetective.OnlineHost/DomainDetective.OnlineHost.csproj  -c Release -o /app/host \
 && dotnet publish DomainDetective.Website/DomainDetective.Website.csproj        -c Release -o /app/webpub \
 && dotnet publish DomainDetective.CLI/DomainDetective.CLI.csproj                -c Release -f net10.0 -o /app/cli \
 && dotnet publish DomainDetective.PowerShell/DomainDetective.PowerShell.csproj  -c Release -f net10.0 -o /app/psmodule
# Serve the app under /tools/ (its NATIVE base href - do NOT rewrite it). Substitute cosmetic tokens.
RUN mkdir -p /app/site/tools && cp -r /app/webpub/wwwroot/. /app/site/tools/ \
 && sed -i 's/__DD_PAGE_TITLE__/Domain Detective/g; s/__DD_LOADING_TITLE__/Domain Detective/g; s/__DD_LOADING_TEXT__/Loading.../g; s#__DD_META_DESCRIPTION__#Domain and email security auditing#g; s/__DD_OG_TITLE__/Domain Detective/g; s#__DD_OG_DESCRIPTION__#Domain and email security auditing#g; s#__DD_CANONICAL_URL__#https://domaindetective.intech.cloud/tools/#g' /app/site/tools/index.html
# Caddy static binary
RUN curl -sSL "https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_linux_amd64.tar.gz" -o /tmp/caddy.tgz \
 && tar -xzf /tmp/caddy.tgz -C /usr/local/bin caddy && chmod +x /usr/local/bin/caddy && rm /tmp/caddy.tgz
# Caddyfile: API + runtime-json -> dotnet on :5000; /tools/* static with SPA try_files; root -> /tools/
RUN printf '%s\n' \
  ':8080 {' \
  '  handle /tool-api/* { reverse_proxy localhost:5000 }' \
  '  handle /tools/data/* { reverse_proxy localhost:5000 }' \
  '  handle_path /tools/* {' \
  '    root * /app/site/tools' \
  '    try_files {path} /index.html' \
  '    file_server' \
  '  }' \
  '  handle { redir /tools/ 302 }' \
  '}' > /app/Caddyfile
# entrypoint: API on :5000 (bg) + Caddy on :8080 (fg)
RUN printf '%s\n' '#!/bin/bash' 'set -e' 'ASPNETCORE_URLS=http://localhost:5000 dotnet /app/host/DomainDetective.OnlineHost.dll &' 'exec caddy run --config /app/Caddyfile --adapter caddyfile' > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080
CMD ["/app/entrypoint.sh"]
