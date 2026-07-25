using Microsoft.EntityFrameworkCore;
using VoiceTranslator.Application.Abstractions;
using VoiceTranslator.Domain.Entities;

namespace VoiceTranslator.Infrastructure.Persistence;

public sealed class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
    : DbContext(options), IApplicationDbContext
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<CallSession> CallSessions => Set<CallSession>();
    public DbSet<CallParticipant> CallParticipants => Set<CallParticipant>();
    public DbSet<TranslationLog> TranslationLogs => Set<TranslationLog>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<Space> Spaces => Set<Space>();
    public DbSet<SpaceMember> SpaceMembers => Set<SpaceMember>();
    public DbSet<Room> Rooms => Set<Room>();
    public DbSet<RoomParticipant> RoomParticipants => Set<RoomParticipant>();
    public DbSet<VideoItem> VideoItems => Set<VideoItem>();
    public DbSet<VideoComment> VideoComments => Set<VideoComment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.ToTable("tbltrans_Users");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.Email).IsUnique();
            entity.Property(x => x.DisplayName).HasMaxLength(120).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(180).IsRequired();
            entity.Property(x => x.PasswordHash).HasMaxLength(500).IsRequired();
            entity.Property(x => x.PreferredSourceLanguage).HasMaxLength(12).IsRequired();
            entity.Property(x => x.PreferredTargetLanguage).HasMaxLength(12).IsRequired();
        });

        modelBuilder.Entity<CallSession>(entity =>
        {
            entity.ToTable("tbltrans_CallSessions");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Status).HasMaxLength(32).IsRequired();
        });

        modelBuilder.Entity<CallParticipant>(entity =>
        {
            entity.ToTable("tbltrans_CallParticipants");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.SourceLanguage).HasMaxLength(12).IsRequired();
            entity.Property(x => x.TargetLanguage).HasMaxLength(12).IsRequired();
            entity.HasOne(x => x.CallSession).WithMany(x => x.Participants).HasForeignKey(x => x.CallSessionId);
            entity.HasOne(x => x.User).WithMany(x => x.CallParticipants).HasForeignKey(x => x.UserId);
        });

        modelBuilder.Entity<TranslationLog>(entity =>
        {
            entity.ToTable("tbltrans_TranslationLogs");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.SourceLanguage).HasMaxLength(12).IsRequired();
            entity.Property(x => x.TargetLanguage).HasMaxLength(12).IsRequired();
            entity.Property(x => x.SourceText).HasMaxLength(4000).IsRequired();
            entity.Property(x => x.TranslatedText).HasMaxLength(4000).IsRequired();
            entity.HasOne(x => x.CallSession).WithMany(x => x.TranslationLogs).HasForeignKey(x => x.CallSessionId);
        });

        modelBuilder.Entity<ChatMessage>(entity =>
        {
            entity.ToTable("tbltrans_ChatMessages");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Message).HasMaxLength(4000).IsRequired();
            entity.HasIndex(x => new { x.SenderUserId, x.RecipientUserId, x.CreatedAt });
            entity.HasIndex(x => new { x.RecipientUserId, x.SenderUserId, x.CreatedAt });
            entity.HasOne(x => x.SenderUser)
                .WithMany(x => x.SentChatMessages)
                .HasForeignKey(x => x.SenderUserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.RecipientUser)
                .WithMany(x => x.ReceivedChatMessages)
                .HasForeignKey(x => x.RecipientUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Space>(entity =>
        {
            entity.ToTable("tbltrans_Spaces");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(150).IsRequired();
            entity.Property(x => x.Code).HasMaxLength(32).IsRequired();
            entity.HasIndex(x => x.Code).IsUnique();
        });

        modelBuilder.Entity<SpaceMember>(entity =>
        {
            entity.ToTable("tbltrans_SpaceMembers");
            entity.HasKey(x => x.Id);
            entity.HasOne(x => x.Space).WithMany(x => x.Members).HasForeignKey(x => x.SpaceId);
        });

        modelBuilder.Entity<Room>(entity =>
        {
            entity.ToTable("tbltrans_Rooms");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(150).IsRequired();
            entity.Property(x => x.RoomType).HasMaxLength(32).IsRequired();
        });

        modelBuilder.Entity<RoomParticipant>(entity =>
        {
            entity.ToTable("tbltrans_RoomParticipants");
            entity.HasKey(x => x.Id);
            entity.HasOne(x => x.Room).WithMany(x => x.Participants).HasForeignKey(x => x.RoomId);
        });

        modelBuilder.Entity<VideoItem>(entity =>
        {
            entity.ToTable("tbltrans_VideoItems");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Title).HasMaxLength(250).IsRequired();
            entity.Property(x => x.VideoType).HasMaxLength(32).IsRequired();
            entity.Property(x => x.Category).HasMaxLength(64).IsRequired();
            entity.HasOne(x => x.Author).WithMany().HasForeignKey(x => x.AuthorId);
        });

        modelBuilder.Entity<VideoComment>(entity =>
        {
            entity.ToTable("tbltrans_VideoComments");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.CommentText).HasMaxLength(1000).IsRequired();
            entity.HasOne(x => x.Video).WithMany(x => x.Comments).HasForeignKey(x => x.VideoId);
            entity.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        });
    }
}
