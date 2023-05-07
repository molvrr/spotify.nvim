# Spotify.nvim

## Setup

### Pré-requisitos
- Sinatra (Ruby)
- Aplicação configurada no [Spotify for Developers](https://developer.spotify.com/dashboard)

### Lazy

```lua
{
  'molvrr/spotify.nvim',
  opts = {
    callback = 'http://localhost:3000/spotify-nvim',
    client_id = 'spotify_api_client_id',
    client_secret = 'spotify_api_client_secret',
  },
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
  }
}
```
