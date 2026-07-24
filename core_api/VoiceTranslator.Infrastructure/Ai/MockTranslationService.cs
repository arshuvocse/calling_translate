using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class MockTranslationService : ITranslationService
{
    public Task<string> TranslateAsync(string text, string sourceLanguage, string targetLanguage, CancellationToken cancellationToken)
    {
        // Replace this class with Google Translate, OpenAI, Azure Translator, or another translation provider.
        var translated = targetLanguage switch
        {
            "bn" => "হ্যালো, আপনি কেমন আছেন?",
            "en" => "Hello, how are you?",
            "hi" => "नमस्ते, आप कैसे हैं?",
            "ar" => "مرحبا، كيف حالك؟",
            _ => $"[{targetLanguage}] {text}"
        };
        return Task.FromResult(translated);
    }
}
