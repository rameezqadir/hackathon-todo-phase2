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

  const fetchTasks = async (
    uid: string,
    status: 'all' | 'pending' | 'completed'
  ) => {
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
    try {
      const newTask = await taskAPI.createTask(userId, { title, description })
      setTasks([newTask, ...tasks])
      toast.success('Task created')
    } catch {
      toast.error('Failed to create task')
    }
  }

  const handleToggle = async (taskId: number) => {
    try {
      const updated = await taskAPI.toggleComplete(userId, taskId)
      setTasks(tasks.map(t => (t.id === taskId ? updated : t)))
    } catch {
      toast.error('Failed to update task')
    }
  }

  const handleDelete = async (taskId: number) => {
    try {
      await taskAPI.deleteTask(userId, taskId)
      setTasks(tasks.filter(t => t.id !== taskId))
      toast.success('Task deleted')
    } catch {
      toast.error('Failed to delete task')
    }
  }

  const handleUpdate = async (
    taskId: number,
    title: string,
    description: string
  ) => {
    try {
      const updated = await taskAPI.updateTask(userId, taskId, {
        title,
        description
      })
      setTasks(tasks.map(t => (t.id === taskId ? updated : t)))
      toast.success('Task updated')
    } catch {
      toast.error('Failed to update task')
    }
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
              className={`px-4 py-2 rounded-md font-medium ${
                filter === f
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700'
              }`}
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
          <TaskList
            tasks={tasks}
            onToggle={handleToggle}
            onDelete={handleDelete}
            onUpdate={handleUpdate}
          />
        )}
      </main>
    </div>
  )
}

