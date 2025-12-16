<template>
  <div class="page">
    <h2>📅 Event Calendar</h2>

    <FullCalendar ref="calendarRef" :options="calendarOptions" />

    <div class="tabs">
      <button
        class="tab"
        :class="{ active: activeTab === 'events' }"
        @click="activeTab = 'events'"
      >
        Events
      </button>
      <button
        class="tab"
        :class="{ active: activeTab === 'holidays' }"
        @click="activeTab = 'holidays'"
      >
        Holidays
      </button>
    </div>

    <div v-if="selectedDate" class="selected-date">
      {{ formatDate(selectedDate) }}
    </div>

    <div class="list">
      <div
        v-for="item in selectedDayItems"
        :key="item.id"
        class="card"
      >
        <div class="card-tag" :style="{ backgroundColor: item.tagColor }">
          {{ item.tagLabel }}
        </div>

        <div class="card-body">
          <div class="card-icon">📅</div>

          <div class="card-text">
            <div class="card-title">{{ item.title }}</div>
            <div class="card-subtitle">{{ item.subtitle }}</div>
          </div>

          <div class="card-actions">
            <button class="small-btn edit" @click="editItem(item)">Edit</button>
            <button class="small-btn delete" @click="deleteItem(item)">Delete</button>
          </div>
        </div>
      </div>

      <p v-if="selectedDayItems.length === 0 && selectedDate" class="empty-text">
        No items for this date. Click on the calendar date to add one.
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted } from 'vue'
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
import interactionPlugin from '@fullcalendar/interaction'
import {
  collection,
  addDoc,
  onSnapshot,
  query,
  orderBy,
  doc,
  updateDoc,
  deleteDoc
} from 'firebase/firestore'
import { db } from '../../firebase'

const calendarRef = ref(null)

const eventsColRef = collection(db, 'schoolEvents')

const allItems = ref([])
const activeTab = ref('events')
const selectedDate = ref(null)

onMounted(() => {
  const q = query(eventsColRef, orderBy('date', 'asc'))
  onSnapshot(q, (snap) => {
    const arr = []
    snap.forEach(docSnap => {
      const data = docSnap.data() || {}
      arr.push({
        id: docSnap.id,
        type: data.type || 'event',
        title: data.title || '',
        subtitle: data.subtitle || '',
        date: data.date || '',
        endDate: data.endDate || data.date || '',
        tagLabel: data.tagLabel || (data.type === 'holiday' ? 'Holiday' : 'Event'),
        tagColor: data.tagColor || '#009966'
      })
    })
    allItems.value = arr
  })
})

const events = computed(() =>
  allItems.value
    .filter(item => item.date)
    .map(item => ({
      id: item.id,
      title: item.title,
      start: item.date,
      allDay: true,
      color: item.tagColor
    }))
)

async function handleDateClick(info) {
  selectedDate.value = info.dateStr

  const type = prompt('Type "event" or "holiday" for this date?')
  if (!type || (type !== 'event' && type !== 'holiday')) return

  const title = prompt('Enter main title (e.g. FA - 3, Sports Carnival)')
  if (!title) return

  const subtitle = prompt('Enter subtitle (optional)') || ''
  const tagLabel = type === 'holiday' ? 'Holiday' : 'Event'
  const tagColor =
    prompt('Enter color hex (e.g. #ff0000) or leave empty', '#009966') ||
    '#009966'

  const payload = {
    type,
    title,
    subtitle,
    date: info.dateStr,
    endDate: info.dateStr,
    tagLabel,
    tagColor
  }

  try {
    await addDoc(eventsColRef, payload)
  } catch (e) {
    console.error('Error adding document: ', e)
    alert('Failed to save event in Firebase')
  }

  nextTick(() => {
    if (calendarRef.value) {
      const api = calendarRef.value.getApi()
      api.gotoDate(info.date)
    }
  })
}

// Edit selected card (update Firestore)
async function editItem(item) {
  const newTitle = prompt('Edit title', item.title)
  if (!newTitle) return

  const newSubtitle = prompt('Edit subtitle', item.subtitle || '') || ''
  const newTagLabel = prompt('Edit tag label', item.tagLabel) || item.tagLabel
  const newColor =
    prompt('Edit color hex', item.tagColor || '#009966') ||
    item.tagColor

  const ref = doc(eventsColRef, item.id)

  try {
    await updateDoc(ref, {
      title: newTitle,
      subtitle: newSubtitle,
      tagLabel: newTagLabel,
      tagColor: newColor
    }) // snapshot se allItems/ calendar auto refresh[web:51][web:68]
  } catch (e) {
    console.error('Error updating document:', e)
    alert('Failed to update event')
  }
}

// Delete selected card (remove from Firestore)
async function deleteItem(item) {
  const ok = confirm('Delete this item?')
  if (!ok) return

  const ref = doc(eventsColRef, item.id)

  try {
    await deleteDoc(ref) // snapshot se list + calendar se bhi hat jayega[web:51][web:68]
  } catch (e) {
    console.error('Error deleting document:', e)
    alert('Failed to delete event')
  }
}

const calendarOptions = ref({
  plugins: [dayGridPlugin, interactionPlugin],
  initialView: 'dayGridMonth',
  height: 400,
  events,
  dateClick: handleDateClick
})

const selectedDayItems = computed(() => {
  if (!selectedDate.value) return []
  return allItems.value.filter(item => {
    if (item.date !== selectedDate.value) return false
    if (activeTab.value === 'events' && item.type !== 'event') return false
    if (activeTab.value === 'holidays' && item.type !== 'holiday') return false
    return true
  })
})

function formatDate(isoDate) {
  const d = new Date(isoDate)
  const day = String(d.getDate()).padStart(2, '0')
  const month = d.toLocaleString('en-US', { month: 'short' }).toUpperCase()
  const year = d.getFullYear()
  return `${day} ${month} ${year}`
}
</script>

<style scoped>
.page {
  padding: 16px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Roboto', sans-serif;
}
.tabs {
  display: flex;
  margin-top: 16px;
  background: #f2f2f2;
  border-radius: 24px;
  padding: 4px;
}
.tab {
  flex: 1;
  border: none;
  background: transparent;
  padding: 8px 0;
  border-radius: 20px;
  font-weight: 600;
  color: #777;
}
.tab.active {
  background: #ffc107;
  color: #000;
}
.selected-date {
  margin-top: 16px;
  font-weight: 700;
}
.list {
  margin-top: 8px;
}
.card {
  background: #fff;
  border-radius: 16px;
  border: 1px solid #00897b;
  padding: 8px 12px 12px;
  margin-bottom: 12px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.04);
}
.card-tag {
  display: inline-block;
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 999px;
  margin-bottom: 8px;
}
.card-body {
  display: flex;
  align-items: center;
  gap: 8px;
}
.card-icon {
  font-size: 24px;
  margin-right: 10px;
}
.card-text {
  flex: 1;
}
.card-title {
  font-weight: 700;
  font-size: 14px;
}
.card-subtitle {
  font-size: 14px;
}
.card-actions {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.small-btn {
  border: none;
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11px;
  cursor: pointer;
}
.small-btn.edit {
  background: #1976d2;
  color: #fff;
}
.small-btn.delete {
  background: #d32f2f;
  color: #fff;
}
.empty-text {
  margin-top: 8px;
  color: #999;
}
</style>

