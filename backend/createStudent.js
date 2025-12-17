// createStudent.js
const { admin, db } = require('./firebaseAdmin');

// Yahan woh UID daalo jo Firebase Auth console me dikh raha hai
const STUDENT_UID = 'XIXtbPP5Usd0FjmTWHQ6ETWo46p1';

async function createStudentDoc() {
  try {
    const studentRef = db.collection('students').doc(STUDENT_UID);

    await studentRef.set(
      {
        name: 'Student One',
        classId: 'class_1',
        rollNo: 1,
        parentPhone: '925000150',
        dob: '2010-01-01',
        admissionDate: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true } // agar pehle se kuch fields hain to unko overwrite na kare
    );

    console.log('✅ Student document created/updated for UID:', STUDENT_UID);
  } catch (err) {
    console.error('❌ Error creating student document:', err.message);
  }
}

createStudentDoc();

