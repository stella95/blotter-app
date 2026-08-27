import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "option", "chip"]

  toggle(event) {
    event.preventDefault()
    this.panelTarget.hidden = !this.panelTarget.hidden
  }

  add(event) {
    event.preventDefault()
    this.setSelected(event.params.categoryId, true)
  }

  remove(event) {
    event.preventDefault()
    this.setSelected(event.params.categoryId, false)
  }

  setSelected(categoryId, selected) {
    categoryId = String(categoryId)
    const chip = this.chipTargets.find((el) => el.dataset.categoryId === categoryId)
    const option = this.optionTargets.find((el) => el.dataset.categoryId === categoryId)

    chip.hidden = !selected
    chip.querySelector("input").disabled = !selected
    option.hidden = selected
  }
}
