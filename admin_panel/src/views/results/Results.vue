<template>
  <div class="results-page">
    <!-- Header -->
    <header class="page-header">
      <div>
        <h1>Student Results</h1>
        <p>Manage exam results for each class and student.</p>
      </div>
    </header>

    <!-- Filters + actions -->
    <section class="card controls-card">
      <div class="controls-row">
        <div class="field">
          <label>Class</label>
          <select v-model="selectedClass" @change="fetchStudents">
            <option v-for="cls in classes" :key="cls" :value="cls">
              {{ cls }}
            </option>
          </select>
        </div>

        <div class="field">
          <label>Search student</label>
          <input
            v-model="searchName"
            type="text"
            placeholder="Type name to filter"
          />
        </div>

        <div class="actions">
          <button class="btn primary" @click="addResult">
            + Add result
          </button>
        </div>
      </div>
    </section>

    <!-- Table -->
    <section class="card">
      <div class="card-header">
        <h2>Results list</h2>
        <span class="subtext">
          Class: {{ selectedClass }} • Students: {{ filteredStudents.length }}
        </span>
      </div>

      <div class="table-wrapper">
        <table v-if="filteredStudents.length" class="results-table">
          <thead>
            <tr>
              <th>Roll No</th>
              <th>Student</th>
              <th>Exam</th>
              <th>Subjects</th>
              <th>Percentage</th>
              <th>Grade</th>
              <th>Report card</th>
            </tr>
          </thead>
          <tbody>
            <template v-for="student in filteredStudents" :key="student.id">
              <tr
                v-for="(exam, examId, idx) in results[student.id] || {}"
                :key="student.id + '-' + examId"
              >
                <!-- Roll / name only on first exam row -->
                <td
                  v-if="idx === 0"
                  :rowspan="Object.keys(results[student.id] || {}).length || 1"
                >
                  {{ student.rollNo || "-" }}
                </td>

                <td
                  v-if="idx === 0"
                  :rowspan="Object.keys(results[student.id] || {}).length || 1"
                >
                  <div class="student-info">
                    <div class="avatar">
                      {{ (student.name || "?").charAt(0).toUpperCase() }}
                    </div>
                    <div>
                      <div class="student-name">{{ student.name || "-" }}</div>
                      <div class="student-meta">{{ student.classId }}</div>
                    </div>
                  </div>
                </td>

                <!-- If exam records exist -->
                <template v-if="Object.keys(results[student.id] || {}).length">
                  <td class="exam-cell">{{ examId }}</td>
                  <td class="subjects-cell">
                    {{ formatSubjects(exam.subjectMarks) }}
                  </td>
                  <td class="percent-cell">
                    {{ exam.percentage }}%
                  </td>
                  <td>
                    <span class="grade-pill">
                      {{ exam.grade }}
                    </span>
                  </td>
                  <td>
                    <a
                      v-if="exam.reportCardURL"
                      :href="exam.reportCardURL"
                      target="_blank"
                      class="link"
                    >
                      View PDF
                    </a>
                    <span v-else class="muted">Not uploaded</span>
                  </td>
                </template>

                <!-- No exam for this student -->
                <template v-else>
                  <td colspan="5" class="muted">
                    No exam records for this student.
                  </td>
                </template>
              </tr>
            </template>
          </tbody>
        </table>

        <p v-else class="empty-state">
          No students found for this class.
        </p>
      </div>
    </section>
  </div>
</template>

<script>
import { db, storage } from "../../services/firebase"
import { collection, doc, getDocs, getDoc, setDoc } from "firebase/firestore"
import { ref, uploadBytes, getDownloadURL } from "firebase/storage"

export default {
  data() {
    return {
      classes: ["Class 1", "Class 2", "Class 3"],
      selectedClass: "Class 1",
      students: [],
      results: {},
      searchName: "",
      user: JSON.parse(localStorage.getItem("user"))
    }
  },
  computed: {
    filteredStudents() {
      const name = this.searchName.trim().toLowerCase()
      return this.students.filter(s =>
        !name || (s.name || "").toLowerCase().includes(name)
      )
    }
  },
  methods: {
    async fetchStudents() {
      const snap = await getDocs(collection(db, "students"))
      this.students = snap.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .filter(s => s.classId === this.selectedClass)
      await this.fetchResults()
    },
    async fetchResults() {
      const resultsCopy = { ...this.results }
      for (const student of this.students) {
        const docRef = doc(db, "results", student.id)
        const docSnap = await getDoc(docRef)
        resultsCopy[student.id] = docSnap.exists() ? docSnap.data() : {}
      }
      this.results = resultsCopy
    },
    formatSubjects(subjectMarks) {
      return Object.entries(subjectMarks || {})
        .map(([sub, mark]) => `${sub}: ${mark}`)
        .join(", ")
    },
    async addResult() {
      const studentId = prompt("Enter student ID")
      if (!studentId) return

      const examId = prompt("Enter exam ID")
      if (!examId) return

      const math = prompt("Math marks")
      const sci = prompt("Science marks")

      const perc = ((Number(math) + Number(sci)) / 2).toFixed(2)
      const grade =
        perc >= 90 ? "A+" :
        perc >= 80 ? "A" :
        perc >= 70 ? "B+" : "B"

      let reportURL = ""
      const filePath = prompt("Enter report card URL or leave blank")
      if (filePath) {
        reportURL = filePath
      }

      const docRef = doc(db, "results", studentId)
      const docSnap = await getDoc(docRef)
      const data = docSnap.exists() ? docSnap.data() : {}
      data[examId] = {
        subjectMarks: { math: Number(math), sci: Number(sci) },
        percentage: perc,
        grade,
        reportCardURL: reportURL
      }
      await setDoc(docRef, data)
      this.$set
        ? this.$set(this.results, studentId, data)
        : (this.results = { ...this.results, [studentId]: data })

      alert("Result saved")
    }
  },
  mounted() {
    this.fetchStudents()
  }
}
</script>

