# Admin Role & Reset Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter un rôle admin aux utilisateurs et permettre de vider le roster entre saisons, avec réactivation en un clic des anciens personnages.

**Architecture:** Deux colonnes en base (`users.admin` et `characters.in_roster`). Le scope `Character.roster` filtre sur `in_roster: true`. L'admin vide via `clear_roster` (met tous les persos à `in_roster: false`) ; les users réactivent les leurs via `reactivate`.

**Tech Stack:** Rails 7.1.6, PostgreSQL, Minitest, ERB, Hotwire Turbo

## Global Constraints

- Ruby 3.3.5, Rails 7.1.6
- Pas de gem de permissions externe (Pundit, CanCanCan) — vérification directe `current_user&.admin?`
- `Character.destroy` ne supprime rien ici — on toggle `in_roster` uniquement
- Les `EventParticipation` existantes ne sont jamais touchées
- La promotion admin se fait via console Rails : `User.find_by(email: "...").update!(admin: true)`

---

## Fichiers touchés

| Fichier | Action |
|---------|--------|
| `db/migrate/TIMESTAMP_add_admin_to_users.rb` | Créer |
| `db/migrate/TIMESTAMP_add_in_roster_to_characters.rb` | Créer |
| `db/schema.rb` | Mis à jour automatiquement |
| `app/models/user.rb` | Modifier — ajouter `admin?` |
| `app/models/character.rb` | Modifier — scopes `roster`, `out_of_roster`, méthodes de comptage |
| `app/controllers/application_controller.rb` | Modifier — ajouter `require_admin!` |
| `config/routes.rb` | Modifier — ajouter `reactivate` et `clear_roster` |
| `app/controllers/characters_controller.rb` | Modifier — ajouter `clear_roster` et `reactivate` |
| `app/views/characters/index.html.erb` | Modifier — bouton admin + section persos inactifs |
| `test/fixtures/users.yml` | Créer |
| `test/fixtures/characters.yml` | Créer |
| `test/models/character_test.rb` | Modifier — tests scopes |
| `test/models/user_test.rb` | Modifier — test `admin?` |
| `test/controllers/characters_controller_test.rb` | Modifier — tests `clear_roster` et `reactivate` |

---

### Task 1: Migrations — `admin` sur users et `in_roster` sur characters

**Files:**
- Create: `db/migrate/TIMESTAMP_add_admin_to_users.rb`
- Create: `db/migrate/TIMESTAMP_add_in_roster_to_characters.rb`
- Modify: `db/schema.rb` (automatique)

**Interfaces:**
- Produces: colonne `users.admin boolean default false not null` et `characters.in_roster boolean default true not null`

- [ ] **Step 1: Générer les deux migrations**

```bash
rails generate migration AddAdminToUsers admin:boolean
rails generate migration AddInRosterToCharacters in_roster:boolean
```

- [ ] **Step 2: Éditer la migration `AddAdminToUsers` pour ajouter `default: false, null: false`**

Fichier : `db/migrate/TIMESTAMP_add_admin_to_users.rb`

```ruby
class AddAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :admin, :boolean, default: false, null: false
  end
end
```

- [ ] **Step 3: Éditer la migration `AddInRosterToCharacters` pour ajouter `default: true, null: false`**

Fichier : `db/migrate/TIMESTAMP_add_in_roster_to_characters.rb`

```ruby
class AddInRosterToCharacters < ActiveRecord::Migration[7.1]
  def change
    add_column :characters, :in_roster, :boolean, default: true, null: false
  end
end
```

- [ ] **Step 4: Lancer les migrations**

```bash
rails db:migrate
```

Résultat attendu :
```
== AddAdminToUsers: migrating ================================================
-- add_column(:users, :admin, :boolean, {:default=>false, :null=>false})
== AddAdminToUsers: migrated =================================================

== AddInRosterToCharacters: migrating ========================================
-- add_column(:characters, :in_roster, :boolean, {:default=>true, :null=>false})
== AddInRosterToCharacters: migrated =========================================
```

- [ ] **Step 5: Vérifier le schema**

