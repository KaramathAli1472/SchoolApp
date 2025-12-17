<template>
  <div class="class-diary-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>Class Diary</h2>
          <p>Daily summary for each class and subject</p>
        </div>

        <button
          v-if="isTeacherOrAdmin"
          class="btn primary"
          @click="toggleForm"
        >
          {{ showForm ? (editingId ? 'Close edit' : 'Close') : '+ Add diary entry' }}
        </button>
      </div>

      <!-- Filters row -->
      <div class="filters">
        <div class="field">
          <label>Class ID</label>
          <input
            v-model="filters.classId"
            type="text"
            placeholder="e.g. class_8A"
            @keyup.enter="fetchDiary"
          />
        </div>
        <div class="field">
          <label>Date</label>
          <input
            v-model="filters.date"
            type="date"
            @change="fetchDiary"
          />
        </div>
        <button class="btn ghost" @click="fetchDiary">Apply</button>
        <button class="btn ghost" @click="clearFilters">Clear</button>
      </div>

      <!-- Add / Edit form -->
      <div v-if="showForm" class="form-section">
        <div class="field-row">
          <div class="field">
            <label>Class ID</label>
            <input
              v-model="form.classId"
              type="text"
              placeholder="e.g. class_8A"
            />
          </div>
          <div class="field">
            <label>Date</label>
            <input
              v-model="form.date"
              type="date"
            />
          </div>
        </div>

        <div class="field-row">
          <div class="field">
            <label>Subject</label>
            <input
              v-model="form.subject"
              type="text"
              placeholder="e.g. Science"
            />
          </div>
          <div class="field">
            <label>Title</label>
            <input
              v-model="form.title"
              type="text"
              placeholder="Short heading of class"
            />
          </div>
        </div>

        <div class="field">
          <label>What was done in class</label>
          <textarea
            v-model="form.details"
            rows="3"
            placeholder="Topics covered, activities, important notes"
          ></textarea>
        </div>

        <div class="field">
          <label>Homework (optional)</label>
          <textarea
            v-model="form.homework"
            rows="2"
            placeholder="Homework summary if any"
          ></textarea>
        </div>

        <div class="form-actions">
          <button
            class="btn primary"
            :disabled="saving"
            @click="editingId ? updateDiary() : addDiary()"
          >
            {{ saving ? 'Saving...' : (editingId ? 'Update' : 'Save') }}
          </button>
          <button class="btn ghost" @click="resetForm">Clear</button>
        </div>
      </div>

      <!-- List -->
      <div v-if="entries.length" class="list">
        <article
          v-for="item in entries"
          :key="item.id"
          class="list-item"
        >
          <div class="list-main" @click="openDetail(item)">
            <div class="list-top">
              <h3>{{ item.title || (item.subject + ' - ' + formatDate(item.date)) }}</h3>
              <span class="pill">
                {{ item.classId }} • {{ item.subject }}
              </span>
            </div>

            <p class="desc">
              {{ shortText(item.details || '', 120) }}
            </p>

            <div class="meta">
              <span>
                {{ formatDate(item.date) }}
              </span>
              <span v-if="item.homework">
                • Homework added
              </span>
            </div>
          </div>

          <div v-if="isTeacherOrAdmin" class="list-actions">
            <button class="link-btn" @click.stop="startEdit(item)">Edit</button>
            <button class="link-btn danger" @click.stop="deleteDiary(item)">
              Delete
            </button>
          </div>
        </article>
      </div>

      <p v-else class="empty-text">No diary entries found.</p>
    </div>

    <!-- Detail modal -->
    <div v-if="detailItem" class="modal-backdrop" @click="closeDetail">
      <div class="modal-dialog" @click.stop>
        <button class="modal-close" @click="closeDetail">×</button>
        <div class="modal-body">
          <h3>
            {{ detailItem.title || (detailItem.subject + ' - ' + formatDate(detailItem.date)) }}
          </h3>
          <p class="modal-meta">
            {{ detailItem.classId }} • {{ detailItem.subject }} • {{ formatDate(detailItem.date) }}
          </p>

          <h4>Class work</h4>
          <p class="modal-text">
            {{ detailItem.details || 'No description provided.' }}
          </p>

          <h4 v-if="detailItem.homework">Homework</h4>
          <p v-if="detailItem.homework" class="modal-text">
            {{ detailItem.homework }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { db } from '../../services/firebase'
import {
  collection,
  getDocs,
  doc,
  setDoc,
  query,
  where,
  orderBy,
  deleteDoc
} from 'firebase/firestore'

export default {
  name: 'ClassDiary',
  data() {
    return {
      entries: [],
      showForm: false,
      saving: false,
      form: {
        classId: '',
        date: '',
        subject: '',
        title: '',
        details: '',
        homework: ''
      },
      filters: {
        classId: '',
        date: ''
      },
      editingId: null,
      detailItem: null,
      user: JSON.parse(localStorage.getItem('user') || '{}')
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return ['teacher', 'admin', 'superadmin'].includes(this.user.role)
    }
  },
  methods: {
    async fetchDiary() {
      try {
        const baseCol = collection(db, 'classDiary')

        // Filter sirf UI se aayega
        const classFilter = this.filters.classId
        const dateFilter = this.filters.date

        let q
        if (classFilter) {
          // where + single orderBy => composite index nahi chahiye
          q = query(
            baseCol,
            where('classId', '==', classFilter),
            orderBy('date', 'desc')
          )
        } else {
          // saare diary entries date ke hisab se
          q = query(baseCol, orderBy('date', 'desc'))
        }

        const snap = await getDocs(q)
        let data = snap.docs.map(d => ({ id: d.id, ...d.data() }))

        // date string filter client-side
        if (dateFilter) {
          data = data.filter(item => item.date === dateFilter)
        }

        this.entries = data
      } catch (e) {
        console.error('Error loading class diary', e)
        alert('Failed to load class diary: ' + (e.message || e))
      }
    },
    toggleForm() {
      if (!this.isTeacherOrAdmin) {
        alert('Only teachers and admins can manage class diary.')
        return
      }
      this.showForm = !this.showForm
      if (!this.showForm) this.resetForm()
    },
    resetForm() {
      this.form = {
        classId: this.user.classId || '',
        date: new Date().toISOString().slice(0, 10),
        subject: '',
        title: '',
        details: '',
        homework: ''
      }
      this.saving = false
      this.editingId = null
    },
    validateForm() {
      if (!this.form.classId) {
        alert('Class ID is required.')
        return false
      }
      if (!this.form.date) {
        alert('Date is required.')
        return false
      }
      if (!this.form.subject) {
        alert('Subject is required.')
        return false
      }
      if (!this.form.details) {
        alert('Please enter class work details.')
        return false
      }
      return true
    },
    async addDiary() {
      if (!this.isTeacherOrAdmin) return
      if (!this.validateForm()) return

      this.saving = true
      try {
        const id = Date.now().toString()
        const payload = {
          classId: this.form.classId,
          date: this.form.date,
          subject: this.form.subject,
          title: this.form.title || '',
          details: this.form.details || '',
          homework: this.form.homework || '',
          createdAt: new Date().toISOString(),
          createdBy: this.user?.uid || 'admin'
        }
        const ref = doc(db, 'classDiary', id)
        await setDoc(ref, payload)

        this.entries = [{ id, ...payload }, ...this.entries]
        this.resetForm()
        this.showForm = false
        alert('Diary entry added')
      } catch (e) {
        console.error('Add diary error', e)
        alert('Failed to add diary entry: ' + (e.message || e))
      } finally {
        this.saving = false
      }
    },
    startEdit(item) {
      if (!this.isTeacherOrAdmin) return
      this.editingId = item.id
      this.form = {
        classId: item.classId || '',
        date: item.date || '',
        subject: item.subject || '',
        title: item.title || '',
        details: item.details || '',
        homework: item.homework || ''
      }
      this.showForm = true
    },
    async updateDiary() {
      if (!this.editingId) return
      if (!this.validateForm()) return

      this.saving = true
      try {
        const current = this.entries.find(e => e.id === this.editingId)
        const payload = {
          classId: this.form.classId,
          date: this.form.date,
          subject: this.form.subject,
          title: this.form.title || '',
          details: this.form.details || '',
          homework: this.form.homework || '',
          createdAt: current?.createdAt || new Date().toISOString(),
          createdBy: current?.createdBy || this.user?.uid || 'admin'
        }
        const ref = doc(db, 'classDiary', this.editingId)
        await setDoc(ref, payload)

        this.entries = this.entries.map(e =>
          e.id === this.editingId ? { id: this.editingId, ...payload } : e
        )
        this.resetForm()
        this.showForm = false
        alert('Diary entry updated')
      } catch (e) {
        console.error('Update diary error', e)
        alert('Failed to update diary entry: ' + (e.message || e))
      } finally {
        this.saving = false
      }
    },
    async deleteDiary(item) {
      if (!this.isTeacherOrAdmin) return
      if (!confirm('Delete this diary entry?')) return
      try {
        await deleteDoc(doc(db, 'classDiary', item.id))
        this.entries = this.entries.filter(e => e.id !== item.id)
        alert('Diary entry deleted')
      } catch (e) {
        console.error('Delete diary error', e)
        alert('Failed to delete diary entry: ' + (e.message || e))
      }
    },
    openDetail(item) {
      this.detailItem = item
    },
    closeDetail() {
      this.detailItem = null
    },
    formatDate(dateStr) {
      if (!dateStr) return '-'
      const d = new Date(dateStr)
      if (isNaN(d)) return dateStr
      const day = String(d.getDate()).padStart(2, '0')
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const year = d.getFullYear()
      return `${day}/${month}/${year}`
    },
    shortText(text, max) {
      if (!text) return ''
      return text.length > max ? text.slice(0, max) + '…' : text
    },
    clearFilters() {
      this.filters = {
        classId: '',
        date: ''
      }
      this.fetchDiary()
    }
  },
  mounted() {
    // default: koi filter nahi, sab diary load
    this.fetchDiary()
    this.resetForm()
  }
}
</script>

<style scoped>
/* tumhara CSS jaisa already hai, same rakha hai */
.class-diary-page {
  min-height: 100vh;
  padding: 1.5rem;
  background: #f3f4f6;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  color: #111827;
  display: flex;
  justify-content: center;
}
.card {
  width: 100%;
  max-width: 980px;
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
  margin-bottom: 0.8rem;
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
  background: #1d4ed8;
}
.btn.ghost {
  background: #f9fafb;
  color: #374151;
  border: 1px solid #d1d5db;
}
.btn.ghost:hover {
  background: #e5e7eb;
}

/* Filters */
.filters {
  display: flex;
  gap: 0.75rem;
  align-items: flex-end;
  margin-bottom: 0.6rem;
  border-top: 1px solid #e5e7eb;
  padding-top: 0.6rem;
}
.field-row {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
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
.field textarea,
.field select {
  padding: 0.35rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.82rem;
}
.field input:focus,
.field textarea:focus,
.field select:focus {
  outline: none;
  border-color: #2563eb;
  box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.15);
}

.form-section {
  border-top: 1px solid #e5e7eb;
  padding-top: 0.8rem;
  margin-top: 0.4rem;
  margin-bottom: 0.8rem;
}
.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.4rem;
  margin-top: 0.4rem;
}

