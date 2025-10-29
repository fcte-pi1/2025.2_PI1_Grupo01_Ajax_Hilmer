# Projeto Integrador de Engenharia 1

## Estrutura do Repositório

O repositório está organizado em **módulos separados**, facilitando o desenvolvimento e a manutenção do projeto.  
A estrutura principal é a seguinte:

```bash
├── api/ # Código-fonte do servidor e da API
│ ├── README.md # Documentação específica do backend
│ └── ...
├── docs/ # Código-fonte da documentação do gitpages
└── README.md # Este arquivo
```

> A estrutura do projeto descrita acima sofrerá mudanças ao longo do projeto

## Fluxo de Trabalho com Git

1. **Não faça commits diretamente na `main`**  
   - Sempre crie uma branch a partir da `main` com um nome descritivo.  
   - Exemplo: `feat/backend`, `fix/bug-endpoint-post-route`.

2. **Atualize sua branch antes de enviar alterações**  
   - Antes de abrir um *pull request*, garanta que sua branch está atualizada com a `main`.  
   - Comandos recomendados:

   ```bash
   git checkout main
   git pull origin main
   git checkout sua-branch
   git merge main
   ```

3. **Crie *Pull Requests* (PRs)**  
   - Depois de finalizar as alterações, crie um PR para a `main`.  
   - Inclua uma descrição clara do que foi alterado ou adicionado.

4. **Revisão e Aprovação**  
   - Pelo menos um colega deve revisar o PR antes da aprovação.  
   - Após aprovado, o PR pode ser *mergeado* na `main`.

---

## Boas Práticas

- Faça *commits* pequenos e descritivos.  
- Utilize mensagens no formato:  
  - `feat: adicionar validação de login`
  - `fix: corrigir erro de autenticação`
- Sempre revise seu código antes de enviar o PR.  
- Mantenha a documentação atualizada conforme o projeto evolui.
