# Installing TeSS in a production environment

This page contains some extra notes about setting up TeSS for production on an Ubuntu-like OS.

## System Dependencies

    sudo apt-get install git postgresql libpq-dev imagemagick nodejs openjdk-11-jdk apache2 gnupg2
    
To install a recent version of Redis (6.2+), use the official Redis APT repo:

    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
    
    sudo apt-get update
    sudo apt-get install redis

## Install RVM

Install RVM to manage Ruby versions.

    sudo gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | sudo bash -s stable

The official install guide can be found here: https://rvm.io/rvm/install

## Install Passenger

Install PGP key:

    sudo apt-get install -y dirmngr gnupg
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
    sudo apt-get install -y apt-transport-https ca-certificates

Add apt repository:

    sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main > /etc/apt/sources.list.d/passenger.list'
    sudo apt-get update

Install Apache module:

    sudo apt-get install -y libapache2-mod-passenger

Enable the module:

    sudo a2enmod passenger
    sudo apache2ctl restart

Check everything worked:

    sudo /usr/bin/passenger-config validate-install

The official install guide can be found here: https://www.phusionpassenger.com/library/install/apache/install/oss/bionic/

## Create user

First create a user to own the TeSS application:

    sudo useradd -m tess

Ensure the user is in the `rvm` group:

    sudo usermod -aG rvm tess

## Check out TeSS

Switch over to the `tess` user:

    sudo su - tess

