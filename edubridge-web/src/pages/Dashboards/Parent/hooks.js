import { useEffect } from 'react'

export function useParentDashboardPageClass() {
  useEffect(() => {
    const root = document.documentElement
    const body = document.body

    root.classList.add('parent-dashboard-page')
    body.classList.add('parent-dashboard-page')

    return () => {
      root.classList.remove('parent-dashboard-page')
      body.classList.remove('parent-dashboard-page')
    }
  }, [])
}

export function useDashboardSidebarSync({ loading, childrenCount, summaries }) {
  useEffect(() => {
    const dashboard = document.querySelector('.parent-dashboard-v2')
    const sidebar = dashboard?.querySelector('.pd-sidebar')
    const progress = dashboard?.querySelector('.pd-progress-section')
    const main = dashboard?.querySelector('.pd-main')

    if (!dashboard || !sidebar || !progress) return undefined

    let resizeFrame = 0

    const syncSidebarWithProgress = () => {
      cancelAnimationFrame(resizeFrame)
      resizeFrame = requestAnimationFrame(() => {
        if (window.innerWidth <= 900) {
          sidebar.style.removeProperty('--pd-sidebar-target-height')
          sidebar.style.removeProperty('--pd-noor-top')
          sidebar.style.removeProperty('--pd-noor-height')
          return
        }

        const dashboardRect = dashboard.getBoundingClientRect()
        const sidebarRect = sidebar.getBoundingClientRect()
        const progressRect = progress.getBoundingClientRect()

        sidebar.style.setProperty('--pd-sidebar-target-height', `${Math.max(0, Math.ceil(progressRect.bottom - dashboardRect.top))}px`)
        sidebar.style.setProperty('--pd-noor-top', `${Math.max(0, Math.round(progressRect.top - sidebarRect.top))}px`)
        sidebar.style.setProperty('--pd-noor-height', `${Math.max(0, Math.round(progressRect.height))}px`)
      })
    }

    syncSidebarWithProgress()
    window.addEventListener('resize', syncSidebarWithProgress)

    const resizeObserver = typeof ResizeObserver !== 'undefined'
      ? new ResizeObserver(syncSidebarWithProgress)
      : null

    if (resizeObserver) {
      resizeObserver.observe(progress)
      if (main) resizeObserver.observe(main)
    }

    return () => {
      cancelAnimationFrame(resizeFrame)
      window.removeEventListener('resize', syncSidebarWithProgress)
      resizeObserver?.disconnect()
      sidebar.style.removeProperty('--pd-sidebar-target-height')
      sidebar.style.removeProperty('--pd-noor-top')
      sidebar.style.removeProperty('--pd-noor-height')
    }
  }, [loading, childrenCount, summaries])
}

export function useSharedSidebarSync({ loading, childrenCount, summaries }) {
  useEffect(() => {
    const dashboard = document.querySelector('.parent-dashboard-v2')
    const shell = dashboard?.closest('.pp-shell')
    const sidebar = shell?.querySelector('.pp-sidebar')
    const progress = dashboard?.querySelector('.pd-progress-section')

    if (!dashboard || !shell || !sidebar || !progress) return undefined

    let frame = 0

    const syncSharedSidebarToProgress = () => {
      cancelAnimationFrame(frame)
      frame = requestAnimationFrame(() => {
        if (window.innerWidth <= 900) {
          sidebar.style.removeProperty('--pp-dashboard-sidebar-height')
          return
        }

        const shellRect = shell.getBoundingClientRect()
        const progressRect = progress.getBoundingClientRect()
        sidebar.style.setProperty('--pp-dashboard-sidebar-height', `${Math.max(0, Math.ceil(progressRect.bottom - shellRect.top))}px`)
      })
    }

    syncSharedSidebarToProgress()
    window.addEventListener('resize', syncSharedSidebarToProgress)

    const resizeObserver = typeof ResizeObserver !== 'undefined'
      ? new ResizeObserver(syncSharedSidebarToProgress)
      : null

    resizeObserver?.observe(progress)
    resizeObserver?.observe(dashboard)

    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('resize', syncSharedSidebarToProgress)
      resizeObserver?.disconnect()
      sidebar.style.removeProperty('--pp-dashboard-sidebar-height')
    }
  }, [loading, childrenCount, summaries])
}
