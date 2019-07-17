release:
	mkdir -p tmp
	# Temporarily backup the original files to inject version string
	cp chief/main.go tmp/chief-main.go
	cp builder/main.go tmp/builder-main.go
	cp repo/main.go tmp/repo-main.go
	cp cli/main.go tmp/cli-main.go
	cat tmp/chief-main.go | sed "s/IRGSH_GO_VERSION/$$(cat VERSION)/g" > chief/main.go
	cat tmp/builder-main.go | sed "s/IRGSH_GO_VERSION/$$(cat VERSION)/g" > builder/main.go
	cat tmp/repo-main.go | sed "s/IRGSH_GO_VERSION/$$(cat VERSION)/g" > repo/main.go
	cat tmp/cli-main.go | sed "s/IRGSH_GO_VERSION/$$(cat VERSION)/g" > cli/main.go
	# Build
	make build
	# Bundling
	mkdir -p irgsh-go/usr/bin
	mkdir -p irgsh-go/etc/irgsh
	mkdir -p irgsh-go/etc/init.d
	mkdir -p irgsh-go/usr/share/irgsh
	cp bin/* irgsh-go/usr/bin/
	cp utils/config.yml irgsh-go/etc/irgsh/
	cp utils/init/* irgsh-go/etc/init.d/
	cp -R utils/reprepro-template irgsh-go/usr/share/irgsh/reprepro-template
	tar -zcvf release.tar.gz irgsh-go
	mkdir -p target
	mv release.tar.gz target/
	# It's possible this release command will be used inside a container
	# Let it rewriteable for host environment
	chmod -vR a+rw target
	chown -vR :users target
	# Clean up
	rm -rf irgsh-go
	cp tmp/chief-main.go chief/main.go
	cp tmp/builder-main.go builder/main.go
	cp tmp/repo-main.go repo/main.go
	cp tmp/cli-main.go cli/main.go

preinstall:
	sudo killall irgsh-chief || true
	sudo killall irgsh-builder || true
	sudo killall irgsh-repo || true

build-in-docker:
	docker build --no-cache -t irgsh-build .
	docker run -v $(pwd)/target:/tmp/src/target irgsh-build make release

build:
	mkdir -p bin
	cp chief/utils.go builder/utils.go
	cp chief/utils.go repo/utils.go
	cp chief/utils.go cli/utils.go
	go build -o ./bin/irgsh-chief ./chief
	go build -o ./bin/irgsh-builder ./builder
	go build -o ./bin/irgsh-repo ./repo
	go build -o ./bin/irgsh-cli ./cli
	rm builder/utils.go
	rm repo/utils.go

build-install: preinstall build
	sudo cp ./bin/irgsh-chief /usr/bin/irgsh-chief
	sudo cp ./bin/irgsh-builder /usr/bin/irgsh-builder
	sudo cp ./bin/irgsh-repo /usr/bin/irgsh-repo
	sudo cp ./bin/irgsh-cli /usr/bin/irgsh-cli

test:
	mkdir -p tmp
	cp chief/utils.go builder/utils.go
	cp chief/utils.go repo/utils.go
	go test -race -coverprofile=coverage.txt -covermode=atomic ./builder
	go test -race -coverprofile=coverage.txt -covermode=atomic ./repo

coverage:test
	go tool cover -html=coverage.txt

irgsh-chief:
	go build -o ./bin/irgsh-chief ./chief && ./bin/irgsh-chief

irgsh-builder-init:
	go build -o ./bin/irgsh-builder ./builder && ./bin/irgsh-builder init

irgsh-builder:
	go build -o ./bin/irgsh-builder ./builder && ./bin/irgsh-builder

irgsh-repo-init:
	go build -o ./bin/irgsh-repo ./repo && ./bin/irgsh-repo init

irgsh-repo:
	go build -o ./bin/irgsh-repo ./repo && ./bin/irgsh-repo

redis:
	docker run -d --network host redis

submit:
	curl --header "Content-Type: application/json" --request POST --data '{"sourceUrl":"https://github.com/BlankOn/bromo-theme.git","packageUrl":"https://github.com/BlankOn-packages/bromo-theme.git"}' http://localhost:8080/api/v1/submit
