# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

# Copy csproj and restore dependencies
COPY ["src/Services/Identity/Identity.API/Identity.API.csproj", "src/Services/Identity/Identity.API/"]
COPY ["src/BuildingBlocks/BuildingBlocks.csproj", "src/BuildingBlocks/"]
RUN dotnet restore "src/Services/Identity/Identity.API/Identity.API.csproj"

# Copy everything else and build
COPY . .
WORKDIR /src/src/Services/Identity/Identity.API
RUN dotnet build "Identity.API.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "Identity.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

WORKDIR /app

# Copy published files
COPY --from=publish /app/publish .

# Expose port used by Identity API (avoid colliding with Catalog)
EXPOSE 5127

# Set environment variables
ENV ASPNETCORE_URLS=http://+:5127

# Start the application
ENTRYPOINT ["dotnet", "Identity.API.dll"]
