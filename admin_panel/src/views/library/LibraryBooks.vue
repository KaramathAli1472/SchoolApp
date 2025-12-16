<template>
  <div class="library-page">
    <div class="card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>Library Books</h2>
          <p>Manage books available in school library</p>
        </div>
        <button class="btn primary" @click="openForm()">
          + Add book
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
          <label>Subject</label>
          <input
            v-model="filters.subject"
            type="text"
            placeholder="e.g. Maths"
          />
        </div>

        <div class="field">
          <label>Search</label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Title / Author"
          />
        </div>

        <button class="btn ghost" @click="applyFilters">Apply</button>
        <button class="btn ghost" @click="clearFilters">Clear</button>
      </div>

      <!-- Summary -->
      <div class="summary" v-if="books.length">
        <div class="summary-item">
          <span class="summary-label">Total books</span>
          <span class="summary-value">{{ books.length }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Total copies</span>
          <span class="summary-value">{{ totalCopies }}</span>
        </div>
        <div class="summary-item">
          <span class="summary-label">Available copies</span>
          <span class="summary-value">{{ totalAvailable }}</span>
        </div>
      </div>

      <!-- Table -->
      <div v-if="filteredBooks.length" class="table-wrapper">
        <table class="books-table">
          <thead>
            <tr>
              <th>Title</th>
              <th>Author</th>
              <th>Subject</th>
              <th>Class</th>
              <th>ISBN</th>
              <th>Rack</th>
              <th>Total</th>
              <th>Available</th>
              <th style="width: 90px;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in filteredBooks" :key="b.id">
              <td>{{ b.title }}</td>
              <td>{{ b.author }}</td>
              <td>{{ b.subject }}</td>
              <td>{{ b.classId }}</td>
              <td>{{ b.isbn || '-' }}</td>
              <td>{{ b.rackNo || '-' }}</td>
              <td>{{ b.totalCopies }}</td>
              <td>{{ b.availableCopies }}</td>
              <td>
                <button class="link-btn" @click="openForm(b)">Edit</button>
                <button class="link-btn danger" @click="deleteBook(b)">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <p v-else class="empty-text">
        No books found. Click "Add book" to create a new record.
      </p>
    </div>

    <!-- Add/Edit modal -->
    <div v-if="showForm" class="modal-backdrop">
      <div class="modal">
        <h3>{{ editingId ? 'Edit book' : 'Add book' }}</h3>

        <div class="field">
          <label>Title</label>
          <input v-model="form.title" type="text" placeholder="Book title" />
        </div>
        <div class="field">
          <label>Author</label>
          <input v-model="form.author" type="text" placeholder="Author name" />
        </div>

        <div class="field-row">
          <div class="field">
            <label>Subject</label>
            <input
              v-model="form.subject"
              type="text"
              placeholder="e.g. Science"
            />
          </div>
          <div class="field">
            <label>Class</label>
            <select v-model="form.classId">
              <option disabled value="">Select class</option>
              <option v-for="cls in classOptions" :key="cls" :value="cls">
                {{ cls }}
              </option>
            </select>
          </div>
        </div>

        <div class="field-row">
          <div class="field">
            <label>ISBN (optional)</label>
            <input v-model="form.isbn" type="text" placeholder="ISBN" />
          </div>
          <div class="field">
            <label>Rack No (optional)</label>
            <input
              v-model="form.rackNo"
              type="text"
              placeholder="Rack / Shelf"
            />
          </div>
        </div>

        <div class="field-row">
          <div class="field">
            <label>Total copies</label>
            <input
              v-model.number="form.totalCopies"
              type="number"
              min="0"
              placeholder="0"
            />
          </div>
          <div class="field">
            <label>Available copies</label>
            <input
              v-model.number="form.availableCopies"
              type="number"
              min="0"
              placeholder="0"
            />
          </div>
        </div>

        <p v-if="error" class="error-text">{{ error }}</p>

        <div class="modal-actions">
          <button class="btn ghost" @click="closeForm">Cancel</button>
          <button class="btn primary" :disabled="saving" @click="saveBook">
            {{ saving ? 'Saving...' : (editingId ? 'Update' : 'Save') }}
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
  addDoc,
  doc,
  setDoc,
  deleteDoc,
  serverTimestamp,
  orderBy,
  query
} from "firebase/firestore"

