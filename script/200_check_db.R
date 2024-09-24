################################################################################

# 作成日: 20240816

# 作成者: inayoshi

################################################################################

# パッケージの読み込み
pacman::p_load(
  lubridate, # 日付操作 
  readxl,
  writexl, # Excel出力 write_xlsx()
  DBI,
  RSQLite,
  tidyverse, # packageセット(ggplot2 tibble tidyr readr purrr dplyr stringr forcats)
  tidylog # tidyverseにlog出力機能追加
)

# 自作関数の読み込み
source('/home/rstudio/srv/function/index.R')

# function以外の変数を削除
clean_vars()

# データベースのpath
db_dpc <- 'output/dpcmst.sqlite'

# connect
con_dpc = dbConnect(SQLite(), db_dpc, synchronous="off")

DBI::dbListTables(con_dpc) %>% print() %>% dput()

################################################################################

dpc_mdc14 <- tbl(con_dpc,'dpc_mdc14') %>% collect() %>% glimpse()

dpc_mdc2 <- tbl(con_dpc,'dpc_mdc2') %>% collect() %>% glimpse()

dpc_mdc6 <- tbl(con_dpc,'dpc_mdc6') %>% collect() %>% glimpse()

dpc_mdc6huku <- tbl(con_dpc,'dpc_mdc6huku') %>% collect() %>% glimpse()

dpc_mdc6icd <- tbl(con_dpc,'dpc_mdc6icd') %>% collect() %>% glimpse()

dpc_opecdkname <- tbl(con_dpc,'dpc_opecdkname') %>% collect() %>% glimpse()

dpc_opecdopekb <- tbl(con_dpc,'dpc_opecdopekb') %>% collect() %>% glimpse()

dpc_syoti1 <- tbl(con_dpc,'dpc_syoti1') %>% collect() %>% glimpse()

dpc_syoti2 <- tbl(con_dpc,'dpc_syoti2') %>% collect() %>% glimpse()

dpc_mdc11_henkan_table <- tbl(con_dpc,'dpc_mdc11_henkan_table') %>% collect() %>% glimpse()

################################################################################

tbl(con_dpc,'dpc_syoti1') %>% collect() %>% count(syoti1cd)
tbl(con_dpc,'dpc_mdc14') %>% collect() %>% count(syoti1cd)

tbl(con_dpc,'dpc_syoti2') %>% collect() %>%  count(syoti2cd)
tbl(con_dpc,'dpc_mdc14') %>% collect() %>% count(syoti2cd)

################################################################################

