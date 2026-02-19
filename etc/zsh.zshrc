#!/bin/zsh
# 💪 .zshrc on steroids with oh-my-posh and useful functions

# Exit if the shell is not interactive
[[ -o interactive ]] || return

# === Basic settings === ⚙️
# History
HISTSIZE=999999
SAVEHIST=999999
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt CHECK_JOBS

# === Oh-My-Posh === ✨

# 👉 Install oh-my-posh if it's not installed:
#
# brew install jandedobbeleer/oh-my-posh/oh-my-posh
# mkdir -p ~/.config/oh-my-posh/themes
# curl -fsSL https://git.recwebnetwork.com/oh-my-posh/themes/recweb.omp.json -o ~/.config/oh-my-posh/themes/recweb.omp.json

eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/recweb.omp.json)"

# === Useful aliases === 🔖
# Colors for commands (macOS uses different flags)
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Shortcuts for ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Other useful aliases
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias top='top -o cpu'
else
    alias free='free -h'
    alias top='htop 2>/dev/null || top'
fi

# Git (if you use it)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias release='git_release'
alias push='git_push'
alias init-repo='git_init_repo'


# === Load additional files === 📂
# Custom aliases
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases

# Zsh completion
autoload -Uz compinit
compinit

# Hestia (if you use it)
[ -f /etc/profile.d/hestia.sh ] && source /etc/profile.d/hestia.sh

# Command not found handler (macOS specific)
if [ -x /usr/libexec/path_helper ]; then
    eval `/usr/libexec/path_helper -s`
fi

# === Useful functions === 🧰
# Extract archives
extract()
{
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a directory and enter it
mkcd()
{
    mkdir -p "$1" && cd "$1"
}

# === Git release helper (semver) === 🏷️🚀
git_release()
{
    # Config
    local DEFAULT_START="v1.0.0"   # starting point if no tag exists
    local REMOTE="origin"
    local BRANCH=""
    local SET_VERSION=""
    local INCREMENT="auto"         # auto | major | minor | patch
    local ALLOW_DIRTY="no"
    local DRY_RUN="no"
    local MESSAGE=""

    # Arg parsing
    for arg in "$@"
    do
        case "$arg" in
            --v=*|--version=*)
                SET_VERSION="${arg#*=}"
                ;;
            --major)
                INCREMENT="major"
                ;;
            --minor)
                INCREMENT="minor"
                ;;
            --patch)
                INCREMENT="patch"
                ;;
            --start=*)
                DEFAULT_START="${arg#*=}"
                [[ "$DEFAULT_START" =~ ^v ]] || DEFAULT_START="v$DEFAULT_START"
                ;;
            --remote=*)
                REMOTE="${arg#*=}"
                ;;
            --branch=*)
                BRANCH="${arg#*=}"
                ;;
            --allow-dirty)
                ALLOW_DIRTY="yes"
                ;;
            -n|--dry-run)
                DRY_RUN="yes"
                ;;
            -m=*)
                MESSAGE="${arg#*=}"
                ;;
            -m)
                shift
                MESSAGE="$1"
                ;;
            -h|--help)
                cat <<'EOF'
Usage: git_release [--v=1.2.3 | --major | --minor | --patch] [--start=1.0.0]
                   [--remote=origin] [--branch=<name>] [--allow-dirty] [-n|--dry-run]
                   [-m "message"]

Without options: autoincrement (vX.Y.0 after vX.(Y-1).9, otherwise vX.Y.(Z+1))
Examples:
  git_release                 # v1.0.1 -> v1.0.2, v1.0.9 -> v1.1.0
  git_release --v=1.2.0       # set directly to v1.2.0
  git_release --minor         # bump minor (reset patch)
  git_release --major         # bump major (reset minor/patch)
  git_release -n              # show what it would do, without modifying repo
