FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 5130

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["src/Services/Notification/Notification.API/Notification.API.csproj", "src/Services/Notification/Notification.API/"]
COPY ["src/BuildingBlocks/BuildingBlocks.csproj", "src/BuildingBlocks/"]
RUN dotnet restore "src/Services/Notification/Notification.API/Notification.API.csproj"
COPY . .
WORKDIR "/src/src/Services/Notification/Notification.API"
RUN dotnet build "Notification.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Notification.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:5130
ENTRYPOINT ["dotnet", "Notification.API.dll"]
