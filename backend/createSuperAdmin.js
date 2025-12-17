const { admin, db, auth } = require("./firebaseAdmin");

async function createSuperAdmin() {
  try {
    // 🔐 1️⃣ Create Firebase Auth user
    const user = await auth.createUser({
      email: "superadmin@schoolapp.com",
      password: "SuperAdmin@123",
      displayName: "Super Admin"
    });

    // 🧾 2️⃣ Save user in Firestore
    await db.collection("users").doc(user.uid).set({
      uid: user.uid,
      name: "Super Admin",
      email: "superadmin@schoolapp.com",
      role: "superadmin",
      classId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log("✅ Super Admin created successfully");
    console.log("UID:", user.uid);
  } catch (err) {
    console.error("❌ Error creating Super Admin:", err.message);
  }
}

createSuperAdmin();

