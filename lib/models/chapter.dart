class Chapter {
  final String id;
  final int orderby;
  final bool isMcq;
  final String name;
  final int mcqCount;
  final int shortCount;

  Chapter({
    required this.id,
    required this.orderby,
    required this.isMcq,
    required this.name,
    this.mcqCount = 0,
    this.shortCount = 0,
  });

  factory Chapter.fromJson(Map<String, dynamic> json, String id) {
    return Chapter(
      id: id,
      orderby: json['orderby'] ?? 0,
      isMcq: json['is_mcq'] ?? false,
      name: json['name'] ?? '',
      mcqCount: json['mcqCount'] ?? 0,
      shortCount: json['shortCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderby': orderby,
      'is_mcq': isMcq,
      'name': name,
      'mcqCount': mcqCount,
      'shortCount': shortCount,
    };
  }
}
