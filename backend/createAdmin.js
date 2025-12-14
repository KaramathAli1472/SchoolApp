const { admin, db, auth } = require("./firebaseAdmin");

async function createAdmin() {
  try {
    // 1️⃣ Create Auth User
    const user = await auth.createUser({
      email: "admin@school.com",
      password: "Admin@123",
      phoneNumber: "+919999999999",
      displayName: "School Admin"
    });

    // 2️⃣ Firestore users collection
    await db.collection("users").doc(user.uid).set({
      name: "School Admin",
      phone: "9999999999",
      role: "admin",
      classId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log("✅ Admin created successfully");
    console.log("UID:", user.uid);
  } catch (err) {
    console.error("❌ Error:", err.message);
  }
}

createAdmin();
