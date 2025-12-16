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
          {{ showForm ? (editingId ? 'Close edit' : 'Close') : '+ Add event' }}
        </button>
      </div>

      <!-- Add / Edit event -->
      <div v-if="showForm" class="add-event">
        <div class="field-row">
          <div class="field">
            <label>Event title</label>
            <input
              v-model="form.title"
              type="text"
              placeholder="e.g. Sports Carnival"
            />
          </div>
          <div class="field">
            <label>Event date</label>
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
          <label>Photos <span style="color:#6b7280">(optional on edit)</span></label>
          <label class="upload-label">
            <input
              type="file"
              accept="image/*"
              multiple
              @change="onFilesSelected"
            />
            <span>
              {{
                selectedFiles.length
                  ? selectedFiles.length + ' file(s) selected'
                  : editingId
                    ? 'Choose photos to ADD (optional)'
                    : 'Choose photos'
              }}
            </span>
          </label>
        </div>

        <div class="form-actions">
          <button
            class="btn primary"
            :disabled="uploading"
            @click="editingId ? updateEvent() : uploadEventPhotos()"
          >
            {{ uploading ? 'Saving...' : (editingId ? 'Update event' : 'Save event') }}
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
          @click="openDetail(photo)"
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
                {{
                  photo.eventDate
                    ? formatDate(photo.eventDate)
                    : formatDate(photo.date)
                }}
              </span>
            </div>

            <!-- Actions (Edit/Delete) -->
            <div
              v-if="isTeacherOrAdmin"
              class="actions"
              @click.stop
            >
              <button class="link-btn" @click="startEdit(photo)">Edit</button>
              <button class="link-btn danger" @click="deleteEvent(photo)">Delete</button>
            </div>
          </div>
        </article>
      </div>

      <p v-else class="empty-text">No photos uploaded yet.</p>
    </div>

    <!-- Detail modal -->
    <div v-if="detailPhoto" class="modal-backdrop" @click="closeDetail">
      <div class="modal-dialog" @click.stop>
        <button class="modal-close" @click="closeDetail">×</button>
        <div class="modal-image">
          <img :src="detailPhoto.url || detailPhoto.photoURLs?.[0]" :alt="detailPhoto.eventTitle" />
        </div>
        <div class="modal-body">
          <h3>{{ detailPhoto.eventTitle || 'Untitled event' }}</h3>
          <p class="modal-date">
            {{
              detailPhoto.eventDate
                ? formatDate(detailPhoto.eventDate)
                : formatDate(detailPhoto.date)
            }}
          </p>
          <p v-if="detailPhoto.description" class="modal-desc">
            {{ detailPhoto.description }}
          </p>
          <div
            v-if="detailPhoto.photoURLs && detailPhoto.photoURLs.length > 1"
            class="thumb-strip"
          >
            <img
              v-for="(u, idx) in detailPhoto.photoURLs"
              :key="idx"
              :src="u"
              :alt="'Photo ' + (idx + 1)"
              @click="detailPhoto.url = u"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { db } from '../../services/firebase'
import { collection, getDocs, doc, setDoc, query, orderBy, deleteDoc } from 'firebase/firestore'

const CLOUD_NAME = 'drxe5e2nk'
const UPLOAD_PRESET = 'students_photos'
const CLOUD_FOLDER = 'school_gallery'

