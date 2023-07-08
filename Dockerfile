FROM ubuntu:bionic

ENV TERM xterm

ENV STEAM_DIR /home/steam
ENV SSH_DIR ${STEAM_DIR}/.ssh
ENV STEAMCMD_DIR ${STEAM_DIR}/steamcmd
ENV CSGO_APP_ID 740
ENV CSGO_DIR ${STEAM_DIR}/csgo
ENV ROOT_PASSWORD rootpassword

SHELL ["/bin/bash", "-c"]

ARG STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

RUN set -xo pipefail \
      && apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
          lib32gcc1 \
          lib32stdc++6 \
          lib32z1 \
          ca-certificates \
          net-tools \
          locales \
          curl \
          unzip \
          sudo \  
          openssh-server \
          lib32z1 \
          rsync \
      && locale-gen en_US.UTF-8 \
      && adduser --disabled-password --gecos "" steam \
      && mkdir ${STEAMCMD_DIR} \
      && cd ${STEAMCMD_DIR} \
      && curl -sSL ${STEAMCMD_URL} | tar -zx -C ${STEAMCMD_DIR} \
      && mkdir -p ${STEAM_DIR}/.steam/sdk32 \
      && ln -s ${STEAMCMD_DIR}/linux32/steamclient.so ${STEAM_DIR}/.steam/sdk32/steamclient.so \
      && { \
            echo '@ShutdownOnFailedCommand 1'; \
            echo '@NoPromptForPassword 1'; \
            echo 'login anonymous'; \
            echo 'force_install_dir ${CSGO_DIR}'; \
            echo 'app_update ${CSGO_APP_ID}'; \
            echo 'quit'; \
        } > ${STEAM_DIR}/autoupdate_script.txt \
      && mkdir ${CSGO_DIR} \
      && chown -R steam:steam ${STEAM_DIR} \
      && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN mkdir /var/run/sshd
# Changing root password.
RUN echo 'root:${ROOT_PASSWORD}' | chpasswd
# Adding our user as a sudoer.
RUN echo "steam ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd  

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

COPY containerfs ${STEAM_DIR}/
RUN chown -R steam:steam ${STEAM_DIR}/

# Configuring SSH access through key_rsa.
COPY .ssh/key_rsa.pub ${SSH_DIR}/key_rsa.pub  
COPY .ssh/sshd_config /etc/ssh/sshd_config 
RUN touch ${SSH_DIR}/authorized_keys \
    && cat ${SSH_DIR}/key_rsa.pub >> ${SSH_DIR}/authorized_keys \
    && chmod 700 ${SSH_DIR} \
    && chmod 600 ${SSH_DIR}/authorized_keys \
    && rm ${SSH_DIR}/key_rsa.pub 
RUN chown -R steam:steam ${SSH_DIR}/

USER steam
WORKDIR ${CSGO_DIR}
VOLUME ${CSGO_DIR}
ENTRYPOINT sudo service ssh start && exec ${STEAM_DIR}/start.sh
