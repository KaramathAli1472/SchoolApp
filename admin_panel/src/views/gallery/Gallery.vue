<template>
  <div class="gallery-page">
    <div class="gallery-card">
      <!-- Header -->
      <div class="card-header">
        <div>
          <h2>School Gallery</h2>
          <p>Photos from school events and activities</p>
        </div>

        <button
          v-if="isTeacherOrAdmin"
          class="btn primary"
          @click="toggleForm"
        >
          {{ showForm ? 'Close' : '+ Add event' }}
        </button>
      </div>

      <!-- Add event (title + date + desc + photos) -->
      <div v-if="showForm" class="add-event">
        <div class="field-row">
          <div class="field">
            <label>Event title</label>
            <input
              v-model="form.title"
              type="text"
              placeholder="e.g. School event title"
            />
          </div>
          <div class="field">
            <label>Event date (DD/MM/YYYY)</label>
            <input
              v-model="form.eventDate"
              type="date"
            />
          </div>
        </div>

        <div class="field">
          <label>Description (optional)</label>
          <textarea
            v-model="form.description"
            rows="2"
            placeholder="Write a short description (optional)"
          ></textarea>
        </div>

        <div class="field">
          <label>Photos</label>
          <label class="upload-label">
            <input
              type="file"
              accept="image/*"
              multiple
              @change="onFilesSelected"
            />
            <span>
              {{ selectedFiles.length
                ? selectedFiles.length + ' file(s) selected'
                : 'Choose photos' }}
            </span>
          </label>
        </div>

        <div class="form-actions">
          <button
            class="btn primary"
            :disabled="uploading"
            @click="uploadEventPhotos"
          >
            {{ uploading ? 'Uploading...' : 'Save event' }}
          </button>
          <button class="btn ghost" @click="resetForm">Clear</button>
        </div>
      </div>

      <!-- Grid -->
      <div v-if="photos.length" class="photo-grid">
        <article
          v-for="photo in photos"
          :key="photo.id"
          class="photo-item"
        >
          <div class="thumb">
            <img :src="photo.url || photo.photoURLs?.[0]" :alt="photo.eventTitle" />
          </div>
          <div class="info">
            <div class="title">{{ photo.eventTitle || 'Untitled event' }}</div>
            <p v-if="photo.description" class="desc">
              {{ photo.description }}
            </p>
            <div class="meta">
              <span>
                {{ photo.eventDate
                  ? formatDate(photo.eventDate)
                  : formatDate(photo.date) }}
              </span>
            </div>
          </div>
        </article>
      </div>

      <p v-else class="empty-text">No photos uploaded yet.</p>
    </div>
  </div>
</template>

<script>
import { db, storage } from "../../services/firebase"
import { collection, getDocs, doc, setDoc } from "firebase/firestore"
import { ref, uploadBytes, getDownloadURL } from "firebase/storage"  // [web:392]

