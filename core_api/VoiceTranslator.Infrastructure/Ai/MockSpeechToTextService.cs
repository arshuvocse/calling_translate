using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class MockSpeechToTextService : ISpeechToTextService
{
    public Task<string> TranscribeAsync(byte[] audioBytes, string sourceLanguage, CancellationToken cancellationToken)
    {
        // Replace this class with Whisper, Google STT, Azure Speech, or another real STT provider.
        return Task.FromResult(sourceLanguage == "bn" ? "Hello, how are you?" : "Ami bhalo achi.");
    }
}
