<template>
  <div class="fees-container">
    <!-- Header with online fees icon -->
    <div class="fees-header">
      <img
        src="https://cdn-icons-png.flaticon.com/512/2920/2920316.png"
        alt="Fees Icon"
        class="fees-logo"
      />
      <h2>Student Fees Management</h2>
    </div>

    <!-- Search bar -->
    <div class="search-row">
      <div class="search-field">
        <label>Search Name:</label>
        <input
          type="text"
          v-model="searchName"
          placeholder="Student name..."
        />
      </div>
      <div class="search-field">
        <label>Search Class:</label>
        <input
          type="text"
          v-model="searchClass"
          placeholder="e.g. 7, 7A, Class 7..."
        />
      </div>
    </div>

    <!-- Top line form -->
    <div v-if="isTeacherOrAdmin" class="top-form">
      <div class="top-field">
        <label>Student:</label>
        <select v-model="paymentForm.studentId">
          <option value="">Select student</option>
          <option
            v-for="s in filteredStudents"
            :key="s.id"
            :value="s.id"
          >
            {{ s.rollNo || s.idNumber || "–" }} - {{ s.name }} ({{ s.classId }})
          </option>
        </select>
      </div>

      <div class="top-field">
        <label>Total Fee:</label>
        <input
          type="number"
          v-model.number="paymentForm.totalFee"
          min="0"
          placeholder="optional"
        />
      </div>

      <div class="top-field">
        <label>Amount:</label>
        <input
          type="number"
          v-model.number="paymentForm.amount"
          min="1"
        />
      </div>

      <div class="top-field">
        <label>Mode:</label>
        <select v-model="paymentForm.mode">
          <option value="cash">Cash</option>
          <option value="online">Online</option>
          <option value="bank">Bank</option>
        </select>
      </div>

      <div class="top-field" v-if="paymentForm.mode !== 'cash'">
        <label>Txn No:</label>
        <input
          type="text"
          v-model="paymentForm.txnRef"
          placeholder="Transaction / UTR number"
        />
      </div>

      <div class="top-field">
        <label>Month:</label>
        <select v-model.number="paymentForm.month">
          <option :value="1">January</option>
          <option :value="2">February</option>
          <option :value="3">March</option>
          <option :value="4">April</option>
          <option :value="5">May</option>
          <option :value="6">June</option>
          <option :value="7">July</option>
          <option :value="8">August</option>
          <option :value="9">September</option>
          <option :value="10">October</option>
          <option :value="11">November</option>
          <option :value="12">December</option>
        </select>
      </div>

      <div class="top-field">
        <label>Year:</label>
        <input
          type="number"
          v-model.number="paymentForm.year"
          min="2000"
          max="2100"
        />
      </div>

      <div class="top-buttons">
        <button @click="submitPayment">Add Payment</button>
        <button class="clear-btn" @click="resetPaymentForm">Clear</button>
      </div>
    </div>

    <table v-if="filteredStudents.length" class="fees-table">
      <thead>
        <tr>
          <th>ID Number</th>
          <th>Name</th>
          <th>Class</th>
          <th>Total Fee</th>
          <th>Total Paid</th>
          <th>Balance</th>
          <th>Status</th>
          <th>Payment History</th>
          <th>Bill</th>
          <th v-if="isTeacherOrAdmin">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="student in filteredStudents" :key="student.id">
          <td>{{ student.idNumber || student.rollNo || "-" }}</td>
          <td>{{ student.name || "-" }}</td>
          <td>{{ student.classId || "-" }}</td>

          <td>{{ feesData[student.id]?.totalFee || 0 }}</td>
          <td>{{ feesData[student.id]?.totalPaid || 0 }}</td>
          <td>{{ studentBalance(student.id) }}</td>

          <td>
            <span :class="statusClass(student.id)">
              {{ feesStatus(student.id) }}
            </span>
          </td>

          <!-- Payment history text -->
          <td>
            <ul>
              <li
                v-for="(p, index) in feesData[student.id]?.paymentHistory || []"
                :key="index"
              >
                {{ p.amount }} |
                {{ formatDate(p.date) }} |
                {{ p.mode }} |
                {{ monthName(p.month) }} {{ p.year }}
                <span v-if="p.mode !== 'cash' && p.txnRef">
                  | Txn: {{ p.txnRef }}
                </span>
              </li>
            </ul>
          </td>

          <!-- Bill column -->
          <td>
            <ul>
              <li
                v-for="(p, index) in feesData[student.id]?.paymentHistory || []"
                :key="index"
                class="actions-row"
              >
                <button
                  class="bill-btn"
                  @click="generateBill(student, p, feesData[student.id])"
                >
                  Bill
                </button>
              </li>
            </ul>
          </td>

          <!-- Edit / Delete column -->
          <td v-if="isTeacherOrAdmin">
            <ul>
              <li
                v-for="(p, index) in feesData[student.id]?.paymentHistory || []"
                :key="index"
                class="actions-row"
              >
                <button
                  class="edit-btn"
                  @click="editPayment(student.id, index)"
                >
                  Edit
                </button>
                <button
                  class="delete-btn"
                  @click="deletePayment(student.id, index)"
                >
                  Delete
                </button>
              </li>
            </ul>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else>No students found.</p>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  getDocs,
  doc,
  getDoc,
  setDoc
} from "firebase/firestore"
import { jsPDF } from "jspdf"  // [web:248]

