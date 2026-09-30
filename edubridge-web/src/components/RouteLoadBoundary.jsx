import { Component } from 'react'

export default class RouteLoadBoundary extends Component {
  state = { failed: false }

  static getDerivedStateFromError() {
    return { failed: true }
  }

  render() {
    if (this.state.failed) {
      return (
        <main className="container route-load-state" role="alert" dir="rtl">
          <h2>تعذّر تحميل الصفحة</h2>
          <p>تحقّق من اتصالك بالإنترنت، ثم أعد تحميل الصفحة.</p>
          <button className="btn" onClick={() => window.location.reload()}>إعادة تحميل الصفحة</button>
        </main>
      )
    }
    return this.props.children
  }
}
