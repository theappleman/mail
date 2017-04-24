server {
	listen 0.0.0.0:80;
	listen [::]:80;

	server_name applehq.eu;
	include acme-challenge.conf;
	<% if ($ssl) { %>
	return 301 https://applehq.eu$request_uri;
}

server {
	server_name applehq.eu;
	listen 0.0.0.0:443 ssl;
	listen [::]:443 ssl;

	ssl_certificate /var/lib/acme/live/applehq.eu/fullchain;
	ssl_certificate_key /var/lib/acme/live/applehq.eu/privkey;
	<% } %>

	location /public {
		alias /home/applehq/applehq.eu/public;
	}

	location / {
		try_files $uri $uri/ @backend;
	}

	location @backend {
		proxy_pass http://127.0.0.1:3000;
		proxy_set_header Host $host;
		access_log /var/log/nginx/applehq.eu_log combined;
	}
}
