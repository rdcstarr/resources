# Rdcstarr resources

A collection of scripts, configurations, and tools for enhancing productivity and system management.

## Scripts

Install the scripts from `scripts/` into your PATH:

```bash
sudo ./scripts/install.sh
```

Or install into a user-local directory:

```bash
./scripts/install.sh "$HOME/.local/bin"
```

Remote install/update (bootstrap from server):

```bash
RESOURCES_REPO_URL="https://git.recwebnetwork.com/<owner>/<repo>.git" \
	wget -qO- https://git.recwebnetwork.com/scripts/update-scripts.sh | sudo bash
```

## Bash configuration

If you want to use this `.bashrc`, run the following command in your terminal:

```bash
wget -qO- https://git.recwebnetwork.com/etc/update-bashrc.sh | sudo bash
```
