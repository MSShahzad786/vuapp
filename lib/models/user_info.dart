import 'selected_subject.dart';

class UserInfo {
  final String userId;
  final String authProvider;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final DateTime dateCreated;
  final DateTime lastLogin;
  final bool isEmailVerified;

  UserInfo({
    required this.userId,
    required this.authProvider,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    required this.dateCreated,
    required this.lastLogin,
    required this.isEmailVerified,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] as String,
      authProvider: json['authProvider'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      isEmailVerified: json['isEmailVerified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'authProvider': authProvider,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'dateCreated': dateCreated.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isEmailVerified': isEmailVerified,
    };
  }

  UserInfo copyWith({
    String? userId,
    String? authProvider,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    DateTime? dateCreated,
    DateTime? lastLogin,
    bool? isEmailVerified,
    bool? isAnonymous,
    List<SelectedSubject>? selectedSubjects,
    List<String>? activeSubjects,
    List<String>? archivedSubjects,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      authProvider: authProvider ?? this.authProvider,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      dateCreated: dateCreated ?? this.dateCreated,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
