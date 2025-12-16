<template>
  <div class="dashboard-container" v-if="user">
    <!-- Header -->
    <div class="dashboard-header">
      <div>
        <h1>Welcome, {{ user.name }}</h1>
        <p class="role-text">Role: {{ user.role.toUpperCase() }}</p>
      </div>
      <div>
        <button
          v-if="['superadmin','admin'].includes(user.role)"
          class="create-btn"
          @click="openCreateUser('staff')"
        >
          + Create Admin / Teacher
        </button>
        <button
          v-if="user.role === 'teacher'"
          class="create-btn"
          @click="openCreateUser('student')"
        >
          + Create Student
        </button>

        <button class="logout-btn" @click="logout">Logout</button>
      </div>
    </div>

    <!-- Top stats row -->
    <div class="dashboard-stats">
      <div class="stat-card">
        <h2>{{ totalStudents }}</h2>
        <p>Total Students</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalTeachers }}</h2>
        <p>Total Teachers</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalResults }}</h2>
        <p>Total Results</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalAttendance }}</h2>
        <p>Attendance records</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalFees }}</h2>
        <p>Fees records</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalTimeTables }}</h2>
        <p>Time Tables</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalEvents }}</h2>
        <p>Events</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalAchievements }}</h2>
        <p>Achievements</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalClassDiary }}</h2>
        <p>Class Diary</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalAnnouncements }}</h2>
        <p>Announcements</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalPTMFeedback }}</h2>
        <p>PTM Feedback</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalLibraryBooks }}</h2>
        <p>Library Books</p>
      </div>
      <div class="stat-card">
        <h2>{{ totalObjectiveExams }}</h2>
        <p>Objective Exams</p>
      </div>
    </div>

    <!-- Quick links row -->
    <div class="quick-links">
      <button class="link-card" @click="$router.push('/students')">Students</button>
      <button class="link-card" @click="$router.push('/attendance')">Attendance</button>
      <button class="link-card" @click="$router.push('/homework')">Homework</button>
      <button class="link-card" @click="$router.push('/fees')">Fees</button>
      <button class="link-card" @click="$router.push('/results')">Results</button>
      <button class="link-card" @click="$router.push('/announcements')">Announcements</button>
      <button class="link-card" @click="$router.push('/timetable')">Time Table</button>
      <button class="link-card" @click="$router.push('/events')">Events</button>
      <button class="link-card" @click="$router.push('/gallery')">Gallery</button>
      <button class="link-card" @click="$router.push('/achievements')">Achievements</button>
      <button class="link-card" @click="$router.push('/class-diary')">Class Diary</button>
      <button class="link-card" @click="$router.push('/ptm-feedback')">PTM Feedback</button>
      <button class="link-card" @click="$router.push('/library')">Library</button>
      <button class="link-card" @click="$router.push('/objective-exams')">Objective Exams</button>
    </div>

    <!-- Bar chart -->
    <div class="chart-card">
      <h3>School overview</h3>
      <div class="chart-wrapper">
        <Bar
          v-if="chartData"
          :key="chartKey"
          :data="chartData"
          :options="chartOptions"
        />
      </div>
    </div>

    <!-- Create user / student modal -->
    <div v-if="showCreateModal" class="modal-backdrop">
      <div class="modal">
        <h3 v-if="createMode === 'staff'">Create Admin / Teacher</h3>
        <h3 v-else>Create Student</h3>

        <input v-model="form.name" type="text" placeholder="Name" />
        <input v-model="form.email" type="email" placeholder="Email" />
        <input v-model="form.password" type="password" placeholder="Password" />

        <select v-if="createMode === 'staff'" v-model="form.role">
          <option disabled value="">Select role</option>
          <option value="admin">Admin</option>
          <option value="teacher">Teacher</option>
        </select>

        <input
          v-else
          type="text"
          value="student"
          disabled
        />

        <input
          v-if="form.role === 'teacher' || createMode === 'student'"
          v-model="form.classId"
          type="text"
          placeholder="Class ID (e.g. class_1)"
        />

        <input
          v-if="createMode === 'student'"
          v-model="form.idNumber"
          type="text"
          placeholder="Student ID / Roll No"
        />
        <input
          v-if="createMode === 'student'"
          v-model="form.branch"
          type="text"
          placeholder="Branch / City"
        />

        <p v-if="createError" class="error-text">{{ createError }}</p>
        <p v-if="createSuccess" class="success-text">{{ createSuccess }}</p>

        <div class="modal-actions">
          <button @click="closeCreateModal">Close</button>
          <button :disabled="creating" @click="handleCreate">
            {{ creating ? 'Creating...' : 'Create' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import { collection, getDocs, query, where, setDoc, doc } from "firebase/firestore"
import { getAuth, createUserWithEmailAndPassword } from "firebase/auth"
import { Chart as ChartJS, BarElement, CategoryScale, LinearScale, Tooltip, Legend } from "chart.js"
import { Bar } from "vue-chartjs"

ChartJS.register(BarElement, CategoryScale, LinearScale, Tooltip, Legend)

export default {
  name: "Dashboard",
  components: { Bar },
  data() {
    return {
      user: null,
      totalStudents: 0,
      totalTeachers: 0,
      totalResults: 0,
      totalAttendance: 0,
      totalFees: 0,
      totalTimeTables: 0,
      totalEvents: 0,
      totalAchievements: 0,
      totalClassDiary: 0,
      totalAnnouncements: 0,
      totalPTMFeedback: 0,
      totalLibraryBooks: 0,
      totalObjectiveExams: 0,
      chartData: null,
      chartKey: 0,
      chartOptions: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false } },
          y: { beginAtZero: true, ticks: { display: false }, grid: { color: "#e5e7eb" } }
        }
      },

      showCreateModal: false,
      createMode: "staff",
      creating: false,
      createError: "",
      createSuccess: "",
      form: {
        name: "",
        email: "",
        password: "",
        role: "",
        classId: "",
        idNumber: "",
        branch: ""
      }
    }
  },
  async mounted() {
    const savedUser = localStorage.getItem("user")
    this.user = savedUser ? JSON.parse(savedUser) : null
    if (!this.user) return

    await this.loadDashboard()
  },
  methods: {
    async loadDashboard() {
      const { role, uid, classId } = this.user
      let queries = []

      if (role === "superadmin" || role === "admin") {
        queries = [
          getDocs(collection(db, "students")),
          getDocs(query(collection(db, "users"), where("role", "==", "teacher"))),
          getDocs(collection(db, "results")),
          getDocs(collection(db, "attendance")),
          getDocs(collection(db, "fees")),
          getDocs(collection(db, "timetables")),
          getDocs(collection(db, "events")),
          getDocs(collection(db, "achievements")),
          getDocs(collection(db, "classDiary")),
          getDocs(collection(db, "announcements")),
          getDocs(collection(db, "ptmFeedback")),
          getDocs(collection(db, "libraryBooks")),
          getDocs(collection(db, "objectiveExams"))
        ]
      } else if (role === "teacher") {
        queries = [
          getDocs(query(collection(db, "students"), where("classId", "==", classId))),
          getDocs(query(collection(db, "users"), where("uid", "==", uid))),
          getDocs(query(collection(db, "results"), where("classId", "==", classId))),
          getDocs(query(collection(db, "attendance"), where("classId", "==", classId))),
          getDocs(query(collection(db, "fees"), where("classId", "==", classId))),
          getDocs(query(collection(db, "timetables"), where("classId", "==", classId))),
          getDocs(collection(db, "events")),
          getDocs(query(collection(db, "achievements"), where("className", "==", classId))),
          getDocs(query(collection(db, "classDiary"), where("classId", "==", classId))),
          getDocs(collection(db, "announcements")),
          getDocs(query(collection(db, "ptmFeedback"), where("classId", "==", classId))),
          getDocs(collection(db, "libraryBooks")),
          getDocs(query(collection(db, "objectiveExams"), where("classId", "==", classId)))
        ]
      } else if (role === "student") {
        queries = [
          getDocs(query(collection(db, "students"), where("uid", "==", uid))),
          getDocs(query(collection(db, "results"), where("studentId", "==", uid))),
          getDocs(query(collection(db, "attendance"), where("studentId", "==", uid))),
          getDocs(query(collection(db, "fees"), where("studentId", "==", uid))),
          getDocs(query(collection(db, "timetables"), where("classId", "==", classId))),
          getDocs(collection(db, "events")),
          getDocs(query(collection(db, "users"), where("uid", "==", uid))),
          getDocs(query(collection(db, "achievements"), where("className", "==", classId))),
          getDocs(query(collection(db, "classDiary"), where("classId", "==", classId))),
          getDocs(collection(db, "announcements")),
          getDocs(query(collection(db, "ptmFeedback"), where("classId", "==", classId))),
          getDocs(collection(db, "libraryBooks")),
          getDocs(query(collection(db, "objectiveExams"), where("classId", "==", classId)))
        ]
      } else {
        return
      }

      try {
        const [
          studentsSnap,
          teachersSnap,
          resultsSnap,
          attendanceSnap,
          feesSnap,
          timetableSnap,
          eventsSnap,
          achievementsSnap,
          classDiarySnap,
          announcementsSnap,
          ptmFeedbackSnap,
          libraryBooksSnap,
          objectiveExamsSnap
        ] = await Promise.all(queries)

        this.totalStudents = studentsSnap.size
        this.totalTeachers = teachersSnap.size
        this.totalResults = resultsSnap.size
        this.totalAttendance = attendanceSnap.size
        this.totalFees = feesSnap.size
        this.totalTimeTables = timetableSnap.size
        this.totalEvents = eventsSnap.size
        this.totalAchievements = achievementsSnap.size
        this.totalClassDiary = classDiarySnap.size
        this.totalAnnouncements = announcementsSnap.size
        this.totalPTMFeedback = ptmFeedbackSnap.size
        this.totalLibraryBooks = libraryBooksSnap.size
        this.totalObjectiveExams = objectiveExamsSnap.size

        this.buildChart()
      } catch (err) {
        console.error("Dashboard fetch error:", err)
      }
    },

    buildChart() {
      this.chartData = {
        labels: [
          "Students",
          "Teachers",
          "Results",
          "Attendance",
          "Fees",
          "Time Tables",
          "Events",
          "Achievements",
          "Class Diary",
          "Announcements",
          "PTM Feedback",
          "Library Books",
          "Objective Exams"
        ],
        datasets: [
          {
            label: "Count",
            data: [
              this.totalStudents,
              this.totalTeachers,
              this.totalResults,
              this.totalAttendance,
              this.totalFees,
              this.totalTimeTables,
              this.totalEvents,
              this.totalAchievements,
              this.totalClassDiary,
              this.totalAnnouncements,
              this.totalPTMFeedback,
              this.totalLibraryBooks,
              this.totalObjectiveExams
            ],
            backgroundColor: "#1976d2",
            hoverBackgroundColor: "#0d47a1",
            borderRadius: 12,
            maxBarThickness: 40
          }
        ]
      }
      this.chartKey++
    },

    openCreateUser(mode) {
      this.createMode = mode
      this.showCreateModal = true
      this.createError = ""
      this.createSuccess = ""

      if (mode === "staff") {
        this.form = {
          name: "",
          email: "",
          password: "",
          role: "",
          classId: "",
          idNumber: "",
          branch: ""
        }
      } else {
        this.form = {
          name: "",
          email: "",
          password: "",
          role: "student",
          classId: this.user.role === "teacher" ? this.user.classId || "" : "",
          idNumber: "",
          branch: ""
        }
      }
    },

    closeCreateModal() {
      this.showCreateModal = false
    },

    async handleCreate() {
      this.createError = ""
      this.createSuccess = ""

      const { name, email, password, role, classId, idNumber, branch } = this.form
      const mode = this.createMode

      if (!name || !email || !password) {
        this.createError = "Please fill name, email and password."
        return
      }

      if (mode === "staff") {
        if (!role) {
          this.createError = "Select role (admin / teacher)."
          return
        }
        if (role === "teacher" && !classId) {
          this.createError = "Enter classId for teacher (e.g. class_1)."
          return
        }
      } else if (mode === "student") {
        if (!classId) {
          this.createError = "Enter classId for student (e.g. class_1)."
          return
        }
        if (!idNumber) {
          this.createError = "Enter student ID / roll number."
          return
        }
      }

      try {
        this.creating = true
        const auth = getAuth()

        const cred = await createUserWithEmailAndPassword(auth, email, password)
        const uid = cred.user.uid

        if (mode === "staff") {
          const userDoc = {
            uid,
            name,
            email,
            role,
            classId: role === "teacher" ? classId : "",
            createdAt: new Date()
          }
          await setDoc(doc(db, "users", uid), userDoc)
        } else {
          const userDoc = {
            uid,
            name,
            email,
            role: "student",
            classId,
            createdAt: new Date()
          }
          await setDoc(doc(db, "users", uid), userDoc)

          const studentId = idNumber.toString()
          await setDoc(doc(db, "students", studentId), {
            uid,
            name,
            idNumber: studentId,
            classId,
            branch,
            createdAt: new Date()
          })
        }

        this.createSuccess = "Account created successfully."
        await this.loadDashboard()
      } catch (err) {
        console.error("Create user error:", err)
        this.createError = "Failed to create account."
      } finally {
        this.creating = false
      }
    },

    logout() {
      localStorage.removeItem("user")
      this.$router.push("/login")
    }
  }
}
</script>

