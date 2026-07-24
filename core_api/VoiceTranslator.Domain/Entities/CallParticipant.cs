namespace VoiceTranslator.Domain.Entities;

public sealed class CallParticipant
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CallSessionId { get; set; }
    public Guid UserId { get; set; }
    public string SourceLanguage { get; set; } = "bn";
    public string TargetLanguage { get; set; } = "en";
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? LeftAt { get; set; }
    public CallSession? CallSession { get; set; }
    public AppUser? User { get; set; }
}
