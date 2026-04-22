# Debug Let's Encrypt

## Objectif

Ce guide aide a debloquer les echecs les plus courants avec Let's Encrypt dans ce projet.

Il est pense pour le mode staging en premier, ce qui est le meilleur terrain de test.

## Reflexe de base

Avant de chercher loin, verifie ces 4 points :

1. le domaine pointe bien vers le bon serveur
2. le port `80` est ouvert
3. Nginx tourne bien
4. `LETSENCRYPT_STAGING=true` pendant les essais

## Commandes de base

Etat de la stack :

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml ps
```

Logs Nginx :

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml logs --tail=200 nginx
```

Lancer une demande :

```bash
make le-prod
```

## Probleme 1. Le domaine ne resolvait pas vers le serveur

Symptomes :

- Let's Encrypt ne trouve pas ton serveur
- timeout ou erreur de connexion

Verification :

```bash
dig +short ton-domaine.tld
dig +short static.ton-domaine.tld
```

Les reponses doivent pointer vers l'IP publique du VPS.

## Probleme 2. Le port 80 n'est pas accessible

Symptomes :

- echec HTTP-01
- timeout
- connexion refusee

Verification depuis une machine externe :

```bash
curl -I http://ton-domaine.tld/
```

Si cela ne repond pas, il faut verifier :

- firewall du VPS
- security group du cloud provider
- NAT ou redirection reseau si besoin

## Probleme 3. Nginx ne tourne pas

Verification :

```bash
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml ps
```

Et :

```bash
make validate ENV_FILE=.env.prod
```

Si `nginx -t` echoue, corrige d'abord la configuration avant de relancer Certbot.

## Probleme 4. Tu utilises encore des domaines d'exemple

Le script bloque volontairement ce cas.

Si tu as encore :

- `example.com`
- `static.example.com`

Alors [scripts/request-letsencrypt.sh](/root/Nginx/scripts/request-letsencrypt.sh:1) refusera de continuer.

## Probleme 5. Tu testes avec `localhost` ou `/etc/hosts`

Let's Encrypt ne peut pas valider un domaine purement local.

Le staging Let’s Encrypt a besoin :

- d'un vrai domaine public
- d'un acces Internet reel jusqu'au serveur

## Probleme 6. La route ACME n'est pas servie correctement

Ce projet attend :

- un webroot `/var/www/certbot`
- une `location /.well-known/acme-challenge/`

Tu peux verifier que cette route existe dans :

- [nginx/templates/default.conf.template](/root/Nginx/nginx/templates/default.conf.template:1)
- [nginx/templates-prod/default.conf.template](/root/Nginx/nginx/templates-prod/default.conf.template:1)

## Probleme 7. Nginx repond, mais pas le bon serveur

Symptomes :

- mauvais domaine servi
- mauvaise redirection
- certificat inattendu

Verifications utiles :

```bash
curl -I -H "Host: ton-domaine.tld" http://127.0.0.1/
curl -kI --resolve ton-domaine.tld:443:127.0.0.1 https://ton-domaine.tld/
```

Cela aide a verifier le routage par `server_name`.

## Probleme 8. Certbot a bien obtenu un certificat, mais Nginx sert encore l'ancien

Dans ce projet, les certificats Let's Encrypt sont ensuite recopies vers `certs/` par :

- [scripts/sync-letsencrypt-certs.sh](/root/Nginx/scripts/sync-letsencrypt-certs.sh:1)

Puis Nginx est recharge.

Si besoin, relance :

```bash
ENV_FILE=.env.prod ./scripts/sync-letsencrypt-certs.sh
docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml exec nginx nginx -s reload
```

## Probleme 9. Le navigateur affiche encore une alerte

En staging, c'est normal.

Les certificats de staging Let's Encrypt ne sont pas approuves par les navigateurs.

Pour cette raison, en staging, les tests se font plutot avec :

```bash
curl -kI https://ton-domaine.tld/
```

## Probleme 10. Le renouvellement ne marche pas

Teste d'abord manuellement :

```bash
make le-renew-prod
```

Puis seulement ensuite pense a l'automatisation avec :

```bash
make le-install-cron-prod
```

## Ordre de debug recommande

Quand ca bloque, suis cet ordre :

1. verifier le DNS
2. verifier le port `80`
3. verifier que Nginx tourne
4. verifier la configuration Nginx
5. verifier que `LETSENCRYPT_STAGING=true`
6. relancer `make le-prod`
7. lire les logs Nginx

## Sources officielles

- Let's Encrypt staging environment : https://letsencrypt.org/docs/staging-environment/
- Let's Encrypt challenge types : https://letsencrypt.org/docs/challenge-types/
- Certbot : https://certbot.eff.org/

## Resume

Dans la plupart des cas, un echec Let's Encrypt vient de l'un de ces trois points :

- DNS incorrect
- port `80` non accessible
- domaine non public
