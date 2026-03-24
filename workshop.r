# Databricks notebook source
# MAGIC %md
# MAGIC # ⚡ Workshop: Dominando R no Databricks
# MAGIC
# MAGIC Bem-vindo ao workshop de R no Databricks! Hoje vamos explorar como utilizar a linguagem R para manipular dados, interagir com o Unity Catalog, acessar arquivos em Volumes e WFS (Workspace File System), construir visualizações e criar dashboards interativos com Shiny.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 0: Configuração de Variáveis (Widgets)
# MAGIC Para que cada participante não sobrescreva os dados dos colegas, vamos criar variáveis (Widgets) no topo do notebook. 
# MAGIC
# MAGIC **O que são widgets?**  
# MAGIC Widgets permitem criar campos interativos no notebook para receber valores do usuário, como o nome do esquema ou prefixo. Assim, cada participante pode personalizar e isolar seus dados durante o workshop.
# MAGIC
# MAGIC **Instrução:** Preencha os campos lá no topo da tela com o seu esquema (schema) de trabalho e as suas iniciais (prefixo).

# COMMAND ----------

# Define os widgets padrão para a sessão
dbutils.widgets.text("catalog_name", "main")
dbutils.widgets.text("schema_name", "default")
dbutils.widgets.text("prefix_table", "user01")

# COMMAND ----------

