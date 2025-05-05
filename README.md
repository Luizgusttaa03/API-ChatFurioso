# ChatFurioso Backend

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) <!-- Opcional: Escolha a licença adequada -->

Backend para a aplicação ChatFurioso, responsável por gerenciar a lógica de negócios, interações com o banco de dados e integração com a API do Google Gemini.

## ✨ Funcionalidades Principais

*   Gerenciamento de salas de chat ou conversas
*   Processamento e armazenamento de mensagens
*   Integração com a IA do Google Gemini
*   API RESTful para comunicação com o frontend

## 🚀 Tecnologias Utilizadas

*   **Linguagem:** Ruby
*   **Framework:** Rails
*   **Banco de Dados:** PostgreSQL (Hospedado em [Koyeb](https://koyeb.com/))
*   **IA:** Google Gemini API
*   **Gerenciador de Pacotes:** npm

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado em sua máquina:

*   Ruby
*   npm
*   Opcional: Cliente PostgreSQL, como psql ou DBeaver
*   Git

## ⚙️ Instalação e Configuração

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/Luizgusttaa03/API-ChatFurioso
    cd chatfurioso-backend
    ```

2.  **Instale as dependências:**
    ```bash
    # Exemplo para Node.js/npm
    npm install
    # Ou para yarn
    # yarn install
    # Ou para Python/pip
    # pip install -r requirements.txt
    ```
    *(Substitua pelo comando apropriado para sua tecnologia)*

3.  **Configure as variáveis de ambiente:**
    *   Crie um arquivo chamado `.env` na raiz do projeto.
    *   Copie o conteúdo do arquivo `.env.example` (se existir) ou adicione as seguintes variáveis:
        ```properties
        # Chave da API do Google Gemini
        GEMINI_API_KEY=SUA_CHAVE_API_GEMINI

        # URL de conexão com o banco de dados PostgreSQL
        DATABASE_URL=postgres://usuario:senha@host:porta/database

        # Outras variáveis necessárias (ex: porta do servidor, segredos JWT, etc.)
        # PORT=3000
        # JWT_SECRET=seu_segredo_super_secreto
        ```
    *   **Importante:** Substitua `SUA_CHAVE_API_GEMINI` e a `DATABASE_URL` pelos seus valores reais. **Nunca** comite o arquivo `.env` com credenciais reais para o repositório Git. Adicione `.env` ao seu arquivo `.gitignore`.

4.  **[Opcional] Migrações do Banco de Dados:**
    *   Se você utiliza um sistema de migração (como Prisma, TypeORM, Alembic, Flyway), execute o comando para aplicar as migrações:
        ```bash
        # Exemplo com Prisma
        # npx prisma migrate deploy
        # Exemplo com TypeORM
        # npm run typeorm migration:run
        ```
        *(Substitua pelo comando apropriado)*

## ▶️ Executando a Aplicação

```bash
# Exemplo para Node.js
npm start
# Ou para desenvolvimento (com hot-reload, se configurado)
# npm run dev
```
*(Substitua pelo comando apropriado para iniciar seu servidor)*

A API estará disponível em `http://localhost:[PORTA]` (a porta padrão geralmente é 3000 ou 8000, verifique sua configuração).

## 📄 API Endpoints (Opcional)

*   `GET /api/health`: Verifica o status da aplicação.
*   `GET /api/chats`: Lista as conversas do usuário.
*   `POST /api/chat`: Envia uma nova mensagem.

## 📝 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais informações.

---

*Desenvolvido por Luiz Gustavo*
