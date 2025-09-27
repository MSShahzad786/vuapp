import 'package:cloud_firestore/cloud_firestore.dart';

class SelectedSubject {
  final String subCode;
  final String subName;
  final String subIcon;
  final String org;
  final int credits;
  final int mcqsCount;
  final String subjRef;
  final DateTime enrollmentDate;
  final DateTime lastModified;

  SelectedSubject({
    required this.subCode,
    required this.subName,
    required this.subIcon,
    required this.org,
    required this.credits,
    required this.mcqsCount,
    required this.subjRef,
    DateTime? enrollmentDate,
    DateTime? lastModified,
  }) :
    enrollmentDate = enrollmentDate ?? DateTime.now(),
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
      subjRef: json['subjRef'] as String,
      enrollmentDate: _parseTimestamp(json['enrollmentDate']),
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
      'enrollmentDate': Timestamp.fromDate(enrollmentDate),
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
    String? subjRef,
    DateTime? enrollmentDate,
    DateTime? lastModified,
  }) {
    return SelectedSubject(
      subCode: subCode ?? this.subCode,
      subName: subName ?? this.subName,
      subIcon: subIcon ?? this.subIcon,
      org: org ?? this.org,
      credits: credits ?? this.credits,
      mcqsCount: mcqsCount ?? this.mcqsCount,
      subjRef: subjRef ?? this.subjRef,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
