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
      underProcess: data['under_process'] ?? false,
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
