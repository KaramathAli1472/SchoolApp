// src/services/firebase.js
import { initializeApp } from "firebase/app"
import { getFirestore } from "firebase/firestore"
import { getAuth } from "firebase/auth"
import { getStorage } from "firebase/storage"

const firebaseConfig = {
  apiKey: "AIzaSyBDxlND__vmvfnbCKy_g01acAtpIFE3WJA",
  authDomain: "schoolapp-b79f4.firebaseapp.com",
  projectId: "schoolapp-b79f4",
  storageBucket: "schoolapp-b79f4.firebasestorage.app",
  messagingSenderId: "702969521148",
  appId: "1:702969521148:web:853093292d61b6f8e30879"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig)
const db = getFirestore(app)
const auth = getAuth(app)
const storage = getStorage(app)   // ← Make sure this is here

export { db, auth, storage }      // ← Export storage

