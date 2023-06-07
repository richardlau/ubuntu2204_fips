FROM ubuntu:22.04

ARG GID 1000
ARG UID 1000

ENV CCACHE_TEMPDIR /home/iojs/.ccache/
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /home/iojs
ENV LC_ALL C
ENV NODE_COMMON_PIPE /home/iojs/test.pipe
ENV NODE_TEST_DIR /home/iojs/tmp
ENV PATH /usr/lib/ccache:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV SHELL /bin/bash
ENV USER iojs

RUN apt-get update && apt-get install apt-utils -y && \
    apt-get dist-upgrade -y && apt-get install -y \
      ccache \
      curl \
      g++ \
      gcc \
      git \
      pkg-config \
      python3-pip 

RUN addgroup --gid "$GID" iojs

RUN adduser --gid "$GID" --uid "$UID" --disabled-password --gecos iojs iojs

# OpenSSL FIPS validation occurs post-release, and not for every version.
# See https://www.openssl.org/docs/fips.html and the version documented in the
# certificate and security policy.
ENV OPENSSL30FIPSVER 3.0.8
ENV OPENSSL30FIPSDIR /opt/openssl-$OPENSSL30FIPSVER-fips
ENV OPENSSL_CONF $OPENSSL30FIPSDIR/ssl/openssl.cnf
ENV OPENSSL_MODULES $OPENSSL30FIPSDIR/lib64/ossl-modules

RUN mkdir -p /tmp/openssl-$OPENSSL30FIPSVER && \
    cd /tmp/openssl-$OPENSSL30FIPSVER && \
    curl -sL https://www.openssl.org/source/openssl-$OPENSSL30FIPSVER.tar.gz | tar zxv --strip=1 && \
    ./config --prefix=$OPENSSL30FIPSDIR enable-fips && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install && \
    rm -rf /tmp/openssl-$OPENSSL30FIPSVER
# Install the FIPS provider. Update OpenSSL config file to enable FIPS.
RUN LD_LIBRARY_PATH=$OPENSSL30FIPSDIR/lib64 $OPENSSL30FIPSDIR/bin/openssl fipsinstall \
      -module $OPENSSL_MODULES/fips.so -provider_name fips \
      -out $OPENSSL30FIPSDIR/ssl/fipsmodule.cnf && \
      sed -i -r "s|^# (.include fipsmodule.cnf)|.include $OPENSSL30FIPSDIR\/ssl\/fipsmodule.cnf|g" $OPENSSL_CONF && \
      sed -i -r '/^providers = provider_sect/a alg_section = evp_properties' $OPENSSL_CONF && \
      sed -i -r 's/^# (fips = fips_sect)/\1/g' $OPENSSL_CONF && \
      sed -i -r 's/^# (activate = 1)/\1/g' $OPENSSL_CONF && \
      echo "\n[evp_properties]\ndefault_properties = \"fips=yes\"\n" >> $OPENSSL_CONF

VOLUME /home/iojs/ /home/iojs/.ccache

USER iojs:iojs

ENV LD_LIBRARY_PATH $OPENSSL30FIPSDIR/lib64
ENV PKG_CONFIG_PATH $OPENSSL30FIPSDIR/lib64/pkgconfig

WORKDIR /home/iojs

CMD cd /home/iojs \
  && tail -f < /dev/null