export default {
  data() {
    return {
      photos: [],
      uploading: false,
      showForm: false,
      selectedFiles: [],
      form: {
        title: '',
        description: '',
        eventDate: ''
      },
      editingId: null,
      detailPhoto: null,
      user: JSON.parse(localStorage.getItem('user') || '{}')
    }
  },
  computed: {
    isTeacherOrAdmin() {
      return ['teacher', 'admin'].includes(this.user.role)
    }
  },
  methods: {
    async fetchGallery() {
      try {
        const q = query(collection(db, 'gallery'), orderBy('date', 'desc'))
        const snap = await getDocs(q)
        this.photos = snap.docs.map(d => ({ id: d.id, ...d.data() }))
      } catch (e) {
        console.error('Error loading gallery', e)
        alert('Failed to load gallery: ' + (e.message || e))
      }
    },
    toggleForm() {
      if (!this.isTeacherOrAdmin) {
        alert('Only teachers and admins can add gallery photos.')
        return
      }
      this.showForm = !this.showForm
      if (!this.showForm) this.resetForm()
    },
    onFilesSelected(e) {
      this.selectedFiles = Array.from(e.target.files || [])
    },
    resetForm() {
      this.form = { title: '', description: '', eventDate: '' }
      this.selectedFiles = []
      this.uploading = false
      this.editingId = null
    },
    async uploadEventPhotos() {
      if (!this.isTeacherOrAdmin) {
        alert('Not allowed.')
        return
      }
      if (!this.form.title) {
        alert('Event title is required.')
        return
      }
      if (!this.form.eventDate) {
        alert('Event date is required.')
        return
      }
      if (!this.selectedFiles.length) {
        alert('Please select at least one photo.')
        return
      }

      this.uploading = true
      try {
        const eventId = Date.now().toString()
        const urls = []

        for (const file of this.selectedFiles) {
          const formData = new FormData()
          formData.append('file', file)
          formData.append('upload_preset', UPLOAD_PRESET)
          if (CLOUD_FOLDER) formData.append('folder', CLOUD_FOLDER)

          const res = await fetch(
            `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`,
            { method: 'POST', body: formData }
          )

          if (!res.ok) {
            const txt = await res.text()
            throw new Error('Cloudinary upload failed: ' + txt)
          }

          const data = await res.json()
          urls.push(data.secure_url)
        }

        const docRef = doc(db, 'gallery', eventId)
        const payload = {
          eventTitle: this.form.title,
          description: this.form.description || '',
          eventDate: this.form.eventDate,
          date: new Date().toISOString(),
          photoURLs: urls,
          url: urls[0],
          uploadedBy: this.user?.uid || 'admin',
          storage: 'cloudinary'
        }
        await setDoc(docRef, payload)

        this.photos = [{ id: eventId, ...payload }, ...this.photos]
        this.resetForm()
        this.showForm = false
        alert('Gallery event saved')
      } catch (e) {
        console.error('Gallery upload error', e)
        alert('Failed to upload event photos: ' + (e.message || e))
      } finally {
        this.uploading = false
      }
    },
    startEdit(photo) {
      if (!this.isTeacherOrAdmin) return
      this.editingId = photo.id
      this.form = {
        title: photo.eventTitle || '',
        description: photo.description || '',
        eventDate: photo.eventDate || ''
      }
      this.selectedFiles = []
      this.showForm = true
    },
    async updateEvent() {
      if (!this.editingId) return
      if (!this.form.title) {
        alert('Event title is required.')
        return
      }
      if (!this.form.eventDate) {
        alert('Event date is required.')
        return
      }

      this.uploading = true
      try {
        const current = this.photos.find(p => p.id === this.editingId)
        const existingUrls = current?.photoURLs || (current?.url ? [current.url] : [])
        const newUrls = [...existingUrls]

        if (this.selectedFiles.length) {
          for (const file of this.selectedFiles) {
            const formData = new FormData()
            formData.append('file', file)
            formData.append('upload_preset', UPLOAD_PRESET)
            if (CLOUD_FOLDER) formData.append('folder', CLOUD_FOLDER)

            const res = await fetch(
              `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`,
              { method: 'POST', body: formData }
            )

            if (!res.ok) {
              const txt = await res.text()
              throw new Error('Cloudinary upload failed: ' + txt)
            }

            const data = await res.json()
            newUrls.push(data.secure_url)
          }
        }

        const docRef = doc(db, 'gallery', this.editingId)
        const payload = {
          eventTitle: this.form.title,
          description: this.form.description || '',
          eventDate: this.form.eventDate,
          date: current?.date || new Date().toISOString(),
          photoURLs: newUrls,
          url: newUrls[0],
          uploadedBy: current?.uploadedBy || this.user?.uid || 'admin',
          storage: 'cloudinary'
        }
        await setDoc(docRef, payload)

        this.photos = this.photos.map(p =>
          p.id === this.editingId ? { id: this.editingId, ...payload } : p
        )

        this.resetForm()
        this.showForm = false
        alert('Gallery event updated')
      } catch (e) {
        console.error('Gallery update error', e)
        alert('Failed to update event: ' + (e.message || e))
      } finally {
        this.uploading = false
      }
    },
    async deleteEvent(photo) {
      if (!this.isTeacherOrAdmin) return
      if (!confirm('Delete this gallery event?')) return
      try {
        const docRef = doc(db, 'gallery', photo.id)
        await deleteDoc(docRef)
        this.photos = this.photos.filter(p => p.id !== photo.id)
        alert('Gallery event deleted')
      } catch (e) {
        console.error('Delete error', e)
        alert('Failed to delete event: ' + (e.message || e))
      }
    },
    openDetail(photo) {
      this.detailPhoto = {
        ...photo,
        url: photo.url || (photo.photoURLs && photo.photoURLs[0]) || ''
      }
    },
    closeDetail() {
      this.detailPhoto = null
    },
    formatDate(dateStr) {
      if (!dateStr) return '-'
      const d = new Date(dateStr)
      if (isNaN(d)) return dateStr
      let day = d.getDate()
      let month = d.getMonth() + 1
      const year = d.getFullYear()
      day = day < 10 ? '0' + day : '' + day
      month = month < 10 ? '0' + month : '' + month
      return `${day}/${month}/${year}`
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
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
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
  cursor: pointer;
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

.actions {
  margin-top: 0.25rem;
  display: flex;
  gap: 0.5rem;
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
  background: rgba(15, 23, 42, 0.65);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 40;
}

.modal-dialog {
  background: #ffffff;
  border-radius: 0.75rem;
  max-width: 720px;
  width: 95%;
  max-height: 90vh;
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
}

.modal-close {
  position: absolute;
  top: 0.35rem;
  right: 0.5rem;
  border: none;
  background: transparent;
  font-size: 1.4rem;
  line-height: 1;
  cursor: pointer;
}

.modal-image {
  background: #000;
  max-height: 420px;
  overflow: hidden;
}

.modal-image img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}

.modal-body {
  padding: 0.75rem 0.9rem 0.9rem;
}

.modal-body h3 {
  margin: 0 0 0.2rem;
  font-size: 1.1rem;
  font-weight: 600;
}

.modal-date {
  margin: 0;
  font-size: 0.82rem;
  color: #6b7280;
}

.modal-desc {
  margin: 0.4rem 0 0.2rem;
  font-size: 0.85rem;
}

.thumb-strip {
  margin-top: 0.4rem;
  display: flex;
  gap: 0.3rem;
  overflow-x: auto;
}

.thumb-strip img {
  width: 60px;
  height: 45px;
  object-fit: cover;
  border-radius: 0.25rem;
  cursor: pointer;
  border: 2px solid transparent;
}

.thumb-strip img:hover {
  border-color: #2563eb;
}

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

