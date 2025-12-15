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
        <div class="field small-field">
          <label>Class</label>
          <select v-model="selectedClass" @change="fetchStudents">
            <option value="All Classes">All Classes</option>
            <option
              v-for="cls in classes"
              :key="cls.value"
              :value="cls.value"
            >
              {{ cls.label }}
            </option>
          </select>
        </div>

        <div class="field small-field">
          <label>Search student</label>
          <input
            v-model="searchName"
            type="text"
            placeholder="Search name"
          />
        </div>

        <div class="actions">
          <button class="btn primary small-btn" @click="openAddResultForm">
            + Add result
          </button>
        </div>
      </div>
    </section>

    <!-- Table: per-exam summary rows -->
    <section class="card">
      <div class="card-header">
        <h2>Results list</h2>
        <span class="subtext">
          Class: {{ selectedClass }} • Records: {{ filteredRows.length }}
        </span>
      </div>

      <div class="table-wrapper">
        <table v-if="filteredRows.length" class="results-table pretty">
          <thead>
            <tr>
              <th>Student</th>
              <th>Exam</th>
              <th>Subjects</th>
              <th>Total</th>
              <th>%</th>
              <th>Grade</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in filteredRows" :key="row.key">
              <!-- Student cell: photo + name + ID/class -->
              <td class="student-cell">
                <img
                  v-if="row.photoUrl"
                  :src="row.photoUrl"
                  alt="photo"
                  class="avatar"
                />
                <div v-else class="avatar avatar-initial">
                  {{ (row.name || '?').charAt(0).toUpperCase() }}
                </div>
                <div class="student-meta">
                  <div class="student-name">{{ row.name || "-" }}</div>
                  <div class="student-sub">
                    ID: {{ row.studentId }} • {{ classLabel(row.classId) }}
                  </div>
                </div>
              </td>

              <td>{{ row.examName }}</td>

              <!-- Subjects multiline -->
              <td class="subjects-cell">
                <div
                  v-for="line in row.subjectLines"
                  :key="line"
                  class="subject-line"
                >
                  {{ line }}
                </div>
              </td>

              <td>{{ row.totalObtained }}/{{ row.totalMaximum }}</td>

              <td>
                <span class="badge pct-badge">
                  {{ row.percentage.toFixed(1) }}%
                </span>
              </td>

              <td>
                <span class="badge grade-badge">
                  {{ row.grade }}
                </span>
              </td>

              <td>
                <span
                  class="badge"
                  :class="row.status === 'Pass' ? 'badge-pass' : 'badge-fail'"
                >
                  {{ row.status }}
                </span>
              </td>

              <td>
                <button
                  class="btn small-btn"
                  @click="editExam(row.studentFirestoreId, row.examName)"
                >
                  Edit
                </button>
                <button
                  class="btn small-btn delete-btn"
                  @click="deleteExam(row.studentFirestoreId, row.examName)"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <p v-else class="empty-state">No results found for this filter.</p>
      </div>
    </section>

    <!-- Add / Edit Result Modal -->
    <div v-if="showAddResultForm" class="modal-backdrop">
      <div class="modal">
        <h3>Add / Update Result (All Subjects)</h3>

        <div class="modal-body">
          <div class="field">
            <label>Student (ID Number)</label>
            <select v-model="form.studentId">
              <option value="">Select student</option>
              <option
                v-for="s in students"
                :key="s.id"
                :value="s.id"
              >
                {{ s.name }} ({{ classLabel(s.classId) }})
                - ID {{ s.idNumber || s.rollNo || s.id }}
              </option>
            </select>
          </div>

          <div class="field">
            <label>Exam name</label>
            <input
              v-model="form.examName"
              type="text"
              placeholder="e.g. Mid Term, Final Exam"
            />
          </div>

          <div class="field">
            <label>Subjects & marks</label>
          </div>
          <div
            class="subject-row"
            v-for="sub in form.subjectsMarks"
            :key="sub.name"
          >
            <div class="subject-name">
              <input
                type="checkbox"
                v-model="sub.enabled"
              />
              <span>{{ sub.name }}</span>
            </div>
            <input
              v-model.number="sub.obtained"
              type="number"
              min="0"
              placeholder="Obtained"
              :disabled="!sub.enabled"
            />
            <input
              v-model.number="sub.maximum"
              type="number"
              min="1"
              placeholder="Maximum"
              :disabled="!sub.enabled"
            />
          </div>

          <div class="field-row">
            <div class="field">
              <label>Grade (optional, auto per subject)</label>
              <small>Leave empty to auto-calculate grade from percentage.</small>
            </div>
          </div>

          <div class="field">
            <label>Overall status (default Pass)</label>
            <select v-model="form.status">
              <option value="Pass">Pass</option>
              <option value="Fail">Fail</option>
            </select>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn" @click="closeAddResultForm">Cancel</button>
          <button class="btn primary" @click="saveResult">Save</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  doc,
  getDocs,
  getDoc,
  setDoc,
} from "firebase/firestore" // [web:989]

