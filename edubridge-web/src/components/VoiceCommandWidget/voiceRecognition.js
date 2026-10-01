// One active recognition session; aborted or duplicate results never execute.
export function createVoiceRecognition(Recognition, { onStatus, onCommand }) {
  let active = null
  const stop = () => {
    const session = active
    active = null
    session?.abort?.()
    onStatus(false, '')
  }
  const start = () => {
    if (active) { stop(); return }
    if (!Recognition) { onStatus(false, 'المتصفح لا يدعم التعرف الصوتي. استخدم Chrome أو Edge.'); return }
    const session = new Recognition()
    active = session
    let handled = false
    session.lang = 'ar-SA'
    session.interimResults = false
    session.continuous = false
    session.maxAlternatives = 1
    onStatus(true, 'أستمع الآن...')
    session.onresult = event => {
      if (active !== session || handled) return
      const result = event.results?.[event.resultIndex ?? 0]
      if (!result?.isFinal) return
      const text = result[0]?.transcript?.trim()
      if (!text) return
      handled = true
      onCommand(text)
    }
    session.onerror = event => {
      if (active !== session) return
      active = null
      const message = ['not-allowed', 'service-not-allowed'].includes(event.error)
        ? 'اسمح باستخدام الميكروفون من إعدادات المتصفح ثم جرّب مجدداً.'
        : event.error === 'no-speech' ? 'لم أسمع أمراً. اضغط الميكروفون وحاول مجدداً.'
          : 'تعذّر سماع الأمر. تأكد من الميكروفون والاتصال ثم حاول مجدداً.'
      onStatus(false, message)
    }
    session.onend = () => {
      if (active !== session) return
      active = null
      onStatus(false, handled ? null : 'لم أسمع أمراً. حاول مجدداً.')
    }
    try { session.start() } catch { active = null; onStatus(false, 'تعذّر تشغيل الميكروفون. حاول مجدداً.') }
  }
  return { start, stop }
}
