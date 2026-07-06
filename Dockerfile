# DomainDetective - Coolify self-host (web UI + API + CLI + PowerShell module).
# SDK base: its bundled pwsh is the one that loads the net10 module (proven). Repo is build context.
FROM mcr.microsoft.com/dotnet/sdk:10.0
WORKDIR /src
COPY . .
RUN dotnet publish DomainDetective.OnlineHost/DomainDetective.OnlineHost.csproj  -c Release -o /app/host \
 && dotnet publish DomainDetective.Website/DomainDetective.Website.csproj        -c Release -o /app/webpub \
 && dotnet publish DomainDetective.CLI/DomainDetective.CLI.csproj                -c Release -f net10.0 -o /app/cli \
 && dotnet publish DomainDetective.PowerShell/DomainDetective.PowerShell.csproj  -c Release -f net10.0 -o /app/psmodule
# Frontend is normally produced by Evotec's PowerForge build (not self-hostable). We serve the raw
# Blazor publish, so fix the two things that break it standalone:
#  (1) base href "/tools/" -> "/" so _framework/js assets load at the served root (was 404 -> stuck on loading)
#  (2) substitute the PowerForge __DD_* placeholder tokens (cosmetic SEO/loading text)
RUN idx=/app/webpub/wwwroot/index.html \
 && sed -i 's#<base href="/tools/" />#<base href="/" />#g; s#<base href="/tools/">#<base href="/">#g' "$idx" \
 && sed -i 's/__DD_PAGE_TITLE__/Domain Detective/g; s/__DD_LOADING_TITLE__/Domain Detective/g; s/__DD_LOADING_TEXT__/Loading.../g; s#__DD_META_DESCRIPTION__#Domain and email security auditing#g; s/__DD_OG_TITLE__/Domain Detective/g; s#__DD_OG_DESCRIPTION__#Domain and email security auditing#g; s#__DD_CANONICAL_URL__#https://domaindetective.intech.cloud/#g' "$idx"
ENV ASPNETCORE_URLS=http://0.0.0.0:8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    SiteRoot=/app/webpub/wwwroot
EXPOSE 8080
WORKDIR /app/host
CMD ["dotnet","DomainDetective.OnlineHost.dll"]
