using System.Text;
using VoiceTranslator.Application.Abstractions;

namespace VoiceTranslator.Infrastructure.Ai;

public sealed class MockTextToSpeechService : ITextToSpeechService
{
    public Task<byte[]> SynthesizeAsync(string text, string targetLanguage, CancellationToken cancellationToken)
    {
        // Replace this class with OpenAI TTS, ElevenLabs, Coqui, Azure Speech, or another TTS provider.
        return Task.FromResult(GenerateToneWavBytes());
    }

    private static byte[] GenerateToneWavBytes()
    {
        const int sampleRate = 16000;
        const short bitsPerSample = 16;
        const short channels = 1;
        const int seconds = 1;
        var sampleCount = sampleRate * seconds;
        var data = new byte[sampleCount * 2];

        for (var i = 0; i < sampleCount; i++)
        {
            var sample = (short)(Math.Sin(2 * Math.PI * 440 * i / sampleRate) * short.MaxValue * 0.2);
            BitConverter.GetBytes(sample).CopyTo(data, i * 2);
        }

        using var stream = new MemoryStream();
        using var writer = new BinaryWriter(stream, Encoding.ASCII);
        writer.Write("RIFF"u8.ToArray());
        writer.Write(36 + data.Length);
        writer.Write("WAVEfmt "u8.ToArray());
        writer.Write(16);
        writer.Write((short)1);
        writer.Write(channels);
        writer.Write(sampleRate);
        writer.Write(sampleRate * channels * bitsPerSample / 8);
        writer.Write((short)(channels * bitsPerSample / 8));
        writer.Write(bitsPerSample);
        writer.Write("data"u8.ToArray());
        writer.Write(data.Length);
        writer.Write(data);
        return stream.ToArray();
    }
}
