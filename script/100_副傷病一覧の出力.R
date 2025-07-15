################################################################################

# 作成日: 2023-12-20

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

# 年度の設定
set_dpcfy <- 2024

# データベースのpath
db_dpc <- 'output/dpcmst.sqlite'

# connect
con_dpc = dbConnect(SQLite(), db_dpc, synchronous="off")

# dpc_mdc6icdを読み込み
dpc_mdc6 <- dbReadTable(con_dpc, 'dpc_mdc6') %>% tibble() 
dpc_mdc6 <- dpc_mdc6 %>% 
  filter(dpcfy==set_dpcfy) %>%
  select(-mdc2cd) %>% 
  glimpse()


# dpc_mdc6icdを読み込み
dpc_mdc6icd <- dbReadTable(con_dpc, 'dpc_mdc6icd') %>% tibble() 
dpc_mdc6icd <- dpc_mdc6icd %>% 
  filter(dpcfy==set_dpcfy) %>%
  glimpse()

# dpc_mdc6hukuを読み込み
dpc_mdc6huku <- dbReadTable(con_dpc, 'dpc_mdc6huku') %>% tibble() 

df <- dpc_mdc6huku %>% 
  filter(dpcfy==set_dpcfy) %>% 
  arrange(mdc6cd) %>% 
  glimpse()

unique_mdc6 <- unique(df$mdc6cd)

hukubunki_unique_mdc6<- df %>% 
  filter(hukubunki==1) %>% 
  distinct(mdc6cd) %>% 
  pull()

df <- df %>% 
  mutate(副傷病分岐 = if_else(mdc6cd %in% hukubunki_unique_mdc6,'あり','なし')) %>%
  arrange(mdc6cd) %>% 
  print()

df %>% 
  filter(副傷病分岐=='あり') %>% 
  print()

df <- df %>% 
  mutate(手術区分 = case_when(
    副傷病分岐 ==  'なし' ~ '共通',
    opeflag== 0 ~ '手術なし',
    opeflag== 1 ~ '手術あり',
  ))

df <- df %>%
  left_join(dpc_mdc6,by=c('dpcfy','mdc6cd')) %>%
  glimpse()


# 列名整理
out1 <- df %>% 
  arrange(mdc6cd,hukusyobyocd,手術区分,hukumdc6cd) %>% 
  select(
    DPC年度 = dpcfy,
    MDC6コード = mdc6cd,
    MDC6名称 = mdc6,
    副傷病分岐,
    手術区分,
    副傷病番号 = hukusyobyocd,
    副傷病MDC6 = hukumdc6cd,
    副傷病MDC6名称 = hukumdc6
  )


# mdc6icd

tmp <- dpc_mdc6icd %>% 
  select(-mdc6) %>% 
  rename(副傷病名ICD=icd) %>% 
  rename(副傷病名ICD名称=icdname) %>% 
  print()

out2 <- out1 %>% 
  left_join(tmp,by=c('DPC年度'='dpcfy','副傷病MDC6'='mdc6cd'))

outputpath <- str_c('output/DPC副傷病一覧_',set_dpcfy,'年度.xlsx') %>% print()

# Excel出力
list('1_副傷病名MDC6' = out1, '2_副傷病名ICD'=out2) %>% 
  write_xlsx(outputpath)

