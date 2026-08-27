import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    this.element.innerHTML = ""
  }

  backdropClick(event) {
    if (event.target === this.element) this.close()
  }
}
