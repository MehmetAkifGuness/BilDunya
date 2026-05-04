import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'BURAYA_API_KEY',
  authDomain: 'BURAYA_AUTH_DOMAIN',
  projectId: 'BURAYA_PROJECT_ID',
  storageBucket: 'BURAYA_STORAGE_BUCKET',
  messagingSenderId: 'BURAYA_MESSAGING_SENDER_ID',
  appId: 'BURAYA_APP_ID',
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);
export const auth = getAuth(app);
