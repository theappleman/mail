server {
	listen 0.0.0.0:80;
	listen [::]:80;

	server_name 0xdc.io mail.0xdc.io;
	include acme-challenge.conf;
	<% if ($ssl) { %>
	return 301 https://0xdc.io$request_uri;
}

server {
	listen 0.0.0.0:443 ssl;
	listen [::]:443 ssl;

	server_name 0xdc.io mail.0xdc.io;

	ssl_certificate /var/lib/acme/live/0xdc.io/fullchain;
	ssl_certificate_key /var/lib/acme/live/0xdc.io/privkey;
	<% } %>


	location /.well-known/coreos {
			sub_filter '<public>' '$remote_addr';
			sub_filter '<hostname>' 'coreos$remote_port';
			sub_filter_once off;
			sub_filter_types '*';
			try_files $uri $uri/ @backend;
			access_log off;
	 }

	location /static {
		alias /home/_0xdc/0xdc-cfg/static;
	}

	location / {
		try_files $uri $uri/ @backend;
	}

	location @backend {
		proxy_pass http://127.0.0.1:8000;
		proxy_set_header Host $host;
		access_log /var/log/nginx/0xdc.io_log combined;
	}
}
