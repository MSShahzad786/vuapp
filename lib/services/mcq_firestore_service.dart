import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mcq.dart';

class McqFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MCQ>> fetchMcqsForChapter(String subjectCode, int chapterOrderby) async {
    try {
      String normalizedSubjectCode = subjectCode.toLowerCase();

      QuerySnapshot mcqDocumentsSnapshot = await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .where('orderby', isEqualTo: chapterOrderby)
          .where('is_mcq', isEqualTo: true)
          .get();

      List<MCQ> mcqs = [];
      for (var mcqDoc in mcqDocumentsSnapshot.docs) {
        final docData = mcqDoc.data() as Map<String, dynamic>;
        List<dynamic> mcqsArray = docData['mcqs'] ?? [];

        if (mcqsArray.isEmpty) {
          continue;
        }

        for (var i = 0; i < mcqsArray.length; i++) {
          final mcqData = mcqsArray[i] as Map<String, dynamic>;

          // Handle explanation - join array if it's an array
          String explanation = '';
          if (mcqData['explain'] is List) {
            explanation = (mcqData['explain'] as List).join(' ');
          } else {
            explanation = mcqData['explain'] ?? mcqData['explanation'] ?? '';
          }

          // Handle reactions object
          final reactions = mcqData['reactions'] as Map<String, dynamic>? ?? {};

          final mcq = MCQ(
            id: mcqData['mcqId']?.toString() ?? 'mcq_${i + 1}',
            question: mcqData['question'] ?? '',
            options: List<String>.from(mcqData['options'] ?? []),
            correctOptionIndex: mcqData['index'] ?? mcqData['correctOptionIndex'] ?? 0,
            explanation: explanation,
            chapterId: mcqDoc.id,
            upvotes: reactions['upvote'] ?? mcqData['upvotes'] ?? 0,
            downvotes: reactions['downvote'] ?? mcqData['downvotes'] ?? 0,
            hearts: reactions['heart'] ?? mcqData['hearts'] ?? 0,
            upvotedBy: List<String>.from(mcqData['upvotedBy'] ?? []),
            downvotedBy: List<String>.from(mcqData['downvotedBy'] ?? []),
            heartedBy: List<String>.from(mcqData['heartedBy'] ?? []),
            topicList: List<String>.from(mcqData['topics'] ?? []),
            subtopicList: List<String>.from(mcqData['subtopics'] ?? []),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          mcqs.add(mcq);
        }
      }

      if (mcqs.isEmpty) {
        return [];
      }

      return mcqs;
    } catch (e) {
      return [];
    }
  }

  Future<void> updateMcqReaction(String subjectCode, int chapterOrderby, String mcqId, String reactionType, String userId) async {
    try {
      String normalizedSubjectCode = subjectCode.toLowerCase();

      // Find the document containing this MCQ
      QuerySnapshot mcqDocumentsSnapshot = await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .where('orderby', isEqualTo: chapterOrderby)
          .where('is_mcq', isEqualTo: true)
          .get();

      // Find the document containing the MCQ
      DocumentSnapshot? mcqDoc;
      int mcqIndex = -1;
      Map<String, dynamic>? mcqData;
      for (var doc in mcqDocumentsSnapshot.docs) {
        final docData = doc.data() as Map<String, dynamic>;
        List<dynamic> mcqsArray = docData['mcqs'] ?? [];
        for (int i = 0; i < mcqsArray.length; i++) {
          final currentMcq = mcqsArray[i] as Map<String, dynamic>;
          if (currentMcq['mcqId']?.toString() == mcqId) {
            mcqDoc = doc;
            mcqIndex = i;
            mcqData = currentMcq;
            break;
          }
        }
        if (mcqDoc != null) break;
      }

      if (mcqDoc == null || mcqIndex == -1 || mcqData == null) {
        return;
      }

      final docData = mcqDoc.data() as Map<String, dynamic>;
      List<dynamic> mcqsArray = docData['mcqs'] ?? [];

      // Initialize user tracking lists if not exists
      if (!mcqData.containsKey('upvotedBy')) mcqData['upvotedBy'] = [];
      if (!mcqData.containsKey('downvotedBy')) mcqData['downvotedBy'] = [];
      if (!mcqData.containsKey('heartedBy')) mcqData['heartedBy'] = [];

      // Initialize reactions if not exists
      if (!mcqData.containsKey('reactions')) {
        mcqData['reactions'] = {
          'upvote': mcqData['upvotes'] ?? 0,
          'downvote': mcqData['downvotes'] ?? 0,
          'heart': mcqData['hearts'] ?? 0,
        };
      }

      final reactions = mcqData['reactions'] as Map<String, dynamic>;
      final upvotedBy = List<String>.from(mcqData['upvotedBy'] ?? []);
      final downvotedBy = List<String>.from(mcqData['downvotedBy'] ?? []);
      final heartedBy = List<String>.from(mcqData['heartedBy'] ?? []);

      // Determine the user list based on reaction type
      List<String> targetList;
      String listKey;
      switch (reactionType) {
        case 'upvote':
          targetList = upvotedBy;
          listKey = 'upvotedBy';
          break;
        case 'downvote':
          targetList = downvotedBy;
          listKey = 'downvotedBy';
          break;
        case 'heart':
          targetList = heartedBy;
          listKey = 'heartedBy';
          break;
        default:
          return;
      }

      // Check if user has already reacted
      bool hasReacted = targetList.contains(userId);
      int currentCount = reactions[reactionType] ?? 0;

      if (hasReacted) {
        // Remove reaction
        targetList.remove(userId);
        reactions[reactionType] = currentCount > 0 ? currentCount - 1 : 0;
      } else {
        // Add reaction
        targetList.add(userId);
        reactions[reactionType] = currentCount + 1;
      }

      // Update the user lists
      mcqData[listKey] = targetList;

      // Update the document
      mcqsArray[mcqIndex] = mcqData;

      await _firestore
          .collection('mySubjects')
          .doc(normalizedSubjectCode)
          .collection('chapters')
          .doc(mcqDoc.id)
          .update({'mcqs': mcqsArray});

    } catch (e) {
      // Silently handle errors
    }
  }
}
