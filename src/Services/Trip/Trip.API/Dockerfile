FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 5128

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["src/Services/Trip/Trip.API/Trip.API.csproj", "src/Services/Trip/Trip.API/"]
COPY ["src/BuildingBlocks/BuildingBlocks.csproj", "src/BuildingBlocks/"]
RUN dotnet restore "src/Services/Trip/Trip.API/Trip.API.csproj"
COPY . .
WORKDIR "/src/src/Services/Trip/Trip.API"
RUN dotnet build "Trip.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Trip.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:5128
ENTRYPOINT ["dotnet", "Trip.API.dll"]
