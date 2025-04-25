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

