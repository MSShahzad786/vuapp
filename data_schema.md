# Data Schema Documentation

This document outlines all fields stored in the application's data storage, separated by online (Firestore) collections and offline (SQLite) tables. All data is stored in JSON format.

## Online Storage (Firestore Collections)

### Collection Path: `/mySubjects`
**Purpose:** Stores subject information and their chapters/MCQs.

#### Document Path: `/mySubjects/{subjectCode}`
- `id` (String): Unique identifier
- `subCode` (String): Subject code
- `subName` (String): Subject name
- `subIcon` (String): Subject icon URL/path
- `org` (String): Organization
- `under_process` (Boolean): Whether subject is under processing
- `credits` (Integer): Subject credits

#### Subcollection Path: `/mySubjects/{subjectCode}/chapters`
##### Document Path: `/mySubjects/{subjectCode}/chapters/questionMetaData`
- `chapterData` (Array): Array of chapter objects
  - `orderby` (Integer): Chapter order
  - `name` (String): Chapter name
  - `mcqCount` (Integer): Number of MCQs
  - `shortCount` (Integer): Number of short questions
- `type` (String): Type identifier

##### Document Paths: `/mySubjects/{subjectCode}/chapters/{documentId}` (containing MCQs)
- `orderby` (Integer): Chapter order
- `is_mcq` (Boolean): Whether contains MCQs
- `mcqs` (Array): Array of MCQ objects
  - `mcqId` (String): MCQ unique identifier
  - `question` (String): Question text
  - `options` (Array): Array of option strings
  - `index`/`correctOptionIndex` (Integer): Index of correct option
  - `explain`/`explanation` (String/Array): Explanation text
  - `reactions` (Object): Reaction counts
    - `upvote` (Integer): Upvote count
    - `downvote` (Integer): Downvote count
    - `heart` (Integer): Heart count
  - `upvotedBy` (Array): Array of user IDs who upvoted
  - `downvotedBy` (Array): Array of user IDs who downvoted
  - `heartedBy` (Array): Array of user IDs who hearted
  - `topics` (Array): Array of topic strings
  - `subtopics` (Array): Array of subtopic strings
  - `createdAt` (Timestamp): Creation timestamp
  - `updatedAt` (Timestamp): Last update timestamp

### Collection Path: `/users`
**Purpose:** Stores user-specific data.

#### Subcollection Path: `/users/{userId}/selectedSubjects`
##### Document Paths: `/users/{userId}/selectedSubjects/{documentId}` (with `is_current = true`)
- `is_current` (Boolean): Whether this is the current active document
- `activeSubjects` (Array): Array of active selected subject objects
  - `subCode` (String): Subject code
  - `subName` (String): Subject name
  - `subIcon` (String): Subject icon
  - `org` (String): Organization
  - `credits` (Integer): Credits
  - `mcqsCount` (Integer): Total number of MCQs
  - `attemptedMcqsCount` (Integer): Number of attempted MCQs
  - `correctMcqsCount` (Integer): Number of correctly answered MCQs
  - `subjRef` (String): Reference to subject
  - `attemptedMcqIds` (Array): Array of attempted MCQ IDs
  - `enrollmentDate` (Timestamp): Enrollment date
  - `lastActivity` (Timestamp): Last activity timestamp
  - `lastModified` (Timestamp): Last modification timestamp
- `inactiveSubjects` (Array): Array of inactive selected subject objects (same structure as activeSubjects)
- `lastUpdated` (Timestamp): Last update timestamp

#### Subcollection Path: `/users/{userId}/userTests`
##### Document Paths: `/users/{userId}/userTests/{documentId}` (with `is_active = true`)
- `is_active` (Boolean): Whether this document is active
- `testData` (Array): Array of test objects
  - `name` (String): Test name
  - `created_date` (Timestamp): Creation date
  - `all_ids` (Array): Array of all MCQ IDs in test
  - `correct_ids` (Array): Array of correctly answered MCQ IDs
  - `attempted_ids` (Array): Array of attempted MCQ IDs
  - `status` (String): Test status
  - `subCode` (String): Subject code
  - `test_id` (String): Unique test identifier
  - `chapter` (Integer): Chapter number
- `total_tests` (Integer): Total number of tests

## Offline Storage (SQLite Tables)
**Database Path:** `{app_data_directory}/vu_mcqs.db`

### Table: `selected_subjects`
**Purpose:** Locally stored selected subjects.

- `id` (INTEGER PRIMARY KEY AUTOINCREMENT): Auto-incrementing ID
- `subCode` (TEXT UNIQUE): Subject code
- `subName` (TEXT): Subject name
- `subIcon` (TEXT): Subject icon
- `org` (TEXT): Organization
- `credits` (INTEGER): Credits
- `mcqsCount` (INTEGER): Total number of MCQs
- `attemptedMcqsCount` (INTEGER): Number of attempted MCQs
- `correctMcqsCount` (INTEGER): Number of correctly answered MCQs
- `subjRef` (TEXT): Reference to subject
- `attemptedMcqIds` (TEXT): Array of attempted MCQ IDs (stored as JSON string)
- `enrollmentDate` (INTEGER): Enrollment date (Unix timestamp)
- `lastActivity` (INTEGER): Last activity timestamp (Unix timestamp)
- `lastModified` (INTEGER): Last modification timestamp (Unix timestamp)
- `is_active` (INTEGER): Active status (1 = active, 0 = inactive)

### Table: `selected_chapters`
**Purpose:** Locally stored selected chapters.

- `id` (TEXT PRIMARY KEY): Unique identifier (format: subCode_orderby)
- `subCode` (TEXT): Subject code
- `chapName` (TEXT): Chapter name
- `orderby` (INTEGER): Chapter order
- `mcqCount` (INTEGER): Number of MCQs
- `shortCount` (INTEGER): Number of short questions

### Dynamic Tables: `mcqs_{subjectCode}`
**Purpose:** Locally stored MCQs per subject (one table per subject).
**Note:** Table name format is `mcqs_` followed by lowercase subject code.

- `id` (INTEGER PRIMARY KEY AUTOINCREMENT): Auto-incrementing ID
- `subCode` (TEXT): Subject code
- `chapter_order` (INTEGER): Chapter order number
- `mcqid` (TEXT): MCQ unique identifier
- `question` (TEXT): Question text
- `options` (TEXT): Options as delimited string (separated by `|||`)
- `correct_index` (INTEGER): Index of correct option
- `explanation` (TEXT): Explanation text
- `reactions` (TEXT): Reaction counts as JSON string (format: `{"upvote": X, "downvote": Y, "heart": Z}`)
- `topics` (TEXT): Topics as delimited string (separated by `|||`)

## Notes
- All online data uses Firestore Timestamps for date/time fields
- Offline storage uses SQLite with appropriate data types
- Dynamic MCQ tables are created on-demand per subject
- Array fields in Firestore are stored as actual arrays
- Array fields in SQLite are stored as delimited strings for options and topics, or JSON strings for complex arrays
- Reaction data in SQLite is stored as a JSON string due to SQLite limitations
- When deactivating a subject locally, update `is_active` to 0 instead of deleting the record to maintain progress data