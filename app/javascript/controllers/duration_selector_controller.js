import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "input"]

  select(event) {
    const selected = event.currentTarget
    this.buttonTargets.forEach(btn => {
      btn.classList.remove("btn-accent", "active")
      btn.classList.add("btn-outline-secondary")
    })
    selected.classList.remove("btn-outline-secondary")
    selected.classList.add("btn-accent", "active")
    this.inputTarget.value = selected.dataset.value
  }
}
