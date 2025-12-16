<template>
  <div class="timetable-page">
    <header class="tt-header">
      <div>
        <h1>Class Time Table</h1>
        <p>Select a class and manage weekly schedule.</p>
      </div>
      <div class="tt-header-right">
        <select v-model="selectedClass" @change="loadTimetable" class="class-select">
          <option disabled value="">Select class</option>
          <option
            v-for="cls in classes"
            :key="cls.value"
            :value="cls.value"
          >
            {{ cls.label }}
          </option>
        </select>
        <button class="btn primary" @click="saveTimetable" :disabled="!selectedClass">
          Save
        </button>
      </div>
    </header>

    <section class="card" v-if="selectedClass">
      <div class="card-header">
        <h2>{{ classLabel(selectedClass) }} weekly timetable</h2>
        <span class="subtext">Click any cell to edit subject.</span>
      </div>

      <div class="table-wrapper">
        <table class="tt-table">
          <thead>
            <tr>
              <th>Day</th>
              <th v-for="col in columns" :key="col.key">
                <div>{{ col.label }}</div>
                <div class="time-text" v-if="col.time">{{ col.time }}</div>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="day in days" :key="day.value">
              <td class="day-cell">{{ day.label }}</td>
              <td
                v-for="col in columns"
                :key="day.value + '-' + col.key"
                class="slot-cell"
                :class="{'break-cell': col.type === 'break'}"
                @click="editSlot(day.value, col.key)"
              >
                <!-- Period cells -->
                <span
                  v-if="col.type === 'period'"
                  class="slot-subject"
                >
                  {{ getSlot(day.value, col.key) || '—' }}
                </span>

                <!-- Break cells: show saved text if any, otherwise default label -->
                <span
                  v-else
                  class="break-label"
                >
                  {{ getSlot(day.value, col.key) || col.label }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <p v-else class="empty-text">Select a class to view its time table.</p>

    <!-- Edit slot modal -->
    <div v-if="showModal" class="modal-backdrop">
      <div class="modal">
        <h3>
          Edit ({{ editingDayLabel }} •
          {{ currentColumnLabel }})
        </h3>
        <div class="modal-body">
          <div class="field">
            <label>Subject / Label</label>
            <input
              v-model="modalSubject"
              type="text"
              placeholder="e.g. Math, Science, Break 1"
            />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn" @click="closeModal">Cancel</button>
          <button class="btn danger" @click="clearSlot">Clear</button>
          <button class="btn primary" @click="applySlot">Apply</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import { doc, getDoc, setDoc } from "firebase/firestore"

export default {
  data() {
    return {
      classes: Array.from({ length: 10 }, (_, i) => ({
        label: `Class ${i + 1}`,
        value: `class_${i + 1}`,
      })),
      days: [
        { label: "Mon", value: "mon" },
        { label: "Tue", value: "tue" },
        { label: "Wed", value: "wed" },
        { label: "Thu", value: "thu" },
        { label: "Fri", value: "fri" },
      ],
      // columns: CT, P1..P7, intervention, breaks
      columns: [
        { key: "ct",  label: "CT",           time: "7:30 - 7:55",   type: "period" },
        { key: "p1",  label: "P1",           time: "7:55 - 8:35",   type: "period" },
        { key: "ip",  label: "Intervention", time: "8:35 - 9:10",   type: "period" },
        { key: "br1", label: "Break 1",      time: "9:10 - 9:35",   type: "break"  },
        { key: "p2",  label: "P2",           time: "9:35 - 10:15",  type: "period" },
        { key: "p3",  label: "P3",           time: "10:15 - 10:55", type: "period" },
        { key: "br2", label: "Break 2",      time: "10:55 - 11:00", type: "break"  },
        { key: "p4",  label: "P4",           time: "11:00 - 11:40", type: "period" },
        { key: "p5",  label: "P5",           time: "11:40 - 12:20", type: "period" },
        { key: "br3", label: "Break 3",      time: "12:20 - 12:25", type: "break"  },
        { key: "p6",  label: "P6",           time: "12:25 - 1:05",  type: "period" },
        { key: "p7",  label: "P7",           time: "1:05 - 1:45",   type: "period" },
      ],
      selectedClass: "",
      // timetable: { mon: { ct:"Math", p1:"Eng", br1:"Break 1", ... }, tue: {...}, ... }
      timetable: {},
      showModal: false,
      editingDay: "",
      editingKey: "",
      modalSubject: "",
    }
  },
  computed: {
    editingDayLabel() {
      const d = this.days.find((x) => x.value === this.editingDay)
      return d ? d.label : ""
    },
    currentColumnLabel() {
      const c = this.columns.find((x) => x.key === this.editingKey)
      return c ? c.label : ""
    },
  },
  methods: {
    classLabel(val) {
      const cls = this.classes.find((c) => c.value === val)
      return cls ? cls.label : "-"
    },

    async loadTimetable() {
      if (!this.selectedClass) return
      try {
        const ref = doc(db, "timetables", this.selectedClass)
        const snap = await getDoc(ref)
        if (snap.exists()) {
          this.timetable = snap.data()
        } else {
          const base = {}
          for (const day of this.days) {
            base[day.value] = {}
          }
          this.timetable = base
        }
      } catch (e) {
        console.error("Load timetable error:", e)
      }
    },

    getSlot(day, key) {
      if (!this.timetable[day]) return ""
      return this.timetable[day][key] || ""
    },

    editSlot(day, key) {
      this.editingDay = day
      this.editingKey = key
      this.modalSubject = this.getSlot(day, key) || ""
      this.showModal = true
    },

    closeModal() {
      this.showModal = false
      this.editingDay = ""
      this.editingKey = ""
      this.modalSubject = ""
    },

    clearSlot() {
      if (!this.editingDay || !this.editingKey) return
      if (!this.timetable[this.editingDay]) {
        this.timetable[this.editingDay] = {}
      }
      delete this.timetable[this.editingDay][this.editingKey]
      this.closeModal()
    },

    applySlot() {
      if (!this.editingDay || !this.editingKey) return
      if (!this.timetable[this.editingDay]) {
        this.timetable[this.editingDay] = {}
      }
      this.timetable[this.editingDay][this.editingKey] = this.modalSubject.trim()
      this.closeModal()
    },

    async saveTimetable() {
      if (!this.selectedClass) return
      try {
        const ref = doc(db, "timetables", this.selectedClass)
        await setDoc(ref, this.timetable, { merge: true })
        alert("Time table saved.")
      } catch (e) {
        console.error("Save timetable error:", e)
        alert("Failed to save time table.")
      }
    },
  },
}
</script>

<style scoped>
/* same CSS as before */
.timetable-page {
  padding: 1.2rem 1.5rem;
  background: #f5f5f5;
  min-height: 100vh;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.tt-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.8rem;
}

.tt-header h1 {
  margin: 0;
  font-size: 1.4rem;
}

.tt-header p {
  margin: 0.18rem 0 0;
  font-size: 0.8rem;
  color: #6b7280;
}

.tt-header-right {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.class-select {
  padding: 0.3rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.8rem;
}

.btn {
  padding: 0.35rem 0.9rem;
  border-radius: 0.4rem;
  border: none;
  font-size: 0.8rem;
  cursor: pointer;
}

.btn.primary {
  background: #1976d2;
  color: #fff;
}

.btn.primary:disabled {
  opacity: 0.6;
  cursor: default;
}

.btn.danger {
  background: #e53935;
  color: white;
}

.card {
  background: #ffffff;
  border-radius: 0.8rem;
  padding: 0.8rem 1rem;
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.06);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 0.4rem;
}

.card-header h2 {
  margin: 0;
  font-size: 1rem;
}

.subtext {
  font-size: 0.78rem;
  color: #6b7280;
}

.table-wrapper {
  overflow-x: auto;
}

.tt-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8rem;
  background: #fafafa;
}