# Recebe os valores dos widgets como parâmetros
catalog_name <- dbutils.widgets.get("catalog_name")
schema_name <- dbutils.widgets.get("schema_name")
prefix <- dbutils.widgets.get("prefix_table")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 1: Criação de Tabelas com SQL (Unity Catalog)
# MAGIC Vamos criar nosso modelo de dados. Usaremos células SQL acessando as variáveis que acabamos de criar.
# MAGIC Criaremos duas tabelas relacionais: `power_plants` (usinas de energia) e `energy_production` (produção diária).

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Cria as tabelas utilizando o prefixo do participante
# MAGIC CREATE TABLE IF NOT EXISTS ${catalog_name}.${schema_name}.${prefix}_power_plants (
# MAGIC   plant_id INT,
# MAGIC   plant_name STRING,
# MAGIC   plant_type STRING,
# MAGIC   capacity_mw DOUBLE
# MAGIC );
# MAGIC
# MAGIC CREATE TABLE IF NOT EXISTS ${catalog_name}.${schema_name}.${prefix}_energy_production (
# MAGIC   log_id INT,
# MAGIC   plant_id INT,
# MAGIC   date DATE,
# MAGIC   mwh_produced DOUBLE
# MAGIC );
# MAGIC
# MAGIC -- Inserindo dados de exemplo (máx 100 linhas simuladas)
# MAGIC TRUNCATE TABLE ${catalog_name}.${schema_name}.${prefix}_power_plants;
# MAGIC INSERT INTO ${catalog_name}.${schema_name}.${prefix}_power_plants VALUES 
# MAGIC   (1, 'Solar Alpha', 'Solar', 150.0),
# MAGIC   (2, 'Wind Beta', 'Wind', 200.0),
# MAGIC   (3, 'Hydro Gamma', 'Hydro', 500.0);
# MAGIC
# MAGIC TRUNCATE TABLE ${catalog_name}.${schema_name}.${prefix}_energy_production;
# MAGIC INSERT INTO ${catalog_name}.${schema_name}.${prefix}_energy_production VALUES 
# MAGIC   -- Completando o dia 2023-10-02 para a planta 3
# MAGIC   (106, 3, '2023-10-02', 485.5),
# MAGIC
# MAGIC   -- Registros do dia 2023-10-03 em diante
# MAGIC   (107, 1, '2023-10-03', 135.2),
# MAGIC   (108, 2, '2023-10-03', 190.1),
# MAGIC   (109, 3, '2023-10-03', 475.8),
# MAGIC
# MAGIC   (110, 1, '2023-10-04', 140.0),
# MAGIC   (111, 2, '2023-10-04', 185.5),
# MAGIC   (112, 3, '2023-10-04', 480.2),
# MAGIC
# MAGIC   (113, 1, '2023-10-05', 128.4),
# MAGIC   (114, 2, '2023-10-05', 170.9),
# MAGIC   (115, 3, '2023-10-05', 495.0),
# MAGIC
# MAGIC   (116, 1, '2023-10-06', 145.1),
# MAGIC   (117, 2, '2023-10-06', 198.0),
# MAGIC   (118, 3, '2023-10-06', 460.5),
# MAGIC
# MAGIC   (119, 1, '2023-10-07', 110.5),
# MAGIC   (120, 2, '2023-10-07', 160.2),
# MAGIC   (121, 3, '2023-10-07', 485.0),
# MAGIC
# MAGIC   (122, 1, '2023-10-08', 132.3),
# MAGIC   (123, 2, '2023-10-08', 182.4),
# MAGIC   (124, 3, '2023-10-08', 490.1),
# MAGIC
# MAGIC   (125, 1, '2023-10-09', 148.0),
# MAGIC   (126, 2, '2023-10-09', 192.5),
# MAGIC   (127, 3, '2023-10-09', 478.9),
# MAGIC
# MAGIC   (128, 1, '2023-10-10', 125.6),
# MAGIC   (129, 2, '2023-10-10', 175.3),
# MAGIC   (130, 3, '2023-10-10', 488.0),
# MAGIC
# MAGIC   (131, 1, '2023-10-11', 138.9),
# MAGIC   (132, 2, '2023-10-11', 188.8),
# MAGIC   (133, 3, '2023-10-11', 492.5),
# MAGIC
# MAGIC   (134, 1, '2023-10-12', 142.0),
# MAGIC   (135, 2, '2023-10-12', 195.0),
# MAGIC   (136, 3, '2023-10-12', 481.4),
# MAGIC
# MAGIC   (137, 1, '2023-10-13', 115.8),
# MAGIC   (138, 2, '2023-10-13', 165.7),
# MAGIC   (139, 3, '2023-10-13', 470.2),
# MAGIC
# MAGIC   (140, 1, '2023-10-14', 130.4),
# MAGIC   (141, 2, '2023-10-14', 178.6),
# MAGIC   (142, 3, '2023-10-14', 495.8),
# MAGIC
# MAGIC   (143, 1, '2023-10-15', 144.5),
# MAGIC   (144, 2, '2023-10-15', 190.0),
# MAGIC   (145, 3, '2023-10-15', 484.3),
# MAGIC
# MAGIC   (146, 1, '2023-10-16', 122.1),
# MAGIC   (147, 2, '2023-10-16', 185.2),
# MAGIC   (148, 3, '2023-10-16', 477.7),
# MAGIC
# MAGIC   (149, 1, '2023-10-17', 136.7),
# MAGIC   (150, 2, '2023-10-17', 193.4),
# MAGIC   (151, 3, '2023-10-17', 489.9),
# MAGIC
# MAGIC   (152, 1, '2023-10-18', 141.2),
# MAGIC   (153, 2, '2023-10-18', 180.1),
# MAGIC   (154, 3, '2023-10-18', 491.0),
# MAGIC
# MAGIC   (155, 1, '2023-10-19', 139.5);

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 2: Criação de um Volume no Unity Catalog
# MAGIC Volumes são locais gerenciados pelo Unity Catalog para armazenar arquivos não-tabulares (como CSVs, imagens, PDFs). Vamos criar um Volume com o seu prefixo.

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE VOLUME IF NOT EXISTS ${catalog_name}.${schema_name}.${prefix}_volume;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 3: R, WFS e Volumes
# MAGIC O Databricks possui o Workspace File System (WFS), onde os arquivos ficam junto ao seu notebook. Mas, para governança, o ideal é usar Volumes.
# MAGIC Vamos gerar um dataframe falso em R com dados geográficos, salvá-lo nos dois locais, ler e validar.

# COMMAND ----------

library(readr)

# Recupera variáveis do Databricks para usar no R
catalog <- dbutils.widgets.get("catalog_name")
schema <- dbutils.widgets.get("schema_name")
prefix <- dbutils.widgets.get("prefix_table")

