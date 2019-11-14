FROM rockerjp/tidyverse
RUN r -e 'install.packages(c("png", "tuneR"), dependencies = TRUE)'
ENV TORIR_HOME=/home/rstudio
WORKDIR $TORIR_HOME
RUN mkdir data
COPY .Rprofile tori.R ./
RUN chown -R rstudio.rstudio $TORIR_HOME
VOLUME $TORIR_HOME/data
CMD ["/init"]
