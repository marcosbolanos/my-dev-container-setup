FROM ubuntu:22.04

# Install conda dependencies and general stuff
RUN apt-get update \ 
    && apt-get install -y wget curl bzip2 git nano sudo \ 
    && rm -rf /var/lib/apt/lists/*

# Download and install Miniconda
ENV MINICONDA_VERSION=py310_24.1.2-0
ENV CONDA_DIR=/opt/conda

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -O /tmp/miniconda.sh \ 
    && bash /tmp/miniconda.sh -b -p $CONDA_DIR \ 
    && rm /tmp/miniconda.sh

ENV SHELL="bash"

# Install nvm, nodejs and pnpm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && \. "$HOME/.nvm/nvm.sh" \
    && nvm install 22 \
    && node -v \
    && nvm current \
    && corepack enable pnpm \
    && pnpm -v \
    && NODE_VERSION=$(nvm current) \
    && ln -sf $NVM_DIR/versions/node/$NODE_VERSION/bin/node /usr/local/bin/node \
    && ln -sf $NVM_DIR/versions/node/$NODE_VERSION/bin/npm /usr/local/bin/npm \
    && ln -sf $NVM_DIR/versions/node/$NODE_VERSION/bin/pnpm /usr/local/bin/pnpm \
    && ln -sf $NVM_DIR/versions/node/$NODE_VERSION/bin/npx /usr/local/bin/npx

# Add Node.js to PATH and set up pnpm
ENV NVM_DIR="/root/.nvm"
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Set up pnpm global directory
RUN mkdir -p $PNPM_HOME && pnpm config set global-bin-dir $PNPM_HOME

# Create a non-root user
RUN useradd -m devuser \
   && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes \
    && echo 'eval "$(starship init bash)"' >> /home/devuser/.bashrc

USER devuser

ENV HOME="/home/devuser"
ENV PNPM_HOME="$HOME/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Get the latest version of uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

COPY starship.toml $HOME/.config/starship.toml

# Install Gemini CLI
RUN mkdir -p $PNPM_HOME && pnpm install -g @google/gemini-cli
