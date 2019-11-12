# FROM tokyor/rstudio
FROM rocker/rstudio
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpng-dev libmariadbclient-dev libpq-dev
RUN r -e 'install.packages("png", dependencies = TRUE)' && \
    r -e 'install.packages("dplyr", dependencies = TRUE)' && \
    r -e 'install.packages("stringr", dependencies = TRUE)'
RUN r -e 'install.packages("tuneR", dependencies = TRUE)'
RUN r -e 'install.packages("extrafont", dependencies = TRUE)'
RUN apt-get install -y fonts-ipaexfont
# RUN apt-get install -y texlive-font-utils
ENV TORIR_HOME=/home/rstudio
WORKDIR $TORIR_HOME
RUN mkdir data
COPY .Rprofile tori.R ./
RUN chown -R rstudio.rstudio $TORIR_HOME
VOLUME $TORIR_HOME/data
CMD ["/init"]
