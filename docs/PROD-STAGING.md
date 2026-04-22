# Prod And Staging

## Objectif

Ce document explique comment utiliser ce projet dans une logique proche de la production, tout en restant volontairement en staging pour Let’s Encrypt.

Le but n'est pas de te faire passer en prod maintenant.

Le but est de te donner :

- une methode de test propre en staging
- une comprehension claire du mecanisme
- une check-list tres simple pour le jour ou tu voudras passer en prod

## Idee generale

Dans ce projet, tu peux raisonner en trois etapes :

1. local : certificats autosignes pour comprendre Nginx
2. staging Let's Encrypt : vrai flux ACME, mais certificats de test non fiables
3. prod Let's Encrypt : meme flux, mais certificats publics valides

Tu peux rester durablement a l'etape 2 si ton objectif est pedagogique.

## Tres important sur le staging Let's Encrypt

Le staging est recommande par Let's Encrypt pour tester avant la production.

Points importants :

- le staging permet de tester sans consommer les limites de production
- les certificats de staging ne sont pas de confiance dans les navigateurs
- avec Certbot, on utilise en general `--staging`, `--test-cert` ou `--dry-run` selon le cas

Sources officielles :

- Let's Encrypt staging environment : https://letsencrypt.org/docs/staging-environment/
- Let's Encrypt challenge types : https://letsencrypt.org/docs/challenge-types/
- Certbot : https://certbot.eff.org/

## Ce que ce projet fait deja

Le projet contient deja :

- un profil `certbot` dans [docker-compose.yml](/root/Nginx/docker-compose.yml:1)
- un script [scripts/request-letsencrypt.sh](/root/Nginx/scripts/request-letsencrypt.sh:1)
- un script [scripts/renew-letsencrypt.sh](/root/Nginx/scripts/renew-letsencrypt.sh:1)
- un chemin webroot `/.well-known/acme-challenge/` dans les templates Nginx

Autrement dit, la logique de validation HTTP-01 est deja prevue.

## Comment fonctionne HTTP-01

Pour HTTP-01, Let's Encrypt demande a voir un fichier special sur :

`http://ton-domaine/.well-known/acme-challenge/<token>`

Dans ce projet :

- Certbot depose le fichier dans `/var/www/certbot`
- Nginx sert ce dossier via `location /.well-known/acme-challenge/`
- Let's Encrypt verifie ensuite que le fichier est bien accessible depuis Internet

## Conditions pour que le staging fonctionne vraiment

Pour obtenir un certificat Let's Encrypt, meme en staging, il faut :

- un vrai nom de domaine public
- un DNS qui pointe vers ton serveur
- le port `80` accessible depuis Internet
- Nginx joignable publiquement

Si tu restes uniquement sur `localhost`, `nginx.local` ou `/etc/hosts`, Let's Encrypt ne pourra pas valider le domaine.

## Configuration recommandee pour rester en staging

Le fichier cible est [.env.prod](/root/Nginx/.env.prod:1).

Exemple d'intention :

```env
COMPOSE_ENV_FILE=.env.prod
COMPOSE_PROJECT_NAME=nginx-prod
NGINX_SERVER_NAME=ton-domaine.tld
STATIC_SERVER_NAME=static.ton-domaine.tld
LETSENCRYPT_EMAIL=toi@exemple.com
LETSENCRYPT_STAGING=true
```

Le point cle ici est :

- `LETSENCRYPT_STAGING=true`

Tant que cette variable reste a `true`, le script demande des certificats de test.

## Workflow conseille pour toi

### Etape 1. Garder le mode local pour apprendre

Utilise :

```bash
make init-dev
make up
```

Ici, tu travailles avec certificats autosignes et domaines locaux.

### Etape 2. Preparer un vrai domaine de test

Quand tu voudras comprendre le vrai flux ACME :

1. prends un domaine ou sous-domaine public dedie au test
2. fais pointer son DNS vers ton serveur
3. garde `LETSENCRYPT_STAGING=true`
4. utilise `.env.prod`

### Etape 3. Lancer en mode prod du projet, mais avec Let’s Encrypt staging

```bash
make init-prod
make up-prod
make le-prod
```

Important :

- ici, `prod` veut dire "topologie du projet", pas "certificat public final"
- tant que `LETSENCRYPT_STAGING=true`, tu restes en environnement de test ACME

### Etape 4. Comprendre le resultat

Si tout se passe bien :

- Certbot obtient un certificat de staging
- le script le synchronise dans `certs/`
- Nginx recharge sa configuration

Le navigateur affichera quand meme un avertissement, car le certificat de staging n'est pas approuve par les navigateurs.

## Ce qu'il faudra changer le jour ou tu voudras passer en prod

Le passage vers la vraie production est volontairement simple.

Dans [.env.prod](/root/Nginx/.env.prod:1), il faudra seulement :

```env
LETSENCRYPT_STAGING=false
```

Puis relancer :

```bash
make le-prod
```

Dans ce projet, le changement principal est donc un basculement de variable d'environnement.

## Ce que je te recommande en pratique

Si ton objectif est d'apprendre sans risque :

- garde le lab local pour tout comprendre
- utilise un vrai domaine de test seulement quand tu veux apprendre ACME
- laisse `LETSENCRYPT_STAGING=true` tant que tu ne veux pas de certificat public final

Tu auras ainsi un environnement "quasi prod" pour la comprehension, sans vrai passage en production de certificat.

## Bonnes pratiques de deploiement

### 1. Toujours tester en staging d'abord

C'est la recommandation officielle de Let's Encrypt.

### 2. Distinguer topologie prod et certificat prod

Tu peux utiliser :

- la stack `docker-compose.prod.yml`
- de vrais noms de domaine
- une exposition publique

Tout en restant en certificat de staging.

### 3. Garder un domaine de test dedie

Exemples :

- `nginx-lab.exemple.com`
- `static-nginx-lab.exemple.com`

Cela evite de melanger apprentissage et services reels.

### 4. Ouvrir seulement ce qui est necessaire

Pour HTTP-01, le port `80` doit etre joignable.

Le port `443` sert le site HTTPS.

### 5. Laisser les challenges ACME passer en clair

La route `/.well-known/acme-challenge/` doit rester correctement servie par Nginx.

### 6. Automatiser le renouvellement seulement apres validation du flux

Le projet contient deja :

- [scripts/renew-letsencrypt.sh](/root/Nginx/scripts/renew-letsencrypt.sh:1)
- [scripts/install-renew-cron.sh](/root/Nginx/scripts/install-renew-cron.sh:1)

Je te conseille d'abord de reussir une emission manuelle en staging avant d'automatiser.

## Difference simple entre staging et prod

### Staging

- bon pour apprendre
- bon pour tester le flux
- certificats non fiables dans le navigateur
- peu de risque de heurter les limites reelles

### Prod

- bon pour un vrai site public
- certificats valides
- demande plus d'attention
- a utiliser seulement quand le staging est deja maitrise

## Check-list de passage eventuel en prod

Le jour ou tu voudras pouvoir passer en prod, voici la check-list minimale :

1. confirmer que le DNS public pointe bien vers le bon serveur
2. verifier que le port `80` est ouvert
3. verifier que `http://ton-domaine/.well-known/acme-challenge/test` peut etre servi
4. basculer `LETSENCRYPT_STAGING=false`
5. relancer `make le-prod`
6. verifier le certificat presente par Nginx

## En une phrase

Tu peux utiliser la topologie "prod" du projet des maintenant, tout en restant volontairement sur des certificats Let's Encrypt de staging, et ne basculer en vraie prod que plus tard en changeant seulement une variable.
