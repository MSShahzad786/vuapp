import 'package:cloud_firestore/cloud_firestore.dart';

class SelectedSubject {
  final String subCode;
  final String subName;
  final String subIcon;
  final String org;
  final int credits;
  final int mcqsCount;
  final int attemptedMcqsCount;
  final int correctMcqsCount;
  final String subjRef;
  final List<String> attemptedMcqIds;
  final DateTime enrollmentDate;
  final DateTime lastActivity;
  final DateTime lastModified;

  SelectedSubject({
    required this.subCode,
    required this.subName,
    required this.subIcon,
    required this.org,
    required this.credits,
    required this.mcqsCount,
    this.attemptedMcqsCount = 0,
    this.correctMcqsCount = 0,
    required this.subjRef,
    this.attemptedMcqIds = const [],
    DateTime? enrollmentDate,
    DateTime? lastActivity,
    DateTime? lastModified,
  }) :
    enrollmentDate = enrollmentDate ?? DateTime.now(),
    lastActivity = lastActivity ?? DateTime.now(),
    lastModified = lastModified ?? DateTime.now();

  static DateTime _parseTimestamp(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    } else if (timestampData is Map<String, dynamic>) {
      // Handle Firestore Timestamp serialized as Map
      final seconds = timestampData['_seconds'] as int?;
      if (seconds != null) {
        final nanoseconds = timestampData['_nanoseconds'] as int?;
        var dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
        if (nanoseconds != null) {
          dateTime = dateTime.add(Duration(microseconds: nanoseconds ~/ 1000));
        }
        return dateTime;
      }
    }
    return DateTime.now(); // Fallback
  }

  factory SelectedSubject.fromJson(Map<String, dynamic> json) {
    return SelectedSubject(
      subCode: json['subCode'] as String,
      subName: json['subName'] as String,
      subIcon: json['subIcon'] as String,
      org: json['org'] as String,
      credits: json['credits'] as int,
      mcqsCount: json['mcqsCount'] as int,
      attemptedMcqsCount: json['attemptedMcqsCount'] as int? ?? 0,
      correctMcqsCount: json['correctMcqsCount'] as int? ?? 0,
      subjRef: json['subjRef'] as String,
      attemptedMcqIds: (json['attemptedMcqIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      enrollmentDate: _parseTimestamp(json['enrollmentDate']),
      lastActivity: _parseTimestamp(json['lastActivity']),
      lastModified: _parseTimestamp(json['lastModified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subCode': subCode,
      'subName': subName,
      'subIcon': subIcon,
      'org': org,
      'credits': credits,
      'subjRef': subjRef,
      'attemptedMcqIds': attemptedMcqIds,
      'enrollmentDate': Timestamp.fromDate(enrollmentDate),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'lastModified': Timestamp.fromDate(lastModified),
    };
  }

  SelectedSubject copyWith({
    String? subCode,
    String? subName,
    String? subIcon,
    String? org,
    int? credits,
    int? mcqsCount,
    int? attemptedMcqsCount,
    int? correctMcqsCount,
    String? subjRef,
    List<String>? attemptedMcqIds,
    DateTime? enrollmentDate,
    DateTime? lastActivity,
    DateTime? lastModified,
  }) {
    return SelectedSubject(
      subCode: subCode ?? this.subCode,
      subName: subName ?? this.subName,
      subIcon: subIcon ?? this.subIcon,
      org: org ?? this.org,
      credits: credits ?? this.credits,
      mcqsCount: mcqsCount ?? this.mcqsCount,
      attemptedMcqsCount: attemptedMcqsCount ?? this.attemptedMcqsCount,
      correctMcqsCount: correctMcqsCount ?? this.correctMcqsCount,
      subjRef: subjRef ?? this.subjRef,
      attemptedMcqIds: attemptedMcqIds ?? this.attemptedMcqIds,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      lastActivity: lastActivity ?? this.lastActivity,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

class Subject {
  final String id;
  final String subCode;
  final String subName;
  final String subIcon;
  final String org;
  final bool underProcess;
  final int credits;

  Subject({
    required this.id,
    required this.subCode,
    required this.subName,
    required this.subIcon,
    required this.org,
    required this.underProcess,
    required this.credits,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? '',
      subCode: json['subCode'] ?? '',
      subName: json['subName'] ?? '',
      subIcon: json['subIcon'] ?? '',
      org: json['org'] ?? '',
      underProcess: json['under_process'] ?? false,
      credits: json['credits'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subCode': subCode,
      'subName': subName,
      'subIcon': subIcon,
      'org': org,
      'under_process': underProcess,
      'credits': credits,
    };
  }

  factory Subject.fromFirestore(Map<String, dynamic> data, String id) {
    return Subject(
      id: id,
      subCode: data['subCode'] ?? '',
      subName: data['subName'] ?? '',
      subIcon: data['subIcon'] ?? '',
      org: data['org'] ?? '',
      underProcess: data['under_proccess'] ?? false,
      credits: data['credits'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subCode': subCode,
      'subName': subName,
      'subIcon': subIcon,
      'org': org,
      'under_process': underProcess,
      'credits': credits,
    };
  }
}

class MCQ {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String chapterId;
  final int upvotes;
  final int downvotes;
  final int hearts;
  final List<String> upvotedBy;
  final List<String> downvotedBy;
  final List<String> heartedBy;
  final List<String> topicList;
  final List<String> subtopicList;
  final DateTime createdAt;
  final DateTime updatedAt;

  MCQ({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.chapterId,
    this.upvotes = 0,
    this.downvotes = 0,
    this.hearts = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
    this.heartedBy = const [],
    this.topicList = const [],
    this.subtopicList = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseTimestamp(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    } else if (timestampData is Map<String, dynamic>) {
      // Handle Firestore Timestamp serialized as Map
      final seconds = timestampData['_seconds'] as int?;
      if (seconds != null) {
        final nanoseconds = timestampData['_nanoseconds'] as int?;
        var dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
        if (nanoseconds != null) {
          dateTime = dateTime.add(Duration(microseconds: nanoseconds ~/ 1000));
        }
        return dateTime;
      }
    }
    return DateTime.now(); // Fallback
  }

  factory MCQ.fromJson(Map<String, dynamic> json, String id) {
    return MCQ(
      id: id,
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
      chapterId: json['chapterId'] ?? '',
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      hearts: json['hearts'] ?? 0,
      upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(json['downvotedBy'] ?? []),
      heartedBy: List<String>.from(json['heartedBy'] ?? []),
      topicList: List<String>.from(json['topicList'] ?? []),
      subtopicList: List<String>.from(json['subtopicList'] ?? []),
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'chapterId': chapterId,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'hearts': hearts,
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
      'heartedBy': heartedBy,
      'topicList': topicList,
      'subtopicList': subtopicList,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  MCQ copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    String? chapterId,
    int? upvotes,
    int? downvotes,
    int? hearts,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    List<String>? heartedBy,
    List<String>? topicList,
    List<String>? subtopicList,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MCQ(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
      chapterId: chapterId ?? this.chapterId,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      hearts: hearts ?? this.hearts,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      downvotedBy: downvotedBy ?? this.downvotedBy,
      heartedBy: heartedBy ?? this.heartedBy,
      topicList: topicList ?? this.topicList,
      subtopicList: subtopicList ?? this.subtopicList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
