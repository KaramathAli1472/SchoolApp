<template>
  <div class="attendance-container" v-if="user">
    <h2>Attendance Records</h2>

    <div class="controls">
      <label>Select Class:</label>
      <select v-model="selectedClass" @change="fetchAttendance">
        <option value="">All Classes</option>
        <option v-for="cls in classes" :key="cls.id" :value="cls.id">{{ cls.label }}</option>
      </select>

      <label>Select Date:</label>
      <input type="date" v-model="selectedDate" @change="applyDate" />

      <span class="today-text">Applied Date: {{ activeDate || 'Not selected' }}</span>
      <input v-model="searchText" type="text" placeholder="Search by name or class..." />
    </div>

    <table v-if="filteredAttendance.length">
      <thead>
        <tr>
          <th>Date</th>
          <th>Photo</th>
          <th>ID Number</th>
          <th>Student Name</th>
          <th>Class</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="record in filteredAttendance" :key="record.date + record.id">
          <td>{{ record.date }}</td>
          <td>
            <img v-if="record.photoUrl" :src="record.photoUrl" class="student-photo" />
            <span v-else>-</span>
          </td>
          <td>{{ record.idNumber || "-" }}</td>
          <td>{{ record.name || "-" }}</td>
          <td>{{ record.classId || "-" }}</td>
          <td>
            <div v-if="isTeacherOrAdmin && record.date === activeDate" class="status-group">
              <label class="status-pill present" :class="{ active: attendance[record.id] === 'Present' }">
                <input type="radio" :name="'status-' + record.id" :checked="attendance[record.id] === 'Present'" @change="setStatus(record.id,'Present')" /> Present
              </label>
              <label class="status-pill absent" :class="{ active: attendance[record.id] === 'Absent' }">
                <input type="radio" :name="'status-' + record.id" :checked="attendance[record.id] === 'Absent'" @change="setStatus(record.id,'Absent')" /> Absent
              </label>
              <label class="status-pill weekoff" :class="{ active: attendance[record.id] === 'Week Off' }">
                <input type="radio" :name="'status-' + record.id" :checked="attendance[record.id] === 'Week Off'" @change="setStatus(record.id,'Week Off')" /> Week Off
              </label>
            </div>
            <span v-else class="status-badge"
                  :class="{
                    present: record.status === 'Present',
                    absent: record.status === 'Absent',
                    weekoff: record.status === 'Week Off'
                  }">{{ record.status || '-' }}</span>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else>No attendance records found.</p>
    <button v-if="isTeacherOrAdmin" @click="saveAttendance">Save Attendance</button>
  </div>

  <div v-else>
    <p>Loading or not logged in...</p>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import { collection, doc, getDocs, getDoc, query, where, setDoc } from "firebase/firestore"

