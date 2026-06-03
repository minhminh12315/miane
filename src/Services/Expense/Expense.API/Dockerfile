FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 5129

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["src/Services/Expense/Expense.API/Expense.API.csproj", "src/Services/Expense/Expense.API/"]
COPY ["src/BuildingBlocks/BuildingBlocks.csproj", "src/BuildingBlocks/"]
RUN dotnet restore "src/Services/Expense/Expense.API/Expense.API.csproj"
COPY . .
WORKDIR "/src/src/Services/Expense/Expense.API"
RUN dotnet build "Expense.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Expense.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:5129
ENTRYPOINT ["dotnet", "Expense.API.dll"]
