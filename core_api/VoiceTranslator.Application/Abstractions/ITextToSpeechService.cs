namespace VoiceTranslator.Application.Abstractions;

public interface ITextToSpeechService
{
    Task<byte[]> SynthesizeAsync(string text, string targetLanguage, CancellationToken cancellationToken);
}
