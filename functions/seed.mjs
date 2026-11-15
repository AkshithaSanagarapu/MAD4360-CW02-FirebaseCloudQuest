import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
process.env.FIRESTORE_EMULATOR_HOST ||= '127.0.0.1:8080';
initializeApp({projectId: process.env.GCLOUD_PROJECT || 'demo-cloud-quest'});
await getFirestore().doc('challenges/today').set({title: 'Your First Cloud Quest', prompt: 'Sign in, read your challenge, and explain why only the trusted backend can award points.'});
console.log('Seeded challenges/today in Firestore emulator.');
