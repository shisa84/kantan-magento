##@ VARS
TRAEFIK_DOMAIN=`cat .env | grep TRAEFIK_DOMAIN | cut -d = -f 2`
DOCKER_ENV_NAME=`cat .env | grep ENV_NAME | cut -d = -f 2`
MYSQL_ROOT_PASSWORD=`cat .env | grep MYSQL_ROOT_PASSWORD | cut -d = -f 2`
MYSQL_DATABASE=`cat .env | grep MYSQL_DATABASE | cut -d = -f 2`
MYSQL_USER=`cat .env | grep MYSQL_USER | cut -d = -f 2`
MYSQL_PASSWORD=`cat .env | grep MYSQL_PASSWORD | cut -d = -f 2`

##@ DB
db-import:
	cat dump.sql.gz | gunzip -c | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | docker exec -i $(DOCKER_ENV_NAME)-db-1 mysql -uroot -p$(MYSQL_ROOT_PASSWORD) --database=$(MYSQL_DATABASE)

db-connect:
	docker exec -it $(DOCKER_ENV_NAME)-db-1 mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) --database=$(MYSQL_DATABASE)

db-export:
	docker exec -i $(DOCKER_ENV_NAME)-db-1 mysqldump -uroot -p$(MYSQL_ROOT_PASSWORD) $(MYSQL_DATABASE) | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip -c > $(DOCKER_ENV_NAME)_`date "+%Y%m%d%H%M%S"`.sql.gz

db-reset:
	docker exec $(DOCKER_ENV_NAME)-db-1 bash -c "mysql -u$(MYSQL_USER) -p$(MYSQL_PASSWORD) -e 'DROP DATABASE IF EXISTS $(MYSQL_DATABASE); CREATE DATABASE $(MYSQL_DATABASE);'"

db-reimport: db-reset db-import


##@ local env
env-install-docker: cert env-up generated-flush preprocessed-flush static-flush composer-vendor-flush

env-install-magento: composer-install patches-apply db-import setup-upgrade-no-interaction cache-flush-all

env-install: env-install-docker env-install-magento

env-reinstall-hard: db-reset env-down-all env-install

##@ warden
env-up:
	warden env up

env-down:
	warden env down

env-down-all:
	warden env down -v

env-start:
	warden env start

env-stop:
	warden env stop

svc-up:
	warden svc up

svc-down:
	warden svc down

svc-start:
	warden svc start

svc-stop:
	warden svc stop

cert:
	warden sign-certificate $(TRAEFIK_DOMAIN)



##@ composer
composer-install:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 composer install

composer-clear-cache:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 composer clear-cache

composer-vendor-flush:
	rm -rf vendor/*


##@ quality-patches
patches-cmd:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 ./vendor/bin/ece-patches $(ACTION)

patches-apply:
	 @make patches-cmd ACTION=apply

patches-revert:
	@make patches-cmd ACTION=revert

patches-status:
	@make patches-cmd ACTION=status


##@ cache
cache-clean:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento cache:clean

cache-flush:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento cache:flush

redis-flush:
	docker exec $(DOCKER_ENV_NAME)-redis-1 redis-cli FLUSHALL

varnish-flush:
	docker exec $(DOCKER_ENV_NAME)-varnish-1 varnishadm ban req.url '~' '.' || true

generated-flush:
	rm -rf generated/*

preprocessed-flush:
	rm -rf var/view_preprocessed/*

static-flush:
	 rm -rf pub/static/*

cache-flush-all: redis-flush cache-flush varnish-flush generated-flush preprocessed-flush static-flush

##@ setup
di-compile:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento setup:di:compile

setup-upgrade:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento setup:upgrade

setup-upgrade-no-interaction:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento setup:upgrade --no-interaction

deploy-static:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento setup:static-content:deploy -f

app-config-import:
	docker exec $(DOCKER_ENV_NAME)-php-fpm-1 bin/magento app:config:import

