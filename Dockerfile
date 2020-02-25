FROM rocker/rstudio:3.6

## allow root access to terminal in RStudio
ENV ROOT=TRUE
ENV PASSWORD=password
ENV DISABLE_AUTH=TRUE
ENV TZ=Australia/Brisbane

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libgit2-dev \
    libxml2-dev \
    libcairo2-dev \
    liblapack-dev \
    liblapack3 \
    libopenblas-base \
    libopenblas-dev \
    libpq-dev \
    default-jdk \
    libbz2-dev \
    libicu-dev \
    liblzma-dev \
    libv8-dev \
    openssh-client \
    mdbtools \
    libmagick++-dev \
    libsnappy-dev \
    autoconf \
    automake \
    libtool \
    python-dev \
    pkg-config \
    p7zip-full \
    libzmq3-dev \
    libudunits2-dev \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && rm -rf -- /var/lib/apt/lists /tmp/*.deb

RUN install2.r --error \
    --deps TRUE \
    devtools

## add regularly used packages
RUN install2.r --error \
  scales \
  reshape2 \
  RPostgreSQL \
  Hmisc \
  scales \
  zoo \
  futile.logger \
  drake \
  visNetwork \
  clustermq \
  writexl \
  secret \
  officer \
  flextable \
  xaringan \
  ggthemes \
  extrafont \  
  flexdashboard \
  XLConnect \
  RSQLite \
  fst

## Install tinytex
RUN install2.r --error tinytex \
  ## Admin-based install of TinyTeX:
  && wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr install metafont mfware inconsolata tex ae parskip listings \
  && tlmgr path add \
  && Rscript -e "source('https://install-github.me/yihui/tinytex'); tinytex::r_texmf()" \
  && chown -R root:staff /opt/TinyTeX \
  && chmod -R a+w /opt/TinyTeX \
  && chmod -R a+wx /opt/TinyTeX/bin

## execute R commands to install some packages
RUN install2.r --error \

  && R -e 'remotes::install_github("tidyverse/ggplot2")' \
  && R -e 'remotes::install_github("wilkelab/gridtext")' \
  && R -e 'remotes::install_gitlab("thedatacollective/segmentr")' \
  && R -e 'remotes::install_github("hrbrmstr/hrbrthemes")' \
  && R -e 'remotes::install_github("thedatacollective/tdcthemes")' \
  && R -e 'remotes::install_gitlab("thedatacollective/templatermd")' \
  && R -e 'remotes::install_github("StevenMMortimer/salesforcer")' \
  && R -e 'install.packages("data.table", type = "source", repos = "http://Rdatatable.github.io/data.table")' \
  && rm -rf /tmp/downloaded_packages/ \
  && rm -rf /tmp/*.tar.gz

## add fonts
COPY fonts /usr/share/fonts
COPY user-settings /home/rstudio/.rstudio/monitored/user-settings/

## Update font cache
RUN fc-cache -f -v

## Add /data volume by default
VOLUME /data
VOLUME /home/rstudio/.ssh