```bash
grep -A2 "t.boolean \"admin\"" db/schema.rb
grep -A2 "t.boolean \"in_roster\"" db/schema.rb
```

Résultat attendu :
```
t.boolean "admin", default: false, null: false
t.boolean "in_roster", default: true, null: false
```

- [ ] **Step 6: Commit**

```bash
git add db/migrate/ db/schema.rb
git commit -m "feat: add admin to users and in_roster to characters"
```

---

### Task 2: User model — méthode `admin?` + fixtures + test

**Files:**
- Modify: `app/models/user.rb`
- Create: `test/fixtures/users.yml`
- Modify: `test/models/user_test.rb`

**Interfaces:**
- Produces: `User#admin?` → `Boolean`

- [ ] **Step 1: Créer les fixtures users**

Fichier : `test/fixtures/users.yml`

```yaml
admin_user:
  email: admin@htw.com
  encrypted_password: <%= BCrypt::Password.create("password") %>
  admin: true

regular_user:
  email: user@htw.com
  encrypted_password: <%= BCrypt::Password.create("password") %>
  admin: false
```

- [ ] **Step 2: Écrire le test qui échoue**

Fichier : `test/models/user_test.rb`

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin? returns true for admin user" do
    assert users(:admin_user).admin?
  end

  test "admin? returns false for regular user" do
    assert_not users(:regular_user).admin?
  end
end
```

- [ ] **Step 3: Lancer le test pour vérifier qu'il échoue**

```bash
rails test test/models/user_test.rb
```

Résultat attendu : `NoMethodError: undefined method 'admin?'`

- [ ] **Step 4: Ajouter `admin?` dans le modèle User**

Fichier : `app/models/user.rb` — ajouter dans la section Méthodes :

```ruby
def admin?
  admin
end
```

- [ ] **Step 5: Lancer le test pour vérifier qu'il passe**

```bash
rails test test/models/user_test.rb
```

Résultat attendu : `2 runs, 2 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add app/models/user.rb test/models/user_test.rb test/fixtures/users.yml
git commit -m "feat: add admin? helper to User model"
```

---

### Task 3: Character model — mise à jour des scopes + fixtures + tests

**Files:**
- Modify: `app/models/character.rb`
- Create: `test/fixtures/characters.yml`
- Modify: `test/models/character_test.rb`

**Interfaces:**
- Consumes: `users(:admin_user)`, `users(:regular_user)` depuis Task 2
- Produces:
  - `Character.roster` → filtre `temporary: false, in_roster: true`
  - `Character.out_of_roster` (scope) → `where(in_roster: false, temporary: false)`
  - `Character.role_counts` → compte uniquement `in_roster: true`
  - `Character.flex_count` → compte uniquement `in_roster: true`
  - `Character.class_counts` → compte uniquement `in_roster: true`

- [ ] **Step 1: Créer les fixtures characters**

Fichier : `test/fixtures/characters.yml`

```yaml
active_character:
  pseudo: Arkhane
  user: regular_user
  in_roster: true
  temporary: false

inactive_character:
  pseudo: Lyana
  user: regular_user
  in_roster: false
  temporary: false

temp_character:
  pseudo: TempGuy
  user: regular_user
  in_roster: true
  temporary: true
```

- [ ] **Step 2: Écrire les tests qui échouent**

Fichier : `test/models/character_test.rb`

```ruby
require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  test "roster scope returns only in_roster permanent characters" do
    assert_includes Character.roster, characters(:active_character)
    assert_not_includes Character.roster, characters(:inactive_character)
    assert_not_includes Character.roster, characters(:temp_character)
  end

  test "out_of_roster scope returns only non-roster permanent characters" do
    assert_includes Character.out_of_roster, characters(:inactive_character)
    assert_not_includes Character.out_of_roster, characters(:active_character)
    assert_not_includes Character.out_of_roster, characters(:temp_character)
  end