and clone the TeSS repo (for this guide we will put it in the `tess` user's home directory `/home/tess/TeSS`).

    git clone https://github.com/ElixirTeSS/TeSS.git

## Install Ruby

Enter the TeSS directory we just cloned, and install TeSS' current version (3.2.2 at time of writing) of Ruby via RVM:

    cd TeSS

    rvm install `cat .ruby-version`

## Set up an RVM alias

To make switching Ruby versions easier in the future, you should create an "alias" using RVM.

Create one named `tess` with the current supported Ruby version for TeSS.

    rvm alias create tess `cat .ruby-version`

In the future, you can re-run this command with a different Ruby version to switch the version used by TeSS, without
having to change any configuration files.

## Install gems

    bundle install --deployment

## Set up database

Switch over to the `postgres` user:

    sudo su - postgres

Create a postgres user to own the database:

    createuser tess_user

Open up the postgres console:

    psql

In the postgres console, set a password for the user:

    postgres=# \password tess_user

...and grant it a privilege to create databases:_

    postgres=# ALTER USER tess_user CREATEDB;

## Install Solr

TeSS uses Apache Solr to power its search and filtering system.

Double check you are using Java 11:

    java -version

If not, you can switch using the following command:

    sudo update-alternatives --config java

Run the following commands to download and install solr into /opt/, and have it run as a service that will start on boot.

    cd /opt
    sudo wget https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz
    sudo tar xzf solr-8.11.2.tgz solr-8.11.2/bin/install_solr_service.sh --strip-components=2
    sudo bash ./install_solr_service.sh solr-8.11.2.tgz

### Starting/stopping solr

Make sure solr is started using:

    sudo service solr start

If you need to stop it for whatever reason, run:

    sudo service solr stop

By default, solr should be running at localhost:8983

### Create a solr "collection"

Next, create a collection for TeSS to use (assuming TeSS is checked out at `/home/tess/TeSS`):

    sudo su - solr -c "/opt/solr/bin/solr create -c tess_production -d /home/tess/TeSS/solr/conf"

`tess_production` here is the collection name, which should match what is configured in your `config/sunspot.yml`
under the `path` parameter, following `/solr/`.

## Configure TeSS

Switch back to the `tess` user.

From the app's root directory, create several config files by copying the example files.

    cp config/tess.example.yml config/tess.yml
    cp config/sunspot.example.yml config/sunspot.yml
    cp config/secrets.example.yml config/secrets.yml
    cp config/ingestion.example.yml config/ingestion.yml

Edit config/secrets.yml to configure the database user and password defined above.

Edit config/secrets.yml to configure the app's secret_key_base which you can generate with:

    bundle exec rake secret

Create the databases:

    RAILS_ENV=production bundle exec rake db:create

Create the database structure and load in seed data:

_Note: Ensure you have started Solr before running this command!_

    RAILS_ENV=production bundle exec rake db:setup

## Compile assets

Assets - such as images, javascript and stylesheets, need to be precompiled -
which means minifying them, grouping some together into a single file, and
compressing. These then get placed into *public/assets*. To compile them run
the following command. This can take some time, so be patient

    bundle exec rake assets:precompile

## Configure Apache

Switch back to a user with `sudo` access.

Now create an Apache virtual host definition for TeSS:

    sudo nano /etc/apache2/sites-available/tess.conf

which looks like (if you have registered a DNS for your site, then set
ServerName appropriately):

    <VirtualHost *:80>
        ServerName www.yourhost.com
        
        PassengerPreloadBundler on
        PassengerRuby /usr/local/rvm/rubies/tess/bin/ruby
        
        DocumentRoot /home/tess/TeSS/public
        <Directory /home/tess/TeSS/public>
            # This relaxes Apache security settings.
            Allow from all
            # MultiViews must be turned off.
            Options -MultiViews
            Require all granted
        </Directory>
        <LocationMatch "^/assets/.*$">
            Header unset ETag
            FileETag None
            # RFC says only cache for 1 year
            ExpiresActive On
            ExpiresDefault "access plus 1 year"
        </LocationMatch>
    </VirtualHost>

(Notice we are referencing our "tess" RVM alias in the `PassengerRuby` directive.)

The LocationMatch block tells Apache to serve up the assets (images, CSS,
Javascript) with a long expiry time, leading to better performance since these
items will be cached. You may need to enable the *headers* and *expires*
modules for Apache, so run:

    sudo a2enmod headers
    sudo a2enmod expires

Now enable the TeSS site, and disable the default that is installed with
Apache, and restart:

    sudo a2ensite tess
    sudo a2dissite 000-default
    sudo service apache2 restart

If you wish to restart TeSS, maybe after an upgrade, without restarting Apache
you can do so by running (as the `tess` user)

    touch /home/tess/TeSS/tmp/restart.txt

### Configuring for HTTPS

We would strongly recommend using [Lets Encrypt](https://letsencrypt.org/) for free SSL certificates.

Certbot is a commandline tool can be used to request an SSL certificate and automatically configure Apache.
[See this guide for more information](https://certbot.eff.org/instructions?ws=apache&os=ubuntufocal).

## Configure Sidekiq

Sidekiq, which runs asynchronous tasks in TeSS, needs to be configured to run as a service. 
Examples of Systemd and Upstart service configurations are provided under `config/sidekiq/`. 
In this example we will use Systemd.

Run the following commands as your TeSS application user (e.g. `tess`).

Copy the example config file to the user's systemd directory: 

    mkdir -p ~/.config/systemd/user
    cp config/sidekiq/systemd/sidekiq.service.example ~/.config/systemd/user/sidekiq.service

Then open it in your editor and change the `WorkingDirectory` field to your TeSS install directory, and the `ExecStart`
field if you are using a different RVM alias than what is suggested in this guide.

In order to run systemctl via `su`, you may need to add the following env vars. To add them to your `.bash_profile` so 
they are set on login, use the following commands:

    touch .bash_profile
    echo 'export XDG_RUNTIME_DIR="/run/user/$UID"' >> .bash_profile
    echo 'export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"' >> .bash_profile

and then restart your SSH/su session.

You should then be able to enable the Sidekiq service (as the `tess` user):

    systemctl --user daemon-reload
    systemctl --user enable sidekiq.service

If this doesn't work, you may need to first enable "linger" on the `tess` user, as a sudoer:

    sudo loginctl enable-linger tess

You can then start/stop/restart Sidekiq using the following:

    systemctl --user {start,stop,restart} sidekiq
