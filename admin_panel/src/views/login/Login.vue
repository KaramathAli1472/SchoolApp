<template>
  <div class="login-container">
    <div class="login-box">
      <h2>Admin / Teacher Login</h2>
      
      <input v-model="email" type="email" placeholder="Email" />
      <input v-model="password" type="password" placeholder="Password" />
      
      <button :disabled="loading" @click="login">
        {{ loading ? "Logging in..." : "Login" }}
      </button>
      
      <p v-if="errorMessage" class="error">{{ errorMessage }}</p>
    </div>
  </div>
</template>

<script>
import { signInWithEmailAndPassword } from "firebase/auth"
import { auth, db } from "../../services/firebase"
import { doc, getDoc } from "firebase/firestore"

export default {
  data() {
    return {
      email: "",
      password: "",
      loading: false,
      errorMessage: ""
    }
  },
  methods: {
    async login() {
      if (!this.email || !this.password) {
        this.errorMessage = "Please enter email and password."
        return
      }

      this.loading = true
      this.errorMessage = ""

      try {
        // Firebase Authentication
        const res = await signInWithEmailAndPassword(auth, this.email, this.password)
        
        // Fetch user data from Firestore
        const userSnap = await getDoc(doc(db, "users", res.user.uid))
        if (!userSnap.exists()) {
          this.errorMessage = "User not found!"
          this.loading = false
          return
        }

        const userData = userSnap.data()
        localStorage.setItem("user", JSON.stringify(userData))

        // Redirect to dashboard
        this.$router.push("/dashboard")
      } catch (err) {
        this.errorMessage = "Invalid email or password."
        console.error(err)
      } finally {
        this.loading = false
      }
    }
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #f5f5f5;
}

.login-box {
  background: white;
  padding: 2rem;
  border-radius: 10px;
  box-shadow: 0px 0px 20px rgba(0,0,0,0.1);
  width: 300px;
  text-align: center;
}

.login-box h2 {
  margin-bottom: 1.5rem;
}

.login-box input {
  width: 100%;
  padding: 0.6rem;
  margin-bottom: 1rem;
  border-radius: 5px;
  border: 1px solid #ccc;
  font-size: 0.95rem;
}

.login-box button {
  width: 100%;
  padding: 0.6rem;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
}

.login-box button:hover {
  background-color: #45a049;
}

.login-box button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  color: red;
  margin-top: 1rem;
  font-size: 0.9rem;
}
</style>

