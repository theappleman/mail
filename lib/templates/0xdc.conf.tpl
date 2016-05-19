server {
	listen 0.0.0.0:80;
	listen [::]:80;

	<% if ($ssl) { %>
	listen 0.0.0.0:443 ssl;
	listen [::]:443 ssl;

	ssl_certificate /var/lib/acme/live/willow.0xdc.host/fullchain;
	ssl_certificate_key /var/lib/acme/live/willow.0xdc.host/privkey;
	<% } %>

	include acme-challenge.conf;

	location /.well-known/coreos {
			sub_filter '<public>' '$remote_addr';
			sub_filter '<hostname>' 'coreos$remote_port';
			sub_filter_once off;
			sub_filter_types '*';
			try_files @backend;
			access_log off;
	 }

	location /static {
		alias /home/www0xdc/0xdc-cfg/static;
	}

	location / {
		try_files $uri $uri/ @backend;
	}

	location @backend {
		proxy_pass http://127.0.0.1:8000;
		proxy_set_header Host $host;
		access_log /var/log/nginx/0xdc_log main;
	}
}