# 1. Gerando dados fictícios em R
set.seed(42)
plant_ids <- 1:3
dates <- seq.Date(as.Date("2023-10-01"), as.Date("2023-10-10"), by = "day")
df_geo <- expand.grid(plant_id = plant_ids, date = dates)
df_geo$avg_consumption_kwh <- runif(nrow(df_geo), 100, 500)
df_geo$lat <- runif(nrow(df_geo), -23.5, -22.5)
df_geo$long <- runif(nrow(df_geo), -44.0, -43.0)

# 2. Definindo caminhos
wfs_path <- paste0(prefix, "_geo_data.csv") # Salva na mesma pasta do notebook
volume_path <- paste0("/Volumes/", catalog, "/", schema, "/", prefix, "_volume/geo_data.csv")

# 3. Escrevendo os arquivos
write_csv(df_geo, wfs_path)
write_csv(df_geo, volume_path)

# 4. Lendo os arquivos
read_wfs <- read_csv(wfs_path, show_col_types = FALSE)
read_vol <- read_csv(volume_path, show_col_types = FALSE)

print("Dados lidos do WFS:")
print(head(read_wfs, 3))

print("Dados lidos do Volume do Unity Catalog:")
print(head(read_vol, 3))

# Exibindo para o Databricks renderizar nativamente
display(read_wfs)

# COMMAND ----------

# MAGIC %md
# MAGIC ### 🗺️ Exercício: Visualização em Mapa (Databricks Visualizations)
# MAGIC
# MAGIC O Databricks possui uma ferramenta nativa incrível para gráficos sem precisar codificar!
# MAGIC 1. Na saída da célula anterior (onde está o dataframe), clique no botão **`+`** (ao lado de "Table").
# MAGIC 2. Selecione **Visualization**.
# MAGIC 3. Em *Visualization Type*, escolha **Map**.
# MAGIC 4. Em *Latitude*, selecione a coluna `lat`. Em *Longitude*, selecione `long`.
# MAGIC 5. Salve! Agora você tem um mapa interativo nativo do Databricks.
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC ### 📈 Exercício: Gráfico de Linha Temporal (Databricks Visualizations)
# MAGIC
# MAGIC Para criar um gráfico de linha mostrando o consumo médio ao longo do tempo:
# MAGIC 1. Na saída da célula anterior, clique no botão **`+`** (ao lado de "Table").
# MAGIC 2. Selecione **Visualization**.
# MAGIC 3. Em *Visualization Type*, escolha **Line**.
# MAGIC 4. Em *X-Axis*, selecione a coluna `date`.
# MAGIC 5. Em *Group By*, selecione a coluna `plant_id`.
# MAGIC 6. Em *Y-Axis*, selecione a coluna `avg_consumption_kwh`.
# MAGIC 7. Salve! Agora você tem um gráfico temporal agrupado por usina mostrando o consumo médio.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 4: Sparklyr e Processamento de Big Data
# MAGIC O R puro roda apenas no nó driver (Driver Node). Para analisar bilhões de linhas de forma distribuída, usamos o **Sparklyr**. Vamos conectar ao Spark, ler nossas tabelas criadas no Passo 1, cruzá-las (`join`) e salvar o resultado no Unity Catalog.

# COMMAND ----------

library(sparklyr)

catalog <- dbutils.widgets.get("catalog_name")
schema <- dbutils.widgets.get("schema_name")
prefix <- dbutils.widgets.get("prefix_table")

# Conecta ao cluster Spark do Databricks
sc <- spark_connect(method = "databricks")

table_plants <- paste0(catalog, ".", schema, ".", prefix, "_power_plants")
table_prod <- paste0(catalog, ".", schema, ".", prefix, "_energy_production")

# Apontando para as tabelas no cluster (Lazy Evaluation)
plants_tbl <- tbl(sc, table_plants)
prod_tbl <- tbl(sc, table_prod)

