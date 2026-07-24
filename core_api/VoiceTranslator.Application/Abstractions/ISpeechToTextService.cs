namespace VoiceTranslator.Application.Abstractions;

public interface ISpeechToTextService
{
    Task<string> TranscribeAsync(byte[] audioBytes, string sourceLanguage, CancellationToken cancellationToken);
}
