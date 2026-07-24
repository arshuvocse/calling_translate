namespace VoiceTranslator.Domain.Entities;

public sealed class SpaceMember
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SpaceId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = "Member"; // Admin, Member
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;

    public Space Space { get; set; } = null!;
}