# Análise de dados distribuída usando verbos do dplyr
results_tbl <- plants_tbl %>%
  inner_join(prod_tbl, by = "plant_id") %>%
  group_by(plant_type) %>%
  summarise(
    total_mwh = sum(mwh_produced, na.rm = TRUE),
    avg_mwh_per_day = mean(mwh_produced, na.rm = TRUE)
  ) %>%
  arrange(desc(total_mwh))

# Salvando a tabela processada de volta no Unity Catalog
output_table_name <- paste0(catalog, ".", schema, ".", prefix, "_results")
spark_write_table(results_tbl, name = output_table_name, mode = "overwrite")

display(results_tbl)

# COMMAND ----------

# DBTITLE 1,Passo 4.1 Sparklyr vs Dplyr
# MAGIC %md
# MAGIC ### 🔎 Passo 4.1 (Opcional): Sparklyr vs Dplyr — Qual a diferença?
# MAGIC
# MAGIC Ambas as bibliotecas usam os **mesmos verbos** (`filter`, `select`, `mutate`, `group_by`, `summarise`...), mas rodam em contextos completamente diferentes:
# MAGIC
# MAGIC | Característica | **dplyr** (R puro) | **sparklyr** (Spark) |
# MAGIC | --- | --- | --- |
# MAGIC | **Onde roda** | Memória do Driver (máquina local) | Cluster distribuído (Spark) |
# MAGIC | **Tipo do objeto** | `data.frame` / `tibble` | `tbl_spark` (referência lazy) |
# MAGIC | **Escala** | Milhares a milhões de linhas | Bilhões de linhas |
# MAGIC | **Execução** | Imediata (eager) | Preguiçosa (lazy) — só executa no `collect()` ou `display()` |
# MAGIC | **Fonte dos dados** | CSVs, dataframes em memória | Tabelas Delta no Unity Catalog, Parquet, etc. |
# MAGIC
# MAGIC #### Lazy Evaluation no Sparklyr
# MAGIC Quando você escreve `plants_tbl %>% filter(capacity_mw > 100)`, o Spark **não executa nada ainda**. Ele monta um plano de execução (DAG). A query só roda de fato quando você chama `collect()`, `display()` ou `spark_write_table()`. Isso permite ao Spark otimizar toda a cadeia de transformações antes de processar.
# MAGIC
# MAGIC #### Verbos em comum (mesma sintaxe, engine diferente)
# MAGIC ```r
# MAGIC # Funciona IGUAL no dplyr e no sparklyr:
# MAGIC df %>% filter(plant_type == "Solar")
# MAGIC df %>% select(plant_id, capacity_mw)
# MAGIC df %>% mutate(capacity_gw = capacity_mw / 1000)
# MAGIC df %>% group_by(plant_type) %>% summarise(total = sum(mwh_produced))
# MAGIC df %>% arrange(desc(total_mwh))
# MAGIC ```
# MAGIC
# MAGIC #### Funções exclusivas do Sparklyr
# MAGIC O sparklyr oferece funções que não existem no dplyr, pois lidam com o cluster Spark:
# MAGIC * `spark_connect()` — conecta ao cluster
# MAGIC * `tbl()` — aponta para uma tabela no catálogo (lazy)
# MAGIC * `sdf_nrow()` — conta linhas de forma distribuída
# MAGIC * `sdf_schema()` — retorna o schema da tabela Spark
# MAGIC * `spark_write_table()` — salva o resultado como tabela Delta no Unity Catalog
# MAGIC * `collect()` — traz os dados do cluster para a memória local do R
# MAGIC
# MAGIC > **💡 Regra de ouro:** Use **dplyr** para dados que cabem na memória (CSVs pequenos, resultados coletados). Use **sparklyr** para dados grandes que vivem no Unity Catalog.

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 5: R e Dplyr com Arquivos
# MAGIC Para bases de dados pequenas ou arquivos CSV no WFS que cabem na memória, o `dplyr` tradicional funciona perfeitamente sem o overhead do Spark. Vamos calcular algumas estatísticas descritivas do nosso arquivo geográfico. Se você for utilizar somente o Dplyr, você pode ter um cluster single node.

# COMMAND ----------

