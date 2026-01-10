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
      console.error('Failed to fetch tasks:', error)
      toast.error('Failed to load tasks')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateTask = async (title: string, description: string) => {
    try {
      const newTask = await taskAPI.createTask(userId, { title, description })
      setTasks([newTask, ...tasks])
    } catch (error) {
      throw error
    }
  }

  const handleToggleComplete = async (taskId: number) => {
    try {
      const updatedTask = await taskAPI.toggleComplete(userId, taskId)
      setTasks(tasks.map(t => t.id === taskId ? updatedTask : t))
    } catch (error) {
      toast.error('Failed to update task')
    }
  }

  const handleDeleteTask = async (taskId: number) => {
    try {
      await taskAPI.deleteTask(userId, taskId)
      setTasks(tasks.filter(t => t.id !== taskId))
    } catch (error) {
      throw error
    }
  }

  const handleUpdateTask = async (taskId: number, title: string, description: string) => {
    try {
      const updatedTask = await taskAPI.updateTask(userId, taskId, { title, description })
      setTasks(tasks.map(t => t.id === taskId ? updatedTask : t))
    } catch (error) {
      throw error
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <main className="max-w-4xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">My Tasks</h1>
          <p className="text-gray-600">Manage your todo list efficiently</p>
        </div>

        <div className="mb-6 flex gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-md font-medium transition ${
              filter === 'all'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-md font-medium transition ${
              filter === 'pending'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            Pending
          </button>
          <button
            onClick={() => setFilter('completed')}
            className={`px-4 py-2 rounded-md font-medium transition ${
              filter === 'completed'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-100'
            }`}
          >
            Completed
          </button>
        </div>

        <div className="mb-8">
          <TaskForm onSubmit={handleCreateTask} />
        </div>

        {loading ? (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-2 text-gray-600">Loading tasks...</p>
          </div>
        ) : (
          <TaskList
            tasks={tasks}
            onToggle={handleToggleComplete}
            onDelete={handleDeleteTask}
            onUpdate={handleUpdateTask}
          />
        )}
      </main>
    </div>
  )
}
