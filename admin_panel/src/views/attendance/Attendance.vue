<template>
  <div class="attendance-container" v-if="user">
    <h2>Mark Attendance</h2>

    <div class="controls">
      <label>Select Class:</label>
      <select v-model="selectedClass" @change="fetchStudents">
        <option value="">All Classes</option>
        <option
          v-for="cls in classes"
          :key="cls.id"
          :value="cls.id"
        >
          {{ cls.label }}
        </option>
      </select>

      <label>Select Date:</label>
      <input type="date" v-model="selectedDate" />

      <button class="add-date-btn" @click="applyDate">Add Date</button>

      <span class="today-text">
        Applied Date: {{ activeDate || 'Not selected' }}
      </span>

      <input
        v-model="searchText"
        type="text"
        placeholder="Search by name or class..."
      />
    </div>

    <table v-if="filteredStudents.length">
      <thead>
        <tr>
          <th>Roll No</th>
          <th>Student Name</th>
          <th>Class</th>
          <th>Date</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="student in filteredStudents" :key="student.id">
          <td>{{ student.rollNo || "-" }}</td>
          <td>{{ student.name || "-" }}</td>
          <td>{{ student.classId || "-" }}</td>
          <td>{{ activeDate }}</td>
          <td>
            <div v-if="isTeacherOrAdmin" class="status-group">
              <label
                class="status-pill present"
                :class="{ active: attendance[student.id] === 'Present' }"
              >
                <input
                  type="checkbox"
                  :checked="attendance[student.id] === 'Present'"
                  @change="setStatus(student.id, 'Present')"
                />
                Present
              </label>

              <label
                class="status-pill absent"
                :class="{ active: attendance[student.id] === 'Absent' }"
              >
                <input
                  type="checkbox"
                  :checked="attendance[student.id] === 'Absent'"
                  @change="setStatus(student.id, 'Absent')"
                />
                Absent
              </label>
            </div>

            <span
              v-else
              class="status-badge"
              :class="attendance[student.id] === 'Present' ? 'present' : 'absent'"
            >
              {{ attendance[student.id] || '-' }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else>No students found for this class.</p>

    <button v-if="isTeacherOrAdmin" @click="saveAttendance">Save Attendance</button>
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
      attendance: {},
      user: JSON.parse(localStorage.getItem("user")) || {}
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return this.user.role === "teacher" || this.user.role === "admin"
    },
    filteredStudents() {
      const text = this.searchText.trim().toLowerCase()
      if (!text) return this.students
      return this.students.filter(s => {
        const name = (s.name || "").toLowerCase()
        const cls = (s.classId || "").toLowerCase()
        return name.includes(text) || cls.includes(text)
      })
    }
  },
  async mounted() {
    if (!this.user || !this.isTeacherOrAdmin) {
      alert("You are not authorized to mark attendance")
      this.$router.push("/login")
      return
    }
    await this.fetchStudents()
    this.activeDate = this.selectedDate
  },
  methods: {
    applyDate() {
      if (!this.selectedDate) {
        alert("Please select a date first")
        return
      }
      this.activeDate = this.selectedDate
    },

    async fetchStudents() {
      try {
        const studentsRef = collection(db, "students")
        const refOrQuery = this.selectedClass
          ? query(studentsRef, where("classId", "==", this.selectedClass))
          : studentsRef

        const snap = await getDocs(refOrQuery)

        if (snap.empty) {
          this.students = []
          this.attendance = {}
          return
        }

        this.students = snap.docs.map(d => ({
          id: d.id,
          ...d.data()
        }))

        const newAttendance = {}
        this.students.forEach(s => {
          newAttendance[s.id] = this.attendance[s.id] || "Present"
        })
        this.attendance = newAttendance
      } catch (err) {
        console.error("Error fetching students:", err)
      }
    },

    setStatus(studentId, status) {
      if (!this.isTeacherOrAdmin) return
      this.$set
        ? this.$set(this.attendance, studentId, status)
        : (this.attendance = { ...this.attendance, [studentId]: status })
    },

    async saveAttendance() {
      if (!this.activeDate) {
        alert("First select date and click 'Add Date'")
        return
      }

      try {
        const docId = this.selectedClass || "all_classes"
        const classRef = doc(db, "attendance", docId)

        const attendancePayload = {}
        this.students.forEach(s => {
          attendancePayload[s.id] = {
            name: s.name || "",
            rollNo: s.rollNo || "",
            classId: s.classId || "",
            date: this.activeDate,
            status: this.attendance[s.id] || "Present"
          }
        })

        await setDoc(
          classRef,
          { [this.activeDate]: attendancePayload },
          { merge: true }
        )

        alert("Attendance saved successfully!")
      } catch (err) {
        console.error("Error saving attendance:", err)
        alert("Failed to save attendance.")
      }
    }
  }
}
</script>

<style scoped>
.attendance-container {
  padding: 2rem;
  background: #f5f5f5;
  min-height: 100vh;
}

.controls {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin-bottom: 1rem;
  align-items: center;
}

.today-text {
  font-weight: bold;
}

.add-date-btn {
  padding: 0.4rem 0.8rem;
  background: #2196f3;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.add-date-btn:hover {
  background: #1976d2;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  margin-top: 1rem;
}

th,
td {
  border: 1px solid #ccc;
  padding: 0.8rem;
  text-align: left;
}

th {
  background: #2196F3;
  color: white;
}

/* Status pills (present/absent) */
.status-group {
  display: flex;
  gap: 0.4rem;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.15rem 0.6rem;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #fff;
  cursor: pointer;
  opacity: 0.6;
  border: 1px solid transparent;
}

.status-pill input {
  margin: 0;
}

.status-pill.present {
  background: #4caf50;
}

.status-pill.absent {
  background: #e53935;
}

/* selected state */
.status-pill.active {
  opacity: 1;
  border-color: #00000044;
}

.status-badge {
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  color: #fff;
  font-size: 0.8rem;
}

.status-badge.present {
  background: #4caf50;
}

.status-badge.absent {
  background: #e53935;
}

button {
  margin-top: 1rem;
  padding: 0.6rem 1.2rem;
  background: #4caf50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

button:hover {
  background: #45a049;
}
</style>

