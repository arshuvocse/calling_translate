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

        services.AddScoped<OpenAiSpeechToTextService>();
        services.AddScoped<OpenAiTranslationService>();
        services.AddScoped<OpenAiTextToSpeechService>();
        services.AddScoped<MyMemoryTranslationService>();

        var openApiKey = configuration["AiServices:OpenApiKey"];

        if (!string.IsNullOrWhiteSpace(openApiKey))
        {
            services.AddScoped<ISpeechToTextService, OpenAiSpeechToTextService>();
            services.AddScoped<ITranslationService, OpenAiTranslationService>();
            services.AddScoped<ITextToSpeechService, OpenAiTextToSpeechService>();
        }
        else
        {
            services.AddScoped<ISpeechToTextService, OpenAiSpeechToTextService>();
            services.AddScoped<ITranslationService, MyMemoryTranslationService>();
            services.AddScoped<ITextToSpeechService, OpenAiTextToSpeechService>();
        }

        services.AddScoped<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddScoped<ITokenService, JwtTokenService>();
        return services;
    }
}
