namespace VoiceTranslator.Domain.Entities;

public sealed class VideoItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid AuthorId { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public required string VideoType { get; set; } // "Quick", "Story", "Full"
    public required string Category { get; set; } // "For You", "Following", "Trending", "Education", "Music"
    public required string VideoUrl { get; set; }
    public required string ThumbnailUrl { get; set; }
    public required string Duration { get; set; }
    public long ViewsCount { get; set; }
    public long LikesCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AppUser? Author { get; set; }
    public ICollection<VideoComment> Comments { get; set; } = new List<VideoComment>();
}