EOF
                return 0
                ;;
        esac
    done

    # 1) Is it a Git repo?
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1
    then
        echo "❌ You are not in a Git repository."
        return 1
    fi

    # 2) Current branch (if not given)
    if [ -z "$BRANCH" ]
    then
        BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    fi

    # 3) Clean?
    if [ "$ALLOW_DIRTY" = "no" ]
    then
        if ! git diff --quiet || ! git diff --cached --quiet
        then
            echo "❌ Working tree has uncommitted changes. Use --allow-dirty if intentional."
            return 1
        fi
    fi

    # 4) Last semver tag reachable from HEAD
    local LAST_TAG
    LAST_TAG="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --merged HEAD | sort -V | tail -n1)"

    # 5) Determine the future tag
    local NEXT_TAG
    if [ -n "$SET_VERSION" ]
    then
        # manually set version
        [[ "$SET_VERSION" =~ ^v ]] || SET_VERSION="v$SET_VERSION"
        if [[ ! "$SET_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
        then
            echo "❌ Invalid version: $SET_VERSION (expected: vX.Y.Z or X.Y.Z)"
            return 1
        fi
        NEXT_TAG="$SET_VERSION"
    else
        local BASE="${LAST_TAG:-$DEFAULT_START}"
        [[ "$BASE" =~ ^v ]] || BASE="v$BASE"
        if [[ ! "$BASE" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
        then
            echo "❌ Last tag is not semver (vX.Y.Z): $BASE"
            return 1
        fi

        local VER="${BASE#v}"
        local MAJOR MINOR PATCH
        IFS='.' read -r MAJOR MINOR PATCH <<< "$VER"

        case "$INCREMENT" in
            major)
                MAJOR=$((MAJOR + 1))
                MINOR=0
                PATCH=0
                ;;
            minor)
                MINOR=$((MINOR + 1))
                PATCH=0
                ;;
            patch)
                PATCH=$((PATCH + 1))
                ;;
            auto)
                # Your logic: 0..8 -> +1 patch; 9 -> bump minor, reset patch
                if [ "$PATCH" -ge 9 ]
                then
                    PATCH=0
                    if [ "$MINOR" -ge 9 ]
                    then
                        MINOR=0
                        MAJOR=$((MAJOR + 1))
                    else
                        MINOR=$((MINOR + 1))
                    fi
                else
                    PATCH=$((PATCH + 1))
                fi
                ;;
        esac

        NEXT_TAG="v${MAJOR}.${MINOR}.${PATCH}"
    fi

    # 6) Avoid duplicates
    if git rev-parse "$NEXT_TAG" >/dev/null 2>&1
    then
        echo "❌ Tag $NEXT_TAG already exists."
        return 1
    fi

    local MSG="${MESSAGE:-$NEXT_TAG}"

    echo "➡️  Branch: $BRANCH"
    echo "➡️  Remote: $REMOTE"
    echo "➡️  Last tag: ${LAST_TAG:-(none)}"
    echo "✅  Next tag: $NEXT_TAG"
    echo "📝  Message: $MSG"
    [ "$DRY_RUN" = "yes" ] && { echo "(dry-run) Not creating tag and not pushing."; return 0; }

    # 7) Create tag and push atomically
    if ! git tag -a "$NEXT_TAG" -m "$MSG"
    then
        echo "❌ Error in 'git tag'."
        return 1
    fi

    if ! git push --atomic "$REMOTE" "$BRANCH" "$NEXT_TAG"
    then
        echo "❌ Error in push. Deleting local tag created."
        git tag -d "$NEXT_TAG" >/dev/null 2>&1
        return 1
    fi

    echo "🎉 Done: $NEXT_TAG has been pushed to $REMOTE/$BRANCH."
}

# === Git quick push (add + commit random + push) === ⚡🐱
git_push()
{
    # Options
    local MSG=""                 # -m "message"
    local PREFIX="chore"         # --prefix=chore|feat|fix|docs|refactor|style|test|perf
    local REMOTE=""              # --remote=origin
    local BRANCH=""              # --branch=main
    local NO_VERIFY="no"         # --no-verify
    local SIGNOFF="no"           # --signoff
    local AMEND="no"             # --amend
    local DRY_RUN="no"           # -n | --dry-run

    # Parse args
    while [ $# -gt 0 ]
    do
        case "$1" in
            -m)
                shift
                MSG="$1"
                ;;
            -m=*)
                MSG="${1#*=}"
                ;;
            --msg=*)
                MSG="${1#*=}"
                ;;
            --prefix=*)
                PREFIX="${1#*=}"
                ;;
            --remote=*)
                REMOTE="${1#*=}"
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                ;;
            --no-verify)
                NO_VERIFY="yes"
                ;;
            --signoff)
                SIGNOFF="yes"
                ;;
            --amend)
                AMEND="yes"
                ;;
            -n|--dry-run)
                DRY_RUN="yes"
                ;;
            -h|--help)
                cat <<'EOF'