export default {
  data() {
    return {
      classes: Array.from({ length: 10 }, (_, i) => ({
        label: `Class ${i + 1}`,
        value: `class_${i + 1}`,
      })),
      subjects: [
        "Hindi",
        "Telugu",
        "Urdu",
        "English",
        "Mathematics",
        "Science",
        "Chemistry",
        "Biology",
        "Social Studies",
        "Computer",
        "Islamiyat",
        "General Knowledge",
      ],
      selectedClass: "All Classes",
      students: [],
      results: {},
      searchName: "",
      showAddResultForm: false,
      form: {
        studentId: "",
        examName: "",
        subjectsMarks: [],
        status: "Pass",
      },
    }
  },

  computed: {
    filteredStudents() {
      const name = this.searchName.trim().toLowerCase()
      return this.students.filter((s) => {
        const matchesName =
          !name || (s.name || "").toLowerCase().includes(name)
        const matchesClass =
          this.selectedClass === "All Classes" ||
          s.classId === this.selectedClass
        return matchesName && matchesClass
      })
    },

    // Per-exam summary rows, with multiline subjectLines
    filteredRows() {
      const rows = []
      for (const student of this.filteredStudents) {
        const studentResults = this.results[student.id] || {}
        for (const [examName, subjects] of Object.entries(studentResults)) {
          let totalObtained = 0
          let totalMaximum = 0
          const subjectLines = []

          for (const [subjectName, data] of Object.entries(subjects)) {
            const obtained = Number(data.obtained || 0)
            const maximum = Number(data.maximum || 0) || 1
            totalObtained += obtained
            totalMaximum += maximum
            const grade =
              data.grade || this.autoGrade((obtained / maximum) * 100)
            subjectLines.push(`${subjectName}: ${obtained}/${maximum} (${grade})`)
          }

          if (totalMaximum === 0) continue
          const percentage = (totalObtained / totalMaximum) * 100
          const overallGrade = this.autoGrade(percentage)
          const overallStatus = percentage >= 40 ? "Pass" : "Fail"

          rows.push({
            key: `${student.id}-${examName}`,
            studentId: student.idNumber || student.rollNo || student.id,
            studentFirestoreId: student.id,
            name: student.name,
            classId: student.classId,
            photoUrl: student.photoUrl || "",
            examName,
            subjectLines,
            totalObtained,
            totalMaximum,
            percentage,
            grade: overallGrade,
            status: overallStatus,
          })
        }
      }
      return rows
    },
  },

  methods: {
    classLabel(classId) {
      const cls = this.classes.find((c) => c.value === classId)
      return cls ? cls.label : "-"
    },

    autoGrade(pct) {
      if (pct >= 80) return "A"
      if (pct >= 60) return "B"
      if (pct >= 50) return "C"
      if (pct >= 40) return "D"
      return "F"
    },

    async fetchStudents() {
      const snap = await getDocs(collection(db, "students"))
      const allStudents = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      this.students =
        this.selectedClass === "All Classes"
          ? allStudents
          : allStudents.filter((s) => s.classId === this.selectedClass)
      await this.fetchResults()
    },

    async fetchResults() {
      const resultsCopy = {}
      for (const student of this.students) {
        const docRef = doc(db, "results", student.id)
        const docSnap = await getDoc(docRef)
        resultsCopy[student.id] = docSnap.exists() ? docSnap.data() : {}
      }
      this.results = resultsCopy
    },

    openAddResultForm() {
      this.resetForm()
      this.showAddResultForm = true
    },

    closeAddResultForm() {
      this.showAddResultForm = false
    },

    resetForm() {
      this.form = {
        studentId: "",
        examName: "",
        subjectsMarks: this.subjects.map((name) => ({
          name,
          enabled: false,
          obtained: null,
          maximum: null,
        })),
        status: "Pass",
      }
    },

    async saveResult() {
      const { studentId, examName, subjectsMarks, status } = this.form

      const enabledSubjects = subjectsMarks.filter(
        (s) => s.enabled && s.obtained != null && s.maximum != null
      )

      if (!studentId || !examName || !enabledSubjects.length) {
        alert(
          "Student, exam name and at least one subject marks are required."
        )
        return
      }

      try {
        const docRef = doc(db, "results", studentId)
        const docSnap = await getDoc(docRef)
        const current = docSnap.exists() ? docSnap.data() : {}

        if (!current[examName]) current[examName] = {}

        for (const sub of enabledSubjects) {
          const obtained = Number(sub.obtained)
          const maximum = Number(sub.maximum) || 1
          const pct = (obtained / maximum) * 100
          current[examName][sub.name] = {
            obtained,
            maximum,
            grade: this.autoGrade(pct),
            status: status || (pct >= 40 ? "Pass" : "Fail"),
          }
        }

        await setDoc(docRef, current, { merge: true }) // [web:989]

        alert("Results saved successfully.")
        this.showAddResultForm = false
        await this.fetchResults()
      } catch (err) {
        console.error("Save result error:", err)
        alert("Failed to save result.")
      }
    },

    async editExam(studentId, examName) {
      const docRef = doc(db, "results", studentId)
      const docSnap = await getDoc(docRef)
      if (!docSnap.exists()) return

      const data = docSnap.data()
      const examData = data[examName] || {}

      const subjectsMarks = this.subjects.map((name) => {
        const sub = examData[name]
        return {
          name,
          enabled: !!sub,
          obtained: sub ? sub.obtained : null,
          maximum: sub ? sub.maximum : null,
        }
      })

      this.form = {
        studentId,
        examName,
        subjectsMarks,
        status: "Pass",
      }
      this.showAddResultForm = true
    },

    async deleteExam(studentId, examName) {
      const ok = confirm(
        `Delete all results for this exam (${examName}) for this student?`
      )
      if (!ok) return

      try {
        const docRef = doc(db, "results", studentId)
        const docSnap = await getDoc(docRef)
        if (!docSnap.exists()) return

        const data = docSnap.data()
        delete data[examName]

        await setDoc(docRef, data, { merge: false }) // overwrite [web:989]
        alert("Exam deleted successfully.")
        await this.fetchResults()
      } catch (e) {
        console.error("Delete exam error:", e)
        alert("Failed to delete exam.")
      }
    },
  },

  mounted() {
    this.resetForm()
    this.fetchStudents()
  },
}
</script>

