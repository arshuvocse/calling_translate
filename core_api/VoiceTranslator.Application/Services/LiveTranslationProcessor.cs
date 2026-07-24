using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Application.Dtos;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Application.Services;

public sealed class LiveTranslationProcessor(
    IApplicationDbContext dbContext,
    ISpeechToTextService speechToTextService,
    ITranslationService translationService,
    ITextToSpeechService textToSpeechService)
{
    public async Task<LiveAudioResponse> ProcessAsync(LiveAudioRequest request, CancellationToken cancellationToken)
    {
        if (request.CallSessionId == Guid.Empty || request.SenderUserId == Guid.Empty)
            throw new ArgumentException("Call session and sender user are required.");

        if (string.IsNullOrWhiteSpace(request.SourceLanguage) || string.IsNullOrWhiteSpace(request.TargetLanguage))
            throw new ArgumentException("Source and target languages are required.");

        byte[] audioBytes;
        try
        {
            audioBytes = Convert.FromBase64String(request.AudioBase64);
        }
        catch (FormatException ex)
        {
            throw new ArgumentException("audioBase64 is not valid Base64.", ex);
        }

        Directory.CreateDirectory(Path.Combine(Path.GetTempPath(), "voice-translator-chunks"));
        var tempPath = Path.Combine(Path.GetTempPath(), "voice-translator-chunks", $"{request.CallSessionId}-{Guid.NewGuid():N}.bin");
        await File.WriteAllBytesAsync(tempPath, audioBytes, cancellationToken);

        var sourceText = await speechToTextService.TranscribeAsync(audioBytes, request.SourceLanguage, cancellationToken);
        var translatedText = await translationService.TranslateAsync(sourceText, request.SourceLanguage, request.TargetLanguage, cancellationToken);
        var translatedAudio = await textToSpeechService.SynthesizeAsync(translatedText, request.TargetLanguage, cancellationToken);

        dbContext.TranslationLogs.Add(new TranslationLog
        {
            CallSessionId = request.CallSessionId,
            SenderUserId = request.SenderUserId,
            SourceLanguage = request.SourceLanguage,
            TargetLanguage = request.TargetLanguage,
            SourceText = sourceText,
            TranslatedText = translatedText
        });
        await dbContext.SaveChangesAsync(cancellationToken);

        return new LiveAudioResponse(request.CallSessionId, translatedText, Convert.ToBase64String(translatedAudio));
    }
}
