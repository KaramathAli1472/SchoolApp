import { createRouter, createWebHistory } from "vue-router"
import Login from "../views/login/Login.vue"
import Dashboard from "../views/dashboard/Dashboard.vue"
import Students from "../views/students/Students.vue"
import Attendance from "../views/attendance/Attendance.vue"
import Homework from "../views/homework/Homework.vue"
import Fees from "../views/fees/Fees.vue"
import Results from "../views/results/Results.vue"
import Notices from "../views/notices/Notices.vue"
import Gallery from "../views/gallery/Gallery.vue"

const routes = [
  { path: "/", redirect: "/login" },
  { path: "/login", component: Login },
  { path: "/dashboard", component: Dashboard },
  { path: "/students", component: Students },
  { path: "/attendance", component: Attendance },
  { path: "/homework", component: Homework },
  { path: "/fees", component: Fees },
  { path: "/results", component: Results },
  { path: "/notices", component: Notices },
  { path: "/gallery", component: Gallery }  // ← last item, no trailing comma
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router

