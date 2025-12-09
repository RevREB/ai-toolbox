#!/bin/bash
# ~/devbox-toolbox/scripts/start_team.sh

set -e

# --- Argument Parsing and Usage ---
usage() {
  echo "Usage: start-team <command> [options]"
  echo ""
  echo "Commands:"
  echo "  new <path> --desc \"<description>\"  Creates a new project directory, initializes it for the AI team, and starts the session."
  echo "  pull <repo_url> [path]              Clones a git repo into a new directory and starts the session."
  echo "  pull-all <topic>                    Finds all repos with a GitHub topic, clones them, and starts a session."
  echo "  open <path>                         Opens an existing project's AI team session."
  echo ""
  echo "Examples:"
  echo "  start-team new ~/dev-workspace/awesome-app --desc \"A new web app using React and Node.js\""
  echo "  start-team pull git@github.com:my-user/my-cool-app.git"
  echo "  start-team pull-all my-projects"
  echo "  start-team open ~/dev-workspace/awesome-app"
  exit 1
}

if [[ "$#" -lt 2 ]]; then
  usage
fi

COMMAND="$1"
ARG="$2"
SESSION_NAME=""

# --- Command Handlers ---

handle_new() {
  PROJECT_PATH="$ARG"
  SESSION_NAME="team-$(basename "$PROJECT_PATH")"

  if [[ -z "$PROJECT_DESC" ]]; then
    echo "Error: --desc is required for the 'new' command."
    usage
  fi

  echo "🚀 Initializing new project: $PROJECT_PATH"
  echo "📝 Description: $PROJECT_DESC"

  mkdir -p "$PROJECT_PATH"
  cd "$PROJECT_PATH"

  if [ ! -d ".git" ]; then
    echo "🔧 Initializing Git repository..."
    git init
    git config user.name "AI Team"
    git config user.email "ai@team.local"
  fi

  echo "🤖 Creating AI team initialization files..."
  cat > .aider.conf <<EOF
# Aider configuration for: $PROJECT_DESC
model: openai/llama-3.1-405b
api_base: https://api.venice.ai/api/v1
api_key: $VENICE_API_KEY
auto_commits: true
auto_commits_message_prefix: '[aider] '
add: .aider.conf
ignore: .git/
ignore: node_modules/
ignore: venv/
ignore: .venv/
ignore: target/
EOF
  cat > .claude_settings <<EOF
{
  "model": "claude-3-5-sonnet-20241022",
  "project_description": "$PROJECT_DESC"
}
EOF
  git add .aider.conf .claude_settings
  git commit -m "feat: Initialize AI team configuration files"
  echo "  ✅ Committed AI config files."

  handle_open
}

handle_pull() {
  REPO_URL="$ARG"
  PROJECT_PATH="${3:-$(basename "$REPO_URL" .git)}"
  SESSION_NAME="team-$(basename "$PROJECT_PATH")"

  echo "🚀 Cloning project from $REPO_URL into $PROJECT_PATH"
  git clone "$REPO_URL" "$PROJECT_PATH"
  cd "$PROJECT_PATH"
  echo "✅ Repository cloned."
  handle_open
}

handle_pull_all() {
  TOPIC="$ARG"
  WORKSPACE_PATH="/tmp/workspace-$(date +%s)"
  mkdir -p "$WORKSPACE_PATH"
  cd "$WORKSPACE_PATH"

  echo "🔍 Finding all repos with topic: $TOPIC"
  
  REPOS=$(gh search repos --topic "$TOPIC" --limit 20 --json fullName,htmlUrl --jq '.[].fullName')

  if [ -z "$REPOS" ]; then
    echo "No repositories found with topic '$TOPIC'."
    exit 0
  fi

  echo "🚀 Cloning found repositories..."
  for REPO_FULL_NAME in $REPOS; do
    echo "  - Cloning $REPO_FULL_NAME..."
    git clone "git@github.com:$REPO_FULL_NAME.git"
  done

  echo "✅ All repositories cloned to $WORKSPACE_PATH"
  echo "🚀 Starting AI Team session in workspace directory."
  
  SESSION_NAME="team-workspace"
  handle_open
}

handle_open() {
  if [ -z "$PROJECT_PATH" ]; then
    PROJECT_PATH="$ARG"
    SESSION_NAME="team-$(basename "$PROJECT_PATH")"
  fi

  ABS_PROJECT_PATH=$(realpath "$PROJECT_PATH")
  if [ ! -d "$ABS_PROJECT_PATH" ]; then
    echo "Error: Directory not found at $ABS_PROJECT_PATH"
    exit 1
  fi

  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "🤖 AI Team session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
  fi

  echo "🚀 Starting AI Team for project: $(basename "$ABS_PROJECT_PATH")"

  tmux new-session -d -s "$SESSION_NAME"

  tmux rename-window -t "$SESSION_NAME:0" "Aider"
  tmux send-keys -t "$SESSION_NAME:0" "cd \"$ABS_PROJECT_PATH\"" C-m
  tmux send-keys -t "$SESSION_NAME:0" "aider" C-m

  tmux new-window -t "$SESSION_NAME:1" -n "Claude"
  tmux send-keys -t "$SESSION_NAME:1" "cd \"$ABS_PROJECT_PATH\"" C-m
  tmux send-keys -t "$SESSION_NAME:1" "claude-code" C-m

  tmux new-window -t "$SESSION_NAME:2" -n "Shell"
  tmux send-keys -t "$SESSION_NAME:2" "cd \"$ABS_PROJECT_PATH\"" C-m
  tmux send-keys -t "$SESSION_NAME:2" "echo 'AI Team Shell. Ready for commands.'" C-m

  tmux select-window -t "$SESSION_NAME:2"

  echo "✅ AI Team session created. Attaching..."
  tmux attach-session -t "$SESSION_NAME"
}

# --- Main Logic ---
case "$COMMAND" in
  new)
    shift 2
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --desc) PROJECT_DESC="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
      esac
      shift
    done
    handle_new
    ;;
  pull)
    if [[ "$#" -gt 3 ]]; then
        echo "Error: 'pull' command takes at most a repo URL and a target path."
        usage
    fi
    handle_pull
    ;;
  pull-all)
    if [[ "$#" -ne 2 ]]; then
      echo "Error: 'pull-all' command requires a single topic."
      usage
    fi
    handle_pull_all
    ;;
  open)
    if [[ "$#" -gt 2 ]]; then
      echo "Error: 'open' command only takes a path."
      usage
    fi
    handle_open
    ;;
  *)
    echo "Error: Unknown command '$COMMAND'."
    usage
    ;;
esac