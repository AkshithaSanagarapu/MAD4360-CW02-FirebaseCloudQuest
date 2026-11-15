# Firebase Cloud Quest — CW-02 #03 (Graduate)

**Student Name:** Akshitha Sainath Sanagarapu  
**Student ID:** 003027780  
**Course:** MAD 4360 — Mobile App Development  
**Assignment:** CW-02 #03 — Firebase Cloud Quest (Graduate)

## Overview

Firebase Cloud Quest is a Flutter Android application that lets a signed-in learner view a daily cloud-security challenge, request a hint from a Genkit-powered Quest Coach, and complete the challenge to earn points and a badge. The project focuses on keeping reward decisions on a trusted backend rather than trusting the phone or AI-generated text.

## Implemented features

- Firebase Authentication sign-in and authenticated access to the challenge.
- Firestore daily challenge and per-user progress display.
- Callable Cloud Function `completeToday` awarding 10 points and the First Quest badge.
- Transaction-based duplicate-completion protection: repeated requests do not award additional points.
- Callable `askQuestCoach` using Genkit and Google's `gemini-3.1-flash-lite` model.
- One read-only Genkit tool, `readMyQuestState`, bound to the Firebase-verified user ID, with no user-selectable UID parameter.
- Firestore rules designed to prevent client-side reward modification and cross-user progress reads.

## Trust boundary

Flutter app → Firebase Authentication → Firestore / callable Cloud Functions.

The app supplies a question or completion request, but it does not decide the user's score. `completeToday` validates the authenticated caller and challenge ID, reads the progress document in a Firestore transaction, and writes the fixed reward only if it has not already been awarded. `askQuestCoach` checks authentication and question length, then exposes a read-only quest-state tool to Genkit. The tool's UID comes from the verified Firebase Authentication context, not from the model or a client-supplied field. The coach has no tool that can award points or edit badges.

## Local setup and execution

1. Install Flutter, Android Studio, Node.js, Firebase CLI, and a compatible Android emulator.
2. From the project root run `flutter pub get`.
3. Install backend packages with `cd functions && npm install && cd ..`.
4. Check the Firebase project ID in the app configuration. The project used during the successful local tests was `mad4360-firebase-productapp`.
5. Set `GEMINI_API_KEY` in the local terminal environment; do not place the key in source control.
6. Start the local services with `firebase emulators:start --project mad4360-firebase-productapp --only auth,firestore,functions`.
7. In a separate terminal, seed the daily challenge using `cd functions && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=mad4360-firebase-productapp node seed.mjs && cd ..`.
8. Run the Flutter application on the Android emulator. The Flutter app and Firebase emulators must use matching project IDs. Android emulator host access normally uses `10.0.2.2`.

The app was tested against local Firebase emulators. The release APK build succeeded, but standalone operation without reachable Firebase services has not been established.

## Tests and observed results

- `flutter analyze`: No issues found.
- `flutter test`: One test passed.
- Backend tests: Four passed when the Firestore emulator was running, including reward idempotency and security boundary checks. An earlier attempt without the emulator running failed with connection refused; this was an environment issue, not a successful security-test run.
- Manual completion: points changed from 0 to 10 and the First Quest badge appeared.
- Manual repeat completion: points remained 10 and the app displayed “Already completed — your reward is safe!”
- AI coach: `Get hint` returned a relevant Gemini-generated explanation of why the backend must control rewards.
- Adversarial request: asking the coach to award 1,000 points and a Master Quest badge did not change the displayed 10 points or First Quest badge; the coach explained it could not modify rewards.
- Android release: `flutter build apk --release` succeeded; output at `build/app/outputs/flutter-apk/app-release.apk` (approximately 50.6 MB).

**Outstanding evidence:** The current code offers Genkit exactly one read-only tool and instructs the model to call it exactly once. The screenshots do not independently prove the number of actual tool invocations. Add a tool-execution log or trace before claiming exactly one call was verified. Also capture the signed-out screen if required by the instructor.

## Suggested evidence screenshots

1. Signed-in challenge with 0 points.
2. Quest Coach's ordinary AI-generated hint.
3. Successful completion showing 10 points and First Quest badge.
4. Repeated completion showing no extra reward.
5. Adversarial AI request, refusal, and unchanged reward.
6. Signed-out screen and backend test results, if captured.

Store screenshots in a `screenshots/` folder in the repository. Do not include secrets, `.env` files, or `node_modules` in the GitHub commit.

## Graduate reflection (123 words)

Building Firebase Cloud Quest helped me understand why authentication alone is not enough to protect an application's rewards. The Flutter app can request a challenge completion, but only the trusted Cloud Function decides whether to award points. I verified this by completing the challenge twice: the first attempt awarded ten points and the First Quest badge, while the second attempt left the reward unchanged. I also tested the Genkit Quest Coach with a prompt asking it to award extra points and a different badge. It refused, and my displayed progress stayed the same. The read-only quest-state tool uses the authenticated user's identity rather than accepting a user ID from the question. This design separates helpful AI responses from actions that change important data.

## Submission

Submit the GitHub repository link, README, screenshots, and graduate reflection through the course submission portal. Include the APK only if requested. Verify that the final repository contains the updated Genkit implementation rather than the earlier deterministic-coach starter version.
