import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, collection, setDoc, getDoc, getDocs, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';

let env;
const projectId = 'demo-chefs-shelf';
const recipe = (overrides = {}) => ({
  title: 'Pasta da casa', ingredients: ['200 g pasta', '1 tomate'],
  instructions: ['Ferva a água.', 'Cozinhe e sirva.'], notes: '',
  category: 'Pasta', area: 'Italian', imageUrl: '', sourceId: '52771',
  savedAt: serverTimestamp(), updatedAt: serverTimestamp(), ...overrides,
});
const path = 'users/alice/recipes/meal_52771';
before(async () => {
  env = await initializeTestEnvironment({ projectId, firestore: {
    host: '127.0.0.1', port: 8080, rules: await readFile('firestore.rules', 'utf8'),
  }});
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

test('owner creates, reads, lists, updates arrays and deletes a recipe', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, path);
  await assertSucceeds(setDoc(ref, recipe()));
  const before = (await assertSucceeds(getDoc(ref))).data();
  assert.deepEqual(before.ingredients, ['200 g pasta', '1 tomate']);
  assert.deepEqual(before.instructions, ['Ferva a água.', 'Cozinhe e sirva.']);
  assert.equal((await assertSucceeds(getDocs(collection(db, 'users/alice/recipes')))).size, 1);
  await assertSucceeds(updateDoc(ref, { title: 'Minha pasta', notes: 'Mais manjericão',
    ingredients: ['200 g pasta', 'Manjericão'], updatedAt: serverTimestamp() }));
  const updated = (await getDoc(ref)).data();
  assert.equal(updated.title, 'Minha pasta');
  assert.ok(updated.savedAt.isEqual(before.savedAt));
  await assertSucceeds(deleteDoc(ref));
  assert.equal((await getDoc(ref)).exists(), false);
});

test('anonymous clients cannot read, list, create or delete', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, path)));
  await assertFails(getDocs(collection(db, 'users/alice/recipes')));
  await assertFails(setDoc(doc(db, path), recipe()));
  await assertFails(deleteDoc(doc(db, path)));
});

test('a second user cannot read, list, edit, create or delete another notebook', async () => {
  await setDoc(doc(env.authenticatedContext('alice').firestore(), path), recipe());
  const bob = env.authenticatedContext('bob').firestore();
  await assertFails(getDoc(doc(bob, path)));
  await assertFails(getDocs(collection(bob, 'users/alice/recipes')));
  await assertFails(updateDoc(doc(bob, path), { notes: 'intrusão', updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(bob, 'users/alice/recipes/meal_99'), recipe({ sourceId: '99' })));
  await assertFails(deleteDoc(doc(bob, path)));
  await assertSucceeds(setDoc(doc(bob, 'users/bob/recipes/meal_52771'), recipe()));
});

test('invalid schema, excessive lengths and additional fields are denied', async () => {
  const ref = doc(env.authenticatedContext('alice').firestore(), path);
  for (const invalid of [
    { title: '' }, { title: 'x'.repeat(121) }, { title: 1 }, { ingredients: [] },
    { ingredients: 'not an array' }, { ingredients: [42] },
    { ingredients: ['ok', { malicious: true }] }, { ingredients: ['x'.repeat(301)] },
    { ingredients: Array(41).fill('x') }, { instructions: [] },
    { instructions: ['ok', 42] }, { instructions: ['x'.repeat(5001)] },
    { notes: 'x'.repeat(2001) }, { admin: true },
    { sourceId: 'other-id' }, { sourceId: '99' }, { category: 42 },
    { imageUrl: 'http://unsafe.example/image.jpg' },
    { imageUrl: 'https://tracking.example/image.jpg' },
    { savedAt: Timestamp.fromMillis(0) }, { updatedAt: Timestamp.fromMillis(0) },
  ]) await assertFails(setDoc(ref, recipe(invalid)));
  const missing = recipe(); delete missing.instructions;
  await assertFails(setDoc(ref, missing));
});

test('all 40 array positions are validated, including the final element', async () => {
  const ref = doc(env.authenticatedContext('alice').firestore(), path);
  await assertSucceeds(setDoc(ref, recipe({ ingredients: Array(40).fill('sal'), instructions: Array(40).fill('Misture.') })));
  const ingredients = Array(40).fill('sal'); ingredients[39] = 99;
  await assertFails(updateDoc(ref, { ingredients, updatedAt: serverTimestamp() }));
  const instructions = Array(40).fill('Misture.'); instructions[39] = { step: 'bad' };
  await assertFails(updateDoc(ref, { instructions, updatedAt: serverTimestamp() }));
});

test('creation time and API provenance cannot be changed during updates', async () => {
  const ref = doc(env.authenticatedContext('alice').firestore(), path);
  await setDoc(ref, recipe());
  for (const invalid of [{ savedAt: Timestamp.fromMillis(0) }, { sourceId: '42' },
    { imageUrl: 'https://www.themealdb.com/images/media/meals/other.jpg' },
    { category: 'Dessert' }, { area: 'Brazilian' }]) {
    await assertFails(updateDoc(ref, { ...invalid, updatedAt: serverTimestamp() }));
  }
});

test('length boundaries, Unicode and multiline steps are preserved without separator injection', async () => {
  const ref = doc(env.authenticatedContext('alice').firestore(), path);
  await assertSucceeds(setDoc(ref, recipe({
    ingredients: Array(40).fill('a'.repeat(300)),
    instructions: Array(40).fill('p'.repeat(5000)),
  })));
  await assertSucceeds(updateDoc(ref, { notes: 'No limite permitido', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { ingredients: ['½ xícara de açúcar'],
    instructions: ['Misture.\nEspere esfriar.'], updatedAt: serverTimestamp() }));
  for (const invalid of [{ ingredients: ['a\u001fb'] },
    { instructions: ['a\u001fb'] }, { ingredients: [true] },
    { ingredients: [null] }, { ingredients: [''] },
    { instructions: [''] }, { instructions: [3.14] }]) {
    await assertFails(updateDoc(ref, { ...invalid, updatedAt: serverTimestamp() }));
  }
});

test('unmodeled collections and parent user documents deny all access', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice'), { admin: true }));
  await assertFails(setDoc(doc(db, 'public/recipe'), recipe()));
  await assertFails(getDoc(doc(db, 'users/alice')));
});
