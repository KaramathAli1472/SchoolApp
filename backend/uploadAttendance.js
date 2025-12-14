async fetchStudents() {
  try {
    // Firestore me class field ka naam check karein: 'class' ya 'classId'
    const q = query(collection(db, "students"), where("class", "==", this.selectedClass))
    const snap = await getDocs(q)
    this.students = snap.docs.map(d => ({ id: d.id, ...d.data() }))

    // Initialize attendance
    this.students.forEach(s => {
      this.attendance[s.id] = this.attendance[s.id] || "Present"
    })

    if(this.students.length === 0){
      console.warn("No students found for this class:", this.selectedClass)
    }

  } catch (err) {
    console.error("Error fetching students:", err)
  }
}

