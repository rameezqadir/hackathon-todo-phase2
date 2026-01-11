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
