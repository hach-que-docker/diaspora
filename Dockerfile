FROM hachque/systemd-none

# Update base image
RUN zypper --non-interactive patch || true
# Update again in case package manager was updated.
RUN zypper --non-interactive patch

# Add user
RUN echo "diaspora:x:4096:4096:user for diaspora:/srv/diaspora:/bin/bash" >> /etc/passwd
RUN echo "diaspora:!:4096:" >> /etc/group

# Install requirements for clone
RUN zypper --non-interactive in git

# Create storage location for diaspora
RUN mkdir /srv/diaspora
RUN chown diaspora:diaspora /srv/diaspora
RUN cd /srv/diaspora

# Clone Diaspora
RUN chown -Rv diaspora:diaspora /srv/diaspora
RUN chmod -Rv u+rwX /srv/diaspora
RUN su diaspora -c "git clone -b master git://github.com/diaspora/diaspora.git /srv/diaspora/diaspora"

# Install requirements
RUN zypper --non-interactive in ruby-devel rubygem-bundler make automake gcc gcc-c++ libcurl-devel ImageMagick ImageMagick-extra libtool bison libtool patch libxml2-devel libxslt-devel libffi-devel libyaml-devel nodejs nginx rubygem-passenger-nginx redis curl git ca-certificates ca-certificates-mozilla ca-certificates-cacert which gdbm-devel libopenssl-devel libdb-4_5 sqlite3-devel libmysqlclient-devel

# Setup REDIS
RUN cp /etc/redis/default.conf.example /etc/redis/default.conf
RUN chown redis: /etc/redis/default.conf

# Trust GPG signatures
RUN su diaspora -c 'gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3'

# Setup RVM
RUN su diaspora -c 'curl -L dspr.tk/1t | bash'
RUN su diaspora -c 'source "$HOME/.rvm/scripts/rvm" && rvm autolibs read-fail'
RUN su diaspora -c 'source "$HOME/.rvm/scripts/rvm" && rvm install 2.1.1'

# Install Ruby libraries
RUN su diaspora -c 'source "$HOME/.rvm/scripts/rvm" && cd /srv/diaspora/diaspora && gem install bundler'
RUN su diaspora -c 'source "$HOME/.rvm/scripts/rvm" && cd /srv/diaspora/diaspora && RAILS_ENV=production DB=mysql bin/bundle install --without test development'

# Update base image
RUN zypper --non-interactive patch || true
RUN zypper --non-interactive patch || true
RUN zypper --non-interactive patch

# Expose port 80 and 443
EXPOSE 80
EXPOSE 443

# Add files
ADD 10-boot-conf /etc/init.simple/10-boot-conf
ADD 20-redis /etc/init.simple/20-redis
ADD 25-nginx /etc/init.simple/25-nginx