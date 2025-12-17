<template>
  <div class="settings-root">
    <div class="settings-card">
      <!-- Top bar -->
      <div class="settings-header">
        <div>
          <h2 class="settings-title">School Settings</h2>
          <p class="settings-subtitle">
            Manage basic details and enable/disable modules for the school app.
          </p>
        </div>

        <div class="settings-actions">
          <button class="btn-secondary" @click="loadSettings">
            Refresh
          </button>
          <button
            class="btn-primary"
            :class="{ 'btn-disabled': saving }"
            :disabled="saving"
            @click="saveSettings"
          >
            <span v-if="saving" class="spinner"></span>
            <span v-if="!saving">Save Changes</span>
            <span v-else>Saving...</span>
          </button>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="info-banner">
        Loading settings, please wait...
      </div>

      <div v-else>
        <!-- General info -->
        <section class="section">
          <div class="section-header">
            <div class="section-chip section-chip-blue">General</div>
            <div>
              <h3 class="section-title">School Information</h3>
              <p class="section-desc">
                Basic details shown in app header and profile.
              </p>
            </div>
          </div>

          <div class="form-grid">
            <div class="form-field">
              <label>School Name</label>
              <input
                v-model="form.schoolName"
                type="text"
                placeholder="Enter school name"
              />
            </div>

            <div class="form-field">
              <label>Academic Year</label>
              <input
                v-model="form.academicYear"
                type="text"
                placeholder="e.g. 2025-26"
              />
            </div>

            <div class="form-field">
              <label>Phone</label>
              <input
                v-model="form.phone"
                type="text"
                placeholder="School phone number"
              />
            </div>

            <div class="form-field">
              <label>Email</label>
              <input
                v-model="form.email"
                type="email"
                placeholder="School email"
              />
            </div>

            <div class="form-field form-field-full">
              <label>Address</label>
              <textarea
                v-model="form.address"
                rows="2"
                placeholder="Full address"
              ></textarea>
            </div>

            <div class="form-field">
              <label>Logo URL</label>
              <input
                v-model="form.logoUrl"
                type="text"
                placeholder="https://example.com/logo.png"
              />
              <p class="field-hint">
                Use Firebase Storage public URL or any accessible image URL.
              </p>
            </div>

            <div class="form-field form-field-full" v-if="form.logoUrl">
              <label>Logo Preview</label>
              <div class="logo-box">
                <img :src="form.logoUrl" alt="Logo preview" />
              </div>
            </div>
          </div>
        </section>

        <!-- Modules / Features -->
        <section class="section">
          <div class="section-header">
            <div class="section-chip section-chip-green">Modules</div>
            <div>
              <h3 class="section-title">Features Visibility</h3>
              <p class="section-desc">
                Enable or disable modules in mobile app & admin portal.
              </p>
            </div>
          </div>

          <div class="feature-grid">
            <div class="feature-card">
              <div class="feature-text">
                <div class="feature-title">Gate Pass</div>
                <div class="feature-sub">
                  Allow parents to request gate pass for students.
                </div>
              </div>
              <label class="switch">
                <input type="checkbox" v-model="form.gatePassEnabled" />
                <span class="slider"></span>
              </label>
            </div>

            <div class="feature-card">
              <div class="feature-text">
                <div class="feature-title">Parent Concern</div>
                <div class="feature-sub">
                  Parents can raise concerns to teachers/admin.
                </div>
              </div>
              <label class="switch">
                <input type="checkbox" v-model="form.parentConcernEnabled" />
                <span class="slider"></span>
              </label>
            </div>

            <div class="feature-card">
              <div class="feature-text">
                <div class="feature-title">Notice Board</div>
                <div class="feature-sub">
                  Show announcements / circulars in app.
                </div>
              </div>
              <label class="switch">
                <input type="checkbox" v-model="form.noticeEnabled" />
                <span class="slider"></span>
              </label>
            </div>

            <div class="feature-card">
              <div class="feature-text">
                <div class="feature-title">Homework</div>
                <div class="feature-sub">
                  Enable homework module for classes.
                </div>
              </div>
              <label class="switch">
                <input type="checkbox" v-model="form.homeworkEnabled" />
                <span class="slider"></span>
              </label>
            </div>
          </div>
        </section>

        <!-- Message -->
        <div v-if="message" class="message-wrapper">
          <div
            class="message"
            :class="messageType === 'success' ? 'message-success' : 'message-error'"
          >
            {{ message }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { doc, getDoc, setDoc } from 'firebase/firestore' // v9 modular API [web:331]
import { db } from '../../firebase'

const loading = ref(true)
const saving = ref(false)
const message = ref('')
const messageType = ref('success')

const defaultForm = {
  schoolName: '',
  academicYear: '',
  phone: '',
  email: '',
  address: '',
  logoUrl: '',
  gatePassEnabled: true,
  parentConcernEnabled: true,
  noticeEnabled: true,
  homeworkEnabled: true
}

const form = ref({ ...defaultForm })
const settingsRef = doc(db, 'settings', 'general') // [web:331]

async function loadSettings () {
  loading.value = true
  message.value = ''

  try {
    const snap = await getDoc(settingsRef)
    if (snap.exists()) {
      form.value = { ...defaultForm, ...snap.data() }
    } else {
      await setDoc(settingsRef, defaultForm, { merge: true })
      form.value = { ...defaultForm }
    }
  } catch (err) {
    console.error('Error loading settings', err)
    message.value = 'Failed to load settings'
    messageType.value = 'error'
  } finally {
    loading.value = false
  }
}

async function saveSettings () {
  saving.value = true
  message.value = ''

  try {
    await setDoc(settingsRef, form.value, { merge: true }) // [web:331]
    message.value = 'Settings saved successfully'
    messageType.value = 'success'
  } catch (err) {
    console.error('Error saving settings', err)
    message.value = 'Failed to save settings'
    messageType.value = 'error'
  } finally {
    saving.value = false
  }
}

loadSettings()
</script>

<style scoped>
/* Page shell */
.settings-root {
  display: flex;
  justify-content: center;
  padding: 24px 16px;
  background: #f3f4f6;
}
.settings-card {
  width: 100%;
  max-width: 980px;
  background: #ffffff;
  border-radius: 10px;
  padding: 20px 22px 24px;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.06);
}

