# VU MCQs App Screen Flow Documentation

## AuthWrapper Screen
    User Actions
        - App launch automatically checks authentication
        - If not authenticated, automatically navigates to login
        - If authenticated, checks for selected subjects from local database
    database:
        - Checks local SQLite for selected subjects (active and inactive)
        - No network calls on initial load
    Screens
        - If not authenticated: LoginScreen
        - If authenticated and has subjects: MainScreen
        - If authenticated and no subjects: SubjectListScreen

## Login Screen
    User Actions
        - User clicks on "Sign in with Google" button
    database:
        - User data saved to Firestore users/{userid}
        - No cache or local storage for user auth data (handled by Firebase Auth)
    Screens
        - After successful sign in: Returns to AuthWrapper which navigates based on subject status
        - If user has subjects: MainScreen
        - If user has no subjects: SubjectListScreen

## SubjectList Screen (All Subjects)
    User Actions
        - User searches subjects by code (starts with search)
        - User taps "select" on subject to add it
        - User taps "Remove" on already selected subject
        - User taps "Start Study" button (appears when subjects selected)
        - User taps menu -> Profile
        - User taps menu -> Add More Subjects (from other screens)
    database:
        - Add subject: Store in local SQLite immediately, sync to Firestore users/{userId}/selectedSubjects if online
        - Remove subject: Remove from local SQLite, remove from Firestore if online
        - Load subjects: Fetch from Firestore if online, show offline message if not
        - Search: Local filtering of loaded subjects
    Screens
        - After adding subjects and tapping "Start Study": MainScreen (Study tab)
        - Menu -> Profile: UserProfileScreen
        - Menu -> Add More Subjects: SubjectListScreen (same screen)

## Main Screen
    User Actions
        - User taps bottom navigation tabs
    database:
        - No database operations (just navigation container)
    Screens
        - Study tab: HomeScreen
        - Progress tab: ProgressScreen (placeholder)
        - Test tab: TestScreen (placeholder)
        - Contribution tab: Center widget with text (placeholder)

## Home Screen (Selected Subjects)
    User Actions
        - User taps on subject card to study
        - User taps status toggle on subject (active/inactive)
        - User taps menu -> Profile
        - User taps menu -> Dark Theme (shows snackbar)
        - User taps menu -> Add More Subjects
        - If no subjects: User taps "Browse Subjects" button
    database:
        - Load subjects: From local SQLite (selected_subjects and inactive_subjects tables)
        - Toggle status: Update local SQLite subject status
    Screens
        - Tap subject: SubjectDetailScreen
        - Menu -> Profile: UserProfileScreen
        - Menu -> Add More Subjects: SubjectListScreen
        - No subjects -> Browse Subjects: SubjectListScreen

## SubjectDetail Screen
    User Actions
        - User taps chapter selection FAB to open chapter list
        - User selects chapter from bottom sheet
        - User switches between MCQs and Short Questions tabs
        - User answers MCQ by selecting option
        - User taps reaction buttons (upvote/downvote/heart) on MCQ
        - User scrolls through MCQs (with draggable slider)
        - User taps "Next Chapter" button at end of MCQs
        - User taps menu -> Dark Theme toggle
        - User taps menu -> Font Size (+/- buttons)
        - User taps "Database" button
    database:
        - Load chapters: First check local SQLite, if empty fetch from Firestore and cache locally
        - Load MCQs/Shorts: First check local SQLite cache, if empty fetch from Firestore and cache locally
        - Answer MCQ: Update local SQLite with user answer
        - Reaction buttons: Update local SQLite immediately, sync to Firestore if online
        - Font size: Local state only
    Screens
        - Chapter selection: Bottom sheet with chapter list (stays on same screen)
        - Database button: DatabaseScreen
        - Next chapter: Loads next chapter data (stays on same screen)

## UserProfile Screen
    User Actions
        - User views profile info (name, email, verification status)
        - User taps on subject to study it
        - User taps remove button on subject
        - User taps "Add Subjects" button
        - User taps "Go to Study" button
        - User taps "Logout" button
    database:
        - Load subjects: From local SQLite
        - Remove subject: Delete from local SQLite
        - Logout: Firebase Auth sign out
    Screens
        - Tap subject: SubjectDetailScreen
        - Add Subjects: SubjectListScreen
        - Go to Study: MainScreen (Study tab)
        - Logout: Pops all routes to root (AuthWrapper will show LoginScreen)

## Database Screen
    User Actions
        - User selects table from dropdown
        - User views table data in scrollable table
    database:
        - Load tables: Query sqlite_master for table names
        - Load table data: Query selected table
        - Load columns: Use PRAGMA table_info for empty tables
    Screens
        - No navigation (view-only screen)

## Test Screen
    User Actions
        - None (placeholder screen)
    database:
        - None
    Screens
        - None

## Progress Screen
    User Actions
        - None (placeholder screen)
    database:
        - None
    Screens
        - None