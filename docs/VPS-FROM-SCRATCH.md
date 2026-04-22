# VPS From Scratch

## Objectif

Ce guide montre un scenario tres pratique :

- tu pars d'un VPS neuf
- tu veux faire tourner ce projet
- tu veux comprendre le mode "quasi prod"
- tu veux rester en Let's Encrypt staging

Le but n'est toujours pas de te faire passer en vrai prod.

## Hypotheses

On part sur :

- un VPS Linux
- Docker et Docker Compose plugin installes
- un utilisateur avec droits `sudo`
- un vrai domaine ou sous-domaine de test

Exemple :

- `nginx-lab.exemple.com`
- `static.nginx-lab.exemple.com`

## Vue rapide du plan

1. preparer le VPS
2. ouvrir les bons ports
3. pointer le DNS
4. cloner le projet
5. preparer `.env.prod`
6. lancer la stack prod du projet
7. demander un certificat staging
8. verifier le fonctionnement

## 1. Preparer le VPS

Exemples de commandes utiles :

```bash
sudo apt update
sudo apt install -y git curl
docker --version
docker compose version
```

Si Docker n'est pas encore installe, il faut d'abord l'installer proprement sur le serveur.

## 2. Ouvrir les ports

Pour ce projet, les ports importants sont :

- `80/tcp`
- `443/tcp`

Le port `80` est indispensable pour HTTP-01 avec Let's Encrypt.

## 3. Configurer le DNS

Avant toute tentative Let's Encrypt, fais pointer :

- `nginx-lab.exemple.com` vers l'IP publique du VPS
- `static.nginx-lab.exemple.com` vers l'IP publique du VPS

Tu peux verifier depuis ta machine :

```bash
dig +short nginx-lab.exemple.com
dig +short static.nginx-lab.exemple.com
```

Les deux doivent resoudre vers l'IP du VPS.

## 4. Cloner le projet

Sur le VPS :

```bash
git clone https://github.com/RobinThiriet/Nginx.git
cd Nginx
chmod +x scripts/*.sh
```

## 5. Preparer `.env.prod`

Cree le fichier :

```bash
cp .env.prod.example .env.prod
```

Puis adapte au minimum :

```env
COMPOSE_ENV_FILE=.env.prod
COMPOSE_PROJECT_NAME=nginx-prod
NGINX_SERVER_NAME=nginx-lab.exemple.com
STATIC_SERVER_NAME=static.nginx-lab.exemple.com
ADMIN_USERNAME=admin
ADMIN_PASSWORD=un-bon-mot-de-passe
LETSENCRYPT_EMAIL=toi@exemple.com
LETSENCRYPT_STAGING=true
```

Le point important est :

- `LETSENCRYPT_STAGING=true`

## 6. Initialiser les fichiers locaux

```bash
make init-prod
```

Cette commande :

- cree des certificats autosignes de depart
- cree le fichier `.htpasswd`

Cela permet a Nginx de demarrer meme avant Let’s Encrypt.

## 7. Lancer la stack

```bash
make up-prod
```

Puis verifier :

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml ps
make validate ENV_FILE=.env.prod
```

## 8. Tester que le challenge ACME pourra passer

Depuis une machine externe au VPS, teste deja :

```bash
curl -I http://nginx-lab.exemple.com/
```

Tu dois voir une redirection vers HTTPS.

Le plus important est que le domaine arrive bien sur ton Nginx public.

## 9. Demander le certificat Let's Encrypt en staging

```bash
make le-prod
```

Dans ce projet, cette commande :

1. demarre Nginx si besoin
2. lance Certbot avec `--staging` si `LETSENCRYPT_STAGING=true`
3. recupere les certificats
4. synchronise les certificats dans `certs/`
5. recharge Nginx

## 10. Verifier le resultat

Tu peux verifier :

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml logs --tail=100 nginx
```

Et depuis ta machine :

```bash
curl -kI https://nginx-lab.exemple.com/
curl -kI https://static.nginx-lab.exemple.com/
```

Le `-k` reste utile en staging car le certificat n'est pas reconnu comme fiable par le navigateur.

## 11. Renouvellement

Quand tu veux tester le renouvellement :

```bash
make le-renew-prod
```

Et si un jour tu veux automatiser :

```bash
make le-install-cron-prod
```

Je te conseille de ne faire cela qu'apres une premiere emission staging reussie.

## 12. Le jour ou tu voudras rendre la prod possible

Tu n'auras pas besoin de changer tout le projet.

Le changement minimal sera dans `.env.prod` :

```env
LETSENCRYPT_STAGING=false
```

Puis :

```bash
make le-prod
```

## Checklist VPS

Si tu veux un pense-bete rapide :

1. VPS accessible
2. Docker OK
3. ports `80` et `443` ouverts
4. DNS pointe vers le VPS
5. `.env.prod` rempli avec vrais domaines
6. `LETSENCRYPT_STAGING=true`
7. `make init-prod`
8. `make up-prod`
9. `make le-prod`

## En une phrase

Sur un VPS, tu peux utiliser ce projet comme une vraie topologie publique, tout en restant volontairement en certificats Let's Encrypt de staging pour apprendre sans risque.
