namespace VoiceTranslator.Application.Dtos;

public sealed record CreateCallSessionRequest(Guid StartedByUserId, Guid ParticipantUserId, string SourceLanguage, string TargetLanguage);
public sealed record CallSessionResponse(Guid CallSessionId, string Status);
public sealed record EndCallRequest(Guid CallSessionId);
public sealed record LiveAudioRequest(Guid CallSessionId, Guid SenderUserId, string SourceLanguage, string TargetLanguage, string AudioBase64);
public sealed record LiveAudioResponse(Guid CallSessionId, string TranslatedText, string TranslatedAudioBase64);
