# Scripts

Helpers to manage the Docker stack.

## `up.sh`

- Subir todos os serviços:
  ```bash
  scripts/up.sh
  ```
- Subir apenas o backend:
  ```bash
  scripts/up.sh backend
  ```
- Rebuild e subir o backend:
  ```bash
  scripts/up.sh backend --build
  ```
- Rebuild sem cache (tudo):
  ```bash
  scripts/up.sh --no-cache
  ```
- Atualizar imagens e subir o tunnel do Cloudflare:
  ```bash
  scripts/up.sh cloudflared --pull
  ```

## `push_root.sh`

- Comitar apenas itens da raiz (exclui `backend/` e `frontend/`):
  ```bash
  scripts/push_root.sh
  ```
  - Coleta arquivos do diretório raiz (ignora `.env*`) e a pasta `scripts/`
  - Garante a branch `dev` (cria a partir da `main` se necessário), faz commit e push para `dev`, troca para `main` e volta para `dev`
