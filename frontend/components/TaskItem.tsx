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

export default function TaskItem({
  task,
  onToggle,
  onDelete,
  onUpdate
}: TaskItemProps) {
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
    } catch {
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
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 bg-blue-600 text-white rounded-md"
            >
              Save
            </button>

            <button
              type="button"
              onClick={() => setIsEditing(false)}
              className="px-4 py-2 bg-gray-200 rounded-md"
            >
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
          {task.completed ? (
            <Check className="w-5 h-5 text-green-600" />
          ) : (
            <Circle className="w-5 h-5 text-gray-400" />
          )}
        </button>

        <div className="flex-1">
          <h3
            className={`text-lg font-medium ${
              task.completed
                ? 'text-gray-500 line-through'
                : 'text-gray-900'
            }`}
          >
            {task.title}
          </h3>

          {task.description && (
            <p className="mt-1 text-sm text-gray-600">
              {task.description}
            </p>
          )}

          <p className="mt-2 text-xs text-gray-400">
            Created: {new Date(task.created_at).toLocaleDateString()}
          </p>
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => setIsEditing(true)}
            className="p-2 hover:bg-blue-50 rounded-md"
            title="Edit"
          >
            <Edit2 className="w-4 h-4" />
          </button>

          <button
            onClick={() => {
              if (confirm('Delete this task?')) {
                onDelete(task.id)
              }
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

