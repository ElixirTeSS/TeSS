# Installing TeSS in a production environment

This page contains some extra notes about setting up TeSS for production on an Ubuntu-like OS.

## System Dependencies

    sudo apt-get install git postgresql libpq-dev imagemagick nodejs redis-server openjdk-11-jdk apache2 gnupg2

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

Enter the TeSS directory we just cloned, and install TeSS' current version (3.0.4 at time of writing) of Ruby via RVM:

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

## Compile assets

Assets - such as images, javascript and stylesheets, need to be precompiled -
which means minifying them, grouping some together into a single file, and
compressing. These then get placed into *public/assets*. To compile them run
the following command. This can take some time, so be patient

    bundle exec rake assets:precompile

#### Apache configuration

Switch back to a user with `sudo` access.

Now create an Apache virtual host definition for TeSS:

    sudo nano /etc/apache2/sites-available/tess.conf

which looks like (if you have registered a DNS for your site, then set
ServerName appropriately):

    <VirtualHost *:80>
        ServerName www.yourhost.com
        
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

### Setting up the services

The following steps show how to setup delayed_job and
soffice to run as a service, and automatically start and shutdown when you
restart the server. Apache Solr should already be setup from following the [Setting up Solr](setting-up-solr) instructions.

## Solr

TeSS uses Apache Solr to power its search and filtering system.

Double check you are using Java 11:

    java -version

If not, you can switch using the following command:

    sudo update-alternatives --config java

### Install

Run the following commands to download and install solr into /opt/, and have it run as a "service" that will start on boot.

    cd /opt
    sudo wget https://downloads.apache.org/lucene/solr/8.11.1/solr-8.11.1.tgz
    sudo tar xzf solr-8.11.1.tgz solr-8.11.1/bin/install_solr_service.sh --strip-components=2
    sudo bash ./install_solr_service.sh solr-8.11.1.tgz

### Starting/stopping solr

Make sure solr is started using:

    sudo service solr start

If you need to stop it for whatever reason, run:

    sudo service solr stop

By default, solr should be running at localhost:8983

### Create a "collection"

Next, create a collection for TeSS to use (assuming TeSS is checked out at `/home/tess/TeSS`):

    sudo su - solr -c "/opt/solr/bin/solr create -c tess_prod -d /home/tess/TeSS/solr/conf"

`tess_prod` here is the collection name, which should match what is configured in your `config/sunspot.yml`.
