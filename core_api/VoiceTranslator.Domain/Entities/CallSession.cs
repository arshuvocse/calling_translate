namespace VoiceTranslator.Domain.Entities;

public sealed class CallSession
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid StartedByUserId { get; set; }
    public string Status { get; set; } = "connecting";
    public DateTimeOffset StartedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? EndedAt { get; set; }
    public ICollection<CallParticipant> Participants { get; set; } = [];
    public ICollection<TranslationLog> TranslationLogs { get; set; } = [];
}
