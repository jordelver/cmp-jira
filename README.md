# cmp-jira

Jira source for [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)

- `#` to trigger Jira issues completion in `gitcommit` buffers

## Requirements

- curl

## Installation

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "nvim-lua/plenary.nvim"
Plug "jordelver/cmp-jira"
```

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use("jordelver/cmp-jira", requires = "nvim-lua/plenary.nvim")
```

## Setup

Setup a personal access token at https://id.atlassian.com/manage-profile/security/api-tokens

You must export the following environment variables.

- `JIRA_USERNAME=<email>`
- `JIRA_TOKEN=<the-token-you-created>`
- `JIRA_SUBDOMAIN=<your-jira-subdomain>`
- `JIRA_ASSIGNEE=<your-jira-assignee-name>`  
  (URL encoded like `'Firstname%20Lastname'`)

```lua
cmp.setup {
  sources = cmp.config.sources({
    -- more sources
    { name = 'jira' },
  }),
}

require("cmp_jira").setup()
```

## TODO

- Fix issue with ghost text (`experimental.ghost_text`) covering up the first
  letter of the completion item - not sure if this is something wrong with ghost
  text or with this plugin.

- Cache the list of issues locally somewhere to make more responsive?

- Fix crimes against querystrings / URL encoding - see `utils.lua`.

## Acknowledgements

- Peter Tri Ho for [`nvim-git`](https://github.com/petertriho/cmp-git) which I
  used as an example of a `nvim-cmp` source.

- Wincent's video: [Neovim #110: Making a custom nvim-cmp source](https://www.youtube.com/watch?v=gAsYolNrjtQ)

- [TJ Devries](https://www.youtube.com/@teej_dv) - For Neovim content in general

## License

[MIT](https://choosealicense.com/licenses/mit/)
