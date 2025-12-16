<template>
  <div class="ptm-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>PTM Feedback</h2>
          <p>Parents' feedback for Parent-Teacher Meetings</p>
        </div>
      </div>

      <!-- Filters -->
      <div class="filters">
        <div class="field">
          <label>Class</label>
          <input
            v-model="filters.classId"
            type="text"
            placeholder="e.g. class_8A"
            @keyup.enter="loadFeedback"
          />
        </div>
        <div class="field">
          <label>Meeting ID</label>
          <input
            v-model="filters.meetingId"
            type="text"
            placeholder="e.g. 2025-01-10_class_8A"
            @keyup.enter="loadFeedback"
          />
        </div>
        <button class="btn ghost" @click="loadFeedback">Apply</button>
        <button class="btn ghost" @click="clearFilters">Clear</button>
      </div>

      <!-- Summary -->
      <div class="summary" v-if="feedback.length">
        <div class="summary-item">
          <span class="summary-label">Total feedback</span>
          <span class="summary-value">{{ feedback.length }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Average rating</span>
          <span class="summary-value">
            {{ averageRating.toFixed(1) }}
            <span class="stars">
              <span v-for="i in 5" :key="i" class="star">
                {{ i <= Math.round(averageRating) ? '★' : '☆' }}
              </span>
            </span>
          </span>
        </div>
      </div>

      <!-- Table -->
      <div v-if="feedback.length" class="table-wrapper">
        <table class="feedback-table">
          <thead>
            <tr>
              <th>Meeting ID</th>
              <th>Class</th>
              <th>Student ID</th>
              <th>Rating</th>
              <th>Comment</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in feedback" :key="row.id">
              <td>{{ row.meetingId }}</td>
              <td>{{ row.classId }}</td>
              <td>{{ row.studentId || '-' }}</td>
              <td>
                <span class="rating-pill">
                  {{ row.rating }} / 5
                </span>
              </td>
              <td class="comment-cell">
                {{ row.comment }}
              </td>
              <td>{{ formatDate(row.createdAt) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <p v-else class="empty-text">No feedback found for selected filters.</p>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  getDocs,
  query,
  where,
  orderBy
} from "firebase/firestore"  // [web:162][web:374]

export default {
  name: "PTMFeedback",
  data() {
    return {
      feedback: [],
      filters: {
        classId: "",
        meetingId: ""
      },
      loading: false
    }
  },
  computed: {
    averageRating() {
      if (!this.feedback.length) return 0
      const sum = this.feedback.reduce((acc, f) => acc + (Number(f.rating) || 0), 0)
      return sum / this.feedback.length
    }
  },
  methods: {
    async loadFeedback() {
      this.loading = true
      try {
        let q = collection(db, "ptmFeedback")

        const conditions = []
        if (this.filters.classId) {
          conditions.push(where("classId", "==", this.filters.classId))
        }
        if (this.filters.meetingId) {
          conditions.push(where("meetingId", "==", this.filters.meetingId))
        }

        if (conditions.length) {
          q = query(q, ...conditions, orderBy("createdAt", "desc"))
        } else {
          q = query(q, orderBy("createdAt", "desc"))
        }

        const snap = await getDocs(q)
        this.feedback = snap.docs.map(d => ({
          id: d.id,
          ...d.data()
        }))
      } catch (e) {
        console.error("Error loading PTM feedback", e)
        alert("Failed to load PTM feedback: " + (e.message || e))
      } finally {
        this.loading = false
      }
    },
    clearFilters() {
      this.filters = {
        classId: "",
        meetingId: ""
      }
      this.loadFeedback()
    },
    formatDate(ts) {
      if (!ts) return "-"
      const d = ts.toDate ? ts.toDate() : new Date(ts)
      const day = String(d.getDate()).padStart(2, "0")
      const month = String(d.getMonth() + 1).padStart(2, "0")
      const year = d.getFullYear()
      return `${day}/${month}/${year}`
    }
  },
  mounted() {
    this.loadFeedback()
  }
}
</script>

<style scoped>
.ptm-page {
  min-height: 100vh;
  padding: 1.5rem;
  background: #f3f4f6;
  display: flex;
  justify-content: center;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.card {
  width: 100%;
  max-width: 1000px;
  background: #ffffff;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
  padding: 1rem 1.25rem 1.25rem;
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.06);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
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
.field input {
  padding: 0.35rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.82rem;
}
.field input:focus {
  outline: none;
  border-color: #2563eb;
  box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.15);
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
.btn.ghost {
  background: #f9fafb;
  color: #374151;
  border: 1px solid #d1d5db;
}
.btn.ghost:hover {
  background: #e5e7eb;
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
.stars {
  margin-left: 0.25rem;
  font-size: 0.8rem;
  color: #f59e0b;
}
.star {
  margin-left: 1px;
}

/* Table */
.table-wrapper {
  overflow-x: auto;
}
.feedback-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}
.feedback-table thead {
  background: #f3f4f6;
}
.feedback-table th,
.feedback-table td {
  padding: 0.45rem 0.5rem;
  border-bottom: 1px solid #e5e7eb;
  text-align: left;
}
.feedback-table th {
  font-weight: 600;
  color: #4b5563;
}
.comment-cell {
  max-width: 320px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.rating-pill {
  display: inline-block;
  padding: 0.08rem 0.45rem;
  border-radius: 999px;
  background: #fef3c7;
  color: #92400e;
  font-size: 0.75rem;
}

.empty-text {
  margin-top: 0.6rem;
  font-size: 0.85rem;
  color: #6b7280;
}

@media (max-width: 768px) {
  .ptm-page {
    padding: 1rem;
  }
  .filters {
    flex-direction: column;
    align-items: stretch;
  }
  .summary {
    flex-direction: column;
  }
}
</style>