/* List */
.list {
  margin-top: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.list-item {
  padding: 0.6rem 0.7rem;
  border-radius: 0.55rem;
  border: 1px solid #e5e7eb;
  background: #f9fafb;
  display: flex;
  justify-content: space-between;
  gap: 0.5rem;
}
.list-main {
  flex: 1;
  cursor: pointer;
}
.list-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.4rem;
}
.list-main h3 {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
}
.list-main .desc {
  margin: 0.25rem 0;
  font-size: 0.8rem;
  color: #4b5563;
}
.meta {
  font-size: 0.75rem;
  color: #6b7280;
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}
.pill {
  padding: 0.05rem 0.5rem;
  border-radius: 999px;
  background: #e5e7eb;
  font-size: 0.72rem;
}
.list-actions {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  align-items: flex-end;
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
  background: rgba(15, 23, 42, 0.65);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 40;
}
.modal-dialog {
  background: #ffffff;
  border-radius: 0.75rem;
  max-width: 560px;
  width: 95%;
  max-height: 80vh;
  overflow: auto;
  position: relative;
}
.modal-close {
  position: absolute;
  top: 0.35rem;
  right: 0.5rem;
  border: none;
  background: transparent;
  font-size: 1.4rem;
  line-height: 1;
  cursor: pointer;
}
.modal-body {
  padding: 0.9rem 1rem 1rem;
}
.modal-body h3 {
  margin: 0 0 0.2rem;
  font-size: 1.1rem;
  font-weight: 600;
}
.modal-meta {
  margin: 0 0 0.6rem;
  font-size: 0.82rem;
  color: #6b7280;
}
.modal-body h4 {
  margin: 0.6rem 0 0.2rem;
  font-size: 0.9rem;
  font-weight: 600;
}
.modal-text {
  margin: 0;
  font-size: 0.9rem;
  color: #374151;
  white-space: pre-line;
}

@media (max-width: 768px) {
  .class-diary-page {
    padding: 1rem;
  }
  .card-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  .filters {
    flex-direction: column;
    align-items: stretch;
  }
  .field-row {
    flex-direction: column;
  }
}
</style>
