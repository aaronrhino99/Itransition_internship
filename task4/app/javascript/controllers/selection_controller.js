import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "row", "action"]

  connect() {
    this.tooltips = [...this.element.querySelectorAll('[data-bs-toggle="tooltip"]')]
      .map(el => new bootstrap.Tooltip(el, { animation: false }))
    this.update()
  }

  disconnect() {
    this.tooltips.forEach(t => t.dispose())
  }

  toggleAll() {
    this.rowTargets.forEach(cb => (cb.checked = this.allTarget.checked))
    this.update()
  }

  update() {
    const checked = this.rowTargets.filter(cb => cb.checked).length
    this.allTarget.checked = checked > 0 && checked === this.rowTargets.length
    this.allTarget.indeterminate = checked > 0 && checked < this.rowTargets.length
    this.actionTargets.forEach(btn => (btn.disabled = checked === 0))
  }
}