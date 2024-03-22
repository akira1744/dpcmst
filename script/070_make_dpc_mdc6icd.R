################################################################################

# 作成日: 2023-12-20

# 作成者: inayoshi

################################################################################
# パッケージの読み込み
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

################################################################################

# データベースのpath
db_dpc <- 'output/dpcmst.sqlite'

# connect
con_dpc = dbConnect(SQLite(), db_dpc, synchronous="off")

# con_dpcのtable一覧を確認
dbListTables(con_dpc) %>% print()

################################################################################

# dpc_mdc6を読み込み
dpc_mdc6 <- dbReadTable(con_dpc, 'dpc_mdc6') %>% tibble() %>% glimpse()

dpc_mdc6 <- dpc_mdc6 %>% select(-mdc2cd)

# dpcmst_icdを読み込み
dpcmst_icd <- dbReadTable(con_dpc, 'dpcmst_mdc06_meisyo_icdcord') %>% tibble() %>% glimpse()

df <- dpcmst_icd %>% 
  rename(stymd=有効期間_開始日) %>% 
  glimpse()

# stymdからyear,monthを作成
df <- df %>% 
  mutate(
    stymd = ymd(stymd),
    year = year(stymd),
    month = month(stymd),
  ) %>% print()

# 年度としてdpcfy列を作成
df <- df %>% 
  mutate(
    dpcfy = case_when(
      month >= 4 ~ year,
      month < 4 ~ year - 1
    )
  ) %>% 
  glimpse()

# 確認
df %>% 
  count(stymd,dpcfy)

# 必要列を抽出
df <- df %>%
  mutate(mdc6cd = str_c(MDCコード,分類コード)) %>%
  select(
    dpcfy,
    mdc6cd,
    icd = ICDコード,
    icdname=ICD名称
  )

# U071が表記ブレしているので統一する
df <- df %>% 
  mutate(icdname = if_else(icd=='U071','COVID-19',icdname))

# icdとicdnameでユニークになることを確認
df %>% 
  distinct(icd,icdname) %>% 
  group_by(icd) %>% 
  filter(n()>1)

dpc_mdc6icd <- df %>% 
  left_join(dpc_mdc6,by=c('dpcfy','mdc6cd')) %>% 
  glimpse()

dpc_mdc6icd <- dpc_mdc6icd %>% 
  relocate(mdc6,.after=mdc6cd) %>%
  print()

# DBに書き出し
dbWriteTable(con_dpc, 'dpc_mdc6icd', dpc_mdc6icd, overwrite = T)




  
