#!/bin/bash

echo "Creating all frontend files..."

# Create directories
mkdir -p lib components app/auth/signin app/auth/signup app/tasks app/api/auth/\[...all\]

# lib/types.ts
cat > lib/types.ts << 'EOF'
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

# lib/api.ts
cat > lib/api.ts << 'EOF'
import axios from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

const apiClient = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
})

apiClient.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
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
    const response = await apiClient.get(\`/api/\${userId}/tasks\`, {
      params: { status_filter: status }
    })
    return response.data
  },

  createTask: async (userId: string, data: CreateTaskData): Promise<Task> => {
    const response = await apiClient.post(\`/api/\${userId}/tasks\`, data)
    return response.data
  },

  updateTask: async (userId: string, taskId: number, data: UpdateTaskData): Promise<Task> => {
    const response = await apiClient.put(\`/api/\${userId}/tasks/\${taskId}\`, data)
    return response.data
  },

  toggleComplete: async (userId: string, taskId: number): Promise<Task> => {
    const response = await apiClient.patch(\`/api/\${userId}/tasks/\${taskId}/complete\`)
    return response.data
  },

  deleteTask: async (userId: string, taskId: number): Promise<void> => {
    await apiClient.delete(\`/api/\${userId}/tasks/\${taskId}\`)
  },
}
EOF

# components/Navbar.tsx
cat > components/Navbar.tsx << 'EOF'
'use client'
import { useRouter } from 'next/navigation'
import toast from 'react-hot-toast'

export default function Navbar() {
  const router = useRouter()
  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('userId')
    toast.success('Logged out')
    router.push('/')
  }
  return (
    <nav className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <h1 className="text-xl font-bold text-gray-900">Todo App</h1>
          </div>
          <div className="flex items-center">
            <button onClick={handleLogout} className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900">
              Logout
            </button>
          </div>
        </div>
      </div>
    </nav>
  )
}
EOF

# components/TaskForm.tsx
cat > components/TaskForm.tsx << 'EOF'
'use client'
import { useState } from 'react'
import toast from 'react-hot-toast'

interface TaskFormProps {
  onSubmit: (title: string, description: string) => Promise<void>
}

export default function TaskForm({ onSubmit }: TaskFormProps) {
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) {
      toast.error('Title is required')
      return
    }
    setLoading(true)
    try {
      await onSubmit(title, description)
      setTitle('')
      setDescription('')
      toast.success('Task created!')
    } catch (error) {
      toast.error('Failed to create task')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border">
      <h2 className="text-xl font-semibold mb-4">Add New Task</h2>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Title <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Task title"
            maxLength={200}
            required
          />
          <p className="mt-1 text-xs text-gray-500">{title.length}/200</p>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Task description (optional)"
            rows={3}
            maxLength={1000}
          />
          <p className="mt-1 text-xs text-gray-500">{description.length}/1000</p>
        </div>
        <button
          type="submit"
          disabled={loading}
          className="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Adding...' : 'Add Task'}
        </button>
      </form>
    </div>
  )
}
EOF

# components/TaskItem.tsx
cat > components/TaskItem.tsx << 'EOF'
'use client'
import { useState } from 'react'
import { Task } from '@/lib/types'
import { Check, Circle, Trash2, Edit2 } from 'lucide-react'
import toast from 'react-hot-toast'

interface TaskItemProps {
  task: Task
  onToggle: (taskId: number) => Promise<void>
  onDelete: (taskId: number) => Promise<void>
  onUpdate: (taskId: number, title: string, description: string) => Promise<void>
}

export default function TaskItem({ task, onToggle, onDelete, onUpdate }: TaskItemProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [title, setTitle] = useState(task.title)
  const [description, setDescription] = useState(task.description)
  const [loading, setLoading] = useState(false)

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) {
      toast.error('Title cannot be empty')
      return
    }
    setLoading(true)
    try {
      await onUpdate(task.id, title, description)
      setIsEditing(false)
      toast.success('Task updated')
    } catch (error) {
      toast.error('Failed to update')
    } finally {
      setLoading(false)
    }
  }

  if (isEditing) {
    return (
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <form onSubmit={handleUpdate} className="space-y-3">
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3 py-2 border rounded-md"
            maxLength={200}
            required
          />
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full px-3 py-2 border rounded-md"
            rows={2}
            maxLength={1000}
          />
          <div className="flex gap-2">
            <button type="submit" disabled={loading} className="px-4 py-2 bg-blue-600 text-white rounded-md">
              Save
            </button>
            <button type="button" onClick={() => setIsEditing(false)} className="px-4 py-2 bg-gray-200 rounded-md">
              Cancel
            </button>
          </div>
        </form>
      </div>
    )
  }

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm border hover:shadow-md transition">
      <div className="flex items-start gap-3">
        <button onClick={() => onToggle(task.id)} className="mt-1">
          {task.completed ? <Check className="w-5 h-5 text-green-600" /> : <Circle className="w-5 h-5 text-gray-400" />}
        </button>
        <div className="flex-1">
          <h3 className={\`text-lg font-medium \${task.completed ? 'text-gray-500 line-through' : 'text-gray-900'}\`}>
            {task.title}
          </h3>
          {task.description && <p className="mt-1 text-sm text-gray-600">{task.description}</p>}
          <p className="mt-2 text-xs text-gray-400">Created: {new Date(task.created_at).toLocaleDateString()}</p>
        </div>
        <div className="flex gap-2">
          <button onClick={() => setIsEditing(true)} className="p-2 hover:bg-blue-50 rounded-md" title="Edit">
            <Edit2 className="w-4 h-4" />
          </button>
          <button
            onClick={() => {
              if (confirm('Delete this task?')) onDelete(task.id)
            }}
            className="p-2 hover:bg-red-50 rounded-md"
            title="Delete"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  )
}
EOF

# components/TaskList.tsx  
cat > components/TaskList.tsx << 'EOF'
'use client'
import { Task } from '@/lib/types'
import TaskItem from './TaskItem'

interface TaskListProps {
  tasks: Task[]
  onToggle: (taskId: number) => Promise<void>
  onDelete: (taskId: number) => Promise<void>
  onUpdate: (taskId: number, title: string, description: string) => Promise<void>
}

export default function TaskList({ tasks, onToggle, onDelete, onUpdate }: TaskListProps) {
  if (tasks.length === 0) {
    return (
      <div className="bg-white p-8 rounded-lg shadow-sm border text-center">
        <p className="text-gray-500">No tasks yet. Create your first task above!</p>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {tasks.map((task) => (
        <TaskItem key={task.id} task={task} onToggle={onToggle} onDelete={onDelete} onUpdate={onUpdate} />
      ))}
    </div>
  )
}
EOF

# app/layout.tsx
cat > app/layout.tsx << 'EOF'
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { Toaster } from "react-hot-toast"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Todo App - Phase II",
  description: "Full-stack todo application",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
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

# app/page.tsx
cat > app/page.tsx << 'EOF'
import Link from 'next/link'

export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-4">Todo App</h1>
        <p className="text-xl text-gray-600 mb-8">Manage your tasks efficiently</p>
        <div className="space-x-4">
          <Link href="/auth/signin" className="inline-block px-8 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            Sign In
          </Link>
          <Link href="/auth/signup" className="inline-block px-8 py-3 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300">
            Sign Up
          </Link>
        </div>
      </div>
    </main>
  )
}
EOF

# app/auth/signin/page.tsx
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
        toast.success('Logged in!')
        router.push('/tasks')
      } else {
        toast.error(data.message || 'Invalid credentials')
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
        <h2 className="text-center text-3xl font-extrabold">Sign in</h2>
        <form className="space-y-6" onSubmit={handleSubmit}>
          <div className="space-y-2">
            <input type="email" required className="w-full px-3 py-2 border rounded-md" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
            <input type="password" required className="w-full px-3 py-2 border rounded-md" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          <button type="submit" disabled={loading} className="w-full py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50">
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
          <div className="text-center">
            <Link href="/auth/signup" className="text-blue-600">Don't have an account? Sign up</Link>
          </div>
        </form>
      </div>
    </div>
  )
}
EOF

# app/auth/signup/page.tsx (similar to signin)
cp app/auth/signin/page.tsx app/auth/signup/page.tsx
sed -i 's/Sign in/Sign up/g' app/auth/signup/page.tsx
sed -i 's/sign-in/sign-up/g' app/auth/signup/page.tsx
sed -i "s/Don't have/Already have/" app/auth/signup/page.tsx
sed -i 's/signup/signin/' app/auth/signup/page.tsx | tail -3

# app/tasks/page.tsx
cat > app/tasks/page.tsx << 'EOF'
'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { taskAPI, Task } from '@/lib/api'
import Navbar from '@/components/Navbar'
import TaskForm from '@/components/TaskForm'
import TaskList from '@/components/TaskList'
import toast from 'react-hot-toast'

export default function TasksPage() {
  const router = useRouter()
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | 'pending' | 'completed'>('all')
  const [userId, setUserId] = useState<string>('')

  useEffect(() => {
    const token = localStorage.getItem('token')
    const storedUserId = localStorage.getItem('userId')
    if (!token || !storedUserId) {
      router.push('/auth/signin')
      return
    }
    setUserId(storedUserId)
    fetchTasks(storedUserId, filter)
  }, [filter, router])

  const fetchTasks = async (uid: string, status: 'all' | 'pending' | 'completed') => {
    try {
      setLoading(true)
      const data = await taskAPI.getTasks(uid, status)
      setTasks(data)
    } catch (error) {
      toast.error('Failed to load tasks')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateTask = async (title: string, description: string) => {
    const newTask = await taskAPI.createTask(userId, { title, description })
    setTasks([newTask, ...tasks])
  }

  const handleToggle = async (taskId: number) => {
    const updated = await taskAPI.toggleComplete(userId, taskId)
    setTasks(tasks.map(t => t.id === taskId ? updated : t))
  }

  const handleDelete = async (taskId: number) => {
    await taskAPI.deleteTask(userId, taskId)
    setTasks(tasks.filter(t => t.id !== taskId))
    toast.success('Task deleted')
  }

  const handleUpdate = async (taskId: number, title: string, description: string) => {
    const updated = await taskAPI.updateTask(userId, taskId, { title, description })
    setTasks(tasks.map(t => t.id === taskId ? updated : t))
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      <main className="max-w-4xl mx-auto py-8 px-4">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">My Tasks</h1>
          <p className="text-gray-600">Manage your todo list</p>
        </div>
        <div className="mb-6 flex gap-2">
          {(['all', 'pending', 'completed'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={\`px-4 py-2 rounded-md font-medium \${filter === f ? 'bg-blue-600 text-white' : 'bg-white text-gray-700'}\`}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
        <div className="mb-8">
          <TaskForm onSubmit={handleCreateTask} />
        </div>
        {loading ? (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <TaskList tasks={tasks} onToggle={handleToggle} onDelete={handleDelete} onUpdate={handleUpdate} />
        )}
      </main>
    </div>
  )
}
EOF

echo "✅ All files created successfully!"

