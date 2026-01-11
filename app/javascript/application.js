// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"

Turbo.setConfirmMethod((message, element) => {
  return new Promise((resolve) => {
    const dialog = document.createElement("div")
    dialog.innerHTML = `
      <div class="confirm-overlay">
        <div class="confirm-modal">
          <p class="confirm-message">${message}</p>
          <button id="confirm-yes" class="confirm-btn confirm-btn-yes">Oui</button>
          <button id="confirm-no" class="confirm-btn confirm-btn-no">Non</button>
        </div>
      </div>
    `
    document.body.appendChild(dialog)

    dialog.querySelector("#confirm-yes").addEventListener("click", () => {
      dialog.remove()
      resolve(true)
    })

    dialog.querySelector("#confirm-no").addEventListener("click", () => {
      dialog.remove()
      resolve(false)
    })
  })
})
