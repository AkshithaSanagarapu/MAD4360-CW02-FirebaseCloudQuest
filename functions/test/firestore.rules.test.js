import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
const rules = readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8');
test('emulator: signed-in learner can read own progress but cannot write rewards or read another learner', async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-cloud-quest', firestore: {rules, host: '127.0.0.1', port: 8080}});
  try {
    await env.withSecurityRulesDisabled(async context => {
      await context.firestore().doc('users/alice/progress/today').set({points: 10});
    });
    const alice = env.authenticatedContext('alice').firestore();
    await assertSucceeds(alice.doc('users/alice/progress/today').get());
    await assertFails(alice.doc('users/bob/progress/today').get());
    await assertFails(alice.doc('users/alice/progress/today').set({points: 999}));
    assert.ok(true);
  } finally { await env.cleanup(); }
});