<style scoped>
.results-page {
  padding: 0.4rem 1rem; /* aur kam top padding */
}

.card:first-of-type {
  margin-top: 0.3rem;   /* filters wali card */
}

.card:nth-of-type(2) {
  margin-top: 0.0rem;   /* Results list wali card ko bhi upar lao */
}

.page-header {
  margin-bottom: 0.1rem;
}

.card {
  background: #ffffff;
  border-radius: 0.75rem;
  padding: 0.75rem 1rem; /* thoda kam padding */
  margin-bottom: 0.5rem;  /* pehle 1rem tha */
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
}

.controls-row {
  display: flex;
  gap: 0.6rem; /* pehle 0.8rem */
  align-items: flex-end;
}

.card-header {
  margin-bottom: 0.0rem; /* optional: list title aur table ke beech gap kam */
}

.field {
  display: flex;
  flex-direction: column;
  min-width: 150px;
}

.field-row {
  display: flex;
  gap: 0.75rem;
}

.small-field select,
.small-field input,
.field select,
.field input {
  font-size: 0.8rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.4rem;
  border: 1px solid #ccc;
}

.actions {
  margin-left: auto;
}

.btn {
  padding: 0.4rem 0.9rem;
  border-radius: 0.4rem;
  border: none;
  cursor: pointer;
  font-size: 0.85rem;
}

.btn.primary {
  background: #4caf50;
  color: #fff;
}

.small-btn {
  font-size: 0.8rem;
  padding: 0.3rem 0.7rem;
}

.delete-btn {
  background: #e53935;
  color: #fff;
}

.delete-btn:hover {
  background: #c62828;
}

.table-wrapper {
  overflow-x: auto;
}

/* Modern table styling */
.results-table.pretty {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 3px; /* pehle 6px tha, ab gap kam */
  font-size: 0.85rem;
}

.results-table.pretty tbody tr {
  background: #fafafa;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04); /* shadow thoda soft */
}

.results-table.pretty tbody tr:hover {
  background: #f0f7ff;
}

.results-table.pretty tbody tr {
  background: #fafafa;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
}

.results-table.pretty tbody tr:hover {
  background: #f0f7ff;
}

.results-table.pretty td {
  padding: 0.35rem 0.5rem;
  border-top: 1px solid #eee;
}

.subtext {
  font-size: 0.8rem;
  color: #666;
}

.empty-state {
  padding: 0.75rem;
  font-size: 0.9rem;
  color: #777;
}

.status-pass {
  color: #2e7d32;
  font-weight: 600;
}

.status-fail {
  color: #c62828;
  font-weight: 600;
}

.avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  object-fit: cover;
}

.avatar-initial {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: #90caf9;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: #0d47a1;
}

.student-cell {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.student-meta {
  display: flex;
  flex-direction: column;
}

.student-name {
  font-weight: 600;
}

.student-sub {
  font-size: 0.75rem;
  color: #777;
}

.subjects-cell {
  max-width: 260px;
}

.subject-line {
  font-size: 0.78rem;
  line-height: 1.2;
}

.subject-row {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-bottom: 0.25rem;
}

.subject-name {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  width: 160px;
}

/* Badges */
.badge {
  display: inline-block;
  padding: 0.1rem 0.45rem;
  border-radius: 999px;
  font-size: 0.75rem;
}

.pct-badge {
  background: #e3f2fd;
  color: #1565c0;
}

.grade-badge {
  background: #ede7f6;
  color: #5e35b1;
  font-weight: 600;
}

.badge-pass {
  background: #e8f5e9;
  color: #2e7d32;
}

.badge-fail {
  background: #ffebee;
  color: #c62828;
}

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
}

.modal {
  background: #fff;
  border-radius: 0.75rem;
  padding: 1rem 1.25rem;
  width: 480px;
  max-width: 95vw;
}

.modal-body {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  margin: 0.5rem 0 0.75rem;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}
</style>

