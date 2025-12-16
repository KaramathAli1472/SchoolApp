import { initializeApp, getApps, getApp } from 'firebase/app'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
  apiKey: 'AIzaSyBDxlND__vmvfnbCKy_g01acAtpIFE3WJA',
  authDomain: 'schoolapp-b79f4.firebaseapp.com',
  projectId: 'schoolapp-b79f4',
  storageBucket: 'schoolapp-b79f4.firebasestorage.app',
  messagingSenderId: '702969521148',
  appId: '1:702969521148:web:90adbdb20d1e3b32e30879'
}

const app = getApps().length ? getApp() : initializeApp(firebaseConfig)

export const db = getFirestore(app)