<style scoped>
/* same CSS as pehle; yahan change ki zaroorat nahi */
.dashboard-container {
  padding: 1.5rem 1.8rem;
  font-family: Arial, sans-serif;
  background-color: #f5f5f5;
  min-height: 100vh;
}

/* header */
.dashboard-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}
.dashboard-header h1 { margin: 0; font-size: 2rem; }
.role-text { margin: 0.2rem 0 0; color: #555; font-size: 0.9rem; }
.logout-btn {
  background: #f44336;
  color: white;
  border: none;
  padding: 0.5rem 1.2rem;
  border-radius: 5px;
  cursor: pointer;
}
.logout-btn:hover { background: #d32f2f; }

.create-btn {
  margin-right: 0.5rem;
  background: #1976d2;
  color: #fff;
  border: none;
  padding: 0.4rem 0.9rem;
  border-radius: 5px;
  cursor: pointer;
}
.create-btn:hover { background:#0d47a1; }

/* stats grid – compact */
.dashboard-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
  gap: 0.7rem;
  margin-bottom: 1rem;
}
.stat-card {
  background: #4CAF50;
  color: white;
  padding: 0.9rem 0.6rem;
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 4px 8px rgba(0,0,0,0.12);
}
.stat-card h2 { margin: 0; font-size: 1.4rem; }
.stat-card p { margin: 0.3rem 0 0; font-size: 0.8rem; }

/* quick links */
.quick-links {
  display: flex;
  flex-wrap: wrap;
  gap: 0.7rem;
  margin-bottom: 1rem;
}
.link-card {
  flex: 1 1 130px;
  border-radius: 8px;
  background: #1976d2;
  color: white;
  border: none;
  padding: 0.7rem 1rem;
  font-size: 0.9rem;
  text-align: center;
  cursor: pointer;
  box-shadow: 0 3px 6px rgba(0,0,0,0.18);
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}
.link-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 5px 10px rgba(0,0,0,0.22);
}

/* chart */
.chart-card {
  margin-top: 0.5rem;
  background: #ffffff;
  border-radius: 8px;
  padding: 0.8rem 1rem 1rem;
  box-shadow: 0 4px 8px rgba(0,0,0,0.06);
}
.chart-card h3 {
  margin: 0 0 0.4rem;
  font-size: 0.95rem;
  color: #333;
}
.chart-wrapper { width: 100%; height: 260px; }

/* modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 50;
}
.modal {
  background: #fff;
  padding: 1.2rem;
  border-radius: 8px;
  width: 320px;
  max-width: 90%;
}
.modal input,
.modal select {
  width: 100%;
  margin-bottom: 0.6rem;
  padding: 0.4rem;
  border-radius: 4px;
  border: 1px solid #ccc;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}
.error-text { color: red; font-size: 0.85rem; }
.success-text { color: green; font-size: 0.85rem; }

/* responsive tweaks */
@media (max-width: 800px) {
  .chart-wrapper { height: 280px; }
}
</style>

