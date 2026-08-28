import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const currency = event.params.currency

    this.tabTargets.forEach((tab) => tab.classList.toggle("active", tab.dataset.currency === currency))
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.currency !== currency })
  }
}
