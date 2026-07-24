namespace VoiceTranslator.Domain.Entities;

public sealed class RoomParticipant
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid RoomId { get; set; }
    public Guid UserId { get; set; }
    public bool IsMuted { get; set; } = false;
    public bool IsSpeaking { get; set; } = false;
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;

    public Room Room { get; set; } = null!;
}
