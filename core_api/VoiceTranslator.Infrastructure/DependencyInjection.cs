using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Infrastructure.Ai;
using VoiceTranslator.Infrastructure.Persistence;
using VoiceTranslator.Infrastructure.Security;

namespace VoiceTranslator.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

        services.AddScoped<DatabaseInitializer>();
        services.AddScoped<IApplicationDbContext>(provider => provider.GetRequiredService<ApplicationDbContext>());
        services.AddScoped<ISpeechToTextService, MockSpeechToTextService>();
        services.AddScoped<ITranslationService, MockTranslationService>();
        services.AddScoped<ITextToSpeechService, MockTextToSpeechService>();
        services.AddScoped<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddScoped<ITokenService, JwtTokenService>();
        return services;
    }
}
