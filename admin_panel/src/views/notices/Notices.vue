<template>
  <div class="notices-page">
    <div class="notices-card">
      <!-- Top bar -->
      <div class="card-header">
        <div class="title-block">
          <div class="title-icon">📢</div>
          <div>
            <h2>Announcements</h2>
            <p>Announcements for students and classes</p>
          </div>
        </div>

        <div class="header-right">
          <select v-model="filterClass" class="class-filter">
            <option value="">All classes</option>
            <option
              v-for="cls in classOptions"
              :key="cls"
              :value="cls"
            >
              {{ cls }}
            </option>
          </select>

          <button class="btn primary" @click="toggleForm">
            {{ showForm ? 'Close' : '+ Add' }}
          </button>
        </div>
      </div>

      <!-- Add / Edit announcement -->
      <div v-if="showForm" class="add-area">
        <div class="field-row">
          <div class="field">
            <label>Title</label>
            <input
              v-model="form.title"
              type="text"
              placeholder="Announcement title"
            />
          </div>
          <div class="field">
            <label>Class (optional)</label>
            <input
              v-model="form.classId"
              type="text"
              placeholder="e.g. Class 7"
            />
          </div>
        </div>

        <div class="field">
          <label>Description</label>
          <textarea
            v-model="form.description"
            rows="2"
            placeholder="Write announcement details"
          ></textarea>
        </div>

        <div class="form-actions">
          <button class="btn primary" @click="saveNotice">
            {{ editingId ? 'Update' : 'Publish' }}
          </button>
          <button class="btn ghost" @click="resetForm">Clear</button>
        </div>
      </div>

      <!-- List -->
      <div class="list-header">
        <span class="list-title">Recent announcements</span>
        <span class="list-meta">{{ filteredNotices.length }} total</span>
      </div>

      <ul v-if="filteredNotices.length" class="notice-list">
        <li
          v-for="notice in filteredNotices"
          :key="notice.id"
          class="notice-row"
        >
          <div class="row-main">
            <div class="row-title">
              <span class="row-icon">🔔</span>
              <span class="title-text">{{ notice.title }}</span>
              <span class="class-badge">
                {{ notice.classId || 'All classes' }}
              </span>
            </div>
            <p class="row-desc">{{ notice.description }}</p>
          </div>

          <div class="row-meta">
            <span class="date-pill">{{ formatDate(notice.date) }}</span>

            <div
              v-if="isTeacherOrAdmin"
              class="row-actions"
            >
              <button
                class="icon-btn"
                title="Edit"
                @click="startEdit(notice)"
              >
                ✏️
              </button>
              <button
                class="icon-btn delete"
                title="Delete"
                @click="deleteNotice(notice)"
              >
                🗑
              </button>
            </div>
          </div>
        </li>
      </ul>

      <p v-else class="empty-text">No announcements found.</p>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  getDocs,
  doc,
  setDoc,
  deleteDoc
} from "firebase/firestore"   // [web:361][web:362]

export default {
  data() {
    return {
      notices: [],
      form: {
        title: "",
        description: "",
        classId: ""
      },
      showForm: false,
      editingId: null,
      filterClass: "",
      classOptions: [
        "Class 1", "Class 2", "Class 3", "Class 4", "Class 5",
        "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
      ],
      user: JSON.parse(localStorage.getItem("user")) || {}
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return ["teacher", "admin"].includes(this.user.role)
    },
    filteredNotices() {
      if (!this.filterClass) return this.notices
      return this.notices.filter(
        n => !n.classId || n.classId === this.filterClass
      )
    }
  },
  methods: {
    async fetchNotices() {
      const snap = await getDocs(collection(db, "notices"))
      this.notices = snap.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .sort((a, b) => new Date(b.date) - new Date(a.date))
    },
    formatDate(dateStr) {
      if (!dateStr) return "-"
      const d = new Date(dateStr)
      return d.toLocaleDateString()
    },
    toggleForm() {
      if (!this.isTeacherOrAdmin) {
        alert("Only teachers and admins can add announcements.")
        return
      }
      this.showForm = !this.showForm
      if (!this.showForm) {
        this.resetForm()
      }
    },
    resetForm() {
      this.form = { title: "", description: "", classId: "" }
      this.editingId = null
    },
    startEdit(notice) {
      if (!this.isTeacherOrAdmin) return
      this.form = {
        title: notice.title,
        description: notice.description,
        classId: notice.classId || ""
      }
      this.editingId = notice.id
      this.showForm = true
    },
    async saveNotice() {
      if (!this.isTeacherOrAdmin) {
        alert("Not allowed.")
        return
      }

      const { title, description, classId } = this.form
      if (!title || !description) {
        alert("Title and description are required.")
        return
      }

      const nowIso = new Date().toISOString()
      const id = this.editingId || Date.now().toString()
      const payload = {
        title,
        description,
        classId: classId || null,
        date: nowIso
      }

      const docRef = doc(db, "notices", id)
      await setDoc(docRef, payload)   // [web:247][web:351]

      if (this.editingId) {
        this.notices = this.notices.map(n =>
          n.id === id ? { id, ...payload } : n
        )
      } else {
        this.notices = [{ id, ...payload }, ...this.notices]
      }

      this.resetForm()
      this.showForm = false
    },
    async deleteNotice(notice) {
      if (!this.isTeacherOrAdmin) {
        alert("Not allowed.")
        return
      }
      if (!confirm("Delete this announcement?")) return

      const docRef = doc(db, "notices", notice.id)
      await deleteDoc(docRef)   // [web:361][web:368]

      this.notices = this.notices.filter(n => n.id !== notice.id)
    }
  },
  mounted() {
    this.fetchNotices()
  }
}
</script>

