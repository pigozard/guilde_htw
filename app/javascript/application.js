// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"
import "@hotwired/turbo-rails"

Turbo.setConfirmMethod((message, element) => {
  return new Promise((resolve) => {
    const dialog = document.createElement("div")
    dialog.innerHTML = `
      <div style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 9999;">
        <div style="background: #2d2d2d; padding: 30px; border-radius: 10px; text-align: center; max-width: 400px; border: 1px solid #ffc107;">
          <p style="color: #ffffff; font-size: 18px; margin-bottom: 20px;">${message}</p>
          <button id="confirm-yes" style="background: #dc3545; color: white; border: none; padding: 10px 30px; margin: 5px; border-radius: 5px; cursor: pointer;">Oui</button>
          <button id="confirm-no" style="background: #6c757d; color: white; border: none; padding: 10px 30px; margin: 5px; border-radius: 5px; cursor: pointer;">Non</button>
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
