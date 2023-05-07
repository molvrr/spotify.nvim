# Spotify.nvim
:warning: **PLUGIN EM VERSÃO EXTREMAMENTE ALFA. ALGUMA COISA COM CERTEZA VAI QUEBRAR. USE POR SUA CONTA E RISCO** :warning:

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

## TODO
- [ ] I18n
- [ ] Separar comportamento da aplicação da UI
- [ ] Remover dependência do Plenary
- [ ] Remover dependência do NUI
- [ ] Remover dependência de Ruby
- [ ] Deixar porta do servidor configurável
- [ ] Resolver problemas de sincronização caso o usuário altere volume direto no Spotify
- [ ] Memoize no device que o player#play_track utiliza
