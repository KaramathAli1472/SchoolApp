<template>
  <div class="homework-container">
    <!-- Title with icon -->
    <h2 class="title">
      <svg xmlns="http://www.w3.org/2000/svg" class="icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M12 6v6h6m-6 0H6m6 0v6m0-6H6m6 0v-6m0 0h6m-6 0H6"/>
      </svg>
      Homework Management
    </h2>

    <!-- Controls for admin/teacher -->
    <div class="controls" v-if="isTeacherOrAdmin">
      <label>Select Class:</label>
      <select class="class-select" v-model="selectedClass" @change="fetchHomework">
        <option value="all">All Classes</option>
        <option v-for="cls in classes" :key="cls.id" :value="cls.id">
          {{ cls.name }}
        </option>
      </select>

      <button @click="showAddHomework = true">
        <svg xmlns="http://www.w3.org/2000/svg" class="button-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Add Homework
      </button>
    </div>

    <!-- Add Homework Modal -->
    <div v-if="showAddHomework" class="modal">
      <div class="modal-content">
        <h3>Add Homework</h3>

        <label>Class:</label>
        <select v-model="newHomework.classId">
          <option disabled value="">Select Class</option>
          <option v-for="cls in classes" :key="cls.id" :value="cls.id">{{ cls.name }}</option>
        </select>

        <label>Subject:</label>
        <input v-model="newHomework.subject" placeholder="Enter subject" />

        <label>Title:</label>
        <input v-model="newHomework.title" placeholder="Enter title" />

        <label>Description:</label>
        <textarea v-model="newHomework.description" placeholder="Enter description"></textarea>

        <label>Deadline:</label>
        <input type="date" v-model="newHomework.deadline" />

        <div class="modal-actions">
          <button @click="addHomework">Save</button>
          <button @click="showAddHomework = false">Cancel</button>
        </div>
      </div>
    </div>

    <!-- Homework Table -->
    <table v-if="homeworks.length">
      <thead>
        <tr>
          <th>Title</th>
          <th>Class</th>
          <th>Subject</th>
          <th>Description</th>
          <th>Date</th>
          <th>Deadline</th>
          <th>Uploaded By</th>
          <th v-if="isTeacherOrAdmin">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="hw in homeworks" :key="hw.id">
          <td>{{ hw.title }}</td>
          <td>{{ getClassName(hw.classId) }}</td>
          <td>{{ hw.subject }}</td>
          <td>{{ hw.description }}</td>
          <td>{{ hw.date }}</td>
          <td>{{ hw.deadline }}</td>
          <td>{{ hw.uploadedBy }}</td>
          <td v-if="isTeacherOrAdmin">
            <button @click="editHomework(hw)">Edit</button>
            <button @click="deleteHomework(hw.id)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else>No homework found.</p>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import { collection, doc, getDocs, addDoc, updateDoc, deleteDoc, query, where } from "firebase/firestore"

