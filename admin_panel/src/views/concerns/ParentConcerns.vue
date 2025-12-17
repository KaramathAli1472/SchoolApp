<template>
  <div class="concerns-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>Parent Concerns</h2>
          <p>View and manage concerns submitted by parents</p>
        </div>
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
          <label>Status</label>
          <select v-model="filters.status">
            <option value="">All</option>
            <option value="open">Open</option>
            <option value="in_progress">In Progress</option>
            <option value="closed">Closed</option>
          </select>
        </div>

        <div class="field">
          <label>Search</label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Subject / Parent / Student"
          />
        </div>

        <button class="btn ghost" @click="clearFilters">Clear</button>
      </div>

      <!-- Summary -->
      <div class="summary" v-if="concerns.length">
        <div class="summary-item">
          <span class="summary-label">Total concerns</span>
          <span class="summary-value">{{ concerns.length }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Open</span>
          <span class="summary-value">
            {{ concerns.filter(c => c.status === 'open').length }}
          </span>
        </div>
        <div class="summary-item">
          <span class="summary-label">In Progress</span>
          <span class="summary-value">
            {{ concerns.filter(c => c.status === 'in_progress').length }}
          </span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Closed</span>
          <span class="summary-value">
            {{ concerns.filter(c => c.status === 'closed').length }}
          </span>
        </div>
      </div>

      <!-- Table -->
      <div v-if="filteredConcerns.length" class="table-wrapper">
        <table class="concerns-table">
          <thead>
            <tr>
              <th>Subject</th>
              <th>Parent</th>
              <th>Contact</th>
              <th>Student</th>
              <th>Class</th>
              <th>Status</th>
              <th>Created</th>
              <th style="width: 80px;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="c in filteredConcerns" :key="c.id">
              <td>{{ c.subject }}</td>
              <td>{{ c.parentName }}</td>
              <td>{{ c.contact }}</td>
              <td>{{ c.studentName }}</td>
              <td>{{ c.classId }}</td>
              <td>
                <span
                  class="status-pill"
                  :class="statusClass(c.status)"
                >
                  {{ statusLabel(c.status) }}
                </span>
              </td>
              <td>{{ formatDate(c.createdAt) }}</td>
              <td>
                <button class="link-btn" @click="openDetail(c)">
                  View
                </button>
                <button class="link-btn danger" @click="deleteConcern(c)">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <p v-else class="empty-text">
        No parent concerns found.
      </p>
    </div>

    <!-- Detail / Update modal -->
    <div v-if="showDetail" class="modal-backdrop">
      <div class="modal modal-wide">
        <h3>Parent Concern Detail</h3>

        <div class="detail-grid">
          <div class="detail-block">
            <h4>Student</h4>
            <p><strong>{{ selected.studentName }}</strong></p>
            <p>Class: {{ selected.classId }}</p>
            <p>ID: {{ selected.idNumber || '-' }}</p>
          </div>

          <div class="detail-block">
            <h4>Parent</h4>
            <p><strong>{{ selected.parentName }}</strong></p>
            <p>Contact: {{ selected.contact }}</p>
          </div>

          <div class="detail-block">
            <h4>Meta</h4>
            <p>Subject: {{ selected.subject }}</p>
            <p>Created: {{ formatDate(selected.createdAt) }}</p>
            <p>Last update: {{ formatDate(selected.updatedAt) }}</p>
          </div>
        </div>

        <div class="field">
          <label>Concern message</label>
          <textarea
            v-model="selected.message"
            rows="4"
            disabled
          ></textarea>
        </div>

        <div class="field-row">
          <div class="field">
            <label>Status</label>
            <select v-model="selected.status">
              <option value="open">Open</option>
              <option value="in_progress">In Progress</option>
              <option value="closed">Closed</option>
            </select>
          </div>
          <div class="field">
            <label>Admin notes (optional)</label>
            <textarea
              v-model="selected.adminNotes"
              rows="2"
              placeholder="Notes / action taken"
            ></textarea>
          </div>
        </div>

        <p v-if="error" class="error-text">{{ error }}</p>

        <div class="modal-actions">
          <button class="btn ghost" @click="closeDetail">Close</button>
          <button
            class="btn primary"
            :disabled="saving"
            @click="updateConcern"
          >
            {{ saving ? 'Saving...' : 'Save changes' }}
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
  doc,
  setDoc,
  deleteDoc,
  serverTimestamp,
  orderBy,
  query
} from "firebase/firestore" // [web:480][web:152]

