using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class MyMemoryTranslationService(
    HttpClient httpClient,
    IConfiguration configuration,
    ILogger<MyMemoryTranslationService> logger,
    OpenAiTranslationService openAiTranslationService) : ITranslationService
{
    public async Task<string> TranslateAsync(string text, string sourceLanguage, string targetLanguage, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";

        var openApiKey = configuration["AiServices:OpenApiKey"];
        if (!string.IsNullOrWhiteSpace(openApiKey))
        {
            return await openAiTranslationService.TranslateAsync(text, sourceLanguage, targetLanguage, cancellationToken);
        }

        try
        {
            var src = sourceLanguage.Split('-')[0];
            var tgt = targetLanguage.Split('-')[0];
            var url = $"https://api.mymemory.translated.net/get?q={Uri.EscapeDataString(text)}&langpair={src}|{tgt}";

            var response = await httpClient.GetAsync(url, cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync(cancellationToken);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("responseData", out var respData) &&
                    respData.TryGetProperty("translatedText", out var transProp))
                {
                    var result = transProp.GetString();
                    if (!string.IsNullOrWhiteSpace(result))
                    {
                        return result;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "MyMemory Free Translation API failed. Falling back to default.");
        }

        return $"[{targetLanguage.Split('-')[0].ToUpper()}]: {text}";
    }
}
