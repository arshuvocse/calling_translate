using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class OpenAiTranslationService(
    HttpClient httpClient,
    IConfiguration configuration,
    ILogger<OpenAiTranslationService> logger) : ITranslationService
{
    public async Task<string> TranslateAsync(string text, string sourceLanguage, string targetLanguage, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";

        var apiKey = configuration["AiServices:OpenApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            logger.LogWarning("OpenAI API Key not configured. Using fallback translation engine.");
            return $"[{targetLanguage.ToUpper()}]: {text}";
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var payload = new
            {
                model = "gpt-4o-mini",
                messages = new object[]
                {
                    new
                    {
                        role = "system",
                        content = $"You are a real-time live voice translator. Translate the text accurately from source dialect '{sourceLanguage}' to target region dialect '{targetLanguage}'. Return ONLY the direct translation string without quotes or explanations."
                    },
                    new
                    {
                        role = "user",
                        content = text
                    }
                },
                temperature = 0.3
            };

            request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
            var response = await httpClient.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(json);
            var choices = doc.RootElement.GetProperty("choices");
            if (choices.GetArrayLength() > 0)
            {
                var translated = choices[0].GetProperty("message").GetProperty("content").GetString();
                return translated?.Trim() ?? text;
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "OpenAI Translation failed.");
        }

        return text;
    }
}
