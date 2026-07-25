namespace VoiceTranslator.Domain.Entities;

public sealed class VideoComment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid VideoId { get; set; }
    public Guid UserId { get; set; }
    public required string CommentText { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public VideoItem? Video { get; set; }
    public AppUser? User { get; set; }
}
