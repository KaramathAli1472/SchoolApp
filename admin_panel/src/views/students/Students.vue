<template>
  <div class="students-container">
    <h2>Students</h2>

    <!-- ===== Add / Edit Student Form ===== -->
    <div class="add-student-form">
      <input v-model="newStudent.name" placeholder="Student Name" />

      <input
        v-model.number="newStudent.rollNo"
        type="number"
        placeholder="Roll No"
      />

      <select v-model="newStudent.classId">
        <option v-for="cls in classes" :key="cls.value" :value="cls.value">
          {{ cls.label }}
        </option>
      </select>

      <input v-model="newStudent.dob" type="date" />

      <input v-model="newStudent.admissionDate" type="date" />

      <input
        v-model="newStudent.parentPhone"
        type="text"
        placeholder="Parent Phone"
      />

      <button @click="editing ? updateStudent() : addStudent()">
        {{ editing ? "Update Student" : "Add Student" }}
      </button>

      <button v-if="editing" class="cancel-btn" @click="cancelEdit">
        Cancel
      </button>
    </div>

    <!-- ===== Filter ===== -->
    <div class="filter-box">
      <label>Filter by Class:</label>
      <select v-model="selectedClass" @change="fetchStudents">
        <option value="">All Classes</option>
        <option v-for="cls in classes" :key="cls.value" :value="cls.value">
          {{ cls.label }}
        </option>
      </select>
    </div>

    <!-- ===== Students Table ===== -->
    <table v-if="students.length">
      <thead>
        <tr>
          <th>Roll No</th>
          <th>Name</th>
          <th>Class</th>
          <th>DOB</th>
          <th>Admission Date</th>
          <th>Parent Phone</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="s in students" :key="s.id">
          <td>{{ s.rollNo }}</td>
          <td>{{ s.name }}</td>
          <td>{{ classLabel(s.classId) }}</td>
          <td>{{ formatDate(s.dob) }}</td>
          <td>{{ formatDate(s.admissionDate) }}</td>
          <td>{{ s.parentPhone || "-" }}</td>
          <td>
            <button class="edit-btn" @click="editStudent(s)">Edit</button>
            <button class="delete-btn" @click="deleteStudent(s)">Delete</button>
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
  addDoc,
  query,
  where,
  Timestamp,
  deleteDoc,
  doc,
  updateDoc,
} from "firebase/firestore"

