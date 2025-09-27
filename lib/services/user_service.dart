import '../models/selected_subject.dart';
import '../models/subject.dart';
import 'user_subject_firestore_service.dart';

class UserService {
  final UserSubjectFirestoreService _firestoreService = UserSubjectFirestoreService();

  Future<Map<String, List<SelectedSubject>>> fetchSubjectsData(String userId) async {
    return await _firestoreService.fetchSubjectsData(userId);
  }

  Future<List<SelectedSubject>> fetchSelectedSubjects(String userId) async {
    return await _firestoreService.fetchSelectedSubjects(userId);
  }


  Future<SelectedSubject?> addSubjectToSelectedSubjectsDoc(String userId, Subject subject, int mcqsCount) async {
    return await _firestoreService.addSubjectToSelectedSubjectsDoc(userId, subject, mcqsCount);
  }

  Future<bool> toggleSubjectStatus(String userId, String subCode) async {
    return await _firestoreService.toggleSubjectStatus(userId, subCode);
  }

  Future<bool> removeSubjectFromSelected(String userId, String subCode) async {
    return await _firestoreService.removeSubjectFromSelected(userId, subCode);
  }

}
