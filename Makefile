TZ=$(shell timedatectl | grep 'Time zone:' | tr -s ' ' | cut -d ' ' -f 4)
TAG=freeswitch-linesip
NAME=freeswitch

build:
	docker build --build-arg TZ=$(TZ) -t $(TAG) .

build-mysql:
	docker build --build-arg TZ=$(TZ) --build-arg use_mariadb=true -t $(TAG):mysql .

build-postgre:
	docker build --build-arg TZ=$(TZ) --build-arg use_postgre=true -t $(TAG):pg .

build-db:
	docker build --build-arg TZ=$(TZ) --build-arg use_mariadb=true --build-arg use_postgre=true -t $(TAG):db .

clean-container:
	@echo "stopping container $(NAME)"
	@docker container stop $(NAME) 2> /dev/null && echo "✓" || echo "✘"
	@echo "deleting container $(NAME)"
	@docker container rm $(NAME) 2>/dev/null && echo "✓" || echo "✘"

clean-image:
	@echo "deleting image $(TAG)"
	@docker image rm "$(TAG)" 2>/dev/null && echo "✓" || echo "✘"
	@echo "deleting bad images"
	@docker image rm $(shell docker image ls -a | grep none | tr -s ' ' | cut -d ' ' -f 3) && echo "✓" || echo "✘"

clean-all: clean-container clean-image
	@echo "done"

run-background:
	docker run -d -t --name $(NAME) $(TAG)

run:
	docker run -t --name $(NAME) $(TAG)

bash:
	docker exec -i -t $(NAME) /bin/bash

fs_cli:
	docker exec -i -t $(NAME) /usr/bin/fs_cli -R -U -i --host=127.0.0.1 --password=ClueCon