Usage: push [-m "message"] [--prefix=chore|feat|fix|docs|refactor|style|test|perf]
            [--remote=origin] [--branch=main] [--no-verify] [--signoff] [--amend]
            [-n|--dry-run]

Without options: stage everything, commit with a random message and push to upstream.
Examples:
  push
  push -m "feat: import products"
  push --prefix=fix
  push --no-verify
  push --amend               # amend the last commit
  push -n                    # show what it would do
EOF
                return 0
                ;;
        esac
        shift
    done

    # In a Git repository?
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1
    then
        echo "❌ You are not in a Git repository."
        return 1
    fi

    # Current branch
    local CUR_BRANCH
    CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || CUR_BRANCH=""

    # Upstream (if any)
    local UPSTREAM REMOTE_FROM_UPSTREAM BRANCH_FROM_UPSTREAM SET_UPSTREAM=""
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1
    then
        UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name @{u})"
        REMOTE_FROM_UPSTREAM="${UPSTREAM%/*}"
        BRANCH_FROM_UPSTREAM="${UPSTREAM#*/}"
    fi

    # Final REMOTE/BRANCH
    local FINAL_REMOTE FINAL_BRANCH
    FINAL_REMOTE="${REMOTE:-${REMOTE_FROM_UPSTREAM:-origin}}"
    FINAL_BRANCH="${BRANCH:-${BRANCH_FROM_UPSTREAM:-${CUR_BRANCH}}}"
    if [ -z "$BRANCH_FROM_UPSTREAM" ]
    then
        SET_UPSTREAM="-u"
    fi

    # Any changes to push?
    if [ -z "$(git status --porcelain)" ] && [ "$AMEND" = "no" ]
    then
        echo "ℹ️  No changes to push."
        return 0
    fi

    # Add all (respects .gitignore)
    echo "➕  git add -A"
    [ "$DRY_RUN" = "yes" ] || git add -A

    # Random message if not provided
    if [ -z "$MSG" ] && [ "$AMEND" = "no" ]
    then
        # simple generator: short random hex (e.g. c091) or fallback random value
        local RANDHEX
        RANDHEX="$(openssl rand -hex 2 2>/dev/null || printf '%06x' $((RANDOM%65536)))"
        MSG="${RANDHEX}"
    elif [ -z "$MSG" ] && [ "$AMEND" = "yes" ]
    then
        # when amend without message => keep previous message (--no-edit)
        :
    fi

    # Commit flags
    local COMMIT_ARGS=()
    [ "$SIGNOFF" = "yes" ] && COMMIT_ARGS+=("--signoff")
    [ "$NO_VERIFY" = "yes" ] && COMMIT_ARGS+=("--no-verify")

    # Commit
    if [ "$AMEND" = "yes" ]
    then
        if [ -n "$MSG" ]
        then
            echo "📝  git commit --amend -m \"$MSG\" ${COMMIT_ARGS[*]}"
            [ "$DRY_RUN" = "yes" ] || git commit --amend -m "$MSG" "${COMMIT_ARGS[@]}"
        else
            echo "📝  git commit --amend --no-edit ${COMMIT_ARGS[*]}"
            [ "$DRY_RUN" = "yes" ] || git commit --amend --no-edit "${COMMIT_ARGS[@]}"
        fi
    else
        echo "📝  git commit -m \"$MSG\" ${COMMIT_ARGS[*]}"
        if [ "$DRY_RUN" = "yes" ]
        then
            :
        else
            if ! git commit -m "$MSG" "${COMMIT_ARGS[@]}"
            then
                echo "❌ Commit failed (maybe no changes)."
                return 1
            fi
        fi
    fi

    # Push
    echo "🚀  git push $SET_UPSTREAM \"$FINAL_REMOTE\" \"$FINAL_BRANCH\""
    if [ "$DRY_RUN" = "yes" ]
    then
        return 0
    fi

    if ! git push $SET_UPSTREAM "$FINAL_REMOTE" "$FINAL_BRANCH"
    then
        echo "❌ Error while pushing."
        return 1
    fi

    echo "✅  Pushed to $FINAL_REMOTE/$FINAL_BRANCH."
}

