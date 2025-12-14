<template>
  <div class="homework-container">
    <h2>Homework Management</h2>

    <div class="controls">
      <label>Select Class:</label>
      <select v-model="selectedClass" @change="fetchHomework">
        <option
          v-for="cls in classes"
          :key="cls.id"
          :value="cls.id"
        >
          {{ cls.label }}
        </option>
      </select>

      <button @click="addHomework">+ Add Homework</button>
    </div>

    <table v-if="homeworks.length">
      <thead>
        <tr>
          <th>Title</th>
          <th>Description</th>
          <th>Date</th>
          <th>Deadline</th>
          <th>Uploaded By</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="hw in homeworks" :key="hw.id">
          <td>{{ hw.title }}</td>
          <td>{{ hw.description }}</td>
          <td>{{ hw.date }}</td>
          <td>{{ hw.deadline }}</td>
          <td>{{ hw.uploadedBy }}</td>
          <td>
            <button @click="editHomework(hw)">Edit</button>
            <button @click="deleteHomework(hw.id)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>

    <p v-else>No homework found for this class.</p>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import {
  collection,
  doc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where
} from "firebase/firestore"

export default {
  data() {
    return {
      // Same pattern as attendance/students: class_1..class_10
      classes: Array.from({ length: 10 }, (_, i) => ({
        id: `class_${i + 1}`,
        label: `Class ${i + 1}`
      })),
      selectedClass: "class_1",
      homeworks: [],
      user: JSON.parse(localStorage.getItem("user")) || {}
    }
  },
  methods: {
    async fetchHomework() {
      try {
        const homeworkRef = collection(db, "homework")
        const q = query(homeworkRef, where("classId", "==", this.selectedClass))
        const snap = await getDocs(q)
        this.homeworks = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (err) {
        console.error("Error fetching homework:", err)
      }
    },

    async addHomework() {
      const title = prompt("Enter homework title")
      const description = prompt("Enter homework description")
      const deadline = prompt("Enter deadline (YYYY-MM-DD)")
      if (!title || !description || !deadline) return

      try {
        await addDoc(collection(db, "homework"), {
          title,
          description,
          date: new Date().toISOString().substr(0, 10), // today [web:139]
          deadline,
          classId: this.selectedClass,
          uploadedBy: this.user.name || "Admin"
        })
        this.fetchHomework()
      } catch (err) {
        console.error("Error adding homework:", err)
        alert("Failed to add homework")
      }
    },

    async editHomework(hw) {
      const title = prompt("Edit title", hw.title)
      const description = prompt("Edit description", hw.description)
      const deadline = prompt("Edit deadline (YYYY-MM-DD)", hw.deadline)
      if (!title || !description || !deadline) return

      try {
        await updateDoc(doc(db, "homework", hw.id), {
          title,
          description,
          deadline
        })
        this.fetchHomework()
      } catch (err) {
        console.error("Error updating homework:", err)
        alert("Failed to update homework")
      }
    },

    async deleteHomework(id) {
      if (!confirm("Are you sure you want to delete this homework?")) return
      try {
        await deleteDoc(doc(db, "homework", id))
        this.fetchHomework()
      } catch (err) {
        console.error("Error deleting homework:", err)
        alert("Failed to delete homework")
      }
    }
  },
  mounted() {
    this.fetchHomework()
  }
}
</script>

<style scoped>
.homework-container {
  padding: 2rem;
  background: #f5f5f5;
  min-height: 100vh;
}

.controls {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  align-items: center;
}

.controls select {
  padding: 0.4rem 0.6rem;
  border-radius: 4px;
  border: 1px solid #ccc;
}

.controls button {
  padding: 0.5rem 1rem;
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

.controls button:hover {
  background: #45a049;
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
  text-align: left;
}

th {
  background: #2196F3;
  color: white;
}

td button {
  margin-right: 0.3rem;
  padding: 0.3rem 0.6rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

td button:first-child {
  background: #FF9800;
  color: white;
}

td button:first-child:hover {
  background: #FB8C00;
}

td button:last-child {
  background: #F44336;
  color: white;
}

td button:last-child:hover {
  background: #D32F2F;
}
</style>

