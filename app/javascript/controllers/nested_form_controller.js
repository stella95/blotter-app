import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "template"]

  add(event) {
    event.preventDefault()
    const newIndex = new Date().getTime()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, newIndex)
    this.linesTarget.insertAdjacentHTML("beforeend", content)
  }
}
