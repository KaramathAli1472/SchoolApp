<template>
  <div class="students-container">
    <h2 class="page-title">🎓 Student Management</h2>

    <!-- ===== Add / Edit Student Form ===== -->
    <div class="card form-card">
      <h3>{{ editing ? "Edit Student" : "Add New Student" }}</h3>
      <div class="form-grid">
        <input v-model="newStudent.name" placeholder="Student Name" />
        <input v-model="newStudent.idNumber" type="text" placeholder="ID Number" />
        <select v-model="newStudent.classId" class="small-select">
          <option v-for="cls in classes" :key="cls.value" :value="cls.value">
            {{ cls.label }}
          </option>
        </select>
        <select v-model="newStudent.gender" class="small-select">
          <option value="">Select Gender</option>
          <option value="Male">Male</option>
          <option value="Female">Female</option>
          <option value="Other">Other</option>
        </select>
        <input v-model="newStudent.branch" type="text" placeholder="School Branch" />
        <input v-model="newStudent.dob" type="date" />
        <input v-model="newStudent.admissionDate" type="date" />
        <input v-model="newStudent.parentPhone" type="text" placeholder="Parent Phone" />

        <!-- Photo Upload -->
        <div class="photo-upload">
          <input type="file" accept="image/*" @change="onPhotoSelect" />
          <img v-if="photoPreview" :src="photoPreview" class="photo-preview" />
        </div>
      </div>

      <div class="form-actions">
        <button class="primary-btn" @click="editing ? updateStudent() : addStudent()">
          {{ editing ? "Update" : "Add Student" }}
        </button>
        <button v-if="editing" class="secondary-btn" @click="cancelEdit">Cancel</button>
      </div>
    </div>

    <!-- ===== Filter & Search ===== -->
<div class="card filter-card">
  <div class="filter-search-line">
    <div class="filter-item">
      <label>Filter by Class:</label>
      <select v-model="selectedClass" @change="applyFilters" class="small-select">
        <option value="">All Classes</option>
        <option v-for="cls in classes" :key="cls.value" :value="cls.value">
          {{ cls.label }}
        </option>
      </select>
    </div>
    <div class="filter-item">
      <label>Search by Name:</label>
      <input type="text" v-model="searchQuery" placeholder="Enter student name..." @input="applyFilters" class="small-search-box" />
    </div>
  </div>
</div>

    <!-- ===== Students Table ===== -->
    <div class="card table-card">
      <table v-if="filteredStudents.length">
        <thead>
          <tr>
            <th>Photo</th>
            <th>ID Number</th>
            <th>Name</th>
            <th>Class</th>
            <th>Gender</th>
            <th>Branch</th>
            <th>DOB</th>
            <th>Admission Date</th>
            <th>Parent Phone</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in filteredStudents" :key="s.id">
            <td>
              <img v-if="s.photoUrl" :src="s.photoUrl" class="table-photo" />
              <span v-else>-</span>
            </td>
            <td>{{ s.idNumber }}</td>
            <td>{{ s.name }}</td>
            <td>{{ classLabel(s.classId) }}</td>
            <td>{{ s.gender || "-" }}</td>
            <td>{{ s.branch || "-" }}</td>
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

      <p v-else class="no-data">No students found.</p>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import { collection, getDocs, addDoc, query, where, Timestamp, deleteDoc, doc, updateDoc } from "firebase/firestore"

