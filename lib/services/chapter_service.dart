import 'dart:async';
import '../models/mcq.dart';
import 'chapter_firestore_service.dart';
import 'mcq_firestore_service.dart';
import 'short_firestore_service.dart';

class ChapterService {
  final ChapterFirestoreService _chapterFirestoreService = ChapterFirestoreService();
  final McqFirestoreService _mcqFirestoreService = McqFirestoreService();
  final ShortFirestoreService _shortFirestoreService = ShortFirestoreService();

  Future<Map<String, dynamic>> fetchChapterData(String subjectCode) async {
    return await _chapterFirestoreService.fetchChapterData(subjectCode);
  }

  Future<List<MCQ>> fetchMcqsForChapter(String subjectCode, int chapterOrderby) async {
    return await _mcqFirestoreService.fetchMcqsForChapter(subjectCode, chapterOrderby);
  }

  Future<List<MCQ>> fetchShortsForChapter(String subjectCode, int chapterOrderby) async {
    return await _shortFirestoreService.fetchShortsForChapter(subjectCode, chapterOrderby);
  }

  Future<void> updateMcqReaction(String subjectCode, int chapterOrderby, String mcqId, String reactionType, String userId) async {
    return await _mcqFirestoreService.updateMcqReaction(subjectCode, chapterOrderby, mcqId, reactionType, userId);
  }

  Future<void> updateShortReaction(String subjectCode, int chapterOrderby, String shortId, String reactionType, String userId) async {
    return await _shortFirestoreService.updateShortReaction(subjectCode, chapterOrderby, shortId, reactionType, userId);
  }




}