.tt-table th,
.tt-table td {
  border: 1px solid #e5e7eb;
  padding: 0.3rem 0.35rem;
  text-align: center;
}

.tt-table thead {
  background: #cfe8ff;
  color: #111827;
}

.tt-table th .time-text {
  font-size: 0.7rem;
  color: #6b7280;
}

.day-cell {
  background: #fdf6e3;
  font-weight: 600;
  text-align: left;
  padding-left: 0.5rem;
}

.slot-cell {
  cursor: pointer;
  min-width: 80px;
  background: #fffef9;
}

.slot-cell:hover {
  background: #e3f2fd;
}

.break-cell {
  background: #fff7d6;
}

.break-cell:hover {
  background: #fff7d6;
}

.break-label {
  font-size: 0.78rem;
  color: #6b7280;
}

.slot-subject {
  font-weight: 600;
}

.empty-text {
  margin-top: 1rem;
  font-size: 0.9rem;
  color: #666;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.35);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 20;
}

.modal {
  background: #ffffff;
  border-radius: 0.8rem;
  padding: 0.9rem 1rem;
  width: 340px;
  max-width: 95vw;
}

.modal h3 {
  margin: 0 0 0.5rem;
  font-size: 1rem;
}

.modal-body {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-bottom: 0.6rem;
}

.field label {
  font-size: 0.78rem;
  color: #6b7280;
  margin-bottom: 0.18rem;
}

.field input {
  width: 100%;
  padding: 0.35rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.8rem;
}

.field input:focus {
  outline: none;
  border-color: #1976d2;
  box-shadow: 0 0 0 1px rgba(25, 118, 210, 0.15);
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.4rem;
}
</style>

