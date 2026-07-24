class AppUser {
  AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.preferredSourceLanguage,
    required this.preferredTargetLanguage,
  });

  final String id;
  final String displayName;
  final String email;
  final String preferredSourceLanguage;
  final String preferredTargetLanguage;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    displayName: json['displayName'],
    email: json['email'],
    preferredSourceLanguage: json['preferredSourceLanguage'] ?? 'bn',
    preferredTargetLanguage: json['preferredTargetLanguage'] ?? 'en',
  );
}

class AuthUser {
  AuthUser({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.token,
  });

  final String userId;
  final String displayName;
  final String email;
  final String token;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['userId'],
    displayName: json['displayName'],
    email: json['email'],
    token: json['token'],
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'token': token,
  };
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String message;
  final DateTime createdAt;

  factory ChatMessage.fromMap(Map<Object?, Object?> map) => ChatMessage(
    id: _stringValue(map, 'id') ?? '',
    senderUserId: _stringValue(map, 'senderUserId') ?? '',
    recipientUserId: _stringValue(map, 'recipientUserId') ?? '',
    message: _stringValue(map, 'message') ?? '',
    createdAt:
        DateTime.tryParse(_stringValue(map, 'createdAt') ?? '') ??
        DateTime.now(),
  );

  static String? _stringValue(Map<Object?, Object?> map, String key) {
    final exact = map[key];
    if (exact != null) return exact.toString();

    final pascalKey = key[0].toUpperCase() + key.substring(1);
    final pascal = map[pascalKey];
    if (pascal != null) return pascal.toString();

    final lowerKey = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key?.toString().toLowerCase() == lowerKey) {
        return entry.value?.toString();
      }
    }

    return null;
  }
}
