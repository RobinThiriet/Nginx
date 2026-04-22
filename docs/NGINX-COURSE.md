# Nginx Course

## Objectif

Ce document explique le template
[nginx/templates/default.conf.template](/root/Nginx/nginx/templates/default.conf.template:1)
presque ligne par ligne, avec une logique de cours.

L'idee est simple :

1. comprendre ce que Nginx lit
2. comprendre dans quel ordre il prend ses decisions
3. comprendre pourquoi chaque bloc existe

## Comment lire un fichier Nginx

Quand Nginx recoit une requete, on peut lire sa logique comme ceci :

1. quel port recoit la requete
2. quel `server` correspond au domaine demande
3. quelle `location` correspond au chemin demande
4. est-ce que Nginx sert un fichier ou fait un proxy

Si tu gardes cette grille en tete, la plupart des configurations Nginx deviennent bien plus faciles a lire.

## Le template complet

Reference :
[nginx/templates/default.conf.template](/root/Nginx/nginx/templates/default.conf.template:1)

## Bloc `upstream`

```nginx
upstream app_cluster {
    least_conn;
    server app1:80 max_fails=3 fail_timeout=10s;
    server app2:80 max_fails=3 fail_timeout=10s;
    keepalive 32;
}
```

Explication ligne par ligne :

- `upstream app_cluster {` : on cree un groupe logique de serveurs backend
- `least_conn;` : Nginx envoie de preference la requete au serveur qui a le moins de connexions actives
- `server app1:80 ...;` : premier backend disponible dans le cluster
- `server app2:80 ...;` : second backend disponible dans le cluster
- `max_fails=3 fail_timeout=10s;` : si un backend echoue plusieurs fois, Nginx le considere temporairement indisponible
- `keepalive 32;` : Nginx peut reutiliser des connexions ouvertes vers les backends

Ce bloc sert a faire du load balancing pour `/app/`, `/cache-demo/` et `/admin/`.

