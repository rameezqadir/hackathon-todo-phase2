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
      <div className="bg-white p-8 rounded-lg shadow-sm border border-gray-200 text-center">
        <p className="text-gray-500">No tasks yet. Create your first task above!</p>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {tasks.map((task) => (
        <TaskItem
          key={task.id}
          task={task}
          onToggle={onToggle}
          onDelete={onDelete}
          onUpdate={onUpdate}
        />
      ))}
    </div>
  )
}
