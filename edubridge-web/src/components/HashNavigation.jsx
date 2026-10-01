import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import { scheduleNavigationScroll } from './scrollToHash'

export default function HashNavigation() {
  const { hash, pathname, key } = useLocation()
  useEffect(() => scheduleNavigationScroll(hash), [hash, pathname, key])
  return null
}