export default {
  name: "LibraryBooks",
  data() {
    return {
      books: [],
      filters: {
        classId: "",
        subject: "",
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
      showForm: false,
      saving: false,
      editingId: null,
      error: "",
      form: {
        title: "",
        author: "",
        subject: "",
        classId: "",
        isbn: "",
        rackNo: "",
        totalCopies: 0,
        availableCopies: 0
      }
    }
  },
  computed: {
    filteredBooks() {
      let list = [...this.books]

      if (this.filters.classId) {
        list = list.filter(b => b.classId === this.filters.classId)
      }
      if (this.filters.subject) {
        const s = this.filters.subject.toLowerCase()
        list = list.filter(b => (b.subject || "").toLowerCase().includes(s))
      }
      if (this.filters.search) {
        const s = this.filters.search.toLowerCase()
        list = list.filter(
          b =>
            (b.title || "").toLowerCase().includes(s) ||
            (b.author || "").toLowerCase().includes(s)
        )
      }
      return list
    },
    totalCopies() {
      return this.books.reduce((sum, b) => sum + (Number(b.totalCopies) || 0), 0)
    },
    totalAvailable() {
      return this.books.reduce(
        (sum, b) => sum + (Number(b.availableCopies) || 0),
        0
      )
    }
  },
  methods: {
    async loadBooks() {
      try {
        const q = query(
          collection(db, "libraryBooks"),
          orderBy("createdAt", "desc")
        )
        const snap = await getDocs(q)
        this.books = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (e) {
        console.error("Error loading books", e)
        alert("Failed to load library books")
      }
    },
    applyFilters() {
      // filteredBooks computed hai, yahan kuch nahi karna
    },
    clearFilters() {
      this.filters = { classId: "", subject: "", search: "" }
    },
    openForm(book) {
      this.error = ""
      if (book) {
        this.editingId = book.id
        this.form = {
          title: book.title || "",
          author: book.author || "",
          subject: book.subject || "",
          classId: book.classId || "",
          isbn: book.isbn || "",
          rackNo: book.rackNo || "",
          totalCopies: Number(book.totalCopies) || 0,
          availableCopies: Number(book.availableCopies) || 0
        }
      } else {
        this.editingId = null
        this.form = {
          title: "",
          author: "",
          subject: "",
          classId: "",
          isbn: "",
          rackNo: "",
          totalCopies: 0,
          availableCopies: 0
        }
      }
      this.showForm = true
    },
    closeForm() {
      this.showForm = false
    },
    validate() {
      if (!this.form.title) {
        this.error = "Title is required."
        return false
      }
      if (!this.form.author) {
        this.error = "Author is required."
        return false
      }
      if (!this.form.classId) {
        this.error = "Class is required."
        return false
      }
      if (this.form.totalCopies < 0 || this.form.availableCopies < 0) {
        this.error = "Copies cannot be negative."
        return false
      }
      if (this.form.availableCopies > this.form.totalCopies) {
        this.error = "Available copies cannot be more than total copies."
        return false
      }
      this.error = ""
      return true
    },
    async saveBook() {
      if (!this.validate()) return

      this.saving = true
      try {
        const payload = {
          title: this.form.title.trim(),
          author: this.form.author.trim(),
          subject: this.form.subject.trim(),
          classId: this.form.classId,
          isbn: this.form.isbn.trim(),
          rackNo: this.form.rackNo.trim(),
          totalCopies: Number(this.form.totalCopies),
          availableCopies: Number(this.form.availableCopies),
          updatedAt: serverTimestamp()
        }

        if (this.editingId) {
          const ref = doc(db, "libraryBooks", this.editingId)
          await setDoc(ref, payload, { merge: true })
        } else {
          await addDoc(collection(db, "libraryBooks"), {
            ...payload,
            createdAt: serverTimestamp()
          })
        }

        await this.loadBooks()
        this.showForm = false
      } catch (e) {
        console.error("Error saving book", e)
        alert("Failed to save book")
      } finally {
        this.saving = false
      }
    },
    async deleteBook(book) {
      if (!confirm(`Delete "${book.title}"?`)) return
      try {
        await deleteDoc(doc(db, "libraryBooks", book.id))
        this.books = this.books.filter(b => b.id !== book.id)
      } catch (e) {
        console.error("Error deleting book", e)
        alert("Failed to delete book")
      }
    }
  },
  mounted() {
    this.loadBooks()
  }
}
</script>

<style scoped>
.library-page {
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
  max-width: 1100px;
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
.field select {
  padding: 0.35rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.82rem;
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
.books-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.82rem;
}
.books-table thead {
  background: #f3f4f6;
}
.books-table th,
.books-table td {
  padding: 0.45rem 0.5rem;
  border-bottom: 1px solid #e5e7eb;
  text-align: left;
}
.books-table th {
  font-weight: 600;
  color: #4b5563;
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
  width: 420px;
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

@media (max-width: 768px) {
  .library-page {
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

