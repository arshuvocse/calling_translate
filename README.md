# Real-Time AI Voice Translator Call App MVP

Separated layout:

- `core_api/` - ASP.NET Core 8 Web API backend
- `flutter_apps/voice_translator_app/` - Flutter mobile app

## Quick Start with Docker

Run the Web API and SQL Server 2022 locally in containers:

```powershell
docker compose up -d --build
```

The Web API will be accessible at `http://localhost:7068` (Swagger at `http://localhost:7068/swagger`).

## Backend Setup (Manual / Local .NET)

```powershell
cd core_api
dotnet restore .\VoiceTranslator.Api\VoiceTranslator.Api.csproj --configfile .\NuGet.config
dotnet build .\VoiceTranslator.Api\VoiceTranslator.Api.csproj
dotnet run --project .\VoiceTranslator.Api\VoiceTranslator.Api.csproj --launch-profile https
```

Configured SQL Server connection:

```json
"DefaultConnection": "Server=104.234.134.230\\MSSQLSERVER2022;Database=SmartBazarDbmssql;User Id=amarthi1_db;Password=Shuvo**10;TrustServerCertificate=True;"
```

Tables are mapped with the `tbltrans_` prefix:

- `tbltrans_Users`
- `tbltrans_CallSessions`
- `tbltrans_CallParticipants`
- `tbltrans_TranslationLogs`

Stored procedure examples use the `sp_trans_` prefix in:

```text
core_api/database/bootstrap.sql
```

The API also initializes these tables and stored procedures automatically on startup when:

```json
"Database": {
  "InitializeOnStartup": true
}
```

Run EF migrations later if you want a migration-managed schema instead:

```powershell
dotnet tool install --global dotnet-ef
dotnet ef migrations add InitialCreate --project .\VoiceTranslator.Infrastructure --startup-project .\VoiceTranslator.Api
dotnet ef database update --project .\VoiceTranslator.Infrastructure --startup-project .\VoiceTranslator.Api
```

Swagger opens at:

```text
https://localhost:{port}/swagger
```

## Flutter Setup

```powershell
cd flutter_apps\voice_translator_app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://10.0.2.2:7068
```

Use your actual API URL/port. For Android emulator, `10.0.2.2` points to the host machine.

## Example API Requests

Register:

```http
POST /api/auth/register
Content-Type: application/json

{
  "displayName": "Shuvo",
  "email": "shuvo@example.com",
  "password": "secret123",
  "sourceLanguage": "bn",
  "targetLanguage": "en"
}
```

Login:

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "shuvo@example.com",
  "password": "secret123"
}
```

Create call sessions can still be done over REST for administrative/testing flows:

```http
POST /api/calls/sessions
Authorization: Bearer {jwt}
Content-Type: application/json

{
  "startedByUserId": "00000000-0000-0000-0000-000000000001",
  "participantUserId": "00000000-0000-0000-0000-000000000002",
  "sourceLanguage": "bn",
  "targetLanguage": "en"
}
```

## Live Call Architecture

This app is a live two-way audio call system. It is not a recorded audio upload app.

Live call flow:

1. User A starts a call to User B from the Flutter users screen.
2. Flutter connects to the ASP.NET Core SignalR hub:

```text
https://localhost:{port}/hubs/calls
```

3. The hub creates a `CallSession`, sends `IncomingCall` to User B, and relays accept/reject events.
4. Flutter uses `flutter_webrtc` to establish a direct `RTCPeerConnection` between the users.
5. WebRTC carries the live two-way microphone audio so both users hear each other in real time.
6. Flutter also captures small PCM microphone chunks and sends them through SignalR with `SendAudioChunk`.
7. The backend performs speech-to-text, translation, and text-to-speech through `LiveTranslationProcessor`.
8. The hub sends `TranslationReceived` to the opposite user with translated text and TTS audio.
9. Either user can end the call with `EndCall`; the hub marks the session ended and notifies both users.

SignalR hub methods/events:

```text
Client -> Server:
StartCall
AcceptCall
RejectCall
SendOffer
SendAnswer
SendIceCandidate
SendAudioChunk
EndCall

Server -> Client:
IncomingCall
CallAccepted
CallRejected
ReceiveOffer
ReceiveAnswer
ReceiveIceCandidate
TranslationReceived
CallEnded
```

WebRTC signaling payloads are sent through SignalR only. The actual live caller audio is not sent through REST and is not uploaded as a file.

Translation chunk payload:

```json
{
  "callSessionId": "guid",
  "senderUserId": "guid",
  "sourceLanguage": "bn",
  "targetLanguage": "en",
  "audioBase64": "..."
}
```

Translated message:

```json
{
  "callSessionId": "guid",
  "senderUserId": "guid",
  "translatedText": "Hello, how are you?",
  "translatedAudioBase64": "..."
}
```

## Mock AI Replacement Points

Replace these infrastructure classes with real providers:

- `VoiceTranslator.Infrastructure/Ai/MockSpeechToTextService.cs`
- `VoiceTranslator.Infrastructure/Ai/MockTranslationService.cs`
- `VoiceTranslator.Infrastructure/Ai/MockTextToSpeechService.cs`

Interfaces are in `VoiceTranslator.Application/Abstractions/`:

- `ISpeechToTextService`
- `ITranslationService`
- `ITextToSpeechService`

The Flutter call screen requests microphone access for both WebRTC live audio and 16 kHz mono PCM translation chunks. The backend currently processes those chunks through mock AI services, so the app can run end to end without paid API keys.

## Security Notes

- Voice translation consent notice is shown in the app before calls.
- Voice cloning is not implemented in this MVP.
- Change `Jwt:Key` before production.
- Move secrets out of `appsettings.json` for production, for example environment variables or a secret manager.
