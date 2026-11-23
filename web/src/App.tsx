import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { setNavigator } from './api/navigation'
import { AppRoutes } from './routes/AppRoutes'

export default function App() {
  const navigate = useNavigate()

  useEffect(() => {
    setNavigator((path) => {
      navigate(path, { replace: true })
    })
    return () => setNavigator(null)
  }, [navigate])

  return <AppRoutes />
}
