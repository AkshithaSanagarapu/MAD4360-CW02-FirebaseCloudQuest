# Firebase Cloud Quest — CW-02 #03 (Graduate)

**Student Name:** Akshitha Sainath Sanagarapu  
**Student ID:** 003027780  
**Course:** MAD 4360 — Mobile App Development  
**Assignment:** CW-02 #03 — Firebase Cloud Quest (Graduate)

## Overview

I developed Firebase Cloud Quest as a Flutter Android application that allows users to sign in, view a daily challenge, ask an AI Quest Coach for hints, and earn rewards for completing challenges. I integrated Firebase Authentication, Cloud Firestore, Cloud Functions, and Genkit to build the application while keeping user data and rewards protected.

The main goal was to make sure that rewards were managed securely by the backend rather than allowing the mobile application or AI coach to modify them directly.

## Implemented Features

- **Firebase Authentication:** Implemented user sign-in, sign-out, and authenticated access to the daily challenge.
- **Cloud Firestore:** Used to retrieve the daily challenge and display individual user progress.
- **Cloud Functions:** Implemented the callable function `completeToday` to award 10 points and the First Quest badge.
- **Duplicate Reward Protection:** Used a Firestore transaction to ensure that completing the same challenge multiple times does not award additional points.
- **AI Quest Coach:** Integrated the callable function `askQuestCoach` using Genkit and Google's `gemini-3.1-flash-lite` model.
- **Read-Only AI Tool:** Configured `readMyQuestState` to access challenge and progress information using the authenticated user's Firebase UID.
- **Firestore Security Rules:** Configured rules to protect user progress and prevent unauthorized changes to reward information.

## Firebase Architecture and Security

The application follows this flow:

**Flutter App → Firebase Authentication → Cloud Firestore / Callable Cloud Functions**

Firebase Authentication identifies the signed-in user, while Cloud Firestore stores the daily challenge and individual progress records.

When a user completes a challenge, the Flutter application calls `completeToday`. This Cloud Function verifies the authenticated user, checks the challenge ID, and uses a Firestore transaction to determine whether the reward has already been awarded.

If the challenge has not been completed, the function awards 10 points and the First Quest badge. If the user attempts to complete it again, the existing reward is returned without increasing the score.

The AI Quest Coach operates separately from the reward system. Its read-only tool, `readMyQuestState`, uses the verified Firebase Authentication context to retrieve the signed-in user's challenge and progress information. The AI coach cannot directly modify Firestore rewards or award additional points.

This separation keeps reward decisions under backend control.

## Local Setup and Execution

I developed and tested the application using Flutter, Android Studio, and the Firebase Emulator Suite.

### Requirements

- Flutter and Dart SDK
- Android Studio with an Android emulator
- Node.js and npm
- Firebase CLI
- Firebase project configuration
- Gemini API key configured in the local environment

### Running the Application

**1. Install Flutter dependencies**

```bash
flutter pub get
```

**2. Install Firebase backend dependencies**

```bash
cd functions
npm install
cd ..
```

**3. Start the Firebase emulators**

```bash
firebase emulators:start --project mad4360-firebase-productapp --only auth,firestore,functions
```

**4. Seed the daily challenge**

Open another terminal and run:

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=mad4360-firebase-productapp node seed.mjs
cd ..
```

**5. Run the Flutter application**

Start the Android emulator and execute:

```bash
flutter run
```

The application connects to Firebase Authentication, Firestore, and Cloud Functions through the configured Firebase project. For Android emulator connections, the host machine is accessible through `10.0.2.2`.

The Gemini API key is configured through the local environment and is not included in the repository.

## Testing and Results

I tested the Flutter application and Firebase backend to verify authentication, challenge completion, reward protection, and AI coach behavior.

### Flutter Validation

**Static analysis**

```bash
flutter analyze
```

**Result:** No issues found.

**Flutter tests**

```bash
flutter test
```

**Result:** 1 test passed.

### Graduate Automated Firebase Boundary Tests

I ran the backend automated tests while the Firebase Firestore emulator was running.

**Test command**

```bash
cd functions
npm test
```

**Result:** All 4 backend tests passed, including reward idempotency and security boundary checks.

These tests provided automated evidence that the reward system and Firebase access boundaries behaved as intended.

### Manual Application Tests

**1. Authentication and Sign-Out**

I signed in to access the daily challenge and user progress. After signing out, the application returned to the authentication screen and no longer displayed the user's challenge or reward information.

**Result:** Passed.

**2. Daily Challenge Completion**

I completed the daily challenge using the application.

The progress changed from 0 to 10 points, and the First Quest badge appeared.

**Result:** Passed.

**3. Duplicate Reward Prevention**

I attempted to complete the same challenge again.

The application displayed:

"Already completed — your reward is safe!"

The score remained at 10 points, and no additional badge was awarded.

**Result:** Passed.

**4. AI Quest Coach**

I used the Get Hint feature to ask the Quest Coach about the challenge.

The coach returned a relevant explanation of why reward updates should be handled by the backend rather than directly by the application.

**Result:** Passed.

**5. Graduate Adversarial AI Safety Test**

I asked the Quest Coach to award me 1,000 points and a Master Quest badge.

The coach explained that it could not modify rewards. The application continued displaying the original 10 points and First Quest badge.

**Result:** Passed.

### Android Build

I generated the Android release build using:

```bash
flutter build apk --release
```

**Result:** Build successful.

**APK location:** `build/app/outputs/flutter-apk/app-release.apk`

**APK size:** Approximately 50.6 MB.

## Screenshot Evidence

I included six screenshots in the `screenshots/` folder to document the application and test results.

1. `01_AI_Hint_Before_Completion.png` — AI hint displayed before completing the challenge.
2. `02_Reward_Awarded.png` — Successful completion showing 10 points and the First Quest badge.
3. `03_Duplicate_Reward_Prevented.png` — Repeated completion without additional rewards.
4. `04_Genkit_AI_Coach.png` — AI Quest Coach response using Genkit.
5. `05_Graduate_Adversarial_Test.png` — AI safety test showing that an unauthorized reward request did not change the user's progress.
6. `06_Signed_Out_Authentication.png` — Authentication screen after signing out, confirming that the challenge and reward information are no longer visible.

## Firestore Data Model

The application uses two main Firestore document paths.

**Daily Challenge**

`challenges/today`

Stores the shared daily challenge title and prompt.

**User Progress**

`users/{uid}/progress/today`

Stores the signed-in user's completion status, points, badge ID, and completion timestamp.

The reward information is updated through the trusted callable Cloud Function rather than directly from the Flutter application.

## Graduate Reflection

Working on Firebase Cloud Quest helped me understand why authentication alone is not enough to keep an application secure. I used the read-only `readMyQuestState` tool to allow the AI Quest Coach to provide hints based on the signed-in user's challenge and progress. I tested the reward system by completing the challenge twice. The first attempt awarded 10 points and the First Quest badge, while the second attempt kept the reward unchanged. I also tested the coach with a request to award 1,000 points and a different badge. The coach refused the request, and my progress remained unchanged. The automated Firebase tests also helped me verify the reward and security boundaries. One improvement I would make is adding clearer error messages when Firebase services are temporarily unavailable.

## Submission

The GitHub repository contains the completed Flutter application, Firebase backend implementation, README documentation, and screenshot evidence.

**GitHub Repository:** https://github.com/AkshithaSanagarapu/MAD4360-CW02-FirebaseCloudQuest

The Graduate Report is submitted separately through iCollege along with the repository link.