end
```

- [ ] **Step 3: Lancer les tests pour vérifier qu'ils échouent**

```bash
rails test test/models/character_test.rb
```

Résultat attendu : les tests sur `roster` et `out_of_roster` échouent.

- [ ] **Step 4: Mettre à jour les scopes et méthodes dans Character**

Fichier : `app/models/character.rb` — remplacer les scopes et méthodes :

```ruby
scope :permanent, -> { where(temporary: false) }
scope :roster, -> { permanent.where(in_roster: true).includes(:user, :wow_class, :specialization).order(created_at: :desc) }
scope :out_of_roster, -> { permanent.where(in_roster: false) }
scope :with_class, -> { joins(:wow_class).where.not(wow_classes: { name: "Flex" }) }

def self.role_counts
  permanent.where(in_roster: true).joins(:specialization).group("specializations.role").count
end

def self.flex_count
  permanent.where(in_roster: true, specialization_id: nil).count
end

def self.class_counts
  all_classes = WowClass.all.pluck(:name)
  counts = permanent.where(in_roster: true).joins(:wow_class)
                    .group("wow_classes.name")
                    .count

  all_classes.each_with_object({}) do |name, hash|
    hash[name] = counts[name] || 0
  end
end
```

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

```bash
rails test test/models/character_test.rb
```

Résultat attendu : `2 runs, 6 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add app/models/character.rb test/models/character_test.rb test/fixtures/characters.yml
git commit -m "feat: update Character scopes for in_roster filtering"
```

---

### Task 4: ApplicationController — helper `require_admin!`

**Files:**
- Modify: `app/controllers/application_controller.rb`

**Interfaces:**
- Produces: méthode privée `require_admin!` disponible dans tous les controllers — redirige vers `root_path` avec alerte si l'utilisateur n'est pas admin

- [ ] **Step 1: Ajouter `require_admin!` dans ApplicationController**

Fichier : `app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:pseudo])
    devise_parameter_sanitizer.permit(:account_update, keys: [:pseudo])
  end

  def require_admin!
    redirect_to root_path, alert: "Accès refusé." unless current_user&.admin?
  end
end
```

- [ ] **Step 2: Vérifier la syntaxe Ruby**

```bash
ruby -c app/controllers/application_controller.rb
```

Résultat attendu : `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add app/controllers/application_controller.rb
git commit -m "feat: add require_admin! helper to ApplicationController"
```

---

### Task 5: Routes — `reactivate` et `clear_roster`

**Files:**
- Modify: `config/routes.rb`

**Interfaces:**
- Produces:
  - `POST /characters/:id/reactivate` → `characters#reactivate`, helper `reactivate_character_path(character)`
  - `POST /characters/clear_roster` → `characters#clear_roster`, helper `clear_roster_characters_path`

- [ ] **Step 1: Mettre à jour les routes**

Fichier : `config/routes.rb` — remplacer la ligne `resources :characters` :

```ruby
resources :characters, only: [:index, :new, :create, :destroy] do
  post :reactivate, on: :member
  collection do
    post :clear_roster
  end
end
```

- [ ] **Step 2: Vérifier les routes générées**

```bash
rails routes | grep characters
```

Résultat attendu (lignes clés) :
```
reactivate_character  POST  /characters/:id/reactivate(.:format)  characters#reactivate
clear_roster_characters  POST  /characters/clear_roster(.:format)  characters#clear_roster
```

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "feat: add reactivate and clear_roster routes for characters"
```

---

### Task 6: CharactersController — actions `clear_roster` et `reactivate` + tests

**Files:**
- Modify: `app/controllers/characters_controller.rb`
- Modify: `test/controllers/characters_controller_test.rb`

**Interfaces:**
- Consumes: `require_admin!` de Task 4, routes de Task 5, scopes de Task 3
- Produces:
  - `clear_roster` : `Character.update_all(in_roster: false)`, redirige vers `characters_path`
  - `reactivate` : `current_user.characters.find(params[:id]).update!(in_roster: true)`, redirige vers `characters_path`

- [ ] **Step 1: Écrire les tests qui échouent**

Fichier : `test/controllers/characters_controller_test.rb`

```ruby
require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  test "GET index is accessible without login" do
    get characters_path
    assert_response :success
  end

  test "POST clear_roster redirects non-admin" do
    sign_in_as users(:regular_user)
    post clear_roster_characters_path
    assert_redirected_to root_path
    assert_equal "Accès refusé.", flash[:alert]
  end

  test "POST clear_roster sets all characters in_roster to false for admin" do
    sign_in_as users(:admin_user)
    assert characters(:active_character).in_roster
    post clear_roster_characters_path
    assert_redirected_to characters_path
    assert_not characters(:active_character).reload.in_roster
  end

  test "POST reactivate reactivates own inactive character" do
    sign_in_as users(:regular_user)
    assert_not characters(:inactive_character).in_roster
    post reactivate_character_path(characters(:inactive_character))
    assert_redirected_to characters_path
    assert characters(:inactive_character).reload.in_roster
  end

  test "POST reactivate cannot reactivate another user's character" do
    sign_in_as users(:admin_user)
    post reactivate_character_path(characters(:inactive_character))
    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

