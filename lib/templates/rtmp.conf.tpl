rtmp {
	deny publish all;
	allow play all;

	server {
		listen [::]:1935;
		chunk_size 4096;

		application record {
			live on;

			record all;
			record_path /var/www/rtmp;
			record_unique on;

		}

		application live {
			live on;
			record off;

			push rtmp://a.rtmp.youtube.com/live2/;
			push rtmp://live-ams.twitch.tv/app/;

		}
	}
}
