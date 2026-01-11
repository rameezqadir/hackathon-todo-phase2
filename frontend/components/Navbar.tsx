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
