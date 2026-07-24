namespace VoiceTranslator.Application.Dtos;

public sealed record RegisterRequest(string DisplayName, string Email, string Password, string SourceLanguage = "bn", string TargetLanguage = "en");
public sealed record LoginRequest(string Email, string Password);
public sealed record AuthResponse(Guid UserId, string DisplayName, string Email, string Token);
