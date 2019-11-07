# FROM tokyor/rstudio
FROM rocker/rstudio
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpng-dev libmariadbclient-dev libpq-dev
RUN r -e 'install.packages("png", dependencies = TRUE)' && \
    r -e 'install.packages("dplyr", dependencies = TRUE)' && \
    r -e 'install.packages("stringr", dependencies = TRUE)'
ENV TORIR_HOME=/home/rstudio
WORKDIR $TORIR_HOME
RUN mkdir data
COPY .Rprofile tori.R ./
RUN chown -R rstudio.rstudio $TORIR_HOME
VOLUME $TORIR_HOME/data
CMD ["/init"]
