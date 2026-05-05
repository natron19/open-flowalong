import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner"]

  generate() {
    this.buttonTarget.classList.add("d-none")
    this.spinnerTarget.classList.remove("d-none")
  }

  submitting(event) {
    this._formSubmission = event.detail.formSubmission
  }

  cancel() {
    if (this._formSubmission) {
      this._formSubmission.stop()
      this._formSubmission = null
    }
    this.spinnerTarget.classList.add("d-none")
    this.buttonTarget.classList.remove("d-none")
  }
}
