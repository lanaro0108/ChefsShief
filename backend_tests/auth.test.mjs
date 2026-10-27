import { test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, createUserWithEmailAndPassword,
  signOut, signInWithEmailAndPassword, updateProfile, sendPasswordResetEmail } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator, doc, setDoc, getDoc, serverTimestamp,
  onSnapshot, updateDoc, deleteDoc, terminate } from 'firebase/firestore';

test('real emulator Auth: registration, profile, logout, login, reset and private Firestore CRUD', async () => {
  const app = initializeApp({ apiKey: 'demo-key', projectId: 'demo-chefs-shelf', appId: 'demo-app' }, `auth-${Date.now()}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const db = getFirestore(app); connectFirestoreEmulator(db, '127.0.0.1', 8080);
  const email = `chef-${Date.now()}@example.com`;
  try {
    const { user } = await createUserWithEmailAndPassword(auth, email, 'SenhaSegura123!');
    await updateProfile(user, { displayName: 'Chef de Teste' });
    assert.equal(auth.currentUser.displayName, 'Chef de Teste');
    const ref = doc(db, `users/${user.uid}/recipes/meal_1`);
    await setDoc(ref, { title: 'Receita do teste', ingredients: ['1 tomate'], instructions: ['Corte e sirva.'],
      imageUrl: '', category: 'Salad', area: 'Brazilian', notes: '', sourceId: '1',
      savedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    assert.equal((await getDoc(ref)).data().ingredients[0], '1 tomate');
    const realtime = new Promise((resolve, reject) => {
      const timer = setTimeout(() => { stop(); reject(new Error('Realtime update timed out')); }, 10000);
      const stop = onSnapshot(ref, snapshot => {
        if (snapshot.data()?.notes === 'Com azeite') { clearTimeout(timer); stop(); resolve(); }
      }, error => { clearTimeout(timer); reject(error); });
    });
    await updateDoc(ref, { notes: 'Com azeite', updatedAt: serverTimestamp() });
    await realtime;
    await signOut(auth); assert.equal(auth.currentUser, null);
    await assert.rejects(signInWithEmailAndPassword(auth, email, 'SenhaErrada123!'));
    await signInWithEmailAndPassword(auth, email, 'SenhaSegura123!');
    assert.equal(auth.currentUser.uid, user.uid);
    await sendPasswordResetEmail(auth, email);
    await deleteDoc(ref); assert.equal((await getDoc(ref)).exists(), false);
  } finally { await signOut(auth); await terminate(db); await deleteApp(app); }
});
