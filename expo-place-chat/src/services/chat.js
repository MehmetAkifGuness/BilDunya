import {
  addDoc,
  collection,
  doc,
  getDoc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { db, auth } from '../firebase/firebase-config';

/**
 * İki Firebase Auth uid için deterministik chatId: küçük_uid + '_' + büyük_uid (lex sıra).
 * Örnek: ahmetUid vedatUid → alfabetik sıraya göre `ahmetUid_vedatUid` veya tersi.
 * @param {string} uidA
 * @param {string} uidB
 * @returns {string}
 */
export function buildChatId(uidA, uidB) {
  const [first, second] = [uidA, uidB].sort((a, b) => a.localeCompare(b));
  return `${first}_${second}`;
}

/**
 * @returns {{ uid: string }}
 */
export function requireCurrentUser() {
  const user = auth.currentUser;
  if (!user?.uid) {
    throw new Error('Oturum açmanız gerekiyor.');
  }
  return { uid: user.uid };
}

/**
 * Sohbet dokümanını oluşturur veya mevcutsa place bilgisini günceller.
 *
 * Firestore şeması:
 * chats/{chatId}: participants, placeId, placeName, createdAt, updatedAt, lastMessage
 *
 * İlk `orderBy('createdAt')` sorgusunda Firebase konsoldan bileşik indeks isteyebilir.
 *
 * @param {{ peerId: string, placeId: string, placeName: string }} params
 * @returns {Promise<string>} chatId
 */
export async function ensurePrivateChat({ peerId, placeId, placeName }) {
  const { uid: myUid } = requireCurrentUser();
  if (!peerId) {
    throw new Error('Karşı kullanıcı bulunamadı.');
  }
  if (myUid === peerId) {
    throw new Error('Kendinize mesaj gönderemezsiniz.');
  }

  const chatId = buildChatId(myUid, peerId);
  const chatRef = doc(db, 'chats', chatId);
  const snap = await getDoc(chatRef);

  const participants = [myUid, peerId].sort((a, b) => a.localeCompare(b));
  const base = {
    participants,
    placeId: placeId ?? '',
    placeName: placeName ?? '',
    updatedAt: serverTimestamp(),
  };

  if (!snap.exists()) {
    await setDoc(chatRef, {
      ...base,
      createdAt: serverTimestamp(),
      lastMessage: '',
    });
  } else {
    await updateDoc(chatRef, {
      ...base,
    });
  }

  return chatId;
}

/**
 * Realtime mesaj listesi (createdAt artan sırada).
 * @param {string} chatId
 * @param {(messages: Array<{ id: string } & Record<string, unknown>>) => void} onUpdate
 * @param {(error: Error) => void} onError
 * @returns {() => void} unsubscribe
 */
export function subscribeToMessages(chatId, onUpdate, onError) {
  const messagesRef = collection(db, 'chats', chatId, 'messages');
  const q = query(messagesRef, orderBy('createdAt', 'asc'));

  return onSnapshot(
    q,
    (snapshot) => {
      const list = snapshot.docs.map((d) => ({
        id: d.id,
        ...d.data(),
      }));
      onUpdate(list);
    },
    (err) => {
      onError(err instanceof Error ? err : new Error(String(err)));
    },
  );
}

/**
 * chats/{chatId}/messages/{messageId}: text, senderId, receiverId, createdAt
 * @param {{ chatId: string, text: string, receiverId: string }} params
 */
export async function sendChatMessage({ chatId, text, receiverId }) {
  const { uid: senderId } = requireCurrentUser();
  const trimmed = (text ?? '').trim();
  if (!trimmed) {
    throw new Error('Boş mesaj gönderilemez.');
  }

  const messagesCol = collection(db, 'chats', chatId, 'messages');
  await addDoc(messagesCol, {
    text: trimmed,
    senderId,
    receiverId,
    createdAt: serverTimestamp(),
  });

  const chatRef = doc(db, 'chats', chatId);
  await updateDoc(chatRef, {
    lastMessage: trimmed,
    updatedAt: serverTimestamp(),
  });
}
