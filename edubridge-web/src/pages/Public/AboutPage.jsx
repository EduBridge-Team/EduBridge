import Footer from '../../components/Footer'
import {
  AboutCta,
  AboutHero,
  AboutJourneySection,
  AboutMissionSection,
  AboutValuesSection,
} from './AboutSections'

export default function AboutPage() {
  return (
    <>
      <div className="about-page">
        <AboutHero />
        <AboutMissionSection />
        <AboutValuesSection />
        <AboutJourneySection />
        <AboutCta />
      </div>
      <Footer />
    </>
  )
}
