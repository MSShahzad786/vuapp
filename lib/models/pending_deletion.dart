class PendingDeletion {
  final int? id;
  final String subjectCode;
  final String userId;
  final int timestamp;
  final int synced;

  PendingDeletion({
    this.id,
    required this.subjectCode,
    required this.userId,
    required this.timestamp,
    required this.synced,
  });

  factory PendingDeletion.fromMap(Map<String, dynamic> map) {
    return PendingDeletion(
      id: map['id'],
      subjectCode: map['subject_code'],
      userId: map['user_id'],
      timestamp: map['timestamp'],
      synced: map['synced'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_code': subjectCode,
      'user_id': userId,
      'timestamp': timestamp,
      'synced': synced,
    };
  }

  @override
  String toString() {
    return 'PendingDeletion(id: $id, subjectCode: $subjectCode, userId: $userId, timestamp: $timestamp, synced: $synced)';
  }
}