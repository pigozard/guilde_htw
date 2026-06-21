# Design — Admin & Reset du Roster entre saisons

**Date :** 2026-06-21  
**Statut :** Approuvé

---

## Contexte

Entre deux saisons de WoW, le roster doit pouvoir être remis à zéro pour que les joueurs re-confirment leur participation. Les personnages ne doivent pas être supprimés : ils restent utilisables dans le calendrier d'événements.

---

## Objectif

- Permettre à certains utilisateurs d'avoir un rôle **admin**
- L'admin dispose d'un bouton **"Vider le roster"** sur la page `/characters`
- Ce bouton masque tous les personnages du roster sans les supprimer
- Les joueurs peuvent ensuite **réactiver leur ancien perso en un clic** ou en ajouter un nouveau

---

## Base de données

### Migration 1 — `add_admin_to_users`

```ruby
add_column :users, :admin, :boolean, default: false, null: false
```

### Migration 2 — `add_in_roster_to_characters`

```ruby
add_column :characters, :in_roster, :boolean, default: true, null: false
```

---

## Modèles

### `User`

```ruby
def admin?
  admin
end
```

### `Character`

- Le scope `roster` existant filtre sur `in_roster: true`
- Nouveau scope `out_of_roster` pour récupérer les persos inactifs d'un user :

```ruby
scope :roster, -> { where(in_roster: true).includes(:wow_class, :specialization) }
scope :out_of_roster, -> { where(in_roster: false) }
```

---

## Routes

```ruby
resources :characters, only: [:index, :new, :create, :destroy] do
  post :reactivate, on: :member
end
post 'characters/clear_roster', to: 'characters#clear_roster', as: :clear_roster
```

---

## Controller — `CharactersController`

### Protection admin

Dans `ApplicationController` :

```ruby
def require_admin!
  redirect_to root_path, alert: "Accès refusé." unless current_user&.admin?
end
```

### Nouvelles actions

**`clear_roster`** — vide le roster (admin uniquement) :

```ruby
before_action :require_admin!, only: [:clear_roster]

def clear_roster
  Character.update_all(in_roster: false)
  redirect_to characters_path, notice: "Roster vidé. Les joueurs peuvent réactiver leur perso."
end
```

**`reactivate`** — réactive un perso appartenant à l'utilisateur connecté :

```ruby
def reactivate
  @character = current_user.characters.find(params[:id])
  @character.update!(in_roster: true)
  redirect_to characters_path, notice: "#{@character.pseudo} a rejoint le roster !"
end
```

---

## Vues

### `characters/index.html.erb`

**1. Bouton admin** (à côté du bouton "Ajouter mon perso") :

```erb
<% if current_user&.admin? %>
  <%= button_to "🗑 Vider le roster", clear_roster_characters_path,
        method: :post,
        data: { confirm: "Vider tout le roster ? Les persos resteront réactivables." },
        class: "hw-btn hw-btn-danger" %>
<% end %>
```

**2. Section persos inactifs** (visible uniquement si l'utilisateur a des persos `in_roster: false`) :

```erb
<% if user_signed_in? && current_user.characters.out_of_roster.any? %>
  <div class="hw-card" style="margin-top: 24px;">
    <div class="hw-card-header">
      <span class="hw-card-icon">💤</span>
      <h2 class="hw-card-title">Tes persos inactifs</h2>
    </div>
    <div class="hw-card-body">
      <% current_user.characters.out_of_roster.each do |character| %>
        <div style="display: flex; justify-content: space-between; align-items: center; padding: 8px 0;">
          <span><%= character.pseudo %> — <%= character.wow_class&.name %> <%= character.specialization&.name %></span>
          <%= button_to "Rejoindre le roster", reactivate_character_path(character),
                method: :post, class: "hw-btn hw-btn-secondary hw-btn-sm" %>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
```

---

## Sécurité

- `clear_roster` protégée par `require_admin!` (redirect si non-admin)
- `reactivate` utilise `current_user.characters.find(...)` → un user ne peut réactiver que ses propres persos
- Pas de gem de permissions externe : un seul point d'entrée admin, une vérification directe suffit

---

## Ce qui ne change pas

- Les `EventParticipation` ne sont pas affectées — les personnages existent toujours en base
- Le formulaire "Ajouter mon perso" continue de fonctionner normalement (crée un perso avec `in_roster: true` par défaut)
- La promotion admin se fait directement en console Rails ou via seeds :
  ```ruby
  User.find_by(email: "pierre@...").update!(admin: true)
  ```
