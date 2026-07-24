namespace VoiceTranslator.Domain.Entities;

public sealed class Room
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string RoomType { get; set; } = "Voice"; // Voice, Video
    public string Status { get; set; } = "Active"; // Active, Closed
    public Guid CreatedByUserId { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<RoomParticipant> Participants { get; set; } = new List<RoomParticipant>();
}
