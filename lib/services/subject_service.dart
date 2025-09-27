import '../models/subject.dart';
import 'subject_firestore_service.dart';

class SubjectService {
  final SubjectFirestoreService _firestoreService = SubjectFirestoreService();

  Future<List<Subject>> fetchMySubjects() async {
    return await _firestoreService.fetchMySubjects();
  }

  Future<List<Subject>> searchSubjects(String query) async {
    return await _firestoreService.searchSubjects(query);
  }

  Future<int> getMcqsCount(String subjectId) async {
    return await _firestoreService.getMcqsCount(subjectId);
  }
}
