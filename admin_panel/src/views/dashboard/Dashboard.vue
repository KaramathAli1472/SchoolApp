<template>
  <div class="dashboard-container" v-if="user">
    <!-- Header -->
    <div class="dashboard-header">
      <div>
        <h1>Welcome, School Admin</h1>
        <p class="role-text">Role: {{ user.role.toUpperCase() }}</p>
      </div>
      <button class="logout-btn" @click="logout">Logout</button>
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
    </div>

    <!-- Quick links row (blue buttons) -->
    <div class="quick-links">
      <button class="link-card" @click="$router.push('/students')">Students</button>
      <button class="link-card" @click="$router.push('/attendance')">Attendance</button>
      <button class="link-card" @click="$router.push('/homework')">Homework</button>
      <button class="link-card" @click="$router.push('/fees')">Fees</button>
      <button class="link-card" @click="$router.push('/results')">Results</button>
      <button class="link-card" @click="$router.push('/notices')">Announcements</button>
      <button class="link-card" @click="$router.push('/timetable')">Time Table</button>
      <button class="link-card" @click="$router.push('/events')">Events</button>
      <button class="link-card" @click="$router.push('/gallery')">Gallery</button>
    </div>

    <!-- Bar chart full width at bottom -->
    <div class="chart-card">
      <h3>School overview</h3>
      <div class="chart-wrapper">
        <Bar
          v-if="chartData"
          :data="chartData"
          :options="chartOptions"
        />
      </div>
    </div>
  </div>

  <div v-else>
    <p>Loading dashboard... or not logged in.</p>
  </div>
</template>

<script>
import { db } from "../../services/firebase"
import { collection, getDocs, query, where } from "firebase/firestore"  // [web:447]

import {
  Chart as ChartJS,
  BarElement,
  CategoryScale,
  LinearScale,
  Tooltip,
  Legend
} from "chart.js"
import { Bar } from "vue-chartjs"   // [web:465][web:463]

ChartJS.register(BarElement, CategoryScale, LinearScale, Tooltip, Legend)

export default {
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
      chartData: null,
      chartOptions: {
        responsive: true,
        maintainAspectRatio: false,
        layout: {
          padding: { top: 10, right: 16, bottom: 4, left: 16 }
        },
        plugins: {
          legend: { display: false },
          tooltip: { enabled: true }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: {
              font: { size: 11 },
              color: "#6b7280"
            }
          },
          y: {
            beginAtZero: true,
            ticks: {
              display: false
            },
            grid: {
              color: "#e5e7eb"
            },
            border: {
              display: false
            }
          }
        }
      }
    }
  },
  async mounted() {
    try {
      const savedUser = localStorage.getItem("user")
      this.user = savedUser ? JSON.parse(savedUser) : null
      if (!this.user) return

      const [
        studentsSnap,
        teachersSnap,
        resultsSnap,
        attendanceSnap,
        feesSnap,
        timetableSnap,
        eventsSnap
      ] = await Promise.all([
        getDocs(collection(db, "students")),
        getDocs(query(collection(db, "users"), where("role", "==", "teacher"))),
        getDocs(collection(db, "results")),
        getDocs(collection(db, "attendance")),
        getDocs(collection(db, "fees")),
        getDocs(collection(db, "timetables")),
        getDocs(collection(db, "events"))
      ])

      this.totalStudents = studentsSnap.size
      this.totalTeachers = teachersSnap.size
      this.totalResults = resultsSnap.size
      this.totalAttendance = attendanceSnap.size
      this.totalFees = feesSnap.size
      this.totalTimeTables = timetableSnap.size
      this.totalEvents = eventsSnap.size

      this.buildChart()
    } catch (err) {
      console.error("Dashboard fetch error:", err)
    }
  },
  methods: {
    buildChart() {
      this.chartData = {
        labels: [
          "Students",
          "Teachers",
          "Results",
          "Attendance",
          "Fees",
          "Time Tables",
          "Events"
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
              this.totalEvents
            ],
            backgroundColor: "#1976d2",
            hoverBackgroundColor: "#0d47a1",
            borderRadius: 12,
            maxBarThickness: 40
          }
        ]
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
.dashboard-container {
  padding: 1.5rem 1.8rem;
  font-family: Arial, sans-serif;
  background-color: #f5f5f5;
  min-height: 100vh;
}

/* Header */
.dashboard-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.dashboard-header h1 {
  margin: 0;
  font-size: 2rem;
}

.role-text {
  margin: 0.2rem 0 0;
  color: #555;
  font-size: 0.9rem;
}

.logout-btn {
  background: #f44336;
  color: white;
  border: none;
  padding: 0.5rem 1.2rem;
  border-radius: 5px;
  cursor: pointer;
}

.logout-btn:hover {
  background: #d32f2f;
}

/* Top green stats */
.dashboard-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.stat-card {
  background: #4CAF50;
  color: white;
  padding: 1.2rem 1rem;
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 4px 8px rgba(0,0,0,0.12);
}

.stat-card h2 {
  margin: 0;
  font-size: 1.8rem;
}

.stat-card p {
  margin: 0.35rem 0 0;
  font-size: 0.9rem;
}

/* Blue buttons */
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

/* Graph block */
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

.chart-wrapper {
  width: 100%;
  height: 220px;
}

/* Responsive */
@media (max-width: 1100px) {
  .dashboard-stats {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 800px) {
  .dashboard-stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .chart-wrapper {
    height: 240px;
  }
}
</style>

