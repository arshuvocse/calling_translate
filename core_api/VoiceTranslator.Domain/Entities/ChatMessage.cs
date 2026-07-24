namespace VoiceTranslator.Domain.Entities;

public sealed class ChatMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SenderUserId { get; set; }
    public Guid RecipientUserId { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public AppUser? SenderUser { get; set; }
    public AppUser? RecipientUser { get; set; }
}