<style scoped>
/* Layout */
.results-page {
  min-height: 100vh;
  padding: 2rem;
  background: #f3f4f6;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #111827;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 1.5rem;
}

.page-header h1 {
  margin: 0;
  font-size: 1.6rem;
  font-weight: 600;
}

.page-header p {
  margin: 0.35rem 0 0;
  color: #6b7280;
  font-size: 0.9rem;
}

/* Card */
.card {
  background: #ffffff;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
  padding: 1rem 1.25rem;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.04);
  margin-bottom: 1.25rem;
}

/* Controls */
.controls-row {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-end;
}

.field {
  display: flex;
  flex-direction: column;
  min-width: 180px;
  flex: 1;
}

.field label {
  font-size: 0.8rem;
  color: #6b7280;
  margin-bottom: 0.25rem;
}

.field select,
.field input {
  padding: 0.4rem 0.7rem;
  border-radius: 0.5rem;
  border: 1px solid #d1d5db;
  background: #ffffff;
  font-size: 0.86rem;
}

.field select:focus,
.field input:focus {
  outline: none;
  border-color: #2563eb;
  box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.18);
}

.actions {
  margin-left: auto;
}

/* Buttons */
.btn {
  border-radius: 999px;
  padding: 0.45rem 1.1rem;
  font-size: 0.85rem;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  transition: all 0.15s ease;
}

.btn.primary {
  background: #2563eb;
  color: #ffffff;
}

.btn.primary:hover {
  background: #1d4ed8;
}

/* Card header */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 0.6rem;
}

.card-header h2 {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
}

.subtext {
  font-size: 0.8rem;
  color: #6b7280;
}

/* Table */
.table-wrapper {
  overflow-x: auto;
}

.results-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.84rem;
}

.results-table thead {
  background: #f9fafb;
}

.results-table th {
  text-align: left;
  padding: 0.55rem 0.7rem;
  font-weight: 500;
  color: #6b7280;
  border-bottom: 1px solid #e5e7eb;
  white-space: nowrap;
}

.results-table tbody tr:nth-child(even) {
  background: #f9fafb;
}

.results-table tbody tr:nth-child(odd) {
  background: #ffffff;
}

.results-table td {
  padding: 0.5rem 0.7rem;
  border-bottom: 1px solid #e5e7eb;
  vertical-align: top;
}

/* Student info */
.student-info {
  display: flex;
  align-items: center;
  gap: 0.55rem;
}

.avatar {
  width: 28px;
  height: 28px;
  border-radius: 999px;
  background: #e5e7eb;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
  font-weight: 600;
  color: #374151;
}

.student-name {
  font-weight: 500;
}

.student-meta {
  font-size: 0.72rem;
  color: #6b7280;
}

/* Cells */
.exam-cell {
  font-weight: 500;
}

.subjects-cell {
  max-width: 260px;
}

.percent-cell {
  font-weight: 500;
}

/* Grade pill (neutral) */
.grade-pill {
  display: inline-flex;
  align-items: center;
  padding: 0.15rem 0.55rem;
  border-radius: 999px;
  font-size: 0.72rem;
  border: 1px solid #e5e7eb;
  color: #374151;
  background: #f9fafb;
}

/* Links / text */
.link {
  color: #2563eb;
  font-size: 0.82rem;
  text-decoration: none;
}

.link:hover {
  text-decoration: underline;
}

.muted {
  font-size: 0.78rem;
  color: #9ca3af;
}

.empty-state {
  margin: 0.6rem 0;
  font-size: 0.83rem;
  color: #6b7280;
}

/* Responsive */
@media (max-width: 768px) {
  .results-page {
    padding: 1.2rem;
  }
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.4rem;
  }
  .controls-row {
    flex-direction: column;
  }
}
</style>

