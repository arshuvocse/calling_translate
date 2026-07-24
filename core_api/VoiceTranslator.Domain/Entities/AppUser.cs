namespace VoiceTranslator.Domain.Entities;

public sealed class AppUser
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string PreferredSourceLanguage { get; set; } = "bn";
    public string PreferredTargetLanguage { get; set; } = "en";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ICollection<CallParticipant> CallParticipants { get; set; } = [];
    public ICollection<ChatMessage> SentChatMessages { get; set; } = [];
    public ICollection<ChatMessage> ReceivedChatMessages { get; set; } = [];
}
