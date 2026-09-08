import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "button"]

  toggle() {
    const expanded = this.buttonTarget.dataset.expanded === "true"

    this.itemTargets.forEach((item) => item.classList.toggle("hw-hidden", expanded))

    this.buttonTarget.textContent = expanded ? "Afficher plus" : "Afficher moins"
    this.buttonTarget.dataset.expanded = (!expanded).toString()
  }
}
