#
# Container Image NGINX
#

FROM alpine:3.16.2

ARG PROJ_NAME
ARG PROJ_VERSION
ARG PROJ_BUILD_NUM
ARG PROJ_BUILD_DATE
ARG PROJ_REPO

LABEL org.opencontainers.image.authors="V10 Solutions"
LABEL org.opencontainers.image.title="${PROJ_NAME}"
LABEL org.opencontainers.image.version="${PROJ_VERSION}"
LABEL org.opencontainers.image.revision="${PROJ_BUILD_NUM}"
LABEL org.opencontainers.image.created="${PROJ_BUILD_DATE}"
LABEL org.opencontainers.image.description="Container image for NGINX"
LABEL org.opencontainers.image.source="${PROJ_REPO}"

RUN apk update \
	&& apk add --no-cache "shadow" "bash" \
	&& usermod -s "$(command -v "bash")" "root"

SHELL [ \
	"bash", \
	"--noprofile", \
	"--norc", \
	"-o", "errexit", \
	"-o", "nounset", \
	"-o", "pipefail", \
	"-c" \
]

ENV LANG "C.UTF-8"
ENV LC_ALL "${LANG}"

RUN apk add --no-cache \
	"ca-certificates" \
	"curl" \
	"gd-dev" \
	"perl-dev" \
	"zlib-dev" \
	"geoip-dev" \
	"pcre2-dev" \
	"libxml2-dev" \
	"libxslt-dev" \
	"openssl-dev" \
	"libatomic_ops-dev"

RUN apk add --no-cache -t "build-deps" \
	"make" \
	"patch" \
	"linux-headers" \
	"gcc" \
	"g++" \
	"pkgconf"

RUN groupadd -r -g "480" "nginx" \
	&& useradd \
		-r \
		-m \
		-s "$(command -v "nologin")" \
		-g "nginx" \
		-c "NGINX" \
		-u "480" \
		"nginx"

WORKDIR "/tmp"

COPY "patches" "patches"

RUN curl -L -f -o "nginx.tar.gz" "https://nginx.org/download/nginx-${PROJ_VERSION}.tar.gz" \
	&& mkdir "nginx" \
	&& tar -x -f "nginx.tar.gz" -C "nginx" --strip-components "1" \
	&& pushd "nginx" \
	&& find "../patches" \
		-mindepth "1" \
		-type "f" \
		-iname "*.patch" \
		-exec bash --noprofile --norc -c "patch -p \"1\" < \"{}\"" ";" \
	&& ./configure \
		--prefix="/usr/local" \
		--sbin-path="/usr/local/sbin/nginx" \
		--modules-path="/usr/local/libexec/nginx" \
		--conf-path="/usr/local/etc/nginx/nginx.conf" \
		--pid-path="/usr/local/var/run/nginx/nginx.pid" \
		--lock-path="/usr/local/var/run/nginx/nginx.lock" \
		--error-log-path="/dev/stderr" \
		--http-log-path="/dev/stdout" \
		--http-client-body-temp-path="/tmp/nginx/client_body" \
		--http-proxy-temp-path="/tmp/nginx/proxy" \
		--http-fastcgi-temp-path="/tmp/nginx/fastcgi" \
		--http-uwsgi-temp-path="/tmp/nginx/uwsgi" \
		--http-scgi-temp-path="/tmp/nginx/scgi" \
		--user="nginx" \
		--group="nginx" \
		--with-perl="$(command -v "perl")" \
		--with-pcre-jit \
		--with-threads \
		--with-file-aio \
		--with-libatomic \
		--with-poll_module \
		--with-select_module \
		--with-http_v2_module \
		--with-http_dav_module \
		--with-http_geoip_module \
		--with-http_mp4_module \
		--with-http_ssl_module \
		--with-http_sub_module \
		--with-http_perl_module \
		--with-http_xslt_module \
		--with-http_geoip_module \
		--with-http_slice_module \
		--with-http_gunzip_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_degradation_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_image_filter_module \
		--with-http_random_index_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_geoip_module \
		--with-stream_realip_module \
		--with-stream_ssl_preread_module \
	&& make \
	&& make "install" \
	&& popd \
	&& rm -r -f "nginx" \
	&& rm "nginx.tar.gz" \
	&& rm -r -f "patches"

WORKDIR "/usr/local"

RUN mkdir -p "etc/nginx" "libexec/nginx" \
	&& folders=("var/lib/nginx" "var/run/nginx" "var/log/nginx") \
	&& for folder in "${folders[@]}"; do \
		mkdir -p "${folder}" \
		&& chmod "700" "${folder}" \
		&& chown -R "480":"480" "${folder}"; \
	done

WORKDIR "/tmp"

RUN mkdir "nginx" \
	&& chmod "700" "nginx" \
	&& chown "480":"480" "nginx"

WORKDIR "/tmp/nginx"

RUN folders=("client_body" "proxy" "fastcgi" "uwsgi" "scgi") \
	&& for folder in "${folders[@]}"; do \
		mkdir "${folder}"; \
	done

WORKDIR "/"

RUN apk del "build-deps"
