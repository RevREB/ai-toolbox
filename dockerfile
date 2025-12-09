# ai-toolbox/Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/zsh

# Install baseline system packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    gnupg \
    lsb-release \
    zsh \
    sudo \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Create the 'coder' user
RUN useradd -m -s /bin/zsh coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the coder user for subsequent steps
USER coder
WORKDIR /home/coder

# --- Install Developer Tools ---
# Install Starship Prompt
RUN curl -sS https://starship.sh/install.sh | sh -s -- -y

# Install LastPass CLI
RUN curl -fsSL https://lastpass.com/download?lp=linux&arch=x64 -o /tmp/lastpass.deb && \
    dpkg -i /tmp/lastpass.deb || apt-get install -f -y

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt-get update \
    && sudo apt-get install -y gh

# Install Chezmoi
RUN sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b /usr/local/bin

# --- Configure the Environment ---
# Initialize Chezmoi and apply your dotfiles
RUN chezmoi init --apply YOUR_USERNAME

# Clone the ai-toolbox repo to get the start-team script
RUN git clone https://github.com/YOUR_USERNAME/ai-toolbox.git /opt/ai-toolbox

# Set the entrypoint to start your AI Team inside a tmux session
ENTRYPOINT ["tmux", "new-session", "-A", "-s", "ai-team"]