library(dplyr)
library(readr)

# Lendo o CSV gerado no passo 3 (R local)

catalog_name <- dbutils.widgets.get("catalog_name")
schema_name <- dbutils.widgets.get("schema_name")
prefix <- dbutils.widgets.get("prefix_table")

df_local <- read_csv(wfs_path, show_col_types = FALSE)

# Análise descritiva da média de consumo
resumo_estatistico <- df_local %>%
  summarise(
    Media_Consumo = mean(avg_consumption_kwh),
    Mediana_Consumo = median(avg_consumption_kwh),
    Consumo_Maximo = max(avg_consumption_kwh),
    Desvio_Padrao = sd(avg_consumption_kwh)
  )

print("Resumo Estatístico do Consumo Geográfico:")
print(resumo_estatistico)

# COMMAND ----------

# MAGIC %md
# MAGIC # (Opcional) Passo 6: Acessando tabelas via Databricks SQL Warehouse
# MAGIC
# MAGIC Além do Sparklyr, você pode acessar tabelas do Unity Catalog usando Databricks SQL Warehouse.
# MAGIC
# MAGIC O pacote DBI permite executar queries SQL diretamente no Warehouse, trazendo resultados para o R.

# COMMAND ----------

library(DBI)

# Parâmetro: nome do warehouse
warehouse_name <- "warehouse_name"

# Conectando ao Databricks SQL Warehouse (sem token, usando contexto do notebook)
con <- dbConnect(
  odbc::odbc(),
  Driver = "Databricks",
  Warehouse = warehouse_name
)

# Consulta SQL: lê a tabela de resultados criada no Passo 4
catalog <- dbutils.widgets.get("catalog_name")
schema <- dbutils.widgets.get("schema_name")
prefix <- dbutils.widgets.get("prefix_table")
table_name <- paste0(catalog, ".", schema, ".", prefix, "_results")

query <- paste0("SELECT * FROM ", catalog, ".", schema, ".", prefix, "_energy_production LIMIT 10")

# Executa a query e traz os dados para o R
df_results <- dbGetQuery(con, query)

# Exibe os primeiros registros
print(head(df_results, 3))

# Fecha a conexão
dbDisconnect(con)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 7: Aplicativos Shiny no Databricks
# MAGIC Você pode rodar aplicativos **Shiny** diretamente nas células do notebook! 
# MAGIC
# MAGIC O código abaixo inicializa um servidor local. Um link ou janela aparecerá permitindo que você visualize a aplicação em execução.

# COMMAND ----------

library(shiny)
library(ggplot2)
library(dplyr)
library(sparklyr)

# Recupera o ambiente Spark e as variáveis
sc <- spark_connect(method = "databricks")
tbl_name <- paste0(catalog, ".", schema, ".", prefix, "_results")

# Interface de Usuário
ui <- fluidPage(
  titlePanel("Dashboard de Geração de Energia ⚡"),
  sidebarLayout(
    sidebarPanel(
      h4("Filtros"),
      selectInput("type", "Selecione o Tipo de Usina:", choices = c("Solar", "Wind", "Hydro", "All")),
      p("Este app lê dados do Unity Catalog via Sparklyr.")
    ),
    mainPanel(
      plotOutput("energyPlot")
    )
  )
)

# Servidor (Lógica)
server <- function(input, output) {
  
  # Reactive block para buscar dados
  dados_plot <- reactive({
    dados <- tbl(sc, tbl_name) %>% collect() # Traz para a memória local para o Shiny plotar
    
    if(input$type != "All") {
      dados <- dados %>% filter(plant_type == input$type)
    }
    return(dados)
  })
  
  output$energyPlot <- renderPlot({
    df <- dados_plot()
    
    ggplot(df, aes(x = plant_type, y = total_mwh, fill = plant_type)) +
      geom_bar(stat = "identity", width = 0.5) +
      theme_minimal() +
      labs(title = "Produção Total de Energia por Tipo de Usina (MWh)",
           x = "Tipo de Usina",
           y = "Total Produzido") +
      scale_fill_brewer(palette = "Set2")
  })
}

