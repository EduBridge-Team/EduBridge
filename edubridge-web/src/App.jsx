import TopBar from './components/TopBar/TopBar'
import AssistantWidget from './components/Noor/AssistantWidget'
import VoiceCommandWidget from './components/VoiceCommandWidget/VoiceCommandWidget'
import AppRoutes from './AppRoutes'
import './role-portal.css'

export default function App() {
  return (
    <div>
      <TopBar />
      <AppRoutes />
      <AssistantWidget />
      <VoiceCommandWidget />
    </div>
  )
}
