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
    // For testing - generate simple token
    const testToken = btoa(email) // Simple base64 encoding
    const testUserId = email.split('@')[0] // Use email username as ID
    
    localStorage.setItem('token', testToken)
    localStorage.setItem('userId', testUserId)
    
    toast.success('Logged in!')
    router.push('/tasks')
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
