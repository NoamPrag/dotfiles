# remote-sshfs.nvim

[![Actions status](https://github.com/nosduco/remote-sshfs.nvim/workflows/CI/badge.svg)](https://github.com/nosduco/remote-sshfs.nvim/actions)

🚧 **(ALPHA/UNSTABLE) This plugin is currently being developed and may
break or change frequently!** 🚧

Explore, edit, and develop on a remote machine via SSHFS with Neovim. Loosely based on the VSCode extension [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh). (Note: this plugin does not install packages on the remote server, instead it conducts finds, greps, etc over SSH and accesses files via SSHFS)

![Demo](https://github.com/nosduco/remote-sshfs.nvim/blob/main/demo.gif)

## Table of Contents

- [Getting Started](#getting-started)
- [Usage](#usage)
- [Customization](#customization)
- [Commands](#commands)
- [Integrations](#integrations)
- [API](#api)
- [Contributing](#contributing)

## Getting Started

[Neovim (v0.7.0)](https://github.com/neovim/neovim/releases/tag/v0.7.0) or the
latest neovim nightly commit is required for `remote-sshfs.nvim` to work because of its dependencies.

### Required dependencies

##### Neovim plugins

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

##### System dependencies

- [sshfs](https://github.com/libfuse/sshfs)
- [ssh](https://www.openssh.com/)

### Installation

##### Install using your favorite package manager

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'nosduco/remote-sshfs.nvim'
```

Using [dein](https://github.com/Shougo/dein.vim)

```viml
call dein#add('nosduco/remote-sshfs.nvim')
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'nosduco/remote-sshfs.nvim',
  requires = { {'nvim-telescope/telescope.nvim'} } -- optional if you declare plugin somewhere else
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
    {
    'nosduco/remote-sshfs.nvim',
    }

-- plugins/telescope.lua:
return {
    'nosduco/remote-sshfs.nvim',
      dependencies = { 'nvim-telescope/telescope.nvim' } -- optional if you declare plugin somewhere else
    }
```

### Setup (<strong>Important!</strong>)

##### Setup the plugin (override config if necessary, default is below)

```lua
require('remote-sshfs').setup({})
```

##### Load the extension with telescope

```lua
require('telescope').load_extension 'remote-sshfs'
```

Try the command `:RemoteSSHFSConnect`
  to see if `remote-sshfs.nvim` is installed and configured corrected

## Usage

This plugin allows you to edit files on remote hosts via SSHFS as if they were local.

With this plugin you can:

- Connect and mount a remote host via SSHFS using the `:RemoteSSHFSConnect` command. This command will trigger a picker to appear where you can select hosts that have been parsed from your SSH config files. Upon selecting a host, remote-sshfs will mount the host (by default at `~/.sshfs/<hostname>`) and change the current working directory to that folder. Additionally, by default, once vim closes the mount will be automatically unmounted and cleaned.
- Disconnect from a remote host that you're current connected to using the `:RemoteSSHFSDisconnect` command
- Select a SSH config to edit via a picker by using the `:RemoteSSHFSEdit` command
- Utilize Telescope Find Files functionality completely remote via SSH by using the `:RemoteSSHFSFindFiles` command (<strong>Note: the remote server must have either [ripgrep](https://github.com/BurntSushi/ripgrep), [fd/fdfind](https://github.com/sharkdp/fd), or the where command</strong>)
- Utilize Telescope Live Grep functionality completely remote via SSH by using the `:RemoteSSHFSLiveGrep` command (<strong>Note: the remote server must have [ripgrep](https://github.com/BurntSushi/ripgrep) installed</strong>)

<strong>Note:</strong> Currently only parsing hosts is supported, the ability to pass a host via the above commands will eventually be added

To learn more about SSH configs and how to write/style one you can read more [here](https://linuxize.com/post/using-the-ssh-config-file/)

For conveninece, it is recommended to setup keymappings for these commands.

Setup keymappings using Lua:

```lua
local api = require('remote-sshfs.api')
vim.keymap.set('n', '<leader>rc', api.connect, {})
vim.keymap.set('n', '<leader>rd', api.disconnect, {})
vim.keymap.set('n', '<leader>re', api.edit, {})

-- (optional) Override telescope find_files and live_grep to make dynamic based on if connected to host
local builtin = require("telescope.builtin")
local connections = require("remote-sshfs.connections")
vim.keymap.set("n", "<leader>ff", function()
 if connections.is_connected then
  api.find_files()
 else
  builtin.find_files()
 end
end, {})
vim.keymap.set("n", "<leader>fg", function()
 if connections.is_connected then
  api.live_grep()
 else
  builtin.live_grep()
 end
end, {})
```

## Customization

This section should help you explore and configure `remote-sshfs.nvim` to your liking

### remote-sshfs setup structure

Here is an example setup with the default config. You do not have to supply a configuration, use this as a reference.

```lua
require('remote-sshfs').setup{
  connections = {
    ssh_configs = { -- which ssh configs to parse for hosts list
      vim.fn.expand "$HOME" .. "/.ssh/config",
      "/etc/ssh/ssh_config",
      -- "/path/to/custom/ssh_config"
    },
    sshfs_args = { -- arguments to pass to the sshfs command
      "-o reconnect",
      "-o ConnectTimeout=5",
    },
  },
  mounts = {
    base_dir = vim.fn.expand "$HOME" .. "/.sshfs/", -- base directory for mount points
    unmount_on_exit = true, -- run sshfs as foreground, will unmount on vim exit
  },
  handlers = {
    on_connect = {
      change_dir = true, -- when connected change vim working directory to mount point
    },
    on_disconnect = {
      clean_mount_folders = false, -- remove mount point folder on disconnect/unmount
    },
    on_edit = {}, -- not yet implemented
  },
  ui = {
    select_prompts = false, -- not yet implemented
    confirm = {
      connect = true, -- prompt y/n when host is selected to connect to
      change_dir = false, -- prompt y/n to change working directory on connection (only applicable if handlers.on_connect.change_dir is enabled)
    },
  },
  log = {
    enable = false, -- enable logging
    truncate = false, -- truncate logs
    types = { -- enabled log types
      all = false,
      util = false,
      handler = false,
      sshfs = false,
    },
  },
}
```

## Commands

Here's a list of the available commands and variations:

`:RemoteSSHFSConnect`: Use this command to open the host picker and connect to a remote host (parsed from ssh configs)

`:RemoteSSHFSConnect <[user@]host>:/path -p <port>`: Use this command to directly connect to a host with optional user, path, and port variables like you would with `scp` or `sshfs`.

- Examples: `:RemoteSSHFSConnect tony@server:/srv -p 1234`, `:RemoteSSHFSConnect server`, `:RemoteSSHFSConnect tony@server`

`:RemoteSSHFSDisconnect`: Use this command to disconnect from a connected host

`:RemoteSSHFSEdit`: Use this command to open the ssh config picker to open and edit ssh configs

`:RemoteSSHFSFindFiles`: Use this command to initiate a telescope find files window which operates completely remotely via SSH and will open buffers referencing to your local mount

`:RemoteSSHFSLiveGrep`: Use this command to initiate a telescope live grep window which operates completely remotely via SSH and will open buffers referencing to your local mount

## Integrations

Integrations are key to the usefulness of `remote-sshfs.nvim` and many more are to come.

Currently, integrations are being developed and will be released soon.

## Contributing

If you find a bug or have a suggestion for how to improve remote-sshfs.nvim or additional functionality, please feel free to submit an issue or a pull request. We welcome contributions from the community and are committed to making remote-sshfs.nvim as useful as possible for everyone who uses it.

## License

remote-sshfs.nvim is released under the MIT license. please see the [LICENSE](https://giuthub.com/nosduco/remote-sshfs.nvim/blob/main/LICENSE) file for details.
