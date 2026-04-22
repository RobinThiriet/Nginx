# Architecture Nginx Docker Lab

## Vue d'ensemble

Cette architecture montre un usage classique de Nginx comme point d'entree unique devant plusieurs services internes.

## Schema logique

```mermaid
flowchart LR
    U[Utilisateur]

    subgraph EDGE[Exposition]
      N[Nginx<br/>80 / 443 / 8443]
    end

    subgraph APP[Reseau applicatif interne]
      LANDING[Landing page]
      A1[app1<br/>whoami]
      A2[app2<br/>whoami]
      API[api<br/>echo-server]
      STATIC[Static site]
    end

    U --> N
    N -->|/| LANDING
    N -->|/app/| A1
    N -->|/app/| A2
    N -->|/api/| API
    N -->|/admin/| A1
    N -->|static.local| STATIC
```

## Composants

### Nginx

Point d'entree unique expose sur l'hote.

Responsabilites :

- recevoir les requetes HTTP et HTTPS
- rediriger HTTP vers HTTPS
- router selon le domaine ou le chemin
- servir du contenu statique
- proxyfier les requetes vers les services internes
- proteger certaines routes

### app1 et app2

Deux services de demonstration utilises pour illustrer le load balancing.

### api

Service HTTP interne utilise pour montrer le reverse proxy vers une API.

### landing et static

Deux sites statiques servis par Nginx.

## Flux principaux

### 1. Arrivee du trafic

Le client appelle `nginx.local` ou `static.local`. Nginx est le seul service expose au reseau externe.

### 2. Redirection HTTPS

Les requetes arrivees sur `80` sont redirigees vers `443`.

### 3. Routage

Nginx route ensuite selon le contexte :

- `/` vers le site principal
- `/app/` vers `app1` et `app2`
- `/api/` vers `api`
- `/admin/` vers le backend avec Basic Auth
- `static.local` vers le site statique secondaire

## Reseaux Docker

Le projet utilise deux reseaux :

- `edge` : reseau de facade sur lequel Nginx est expose
- `app_net` : reseau interne reserve aux backends

Cela permet de ne pas exposer directement les services applicatifs.

## Lecture pratique du reverse proxy

Quand une requete arrive :

1. le client contacte Nginx
2. Nginx identifie le bon bloc `server`
3. Nginx choisit la bonne `location`
4. Nginx sert un fichier statique ou relaie la requete vers un upstream
5. la reponse revient au client via Nginx

## Bonnes pratiques visibles dans ce lab

- un point d'entree unique
- des backends non publies
- HTTPS active
- snippets reutilisables pour le proxy
- fichiers de configuration separes entre dev et prod
- authentification simple sur une zone sensible
