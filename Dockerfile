FROM r-base:latest

MAINTAINER Winston Chang "winston@rstudio.com"

# Install dependencies and Download and install shiny server
RUN apt-get update && apt-get install -y -t unstable \
    sudo \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev/unstable \
    libxt-dev \
    libssl-dev && \
    wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')" && \
    cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/ && \
    rm -rf /var/lib/apt/lists/*

## additional system packages to support ODBC connection to dashDB
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	libxml2 \
    libxml2-dev \
	mksh \
	procps \
	ssh \
	unixodbc-dev \
	&& apt-get clean

## copy our database drivers
COPY drivers/* /

## install data server drivers
RUN echo $SHELL
RUN echo $TERM
ENV TERM dumb
RUN tar -xvzf ibm_data_server_driver_package_linuxx64_v11.1.tar.gz \
	&& dsdriver/installDSDriver \
	&& printf "[DASHDB]\nDriver = /dsdriver/lib/libdb2o.so\n" >> etc/odbc.ini
RUN cp dsdriver/lib/libdb2.so.1 /lib/x86_64-linux-gnu \
	&& cp -r dsdriver/lib/* dsdriver/bin/ \
    && cp -r dsdriver/lib/* /usr/local/lib/
RUN dsdriver/bin/db2cli writecfg add -database BLUDB -host dash-db-hostname.services.dal.bluemix.net -port 50000 \
	&& dsdriver/bin/db2cli writecfg add -dsn dashdb -database BLUDB -host dash-db-hostname.services.dal.bluemix.net -port 50000

## install additional packages required for this app
RUN R -e "install.packages('httr', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('datasets', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('ibmdbR', repos='http://cran.rstudio.com/')"

## copy our application to the docker image
RUN mkdir -p /srv/shiny-server/app; sync
RUN mkdir -p /srv/shiny-server/app/www; sync
COPY app/www/* /srv/shiny-server/app/www/
COPY app/* /srv/shiny-server/app/


#volume for Shiny Apps and static assets. Here is the folder for index.html(link) and sample apps.
VOLUME /srv/shiny-server

## add user account for Shiny
RUN adduser shiny sudo
RUN chown -R shiny /var/log/shiny-server \
    && sed -i '113 a <h2><a href="./examples/">Other examples of Shiny application</a> </h2>' /srv/shiny-server/index.html

EXPOSE 3838

COPY shiny-server.sh /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]
