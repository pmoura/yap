FROM ubuntu AS base

RUN ln -snf /usr/share/zoneinfo/ /etc/localtime && echo  > /etc/timezone
# Set the working directory to /app

WORKDIR /app

RUN      apt -y update && apt -y upgrade &&     apt -y install git gcc g++ make cmake    autotools-dev automake autoconf perl-base m4 doxygen    libreadline-dev libgmp-dev     openmpi-bin libopenmpi-dev    swig ninja-build    mkdocs      r-cran-rcpp

RUN  apt install -y    minisat libcryptominisat5-dev
 
RUN  git clone https://github.com/audemard/glucose.git && mkdir glucose/release && cd  glucose/release && cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5   -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -G Ninja .. &&  ninja 
RUN  apt install -y  libsqlite3-dev libpq-dev libmariadb-dev libmariadb-dev-compat unixodbc-dev

RUN  git clone https://github.com/vscosta/yap /app/yap --depth=1     && mkdir -p /app/yap/build    && cd /app/yap/build    && cmake ..  -DCMAKE_BUILD_TYPE=Release -DWITH_PACKAGES=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -G Ninja  && ninja install &&  cpack -C Release 

ENV NAME=World

