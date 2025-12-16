<template>
  <div class="achievements-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>Achievements</h2>
          <p>School and student achievements</p>
        </div>

        <button
          v-if="isTeacherOrAdmin"
          class="btn primary"
          @click="toggleForm"
        >
          {{ showForm ? (editingId ? 'Close edit' : 'Close') : '+ Add achievement' }}
        </button>
      </div>

      <!-- Add / Edit form -->
      <div v-if="showForm" class="form-section">
        <div class="field-row">
          <div class="field">
            <label>Title</label>
            <input
              v-model="form.title"
              type="text"
              placeholder="e.g. State Level Science Fair 1st Prize"
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
            <label>Type</label>
            <select v-model="form.type">
              <option value="school">School</option>
              <option value="student">Student</option>
              <option value="sports">Sports</option>
              <option value="cultural">Cultural</option>
            </select>
          </div>
          <div class="field">
            <label>Student name (optional)</label>
            <input
              v-model="form.studentName"
              type="text"
              placeholder="e.g. Rahul Sharma"
            />
          </div>
        </div>

        <div class="field">
          <label>Class / Section (optional)</label>
          <input
            v-model="form.className"
            type="text"
            placeholder="e.g. 8-A"
          />
        </div>

        <div class="field">
          <label>Description</label>
          <textarea
            v-model="form.description"
            rows="2"
            placeholder="Short description of the achievement"
          ></textarea>
        </div>

        <div class="form-actions">
          <button
            class="btn primary"
            :disabled="saving"
            @click="editingId ? updateAchievement() : addAchievement()"
          >
            {{ saving ? 'Saving...' : (editingId ? 'Update' : 'Save') }}
          </button>
          <button class="btn ghost" @click="resetForm">Clear</button>
        </div>
      </div>

      <!-- List -->
      <div v-if="achievements.length" class="list">
        <article
          v-for="item in achievements"
          :key="item.id"
          class="list-item"
        >
          <div class="list-main" @click="openDetail(item)">
            <h3>{{ item.title }}</h3>
            <p v-if="item.description" class="desc">
              {{ item.description }}
            </p>
            <div class="meta">
              <span v-if="item.date">
                {{ formatDate(item.date) }}
              </span>
              <span v-if="item.type" class="pill">
                {{ item.type }}
              </span>
              <span v-if="item.studentName">
                • {{ item.studentName }}
              </span>
              <span v-if="item.className">
                • {{ item.className }}
              </span>
            </div>
          </div>

          <div v-if="isTeacherOrAdmin" class="list-actions">
            <button class="link-btn" @click.stop="startEdit(item)">Edit</button>
            <button class="link-btn danger" @click.stop="deleteAchievement(item)">
              Delete
            </button>
          </div>
        </article>
      </div>

      <p v-else class="empty-text">No achievements added yet.</p>
    </div>

    <!-- Detail modal (read-only) -->
    <div v-if="detailItem" class="modal-backdrop" @click="closeDetail">
      <div class="modal-dialog" @click.stop>
        <button class="modal-close" @click="closeDetail">×</button>
        <div class="modal-body">
          <h3>{{ detailItem.title }}</h3>
          <p class="modal-date" v-if="detailItem.date">
            {{ formatDate(detailItem.date) }}
          </p>
          <p class="modal-tags">
            <span v-if="detailItem.type" class="pill pill-primary">
              {{ detailItem.type }}
            </span>
            <span v-if="detailItem.studentName">
              • {{ detailItem.studentName }}
            </span>
            <span v-if="detailItem.className">
              • {{ detailItem.className }}
            </span>
          </p>
          <p v-if="detailItem.description" class="modal-desc">
            {{ detailItem.description }}
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
  orderBy,
  deleteDoc
} from 'firebase/firestore'

