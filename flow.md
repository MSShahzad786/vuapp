# VU MCQs App Flow Documentation


  "reactions": {
    "mcq_12": 1,
    "mcq_17": 3
  }

## Overview
This document outlines the complete user flow, data fetching strategies, and offline/online behavior of the VU MCQs Flutter application. The app provides MCQ-based learning with offline-first capabilities.

## 1. Application Architecture

### Core Components
- **Authentication**: Firebase Auth with Google Sign-In
- **Data Storage**: Firestore (online) + SQLite (offline)
- **State Management**: Provider pattern
- **Connectivity**: Real-time network status monitoring

### Data Flow Strategy
- **Offline-First**: Local SQLite database prioritized for instant access
- **Online-2nd**: If Local Not Exist.

## 2. Authentication Flow

### Initial App Launch
```
App Start → Bootstrap.initialize() → MyApp → AuthWrapper
```

### Authentication States
```
AuthWrapper Logic:
├── User NOT authenticated → LoginScreen
├── User authenticated:
│   ├── Check selected subjects in Firestore
│   ├── Has subjects → HomeScreen
│   └── No subjects → SubjectListScreen
```

### Login Process
```
Google Sign-In → Firebase Auth → Create/Update Firestore user document
→ Initialize user subjects subcollection → Navigate to subject selection
```

## 3. Subject Management Flow

### Subject Selection Screen
```
SubjectListScreen:
├── Load subjects from Firestore (online) or show offline message
├── Display subjects with select/tick green icon(for selected) buttons
├── Search functionality for subject codes (search should start from beggining of the subject code)
```

### Adding a Subject
```
User taps "select" → Confirmation dialog → Store in SQLite immediately
├── Online: Store subject data locally also import to → Sync to Firestore user collection
└── Offline: Store locally only
```

### Removing a Subject
```
User taps "Remove" → Confirmation dialog → Remove from SQLite
├── Online: Remove from Firestore
└── Offline: Remove locally → Sync when online
```

## 4. Study Mode Flow

### Main Navigation
```
Bottom Tabs: Study | Progress | Test | Contribution
├── Study tab → SubjectListScreen (filtered to selected subjects)
├── Progress tab → Progress tracking
├── Test tab → Test management
└── Contribution tab → User contributions
```

### Subject Detail Screen
```
SelectedSubject → SubjectDetailScreen:
├── Load chapters from local SQLite (instant)
├── No local chapters + Online → Fetch from Firestore → Cache locally
├── No local chapters + Offline → Show offline message
├── Chapter selection → Load MCQs for selected chapter
```

### MCQ Loading Strategy
```
Load MCQs for Chapter:
├── Check local SQLite cache → Load instantly if available
├── No cache + Online → Fetch from Firestore → Store in SQLite → Display
├── No cache + Offline → Show "MCQs not available offline" message
└── Cache hit → Display with instant loading
```

### User Interactions in Study Mode
```
MCQ Card Interactions:
├── Answer selection → Local state update
├── Reaction buttons (upvote/downvote/heart):
│   ├── Update local SQLite immediately
│   ├── Online: Sync to Firestore
│   └── Offline: Queue for sync
├── Chapter navigation → Load next chapter's MCQs
```

## 5. Test Creation and Taking Flow

### Test Creation
```
Test Creation Screens:
├── Select subject → Choose chapters → Configure test parameters
├── Generate test with random MCQs from selected chapters
├── Store test configuration in Firestore
```

### Test Taking
```
TestTakingScreen:
├── Load test configuration from Firestore
├── Fetch MCQs for test (prioritize local cache)
├── Present questions sequentially
├── Track user answers locally
├── Submit test → Calculate results → Store in Firestore
```

### Test Results
```
Test completion → TestResultsScreen:
├── Display score and statistics
├── Show correct/incorrect answers
├── Update user progress in Firestore
```

## 6. Offline/Online Data Fetching Strategies

### Connectivity Detection
```
ConnectivityService:
├── Real-time network monitoring
├── Check connectivity before network operations
├── Handle offline scenarios gracefully
```

### Data Fetching Priority
```
All Data Operations:
1. Check local SQLite cache first (instant access)
2. If cache empty + Online → Fetch from Firestore → Cache locally
3. If cache empty + Offline → Show appropriate offline message
4. Background sync for pending operations when connection restored
```

### Specific Data Fetching Rules

#### Subjects
- **Online**: `SubjectFirestoreService.fetchMySubjects()` → Cache in SQLite
- **Offline**: Load from SQLite `selected_subjects` table
- **Sync**: User selections synced to Firestore `/users/{userId}/selectedSubjects/`

#### Chapters
- **Online**: `ChapterService.fetchChapterData()` → Cache in `selected_chapters` table
- **Offline**: Load from `selected_chapters` table
- **Source**: Firestore `/mySubjects/{subjectCode}/chapters/`

#### MCQs
- **Online**: `McqFirestoreService.fetchMcqsForChapter()` → Cache in dynamic `mcqs_{subjectCode}` tables
- **Offline**: Load from `mcqs_{subjectCode}` table
- **Source**: Firestore `/mySubjects/{subjectCode}/chapters/{documentId}/mcqs`

#### User Tests
- **Online**: Store/retrieve from Firestore `/users/{userId}/userTests/`
- **Offline**: Limited functionality, show offline message for test operations

### Reaction Updates
```
Reaction Update Flow:
├── User taps reaction button
├── Update local SQLite immediately (optimistic UI)
├── Online: Sync to Firestore MCQ document
├── Offline: Queue for sync, show pending indicator
```

## 7. User Experience Considerations

### Loading States
- **Instant Loading**: Cached data loads immediately
- **Progressive Loading**: Show cached data first, then fresh data
- **Offline Indicators**: Clear messaging when features unavailable

### Error Handling
- **Network Errors**: Graceful degradation with retry options
- **Data Sync Errors**: Background retry mechanisms
- **Offline Limitations**: Clear feature restrictions communicated

### Performance Optimizations
- **Lazy Loading**: Load data on-demand
- **Caching Strategy**: SQLite for offline, Firestore for sync
- **Background Sync**: Non-blocking data synchronization

## 8. Data Synchronization

### Sync Triggers
- **On App Launch**: Check for pending sync operations
- **On Network Restore**: Sync queued operations
- **On User Actions**: Immediate sync for critical operations

### Conflict Resolution
- **Last Write Wins**: Firestore timestamps determine latest version
- **Local Priority**: User interactions take precedence
- **Merge Strategy**: Combine local and remote data appropriately

## 9. State Management

### Provider Structure
```
AuthProvider: Authentication state
UserTestProvider: Test-related state
Local Services: SQLite operations
Firestore Services: Online operations
```

### State Persistence
- **Authentication**: Firebase Auth persistence
- **User Data**: SQLite + Firestore sync
- **App State**: Provider state with local persistence

## 10. Key User Journeys

### New User Journey
```
1. Install app → Launch
2. Google Sign-In → Account creation
3. Subject selection → Add subjects
4. Chapter exploration → MCQ study
5. Test creation → Assessment
```

### Returning User Journey
```
1. Launch app → Auto-login
2. Load cached subjects → Continue study
3. Sync any pending changes
4. Offline-capable study session
```

### Offline User Journey
```
1. Launch app → Load cached data
2. Study with cached MCQs
3. Take cached tests
4. Reactions queued for sync
5. Sync on network restore
```

This flow ensures a seamless experience whether users are online or offline, with data availability prioritized for learning continuity.