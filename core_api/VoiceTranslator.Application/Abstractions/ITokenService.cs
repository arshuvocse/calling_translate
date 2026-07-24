using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Application.Abstractions;

public interface ITokenService
{
    string CreateToken(AppUser user);
}
