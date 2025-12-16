<template>
  <div class="attendance-container" v-if="user">
    <h2>Attendance Records</h2>

    <div class="controls">
      <label>Select Class:</label>
      <select v-model="selectedClass" @change="fetchAttendance">
        <option value="">All Classes</option>
        <option v-for="cls in classes" :key="cls.id" :value="cls.id">
          {{ cls.label }}
        </option>
      </select>

      <label>Select Date:</label>
      <input type="date" v-model="selectedDate" @change="applyDate" />

      <span class="today-text">
        Applied Date: {{ activeDate || 'Not selected' }}
      </span>

      <input
        v-model="searchText"
        type="text"
        placeholder="Search by name or class..."
      />

      <div v-if="canEditAttendance" class="add-student-section">
        <label>Add Student:</label>
        <select v-model="studentToAdd">
          <option value="">Select Student</option>
          <option
            v-for="s in availableStudents"
            :key="s.id"
            :value="s.id"
          >
            {{ s.name }} ({{ s.classId }})
          </option>
        </select>
        <button @click="addAttendanceRecord">Add</button>
      </div>
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
          <th v-if="canEditAttendance">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="record in filteredAttendance"
          :key="record.date + record.id"
        >
          <td>{{ record.date }}</td>
          <td>
            <img
              v-if="record.photoUrl"
              :src="record.photoUrl"
              class="student-photo"
            />
            <span v-else>-</span>
          </td>
          <td>{{ record.idNumber || '-' }}</td>
          <td>{{ record.name || '-' }}</td>
          <td>{{ record.classId || '-' }}</td>
          <td>
            <div
              v-if="canEditAttendance && record.date === activeDate"
              class="status-group"
            >
              <label
                class="status-pill present"
                :class="{ active: attendance[record.id] === 'Present' }"
              >
                <input
                  type="radio"
                  :name="'status-' + record.id"
                  :checked="attendance[record.id] === 'Present'"
                  @change="setStatus(record.id, 'Present')"
                />
                Present
              </label>
              <label
                class="status-pill absent"
                :class="{ active: attendance[record.id] === 'Absent' }"
              >
                <input
                  type="radio"
                  :name="'status-' + record.id"
                  :checked="attendance[record.id] === 'Absent'"
                  @change="setStatus(record.id, 'Absent')"
                />
                Absent
              </label>
              <label
                class="status-pill weekoff"
                :class="{ active: attendance[record.id] === 'Week Off' }"
              >
                <input
                  type="radio"
                  :name="'status-' + record.id"
                  :checked="attendance[record.id] === 'Week Off'"
                  @change="setStatus(record.id, 'Week Off')"
                />
                Week Off
              </label>
            </div>
            <span
              v-else
              class="status-badge"
              :class="{
                present: record.status === 'Present',
                absent: record.status === 'Absent',
                weekoff: record.status === 'Week Off'
              }"
            >
              {{ record.status || '-' }}
            </span>
          </td>
          <td v-if="canEditAttendance">
            <button @click="editRecord(record.id)">Edit</button>
            <button @click="deleteRecord(record.id)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else>No attendance records found.</p>
    <button v-if="canEditAttendance" @click="saveAttendance">
      Save Attendance
    </button>
  </div>

  <div v-else>
    <p>Loading or not logged in...</p>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  doc,
  getDocs,
  getDoc,
  query,
  where,
  setDoc
} from "firebase/firestore"

