FROM php:$VERSION
MAINTAINER Mark Shust <mark.shust@mageinferno.com>

RUN apt-get update \
  && apt-get install -y \
    cron \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev

RUN docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
  bcmath \
  gd \
  intl \
  mbstring \
  mcrypt \
  pdo_mysql \
  soap \
  xsl \
  zip

RUN curl -sS https://getcomposer.org/installer | \
  php -- --install-dir=/usr/local/bin --filename=composer

ENV PHP_MEMORY_LIMIT 2G
ENV PHP_PORT 9000
ENV PHP_PM dynamic
ENV PHP_PM_MAX_CHILDREN 10
ENV PHP_PM_START_SERVERS 4
ENV PHP_PM_MIN_SPARE_SERVERS 2
ENV PHP_PM_MAX_SPARE_SERVERS 6
ENV APP_MAGE_MODE default

COPY conf/www.conf /usr/local/etc/php-fpm.d/
COPY conf/php.ini /usr/local/etc/php/
COPY conf/php-fpm.conf /usr/local/etc/
COPY bin/* /usr/local/bin/

WORKDIR /var/www/html



# Run setup script
RUN php /var/www/html/bin/magento setup:install --base-url=http://il0a-cms-docker1/ \
--db-host=54.146.189.180 --db-name=magento --db-user=root --db-password=Gigya123 \
--admin-firstname=Magento --admin-lastname=User --admin-email=dor.av@gigya-inc.com --backend-frontname=admin \
--admin-user=admin --admin-password=Gigya123 --language=en_US \
--currency=USD --timezone=America/Chicago --cleanup-database \
--sales-order-increment-prefix="ORD$" --session-save=db --use-rewrites=1

#Get permissions
RUN chmod -Rf 777 /var/www/html

#set developer mode
RUN php /var/www/html/bin/magento deploy:mode:set developer

COPY ./composer.json /var/www/html/
COPY ./key.txt /var/www/html/

#Get permissions
RUN chmod -Rf 777 /var/www/html

CMD ["/usr/local/bin/start"]


