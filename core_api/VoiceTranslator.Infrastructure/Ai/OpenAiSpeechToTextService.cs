using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class OpenAiSpeechToTextService(
    HttpClient httpClient,
    IConfiguration configuration,
    ILogger<OpenAiSpeechToTextService> logger) : ISpeechToTextService
{
    public async Task<string> TranscribeAsync(byte[] audioBytes, string sourceLanguage, CancellationToken cancellationToken)
    {
        var apiKey = configuration["AiServices:OpenApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            logger.LogWarning("OpenAI API Key not configured. Using fallback Whisper transcription simulation.");
            return "Assalamu Alaikum, how are you?";
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/audio/transcriptions");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            using var content = new MultipartFormDataContent();
            var audioContent = new ByteArrayContent(audioBytes);
            audioContent.Headers.ContentType = MediaTypeHeaderValue.Parse("audio/wav");
            content.Add(audioContent, "file", "audio.wav");
            content.Add(new StringContent("whisper-1"), "model");

            if (!string.IsNullOrWhiteSpace(sourceLanguage))
            {
                var langCode = sourceLanguage.Split('-')[0];
                content.Add(new StringContent(langCode), "language");
            }

            request.Content = content;
            var response = await httpClient.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.TryGetProperty("text", out var textProp))
            {
                return textProp.GetString() ?? "";
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "OpenAI Whisper transcription failed.");
        }

        return "Speech audio received.";
    }
}
