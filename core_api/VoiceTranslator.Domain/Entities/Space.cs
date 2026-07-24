namespace VoiceTranslator.Domain.Entities;

public sealed class Space
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty; // e.g. SP-8K2M9
    public string Category { get; set; } = "Design";
    public Guid CreatedByUserId { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<SpaceMember> Members { get; set; } = new List<SpaceMember>();
}