export default {
  name: "ParentConcerns",
  data() {
    return {
      concerns: [],
      filters: {
        classId: "",
        status: "",
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
      showDetail: false,
      selected: {
        id: "",
        studentUid: "",
        studentName: "",
        classId: "",
        idNumber: "",
        parentName: "",
        contact: "",
        subject: "",
        message: "",
        status: "open",
        adminNotes: "",
        createdAt: null,
        updatedAt: null
      },
      saving: false,
      error: ""
    }
  },
  computed: {
    filteredConcerns() {
      let list = [...this.concerns]

      if (this.filters.classId) {
        list = list.filter(c => c.classId === this.filters.classId)
      }
      if (this.filters.status) {
        list = list.filter(c => c.status === this.filters.status)
      }
      if (this.filters.search) {
        const s = this.filters.search.toLowerCase()
        list = list.filter(c =>
          (c.subject || "").toLowerCase().includes(s) ||
          (c.parentName || "").toLowerCase().includes(s) ||
          (c.studentName || "").toLowerCase().includes(s)
        )
      }
      return list
    }
  },
  methods: {
    statusLabel(status) {
      if (status === "in_progress") return "In Progress"
      if (status === "closed") return "Closed"
      return "Open"
    },
    statusClass(status) {
      if (status === "in_progress") return "status-progress"
      if (status === "closed") return "status-closed"
      return "status-open"
    },
    formatDate(ts) {
      if (!ts) return "-"
      const d = ts.toDate ? ts.toDate() : new Date(ts)
      return d.toLocaleString()
    },
    clearFilters() {
      this.filters = { classId: "", status: "", search: "" }
    },
    async loadConcerns() {
      try {
        const q = query(
          collection(db, "parentConcerns"),
          orderBy("createdAt", "desc")
        )
        const snap = await getDocs(q)
        this.concerns = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (e) {
        console.error("Error loading parent concerns", e)
        alert("Failed to load parent concerns")
      }
    },
    openDetail(c) {
      this.error = ""
      this.selected = {
        id: c.id,
        studentUid: c.studentUid || "",
        studentName: c.studentName || "",
        classId: c.classId || "",
        idNumber: c.idNumber || "",
        parentName: c.parentName || "",
        contact: c.contact || "",
        subject: c.subject || "",
        message: c.message || "",
        status: c.status || "open",
        adminNotes: c.adminNotes || "",
        createdAt: c.createdAt || null,
        updatedAt: c.updatedAt || null
      }
      this.showDetail = true
    },
    closeDetail() {
      this.showDetail = false
    },
    async updateConcern() {
      if (!this.selected.id) return
      this.saving = true
      this.error = ""
      try {
        const ref = doc(db, "parentConcerns", this.selected.id)
        await setDoc(
          ref,
          {
            status: this.selected.status,
            adminNotes: this.selected.adminNotes || "",
            updatedAt: serverTimestamp()
          },
          { merge: true }
        )
        await this.loadConcerns()
        this.showDetail = false
      } catch (e) {
        console.error("Error updating concern", e)
        this.error = "Failed to update concern."
      } finally {
        this.saving = false
      }
    },
    async deleteConcern(c) {
      if (!confirm(`Delete concern "${c.subject}"?`)) return
      try {
        await deleteDoc(doc(db, "parentConcerns", c.id))
        this.concerns = this.concerns.filter(x => x.id !== c.id)
      } catch (e) {
        console.error("Error deleting concern", e)
        alert("Failed to delete concern")
      }
    }
  },
  mounted() {
    this.loadConcerns()
  }
}
</script>

<style scoped>
.concerns-page {
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
.concerns-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}
.concerns-table thead {
  background: #f3f4f6;
}
.concerns-table th,
.concerns-table td {
  padding: 0.45rem 0.5rem;
  border-bottom: 1px solid #e5e7eb;
  text-align: left;
}
.concerns-table th {
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
.status-open {
  background: #fee2e2;
  color: #b91c1c;
}
.status-progress {
  background: #fef3c7;
  color: #92400e;
}
.status-closed {
  background: #dcfce7;
  color: #15803d;
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
  width: 720px;
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

/* Detail layout */
.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 0.7rem;
  margin-bottom: 0.6rem;
}
.detail-block {
  background: #f9fafb;
  border-radius: 0.5rem;
  border: 1px solid #e5e7eb;
  padding: 0.5rem 0.7rem;
}
.detail-block h4 {
  margin: 0 0 0.25rem;
  font-size: 0.85rem;
  color: #374151;
}

@media (max-width: 768px) {
  .concerns-page {
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