export default {
  data() {
    const now = new Date()
    return {
      students: [],
      feesData: {},
      user: JSON.parse(localStorage.getItem("user")) || {},
      searchName: "",
      searchClass: "",
      paymentForm: {
        studentId: "",
        totalFee: null,
        amount: null,
        mode: "cash",
        txnRef: "",
        month: now.getMonth() + 1,
        year: now.getFullYear()
      }
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return this.user.role === "teacher" || this.user.role === "admin"
    },

    filteredStudents() {
      const name = this.searchName.trim().toLowerCase()
      const cls = this.searchClass.trim().toLowerCase()

      return this.students.filter(s => {
        const sName = (s.name || "").toLowerCase()
        const sClass = (s.classId || "").toLowerCase()

        const matchName = !name || sName.includes(name)
        const matchClass = !cls || sClass.includes(cls)

        return matchName && matchClass
      })
    }
  },
  methods: {
    async fetchStudents() {
      try {
        const colRef = collection(db, "students")
        const snap = await getDocs(colRef)
        this.students = snap.docs.map(d => ({ id: d.id, ...d.data() }))
        await this.fetchFees()
      } catch (err) {
        console.error("Fetch students error:", err)
        alert("Error loading students, check console")
      }
    },

    async fetchFees() {
      try {
        const feesCopy = { ...this.feesData }
        for (const student of this.students) {
          const docRef = doc(db, "fees", student.id)
          const docSnap = await getDoc(docRef)
          feesCopy[student.id] = docSnap.exists()
            ? docSnap.data()
            : { totalFee: 0, totalPaid: 0, paymentHistory: [] }
        }
        this.feesData = feesCopy
      } catch (err) {
        console.error("Fetch fees error:", err)
      }
    },

    studentBalance(studentId) {
      const data = this.feesData[studentId] || {}
      const totalFee = data.totalFee || 0
      const totalPaid = data.totalPaid || 0
      return totalFee - totalPaid
    },

    feesStatus(studentId) {
      const data = this.feesData[studentId] || {}
      const totalFee = data.totalFee || 0
      const totalPaid = data.totalPaid || 0

      if (!totalFee && !totalPaid) return "Not Set"
      if (totalPaid === 0) return "Not Paid"
      if (totalPaid >= totalFee) return "Paid"
      return "Partially Paid"
    },

    statusClass(studentId) {
      const status = this.feesStatus(studentId)
      if (status === "Paid") return "status-paid"
      if (status === "Partially Paid") return "status-partial"
      if (status === "Not Paid") return "status-unpaid"
      return "status-unknown"
    },

    resetPaymentForm() {
      const now = new Date()
      this.paymentForm = {
        studentId: "",
        totalFee: null,
        amount: null,
        mode: "cash",
        txnRef: "",
        month: now.getMonth() + 1,
        year: now.getFullYear()
      }
    },

    async submitPayment() {
      const { studentId, totalFee, amount, mode, month, year, txnRef } =
        this.paymentForm

      if (!studentId) {
        alert("Select a student")
        return
      }
      if (!amount || amount <= 0) {
        alert("Enter valid amount")
        return
      }
      if (!month || !year) {
        alert("Select month and year")
        return
      }
      if (mode !== "cash" && !txnRef) {
        alert("Enter transaction number for online/bank payment")
        return
      }

      try {
        const docRef = doc(db, "fees", studentId)
        const existing = this.feesData[studentId] || {
          totalFee: 0,
          totalPaid: 0,
          paymentHistory: []
        }

        const finalTotalFee =
          totalFee != null && totalFee !== ""
            ? Number(totalFee)
            : existing.totalFee || 0

        const newTotalPaid = (existing.totalPaid || 0) + Number(amount)

        const updated = {
          ...existing,
          totalFee: finalTotalFee,
          totalPaid: newTotalPaid,
          paymentHistory: [
            ...(existing.paymentHistory || []),
            {
              amount: Number(amount),
              date: new Date().toISOString().substr(0, 10),
              mode,
              month,
              year,
              txnRef: mode === "cash" ? "" : txnRef
            }
          ]
        }

        await setDoc(docRef, updated)
        // Vue 2 compatibility
        this.$set
          ? this.$set(this.feesData, studentId, updated)
          : (this.feesData = { ...this.feesData, [studentId]: updated })

        alert("Payment saved")
        this.resetPaymentForm()
      } catch (err) {
        console.error("Submit payment error:", err)
        alert("Failed to save payment")
      }
    },

    async editPayment(studentId, index) {
      const data = this.feesData[studentId]
      if (!data || !data.paymentHistory || !data.paymentHistory[index]) return

      const payment = data.paymentHistory[index]
      const newAmountStr = prompt("Edit amount", payment.amount)
      const newAmount = Number(newAmountStr)
      if (!newAmount || newAmount <= 0) return

      const newMode =
        prompt("Edit mode (cash/online/bank)", payment.mode) || payment.mode
      let newTxn = payment.txnRef || ""
      if (newMode !== "cash") {
        newTxn =
          prompt("Edit transaction no", payment.txnRef || "") || ""
      } else {
        newTxn = ""
      }

      const diff = newAmount - Number(payment.amount)
      const updatedHistory = [...data.paymentHistory]
      updatedHistory[index] = {
        ...payment,
        amount: newAmount,
        mode: newMode,
        txnRef: newTxn
      }

      const updatedDoc = {
        ...data,
        totalPaid: (data.totalPaid || 0) + diff,
        paymentHistory: updatedHistory
      }

      try {
        const docRef = doc(db, "fees", studentId)
        await setDoc(docRef, updatedDoc)
        this.$set(this.feesData, studentId, updatedDoc)
        alert("Payment updated")
      } catch (err) {
        console.error("Edit payment error:", err)
        alert("Failed to update payment")
      }
    },

    async deletePayment(studentId, index) {
      const data = this.feesData[studentId]
      if (!data || !data.paymentHistory || !data.paymentHistory[index]) return
      if (!confirm("Delete this payment?")) return

      const payment = data.paymentHistory[index]
      const updatedHistory = data.paymentHistory.filter((_, i) => i !== index)
      const updatedDoc = {
        ...data,
        totalPaid: (data.totalPaid || 0) - Number(payment.amount),
        paymentHistory: updatedHistory
      }

      try {
        const docRef = doc(db, "fees", studentId)
        await setDoc(docRef, updatedDoc)
        this.$set(this.feesData, studentId, updatedDoc)
        alert("Payment deleted")
      } catch (err) {
        console.error("Delete payment error:", err)
        alert("Failed to delete payment")
      }
    },

    generateBill(student, payment, feeDoc) {
      const docPdf = new jsPDF()

      const schoolName = "Your School Name"
      const address = "School Address, City"
      const totalFee = feeDoc.totalFee || 0
      const totalPaid = feeDoc.totalPaid || 0
      const balance = totalFee - totalPaid

      docPdf.setFontSize(16)
      docPdf.text(schoolName, 10, 15)
      docPdf.setFontSize(11)
      docPdf.text(address, 10, 22)
      docPdf.text("Fees Payment Receipt", 10, 30)

      docPdf.setFontSize(10)
      let y = 40
      docPdf.text(
        `Student: ${student.name} (ID: ${student.idNumber || student.id || "-"})`,
        10,
        y
      )
      y += 6
      docPdf.text(`Class: ${student.classId || "-"}`, 10, y)
      y += 6
      docPdf.text(`Date: ${this.formatDate(payment.date)}`, 10, y)
      y += 10

      docPdf.text(`Total Fee: ${totalFee}`, 10, y)
      y += 6
      docPdf.text(`Total Paid (till now): ${totalPaid}`, 10, y)
      y += 6
      docPdf.text(`This Payment: ${payment.amount}`, 10, y)
      y += 6
      docPdf.text(`Balance: ${balance}`, 10, y)
      y += 10

      docPdf.text(`Mode: ${payment.mode}`, 10, y)
      y += 6
      if (payment.mode !== "cash" && payment.txnRef) {
        docPdf.text(`Transaction No: ${payment.txnRef}`, 10, y)
        y += 6
      }

      docPdf.text("Thank you.", 10, y + 4)

      const fileName = `fees_${student.idNumber || student.id}_${payment.date}.pdf`
      docPdf.save(fileName)
    },

    formatDate(dateStr) {
      if (!dateStr) return "-"
      const d = new Date(dateStr)
      return d.toISOString().substr(0, 10)
    },

    monthName(m) {
      const names = [
        "", "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ]
      return names[m] || "-"
    }
  },
  mounted() {
    this.fetchStudents()
  }
}
</script>

<style scoped>
.fees-container {
  padding: 2rem;
  background: #f5f5f5;
  min-height: 100vh;
}
.fees-header {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-bottom: 0rem;
}
.fees-logo {
  width: 34px;
  height: 34px;
  object-fit: contain;
}
.search-row {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin-bottom: 0.7rem;
}
.search-field {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}
.search-field input {
  padding: 0.3rem 0.5rem;
  border-radius: 4px;
  border: 1px solid #ccc;
}
.top-form {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.5rem;
}
.top-field {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}
.top-field label {
  font-weight: 600;
}
.top-field input,
.top-field select {
  padding: 0.3rem 0.5rem;
  border-radius: 4px;
  border: 1px solid #ccc;
}
.top-buttons {
  margin-left: auto;
  display: flex;
  gap: 0.4rem;
}
.top-buttons button {
  padding: 0.4rem 0.9rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  color: #fff;
}
.top-buttons button:first-child {
  background: #4caf50;
}
.top-buttons .clear-btn {
  background: #9e9e9e;
}
.fees-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  margin-top: 0.5rem;
}
th,
td {
  border: 1px solid #ccc;
  padding: 0.8rem;
  text-align: left;
}
th {
  background: #2196f3;
  color: white;
}
.actions-row {
  display: flex;
  gap: 0.3rem;
  margin-bottom: 0.25rem;
}
button {
  padding: 0.3rem 0.6rem;
  border: none;
  border-radius: 4px;
  background: #4caf50;
  color: white;
  cursor: pointer;
}
button:hover {
  background: #45a049;
}
.bill-btn {
  padding: 0.2rem 0.5rem;
  background: #1976d2;
  color: #fff;
  border-radius: 3px;
  font-size: 0.75rem;
}
.bill-btn:hover {
  background: #1565c0;
}
.edit-btn {
  padding: 0.2rem 0.5rem;
  background: #ff9800;
  color: #fff;
  border-radius: 3px;
  font-size: 0.75rem;
}
.edit-btn:hover {
  background: #fb8c00;
}
.delete-btn {
  padding: 0.2rem 0.5rem;
  background: #f44336;
  color: #fff;
  border-radius: 3px;
  font-size: 0.75rem;
}
.delete-btn:hover {
  background: #d32f2f;
}
.status-paid {
  color: #2e7d32;
  font-weight: 600;
}
.status-partial {
  color: #f9a825;
  font-weight: 600;
}
.status-unpaid {
  color: #c62828;
  font-weight: 600;
}
.status-unknown {
  color: #757575;
}
</style>

