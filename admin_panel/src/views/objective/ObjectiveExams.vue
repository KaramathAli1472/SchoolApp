<template>
  <div class="objective-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>Objective Exams</h2>
          <p>Create and manage multiple-choice exams for classes</p>
        </div>
        <button class="btn primary" @click="openForm()">
          + Create exam
        </button>
      </div>

      <!-- Filters -->
      <div class="filters">
        <div class="field">
          <label>Class</label>
          <select v-model="filters.classId">
            <option value="">All classes</option>
            <option v-for="cls in classOptions" :key="cls" :value="cls">
              {{ cls }}
            </option>
          </select>
        </div>

        <div class="field">
          <label>Subject</label>
          <input
            v-model="filters.subject"
            type="text"
            placeholder="e.g. Science"
          />
        </div>

        <div class="field">
          <label>Search</label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Exam title"
          />
        </div>

        <button class="btn ghost" @click="clearFilters">Clear</button>
      </div>

      <!-- Summary -->
      <div class="summary" v-if="exams.length">
        <div class="summary-item">
          <span class="summary-label">Total exams</span>
          <span class="summary-value">{{ exams.length }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Published</span>
          <span class="summary-value">
            {{ exams.filter(e => e.isPublished).length }}
          </span>
        </div>
      </div>

      <!-- Table -->
      <div v-if="filteredExams.length" class="table-wrapper">
        <table class="exams-table">
          <thead>
            <tr>
              <th>Title</th>
              <th>Subject</th>
              <th>Class</th>
              <th>Total Questions</th>
              <th>Max Marks</th>
              <th>Duration (min)</th>
              <th>Schedule</th>
              <th>Status</th>
              <th style="width: 110px;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="exam in filteredExams" :key="exam.id">
              <td>{{ exam.title }}</td>
              <td>{{ exam.subject }}</td>
              <td>{{ exam.classId }}</td>
              <td>{{ exam.questions?.length || 0 }}</td>
              <td>{{ exam.totalMarks }}</td>
              <td>{{ exam.durationMinutes }}</td>
              <td>
                <div v-if="exam.startTime && exam.endTime">
                  <div>{{ formatDate(exam.startTime) }}</div>
                  <small>to {{ formatDate(exam.endTime) }}</small>
                </div>
                <span v-else>-</span>
              </td>
              <td>
                <span
                  class="status-pill"
                  :class="exam.isPublished ? 'status-live' : 'status-draft'"
                >
                  {{ exam.isPublished ? 'Published' : 'Draft' }}
                </span>
              </td>
              <td>
                <button class="link-btn" @click="openForm(exam)">Edit</button>
                <button class="link-btn danger" @click="deleteExam(exam)">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <p v-else class="empty-text">
        No exams found. Click "Create exam" to add a new objective test.
      </p>
    </div>

    <!-- Add/Edit Exam Modal -->
    <div v-if="showForm" class="modal-backdrop">
      <div class="modal modal-wide">
        <h3>{{ editingId ? 'Edit exam' : 'Create exam' }}</h3>

        <!-- Basic exam info -->
        <div class="field">
          <label>Exam title</label>
          <input
            v-model="form.title"
            type="text"
            placeholder="e.g. Science Unit Test 1"
          />
        </div>

        <div class="field-row">
          <div class="field">
            <label>Subject</label>
            <input v-model="form.subject" type="text" placeholder="Science" />
          </div>
          <div class="field">
            <label>Class</label>
            <select v-model="form.classId">
              <option disabled value="">Select class</option>
              <option v-for="cls in classOptions" :key="cls" :value="cls">
                {{ cls }}
              </option>
            </select>
          </div>
        </div>

        <div class="field-row">
          <div class="field">
            <label>Total marks</label>
            <input
              v-model.number="form.totalMarks"
              type="number"
              min="0"
              placeholder="e.g. 20"
            />
          </div>
          <div class="field">
            <label>Duration (minutes)</label>
            <input
              v-model.number="form.durationMinutes"
              type="number"
              min="0"
              placeholder="e.g. 30"
            />
          </div>
        </div>

        <!-- Schedule (simple text / datetime) -->
        <div class="field-row">
          <div class="field">
            <label>Start time (optional)</label>
            <input
              v-model="form.startTimeText"
              type="datetime-local"
            />
          </div>
          <div class="field">
            <label>End time (optional)</label>
            <input
              v-model="form.endTimeText"
              type="datetime-local"
            />
          </div>
        </div>

        <!-- Questions section -->
        <div class="questions-block">
          <div class="questions-header">
            <h4>Questions (MCQ)</h4>
            <button class="btn small" @click="addQuestion">
              + Add question
            </button>
          </div>

          <div v-if="form.questions.length === 0" class="empty-questions">
            No questions added. Click "Add question" to insert MCQs.
          </div>

          <div
            v-for="(q, idx) in form.questions"
            :key="idx"
            class="question-card"
          >
            <div class="question-header">
              <span>Q{{ idx + 1 }}</span>
              <button class="link-btn danger" @click="removeQuestion(idx)">
                Remove
              </button>
            </div>

            <div class="field">
              <label>Question text</label>
              <textarea
                v-model="q.text"
                rows="2"
                placeholder="Type question here"
              ></textarea>
            </div>

            <div class="field-row">
              <div class="field">
                <label>Option A</label>
                <input v-model="q.options[0]" type="text" />
              </div>
              <div class="field">
                <label>Option B</label>
                <input v-model="q.options[1]" type="text" />
              </div>
            </div>

            <div class="field-row">
              <div class="field">
                <label>Option C</label>
                <input v-model="q.options[2]" type="text" />
              </div>
              <div class="field">
                <label>Option D</label>
                <input v-model="q.options[3]" type="text" />
              </div>
            </div>

            <div class="field-row">
              <div class="field">
                <label>Correct option</label>
                <select v-model="q.correctIndex">
                  <option :value="0">A</option>
                  <option :value="1">B</option>
                  <option :value="2">C</option>
                  <option :value="3">D</option>
                </select>
              </div>
              <div class="field">
                <label>Marks</label>
                <input
                  v-model.number="q.marks"
                  type="number"
                  min="0"
                  placeholder="1"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="field">
          <label>
            <input type="checkbox" v-model="form.isPublished" />
            <span>Publish exam (visible to students)</span>
          </label>
        </div>

        <p v-if="error" class="error-text">{{ error }}</p>

        <div class="modal-actions">
          <button class="btn ghost" @click="closeForm">Cancel</button>
          <button class="btn primary" :disabled="saving" @click="saveExam">
            {{ saving ? 'Saving...' : (editingId ? 'Update exam' : 'Create exam') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  getDocs,
  addDoc,
  doc,
  setDoc,
  deleteDoc,
  serverTimestamp,
  orderBy,
  query
} from "firebase/firestore" // Firestore web v9 style [web:480]

export default {
  name: "ObjectiveExams",
  data() {
    return {
      exams: [],
      filters: {
        classId: "",
        subject: "",
        search: ""
      },
      classOptions: [
        "class_1",
        "class_2",
        "class_3",
        "class_4",
        "class_5",
        "class_6",
        "class_7",
        "class_8",
        "class_9",
        "class_10"
      ],
      showForm: false,
      saving: false,
      editingId: null,
      error: "",
      form: this.defaultForm()
    }
  },
  computed: {
    filteredExams() {
      let list = [...this.exams]

      if (this.filters.classId) {
        list = list.filter(e => e.classId === this.filters.classId)
      }
      if (this.filters.subject) {
        const s = this.filters.subject.toLowerCase()
        list = list.filter(e => (e.subject || "").toLowerCase().includes(s))
      }
      if (this.filters.search) {
        const s = this.filters.search.toLowerCase()
        list = list.filter(e => (e.title || "").toLowerCase().includes(s))
      }

      return list
    }
  },
  methods: {
    defaultForm() {
      return {
        title: "",
        subject: "",
        classId: "",
        totalMarks: 0,
        durationMinutes: 0,
        startTimeText: "",
        endTimeText: "",
        isPublished: false,
        questions: []
      }
    },
    formatDate(ts) {
      if (!ts) return ""
      const d = ts.toDate ? ts.toDate() : new Date(ts)
      return d.toLocaleString()
    },
    async loadExams() {
      try {
        const q = query(
          collection(db, "objectiveExams"),
          orderBy("createdAt", "desc")
        )
        const snap = await getDocs(q)
        this.exams = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (e) {
        console.error("Error loading exams", e)
        alert("Failed to load objective exams")
      }
    },
    clearFilters() {
      this.filters = { classId: "", subject: "", search: "" }
    },
    openForm(exam) {
      this.error = ""
      if (exam) {
        this.editingId = exam.id
        this.form = {
          title: exam.title || "",
          subject: exam.subject || "",
          classId: exam.classId || "",
          totalMarks: exam.totalMarks || 0,
          durationMinutes: exam.durationMinutes || 0,
          startTimeText: exam.startTime
            ? exam.startTime.toDate().toISOString().slice(0, 16)
            : "",
          endTimeText: exam.endTime
            ? exam.endTime.toDate().toISOString().slice(0, 16)
            : "",
          isPublished: !!exam.isPublished,
          questions: (exam.questions || []).map(q => ({
            text: q.text || "",
            options: q.options && q.options.length === 4
              ? [...q.options]
              : ["", "", "", ""],
            correctIndex: q.correctIndex ?? 0,
            marks: q.marks ?? 1
          }))
        }
      } else {
        this.editingId = null
        this.form = this.defaultForm()
      }
      this.showForm = true
    },
    closeForm() {
      this.showForm = false
    },
    addQuestion() {
      this.form.questions.push({
        text: "",
        options: ["", "", "", ""],
        correctIndex: 0,
        marks: 1
      })
    },
    removeQuestion(index) {
      this.form.questions.splice(index, 1)
    },
    validate() {
      if (!this.form.title) {
        this.error = "Exam title is required."
        return false
      }
      if (!this.form.subject) {
        this.error = "Subject is required."
        return false
      }
      if (!this.form.classId) {
        this.error = "Class is required."
        return false
      }
      if (this.form.questions.length === 0) {
        this.error = "Add at least one question."
        return false
      }
      for (const [idx, q] of this.form.questions.entries()) {
        if (!q.text.trim()) {
          this.error = `Question ${idx + 1}: text is required.`
          return false
        }
        if (q.options.some(opt => !opt || !opt.trim())) {
          this.error = `Question ${idx + 1}: all 4 options are required.`
          return false
        }
      }
      this.error = ""
      return true
    },
    async saveExam() {
      if (!this.validate()) return

      this.saving = true
      try {
        let startTime = null
        let endTime = null
        if (this.form.startTimeText) {
          startTime = new Date(this.form.startTimeText)
        }
        if (this.form.endTimeText) {
          endTime = new Date(this.form.endTimeText)
        }

        const payload = {
          title: this.form.title.trim(),
          subject: this.form.subject.trim(),
          classId: this.form.classId,
          totalMarks: Number(this.form.totalMarks) || 0,
          durationMinutes: Number(this.form.durationMinutes) || 0,
          startTime: startTime,
          endTime: endTime,
          isPublished: !!this.form.isPublished,
          questions: this.form.questions.map(q => ({
            text: q.text.trim(),
            options: q.options.map(o => o.trim()),
            correctIndex: Number(q.correctIndex) || 0,
            marks: Number(q.marks) || 1
          })),
          updatedAt: serverTimestamp()
        }

        if (this.editingId) {
          const ref = doc(db, "objectiveExams", this.editingId)
          await setDoc(ref, payload, { merge: true })
        } else {
          await addDoc(collection(db, "objectiveExams"), {
            ...payload,
            createdAt: serverTimestamp()
          })
        }

        await this.loadExams()
        this.showForm = false
      } catch (e) {
        console.error("Error saving exam", e)
        alert("Failed to save exam")
      } finally {
        this.saving = false
      }
    },
    async deleteExam(exam) {
      if (!confirm(`Delete exam "${exam.title}"?`)) return
      try {
        await deleteDoc(doc(db, "objectiveExams", exam.id))
        this.exams = this.exams.filter(e => e.id !== exam.id)
      } catch (e) {
        console.error("Error deleting exam", e)
        alert("Failed to delete exam")
      }
    }
  },
  mounted() {
    this.loadExams()
  }
}
</script>

<style scoped>
.objective-page {
  min-height: 100vh;
  padding: 1.5rem;
  background: #f3f4f6;
  display: flex;
  justify-content: center;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}
.card {
  width: 100%;
  max-width: 1150px;
  background: #ffffff;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
  padding: 1rem 1.25rem 1.25rem;
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.06);
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}
.card-header h2 {
  margin: 0;
  font-size: 1.3rem;
  font-weight: 600;
}
.card-header p {
  margin: 0.2rem 0 0;
  color: #6b7280;
  font-size: 0.82rem;
}

/* Buttons */
.btn {
  border-radius: 999px;
  padding: 0.35rem 0.9rem;
  font-size: 0.8rem;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  transition: all 0.15s ease;
}
.btn.primary {
  background: #2563eb;
  color: #ffffff;
}
.btn.primary:hover {
  filter: brightness(1.05);
}
.btn.ghost {
  background: #f9fafb;
  color: #374151;
  border: 1px solid #d1d5db;
}
.btn.ghost:hover {
  background: #e5e7eb;
}
.btn.small {
  padding: 0.3rem 0.75rem;
  font-size: 0.78rem;
}

/* Filters */
.filters {
  display: flex;
  gap: 0.75rem;
  align-items: flex-end;
  margin-bottom: 0.7rem;
  border-top: 1px solid #e5e7eb;
  padding-top: 0.6rem;
}
.field {
  flex: 1;
  display: flex;
  flex-direction: column;
}
.field label {
  font-size: 0.78rem;
  color: #6b7280;
  margin-bottom: 0.2rem;
}
.field input,
.field select,
.field textarea {
  padding: 0.35rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.82rem;
}
.field textarea {
  resize: vertical;
}

/* Summary */
.summary {
  display: flex;
  gap: 1rem;
  margin-bottom: 0.6rem;
}
.summary-item {
  background: #f9fafb;
  border-radius: 0.6rem;
  padding: 0.5rem 0.7rem;
  border: 1px solid #e5e7eb;
  min-width: 140px;
}
.summary-label {
  display: block;
  font-size: 0.76rem;
  color: #6b7280;
}
.summary-value {
  font-size: 0.95rem;
  font-weight: 600;
  color: #111827;
}

/* Table */
.table-wrapper {
  overflow-x: auto;
}
.exams-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}
.exams-table thead {
  background: #f3f4f6;
}
.exams-table th,
.exams-table td {
  padding: 0.45rem 0.5rem;
  border-bottom: 1px solid #e5e7eb;
  text-align: left;
}
.exams-table th {
  font-weight: 600;
  color: #4b5563;
}

/* Status pill */
.status-pill {
  padding: 0.18rem 0.55rem;
  border-radius: 999px;
  font-size: 0.7rem;
  font-weight: 600;
}
.status-live {
  background: #dcfce7;
  color: #15803d;
}
.status-draft {
  background: #e5e7eb;
  color: #374151;
}

.link-btn {
  background: transparent;
  border: none;
  padding: 0;
  font-size: 0.78rem;
  color: #2563eb;
  cursor: pointer;
}
.link-btn.danger {
  color: #dc2626;
}

.empty-text {
  margin-top: 0.6rem;
  font-size: 0.85rem;
  color: #6b7280;
}

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 50;
}
.modal {
  background: #ffffff;
  padding: 1rem 1.1rem 1rem;
  border-radius: 0.7rem;
  width: 520px;
  max-width: 95%;
}
.modal-wide {
  width: 700px;
  max-width: 95%;
}
.modal h3 {
  margin: 0 0 0.6rem;
  font-size: 1.05rem;
  font-weight: 600;
}
.field-row {
  display: flex;
  gap: 0.7rem;
  margin-top: 0.4rem;
}
.modal .field {
  margin-top: 0.3rem;
}
.modal-actions {
  margin-top: 0.8rem;
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}
.error-text {
  margin-top: 0.4rem;
  font-size: 0.8rem;
  color: #dc2626;
}

/* Questions block */
.questions-block {
  margin-top: 0.8rem;
  border-top: 1px solid #e5e7eb;
  padding-top: 0.6rem;
}
.questions-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.questions-header h4 {
  margin: 0;
  font-size: 0.96rem;
}
.question-card {
  margin-top: 0.6rem;
  padding: 0.6rem 0.7rem;
  border-radius: 0.5rem;
  border: 1px solid #e5e7eb;
  background: #f9fafb;
}
.question-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.3rem;
  font-size: 0.8rem;
  font-weight: 600;
}
.empty-questions {
  margin-top: 0.4rem;
  font-size: 0.8rem;
  color: #6b7280;
}

@media (max-width: 768px) {
  .objective-page {
    padding: 1rem;
  }
  .filters {
    flex-direction: column;
    align-items: stretch;
  }
  .summary {
    flex-direction: column;
  }
  .field-row {
    flex-direction: column;
  }
}
</style>

