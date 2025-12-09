# AI Toolbox

A portable, Docker-based development environment designed for AI-assisted coding. This toolbox provides a consistent, ephemeral workspace that can be run on any machine with Docker and Docker Compose.

## Quick Start

1.  Clone this repository:
    ```bash
    git clone https://github.com/YOUR_USERNAME/ai-toolbox.git
    cd ai-toolbox
    ```

2.  Build and run the container:
    ```bash
    docker-compose up --build -d
    ```

3.  Attach to the running AI Team session:
    ```bash
    docker attach ai-team-workstation
    ```

## Usage

Inside the container, use the `start-team` script to manage your projects.

### Start a New Project
Creates a new project directory, initializes it with AI configuration, and starts the team.
```bash
start-team new /tmp/my-new-project --desc "A new project to build a thing"