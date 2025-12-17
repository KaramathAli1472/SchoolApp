<template>
  <div class="gatepass-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>Gate Pass Requests</h2>
          <p>Review and approve student gate pass requests</p>
        </div>
        <button class="btn primary" @click="openCreate">
          + New Gate Pass
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
          <label>Status</label>
          <select v-model="filters.status">
            <option value="">All</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="used">Used</option>
          </select>
        </div>

        <div class="field">
          <label>Search</label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Student / ID / Reason"
          />
        </div>

        <button class="btn ghost" @click="clearFilters">Clear</button>
      </div>

      <!-- Summary -->
      <div class="summary" v-if="requests.length">
        <div class="summary-item">
          <span class="summary-label">Total requests</span>
          <span class="summary-value">{{ requests.length }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Pending</span>
          <span class="summary-value">
            {{ requests.filter(r => r.status === 'pending').length }}
          </span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Approved</span>
          <span class="summary-value">
            {{ requests.filter(r => r.status === 'approved').length }}
          </span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Rejected</span>
          <span class="summary-value">
            {{ requests.filter(r => r.status === 'rejected').length }}
          </span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Used</span>
          <span class="summary-value">
            {{ requests.filter(r => r.status === 'used').length }}
          </span>
        </div>
      </div>

      <!-- Table -->
      <div v-if="filteredRequests.length" class="table-wrapper">
        <table class="gatepass-table">
          <thead>
            <tr>
              <th>Student</th>
              <th>Class</th>
              <th>ID / Roll</th>
              <th>Reason</th>
              <th>From</th>
              <th>To</th>
              <th>Status</th>
              <th>Requested</th>
              <th style="width: 90px;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in filteredRequests" :key="r.id">
              <td>{{ r.studentName }}</td>
              <td>{{ r.classId }}</td>
              <td>{{ r.idNumber }}</td>
              <td>{{ r.reason }}</td>
              <td>{{ formatDate(r.fromDateTime) }}</td>
              <td>{{ formatDate(r.toDateTime) }}</td>
              <td>
                <span
                  class="status-pill"
                  :class="statusClass(r.status)"
                >
                  {{ statusLabel(r.status) }}
                </span>
              </td>
              <td>{{ formatDate(r.createdAt) }}</td>
              <td>
                <button class="link-btn" @click="openDetail(r)">View</button>
                <button class="link-btn danger" @click="deleteRequest(r)">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <p v-else class="empty-text">
        No gate pass requests found.
      </p>
    </div>

    <!-- Detail / Update modal -->
    <div v-if="showDetail" class="modal-backdrop">
      <div class="modal modal-wide">
        <h3>Gate Pass Detail</h3>

        <div class="detail-grid">
          <div class="detail-block">
            <h4>Student</h4>
            <p><strong>{{ selected.studentName }}</strong></p>
            <p>Class: {{ selected.classId }}</p>
            <p>ID: {{ selected.idNumber || '-' }}</p>
          </div>

          <div class="detail-block">
            <h4>Request</h4>
            <p>Reason: {{ selected.reason }}</p>
            <p>From: {{ formatDate(selected.fromDateTime) }}</p>
            <p>To: {{ formatDate(selected.toDateTime) }}</p>
          </div>

          <div class="detail-block">
            <h4>Meta</h4>
            <p>Requested by: {{ selected.requestedBy || 'parent' }}</p>
            <p>Created: {{ formatDate(selected.createdAt) }}</p>
            <p>Last update: {{ formatDate(selected.updatedAt) }}</p>
          </div>
        </div>

        <div class="field">
          <label>Current status</label>
          <select v-model="selected.status">
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="used">Used</option>
          </select>
        </div>

        <div class="field">
          <label>Approval notes (optional)</label>
          <textarea
            v-model="selected.approvalNotes"
            rows="2"
            placeholder="E.g. Allowed to leave with parent, time, remarks"
          ></textarea>
        </div>

        <p v-if="error" class="error-text">{{ error }}</p>

        <div class="modal-actions">
          <button class="btn ghost" @click="closeDetail">Close</button>
          <button
            class="btn primary"
            :disabled="saving"
            @click="updateRequest"
          >
            {{ saving ? 'Saving...' : 'Save changes' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Create Gate Pass modal -->
    <div v-if="showCreate" class="modal-backdrop">
      <div class="modal modal-wide">
        <h3>Create Gate Pass</h3>

        <div class="field-row">
          <div class="field">
            <label>Student name</label>
            <input
              v-model="createForm.studentName"
              type="text"
              placeholder="Student name"
            />
          </div>
          <div class="field">
            <label>Class</label>
            <select v-model="createForm.classId">
              <option disabled value="">Select class</option>
              <option v-for="cls in classOptions" :key="cls" :value="cls">
                {{ cls }}
              </option>
            </select>
          </div>
        </div>

        <div class="field-row">
          <div class="field">
            <label>ID / Roll No</label>
            <input
              v-model="createForm.idNumber"
              type="text"
              placeholder="e.g. 23 / GR123"
            />
          </div>
          <div class="field">
            <label>Requested by</label>
            <select v-model="createForm.requestedBy">
              <option value="parent">Parent</option>
              <option value="student">Student</option>
            </select>
          </div>
        </div>

        <div class="field">
          <label>Reason</label>
          <input
            v-model="createForm.reason"
            type="text"
            placeholder="Reason for gate pass"
          />
        </div>

        <div class="field-row">
          <div class="field">
            <label>From (date & time)</label>
            <input
              v-model="createForm.fromDateTimeText"
              type="datetime-local"
            />
          </div>
          <div class="field">
            <label>To (date & time)</label>
            <input
              v-model="createForm.toDateTimeText"
              type="datetime-local"
            />
          </div>
        </div>

        <p v-if="createError" class="error-text">{{ createError }}</p>

        <div class="modal-actions">
          <button class="btn ghost" @click="closeCreate">Cancel</button>
          <button
            class="btn primary"
            :disabled="creating"
            @click="saveNewGatePass"
          >
            {{ creating ? 'Creating...' : 'Create Gate Pass' }}
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
  addDoc,
  getDocs,
  doc,
  setDoc,
  deleteDoc,
  serverTimestamp,
  orderBy,
  query
} from "firebase/firestore"

export default {
  name: "GatePassRequests",
  data() {
    return {
      requests: [],
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
        reason: "",
        fromDateTime: null,
        toDateTime: null,
        requestedBy: "parent",
        status: "pending",
        approvalNotes: "",
        createdAt: null,
        updatedAt: null
      },
      saving: false,
      error: "",

      showCreate: false,
      creating: false,
      createError: "",
      createForm: {
        studentName: "",
        classId: "",
        idNumber: "",
        reason: "",
        requestedBy: "parent",
        fromDateTimeText: "",
        toDateTimeText: ""
      }
    }
  },
  computed: {
    filteredRequests() {
      let list = [...this.requests]

      if (this.filters.classId) {
        list = list.filter(r => r.classId === this.filters.classId)
      }
      if (this.filters.status) {
        list = list.filter(r => r.status === this.filters.status)
      }
      if (this.filters.search) {
        const s = this.filters.search.toLowerCase()
        list = list.filter(r =>
          (r.studentName || "").toLowerCase().includes(s) ||
          (r.idNumber || "").toLowerCase().includes(s) ||
          (r.reason || "").toLowerCase().includes(s)
        )
      }
      return list
    }
  },
  methods: {
    statusLabel(status) {
      if (status === "approved") return "Approved"
      if (status === "rejected") return "Rejected"
      if (status === "used") return "Used"
      return "Pending"
    },
    statusClass(status) {
      if (status === "approved") return "status-approved"
      if (status === "rejected") return "status-rejected"
      if (status === "used") return "status-used"
      return "status-pending"
    },
    formatDate(ts) {
      if (!ts) return "-"
      const d = ts.toDate ? ts.toDate() : new Date(ts)
      return d.toLocaleString()
    },
    clearFilters() {
      this.filters = { classId: "", status: "", search: "" }
    },
    async loadRequests() {
      try {
        const q = query(
          collection(db, "gatePassRequests"),
          orderBy("createdAt", "desc")
        )
        const snap = await getDocs(q)
        this.requests = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (e) {
        console.error("Error loading gate pass requests", e)
        alert("Failed to load gate pass requests")
      }
    },
    openDetail(r) {
      this.error = ""
      this.selected = {
        id: r.id,
        studentUid: r.studentUid || "",
        studentName: r.studentName || "",
        classId: r.classId || "",
        idNumber: r.idNumber || "",
        reason: r.reason || "",
        fromDateTime: r.fromDateTime || null,
        toDateTime: r.toDateTime || null,
        requestedBy: r.requestedBy || "parent",
        status: r.status || "pending",
        approvalNotes: r.approvalNotes || "",
        createdAt: r.createdAt || null,
        updatedAt: r.updatedAt || null
      }
      this.showDetail = true
    },
    closeDetail() {
      this.showDetail = false
    },
    async updateRequest() {
      if (!this.selected.id) return
      this.saving = true
      this.error = ""
      try {
        const ref = doc(db, "gatePassRequests", this.selected.id)
        await setDoc(
          ref,
          {
            status: this.selected.status,
            approvalNotes: this.selected.approvalNotes || "",
            updatedAt: serverTimestamp()
          },
          { merge: true }
        )
        await this.loadRequests()
        this.showDetail = false
      } catch (e) {
        console.error("Error updating gate pass", e)
        this.error = "Failed to update gate pass request."
      } finally {
        this.saving = false
      }
    },
    async deleteRequest(r) {
      if (!confirm(`Delete gate pass for "${r.studentName}"?`)) return
      try {
        await deleteDoc(doc(db, "gatePassRequests", r.id))
        this.requests = this.requests.filter(x => x.id !== r.id)
      } catch (e) {
        console.error("Error deleting gate pass", e)
        alert("Failed to delete gate pass request")
      }
    },

    openCreate() {
      this.createError = ""
      this.createForm = {
        studentName: "",
        classId: "",
        idNumber: "",
        reason: "",
        requestedBy: "parent",
        fromDateTimeText: "",
        toDateTimeText: ""
      }
      this.showCreate = true
    },
    closeCreate() {
      this.showCreate = false
    },
    async saveNewGatePass() {
      this.createError = ""

      const f = this.createForm
      if (!f.studentName || !f.classId || !f.idNumber || !f.reason) {
        this.createError = "Fill student name, class, ID and reason."
        return
      }

      let fromDateTime = null
      let toDateTime = null
      if (f.fromDateTimeText) {
        fromDateTime = new Date(f.fromDateTimeText)
      }
      if (f.toDateTimeText) {
        toDateTime = new Date(f.toDateTimeText)
      }

      try {
        this.creating = true
        await addDoc(collection(db, "gatePassRequests"), {
          studentUid: "",
          studentName: f.studentName.trim(),
          classId: f.classId,
          idNumber: f.idNumber.trim(),
          reason: f.reason.trim(),
          fromDateTime,
          toDateTime,
          requestedBy: f.requestedBy,
          status: "pending",
          approvalNotes: "",
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        })
        await this.loadRequests()
        this.showCreate = false
      } catch (e) {
        console.error("Error creating gate pass", e)
        this.createError = "Failed to create gate pass."
      } finally {
        this.creating = false
      }
    }
  },
  mounted() {
    this.loadRequests()
  }
}
</script>

<style scoped>
.gatepass-page {
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
.gatepass-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}
.gatepass-table thead {
  background: #f3f4f6;
}
.gatepass-table th,
.gatepass-table td {
  padding: 0.45rem 0.5rem;
  border-bottom: 1px solid #e5e7eb;
  text-align: left;
}
.gatepass-table th {
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
.status-pending {
  background: #fef3c7;
  color: #92400e;
}
.status-approved {
  background: #dcfce7;
  color: #15803d;
}
.status-rejected {
  background: #fee2e2;
  color: #b91c1c;
}
.status-used {
  background: #e0f2fe;
  color: #075985;
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
  .gatepass-page {
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