# === Git init helper for new repos === 🆕📦
git_init_repo()
{
    local REPO_URL=""
    local BRANCH="main"
    local README_TEXT=""
    local INITIAL_COMMIT="first commit"
    local DRY_RUN="no"

    # Parse args
    while [ $# -gt 0 ]
    do
        case "$1" in
            --url=*)
                REPO_URL="${1#*=}"
                ;;
            --branch=*)
                BRANCH="${1#*=}"
                ;;
            --readme=*)
                README_TEXT="${1#*=}"
                ;;
            --commit=*)
                INITIAL_COMMIT="${1#*=}"
                ;;
            -n|--dry-run)
                DRY_RUN="yes"
                ;;
            -h|--help)
                cat <<'EOF'
Usage: git_init_repo --url=<github-url> [--branch=main] [--readme="text"] [--commit="first commit"] [-n|--dry-run]

Initialize a new Git repository and push to GitHub.
Examples:
  git_init_repo --url=https://github.com/user/repo.git
  git_init_repo --url=https://github.com/user/repo.git --readme="My Project"
  git_init_repo --url=https://github.com/user/repo.git --branch=master
  git_init_repo -n --url=https://github.com/user/repo.git  # dry-run
EOF
                return 0
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo "Use --help for usage information."
                return 1
                ;;
        esac
        shift
    done

    # Validate URL
    if [ -z "$REPO_URL" ]
    then
        echo "❌ Repository URL is required. Use --url=<github-url>"
        return 1
    fi

    # Extract repo name from URL for README
    local REPO_NAME
    REPO_NAME="$(basename "$REPO_URL" .git)"

    # Default README text if not provided
    if [ -z "$README_TEXT" ]
    then
        README_TEXT="# ${REPO_NAME}"
    fi

    echo "📦  Initializing repository..."
    echo "➡️  URL: $REPO_URL"
    echo "➡️  Branch: $BRANCH"
    echo "➡️  Commit: $INITIAL_COMMIT"

    if [ "$DRY_RUN" = "yes" ]
    then
        echo "(dry-run) Commands that would be executed:"
        echo "  echo \"$README_TEXT\" >> README.md"
        echo "  git init"
        echo "  git add README.md"
        echo "  git commit -m \"$INITIAL_COMMIT\""
        echo "  git branch -M $BRANCH"
        echo "  git remote add origin $REPO_URL"
        echo "  git push -u origin $BRANCH"
        return 0
    fi

    # Check if already a git repo
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
    then
        echo "❌ Already a Git repository. Use 'git remote add origin <url>' instead."
        return 1
    fi

    # Initialize repo first
    echo "🔧  git init"
    git init || { echo "❌ git init failed"; return 1; }

    # Create README if it doesn't exist
    if [ ! -f "README.md" ]
    then
        echo "📝  Creating README.md..."
        echo "$README_TEXT" > README.md || { echo "❌ Failed to create README.md"; return 1; }
    fi

    # Add all files (respects .gitignore if exists)
    echo "➕  git add -A"
    git add -A || { echo "❌ git add failed"; return 1; }

    # First commit
    echo "📝  git commit -m \"$INITIAL_COMMIT\""
    git commit -m "$INITIAL_COMMIT" || { echo "❌ git commit failed"; return 1; }

    # Set branch name
    echo "🌿  git branch -M $BRANCH"
    git branch -M "$BRANCH" || { echo "❌ git branch failed"; return 1; }

    # Add remote
    echo "🔗  git remote add origin $REPO_URL"
    git remote add origin "$REPO_URL" || { echo "❌ git remote add failed"; return 1; }

    # Push
    echo "🚀  git push -u origin $BRANCH"
    if ! git push -u origin "$BRANCH"
    then
        echo "❌ git push failed. Check your credentials and repository access."
        return 1
    fi

    echo "✅  Repository initialized and pushed to $REPO_URL"
}

