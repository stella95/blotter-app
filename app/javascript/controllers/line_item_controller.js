import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["action", "quantity", "price", "amount", "destroy"]

  connect() {
    this.sync()
  }

  remove() {
    if (this.hasDestroyTarget) {
      this.destroyTarget.value = "1"
      this.element.hidden = true
    } else {
      this.element.remove()
    }
  }

  sync() {
    const action = this.actionTarget.value

    if (action === "buy" || action === "sell") {
      this.amountTarget.readOnly = true
      const quantity = parseFloat(this.quantityTarget.value)
      const price = parseFloat(this.priceTarget.value)
      if (!isNaN(quantity) && !isNaN(price)) {
        const magnitude = quantity * price
        this.amountTarget.value = (action === "buy" ? -magnitude : magnitude).toFixed(4)
      } else {
        this.amountTarget.value = ""
      }
    } else {
      this.amountTarget.readOnly = false
    }
  }

  signFee() {
    if (this.actionTarget.value !== "fee") return

    const value = parseFloat(this.amountTarget.value)
    if (!isNaN(value)) this.amountTarget.value = (-Math.abs(value)).toFixed(2)
  }
}