```bash
rails test test/controllers/characters_controller_test.rb
```

Résultat attendu : erreurs de routing ou `NoMethodError` sur les nouvelles actions.

- [ ] **Step 3: Mettre à jour CharactersController**

Fichier : `app/controllers/characters_controller.rb`

```ruby
class CharactersController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_wow_classes, only: [:new, :create]
  before_action :require_admin!, only: [:clear_roster]

  def index
    @characters = Character.roster
    @role_counts = Character.role_counts
    @flex_count = Character.flex_count
    @class_counts = Character.class_counts
  end

  def new
    @character = Character.new

    if params[:wow_class_id]
      @wow_class = WowClass.find(params[:wow_class_id])
      @specializations = @wow_class.specializations
    elsif params[:flex]
      @flex = true
    end
  end

  def create
    @character = current_user.characters.build(character_params)

    if @character.save
      redirect_to characters_path, notice: "Perso ajouté !"
    else
      if params[:character][:wow_class_id].present?
        @wow_class = WowClass.find(params[:character][:wow_class_id])
        @specializations = @wow_class.specializations
      elsif @character.wow_class_id.nil?
        @flex = true
      end
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @character = current_user.characters.find(params[:id])
    @character.destroy
    redirect_back fallback_location: characters_path, notice: "Perso supprimé."
  end

  def clear_roster
    Character.update_all(in_roster: false)
    redirect_to characters_path, notice: "Roster vidé. Les joueurs peuvent réactiver leur perso."
  end

  def reactivate
    @character = current_user.characters.find(params[:id])
    @character.update!(in_roster: true)
    redirect_to characters_path, notice: "#{@character.pseudo} a rejoint le roster !"
  end

  private

  def set_wow_classes
    @wow_classes ||= WowClass.order(:name)
  end

  def character_params
    params.require(:character).permit(:pseudo, :wow_class_id, :specialization_id)
  end
end
```

- [ ] **Step 4: Lancer les tests pour vérifier qu'ils passent**

```bash
rails test test/controllers/characters_controller_test.rb
```

Résultat attendu : `6 runs, 6+ assertions, 0 failures, 0 errors`

- [ ] **Step 5: Commit**

```bash
git add app/controllers/characters_controller.rb test/controllers/characters_controller_test.rb
git commit -m "feat: add clear_roster and reactivate actions to CharactersController"
```

---

### Task 7: Vues — bouton admin + section persos inactifs

**Files:**
- Modify: `app/views/characters/index.html.erb`

**Interfaces:**
- Consumes:
  - `clear_roster_characters_path` (POST) de Task 5
  - `reactivate_character_path(character)` (POST) de Task 5
  - `current_user.characters.out_of_roster` de Task 3
  - `current_user&.admin?` de Task 2

- [ ] **Step 1: Ajouter le bouton admin et la section persos inactifs dans la vue**

Fichier : `app/views/characters/index.html.erb` — remplacer le contenu complet :

