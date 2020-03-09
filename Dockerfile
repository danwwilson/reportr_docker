FROM rocker/rstudio:latest

## allow root access to terminal in RStudio
ENV ROOT=TRUE
ENV PASSWORD=password
ENV DISABLE_AUTH=TRUE
ENV TZ=Australia/Brisbane

ARG CTAN_REPO=${CTAN_REPO:-http://www.texlive.info/tlnet-archive/2017/04/13/tlnet}
ENV CTAN_REPO=${CTAN_REPO}

ENV PATH=$PATH:/opt/TinyTeX/bin/x86_64-linux/

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
  readxl \
  writexl \
  RSQLite \
  fst

## Install tinytex
RUN install2.r --error tinytex \
  ## Admin-based install of TinyTeX:
  && wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && if /opt/TinyTeX/bin/*/tex -v | grep -q 'TeX Live 2018'; then \
      ## Patch the Perl modules in the frozen TeX Live 2018 snapshot with the newer
      ## version available for the installer in tlnet/tlpkg/TeXLive, to include the
      ## fix described in https://github.com/yihui/tinytex/issues/77#issuecomment-466584510
      ## as discussed in https://www.preining.info/blog/2019/09/tex-services-at-texlive-info/#comments
      wget -P /tmp/ ${CTAN_REPO}/install-tl-unx.tar.gz \
      && tar -xzf /tmp/install-tl-unx.tar.gz -C /tmp/ \
      && cp -Tr /tmp/install-tl-*/tlpkg/TeXLive /opt/TinyTeX/tlpkg/TeXLive \
      && rm -r /tmp/install-tl-*; \
    fi \
  && if /opt/TinyTeX/bin/*/tex -v | grep -q 'TeX Live 2016'; then \
      ## Patch error handling of tlmgr path (https://tex.stackexchange.com/a/314079)
      ## in the frozen TeX Live 2016 snapshot by back-porting the corresponding fix:
      ## https://git.texlive.info/texlive/commit/Master/tlpkg/TeXLive/TLUtils.pm?id=69cee5e1ce4b20f6ebb6af77e19d49706a842a3e
      apt-get update && apt-get install -y --no-install-recommends patch \
      && wget -qO- \
         "https://git.texlive.info/texlive/patch/Master/tlpkg/TeXLive/TLUtils.pm?id=69cee5e1ce4b20f6ebb6af77e19d49706a842a3e" | \
         patch -i - /opt/TinyTeX/tlpkg/TeXLive/TLUtils.pm \
      && apt-get remove --purge --autoremove -y patch \
      && apt-get clean && rm -rf /var/lib/apt/lists/; \
    fi \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr install ae inconsolata listings metafont mfware parskip pdfcrop tex \
  && tlmgr path add \
  && Rscript -e "tinytex::r_texmf()" \
  && chown -R root:staff /opt/TinyTeX \
  && chmod -R g+w /opt/TinyTeX \
  && chmod -R g+wx /opt/TinyTeX/bin \
  && echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

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