const CLOUD_NAME = "drxe5e2nk"
const UPLOAD_PRESET = "students_photos"

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
      searchQuery: "",
      newStudent: {
        id: null,
        name: "",
        idNumber: "",
        classId: "class_1",
        gender: "",
        branch: "",
        dob: "",
        admissionDate: "",
        parentPhone: "",
        photoUrl: "",
      },
      photoFile: null,
      photoPreview: "",
      editing: false,
    }
  },

  mounted() {
    this.fetchStudents()
  },

  computed: {
    filteredStudents() {
      return this.students.filter(s => {
        const matchesClass = this.selectedClass ? s.classId === this.selectedClass : true
        const matchesSearch = this.searchQuery
          ? s.name.toLowerCase().includes(this.searchQuery.toLowerCase())
          : true
        return matchesClass && matchesSearch
      })
    }
  },

  methods: {
    classLabel(classId) {
      const cls = this.classes.find(c => c.value === classId)
      return cls ? cls.label : "-"
    },

    formatDate(date) {
      if (!date) return "-"
      let d = date.toDate ? date.toDate() : new Date(date)
      return `${("0"+(d.getMonth()+1)).slice(-2)}/${("0"+d.getDate()).slice(-2)}/${d.getFullYear()}`
    },

    async fetchStudents() {
      try {
        const ref = collection(db, "students")
        const snap = await getDocs(ref)
        this.students = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (err) {
        console.error("Fetch students error:", err)
      }
    },

    applyFilters() {
      // filteredStudents computed property will handle filtering automatically
    },

    onPhotoSelect(e) {
      this.photoFile = e.target.files[0]
      this.photoPreview = URL.createObjectURL(this.photoFile)
    },

    async uploadPhoto() {
      if (!this.photoFile) return this.newStudent.photoUrl || ""
      const fd = new FormData()
      fd.append("file", this.photoFile)
      fd.append("upload_preset", UPLOAD_PRESET)
      const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`, { method:"POST", body: fd })
      const data = await res.json()
      return data.secure_url
    },

    async addStudent() {
      if (!this.newStudent.name || !this.newStudent.idNumber || !this.newStudent.classId) {
        alert("Name, ID Number, and Class are required")
        return
      }
      const photoUrl = await this.uploadPhoto()
      try {
        await addDoc(collection(db, "students"), {
          ...this.newStudent,
          photoUrl,
          admissionDate: this.newStudent.admissionDate ? Timestamp.fromDate(new Date(this.newStudent.admissionDate)) : Timestamp.now(),
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
      this.photoPreview = student.photoUrl || ""
      if (student.dob) this.newStudent.dob = this.formatDateForInput(student.dob)
      if (student.admissionDate) this.newStudent.admissionDate = this.formatDateForInput(student.admissionDate)
      this.editing = true
    },

    formatDateForInput(date) {
      let d = date.toDate ? date.toDate() : new Date(date)
      return d.toISOString().substr(0,10)
    },

    async updateStudent() {
      if (!this.newStudent.id) return
      const photoUrl = this.photoFile ? await this.uploadPhoto() : this.newStudent.photoUrl || ""
      try {
        await updateDoc(doc(db, "students", this.newStudent.id), {
          ...this.newStudent,
          photoUrl,
          admissionDate: this.newStudent.admissionDate ? Timestamp.fromDate(new Date(this.newStudent.admissionDate)) : Timestamp.now(),
        })
        alert("Student updated successfully")
        this.resetForm()
        this.fetchStudents()
      } catch(err) {
        console.error("Update student error:", err)
        alert("Failed to update student")
      }
    },

    async deleteStudent(student) {
      if(!confirm(`Are you sure you want to delete ${student.name}?`)) return
      try {
        await deleteDoc(doc(db, "students", student.id))
        alert("Student deleted successfully")
        this.fetchStudents()
      } catch(err) {
        console.error("Delete student error:", err)
        alert("Failed to delete student")
      }
    },

    cancelEdit() {
      this.resetForm()
    },

    resetForm() {
      this.newStudent = {
        id: null,
        name: "",
        idNumber: "",
        classId: "class_1",
        gender: "",
        branch: "",
        dob: "",
        admissionDate: "",
        parentPhone: "",
        photoUrl: "",
      }
      this.photoFile = null
      this.photoPreview = ""
      this.editing = false
    },
  }
}
</script>

<style scoped>
.students-container {
  padding: 1rem 2rem;
  background: #f0f4f8;
  min-height: 100vh;
  font-family: "Segoe UI", sans-serif;
}

.page-title {
  text-align: center;
  color: #1e3a8a;
  margin-bottom: 1rem;
  margin-top: 0.5rem;
}

.card {
  background: #fff;
  padding: 1rem;
  margin-bottom: 1rem;
  border-radius: 12px;
  box-shadow: 0 3px 8px rgba(0,0,0,0.08);
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px,1fr));
  gap: 0.6rem;
  align-items: center;
}

.filter-search-line {
  display: flex;
  gap: 2rem; /* dono items ke beech gap */
  align-items: center; /* label aur input same horizontal line me */
  flex-wrap: nowrap; /* wrap nahi hoga, hamesha ek line me rahega */
}

.filter-item {
  display: flex;
  align-items: center;
  gap: 0.4rem; /* label aur input ke beech gap */
}

.filter-item label {
  margin: 0;
  font-size: 0.85rem;
}

.small-select, .small-search-box {
  padding: 0.25rem 0.4rem;
  font-size: 0.8rem;
  border-radius: 5px;
}

input, select {
  padding: 0.4rem;
  border-radius: 6px;
  border: 1px solid #ccc;
  width: 100%;
  font-size: 0.9rem;
}

.small-select { max-width: 160px; }

.photo-upload {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.photo-preview { width: 50px; height: 50px; border-radius: 50%; object-fit: cover; margin-top: 4px; border: 2px solid #2563eb; }

.form-actions { margin-top: 0.8rem; display: flex; gap: 0.4rem; }

.primary-btn { background: #2563eb; color: #fff; padding: 0.4rem 0.8rem; border-radius: 6px; font-size: 0.9rem; cursor: pointer; }
.secondary-btn { background: #9ca3af; color: #fff; padding: 0.4rem 0.8rem; border-radius: 6px; font-size: 0.9rem; cursor: pointer; }

.edit-btn { background: #f59e0b; color:#fff; padding: 0.25rem 0.4rem; border-radius:5px; margin-right:3px; font-size:0.8rem; }
.delete-btn { background: #ef4444; color:#fff; padding: 0.25rem 0.4rem; border-radius:5px; font-size:0.8rem; }

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
}

th, td {
  padding: 0.5rem;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  font-size: 0.85rem;
}

th { background: #2563eb; color: #fff; }

.table-photo { width: 30px; height: 30px; border-radius: 50%; object-fit: cover; }

.no-data { text-align: center; color: #6b7280; padding: 0.8rem; }
</style>

