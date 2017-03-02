FROM doravidan/apache2-php5.6

RUN a2enmod rewrite

ENV MAGENTO_VERSION 2.0.9

RUN rm -rf /var/www/html/*
RUN mkdir /var/www/html
RUN cd /tmp && curl https://codeload.github.com/magento/magento2/tar.gz/$MAGENTO_VERSION -o $MAGENTO_VERSION.tar.gz && tar xvf $MAGENTO_VERSION.tar.gz && mv magento2-$MAGENTO_VERSION/* magento2-$MAGENTO_VERSION/.htaccess /var/www/html

RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Make ssh dir
RUN mkdir -p /root/.ssh
RUN chown -R root:root /root/.ssh
RUN chmod 700 /root/.ssh

# Create known_hosts
RUN touch /root/.ssh/known_hosts
# Add github key
RUN ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts

COPY ./auth.json /var/www/.composer/
RUN chsh -s /bin/bash www-data
RUN chown -R www-data:www-data /var/www
RUN su www-data -c "cd /var/www/html && composer install"
RUN cd /var/www/html \
    && find . -type d -exec chmod 770 {} \; \
    && find . -type f -exec chmod 660 {} \; \
    && chmod u+x bin/magento

COPY ./bin/install-magento /usr/local/bin/install-magento
RUN chmod +x /usr/local/bin/install-magento

COPY ./bin/install-sampledata /usr/local/bin/install-sampledata
RUN chmod +x /usr/local/bin/install-sampledata

RUN echo "memory_limit=1024M" > /usr/local/etc/php/conf.d/memory-limit.ini

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html

VOLUME /var/www/html/var
VOLUME /var/www/html/pub

# Add cron job
ADD crontab /etc/cron.d/magento2-cron
RUN chmod 0644 /etc/cron.d/magento2-cron
RUN crontab -u www-data /etc/cron.d/magento2-cron

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