# === Environment variables === 🌐
export EDITOR='nano'
export VISUAL='nano'
export PAGER='less'

# Settings for less
export LESS='-R --use-color -Dd+r$Du+b'

# === SSH helpers === 🔐
# Usage:
#   hosts        # list host names from ~/.ssh/config (and Include files)
#   hosts foo    # filter by substring (case-insensitive)
__ssh__config_files()
{
    local main_config="$HOME/.ssh/config"
    local -a queue=("$main_config")
    local -a out=()
    typeset -A visited

    while ((${#queue[@]})); do
        local file="${queue[-1]}"
        queue[-1]=()

        [[ -r "$file" ]] || continue
        [[ -n "${visited[$file]}" ]] && continue
        visited[$file]=1
        out+=("$file")

        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%$'\r'}"
            # Strip comments safely (do not break Host aliases containing '#')
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            line="${line%%[[:space:]]#*}"

            [[ "$line" =~ ^[[:space:]]*Include[[:space:]]+(.+)$ ]] || continue

            local rest="${match[1]}"
            local -a patterns=()
            patterns=(${=rest})

            local pattern
            for pattern in "${patterns[@]}"; do
                [[ -n "$pattern" ]] || continue

                if [[ "$pattern" == "~/"* ]]; then
                    pattern="$HOME/${pattern:2}"
                elif [[ "$pattern" != /* ]]; then
                    pattern="$HOME/.ssh/$pattern"
                fi

                local match_file
                for match_file in ${~pattern}; do
                    [[ -e "$match_file" ]] && queue+=("$match_file")
                done
            done
        done <"$file"
    done

    printf '%s\n' "${out[@]}"
}

__ssh__list_hosts()
{
    local -a files=()
    files=(${(f)"$(__ssh__config_files)"})
    ((${#files[@]})) || return 0

    awk '
        {
            sub(/\r$/, "")
            # Strip comments safely: whole-line comments or inline comments preceded by whitespace
            sub(/^[[:space:]]*#.*/, "")
            sub(/[[:space:]]+#.*/, "")
        }
        /^[[:space:]]*Host[[:space:]]+/ {
            for (i = 2; i <= NF; i++) {
                if ($i !~ /[*?]/) print $i
            }
        }
    ' "${files[@]}" 2>/dev/null | sort -u
}

hosts()
{
    if [[ $# -ge 1 && -n "$1" ]]; then
        __ssh__list_hosts | grep -i -- "$1"
    else
        __ssh__list_hosts
    fi
}

# Open ~/.ssh/config quickly
open_hosts()
{
    mkdir -p "$HOME/.ssh"
    touch "$HOME/.ssh/config"

    case "$1" in
        --code)
            if command -v code >/dev/null 2>&1
            then
                code "$HOME/.ssh/config"
            else
                nano "$HOME/.ssh/config"
            fi
            ;;
        *)
            nano "$HOME/.ssh/config"
            ;;
    esac
}

alias open-hosts='open_hosts'

# === OMP host background color based on hostname === 🎨
omp_host_bg() {
  local host
  host="$(hostname)"

  local palette=(
    "#E49595" "#E4AD95" "#E4C395" "#E4D795" "#D7E495"
    "#B6E495" "#95E495" "#95E4B6" "#95E4D7" "#95D1E4"
    "#95B6E4" "#959CE4" "#A995E4" "#C395E4" "#DE95E4"
    "#E495D1" "#E495BD" "#E495A9" "#95E4CA" "#E4CA95"
  )

  local idx
  idx=$(printf '%s' "$host" | shasum -a 256 | awk '{print $1}' | cut -c1-8)
  idx=$(( 16#$idx % ${#palette[@]} ))

  export OMP_HOST_BG="${palette[$idx]}"
}

omp_host_bg
