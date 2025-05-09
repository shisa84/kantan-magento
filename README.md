# kantan-magento

### How to install
<details>
<summary>Kantan install</summary>

#### Install
```
warden svc up
cp .env.local .env
cp app/etc/env.php.local app/etc/env.php
cp app/etc/config.php.local app/etc/config.php
make env-init
```

#### Reinstall
```
warden svc up
warden env up
make env-reinstall-hard
```

</details>

<details>
<summary>Install from scratch</summary>

```
warden svc up
```
Make sure there is no `app/etc/env.php` and `app/etc/config.php` files before to install Magento 
```
cp .env.local .env
warden sign-certificate kantan-magento.test
warden env up
warden shell

composer install

bin/magento setup:install \
--backend-frontname=admin \
--amqp-host=rabbitmq \
--amqp-port=5672 \
--amqp-user=guest \
--amqp-password=guest \
--db-host=db \
--db-name=magento \
--db-user=magento \
--db-password=magento \
--language=ja_JP \
--currency=JPY \
--timezone=Asia/Tokyo \
--search-engine=opensearch \
--opensearch-host=opensearch \
--opensearch-port=9200 \
--opensearch-index-prefix=magento2 \
--opensearch-enable-auth=0 \
--opensearch-timeout=15 \
--http-cache-hosts=varnish:80 \
--session-save=redis \
--session-save-redis-host=redis \
--session-save-redis-port=6379 \
--session-save-redis-db=2 \
--session-save-redis-max-concurrency=20 \
--cache-backend=redis \
--cache-backend-redis-server=redis \
--cache-backend-redis-db=0 \
--cache-backend-redis-port=6379 \
--page-cache=redis \
--page-cache-redis-server=redis \
--page-cache-redis-db=1 \
--page-cache-redis-port=6379
```

More detail on https://experienceleague.adobe.com/ja/docs/commerce-operations/installation-guide/advanced

```
bin/magento config:set --lock-env web/seo/use_rewrites 1
bin/magento config:set --lock-env web/unsecure/base_url "https://kantan-magento.test/"
bin/magento config:set --lock-env web/secure/base_url "https://kantan-magento.test/"
bin/magento deploy:mode:set -s developer
```

Depending to your OS/setup, you may get the dns error when you try to access
DNS_PROBE_FINISHED_NXDOMAIN

Edit the hosts file
```
127.0.0.1 kantan-magento.test
```

Access to the admin interface https://kantan-magento.test/admin
```
bin/magento admin:user:create
```

disable Two-Factor Authorization
```
bin/magento module:disable Magento_TwoFactorAuth Magento_AdminAdobeImsTwoFactorAuth
bin/magento setup:upgrade
```

Install japanese language pack
```
composer require mageplaza/magento-2-japanese-language-pack:dev-master
bin/magento setup:upgrade
```
</details>


### How to clear docker volumes
```
make db-reset env-down-all
```