```erb
<div class="hw-hero">
  <h1 class="hw-hero-title">Roster Midnight 🌙</h1>
  <p class="hw-hero-subtitle">Composition pour la prochaine extension</p>
</div>

<div class="hw-container">

  <!-- Compteurs de rôles -->
  <div class="hw-role-grid">
    <%= render "role_counter", role: "tank", count: @role_counts["tank"] || 0, label: "Tanks" %>
    <%= render "role_counter", role: "healer", count: @role_counts["healer"] || 0, label: "Healers"%>
    <%= render "role_counter", role: "dps_cac", count: @role_counts["dps_cac"] || 0, label: "DPS CAC"%>
    <%= render "role_counter", role: "dps_caster", count: @role_counts["dps_caster"] || 0, label: "Casters"%>
    <%= render "role_counter", role: "flex", count: @flex_count, label: "Flex", icon: "✨" %>
  </div>

  <!-- Compteurs de classes -->
  <div class="hw-class-grid">
    <% @class_counts.sort_by { |_, count| -count }.each do |class_name, count| %>
      <%= render "class_counter", class_name: class_name, count: count %>
    <% end %>
  </div>

  <!-- Boutons CTA -->
  <div class="hw-card-actions" style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
    <% if user_signed_in? %>
      <%= link_to "Ajouter mon perso", new_character_path, class: "hw-btn hw-btn-primary hw-btn-lg" %>
    <% else %>
      <%= link_to "Connecte-toi pour ajouter ton perso", new_user_session_path, class: "hw-btn hw-btn-secondary hw-btn-lg" %>
    <% end %>

    <% if current_user&.admin? %>
      <%= button_to "🗑 Vider le roster", clear_roster_characters_path,
            method: :post,
            data: { turbo_confirm: "Vider tout le roster ? Les persos resteront réactivables par les joueurs." },
            class: "hw-btn hw-btn-danger hw-btn-lg" %>
    <% end %>
  </div>

  <!-- Liste des persos actifs -->
  <% if @characters.any? %>
    <div class="hw-table-wrapper">
      <table class="hw-table">
        <thead>
          <tr>
            <th>Pseudo</th>
            <th>Classe</th>
            <th>Spé</th>
            <th>Rôle</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <%= render @characters %>
        </tbody>
      </table>
    </div>
  <% else %>
    <p class="hw-empty">Aucun perso inscrit pour le moment</p>
  <% end %>

  <!-- Section persos inactifs (visible uniquement pour l'utilisateur connecté qui en a) -->
  <% if user_signed_in? && current_user.characters.out_of_roster.any? %>
    <div class="hw-card" style="margin-top: 32px;">
      <div class="hw-card-header">
        <span class="hw-card-icon">💤</span>
        <h2 class="hw-card-title">Tes persos inactifs</h2>
      </div>
      <div class="hw-card-body">
        <% current_user.characters.out_of_roster.each do |character| %>
          <div style="display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid rgba(255,255,255,0.06);">
            <div>
              <strong><%= character.pseudo %></strong>
              <% if character.wow_class %>
                <span style="color: #888; font-size: 13px;"> — <%= character.wow_class.name %>
                  <% if character.specialization %><%= character.specialization.name %><% end %>
                </span>
              <% end %>
            </div>
            <%= button_to "Rejoindre le roster", reactivate_character_path(character),
                  method: :post,
                  class: "hw-btn hw-btn-secondary hw-btn-sm" %>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>

</div>
```

- [ ] **Step 2: Lancer les tests complets pour s'assurer qu'il n'y a pas de régression**

```bash
rails test
```

Résultat attendu : tous les tests passent, 0 failures, 0 errors.

- [ ] **Step 3: Tester manuellement dans le navigateur**

```bash
rails server
```

Vérifier :
- [ ] Un user non-connecté voit le roster normalement, sans bouton admin
- [ ] Un user connecté voit "Ajouter mon perso", sans bouton admin
- [ ] Promouvoir un user en admin : `rails console` → `User.find_by(email: "ton@email.com").update!(admin: true)`
- [ ] L'admin voit le bouton "🗑 Vider le roster" à côté de "Ajouter mon perso"
- [ ] Cliquer "Vider le roster" affiche la confirmation Turbo, puis vide le roster
- [ ] Après vidage, un user connecté voit ses persos dans "Tes persos inactifs"
- [ ] Cliquer "Rejoindre le roster" réactive le perso et il réapparaît dans le tableau

- [ ] **Step 4: Commit final**

```bash
git add app/views/characters/index.html.erb
git commit -m "feat: add admin clear roster button and inactive characters reactivation"
```
