import { createRouter, createWebHistory } from "vue-router"

import Login from "../views/login/Login.vue"
import Dashboard from "../views/dashboard/Dashboard.vue"
import Students from "../views/students/Students.vue"
import Attendance from "../views/attendance/Attendance.vue"
import Homework from "../views/homework/Homework.vue"
import Fees from "../views/fees/Fees.vue"
import Results from "../views/results/Results.vue"
import Gallery from "../views/gallery/Gallery.vue"
import TimeTable from "../views/timetable/TimeTable.vue"

// ✅ Event Calendar
import EventCalendar from "../views/events/EventCalendar.vue"

// ✅ Achievements & others
import Achievements from "../views/achievements/Achievements.vue"
import ClassDiary from "../views/classDiary/ClassDiary.vue"
import Announcements from "../views/announcements/Announcements.vue"
import PTMFeedback from "../views/feedback/PTMFeedback.vue"
import LibraryBooks from "../views/library/LibraryBooks.vue"
import ObjectiveExams from "../views/objective/ObjectiveExams.vue"

const routes = [
  { path: "/", redirect: "/login" },
  { path: "/login", component: Login },
  { path: "/dashboard", component: Dashboard },
  { path: "/students", component: Students },
  { path: "/attendance", component: Attendance },
  { path: "/homework", component: Homework },
  { path: "/fees", component: Fees },
  { path: "/results", component: Results },
  { path: "/gallery", component: Gallery },
  { path: "/timetable", component: TimeTable },
  { path: "/class-diary", component: ClassDiary },

  { path: "/ptm-feedback", component: PTMFeedback },
  { path: "/library", component: LibraryBooks },
  { path: "/objective-exams", component: ObjectiveExams },  // 👈 comma added

  // Announcements (two paths, same component)
  { path: "/notices", component: Announcements },
  { path: "/announcements", component: Announcements },

  // ✅ Event Calendar
  { path: "/events", component: EventCalendar },

  // ✅ Achievements
  { path: "/achievements", component: Achievements }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router

