import {
  AboutCta,
  AboutHero,
  AboutJourneySection,
  AboutMissionSection,
  AboutValuesSection,
} from './AboutSections'
import './about-page.css'

export default function AboutPage() {
  return (
    <div className="about-page">
      <AboutHero />
      <AboutMissionSection />
      <AboutValuesSection />
      <AboutJourneySection />
      <AboutCta />
    </div>
  )
}
