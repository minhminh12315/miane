FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["src/ApiGateways/Web.Gateway/Web.Gateway.csproj", "src/ApiGateways/Web.Gateway/"]
COPY ["src/BuildingBlocks/BuildingBlocks.csproj", "src/BuildingBlocks/"]
RUN dotnet restore "src/ApiGateways/Web.Gateway/Web.Gateway.csproj"
COPY . .
WORKDIR "/src/src/ApiGateways/Web.Gateway"
RUN dotnet build "Web.Gateway.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Web.Gateway.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Web.Gateway.dll"]
