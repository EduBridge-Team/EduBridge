import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'
import { scheduleHashScroll } from './scrollToHash'

export default function HashNavigation() {
  const { hash, pathname, key } = useLocation()
  useEffect(() => scheduleHashScroll(hash), [hash, pathname, key])
  return null
}
