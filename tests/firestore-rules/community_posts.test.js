// Firestore rules tests for community_posts (pre-launch review: delete
// permissions and required category). Run from this folder:
//   npm install && npm run test:emulator
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayUnion,
  deleteDoc,
  doc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const OWNER = 'owner-uid';
const OTHER = 'other-uid';
const ADMIN = 'admin-uid';
const MANAGER = 'manager-uid';
const POST = 'post-1';

let env;

const newPost = (uid, extra = {}) => ({
  userId: uid,
  authorName: 'Test Mama',
  title: 'Hello',
  content: 'First post',
  category: 'Questions',
  likes: [],
  replies: [],
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

const db = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-empowerhealth',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const admin = ctx.firestore();
    await setDoc(doc(admin, 'ADMIN', ADMIN), { role: 'admin' });
    await setDoc(doc(admin, 'COMMUNITY_MANAGERS', MANAGER), { role: 'manager' });
    await setDoc(doc(admin, 'community_posts', POST), {
      ...newPost(OWNER),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
});

describe('community_posts create', () => {
  it('allows a post with a category', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'community_posts', 'p2'), newPost(OWNER)));
  });

  it('allows a pregnancy-loss category', async () => {
    await assertSucceeds(setDoc(doc(db(OWNER), 'community_posts', 'p2'),
      newPost(OWNER, { category: 'Grief and emotional support' })));
  });

  it('rejects a post with no category', async () => {
    const { category, ...withoutCategory } = newPost(OWNER);
    await assertFails(setDoc(doc(db(OWNER), 'community_posts', 'p2'), withoutCategory));
  });

  it('rejects an empty category', async () => {
    await assertFails(setDoc(doc(db(OWNER), 'community_posts', 'p2'), newPost(OWNER, { category: '' })));
  });

  it('rejects the "All" filter as a category', async () => {
    await assertFails(setDoc(doc(db(OWNER), 'community_posts', 'p2'), newPost(OWNER, { category: 'All' })));
  });

  it('rejects posting as someone else', async () => {
    await assertFails(setDoc(doc(db(OTHER), 'community_posts', 'p2'), newPost(OWNER)));
  });
});

describe('community_posts delete', () => {
  it('lets the owner delete their post', async () => {
    await assertSucceeds(deleteDoc(doc(db(OWNER), 'community_posts', POST)));
  });

  it('blocks another user from deleting it', async () => {
    await assertFails(deleteDoc(doc(db(OTHER), 'community_posts', POST)));
  });

  it('lets an admin delete it', async () => {
    await assertSucceeds(deleteDoc(doc(db(ADMIN), 'community_posts', POST)));
  });

  it('lets a community manager delete it', async () => {
    await assertSucceeds(deleteDoc(doc(db(MANAGER), 'community_posts', POST)));
  });

  it('blocks signed-out users', async () => {
    await assertFails(deleteDoc(doc(env.unauthenticatedContext().firestore(), 'community_posts', POST)));
  });
});

describe('community_posts update', () => {
  it('lets another user like a post', async () => {
    await assertSucceeds(updateDoc(doc(db(OTHER), 'community_posts', POST), { likes: [OTHER] }));
  });

  it('lets another user reply', async () => {
    await assertSucceeds(updateDoc(doc(db(OTHER), 'community_posts', POST), {
      replies: arrayUnion({ id: 'r1', userId: OTHER, content: 'Hi' }),
      updatedAt: serverTimestamp(),
    }));
  });

  it('blocks another user from editing the content', async () => {
    await assertFails(updateDoc(doc(db(OTHER), 'community_posts', POST), { content: 'hijacked' }));
  });

  it('blocks taking ownership (which would then allow delete)', async () => {
    await assertFails(updateDoc(doc(db(OTHER), 'community_posts', POST), { userId: OTHER }));
  });

  it('lets the owner edit their content', async () => {
    await assertSucceeds(updateDoc(doc(db(OWNER), 'community_posts', POST), { content: 'edited' }));
  });

  it('blocks the owner from reassigning the post', async () => {
    await assertFails(updateDoc(doc(db(OWNER), 'community_posts', POST), { userId: OTHER }));
  });
});