## Premier bloc `server` HTTP

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name ${NGINX_SERVER_NAME};
```

Explication :

- `server {` : debut d'un hote virtuel
- `listen 80;` : ce site ecoute en HTTP sur IPv4
- `listen [::]:80;` : meme chose pour IPv6
- `server_name ${NGINX_SERVER_NAME};` : ce bloc s'applique au domaine principal

### Challenge ACME

```nginx
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
```

Ce bloc permet a Certbot de deposer les fichiers de validation HTTP-01 dans un dossier que Nginx sait servir.

Concretement, Let's Encrypt vient tester une URL comme :

`http://ton-domaine/.well-known/acme-challenge/<token>`

### Healthcheck

```nginx
    location /healthz {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
```

Ce bloc sert uniquement a verifier rapidement que Nginx repond.

- `access_log off;` : on evite de polluer les logs
- `return 200` : Nginx renvoie directement une reponse simple
- `add_header Content-Type text/plain;` : on force un type de contenu lisible

### Redirection HTTP vers HTTPS

```nginx
    location / {
        return 301 https://$host$request_uri;
    }
}
```

- `location /` : toutes les autres requetes tombent ici
- `return 301 ...` : redirection permanente vers HTTPS

## Deuxieme bloc `server` HTTP

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name ${STATIC_SERVER_NAME};
```

Ce bloc fait la meme chose pour le site secondaire `static.local`.

Il sert surtout a :

- repondre au challenge ACME
- rediriger ensuite vers HTTPS

## Bloc `default_server`

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
```

Ce bloc capture ce qui ne correspond a aucun domaine declare.

### Pourquoi il est utile

Il evite qu'une requete inconnue tombe par hasard sur ton site principal.

### `location /nginx_status`

```nginx
    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        allow ::1;
        allow 172.16.0.0/12;
        deny all;
    }
```

Ce bloc expose un petit statut Nginx reserve aux acces internes.

- `stub_status;` : active une page d'etat minimale
- `allow ...` : autorise seulement certaines adresses
- `deny all;` : bloque tout le reste

### Rejet des autres requetes

```nginx
    location / {
        return 444;
    }
}
```

`444` est une reponse Nginx speciale qui ferme la connexion sans page classique.

## Bloc HTTPS principal

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name ${NGINX_SERVER_NAME};
```

Ce bloc gere le vrai site principal en HTTPS.

- `listen 443 ssl;` : Nginx attend du TLS
- `http2 on;` : active HTTP/2
- `server_name ...` : ce bloc s'applique au domaine principal

### Certificats TLS

```nginx
    ssl_certificate /etc/nginx/certs/${NGINX_SERVER_NAME}.crt;
    ssl_certificate_key /etc/nginx/certs/${NGINX_SERVER_NAME}.key;
    ssl_protocols TLSv1.2 TLSv1.3;
```

- `ssl_certificate` : chemin du certificat public
- `ssl_certificate_key` : chemin de la cle privee
- `ssl_protocols` : limite les versions TLS aux plus modernes

### Parametres TLS supplementaires

```nginx
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_ciphers HIGH:!aNULL:!MD5;
```

Ce sont des reglages classiques :

- cache de session TLS
- duree de vie des sessions
- politique de suites cryptographiques

### Headers de securite

```nginx
    include /etc/nginx/snippets/security-headers.conf;
```

On factorise ici des headers de securite communs dans un snippet reutilisable.

### Racine du site principal

```nginx
    root /usr/share/nginx/lab-sites/landing;
    index index.html;
```

- `root` : dossier de contenu
- `index` : page par defaut

### Healthcheck HTTPS et statut

```nginx
    location = /healthz {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
```

Le `=` signifie ici correspondance exacte du chemin.

Même logique pour :

```nginx
    location = /nginx_status {
        stub_status;
        ...
    }
```

## `location /`

```nginx
    location / {
        try_files $uri $uri/ /index.html;
    }
```

`try_files` teste plusieurs possibilites :

- le fichier demande
- le dossier demande
- sinon `index.html`

C'est pratique pour un site statique simple.

## `location /app/`

```nginx
    location /app/ {
        include /etc/nginx/snippets/proxy-common.conf;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_pass http://app_cluster/;
    }
```

Ligne par ligne :

- `location /app/` : toutes les requetes commencant par `/app/`
- `include ...proxy-common.conf` : ajoute les headers proxy communs
- `proxy_http_version 1.1;` : force HTTP/1.1 vers le backend
- `proxy_set_header Connection "";` : nettoie l'en-tete `Connection`
- `proxy_pass http://app_cluster/;` : envoie la requete vers l'upstream

## `location /api/`

```nginx
    location /api/ {
        include /etc/nginx/snippets/proxy-common.conf;
        limit_req zone=api_rate_limit burst=20 nodelay;
        proxy_pass http://api/;
    }
```

Ligne par ligne :

- `include ...` : ajoute les headers proxy
- `limit_req ...` : active une limitation de debit
- `burst=20` : accepte un petit pic temporaire
- `nodelay` : ne retarde pas artificiellement les requetes autorisees
- `proxy_pass http://api/;` : envoie la requete au service `api`

## `location /cache-demo/`

```nginx
    location /cache-demo/ {
        include /etc/nginx/snippets/proxy-common.conf;
        proxy_cache lab_cache;
        proxy_cache_valid 200 10m;
        proxy_cache_methods GET HEAD;
        proxy_ignore_headers Set-Cookie Cache-Control Expires;
        add_header X-Cache-Status $upstream_cache_status always;
        proxy_pass http://app_cluster/;
    }
```

Ce bloc montre le cache reverse proxy.

- `proxy_cache lab_cache;` : utilise la zone de cache definie globalement
- `proxy_cache_valid 200 10m;` : garde les reponses `200` pendant 10 minutes
- `proxy_cache_methods GET HEAD;` : met en cache seulement les methodes prevues
- `proxy_ignore_headers ...` : ignore certains headers du backend pour la demo
- `add_header X-Cache-Status ...` : permet de voir `MISS`, `HIT` ou autre dans la reponse

## `location /admin/`

```nginx
    location /admin/ {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/auth/.htpasswd;
        include /etc/nginx/snippets/proxy-common.conf;
        proxy_pass http://app_cluster/;
    }
```

Ce bloc ajoute une protection simple.

- `auth_basic` : active la fenetre d'authentification HTTP Basic
- `auth_basic_user_file` : pointe vers le fichier d'utilisateurs
- `proxy_pass` : une fois authentifie, le client atteint le backend

## Bloc HTTPS du site secondaire

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    listen 8443 ssl;
    listen [::]:8443 ssl;
    http2 on;
    server_name ${STATIC_SERVER_NAME};
```

Ce bloc sert le site statique secondaire.

Le port `8443` est utile en local pour tester un second site HTTPS sans autre IP.

```nginx
    root /usr/share/nginx/lab-sites/static;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Ici, Nginx sert simplement les fichiers statiques du second site.

## Le snippet `proxy-common.conf`

Reference :
[nginx/snippets/proxy-common.conf](/root/Nginx/nginx/snippets/proxy-common.conf:1)

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;
proxy_connect_timeout 5s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

Ce snippet sert a standardiser le comportement du reverse proxy.

- `Host` : conserve le host original
- `X-Real-IP` : transmet l'IP du client vue par Nginx
- `X-Forwarded-For` : conserve la chaine des proxys
- `X-Forwarded-Proto` : dit si la requete d'origine etait en HTTP ou HTTPS
- `X-Forwarded-Host` : transmet le nom d'hote original
- `X-Forwarded-Port` : transmet le port d'origine
- `proxy_connect_timeout` : temps max pour ouvrir la connexion backend
- `proxy_send_timeout` : temps max pour envoyer la requete au backend
- `proxy_read_timeout` : temps max pour lire la reponse backend

## Resume de la lecture

Si tu dois retenir seulement l'essentiel :

1. `upstream` regroupe les backends
2. `server` choisit le site selon port et domaine
3. `location` choisit l'action selon le chemin
4. `proxy_pass` envoie la requete a l'application
5. les snippets evitent de repeter la meme configuration partout