/* Header */
.settings-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 12px;
}
.settings-title {
  margin: 0;
  font-size: 22px;
  font-weight: 600;
}
.settings-subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: #6b7280;
}
.settings-actions {
  display: flex;
  gap: 8px;
}

/* Buttons */
.btn-primary,
.btn-secondary {
  border: none;
  border-radius: 999px;
  padding: 6px 14px;
  font-size: 13px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.btn-primary {
  background: #2563eb;
  color: #ffffff;
}
.btn-primary:hover {
  background: #1d4ed8;
}
.btn-secondary {
  background: #e5e7eb;
  color: #374151;
}
.btn-secondary:hover {
  background: #d1d5db;
}
.btn-disabled {
  opacity: 0.7;
  cursor: default;
}

/* Spinner */
.spinner {
  width: 14px;
  height: 14px;
  border-radius: 999px;
  border: 2px solid #ffffff;
  border-top-color: transparent;
  animation: spin 0.7s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* Info banner */
.info-banner {
  margin-top: 8px;
  margin-bottom: 10px;
  padding: 8px 10px;
  border-radius: 6px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 13px;
}

/* Sections */
.section {
  margin-top: 16px;
  padding: 14px 14px 16px;
  border-radius: 10px;
  border: 1px solid #e5e7eb;
  background: #fafafa;
}
.section-header {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 12px;
}
.section-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
}
.section-desc {
  margin: 3px 0 0;
  font-size: 12px;
  color: #6b7280;
}
.section-chip {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 999px;
  color: #ffffff;
  margin-top: 2px;
}
.section-chip-blue {
  background: #3b82f6;
}
.section-chip-green {
  background: #22c55e;
}

/* Form grid */
.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px 16px;
}
.form-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.form-field-full {
  grid-column: 1 / -1;
}
.form-field label {
  font-size: 13px;
  font-weight: 500;
  color: #374151;
}
.form-field input,
.form-field textarea {
  font-size: 13px;
  padding: 6px 8px;
  border-radius: 6px;
  border: 1px solid #d1d5db;
  outline: none;
  background: #ffffff;
}
.form-field input:focus,
.form-field textarea:focus {
  border-color: #2563eb;
  box-shadow: 0 0 0 1px rgba(37, 99, 235, 0.2);
}
.field-hint {
  margin: 2px 0 0;
  font-size: 11px;
  color: #6b7280;
}

/* Logo */
.logo-box {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 140px;
  min-height: 70px;
  padding: 6px 10px;
  border-radius: 8px;
  border: 1px dashed #d1d5db;
  background: #f9fafb;
}
.logo-box img {
  max-height: 60px;
  max-width: 100%;
  object-fit: contain;
}

/* Features */
.feature-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px 14px;
}
.feature-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 10px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  background: #ffffff;
}
.feature-card:hover {
  background: #f3f4ff;
}
.feature-title {
  font-size: 13px;
  font-weight: 600;
  color: #111827;
}
.feature-sub {
  font-size: 11px;
  color: #6b7280;
  margin-top: 2px;
}

/* Custom switch */
.switch {
  position: relative;
  display: inline-block;
  width: 38px;
  height: 20px;
}
.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}
.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #d1d5db;
  transition: 0.2s;
  border-radius: 999px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 14px;
  width: 14px;
  left: 3px;
  top: 3px;
  background-color: white;
  transition: 0.2s;
  border-radius: 50%;
}
.switch input:checked + .slider {
  background-color: #22c55e;
}
.switch input:checked + .slider:before {
  transform: translateX(16px);
}

/* Messages */
.message-wrapper {
  margin-top: 10px;
}
.message {
  font-size: 13px;
  padding: 6px 10px;
  border-radius: 6px;
}
.message-success {
  background: #ecfdf5;
  color: #15803d;
}
.message-error {
  background: #fef2f2;
  color: #b91c1c;
}

/* Responsive */
@media (max-width: 768px) {
  .settings-card {
    padding: 16px 12px 20px;
  }
  .settings-header {
    flex-direction: column;
    align-items: flex-start;
  }
  .settings-actions {
    margin-top: 6px;
  }
  .form-grid,
  .feature-grid {
    grid-template-columns: 1fr;
  }
}
</style>

