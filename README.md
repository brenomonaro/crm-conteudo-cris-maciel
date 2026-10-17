# Central de Conteúdo, Cris Maciel

Ferramenta interna de gestão do pipeline de produção de conteúdo de marketing.
Um único arquivo HTML (`index.html`), sem build, que fala direto com um banco
Supabase para Breno e Nicole verem o mesmo quadro em tempo real.

Sem o Supabase configurado, o app continua funcionando sozinho, salvando só
no navegador local (útil para testar antes de publicar).

## O material que não é vídeo

Além das quatro classificações de vídeo existe **Outros**: panfleto, foto à
parte, arte de campanha, o que a Nicole produz fora da câmera. Esse trabalho
sempre existiu e vivia fora do quadro; agora entra como card, com checklist
próprio (briefing definido, arquivo anexado) e sem meta mensal, porque meta
mede o que a agenda de gravação precisa produzir e isso aqui nasce de demanda
avulsa.

## Material anexado

Dentro do **Kit de publicação** o card tem uma área de anexos: imagem, PDF ou
documento, até 25 MB cada. Imagem e PDF abrem **dentro do site**, na mesma tela
onde está o botão de liberar, inclusive na fila de **Aprovações**. Aprovar
material que só existe como link no WhatsApp é aprovar no escuro.

O que não sobe (vídeo grande, pasta do Drive, Canva aberto para edição) entra
como **anexo por link**: fica registrado no card, só não abre aqui dentro.

Duas regras valem a pena saber:

- Card classificado como **Outros** não fica pronto sem arquivo anexado, e em
  compensação não pede capa: ali o arquivo *é* a peça.
- Trocar ou remover o material depois de liberado **derruba a liberação**, pelo
  mesmo motivo que trocar a capa derruba: o aval era sobre o pacote antigo.

## Conversa sobre o material

Embaixo do kit, cada card tem uma conversa: o Breno escreve o que quer que
melhore, a Nicole lê e responde, tudo em ordem e assinado. Pedido em aberto
aparece no card do quadro, na faixa de alerta e numa seção própria em
**Aprovações**, até alguém clicar em *marcar como feito*.

Pedido de ajuste de trava cai nessa mesma lista, marcado com a trava de origem,
para quem vai refazer não ter que olhar em dois lugares. A diferença é o que
cada um faz: **pedir ajuste** derruba a aprovação e devolve o card; **pedido de
mudança** é recado, não trava etapa nenhuma. Quando a liberação já está dada, o
próprio campo avisa isso e aponta para o Pedir ajuste.

## As duas travas de aprovação

Nada entra em **Gravado** sem a pauta aprovada pelo Breno e pela Nicole, e
nada entra em **Postado** sem a Nicole montar o kit e o Breno liberar.

**1. Pauta, antes de gravar.** Os dois aprovam, em qualquer ordem. Depois de
gravado não adianta mais discordar do gancho, por isso a trava fica antes da
câmera ligar. O prazo dela corre contra a data da gravação.

**2. Publicação, antes de postar.** Nesta ordem: a Nicole preenche o kit
(título, descrição, capa e data), manda; o Breno confere e libera. O prazo
corre contra a data de publicação. Enquanto faltar qualquer item do kit, o
card nem chega na fila do Breno.

Em qualquer uma das duas, no lugar de aprovar dá para **pedir ajuste** com um
texto dizendo o que mudar. Isso zera aquela trava e devolve o card para quem
precisa refazer, com o pedido visível no card até ser atendido.

Mexer no kit depois de liberado derruba a liberação: ela valia para aquele
pacote, não para outro.

### O que a trava não faz

Ela impede o avanço manual, não a realidade. Se a data de publicação chegar e
a automação mover o card sozinho, ele vai para Postado do mesmo jeito e fica
marcado como **furo**, visível no card, na faixa de alerta e no relatório. O
quadro não finge que a gravação não aconteceu só porque ninguém clicou em
aprovar. Registrar o aval depois fecha o furo.

