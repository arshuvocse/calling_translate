namespace VoiceTranslator.Domain.Entities;

public sealed class TranslationLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CallSessionId { get; set; }
    public Guid SenderUserId { get; set; }
    public string SourceLanguage { get; set; } = string.Empty;
    public string TargetLanguage { get; set; } = string.Empty;
    public string SourceText { get; set; } = string.Empty;
    public string TranslatedText { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public CallSession? CallSession { get; set; }
}
