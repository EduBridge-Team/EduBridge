import HashNavigation from './components/HashNavigation'
import TopBar from './components/TopBar/TopBar'
import AssistantWidget from './components/Noor/AssistantWidget'
import VoiceCommandWidget from './components/VoiceCommandWidget/VoiceCommandWidget'
import AppRoutes from './AppRoutes'
import { VerificationProvider, useVerification } from './verification'
import './role-portal.css'

export default function App() {
  return <VerificationProvider><VerifiedApp /></VerificationProvider>
}

function VerifiedApp() {
  const { verified } = useVerification()
  return (
    <div>
      <TopBar />
      <HashNavigation />
      <AppRoutes />
      {verified && <AssistantWidget />}
      {verified && <VoiceCommandWidget />}
    </div>
  )
}
