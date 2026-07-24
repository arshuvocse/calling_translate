# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution project files for dependency caching
COPY ["VoiceTranslator.Api/VoiceTranslator.Api.csproj", "VoiceTranslator.Api/"]
COPY ["VoiceTranslator.Application/VoiceTranslator.Application.csproj", "VoiceTranslator.Application/"]
COPY ["VoiceTranslator.Domain/VoiceTranslator.Domain.csproj", "VoiceTranslator.Domain/"]
COPY ["VoiceTranslator.Infrastructure/VoiceTranslator.Infrastructure.csproj", "VoiceTranslator.Infrastructure/"]
COPY ["NuGet.config", "./"]
COPY ["Directory.Build.props", "./"]

RUN dotnet restore "VoiceTranslator.Api/VoiceTranslator.Api.csproj" --configfile "NuGet.config"

# Copy full source and build
COPY . .
WORKDIR "/src/VoiceTranslator.Api"
RUN dotnet build "VoiceTranslator.Api.csproj" -c Release -o /app/build

# Publish Stage
FROM build AS publish
RUN dotnet publish "VoiceTranslator.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "VoiceTranslator.Api.dll"]
