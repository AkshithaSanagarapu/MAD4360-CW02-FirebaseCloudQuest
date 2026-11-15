# Firebase Cloud Quest — CW-02 #03 (Graduate)

**Student Name:** Akshitha Sainath Sanagarapu  
**Student ID:** 003027780  
**Course:** MAD 4360 — Mobile App Development  
**Assignment:** CW-02 #03 — Firebase Cloud Quest (Graduate)

## Overview

I built Firebase Cloud Quest as a Flutter Android app where I can sign in, see a daily challenge, ask the Quest Coach for a hint, and earn a reward for completing the challenge. I wanted the reward to be handled by Firebase rather than by the phone or the AI coach.

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

**One thing I have not verified yet:** I configured Genkit with one read-only tool and instructed the model to call it once, but I have not saved a trace showing the exact number of calls. I would add a tool-execution trace as a next step. I captured the signed-out screen as screenshot 06.

## Screenshot evidence

I saved these screenshots in the `screenshots/` folder:

1. `01_AI_Hint_Before_Completion.png` — the hint before completing the challenge.
2. `02_Reward_Awarded.png` — 10 points and the First Quest badge after completion.
3. `03_Duplicate_Reward_Prevented.png` — a repeat attempt did not add another reward.
4. `04_Genkit_AI_Coach.png` — the coach's response after the Genkit update.
5. `05_Graduate_Adversarial_Test.png` — the coach refused a request for extra points, and the reward did not change.
6. `06_Signed_Out_Authentication.png` — the sign-in screen after signing out, without challenge or reward information.

I did not include `.env` files, `node_modules`, or private Gemini credentials in the repository.

## Graduate reflection (134 words)

Working on Firebase Cloud Quest helped me see why signing in is only one part of keeping an app secure. I used the read-only readMyQuestState tool so the AI coach could give a hint based on the signed-in user's challenge without changing their progress. I tested the reward by completing the challenge twice. The first attempt gave me 10 points and the First Quest badge, but the second attempt did not add anything. I also asked the coach to give me 1,000 points and a different badge. It refused, and my points stayed the same. One limitation is that I have not captured a trace proving the tool was called exactly once for each hint. As a next step, I would add that trace so I could verify the AI tool's behavior more clearly.

## Submission

For iCollege, I will submit my GitHub repository link and the Graduate Report. The repository includes this README, the screenshots, the Flutter source, and the Firebase backend. I will attach an APK only if the instructor requests it.
