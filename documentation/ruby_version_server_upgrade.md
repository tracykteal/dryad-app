# Manual Ruby version upgrade on our servers

We do not currently have an automated Ruby version upgrade on our servers.
These instructions are how I did it in our development environment going
from Ruby 2.4 to Ruby 2.6.

## Getting ready

- [ ] Take the server you wish to upgrade out of the ALB rotation.

## Basic Ruby Setup on server

- [ ] Remove old versions of Ruby junk in the local directory
```shell script
cd /dryad/local
mv bin bin-old
```

- [ ] Compile and install the new Ruby version
```shell script
cd ~/install  # or make this directory first if it doesn't exist
wget https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.6.tar.gz
tar -xvf ruby-2.6.6.tar.gz
cd ruby-2.6.6
./configure --prefix=/dryad/local
make
make install
cd ~/install
rm -rf ruby-2.6.6
```

- [ ] Get changes to ruby version by exiting the shell and re-enter it

## Basic Gems

- [ ] Install some basic gems
```shell script
gem update --system
gem install bundler -v 1.17.3
# bundler 2 will refuse to work with Rails 4 sometimes (but not other times).
# You're better off not trying it since it is a mess.
```

## Get Capistrano Working

- [ ] Set environment variables for your environment, change as necessary
```shell script
export MY_BRANCH=master
export RAILS_ENV=development
# the capistrano environment may be things like stage1 and refers to the server
export CAP_ENV=development
```

- [ ] Mess with your releases directory so you can use capistrano with this version of Ruby/Gems
```shell script
cd ~/apps/ui/releases/
git clone --single-branch --branch $MY_BRANCH git@github.com:CDL-Dryad/dryad-app.git temp-cap

# mess with current
cd ~/apps/ui/
unlink current
ln -s /apps/dryad/apps/ui/releases/temp-cap current
cd current
bundle install --deployment
# You may get weird errors saying a gem can't be installed because it's not the default.
# If that happens, try an example such as below to set the gem you need as the default.
# gem install --default -v1.0.1  etc
```

- [ ] Symlink the files, otherwise capistrano task fails, change the deployment host in commands below.
```shell script
bundle exec cap $CAP_ENV deploy:my_linked_files
bundle exec cap $CAP_ENV deploy:symlink:shared
bundle exec cap $CAP_ENV deploy:update_config BRANCH="$MY_BRANCH"
```

## Deploy with Capistrano

- [ ] Now capistrano should be able to deploy, change deploy host below (development there)
```shell script
bundle exec cap $CAP_ENV deploy BRANCH="$MY_BRANCH"
```

- [ ] Watch out for disk filling up.  You can go delete the temp-cap directory you created earlier here. Maybe clean
up some things in ~/install or logs

## Fix the Notifier if it's on this server (the 2a servers)

- [ ] Get latest version of notifier code
```shell script
cd ~/apps
mv stash-notifier stash-notifier-old
cp -avr ~/apps/ui/current/stash/stash-notifier stash-notifier
cp "stash-notifier-old/state/${RAILS_ENV}.json" stash-notifier/state/
cd stash-notifier
bundle install
```

- [ ] Either check or test the stash-notifier to be sure it's working
```shell script
# Either check output for latest runs to be sure it's working
less /dryad/apps/ui/shared/cron/logs/stash-notifier.log
# or run manually run the tool to test
STASH_ENV="$RAILS_ENV" NOTIFIER_OUTPUT=stdout /dryad/apps/stash-notifier/main.rb
```

## Check the disk isn't full
- [ ] for good measure check `df` to see free space and clean something up if needed
- [ ] It doesn't hurt to check the restart scripts in ~/init.d for passenger still working
```shell script
~/init.d/passenger.dryad restart
```

## Wrapping up
- [ ] Things should be working.  If so, put back into ALB rotation.
- [ ] After both deploys, unpause the submission queue or any other typical tasks around deploys.