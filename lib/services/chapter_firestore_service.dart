import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chapter.dart';

class ChapterFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchChapterData(String subjectCode) async {
    try {
      String normalizedSubjectCode = subjectCode.toLowerCase();

      DocumentSnapshot metaDataDoc = await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .doc('questionMetaData')
          .get();

      if (!metaDataDoc.exists) {
        return {'chapters': [], 'type': ''};
      }

      final data = metaDataDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        return {'chapters': [], 'type': ''};
      }

      List<dynamic> chaptersData = data['chapterData'] ?? data['chapters'] ?? [];

      if (chaptersData.isEmpty) {
        return {'chapters': [], 'type': ''};
      }

      List<Chapter> chapters = [];
      for (var i = 0; i < chaptersData.length; i++) {
        final chapterData = chaptersData[i] as Map<String, dynamic>;

        final chapter = Chapter(
          id: 'chapter_${chapterData['orderby'] ?? i + 1}',
          orderby: chapterData['orderby'] ?? i + 1,
          isMcq: true,
          name: chapterData['name'] ?? 'Chapter ${i + 1}',
          mcqCount: chapterData['mcqCount'] ?? 0,
          shortCount: chapterData['shortCount'] ?? 0,
        );

        chapters.add(chapter);
      }

      // Sort by orderby
      chapters.sort((a, b) => a.orderby.compareTo(b.orderby));

      return {'chapters': chapters, 'type': 'Chapter'};
    } catch (e) {
      return {'chapters': [], 'type': ''};
    }
  }
}
