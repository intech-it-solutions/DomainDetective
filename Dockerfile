# DomainDetective - Coolify build (repo is the build context). Multi-stage -> slim ASP.NET runtime.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish DomainDetective.OnlineHost/DomainDetective.OnlineHost.csproj -c Release -o /app/host \
 && dotnet publish DomainDetective.Website/DomainDetective.Website.csproj -c Release -o /app/webpub \
 && dotnet publish DomainDetective.CLI/DomainDetective.CLI.csproj -c Release -f net10.0 -o /app/cli

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/host   ./host
COPY --from=build /app/webpub ./webpub
COPY --from=build /app/cli    ./cli
ENV ASPNETCORE_URLS=http://0.0.0.0:8080 \
    ASPNETCORE_ENVIRONMENT=Production \
    SiteRoot=/app/webpub/wwwroot
EXPOSE 8080
WORKDIR /app/host
CMD ["dotnet","DomainDetective.OnlineHost.dll"]
