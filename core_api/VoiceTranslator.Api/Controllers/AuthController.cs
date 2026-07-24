using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Application.Dtos;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController(IApplicationDbContext dbContext, IPasswordHasher passwordHasher, ITokenService tokenService) : ControllerBase
{
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            return BadRequest("Valid email and password with at least 6 characters are required.");

        var email = request.Email.Trim().ToLowerInvariant();
        if (await dbContext.Users.AnyAsync(x => x.Email == email, cancellationToken))
            return Conflict("Email already registered.");

        var user = new AppUser
        {
            DisplayName = request.DisplayName.Trim(),
            Email = email,
            PasswordHash = passwordHasher.Hash(request.Password),
            PreferredSourceLanguage = request.SourceLanguage,
            PreferredTargetLanguage = request.TargetLanguage
        };

        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new AuthResponse(user.Id, user.DisplayName, user.Email, tokenService.CreateToken(user)));
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await dbContext.Users.FirstOrDefaultAsync(x => x.Email == email, cancellationToken);
        if (user is null || !passwordHasher.Verify(request.Password, user.PasswordHash))
            return Unauthorized("Invalid email or password.");

        return Ok(new AuthResponse(user.Id, user.DisplayName, user.Email, tokenService.CreateToken(user)));
    }
}
