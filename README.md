# Highway to Wipe — Application de Guilde WoW

Application web complète pour la guilde **Highway to Wipe**, guilde PvE Alliance sur le serveur **Eitrigg (EU)** dans *World of Warcraft*.

---

## Sommaire

- [Aperçu](#aperçu)
- [Fonctionnalités](#fonctionnalités)
- [Stack Technique](#stack-technique)
- [Architecture](#architecture)
- [Installation](#installation)
- [Variables d'environnement](#variables-denvironnement)
- [Base de données](#base-de-données)
- [Tâches automatisées](#tâches-automatisées)
- [Intégrations externes](#intégrations-externes)
- [Déploiement](#déploiement)

---

## Aperçu

Highway to Wipe centralise tous les outils dont une guilde de raid a besoin : gestion des membres et personnages, calendrier d'événements avec inscriptions, suivi de farm collaboratif, hauts faits, et tableau de bord en temps réel alimenté par des APIs externes (Warcraft Logs, Raider.io, Blizzard).

---

## Fonctionnalités

### Page d'accueil
- Progression de raid en temps réel (Normal / Héroïque / Mythique) par raid de la saison, alimentée par Warcraft Logs
- Kills récents avec date et difficulté
- Top Mythic+ des membres de la guilde via Raider.io
- Wall of Shame (classement des morts en raid)
- Prochain événement avec statut de participation de l'utilisateur connecté
- Lien direct vers le dernier log Warcraft Logs de la guilde

### Calendrier des événements
- Vue mensuelle avec navigation mois par mois
- Types d'événements : Raid ⚔️, Mythic+ 🔑, PvP 🛡️, Social 🎉, Autre 📅
- Indicateur visuel du statut de participation (✅ / ❓ / ❌) sur chaque pill de l'agenda
- Création/édition/suppression d'événements (réservé au créateur)

### Inscriptions aux événements
- Inscription avec trois statuts : **Confirmé** ✅, **Incertain** ❓, **Absent** ❌
- Choix de la spécialisation au moment de l'inscription
- Possibilité de jouer un personnage temporaire (pseudo, classe, spé) sans le créer définitivement
- Mise à jour du statut en un clic depuis la page de l'événement
- Désinscription possible à tout moment
- Composition automatique des rôles (Tank / Heal / DPS CAC / DPS Caster)
- Notification de rappel envoyée sur Discord 3 jours avant l'événement

### Roster
- Liste de tous les personnages permanents de la guilde
- Filtrage par classe et rôle
- Compteurs de rôles (Tanks, Heals, DPS)
- Compteurs par classe

### Farm collaboratif
- Sélection hebdomadaire des consommables nécessaires par joueur (potions, flacons, etc.)
- Calcul automatique des ingrédients nécessaires à partir des recettes
- Attribution des ingrédients à farmer aux membres volontaires
- Suivi des contributions par semaine
- Données consommables/ingrédients importées depuis l'API Blizzard

### Hauts Faits
- Synchronisation des hauts faits d'un personnage via l'API Blizzard
- Vue d'ensemble par extension (progression globale en %)
- Catégories spéciales : PvP, Métiers, Mascottes, Collections, Exploration, Événements
- Filtrage par catégorie et sous-catégorie
- Affichage des hauts faits non obtenus (mode progression) ou obtenus
- Mise en avant des Exploits légendaires (Feats of Strength)

### Outils
Page de référencement de ressources communautaires, organisée par catégorie :
- **Template & Theorycraft** : Icy Veins, Raidbots
- **BiS & Stuff** : Bloodmallet, QE Live, Archon.gg
- **Logs & Actus** : Warcraft Logs, Wowhead

### Profil utilisateur
- Pseudonyme personnalisable
- Gestion des personnages principaux
- Historique des synchronisations de hauts faits

---

## Stack Technique

| Couche | Technologie |
|--------|-------------|
| Langage | Ruby 3.3.5 |
| Framework | Rails 7.1.6 |
| Base de données | PostgreSQL |
| CSS | Bootstrap 5.3 + SCSS (Sass) |
| JavaScript | Importmap + Hotwire (Turbo + Stimulus) |
| Authentification | Devise |
| Templates | ERB |
| Calendrier | simple_calendar 3.0 |
| HTTP Client | HTTParty |
| Assets | Sprockets + autoprefixer |
| Serveur | Puma |
| Déploiement | Heroku (Docker) |

---

## Architecture

```
app/
├── controllers/
│   ├── achievements_controller.rb      # Hauts faits + sync Blizzard
│   ├── characters_controller.rb        # Gestion des personnages
│   ├── consumable_selections_controller.rb
│   ├── event_participations_controller.rb  # Inscriptions événements
│   ├── events_controller.rb            # Calendrier
│   ├── farm_controller.rb              # Farm collaboratif
│   ├── farmer_assignments_controller.rb
│   ├── pages_controller.rb             # Home + Outils
│   └── profiles_controller.rb
│
├── models/
│   ├── user.rb                         # Devise, pseudo, nickname
│   ├── character.rb                    # Personnage WoW (classe, spé, realm)
│   ├── wow_class.rb                    # Classes WoW
│   ├── specialization.rb               # Spécialisations + rôles
│   ├── event.rb                        # Événements (5 types)
│   ├── event_participation.rb          # Inscription (confirmed/tentative/declined)
│   ├── consumable.rb / ingredient.rb / recipe.rb
│   ├── consumable_selection.rb         # Sélection hebdomadaire
│   ├── farm_contribution.rb / farmer_assignment.rb
│   ├── achievement.rb                  # Hauts faits Blizzard
│   ├── character_achievement.rb        # Progression par personnage
│   ├── expansion.rb                    # Extensions WoW
│   ├── user_achievement_sync.rb        # Historique de sync
│   └── guild_statistic.rb             # Cache des stats (WCL + Raider.io)
│
├── services/
│   ├── blizzard_api_service.rb         # OAuth2 + hauts faits + items
│   ├── warcraft_logs_service.rb        # GraphQL WCL (progression, kills, deaths)
│   ├── raider_io_service.rb            # Top M+ membres
│   └── discord_notification_service.rb # Webhooks Discord
│
└── views/
    ├── layouts/application.html.erb
    ├── shared/_navbar.html.erb
    ├── pages/home.html.erb + outils.html.erb
    ├── events/                         # Calendrier, show, forms, partials
    ├── characters/
    ├── farm/
    └── achievements/

lib/tasks/
├── blizzard.rake       # Import consumables/ingrédients depuis l'API
├── guild_stats.rake    # Mise à jour cache WCL + Raider.io
├── discord.rake        # Rappels Discord événements
└── warcraft_logs.rake  # Sync manuelle Warcraft Logs
```

### Modèle de données simplifié

```
User ──< Character >── WowClass ──< Specialization
 │           │
 │           └──< EventParticipation >── Event
 │           └──< CharacterAchievement >── Achievement >── Expansion
 │
 ├──< ConsumableSelection >── Consumable ──< Recipe >── Ingredient
 ├──< FarmContribution >── Ingredient
 └──< FarmerAssignment >── Ingredient

GuildStatistic  (cache JSON : warcraft_logs, raider_io)
```

---

## Installation

### Prérequis

- Ruby 3.3.5
- PostgreSQL
- Bundler

### Étapes

```bash
# 1. Cloner le repo
git clone <repo-url>
cd guilde_htw

# 2. Installer les dépendances
bundle install

# 3. Configurer les variables d'environnement (voir section suivante)
cp .env.example .env  # ou créer le fichier manuellement

# 4. Créer et migrer la base de données
rails db:create db:migrate

# 5. Alimenter les données de base (classes, spés, consumables, hauts faits)
rails db:seed

# 6. Lancer le serveur
rails server
```

L'application sera disponible sur `http://localhost:3000`.

---

## Variables d'environnement

Créer un fichier `.env` à la racine (non versionné) :

```env
# API Blizzard (https://develop.battle.net)
BLIZZARD_CLIENT_ID=xxx
BLIZZARD_CLIENT_SECRET=xxx

# Warcraft Logs (https://www.warcraftlogs.com/api/docs)
WARCRAFTLOGS_CLIENT_ID=xxx
WARCRAFTLOGS_CLIENT_SECRET=xxx

# Discord (webhook du canal de la guilde)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/xxx/xxx
```

---

## Base de données

### Migrations principales

| Date | Migration |
|------|-----------|
| Jan 2026 | Utilisateurs (Devise), classes, spés, personnages |
| Jan 2026 | Événements et participations |
| Jan 2026 | Farm : consumables, ingrédients, recettes, contributions |
| Jan 2026 | Sélections hebdomadaires, assignments farmers |
| Jan 2026 | Hauts faits, extensions, sync par personnage |
| Fév 2026 | Cache `guild_statistics` (WCL + Raider.io) |

### Import des données de référence

```bash
# Importer les consumables et ingrédients depuis l'API Blizzard (The War Within)
rails blizzard:import_consumables EXPANSION=tww

# Importer les hauts faits
rails blizzard:import_achievements
```

---

## Tâches automatisées

Ces tâches sont à planifier via un scheduler (Heroku Scheduler ou cron) :

```bash
# Mettre à jour le cache des stats de guilde (Warcraft Logs + Raider.io)
# Recommandé : toutes les heures
rails guild:update_stats

# Envoyer les rappels Discord pour les événements dans 3 jours
# Recommandé : tous les jours à 10h00
rails discord:event_reminders
```

Les stats sont stockées en cache dans la table `guild_statistics` pour éviter les appels API synchrones lors du chargement de la page d'accueil.

---

## Intégrations externes

### API Blizzard
- **Authentification** : OAuth2 client credentials
- **Usages** : récupération des hauts faits d'un personnage, import des items (consommables, ingrédients) avec icônes
- **Fallback** : données YAML embarquées si l'API est indisponible

### Warcraft Logs (GraphQL)
- **Authentification** : OAuth2 client credentials
- **Usages** : progression de raid par difficulté, kills récents, statistiques de morts par joueur, code du dernier rapport
- **Raids suivis** : The Voidspire (6 boss), The Dreamrift (1 boss), March on Quel'Danas (2 boss)
- **Cache** : résultats stockés en BDD, rafraîchis par rake task

### Raider.io
- **Usages** : score Mythic+ de chaque membre de la guilde, classement interne
- **Cache** : même mécanisme que Warcraft Logs

### Discord
- **Type** : webhook entrant
- **Usage** : rappels automatiques 3 jours avant chaque événement (embed avec titre, date, type)

---

## Déploiement

L'application est conteneurisée via Docker et déployée sur **Heroku**.

```bash
# Connexion Heroku
heroku login

# Déployer
git push heroku master

# Migrations en production
heroku run rails db:migrate

# Variables d'environnement en production
heroku config:set BLIZZARD_CLIENT_ID=xxx
heroku config:set BLIZZARD_CLIENT_SECRET=xxx
heroku config:set WARCRAFTLOGS_CLIENT_ID=xxx
heroku config:set WARCRAFTLOGS_CLIENT_SECRET=xxx
heroku config:set DISCORD_WEBHOOK_URL=xxx

# Mettre à jour les stats manuellement
heroku run rails guild:update_stats
```

---

*Highway to Wipe — Guilde PvE Alliance • Eitrigg EU*
