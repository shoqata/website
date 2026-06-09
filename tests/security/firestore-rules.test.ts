import { assertFails, assertSucceeds, initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve } from 'path';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  // Initialize the test environment with the local firestore.rules file
  testEnv = await initializeTestEnvironment({
    projectId: 'unityhub-test',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe('Firestore Security Rules', () => {
  it('should deny unauthenticated users from reading user profiles', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    const docRef = unauthedDb.collection('users').doc('some-user-id');
    await assertFails(docRef.get());
  });

  it('should allow authenticated users to read their own profile', async () => {
    const authedDb = testEnv.authenticatedContext('alice').firestore();
    const docRef = authedDb.collection('users').doc('alice');
    // Note: In a real test, you'd need to mock the data or ensure the rule matches exactly
    // This is a basic structure for testing the rules.
    await assertSucceeds(docRef.get());
  });

  it('should deny users from escalating their own privileges', async () => {
    const authedDb = testEnv.authenticatedContext('bob').firestore();
    const docRef = authedDb.collection('users').doc('bob');
    
    // Attempt to update role to ADMIN
    await assertFails(docRef.update({ role: 'ADMIN' }));
  });
});
