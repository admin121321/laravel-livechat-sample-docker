# 2022 update
FROM php:8.2-fpm

# setup user as root
USER root

WORKDIR /var/www

# setup node js source will be used later to install node js
RUN curl -sL https://deb.nodesource.com/setup_21.x -o nodesource_setup.sh
RUN ["sh",  "./nodesource_setup.sh"]

# Install environment dependencies
# PS. you can deploy an image that stops at this step so that your cI/CD builds are a bit faster (if not cached) this is what takes the most time in the deployment process.
RUN apt-get update \
    # gd
    && apt-get install -y build-essential  openssl nginx libfreetype6-dev libjpeg-dev libpng-dev libwebp-dev zlib1g-dev libzip-dev gcc g++ make vim unzip curl git jpegoptim optipng pngquant gifsicle locales libonig-dev nodejs  \
    && docker-php-ext-configure gd  \
    && docker-php-ext-install gd \
    # gmp
    && apt-get install -y --no-install-recommends libgmp-dev \
    && docker-php-ext-install gmp \
    # pdo_mysql
    && docker-php-ext-install pdo_mysql mbstring \
    # pdo
    && docker-php-ext-install pdo \
    # opcache
    && docker-php-ext-enable opcache \
    # exif
    && docker-php-ext-install exif \
    && docker-php-ext-install sockets \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install bcmath \
    # zip
    && docker-php-ext-install zip \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear/

# Copy files
COPY . /var/www/

COPY ./nginx/php.ini /usr/local/etc/php/local.ini

COPY ./nginx/conf.d/app.conf /etc/nginx/nginx.conf
    
RUN chown -R www-data:www-data /var/www/

#RUN chown -R www-data:www-data /var/www/storage

#RUN chown -R www-data:www-data /var/www/bootstrap/cache

RUN chmod +rwx /var/www/

RUN chmod -R 777 /var/www/

# setup FE
#RUN npm cache clean --force

RUN npm install --cache /path/to/cache

RUN npm rebuild node-sass

RUN npm run build

# setup composer and laravel
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#RUN composer install --working-dir="/var/www"
RUN composer install --no-interaction --no-scripts --no-progress --no-dev --optimize-autoloader

#RUN composer dump-autoload --working-dir="/var/www"

#RUN composer update

RUN composer self-update

RUN composer clear-cache

#RUN php artisan route:clear

#RUN php artisan route:cache

#RUN php artisan config:clear

#RUN php artisan config:cache

#RUN php artisan view:clear

#RUN php artisan view:cache

#RUN php artisan optimize
# remove this line if you do not want to run migrations on each build
#RUN php artisan migrate --force

EXPOSE 9000

RUN ["chmod", "+x", "post_deploy.sh"]

CMD [ "sh", "post_deploy.sh" ]
# CMD php artisan serve --host=127.0.0.1 --port=9000