Card criado já numa etapa adiantada é registro retroativo, não furo: nunca
existiu o momento de aprovar. O mesmo vale para os cards que já estavam no
quadro antes das travas existirem.

### Quem é você

Como não existe login, cada navegador escolhe uma vez entre Breno e Nicole, no
alto da tela. Serve para o quadro saber de quem é cada aprovação e para cada
um ver a própria fila na aba **Aprovações**. Não é senha: o que faz o registro
valer é a combinação de cada um aprovar só em nome próprio.

### Fechar o ciclo

Três dias depois de publicado, o card pede uma leitura de resultado (abaixo,
dentro ou acima do esperado) e uma linha explicando o porquê. Não muda nada no
quadro; é o que entra no relatório e o que faz o mês seguinte sair diferente
deste.

## Colocar a nuvem no ar

### 1. Criar o projeto no Supabase

1. Crie uma conta gratuita em supabase.com e um novo projeto.
2. No painel do projeto, abra "SQL Editor", cole o conteúdo de
   `supabase/schema.sql` e rode. Isso cria as tabelas `cards` e `ideas`,
   liga o realtime e libera leitura/escrita sem exigir login.
3. Em "Project Settings" e depois "API", copie a "Project URL" e a chave
   "anon public".
4. Abra `config.js` e preencha:
   ```js
   window.SUPABASE_URL = 'cole a Project URL aqui';
   window.SUPABASE_ANON_KEY = 'cole a chave anon aqui';
   ```

A partir daí, todo mundo que abrir o link publicado enxerga e edita o
mesmo quadro em tempo real.

> **Atualizando um banco que já existe:** rode `supabase/schema.sql` inteiro
> de novo no SQL Editor. Ele é seguro de repetir, não apaga nada, só
> acrescenta o que falta. Enquanto as colunas das aprovações não
> existirem, o quadro continua funcionando normal e aparece uma faixa no topo
> avisando; as aprovações ficam bloqueadas nesse período, porque aprovação que
> não salva é pior do que aprovação nenhuma. O mesmo vale para os anexos.
>
> O arquivo também cria o bucket **anexos** no Storage, que é onde os arquivos
> ficam. Se esse bloco falhar por falta de permissão, nada mais quebra: crie o
> bucket à mão em *Storage > New bucket*, com o nome `anexos` e a opção
> **Public** marcada. Sem ele dá para anexar por link, só não dá para subir
> arquivo, e a faixa no topo avisa.

### 2. Publicar num link fixo

Sem servidor próprio, sem build, é só hospedar o `index.html` (mais
`config.js`) como arquivo estático. Duas opções simples e gratuitas:

**GitHub Pages**
1. Crie um repositório no GitHub e suba este projeto:
   ```bash
   git remote add origin https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git
   git push -u origin master
   ```
2. Nas configurações do repositório, aba "Pages", selecione a branch
   `master` e a pasta raiz.
3. O link fica em `https://SEU-USUARIO.github.io/SEU-REPOSITORIO/`.

**Vercel ou Netlify**
1. Conecte o repositório do GitHub direto no painel do Vercel ou Netlify.
2. Não precisa configurar build nem comando de start, é um site estático.
3. Cada um desses serviços gera um link fixo próprio na hora.

### 3. Backup

O botão "Exportar backup" no rodapé continua funcionando mesmo com o
Supabase ligado, gerando um JSON com todos os cards e ideias, como
válvula de escape independente do banco.

## Estrutura

- `index.html`: aplicativo completo (interface, regras de negócio, camada
  de sincronização).
- `config.js`: credenciais do projeto Supabase.
- `supabase/schema.sql`: schema das tabelas, o bucket dos anexos, realtime e
  políticas de acesso.

## Relatório

Além dos modelos que já existiam, dois recortes novos: **Esperando aprovação**,
com o que está parado numa das travas, e **Passou sem aprovação**, com o que
andou sem alguém liberar. O resumo em números traz as duas contagens, e cada
conteúdo sai com a situação da aprovação e a leitura de resultado.