export default {
  data() {
    return {
      photos: [],
      uploading: false,
      showForm: false,
      selectedFiles: [],
      form: {
        title: "",
        description: "",
        eventDate: ""
      },
      user: JSON.parse(localStorage.getItem("user")) || {}
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return ["teacher", "admin"].includes(this.user.role)
    }
  },
  methods: {
    async fetchGallery() {
      const snap = await getDocs(collection(db, "gallery"))
      this.photos = snap.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .sort((a, b) => new Date(b.date) - new Date(a.date))
    },
    toggleForm() {
      if (!this.isTeacherOrAdmin) {
        alert("Only teachers and admins can add gallery photos.")
        return
      }
      this.showForm = !this.showForm
      if (!this.showForm) this.resetForm()
    },
    onFilesSelected(e) {
      this.selectedFiles = Array.from(e.target.files || [])
    },
    resetForm() {
      this.form = { title: "", description: "", eventDate: "" }
      this.selectedFiles = []
      this.uploading = false
    },
    async uploadEventPhotos() {
      if (!this.isTeacherOrAdmin) {
        alert("Not allowed.")
        return
      }
      if (!this.form.title) {
        alert("Event title is required.")
        return
      }
      if (!this.form.eventDate) {
        alert("Event date is required.")
        return
      }
      if (!this.selectedFiles.length) {
        alert("Please select at least one photo.")
        return
      }

      this.uploading = true
      try {
        const eventId = Date.now().toString()
        const urls = []

        for (let file of this.selectedFiles) {
          const fileId = `${eventId}_${file.name}`
          const storageRef = ref(storage, `gallery_photos/${fileId}`)
          await uploadBytes(storageRef, file)
          const url = await getDownloadURL(storageRef)
          urls.push(url)
        }

        const docRef = doc(db, "gallery", eventId)
        const payload = {
          eventTitle: this.form.title,
          description: this.form.description || "",
          eventDate: this.form.eventDate,               // YYYY-MM-DD
          date: new Date().toISOString(),              // upload date
          photoURLs: urls,
          url: urls[0],
          uploadedBy: this.user?.uid || "admin"
        }
        await setDoc(docRef, payload)

        this.photos = [{ id: eventId, ...payload }, ...this.photos]
        this.resetForm()
        this.showForm = false
        alert("Gallery event saved")
      } catch (e) {
        console.error("Gallery upload error", e)
        alert("Failed to upload event photos")
      } finally {
        this.uploading = false
      }
    },
    formatDate(dateStr) {
      if (!dateStr) return "-"
      const d = new Date(dateStr)
      if (isNaN(d)) return dateStr
      let day = d.getDate()
      let month = d.getMonth() + 1
      const year = d.getFullYear()
      day = day < 10 ? "0" + day : "" + day
      month = month < 10 ? "0" + month : "" + month
      return `${day}/${month}/${year}`   // DD/MM/YYYY [web:417][web:421]
    }
  },
  mounted() {
    this.fetchGallery()
  }
}
</script>

<style scoped>
.gallery-page {
  min-height: 100vh;
  padding: 1.5rem;
  background: #f3f4f6;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #111827;
  display: flex;
  justify-content: center;
}

.gallery-card {
  width: 100%;
  max-width: 1000px;
  background: #ffffff;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
  padding: 1rem 1.25rem 1.25rem;
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.06);
}

/* Header */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.8rem;
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
  background: #1d4ed8;
}

.btn.ghost {
  background: #f9fafb;
  color: #374151;
  border: 1px solid #d1d5db;
}

.btn.ghost:hover {
  background: #e5e7eb;
}

/* Add event form */
.add-event {
  border-top: 1px solid #e5e7eb;
  padding-top: 0.8rem;
  margin-top: 0.4rem;
  margin-bottom: 0.8rem;
}

.field-row {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
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
.field textarea {
  padding: 0.35rem 0.6rem;
  border-radius: 0.4rem;
  border: 1px solid #d1d5db;
  font-size: 0.82rem;
}

.field input:focus,
.field textarea:focus {
  outline: none;
  border-color: #2563eb;
  box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.15);
}

.upload-label {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  background: #e5e7eb;
  padding: 0.3rem 0.9rem;
  font-size: 0.8rem;
  color: #374151;
  cursor: pointer;
  width: fit-content;
}

.upload-label input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.4rem;
  margin-top: 0.4rem;
}

/* Grid */
.photo-grid {
  margin-top: 0.5rem;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
  gap: 0.9rem;
}

.photo-item {
  background: #f9fafb;
  border-radius: 0.6rem;
  border: 1px solid #e5e7eb;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.thumb {
  width: 100%;
  aspect-ratio: 4 / 3;
  background: #e5e7eb;
  overflow: hidden;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.info {
  padding: 0.4rem 0.55rem 0.5rem;
}

.title {
  font-size: 0.85rem;
  font-weight: 600;
  margin-bottom: 0.1rem;
}

.desc {
  font-size: 0.78rem;
  color: #4b5563;
  margin: 0 0 0.1rem;
}

.meta {
  font-size: 0.75rem;
  color: #6b7280;
}

.empty-text {
  margin-top: 0.6rem;
  font-size: 0.85rem;
  color: #6b7280;
}

/* Responsive */
@media (max-width: 768px) {
  .gallery-page {
    padding: 1rem;
  }
  .card-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  .field-row {
    flex-direction: column;
  }
}
</style>

