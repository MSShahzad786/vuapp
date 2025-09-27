import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject.dart';
import '../models/mcq.dart';
import 'reaction_firestore_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final ReactionFirestoreService _reactionService = ReactionFirestoreService();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vu_mcqs.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create selected_subjects table
    await db.execute('''
      CREATE TABLE selected_subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subCode TEXT UNIQUE,
        subName TEXT,
        subIcon TEXT,
        org TEXT,
        credits INTEGER,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Create selected_chapters table
    await db.execute('''
      CREATE TABLE selected_chapters (
        id TEXT PRIMARY KEY,
        subCode TEXT,
        chapName TEXT,
        orderby INTEGER,
        mcqCount INTEGER,
        shortCount INTEGER,
        UNIQUE(subCode, orderby)
      )
    ''');

    // Create pending_sub_del table for offline subject deletions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sub_del (
        subject_code TEXT PRIMARY KEY,
        deletion_time INTEGER
      )
    ''');

    // Create settings table for app settings
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        value TEXT
      )
    ''');

    // Insert default theme setting (1 for light, 0 for dark)
    await db.insert('settings', {'key': 'theme', 'value': '1'});
  }

  // Selected Subjects operations
  Future<void> insertSelectedSubject(Subject subject) async {
    final db = await database;
    await db.insert(
      'selected_subjects',
      {
        'subCode': subject.subCode,
        'subName': subject.subName,
        'subIcon': subject.subIcon,
        'org': subject.org,
        'credits': subject.credits,
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSelectedSubjects() async {
    final db = await database;
    return await db.query('selected_subjects', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<void> removeSelectedSubject(String subCode) async {
    final db = await database;
    await db.delete('selected_subjects', where: 'subCode = ?', whereArgs: [subCode]);
  }

  Future<void> updateSubjectStatus(String subCode, int isActive) async {
    final db = await database;
    await db.update('selected_subjects', {'is_active': isActive}, where: 'subCode = ?', whereArgs: [subCode]);
  }

  Future<List<Map<String, dynamic>>> getInactiveSubjects() async {
    final db = await database;
    return await db.query('selected_subjects', where: 'is_active = ?', whereArgs: [0]);
  }

  Future<bool> isSubjectSelected(String subCode) async {
    final db = await database;
    final result = await db.query(
      'selected_subjects',
      where: 'subCode = ?',
      whereArgs: [subCode],
    );
    return result.isNotEmpty;
  }

  // Selected Chapters operations
  Future<void> insertSelectedChapter(String subCode, Map<String, dynamic> chapterData) async {
    final db = await database;

    await db.insert(
      'selected_chapters',
      {
        'id': '${subCode}_${chapterData['orderby']}',
        'subCode': subCode,
        'chapName': chapterData['name'] ?? '',
        'orderby': chapterData['orderby'] ?? 0,
        'mcqCount': chapterData['mcqCount'] ?? 0,
        'shortCount': chapterData['shortCount'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSelectedChapters(String subCode) async {
    final db = await database;
    return await db.query(
      'selected_chapters',
      where: 'subCode = ?',
      whereArgs: [subCode],
      orderBy: 'orderby ASC',
    );
  }

  Future<void> removeSelectedChapters(String subCode) async {
    final db = await database;
    await db.delete('selected_chapters', where: 'subCode = ?', whereArgs: [subCode]);
  }

  // MCQ operations - Dynamic table creation per subject
  Future<void> createMcqTable(String subjectCode) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subCode TEXT,
        chapter_order INTEGER,
        mcqid TEXT,
        question TEXT,
        options TEXT,
        correct_index INTEGER,
        explanation TEXT,
        reactions TEXT,
        topics TEXT,
        is_reacted INTEGER DEFAULT 0,
        is_sync INTEGER DEFAULT 0,
        UNIQUE(subCode, chapter_order, mcqid)
      )
    ''');
  }

  // Short operations - Dynamic table creation per subject
  Future<void> createShortTable(String subjectCode) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subCode TEXT,
        chapter_order INTEGER,
        shortid TEXT,
        question TEXT,
        explanation TEXT,
        reactions TEXT,
        topics TEXT,
        is_reacted INTEGER DEFAULT 0,
        is_sync INTEGER DEFAULT 0,
        UNIQUE(subCode, chapter_order, shortid)
      )
    ''');
  }

  Future<void> insertMcq(String subjectCode, int chapterOrder, MCQ mcq) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    try {
      await createMcqTable(subjectCode);

      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Fetch user reactions for this chapter
      int isReacted = 0;
      if (userId != null) {
        try {
          final userReaction = await _reactionService.getUserReaction(userId, subjectCode, chapterOrder, mcq.id, 'mcq');
          if (userReaction != null) {
            isReacted = userReaction; // 1=upvote, 2=downvote, 3=heart
          }
        } catch (e) {
          // Silently handle errors - default to 0
        }
      }

      final data = {
        'subCode': subjectCode,
        'chapter_order': chapterOrder,
        'mcqid': mcq.id,
        'question': mcq.question,
        'options': mcq.options.join('|||'), // Store as delimited string
        'correct_index': mcq.correctOptionIndex,
        'explanation': mcq.explanation,
        'reactions': '{"upvote": ${mcq.upvotes}, "downvote": ${mcq.downvotes}, "heart": ${mcq.hearts}}',
        'topics': mcq.topicList.join('|||'),
        'is_reacted': isReacted,
        'is_sync': 1, // Always 1 when inserting from Firestore (reactions fetched)
      };

      await db.insert(
        tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

    } catch (e) {
      rethrow;
    }
  }

  /// Batch insert multiple MCQs using SQLite transactions for better performance
  Future<void> batchInsertMcqs(String subjectCode, int chapterOrder, List<MCQ> mcqs) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    try {
      await createMcqTable(subjectCode);

      // Get current user ID once for all MCQs
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Pre-fetch all user reactions for this chapter to avoid multiple network calls
      Map<String, int> userReactions = {};
      if (userId != null) {
        try {
          for (final mcq in mcqs) {
            final userReaction = await _reactionService.getUserReaction(userId, subjectCode, chapterOrder, mcq.id, 'mcq');
            if (userReaction != null) {
              userReactions[mcq.id] = userReaction;
            }
          }
        } catch (e) {
          // Silently handle errors - default to 0 for all
        }
      }

      // Use transaction for batch insert
      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final mcq in mcqs) {
          final isReacted = userReactions[mcq.id] ?? 0;

          final data = {
            'subCode': subjectCode,
            'chapter_order': chapterOrder,
            'mcqid': mcq.id,
            'question': mcq.question,
            'options': mcq.options.join('|||'),
            'correct_index': mcq.correctOptionIndex,
            'explanation': mcq.explanation,
            'reactions': '{"upvote": ${mcq.upvotes}, "downvote": ${mcq.downvotes}, "heart": ${mcq.hearts}}',
            'topics': mcq.topicList.join('|||'),
            'is_reacted': isReacted,
            'is_sync': 1,
          };

          batch.insert(
            tableName,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

    } catch (e) {
      rethrow;
    }
  }

  Future<void> insertShort(String subjectCode, int chapterOrder, MCQ short) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    try {
      await createShortTable(subjectCode);

      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Fetch user reactions for this chapter
      int isReacted = 0;
      if (userId != null) {
        try {
          final userReaction = await _reactionService.getUserReaction(userId, subjectCode, chapterOrder, short.id, 'short');
          if (userReaction != null) {
            isReacted = userReaction; // 1=upvote, 2=downvote, 3=heart
          }
        } catch (e) {
          // Silently handle errors - default to 0
        }
      }

      final data = {
        'subCode': subjectCode,
        'chapter_order': chapterOrder,
        'shortid': short.id,
        'question': short.question,
        'explanation': short.explanation,
        'reactions': '{"upvote": ${short.upvotes}, "downvote": ${short.downvotes}, "heart": ${short.hearts}}',
        'topics': short.topicList.join('|||'),
        'is_reacted': isReacted,
        'is_sync': 1, // Always 1 when inserting from Firestore (reactions fetched)
      };

      final result = await db.insert(
        tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Verify the insertion
      final verifyResult = await db.query(tableName, where: 'shortid = ?', whereArgs: [short.id]);

    } catch (e) {
      rethrow;
    }
  }

  /// Batch insert multiple Shorts using SQLite transactions for better performance
  Future<void> batchInsertShorts(String subjectCode, int chapterOrder, List<MCQ> shorts) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    try {
      await createShortTable(subjectCode);

      // Get current user ID once for all shorts
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Pre-fetch all user reactions for this chapter
      Map<String, int> userReactions = {};
      if (userId != null) {
        try {
          for (final short in shorts) {
            final userReaction = await _reactionService.getUserReaction(userId, subjectCode, chapterOrder, short.id, 'short');
            if (userReaction != null) {
              userReactions[short.id] = userReaction;
            }
          }
        } catch (e) {
          // Silently handle errors - default to 0 for all
        }
      }

      // Use transaction for batch insert
      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final short in shorts) {
          final isReacted = userReactions[short.id] ?? 0;

          final data = {
            'subCode': subjectCode,
            'chapter_order': chapterOrder,
            'shortid': short.id,
            'question': short.question,
            'explanation': short.explanation,
            'reactions': '{"upvote": ${short.upvotes}, "downvote": ${short.downvotes}, "heart": ${short.hearts}}',
            'topics': short.topicList.join('|||'),
            'is_reacted': isReacted,
            'is_sync': 1,
          };

          batch.insert(
            tableName,
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });

    } catch (e) {
      rethrow;
    }
  }

  Future<List<MCQ>> getMcqsForChapter(String subjectCode, int chapterOrder) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    debugPrint('Querying table: $tableName for chapter_order: $chapterOrder');

    // Create table if it doesn't exist
    await createMcqTable(subjectCode);

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'chapter_order = ?',
      whereArgs: [chapterOrder],
    );

    debugPrint('Found ${maps.length} MCQ records in database');

    // Get current user ID to update is_reacted if needed
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Build MCQs list asynchronously
    final mcqs = <MCQ>[];
    for (final map in maps) {
      try {
        // Parse reaction data from stored JSON string
        final reactionsStr = map['reactions'] as String? ?? '{"upvote": 0, "downvote": 0, "heart": 0}';
        int upvotes = 0, downvotes = 0, hearts = 0;

        try {
          final upvoteMatch = RegExp(r'"upvote":\s*(\d+)').firstMatch(reactionsStr);
          if (upvoteMatch != null) upvotes = int.parse(upvoteMatch.group(1)!);

          final downvoteMatch = RegExp(r'"downvote":\s*(\d+)').firstMatch(reactionsStr);
          if (downvoteMatch != null) downvotes = int.parse(downvoteMatch.group(1)!);

          final heartMatch = RegExp(r'"heart":\s*(\d+)').firstMatch(reactionsStr);
          if (heartMatch != null) hearts = int.parse(heartMatch.group(1)!);
        } catch (parseError) {
          // Silently handle parse errors
        }

        // Check if we need to update is_reacted for this MCQ
        int currentIsReacted = map['is_reacted'] as int? ?? 0;
        if (userId != null && currentIsReacted == 0) {
          // Try to fetch user reaction and update if found
          try {
            final userReaction = await _reactionService.getUserReaction(userId, subjectCode, chapterOrder, map['mcqid'], 'mcq');
            if (userReaction != null && userReaction != 0) {
              // Update the is_reacted and is_sync in database
              await db.update(
                tableName,
                {'is_reacted': userReaction, 'is_sync': 1},
                where: 'mcqid = ? AND chapter_order = ?',
                whereArgs: [map['mcqid'], chapterOrder],
              );
              currentIsReacted = userReaction;
            }
          } catch (e) {
            // Silently handle errors
          }
        }

        // For local storage, user reactions are handled per user via is_reacted column
        final upvotedBy = <String>[];
        final downvotedBy = <String>[];
        final heartedBy = <String>[];

        final mcq = MCQ(
          id: map['mcqid'],
          question: map['question'],
          options: (map['options'] as String).split('|||'),
          correctOptionIndex: map['correct_index'],
          explanation: map['explanation'],
          chapterId: chapterOrder.toString(),
          upvotes: upvotes,
          downvotes: downvotes,
          hearts: hearts,
          upvotedBy: upvotedBy,
          downvotedBy: downvotedBy,
          heartedBy: heartedBy,
          topicList: (map['topics'] as String?)?.split('|||') ?? [],
          subtopicList: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mcqs.add(mcq);
      } catch (e) {
        // Skip invalid records
      }
    }

    return mcqs;
  }

  Future<List<MCQ>> getShortsForChapter(String subjectCode, int chapterOrder) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    // Create table if it doesn't exist
    await createShortTable(subjectCode);

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'chapter_order = ?',
      whereArgs: [chapterOrder],
    );

    // Get current user ID to update is_reacted if needed
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Build Shorts list asynchronously
    final shorts = <MCQ>[];
    for (final map in maps) {
      try {
        // Parse reaction data from stored JSON string
        final reactionsStr = map['reactions'] as String? ?? '{"upvote": 0, "downvote": 0, "heart": 0}';
        int upvotes = 0, downvotes = 0, hearts = 0;

        try {
          final upvoteMatch = RegExp(r'"upvote":\s*(\d+)').firstMatch(reactionsStr);
          if (upvoteMatch != null) upvotes = int.parse(upvoteMatch.group(1)!);

          final downvoteMatch = RegExp(r'"downvote":\s*(\d+)').firstMatch(reactionsStr);
          if (downvoteMatch != null) downvotes = int.parse(downvoteMatch.group(1)!);

          final heartMatch = RegExp(r'"heart":\s*(\d+)').firstMatch(reactionsStr);
          if (heartMatch != null) hearts = int.parse(heartMatch.group(1)!);
        } catch (parseError) {
          // Silently handle parse errors
        }

        // Check if we need to update is_reacted for this short
        int currentIsReacted = map['is_reacted'] as int? ?? 0;
        if (userId != null && currentIsReacted == 0) {
          // Try to fetch user reaction and update if found
          try {
            final userReaction = await _reactionService.getUserReaction(userId, subjectCode, chapterOrder, map['shortid'], 'short');
            if (userReaction != null && userReaction != 0) {
              // Update the is_reacted and is_sync in database
              await db.update(
                tableName,
                {'is_reacted': userReaction, 'is_sync': 1},
                where: 'shortid = ? AND chapter_order = ?',
                whereArgs: [map['shortid'], chapterOrder],
              );
              currentIsReacted = userReaction;
            }
          } catch (e) {
            // Silently handle errors
          }
        }

        // For local storage, user reactions are handled per user via is_reacted column
        final upvotedBy = <String>[];
        final downvotedBy = <String>[];
        final heartedBy = <String>[];

        final short = MCQ(
          id: map['shortid'],
          question: map['question'],
          options: [], // Shorts don't have options
          correctOptionIndex: 0, // Not applicable for shorts
          explanation: map['explanation'],
          chapterId: chapterOrder.toString(),
          upvotes: upvotes,
          downvotes: downvotes,
          hearts: hearts,
          upvotedBy: upvotedBy,
          downvotedBy: downvotedBy,
          heartedBy: heartedBy,
          topicList: (map['topics'] as String?)?.split('|||') ?? [],
          subtopicList: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        shorts.add(short);
      } catch (e) {
        // Skip invalid records
      }
    }

    return shorts;
  }

  Future<bool> hasMcqsForChapter(String subjectCode, int chapterOrder) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    final result = await db.query(
      tableName,
      where: 'chapter_order = ?',
      whereArgs: [chapterOrder],
      limit: 1,
    );

    final hasData = result.isNotEmpty;
    debugPrint('hasMcqsForChapter: table=$tableName, chapter=$chapterOrder, hasData=$hasData');
    return hasData;
  }

  Future<bool> hasShortsForChapter(String subjectCode, int chapterOrder) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    final result = await db.query(
      tableName,
      where: 'chapter_order = ?',
      whereArgs: [chapterOrder],
      limit: 1,
    );

    final hasData = result.isNotEmpty;
    debugPrint('hasShortsForChapter: table=$tableName, chapter=$chapterOrder, hasData=$hasData');
    return hasData;
  }

  Future<void> clearMcqsForSubject(String subjectCode) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    // Check if table exists before attempting to delete
    final tableExists = await db.query('sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName]);

    if (tableExists.isNotEmpty) {
      await db.delete(tableName);
    }
  }

  Future<void> clearShortsForSubject(String subjectCode) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    // Check if table exists before attempting to delete
    final tableExists = await db.query('sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName]);

    if (tableExists.isNotEmpty) {
      await db.delete(tableName);
    }
  }

  // Drop MCQ table completely for a subject
  Future<void> dropMcqTable(String subjectCode) async {
    try {
      final db = await database;
      final tableName = 'mcqs_${subjectCode.toLowerCase()}';

      // Check if table exists before attempting to drop
      final tableExists = await db.query('sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', tableName]);

      if (tableExists.isNotEmpty) {
        await db.execute('DROP TABLE IF EXISTS $tableName');
      }
    } catch (e) {
      // Silently handle errors - table might not exist or other issues
      debugPrint('Warning: Failed to drop MCQ table for $subjectCode: $e');
    }
  }

  // Drop Short table completely for a subject
  Future<void> dropShortTable(String subjectCode) async {
    try {
      final db = await database;
      final tableName = 'shorts_${subjectCode.toLowerCase()}';

      // Check if table exists before attempting to drop
      final tableExists = await db.query('sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', tableName]);

      if (tableExists.isNotEmpty) {
        await db.execute('DROP TABLE IF EXISTS $tableName');
      }
    } catch (e) {
      // Silently handle errors - table might not exist or other issues
      debugPrint('Warning: Failed to drop Short table for $subjectCode: $e');
    }
  }

  // Update MCQ reaction in local database
  Future<void> updateMcqReactionLocal(String subjectCode, int chapterOrder, String mcqId, String reactionType, String userId, bool isAdding) async {
    final db = await database;
    final tableName = 'mcqs_${subjectCode.toLowerCase()}';

    try {
      // Get current reaction data
      final result = await db.query(
        tableName,
        where: 'mcqid = ? AND chapter_order = ?',
        whereArgs: [mcqId, chapterOrder],
        limit: 1,
      );

      if (result.isEmpty) return;

      final row = result.first;
      final currentReactionValue = row['is_reacted'] as int? ?? 0;
      final reactionsStr = row['reactions'] as String? ?? '{"upvote": 0, "downvote": 0, "heart": 0}';

      // Parse current counts
      int upvotes = 0, downvotes = 0, hearts = 0;
      try {
        final upvoteMatch = RegExp(r'"upvote":\s*(\d+)').firstMatch(reactionsStr);
        if (upvoteMatch != null) upvotes = int.parse(upvoteMatch.group(1)!);

        final downvoteMatch = RegExp(r'"downvote":\s*(\d+)').firstMatch(reactionsStr);
        if (downvoteMatch != null) downvotes = int.parse(downvoteMatch.group(1)!);

        final heartMatch = RegExp(r'"heart":\s*(\d+)').firstMatch(reactionsStr);
        if (heartMatch != null) hearts = int.parse(heartMatch.group(1)!);
      } catch (e) {
        // Use defaults
      }

      // Determine new reaction value
      int newReactionValue;
      String oldReactionType = '';
      if (currentReactionValue == 1) oldReactionType = 'upvote';
      else if (currentReactionValue == 2) oldReactionType = 'downvote';
      else if (currentReactionValue == 3) oldReactionType = 'heart';

      if (!isAdding) {
        newReactionValue = 0; // Remove reaction
      } else {
        newReactionValue = reactionType == 'upvote' ? 1 : (reactionType == 'downvote' ? 2 : 3);
      }

      // Update counts
      if (oldReactionType.isNotEmpty) {
        // Decrement old reaction
        if (oldReactionType == 'upvote') upvotes = (upvotes > 0) ? upvotes - 1 : 0;
        else if (oldReactionType == 'downvote') downvotes = (downvotes > 0) ? downvotes - 1 : 0;
        else if (oldReactionType == 'heart') hearts = (hearts > 0) ? hearts - 1 : 0;
      }

      if (isAdding) {
        // Increment new reaction
        if (reactionType == 'upvote') upvotes += 1;
        else if (reactionType == 'downvote') downvotes += 1;
        else if (reactionType == 'heart') hearts += 1;
      }

      // Update the database
      final updatedReactionsStr = '{"upvote": $upvotes, "downvote": $downvotes, "heart": $hearts}';
      await db.update(
        tableName,
        {
          'is_reacted': newReactionValue,
          'reactions': updatedReactionsStr,
          'is_sync': 0, // Mark as not synced since user reacted locally
        },
        where: 'mcqid = ? AND chapter_order = ?',
        whereArgs: [mcqId, chapterOrder],
      );

    } catch (e) {
      // Handle error
      debugPrint('Error updating MCQ reaction: $e');
    }
  }

  // Update Short reaction in local database
  Future<void> updateShortReactionLocal(String subjectCode, int chapterOrder, String shortId, String reactionType, String userId, bool isAdding) async {
    final db = await database;
    final tableName = 'shorts_${subjectCode.toLowerCase()}';

    try {
      // Get current reaction data
      final result = await db.query(
        tableName,
        where: 'shortid = ? AND chapter_order = ?',
        whereArgs: [shortId, chapterOrder],
        limit: 1,
      );

      if (result.isEmpty) return;

      final row = result.first;
      final currentReactionValue = row['is_reacted'] as int? ?? 0;
      final reactionsStr = row['reactions'] as String? ?? '{"upvote": 0, "downvote": 0, "heart": 0}';

      // Parse current counts
      int upvotes = 0, downvotes = 0, hearts = 0;
      try {
        final upvoteMatch = RegExp(r'"upvote":\s*(\d+)').firstMatch(reactionsStr);
        if (upvoteMatch != null) upvotes = int.parse(upvoteMatch.group(1)!);

        final downvoteMatch = RegExp(r'"downvote":\s*(\d+)').firstMatch(reactionsStr);
        if (downvoteMatch != null) downvotes = int.parse(downvoteMatch.group(1)!);

        final heartMatch = RegExp(r'"heart":\s*(\d+)').firstMatch(reactionsStr);
        if (heartMatch != null) hearts = int.parse(heartMatch.group(1)!);
      } catch (e) {
        // Use defaults
      }

      // Determine new reaction value
      int newReactionValue;
      String oldReactionType = '';
      if (currentReactionValue == 1) oldReactionType = 'upvote';
      else if (currentReactionValue == 2) oldReactionType = 'downvote';
      else if (currentReactionValue == 3) oldReactionType = 'heart';

      if (!isAdding) {
        newReactionValue = 0; // Remove reaction
      } else {
        newReactionValue = reactionType == 'upvote' ? 1 : (reactionType == 'downvote' ? 2 : 3);
      }

      // Update counts
      if (oldReactionType.isNotEmpty) {
        // Decrement old reaction
        if (oldReactionType == 'upvote') upvotes = (upvotes > 0) ? upvotes - 1 : 0;
        else if (oldReactionType == 'downvote') downvotes = (downvotes > 0) ? downvotes - 1 : 0;
        else if (oldReactionType == 'heart') hearts = (hearts > 0) ? hearts - 1 : 0;
      }

      if (isAdding) {
        // Increment new reaction
        if (reactionType == 'upvote') upvotes += 1;
        else if (reactionType == 'downvote') downvotes += 1;
        else if (reactionType == 'heart') hearts += 1;
      }

      // Update the database
      final updatedReactionsStr = '{"upvote": $upvotes, "downvote": $downvotes, "heart": $hearts}';
      await db.update(
        tableName,
        {
          'is_reacted': newReactionValue,
          'reactions': updatedReactionsStr,
          'is_sync': 0, // Mark as not synced since user reacted locally
        },
        where: 'shortid = ? AND chapter_order = ?',
        whereArgs: [shortId, chapterOrder],
      );

    } catch (e) {
      // Handle error
      debugPrint('Error updating Short reaction: $e');
    }
  }

  // User reaction management methods
  Future<void> _addUserReaction(String userId, String questionId, int questionType, int reactionType, String subjectCode, int chapterOrder) async {
    final db = await database;
    await db.insert(
      'user_reactions',
      {
        'user_id': userId,
        'question_id': questionId,
        'question_type': questionType,
        'reaction_type': reactionType,
        'subject_code': subjectCode,
        'chapter_order': chapterOrder,
        'sync': 0, // pending sync
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Replace if exists
    );
  }

  Future<void> _removeUserReaction(String userId, String questionId, int questionType, int reactionType) async {
    final db = await database;
    await db.delete(
      'user_reactions',
      where: 'user_id = ? AND question_id = ? AND question_type = ? AND reaction_type = ?',
      whereArgs: [userId, questionId, questionType, reactionType],
    );
  }

  Future<void> _removeAllUserReactions(String userId, String questionId, String questionType) async {
    final db = await database;
    await db.delete(
      'user_reactions',
      where: 'user_id = ? AND question_id = ? AND question_type = ?',
      whereArgs: [userId, questionId, questionType],
    );
  }

  Future<String?> getUserReactionType(String userId, String questionId, String questionType) async {
    final db = await database;
    int qType = questionType == 'mcq' ? 1 : 2;
    final result = await db.query(
      'user_reactions',
      where: 'user_id = ? AND question_id = ? AND question_type = ?',
      whereArgs: [userId, questionId, qType],
      limit: 1,
    );
    if (result.isNotEmpty) {
      int rType = result.first['reaction_type'] as int;
      return rType == 1 ? 'upvote' : (rType == 2 ? 'downvote' : 'heart');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserReactionsForQuestion(String questionId, String questionType) async {
    final db = await database;
    int qType = questionType == 'mcq' ? 1 : 2;
    final results = await db.query(
      'user_reactions',
      where: 'question_id = ? AND question_type = ?',
      whereArgs: [questionId, qType],
    );
    // Convert back to string format for compatibility
    return results.map((row) {
      int rType = row['reaction_type'] as int;
      String reactionStr = rType == 1 ? 'upvote' : (rType == 2 ? 'downvote' : 'heart');
      return {
        ...row,
        'reaction_type': reactionStr,
        'question_type': questionType,
        'user_id': row['user_id'],
      };
    }).toList();
  }

  Future<bool> hasUserReacted(String userId, String questionId, String questionType, String reactionType) async {
    final db = await database;
    int qType = questionType == 'mcq' ? 1 : 2;
    int rType = reactionType == 'upvote' ? 1 : (reactionType == 'downvote' ? 2 : 3);
    final result = await db.query(
      'user_reactions',
      where: 'user_id = ? AND question_id = ? AND question_type = ? AND reaction_type = ?',
      whereArgs: [userId, questionId, qType, rType],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> clearUserReactionsForSubject(String subjectCode) async {
    final db = await database;
    await db.delete('user_reactions', where: 'subject_code = ?', whereArgs: [subjectCode]);
  }

  // Get all user reactions for a subject, grouped by chapter
  Future<Map<int, List<Map<String, dynamic>>>> getUserReactionsForSubject(String userId, String subjectCode) async {
    final db = await database;
    final results = await db.query(
      'user_reactions',
      where: 'user_id = ? AND subject_code = ?',
      whereArgs: [userId, subjectCode],
    );

    final Map<int, List<Map<String, dynamic>>> chapterReactions = {};

    for (final row in results) {
      int chapterOrder = row['chapter_order'] as int;
      int qType = row['question_type'] as int;
      int rType = row['reaction_type'] as int;

      if (!chapterReactions.containsKey(chapterOrder)) {
        chapterReactions[chapterOrder] = [];
      }

      chapterReactions[chapterOrder]!.add({
        'r_type': rType,
        'id': row['question_id'] as String,
        'q_type': qType,
      });
    }

    return chapterReactions;
  }

  // Mark reactions as synced for a subject
  Future<void> markReactionsAsSynced(String userId, String subjectCode) async {
    final db = await database;
    await db.update(
      'user_reactions',
      {'sync': 1},
      where: 'user_id = ? AND subject_code = ?',
      whereArgs: [userId, subjectCode],
    );
  }

  // Get pending reactions that need to be synced
  Future<List<Map<String, dynamic>>> getPendingReactions() async {
    final db = await database;
    return await db.query(
      'user_reactions',
      where: 'sync = ?',
      whereArgs: [0],
    );
  }


  // Settings operations
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Pending subject deletions operations
  Future<void> addPendingSubjectDeletion(String subjectCode) async {
    final db = await database;
    // Create table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sub_del (
        subject_code TEXT PRIMARY KEY,
        deletion_time INTEGER
      )
    ''');

    await db.insert(
      'pending_sub_del',
      {
        'subject_code': subjectCode,
        'deletion_time': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSubjectDeletions() async {
    final db = await database;
    // Create table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_sub_del (
        subject_code TEXT PRIMARY KEY,
        deletion_time INTEGER
      )
    ''');

    return await db.query('pending_sub_del', orderBy: 'deletion_time ASC');
  }

  Future<void> removePendingSubjectDeletion(String subjectCode) async {
    final db = await database;
    await db.delete('pending_sub_del', where: 'subject_code = ?', whereArgs: [subjectCode]);
  }

  Future<void> clearAllPendingSubjectDeletions() async {
    final db = await database;
    await db.delete('pending_sub_del');
  }
}