# Roda o App - Ele abrirá em uma aba separada do seu navegador (ou pop-up)
shinyApp(ui = ui, server = server)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 8: Upload Manual de CSV e Criação de Tabela no Unity Catalog
# MAGIC
# MAGIC Faça upload do arquivo CSV manualmente:
# MAGIC
# MAGIC    - Clique em "Add Data" (Adicionar Dados) no menu lateral do Databricks.
# MAGIC    - Selecione "Upload File" e escolha seu arquivo CSV.
# MAGIC    - O arquivo será salvo em `/tmp/` ou em um caminho acessível via `dbutils.fs`.
# MAGIC    - Após o upload, copie o caminho do arquivo exibido (ex: `/tmp/seu_arquivo.csv`).
# MAGIC    - **Não esqueça de adicionar ao nome da tabela o prefixo do seu nome**
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC > O código abaixo cria as tabelas de forma programática a partir dos arquivos CSV existentes, utilizando Sparklyr e salvando no Unity Catalog.

# COMMAND ----------

library(sparklyr)
library(readr)
library(dplyr)

# Recupera variáveis dos widgets
catalog <- dbutils.widgets.get("catalog_name")
schema <- dbutils.widgets.get("schema_name")
prefix <- dbutils.widgets.get("prefix_table")

# Conecta ao cluster Spark
sc <- spark_connect(method = "databricks")

# Caminhos dos arquivos CSV (ajuste se necessário)
plant_path <- "plant.csv"
consumo_path <- "historico_consumo.csv"
manutencao_path <- "historico_manutencao.csv"

# Lê os arquivos CSV em R
df_plant <- read_csv(plant_path, show_col_types = FALSE)
df_consumo <- read_csv(consumo_path, show_col_types = FALSE)
df_manutencao <- read_csv(manutencao_path, show_col_types = FALSE)

# Copia para Spark
plant_tbl <- copy_to(sc, df_plant, paste0(prefix, "_plant"), overwrite = TRUE)
consumo_tbl <- copy_to(sc, df_consumo, paste0(prefix, "_historico_consumo"), overwrite = TRUE)
manutencao_tbl <- copy_to(sc, df_manutencao, paste0(prefix, "_historico_manutencao"), overwrite = TRUE)

# Salva como tabelas Delta no Unity Catalog
spark_write_table(plant_tbl, name = paste0(catalog, ".", schema, ".", prefix, "_plant"), mode = "overwrite")
spark_write_table(consumo_tbl, name = paste0(catalog, ".", schema, ".", prefix, "_historico_consumo"), mode = "overwrite")
spark_write_table(manutencao_tbl, name = paste0(catalog, ".", schema, ".", prefix, "_historico_manutencao"), mode = "overwrite")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Passo 9: Criando uma Sala Genie no Databricks
# MAGIC
# MAGIC ### O que é o Genie?
# MAGIC O Genie é uma ferramenta de IA generativa no Databricks que permite criar "salas" para análise conversacional de dados. Você pode conectar tabelas do Unity Catalog e fazer perguntas em linguagem natural, obtendo respostas, gráficos e insights instantâneos.
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC ### Como criar uma sala Genie
# MAGIC
# MAGIC 1. **Abra o Genie**
# MAGIC    - No menu lateral do Databricks, clique em **Genie**.
# MAGIC
# MAGIC 2. **Crie uma nova sala**
# MAGIC    - Clique em **Create Room** ou **Nova Sala**. O nome da sala deve ser **prefixo_sala_genie**.
# MAGIC
# MAGIC 3. **Adicione as tabelas**
# MAGIC    - Na etapa de configuração, selecione as tabelas do Unity Catalog:
# MAGIC      - `prefixo_plant`
# MAGIC      - `prefixo_historico_consumo`
# MAGIC      - `prefixo_historico_manutencao`
# MAGIC    - Use o seu prefixo definido nos widgets (ex: `joao_plant`, `joao_historico_consumo`, etc.).
# MAGIC
# MAGIC 4. **Configure permissões**
# MAGIC    - Defina quem pode acessar a sala (público, privado ou restrito ao seu grupo).
# MAGIC
# MAGIC 5. **Finalize e entre na sala**
# MAGIC    - Clique em **Create**. Agora você pode conversar com o Genie sobre seus dados.
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC
# MAGIC ### Sugestões de perguntas para o Genie
# MAGIC
# MAGIC - Qual a capacidade instalada de cada usina (`capacity_mw`)?
# MAGIC - Mostre o consumo médio (`avg_consumption_kwh`) por usina.
# MAGIC - Descreva os datasets da sala, faça uma análise estatística simples.
# MAGIC - Qual foi o consumo máximo registrado por cada usina?
# MAGIC - Quais datas tiveram manutenção programada e qual o status?
# MAGIC - Existe correlação entre o status de manutenção e o consumo?
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC > **Dica:** Use perguntas claras e mencione o nome das tabelas conforme seu prefixo para melhores resultados!