export default {
  data() {
    return {
      classes: [
        { label: "Class 1", value: "class_1" },
        { label: "Class 2", value: "class_2" },
        { label: "Class 3", value: "class_3" },
        { label: "Class 4", value: "class_4" },
        { label: "Class 5", value: "class_5" },
        { label: "Class 6", value: "class_6" },
        { label: "Class 7", value: "class_7" },
        { label: "Class 8", value: "class_8" },
        { label: "Class 9", value: "class_9" },
        { label: "Class 10", value: "class_10" },
      ],
      students: [],
      selectedClass: "",
      newStudent: {
        id: null,
        name: "",
        rollNo: "",
        classId: "class_1",
        dob: "",
        admissionDate: "",
        parentPhone: "",
      },
      editing: false,
    }
  },

  mounted() {
    this.fetchStudents()
  },

  methods: {
    classLabel(classId) {
      const cls = this.classes.find((c) => c.value === classId)
      return cls ? cls.label : "-"
    },

    formatDate(date) {
      if (!date) return "-"
      let d
      // Agar date Firebase Timestamp hai
      if (date.toDate) d = date.toDate()
      else d = new Date(date)
      return (
        ("0" + (d.getMonth() + 1)).slice(-2) +
        "/" +
        ("0" + d.getDate()).slice(-2) +
        "/" +
        d.getFullYear()
      )
    },

    async fetchStudents() {
      try {
        const ref = collection(db, "students")
        const q = this.selectedClass
          ? query(ref, where("classId", "==", this.selectedClass))
          : ref

        const snap = await getDocs(q)
        this.students = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      } catch (err) {
        console.error("Fetch students error:", err)
      }
    },

    async addStudent() {
      const { name, rollNo, classId } = this.newStudent
      if (!name || !rollNo || !classId) {
        alert("Name, Roll No and Class are required")
        return
      }

      const dupQuery = query(
        collection(db, "students"),
        where("classId", "==", classId),
        where("rollNo", "==", rollNo)
      )
      const dupSnap = await getDocs(dupQuery)
      if (!dupSnap.empty) {
        alert("Roll No already exists in this class")
        return
      }

      try {
        await addDoc(collection(db, "students"), {
          name,
          rollNo,
          classId,
          dob: this.newStudent.dob || null,
          admissionDate: this.newStudent.admissionDate
            ? Timestamp.fromDate(new Date(this.newStudent.admissionDate))
            : Timestamp.now(),
          parentPhone: this.newStudent.parentPhone || null,
          parentId: null,
          createdAt: Timestamp.now(),
        })

        alert("Student added successfully")
        this.resetForm()
        this.fetchStudents()
      } catch (err) {
        console.error("Add student error:", err)
        alert("Failed to add student")
      }
    },

    editStudent(student) {
      this.newStudent = { ...student }
      if (student.dob) {
        this.newStudent.dob = this.formatDateForInput(student.dob)
      }
      if (student.admissionDate) {
        this.newStudent.admissionDate = this.formatDateForInput(
          student.admissionDate
        )
      }
      this.editing = true
    },

    formatDateForInput(date) {
      let d
      if (date.toDate) d = date.toDate()
      else d = new Date(date)
      return d.toISOString().substr(0, 10) // YYYY-MM-DD for input type date
    },

    async updateStudent() {
      if (!this.newStudent.id) return
      try {
        await updateDoc(doc(db, "students", this.newStudent.id), {
          name: this.newStudent.name,
          rollNo: this.newStudent.rollNo,
          classId: this.newStudent.classId,
          dob: this.newStudent.dob || null,
          admissionDate: this.newStudent.admissionDate
            ? Timestamp.fromDate(new Date(this.newStudent.admissionDate))
            : Timestamp.now(),
          parentPhone: this.newStudent.parentPhone || null,
        })
        alert("Student updated successfully")
        this.resetForm()
        this.fetchStudents()
      } catch (err) {
        console.error("Update student error:", err)
        alert("Failed to update student")
      }
    },

    cancelEdit() {
      this.resetForm()
    },

    resetForm() {
      this.newStudent = {
        id: null,
        name: "",
        rollNo: "",
        classId: "class_1",
        dob: "",
        admissionDate: "",
        parentPhone: "",
      }
      this.editing = false
    },

    async deleteStudent(student) {
      const ok = confirm(`Are you sure you want to delete ${student.name}?`)
      if (!ok) return

      try {
        await deleteDoc(doc(db, "students", student.id))
        alert("Student deleted successfully")
        this.fetchStudents()
      } catch (err) {
        console.error("Delete student error:", err)
        alert("Failed to delete student")
      }
    },
  },
}
</script>

<style scoped>
.students-container {
  padding: 2rem;
  background: #f5f5f5;
  min-height: 100vh;
}

.add-student-form {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.filter-box {
  margin-bottom: 1rem;
}

input,
select {
  padding: 0.5rem;
  border-radius: 5px;
  border: 1px solid #ccc;
}

button {
  padding: 0.5rem 1rem;
  background: #4CAF50;
  color: white;
  border: none;
  cursor: pointer;
  border-radius: 5px;
}

.edit-btn {
  background: #ff9800;
  margin-right: 5px;
}

.edit-btn:hover {
  background: #fb8c00;
}

.delete-btn {
  background: #e53935;
}

.delete-btn:hover {
  background: #c62828;
}

.cancel-btn {
  background: #9e9e9e;
}

.cancel-btn:hover {
  background: #757575;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
}

th,
td {
  border: 1px solid #ccc;
  padding: 0.8rem;
}

th {
  background: #2196F3;
  color: white;
}
</style>

