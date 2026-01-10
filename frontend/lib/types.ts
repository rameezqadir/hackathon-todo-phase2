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