# COMMAND ----------

# MAGIC %md
# MAGIC # Passo 10: Dashboards com AI/BI e Linguagem Natural
# MAGIC
# MAGIC O Databricks permite criar dashboards interativos com recursos de IA, como Genie e Databricks AI.
# MAGIC Você pode explorar dados, gerar gráficos e obter insights usando perguntas em linguagem natural, sem precisar de código SQL.
# MAGIC
# MAGIC Exemplos de perguntas para dashboards AI/BI:
# MAGIC - "Crie um gráfico de barras mostrando a produção total por tipo de usina."
# MAGIC - Quantas usinas existem por tipo (plant_type)
# MAGIC - Nos meses em que uma usina teve manutenção, qual foi a queda percentual na energia produzida comparado aos meses sem manutenção? 
# MAGIC - "Mostre a tendência de consumo ao longo do tempo."
# MAGIC
# MAGIC Com AI/BI, qualquer usuário pode analisar dados de forma intuitiva, democratizando o acesso e acelerando a tomada de decisão.

# COMMAND ----------

# MAGIC %md
# MAGIC ### Dica Pro: Modo Agent do Genie para Dashboards AI/BI
# MAGIC
# MAGIC O **AI/BI Dashboard** possui um recurso poderoso chamado **Genie Agent Mode**. Com ele, você pode criar **múltiplos gráficos e visualizações de uma só vez**, simplesmente descrevendo a história que deseja contar com os dados.
# MAGIC
# MAGIC Em vez de criar cada gráfico manualmente, você descreve o panorama completo em linguagem natural e o agente gera automaticamente:
# MAGIC * Queries SQL otimizadas para cada visualização
# MAGIC * Gráficos organizados em tabs ou seções
# MAGIC * Títulos e formatações adequados ao contexto
# MAGIC
# MAGIC #### Como usar
# MAGIC
# MAGIC 1. Abra um **Dashboard AI/BI** (novo ou existente)
# MAGIC 2. Ative o modo **Agent** (ícone de IA no editor)
# MAGIC 3. Descreva o que você quer ver — seja específico sobre agrupamentos, métricas e organização
# MAGIC
# MAGIC #### Exemplo de prompt
# MAGIC
# MAGIC > *"Popule o dashboard dividindo em duas tabs: **Estatísticas de Consumo** (evolução mensal de energia produzida e consumo interno por usina, top 5 usinas por produção total, e distribuição do consumo interno) e **Estatísticas de Manutenção** (custo total por motivo de manutenção, duração média por usina, e frequência de manutenções ao longo do tempo)."*
# MAGIC
# MAGIC > *"popule o dashboard dividindo em duas tabs estatisticas de consumo e estatisticas de manutencao."*
# MAGIC
# MAGIC Com um único prompt, o agente cria todas as visualizações organizadas nas tabs solicitadas — economizando tempo e garantindo consistência na análise.
# MAGIC
# MAGIC > **Dica:** Quanto mais detalhado o prompt (métricas, agrupamentos, tipo de gráfico), melhores serão os resultados gerados pelo agente.

# COMMAND ----------

# MAGIC %md
# MAGIC