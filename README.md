# Nginx Docker Lab

Une stack simple et complete pour apprendre les usages essentiels de Nginx en reverse proxy avec Docker.

## Ce que montre ce projet

Ce lab se concentre sur les usages les plus utiles de Nginx dans un contexte realiste :

- terminaison TLS sur `443`
- redirection HTTP vers HTTPS
- reverse proxy vers une API interne
- load balancing entre plusieurs services
- hebergement de plusieurs sites avec des `server_name`
- protection d'une zone avec Basic Auth
- service de contenu statique
- quelques bonnes pratiques de securite et de logs

## Usages principaux d'un reverse proxy Nginx

### 1. Centraliser l'entree web

Nginx recoit toutes les requetes entrantes puis decide quoi faire selon le domaine, le port ou le chemin demande.

Exemples dans ce projet :

- `https://nginx.local/` sert le site principal
- `https://nginx.local/app/` envoie la requete vers un cluster applicatif
- `https://nginx.local/api/` envoie la requete vers une API interne
- `https://static.local/` sert un second site statique

### 2. Cacher l'infrastructure interne

Les services `app1`, `app2` et `api` ne sont pas exposes publiquement. Seul Nginx est publie. Cela simplifie la securite et l'exploitation.

### 3. Gerer HTTPS

Nginx porte les certificats, negocie TLS et peut rediriger automatiquement le trafic HTTP vers HTTPS.

### 4. Faire du routage applicatif

Nginx peut router par domaine ou par chemin :

- routage par domaine avec `nginx.local` et `static.local`
- routage par chemin avec `/app/`, `/api/` et `/admin/`

### 5. Equilibrer la charge

Dans ce lab, Nginx distribue les requetes du chemin `/app/` entre `app1` et `app2`.

### 6. Ajouter une couche de securite

Nginx applique ici :

- des en-tetes de securite
- le masquage de version
- une zone protegee par mot de passe sur `/admin/`

## Architecture

Schema detaille : [docs/ARCHITECTURE.md](/root/Nginx/docs/ARCHITECTURE.md:1)

```mermaid
flowchart LR
    C[Client]
    N[Nginx reverse proxy]
    S1[Site principal]
    A1[app1]
    A2[app2]
    API[api]
    S2[Site statique secondaire]

    C --> N
    N -->|/| S1
    N -->|/app/| A1
    N -->|/app/| A2
    N -->|/api/| API
    N -->|static.local| S2
```

## Arborescence utile

```text
.
|-- docker-compose.yml
|-- docker-compose.dev.yml
|-- docker-compose.prod.yml
|-- Makefile
|-- docs/
|   `-- ARCHITECTURE.md
|-- nginx/
|   |-- nginx.conf
|   |-- snippets/
|   `-- templates/
|-- scripts/
`-- sites/
    |-- landing/
    `-- static/
```

## Demarrage rapide

### 1. Initialiser

```bash
chmod +x scripts/*.sh
make init-dev
```

Cette commande :

- cree `.env.dev` si besoin
- genere des certificats autosignes
- genere le fichier `.htpasswd` pour `/admin/`

### 2. Ajouter les entrees locales

Ajoutez dans `/etc/hosts` :

```text
127.0.0.1 nginx.local
127.0.0.1 static.local
```

### 3. Lancer la stack

```bash
make up
```

### 4. Tester

```bash
curl -I -H "Host: nginx.local" http://127.0.0.1/
curl -k https://nginx.local/
curl -k https://nginx.local/app/
curl -k https://nginx.local/api/
curl -k -u admin:ChangeMeNow123! https://nginx.local/admin/
curl -k https://static.local/
curl -k https://localhost/
curl -k https://localhost:8443/
```

## Comment Nginx est utilise ici

### Site principal

Le site principal est servi directement par Nginx depuis `sites/landing/`.

### Reverse proxy vers une API

Le chemin `/api/` est transmis au service `api` sur le reseau interne Docker.

### Load balancing

Le chemin `/app/` utilise l'upstream `app_cluster`, compose de `app1` et `app2`.

### Zone protegee

Le chemin `/admin/` exige une authentification Basic Auth avant de relayer vers le backend.

### Multi-site

Un second bloc `server` repond pour `static.local` et sert le contenu de `sites/static/`.

## Fichiers a connaitre

- [docker-compose.yml](/root/Nginx/docker-compose.yml:1) : definition des services
- [docker-compose.dev.yml](/root/Nginx/docker-compose.dev.yml:1) : options locales de developpement
- [docker-compose.prod.yml](/root/Nginx/docker-compose.prod.yml:1) : surcharge production
- [nginx/nginx.conf](/root/Nginx/nginx/nginx.conf:1) : configuration globale Nginx
- [nginx/templates/default.conf.template](/root/Nginx/nginx/templates/default.conf.template:1) : virtual hosts du mode dev
- [nginx/templates-prod/default.conf.template](/root/Nginx/nginx/templates-prod/default.conf.template:1) : virtual hosts du mode prod

## Commandes utiles

```bash
make up
make down
make logs
make validate
make test
```

## Documentation officielle

- Nginx Reverse Proxy: https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/
- Nginx Load Balancing: https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/
- Nginx Beginner's Guide: https://nginx.org/en/docs/beginners_guide.html
- Nginx Admin Guide: https://docs.nginx.com/nginx/admin-guide/

## Suite possible

Cette base est volontairement simple. On pourra ensuite l'ameliorer avec :

- Let's Encrypt
- cache proxy plus avance
- rate limiting plus strict
- headers et hardening supplementaires
- CI de validation Nginx
