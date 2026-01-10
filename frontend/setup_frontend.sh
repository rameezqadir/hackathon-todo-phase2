#!/bin/bash

cd ~/projects/hackathon-todo-phase2/frontend

echo "Creating frontend structure..."

# Create directories
mkdir -p lib components app/auth/signin app/auth/signup app/tasks app/api/auth/[...all]

# Create lib/types.ts
cat > lib/types.ts << 'EOF'
export interface User {
  id: string
  email: string
  name?: string
}

export interface Task {
  id: number
  user_id: string
  title: string
  description: string
  completed: boolean
  created_at: string
  updated_at: string
}
EOF

# Create lib/api.ts
cat > lib/api.ts << 'EOF'
import axios from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export interface Task {
  id: number
  user_id: string
  title: string
  description: string
  completed: boolean
  created_at: string
  updated_at: string
}

export interface CreateTaskData {
  title: string
  description?: string
}

export interface UpdateTaskData {
  title?: string
  description?: string
}

export const taskAPI = {
  getTasks: async (userId: string, status: 'all' | 'pending' | 'completed' = 'all'): Promise<Task[]> => {
    const response = await apiClient.get(`/api/${userId}/tasks`, {
      params: { status_filter: status }
    })
    return response.data
  },

  getTask: async (userId: string, taskId: number): Promise<Task> => {
    const response = await apiClient.get(`/api/${userId}/tasks/${taskId}`)
    return response.data
  },

  createTask: async (userId: string, data: CreateTaskData): Promise<Task> => {
    const response = await apiClient.post(`/api/${userId}/tasks`, data)
    return response.data
  },

  updateTask: async (userId: string, taskId: number, data: UpdateTaskData): Promise<Task> => {
    const response = await apiClient.put(`/api/${userId}/tasks/${taskId}`, data)
    return response.data
  },

  toggleComplete: async (userId: string, taskId: number): Promise<Task> => {
    const response = await apiClient.patch(`/api/${userId}/tasks/${taskId}/complete`)
    return response.data
  },

  deleteTask: async (userId: string, taskId: number): Promise<void> => {
    await apiClient.delete(`/api/${userId}/tasks/${taskId}`)
  },
}
EOF

# Create app/layout.tsx
cat > app/layout.tsx << 'EOF'
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { Toaster } from "react-hot-toast"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Todo App - Phase II",
  description: "Full-stack todo application with authentication",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
        <Toaster position="top-right" />
      </body>
    </html>
  )
}
EOF

# Create app/page.tsx
cat > app/page.tsx << 'EOF'
import Link from 'next/link'

export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-4">
          Todo App
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Manage your tasks efficiently
        </p>
        <div className="space-x-4">
          <Link
            href="/auth/signin"
            className="inline-block px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            Sign In
          </Link>
          <Link
            href="/auth/signup"
            className="inline-block px-8 py-3 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition"
          >
            Sign Up
          </Link>
        </div>
      </div>
    </main>
  )
}
EOF

# Create signin page
cat > app/auth/signin/page.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import toast from 'react-hot-toast'

export default function SignIn() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const response = await fetch('/api/auth/sign-in', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })

      const data = await response.json()

      if (response.ok) {
        localStorage.setItem('token', data.token)
        localStorage.setItem('userId', data.user.id)
        toast.success('Logged in successfully!')
        router.push('/tasks')
      } else {
        toast.error(data.message || 'Invalid credentials')
      }
    } catch (error) {
      toast.error('An error occurred. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <input
                type="email"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <input
                type="password"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none disabled:opacity-50"
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>

          <div className="text-center">
            <Link href="/auth/signup" className="text-blue-600 hover:text-blue-500">
              Don't have an account? Sign up
            </Link>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# Create signup page (same as signin with minor changes)
cat > app/auth/signup/page.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import toast from 'react-hot-toast'

export default function SignUp() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (password.length < 8) {
      toast.error('Password must be at least 8 characters')
      return
    }

    setLoading(true)

    try {
      const response = await fetch('/api/auth/sign-up', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, name }),
      })

      const data = await response.json()

      if (response.ok) {
        localStorage.setItem('token', data.token)
        localStorage.setItem('userId', data.user.id)
        toast.success('Account created!')
        router.push('/tasks')
      } else {
        toast.error(data.message || 'Registration failed')
      }
    } catch (error) {
      toast.error('An error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4">
      <div className="max-w-md w-full space-y-8">
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Create your account
        </h2>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="space-y-2">
            <input
              type="text"
              required
              className="w-full px-3 py-2 border rounded-md"
              placeholder="Full Name"
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
            <input
              type="email"
              required
              className="w-full px-3 py-2 border rounded-md"
              placeholder="Email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
            <input
              type="password"
              required
              minLength={8}
              className="w-full px-3 py-2 border rounded-md"
              placeholder="Password (min 8 chars)"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full py-2 px-4 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Creating...' : 'Sign up'}
          </button>
          <div className="text-center">
            <Link href="/auth/signin" className="text-blue-600">
              Already have an account? Sign in
            </Link>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

echo "✅ Frontend structure created!"
echo ""
echo "Next: Create components (Navbar, TaskForm, TaskItem, TaskList) and tasks page"