export default {
  data() {
    return {
      classes: Array.from({ length: 10 }, (_, i) => ({ id: `class_${i + 1}`, label: `Class ${i + 1}` })),
      selectedClass: "",
      selectedDate: new Date().toISOString().substr(0, 10),
      activeDate: "",
      searchText: "",
      students: [],
      attendance: {},
      allAttendanceRecords: [],
      user: JSON.parse(localStorage.getItem("user")) || {}
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return this.user.role === "teacher" || this.user.role === "admin"
    },
    filteredAttendance() {
      const text = this.searchText.trim().toLowerCase()
      if (!text) return this.allAttendanceRecords
      return this.allAttendanceRecords.filter(r =>
        (r.name || "").toLowerCase().includes(text) || (r.classId || "").toLowerCase().includes(text)
      )
    }
  },
  async mounted() {
    if (!this.user || !this.isTeacherOrAdmin) {
      alert("You are not authorized to mark attendance")
      this.$router.push("/login")
      return
    }
    this.activeDate = this.selectedDate
    await this.fetchAttendance()
  },
  methods: {
    applyDate() {
      if (!this.selectedDate) { alert("Please select a date first"); return }
      this.activeDate = this.selectedDate
      this.prepareAttendance()
    },

    async fetchAttendance() {
      try {
        // Fetch students
        const studentsRef = collection(db, "students")
        const q = this.selectedClass ? query(studentsRef, where("classId", "==", this.selectedClass)) : studentsRef
        const snap = await getDocs(q)
        this.students = snap.docs.map(d => ({ id: d.id, ...d.data() }))

        // Fetch attendance
        const docId = this.selectedClass || "all_classes"
        const classRef = doc(db, "attendance", docId)
        const docSnap = await getDoc(classRef)
        const attendanceData = docSnap.exists() ? docSnap.data() : {}

        // Convert attendanceData to array of records
        const records = []
        for (let date in attendanceData) {
          for (let studentId in attendanceData[date]) {
            records.push({
              date,
              id: studentId,
              name: attendanceData[date][studentId].name,
              idNumber: attendanceData[date][studentId].idNumber,
              classId: attendanceData[date][studentId].classId,
              photoUrl: attendanceData[date][studentId].photoUrl,
              status: attendanceData[date][studentId].status
            })
          }
        }
        this.allAttendanceRecords = records

        this.prepareAttendance()
      } catch (err) {
        console.error("Error fetching attendance:", err)
      }
    },

    prepareAttendance() {
      // Initialize attendance map for selected date
      const selectedRecords = this.allAttendanceRecords.filter(r => r.date === this.activeDate)
      const map = {}
      selectedRecords.forEach(r => { map[r.id] = r.status })
      this.attendance = map
    },

    setStatus(studentId, status) {
      if (!this.isTeacherOrAdmin) return
      this.attendance = { ...this.attendance, [studentId]: status }
      // Update in allAttendanceRecords
      const index = this.allAttendanceRecords.findIndex(r => r.id === studentId && r.date === this.activeDate)
      if (index !== -1) {
        this.allAttendanceRecords[index].status = status
      } else {
        const student = this.students.find(s => s.id === studentId)
        this.allAttendanceRecords.push({
          date: this.activeDate,
          id: studentId,
          name: student.name,
          idNumber: student.idNumber,
          classId: student.classId,
          photoUrl: student.photoUrl,
          status
        })
      }
    },

    async saveAttendance() {
      if (!this.activeDate) { alert("First select date"); return }
      try {
        const docId = this.selectedClass || "all_classes"
        const classRef = doc(db, "attendance", docId)

        // Prepare payload for selected date
        const attendancePayload = {}
        this.students.forEach(s => {
          attendancePayload[s.id] = {
            name: s.name,
            idNumber: s.idNumber,
            classId: s.classId,
            photoUrl: s.photoUrl,
            status: this.attendance[s.id] || "-"
          }
        })

        await setDoc(classRef, { [this.activeDate]: attendancePayload }, { merge: true })
        alert("Attendance saved successfully!")
        await this.fetchAttendance()
      } catch (err) {
        console.error("Error saving attendance:", err)
        alert("Failed to save attendance.")
      }
    }
  }
}
</script>

<style scoped>
.attendance-container { padding: 2rem; background: #f5f5f5; min-height: 100vh; }
.controls { display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 1rem; align-items: center; }
.today-text { font-weight: bold; }
.add-date-btn { padding: 0.4rem 0.8rem; background: #2196f3; color: #fff; border: none; border-radius: 4px; cursor: pointer; }
.add-date-btn:hover { background: #1976d2; }
table { width: 100%; border-collapse: collapse; background: white; margin-top: 1rem; }
th, td { border: 1px solid #ccc; padding: 0.8rem; text-align: left; }
th { background: #2196F3; color: white; }
.student-photo { width: 35px; height: 35px; border-radius: 50%; object-fit: cover; }
.status-group { display: flex; gap: 0.4rem; }
.status-pill { display: inline-flex; align-items: center; gap: 0.25rem; padding: 0.15rem 0.6rem; border-radius: 999px; font-size: 0.8rem; font-weight: 600; color: #fff; cursor: pointer; opacity: 0.6; border: 1px solid transparent; }
.status-pill input { margin: 0; }
.status-pill.present { background: #4caf50; }
.status-pill.absent { background: #e53935; }
.status-pill.weekoff { background: #ff9800; }
.status-pill.active { opacity: 1; border-color: #00000044; }
.status-badge { padding: 0.2rem 0.6rem; border-radius: 999px; color: #fff; font-size: 0.8rem; }
.status-badge.present { background: #4caf50; }
.status-badge.absent { background: #e53935; }
.status-badge.weekoff { background: #ff9800; }
button { margin-top: 1rem; padding: 0.6rem 1.2rem; background: #4caf50; color: white; border: none; border-radius: 5px; cursor: pointer; }
button:hover { background: #45a049; }
</style>