export default {
  data() {
    return {
      achievements: [],
      showForm: false,
      saving: false,
      form: {
        title: '',
        description: '',
        date: '',
        type: 'school',
        studentName: '',
        className: ''
      },
      editingId: null,
      detailItem: null,
      user: JSON.parse(localStorage.getItem('user') || '{}')
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return ['teacher', 'admin'].includes(this.user.role)
    }
  },
  methods: {
    async fetchAchievements() {
      try {
        const q = query(
          collection(db, 'achievements'),
          orderBy('createdAt', 'desc')
        )
        const snap = await getDocs(q)
        this.achievements = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (e) {
        console.error('Error loading achievements', e)
        alert('Failed to load achievements: ' + (e.message || e))
      }
    },
    toggleForm() {
      if (!this.isTeacherOrAdmin) {
        alert('Only teachers and admins can manage achievements.')
        return
      }
      this.showForm = !this.showForm
      if (!this.showForm) this.resetForm()
    },
    resetForm() {
      this.form = {
        title: '',
        description: '',
        date: '',
        type: 'school',
        studentName: '',
        className: ''
      }
      this.saving = false
      this.editingId = null
    },
    async addAchievement() {
      if (!this.isTeacherOrAdmin) return
      if (!this.form.title) {
        alert('Title is required.')
        return
      }
      if (!this.form.date) {
        alert('Date is required.')
        return
      }

      this.saving = true
      try {
        const id = Date.now().toString()
        const payload = {
          title: this.form.title,
          description: this.form.description || '',
          date: this.form.date,
          type: this.form.type || 'school',
          studentName: this.form.studentName || '',
          className: this.form.className || '',
          createdAt: new Date().toISOString(),
          createdBy: this.user?.uid || 'admin'
        }
        const ref = doc(db, 'achievements', id)
        await setDoc(ref, payload)

        this.achievements = [{ id, ...payload }, ...this.achievements]
        this.resetForm()
        this.showForm = false
        alert('Achievement added')
      } catch (e) {
        console.error('Add achievement error', e)
        alert('Failed to add achievement: ' + (e.message || e))
      } finally {
        this.saving = false
      }
    },
    startEdit(item) {
      if (!this.isTeacherOrAdmin) return
      this.editingId = item.id
      this.form = {
        title: item.title || '',
        description: item.description || '',
        date: item.date || '',
        type: item.type || 'school',
        studentName: item.studentName || '',
        className: item.className || ''
      }
      this.showForm = true
    },
    async updateAchievement() {
      if (!this.editingId) return
      if (!this.form.title) {
        alert('Title is required.')
        return
      }
      if (!this.form.date) {
        alert('Date is required.')
        return
      }

      this.saving = true
      try {
        const current = this.achievements.find(a => a.id === this.editingId)
        const payload = {
          title: this.form.title,
          description: this.form.description || '',
          date: this.form.date,
          type: this.form.type || 'school',
          studentName: this.form.studentName || '',
          className: this.form.className || '',
          createdAt: current?.createdAt || new Date().toISOString(),
          createdBy: current?.createdBy || this.user?.uid || 'admin'
        }
        const ref = doc(db, 'achievements', this.editingId)
        await setDoc(ref, payload)

        this.achievements = this.achievements.map(a =>
          a.id === this.editingId ? { id: this.editingId, ...payload } : a
        )
        this.resetForm()
        this.showForm = false
        alert('Achievement updated')
      } catch (e) {
        console.error('Update achievement error', e)
        alert('Failed to update achievement: ' + (e.message || e))
      } finally {
        this.saving = false
      }
    },
    async deleteAchievement(item) {
      if (!this.isTeacherOrAdmin) return
      if (!confirm('Delete this achievement?')) return
      try {
        await deleteDoc(doc(db, 'achievements', item.id))
        this.achievements = this.achievements.filter(a => a.id !== item.id)
        alert('Achievement deleted')
      } catch (e) {
        console.error('Delete achievement error', e)
        alert('Failed to delete achievement: ' + (e.message || e))
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
      let day = d.getDate()
      let month = d.getMonth() + 1
      const year = d.getFullYear()
      day = day < 10 ? '0' + day : '' + day
      month = month < 10 ? '0' + month : '' + month
      return `${day}/${month}/${year}`
    }
  },
  mounted() {
    this.fetchAchievements()
  }
}
</script>

<style scoped>
.achievements-page {
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
  max-width: 900px;
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

.form-section {
  border-top: 1px solid #e5e7eb;
  padding-top: 0.8rem;
  margin-top: 0.4rem;
  margin-bottom: 0.8rem;
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

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.4rem;
  margin-top: 0.4rem;
}

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

.list-main h3 {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
}

.list-main .desc {
  margin: 0.2rem 0;
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

.pill-primary {
  background: #2563eb;
  color: #ffffff;
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
  max-width: 520px;
  width: 95%;
  max-height: 80vh;
  overflow: hidden;
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

.modal-date {
  margin: 0;
  font-size: 0.82rem;
  color: #6b7280;
}

.modal-tags {
  margin: 0.35rem 0 0.3rem;
  font-size: 0.8rem;
  color: #4b5563;
}

.modal-desc {
  margin: 0;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .achievements-page {
    padding: 1rem;
  }
  .card-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  .field-row {
    flex-direction: column;
  }
}
</style>

