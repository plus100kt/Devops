FROM node:18-alpine as base

FROM base as server-dep
WORKDIR /opt/server
COPY ./server/package*.json ./
RUN npm ci --omit dev
# /opt/server/node_modules - 서버실행시 필요한 dep

FROM base as frontend-dep
WORKDIR /opt/frontend
COPY ./package*.json ./
RUN npm ci --omit dev
# /opt/frontend/node_modules - frontend 빌드에 필요한 dep

FROM base as builder
WORKDIR /opt/frontend
COPY ./public ./public
COPY --from=frontend-dep /opt/frontend/node_modules ./node_modules
COPY ./package.json ./tsconfig.json ./
COPY ./src ./src
RUN npm run build
# /opt/frontend/build - 실행에 필요한 static 파일들이 위치

FROM base as runner
WORKDIR /opt/gdsc

# M1에서 쓰기 까다로워서 TINI 일단은 주석
# RUN apk add --no-cache tini

# install gosu
ENV GOSU_VERSION 1.16
RUN set -eux; \
	\
	apk add --no-cache --virtual .gosu-deps \
		ca-certificates \
		dpkg \
		gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true

RUN adduser --disabled-password gdsc

COPY ./server/index.js \
     ./server/package.json ./
COPY --from=builder /opt/frontend/build/ ./build/
COPY --from=server-dep /opt/server/node_modules ./node_modules

# ENTRYPOINT ["/sbin/tini", "--"]
CMD ["gosu", "gdsc", "node", "index.js"]