export default {
  data() {
    return {
      classes: Array.from({ length: 10 }, (_, i) => ({ id: `class_${i + 1}`, name: `Class ${i + 1}` })),
      selectedClass: "all",
      homeworks: [],
      user: JSON.parse(localStorage.getItem("user")) || {},
      showAddHomework: false,
      newHomework: { classId: "", subject: "", title: "", description: "", deadline: "" }
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return this.user.role === "teacher" || this.user.role === "admin"
    }
  },
  methods: {
    getClassName(classId) {
      if (classId === "all") return "All Classes"
      const cls = this.classes.find(c => c.id === classId)
      return cls ? cls.name : "N/A"
    },
    async fetchHomework() {
      try {
        const homeworkRef = collection(db, "homework")
        let snap
        if (this.selectedClass === "all") {
          snap = await getDocs(homeworkRef)
        } else {
          const q = query(homeworkRef, where("classId", "==", this.selectedClass))
          snap = await getDocs(q)
        }
        this.homeworks = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (err) { console.error("Error fetching homework:", err) }
    },
    async addHomework() {
      if (!this.isTeacherOrAdmin) return alert("You are not authorized.")
      const { classId, subject, title, description, deadline } = this.newHomework
      if (!classId || !subject || !title || !description || !deadline)
        return alert("Please fill all fields.")
      try {
        await addDoc(collection(db, "homework"), {
          classId, subject, title, description,
          date: new Date().toISOString().substr(0, 10),
          deadline, uploadedBy: this.user.name || "Admin"
        })
        this.showAddHomework = false
        this.newHomework = { classId: "", subject: "", title: "", description: "", deadline: "" }
        this.fetchHomework()
      } catch (err) {
        console.error("Error adding homework:", err)
        alert("Failed to add homework")
      }
    },
    async editHomework(hw) {
      if (!this.isTeacherOrAdmin) return alert("You are not authorized.")
      const classObj = this.classes.find(c => c.id === hw.classId) || this.classes[0]
      const selectedClass = prompt("Edit class name:", classObj.name)
      const newClassObj = this.classes.find(c => c.name === selectedClass)
      if (!newClassObj) return alert("Invalid class")
      const subject = prompt("Edit subject:", hw.subject)
      const title = prompt("Edit title:", hw.title)
      const description = prompt("Edit description:", hw.description)
      const deadline = prompt("Edit deadline:", hw.deadline)
      try {
        await updateDoc(doc(db, "homework", hw.id), {
          classId: newClassObj.id, subject, title, description, deadline
        })
        this.fetchHomework()
      } catch (err) { console.error("Error updating homework:", err); alert("Failed to update homework") }
    },
    async deleteHomework(id) {
      if (!this.isTeacherOrAdmin) return alert("You are not authorized.")
      if (!confirm("Are you sure you want to delete this homework?")) return
      try { await deleteDoc(doc(db, "homework", id)); this.fetchHomework() }
      catch (err) { console.error("Error deleting homework:", err); alert("Failed to delete homework") }
    }
  },
  mounted() { this.fetchHomework() }
}
</script>

<style scoped>
.homework-container { padding: 2rem; background: #f5f5f5; min-height: 100vh; }
.title { display: flex; align-items: center; gap: 0.5rem; font-size: 1.8rem; color: #2196F3; margin-bottom: 1.5rem; }
.icon { width: 28px; height: 28px; color: #2196F3; }

.controls { display: flex; gap: 1rem; margin-bottom: 1rem; align-items: center; }
.controls .class-select { padding: 0.4rem 0.6rem; border-radius: 4px; border: 1px solid #ccc; width: 150px; }
.controls button { display: flex; align-items: center; gap: 0.3rem; padding: 0.4rem 0.8rem; background: #4CAF50; color: white; border: none; border-radius: 5px; cursor: pointer; }
.controls button:hover { background: #45a049; }
.button-icon { width: 18px; height: 18px; }

.modal select, .modal input, .modal textarea { padding: 0.4rem 0.6rem; border-radius: 4px; border: 1px solid #ccc; width: 100%; margin-bottom: 0.5rem; }
table { width: 100%; border-collapse: collapse; background: white; }
th, td { border: 1px solid #ccc; padding: 0.8rem; text-align: left; }
th { background: #2196F3; color: white; }
td button { margin-right: 0.3rem; padding: 0.3rem 0.6rem; border: none; border-radius: 4px; cursor: pointer; }
td button:first-child { background: #FF9800; color: white; }
td button:first-child:hover { background: #FB8C00; }
td button:last-child { background: #F44336; color: white; }
td button:last-child:hover { background: #D32F2F; }

.modal { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: flex; justify-content: center; align-items: center; }
.modal-content { background: white; padding: 1rem; border-radius: 5px; width: 400px; }
.modal-actions { display: flex; justify-content: flex-end; gap: 0.5rem; }
</style>