<style scoped>
.notices-page {
  min-height: 100vh;
  padding: 1rem;
  background: radial-gradient(circle at top left, #e0f2fe, #f5f5f7);
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #111827;
  display: flex;
  justify-content: center;
}

.notices-card {
  width: 100%;
  max-width: 880px;
  background: #ffffff;
  border-radius: 1rem;
  border: 1px solid #e5e7eb;
  padding: 0.9rem 1.1rem;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.08);
  border-left: 4px solid #2563eb;
}

/* Header */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.6rem;
}

.title-block {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.title-icon {
  width: 30px;
  height: 30px;
  border-radius: 999px;
  background: #eff6ff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
}

.card-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 650;
}

.card-header p {
  margin: 0.18rem 0 0;
  color: #6b7280;
  font-size: 0.8rem;
}

.header-right {
  display: flex;
  gap: 0.45rem;
  align-items: center;
}

.class-filter {
  padding: 0.28rem 0.6rem;
  border-radius: 999px;
  border: 1px solid #d1d5db;
  background: #ffffff;
  font-size: 0.8rem;
}

/* Buttons */
.btn {
  border-radius: 999px;
  padding: 0.33rem 0.85rem;
  font-size: 0.8rem;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  transition: all 0.15s ease;
}

.btn.primary {
  background: linear-gradient(135deg, #2563eb, #1d4ed8);
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

/* Add form */
.add-area {
  border-top: 1px solid #e5e7eb;
  padding-top: 0.7rem;
  margin-top: 0.35rem;
  margin-bottom: 0.6rem;
}

.field-row {
  display: flex;
  gap: 0.7rem;
  margin-bottom: 0.45rem;
}

.field {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.field label {
  font-size: 0.76rem;
  color: #6b7280;
  margin-bottom: 0.18rem;
}

.field input,
.field textarea {
  padding: 0.33rem 0.6rem;
  border-radius: 0.5rem;
  border: 1px solid #d1d5db;
  font-size: 0.8rem;
  resize: vertical;
  background: #f9fafb;
}

.field input:focus,
.field textarea:focus {
  outline: none;
  border-color: #2563eb;
  background: #ffffff;
  box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.16);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.4rem;
  margin-top: 0.35rem;
}

/* List */
.list-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-top: 0.2rem;
  margin-bottom: 0.25rem;
}

.list-title {
  font-size: 0.88rem;
  font-weight: 600;
}

.list-meta {
  font-size: 0.76rem;
  color: #6b7280;
}

.notice-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.notice-row {
  display: flex;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.55rem 0.55rem;
  border-radius: 0.7rem;
  border: 1px solid #e5e7eb;
  background: #f9fafb;
  margin-bottom: 0.38rem;
  transition: all 0.15s ease;
}

.notice-row:hover {
  background: #eef3ff;
  border-color: #c7d2fe;
}

.row-main {
  flex: 1;
}

.row-title {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.3rem;
}

.row-icon {
  font-size: 0.85rem;
}

.title-text {
  font-weight: 600;
  font-size: 0.9rem;
}

.class-badge {
  padding: 0.06rem 0.5rem;
  border-radius: 999px;
  background: #e0edff;
  color: #1d4ed8;
  font-size: 0.7rem;
}

.row-desc {
  margin: 0.22rem 0 0;
  font-size: 0.8rem;
  color: #374151;
}

.row-meta {
  min-width: 120px;
  text-align: right;
  font-size: 0.76rem;
  color: #6b7280;
}

.date-pill {
  display: inline-block;
  padding: 0.08rem 0.5rem;
  border-radius: 999px;
  background: #eef2ff;
  color: #4f46e5;
  font-size: 0.74rem;
}

/* Edit/Delete small icons */
.row-actions {
  margin-top: 0.28rem;
  display: flex;
  justify-content: flex-end;
  gap: 0.25rem;
}

.icon-btn {
  width: 22px;
  height: 22px;
  border-radius: 999px;
  border: 1px solid #d1d5db;
  background: #ffffff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 0.78rem;
  cursor: pointer;
  padding: 0;
}

.icon-btn.delete {
  border-color: #f97373;
}

.icon-btn:hover {
  background: #f3f4f6;
}

.empty-text {
  margin-top: 0.4rem;
  font-size: 0.84rem;
  color: #6b7280;
}

/* Responsive */
@media (max-width: 768px) {
  .notices-page {
    padding: 0.8rem;
  }
  .card-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.35rem;
  }
  .header-right {
    width: 100%;
    justify-content: flex-start;
  }
  .field-row {
    flex-direction: column;
  }
  .notice-row {
    flex-direction: column;
    align-items: flex-start;
  }
  .row-meta {
    text-align: left;
  }
}
</style>

