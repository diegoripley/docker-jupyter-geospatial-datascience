FROM jupyter/minimal-notebook

USER root

RUN apt-get update -y \
    && apt-get -y install gcc make gnupg2 curl autoconf automake libtool pkg-config wget

# Bash Kernel
RUN pip install bash_kernel \
	&& python -m bash_kernel.install

# Utilities
RUN apt-get install -y neovim \
                       python3-neovim \
                       htop \
                       fish \
                       tmux \
                       git \
                       aria2

# Geospatial
RUN mamba install -y -c conda-forge geospatial libgdal-arrow-parquet  geoserver-rest

# Scraping
# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get -y update \
    && apt-get install -y google-chrome-stable

# Install chromedriver
RUN apt-get install -yqq unzip \
    && wget -O /tmp/chromedriver.zip http://chromedriver.storage.googleapis.com/`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`/chromedriver_linux64.zip \
    && unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/

RUN mamba install -y -c conda-forge scrapy \
                                 requests \
                                 bs4

# Jupyter extensions
RUN mamba install -y -c conda-forge jupyter_contrib_nbextensions \
                                    jupyter_dashboards \
    && pip install autopep8

# Download libpostal model
RUN wget https://www.diegoripley.ca/files/libpostal/libpostal_data_sept_3_2018.tar.gz \
    && tar xf libpostal_data_sept_3_2018.tar.gz \
    && mkdir -p /data/libpostal \
    && mv data/* /data/libpostal \
    && rm data -rf \
    && rm libpostal_data_sept_3_2018.tar.gz

# Libpostal
RUN git clone https://github.com/openvenues/libpostal /libpostal \
          && cd /libpostal/ \
          && ./bootstrap.sh \
          && ./configure --disable-data-download --datadir=/data/ \
          && make -j8 \
          && sudo make install \
          && sudo ldconfig

# Python libpostal package
RUN pip install postal

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && conda clean --all -y

#USER $NB_UID

WORKDIR /home/jovyan/

#ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["jupyter", "notebook", "--allow-root"]