export default {
  data() {
    return {
      classes: Array.from({ length: 10 }, (_, i) => ({
        id: `class_${i + 1}`,
        label: `Class ${i + 1}`
      })),
      selectedClass: "",
      selectedDate: new Date().toISOString().substr(0, 10),
      activeDate: "",
      searchText: "",
      students: [],
      studentToAdd: "",
      attendance: {},
      allAttendanceRecords: [],
      user: JSON.parse(localStorage.getItem("user")) || {}
    }
  },
  computed: {
    canEditAttendance() {
      return ["teacher", "admin", "superadmin"].includes(this.user.role)
    },
    filteredAttendance() {
      const text = this.searchText.trim().toLowerCase()
      if (!text) return this.allAttendanceRecords
      return this.allAttendanceRecords.filter(
        r =>
          (r.name || "").toLowerCase().includes(text) ||
          (r.classId || "").toLowerCase().includes(text)
      )
    },
    availableStudents() {
      return this.students.filter(
        s =>
          !this.allAttendanceRecords.some(
            r => r.id === s.id && r.date === this.activeDate
          )
      )
    }
  },
  async mounted() {
    if (!this.user || !this.user.role) {
      alert("Please login first")
      this.$router.push("/login")
      return
    }
    this.activeDate = this.selectedDate
    await this.fetchAttendance()
  },
  methods: {
    applyDate() {
      if (!this.selectedDate) {
        alert("Please select a date first")
        return
      }
      this.activeDate = this.selectedDate
      this.fetchAttendance()   // date change pe fresh load
    },

    async fetchAttendance() {
      try {
        // 1) Students list (role + class filter same as pehle)
        const studentsRef = collection(db, "students")
        let q = studentsRef

        console.log(
          "role:",
          this.user.role,
          "classId:",
          this.user.classId,
          "selectedClass:",
          this.selectedClass
        )

        if (this.user.role === "superadmin") {
          q = studentsRef
        } else if (this.user.role === "admin") {
          if (this.selectedClass) {
            q = query(studentsRef, where("classId", "==", this.selectedClass))
          } else {
            q = studentsRef
          }
        } else if (this.user.role === "teacher") {
          if (this.selectedClass) {
            q = query(studentsRef, where("classId", "==", this.selectedClass))
          } else if (this.user.classId) {
            q = query(studentsRef, where("classId", "==", this.user.classId))
          } else {
            q = studentsRef
          }
        }

        const snap = await getDocs(q)
        console.log("👀 Students fetched:", snap.size)
        this.students = snap.docs.map(d => ({ id: d.id, ...d.data() }))

        // 2) Attendance: date-wise doc
        if (!this.activeDate) {
          this.allAttendanceRecords = []
          this.prepareAttendance()
          return
        }

        const docId = this.activeDate           // e.g. "2025-12-15"
        const dateRef = doc(db, "attendance", docId)
        const docSnap = await getDoc(dateRef)
        const attendanceData = docSnap.exists() ? docSnap.data() : {}

        // Expected structure:
        // {
        //   "class_2": {
        //      "studentId": { name, idNumber, classId, photoUrl, status }
        //   },
        //   "class_3": { ... }
        // }

        const records = []

        for (const cid in attendanceData) {
          const classBlock = attendanceData[cid]
          if (!classBlock || typeof classBlock !== "object") continue

          // Agar UI me class filter laga ho, to yahin filter kar sakte ho
          if (this.selectedClass && cid !== this.selectedClass) continue

          for (const studentId in classBlock) {
            const rec = classBlock[studentId]
            records.push({
              date: this.activeDate,
              id: studentId,
              name: rec.name,
              idNumber: rec.idNumber,
              classId: rec.classId,
              photoUrl: rec.photoUrl,
              status: rec.status
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
      const selectedRecords = this.allAttendanceRecords.filter(
        r => r.date === this.activeDate
      )
      const map = {}
      selectedRecords.forEach(r => {
        map[r.id] = r.status
      })
      this.attendance = map
    },

    setStatus(studentId, status) {
      if (!this.canEditAttendance) return
      this.attendance = { ...this.attendance, [studentId]: status }
      const index = this.allAttendanceRecords.findIndex(
        r => r.id === studentId && r.date === this.activeDate
      )
      if (index !== -1) {
        this.allAttendanceRecords[index].status = status
      } else {
        const student = this.students.find(s => s.id === studentId)
        if (!student) return
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

    addAttendanceRecord() {
      if (!this.studentToAdd) {
        alert("Select a student")
        return
      }
      const student = this.students.find(s => s.id === this.studentToAdd)
      if (!student) return
      this.allAttendanceRecords.push({
        date: this.activeDate,
        id: student.id,
        name: student.name,
        idNumber: student.idNumber,
        classId: student.classId,
        photoUrl: student.photoUrl,
        status: "Present"
      })
      this.attendance[student.id] = "Present"
      this.studentToAdd = ""
    },

    editRecord(studentId) {
      const record = this.allAttendanceRecords.find(
        r => r.id === studentId && r.date === this.activeDate
      )
      if (!record) return
      const newStatus = prompt(
        "Enter status (Present / Absent / Week Off):",
        record.status
      )
      if (
        newStatus &&
        ["Present", "Absent", "Week Off"].includes(newStatus)
      ) {
        this.setStatus(studentId, newStatus)
      }
    },

    deleteRecord(studentId) {
      if (!confirm("Are you sure you want to delete this record?")) return
      const { [studentId]: _, ...rest } = this.attendance
      this.attendance = rest
      this.allAttendanceRecords = this.allAttendanceRecords.filter(
        r => !(r.id === studentId && r.date === this.activeDate)
      )
    },

    async saveAttendance() {
      if (!this.canEditAttendance) {
        alert("You cannot save attendance")
        return
      }
      if (!this.activeDate) {
        alert("First select date")
        return
      }
      try {
        const docId = this.activeDate        // date-wise document
        const dateRef = doc(db, "attendance", docId)

        // Build payload: { classId: { studentId: {...} } }
        const attendancePayload = {}

        this.allAttendanceRecords.forEach(s => {
          if (!s.status) return
          const cid = s.classId || "unknown"

          if (!attendancePayload[cid]) {
            attendancePayload[cid] = {}
          }

          attendancePayload[cid][s.id] = {
            name: s.name,
            idNumber: s.idNumber,
            classId: s.classId,
            photoUrl: s.photoUrl,
            status: s.status
          }
        })

        await setDoc(
          dateRef,
          attendancePayload,
          { merge: true }
        )

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
.attendance-container{padding:2rem;background:#f5f5f5;min-height:100vh}
.controls{display:flex;flex-wrap:wrap;gap:1rem;margin-bottom:1rem;align-items:center}
.today-text{font-weight:bold}
.add-student-section{display:flex;align-items:center;gap:0.5rem}
table{width:100%;border-collapse:collapse;background:white;margin-top:1rem}
th,td{border:1px solid #ccc;padding:0.8rem;text-align:left}
th{background:#2196F3;color:white}
.student-photo{width:35px;height:35px;border-radius:50%;object-fit:cover}
.status-group{display:flex;gap:0.4rem}
.status-pill{display:inline-flex;align-items:center;gap:0.25rem;padding:0.15rem 0.6rem;border-radius:999px;font-size:0.8rem;font-weight:600;color:#fff;cursor:pointer;opacity:0.6;border:1px solid transparent}
.status-pill input{margin:0}
.status-pill.present{background:#4caf50}
.status-pill.absent{background:#e53935}
.status-pill.weekoff{background:#ff9800}
.status-pill.active{opacity:1;border-color:#00000044}
.status-badge{padding:0.2rem 0.6rem;border-radius:999px;color:#fff;font-size:0.8rem}
.status-badge.present{background:#4caf50}
.status-badge.absent{background:#e53935}
.status-badge.weekoff{background:#ff9800}
button{margin-top:0.3rem;padding:0.4rem 0.8rem;background:#1976d2;color:white;border:none;border-radius:5px;cursor:pointer}
button:hover{background:#0d47a1}
</style>

