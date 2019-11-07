# FROM tokyor/rstudio
FROM rocker/rstudio
RUN apt update && \
    apt install -y --no-install-recommends libpng-dev libmariadbclient-dev libpq-dev
RUN r -e 'install.packages("png", dependencies = TRUE)' && \
    r -e 'install.packages("dplyr", dependencies = TRUE)' && \
    r -e 'install.packages("stringr", dependencies = TRUE)'
ENV RSTUDIO_HOME=/home/rstudio
WORKDIR $RSTUDIO_HOME
VOLUME $RSTUDIO_HOME/data
COPY .Rprofile tori.R ./
CMD ["/init"]
