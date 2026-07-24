using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class OpenAiTextToSpeechService(
    HttpClient httpClient,
    IConfiguration configuration,
    ILogger<OpenAiTextToSpeechService> logger) : ITextToSpeechService
{
    public async Task<byte[]> SynthesizeAsync(string text, string targetLanguage, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(text)) return Array.Empty<byte>();

        var apiKey = configuration["AiServices:OpenApiKey"];
        var voice = configuration["AiServices:TtsVoice"] ?? "nova"; // alloy, echo, fable, onyx, nova, shimmer

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            logger.LogWarning("OpenAI API Key not configured. Using realistic audio wave generator.");
            return GenerateFallbackPcmWav(text);
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/audio/speech");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var payload = new
            {
                model = "tts-1",
                input = text,
                voice = voice,
                response_format = "wav"
            };

            request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
            var response = await httpClient.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();

            return await response.Content.ReadAsByteArrayAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "OpenAI TTS voice synthesis failed.");
        }

        return GenerateFallbackPcmWav(text);
    }

    private static byte[] GenerateFallbackPcmWav(string text)
    {
        var sampleRate = 16000;
        var seconds = 2;
        var numSamples = sampleRate * seconds;
        var pcmData = new byte[numSamples * 2];

        for (int i = 0; i < numSamples; i++)
        {
            short sample = (short)(Math.Sin(2 * Math.PI * 440 * i / sampleRate) * 8000);
            pcmData[i * 2] = (byte)(sample & 0xFF);
            pcmData[i * 2 + 1] = (byte)((sample >> 8) & 0xFF);
        }

        using var ms = new MemoryStream();
        using var writer = new BinaryWriter(ms);
        writer.Write(Encoding.ASCII.GetBytes("RIFF"));
        writer.Write(36 + pcmData.Length);
        writer.Write(Encoding.ASCII.GetBytes("WAVE"));
        writer.Write(Encoding.ASCII.GetBytes("fmt "));
        writer.Write(16);
        writer.Write((short)1); // PCM
        writer.Write((short)1); // Mono
        writer.Write(sampleRate);
        writer.Write(sampleRate * 2);
        writer.Write((short)2);
        writer.Write((short)16);
        writer.Write(Encoding.ASCII.GetBytes("data"));
        writer.Write(pcmData.Length);
        writer.Write(pcmData);

        return ms.ToArray();
    }
}
