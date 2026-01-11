import axios from 'axios'

const API_URL =
  process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000'

const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use(
  (config) => {
    // IMPORTANT: token only exists on client
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('token')
      if (token) {
        config.headers = config.headers || {}
        config.headers.Authorization = `Bearer ${token}`
      }
    }
    return config
  },
  (error) => Promise.reject(error)
)

/* =======================
   TYPES
======================= */

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

/* =======================
   API METHODS
======================= */

export const taskAPI = {
  getTasks: async (
    userId: string,
    status: 'all' | 'pending' | 'completed' = 'all'
  ): Promise<Task[]> => {
    const response = await apiClient.get(
      `/api/${userId}/tasks`,
      {
        params: { status_filter: status },
      }
    )
    return response.data
  },

  createTask: async (
    userId: string,
    data: CreateTaskData
  ): Promise<Task> => {
    const response = await apiClient.post(
      `/api/${userId}/tasks`,
      data
    )
    return response.data
  },

  updateTask: async (
    userId: string,
    taskId: number,
    data: UpdateTaskData
  ): Promise<Task> => {
    const response = await apiClient.put(
      `/api/${userId}/tasks/${taskId}`,
      data
    )
    return response.data
  },

  toggleComplete: async (
    userId: string,
    taskId: number
  ): Promise<Task> => {
    const response = await apiClient.patch(
      `/api/${userId}/tasks/${taskId}/complete`
    )
    return response.data
  },

  deleteTask: async (
    userId: string,
    taskId: number
  ): Promise<void> => {
    await apiClient.delete(
      `/api/${userId}/tasks/${taskId}`
    )
  },
}

