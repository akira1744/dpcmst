################################################################################

# 作成日: 20241105

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

DBI::dbListTables(con_dpc) %>% print() 

mdc11_henkan_table <- tbl(con_dpc, 'dpc_mdc11_henkan_table') %>% 
  collect() %>% 
  print()

tbl(con_dpc, 'dpc_mdc14') %>% glimpse()

mdc14 <- tbl(con_dpc, 'dpc_mdc14') %>% 
  select(dpcfy,mdc14cd,mdc6,opecd,opekb,syoti1cd,syoti1kb,kikan1,kikan2,kikan3,kikan1ten,kikan2ten,kikan3ten,包括フラグ) %>% 
  collect() %>% 
  print()

df <- mdc11_henkan_table %>% 
  left_join(mdc14,by=c('dpcfy','mdc14cd')) %>% 
  glimpse()

df %>% names() %>% dput()

df_long <- df %>% 
  select(
    DPC年度="dpcfy",
    DPC疾患コード="mdc6cd",
    DPC疾患名 ="mdc6",
    DPC病態等分類コード="mdc7cd",
    DPC年齢出生時体重等コード = "mdc8cd",
    手術_会計コード="kcode",
    手術_DPCコード="opecd",
    手術_DPC名称 = "opekb",
    手術処置1_会計コード = "syoti1_kcode", 
    手術処置1_DPCコード = "syoti1cd",
    手術処置1_DPC名称="syoti1kb",
    DPCコード= "mdc14cd",
    DPC期間1 = "kikan1",
    DPC期間2 = "kikan2",
    DPC期間3 = "kikan3", 
    DPC期間1点数 = "kikan1ten",
    DPC期間2点数 = "kikan2ten",
    DPC期間3点数 = "kikan3ten",
    "包括フラグ"
) %>% 
  glimpse()

df_wide <- df_long %>% 
  mutate(DPC年度 = str_glue('DPC期間2_{DPC年度}')) %>% 
  select(DPC疾患コード,DPC疾患名,DPC病態等分類コード,DPC年齢出生時体重等コード,手術_会計コード,手術_DPC名称,手術処置1_会計コード,手術処置1_会計コード,DPC年度,DPC期間2) %>% 
  pivot_wider(
    id_cols=c(DPC疾患コード,DPC疾患名,DPC病態等分類コード,DPC年齢出生時体重等コード,手術_会計コード,手術処置1_会計コード,手術処置1_会計コード)
    ,names_from='DPC年度'
    ,values_from='DPC期間2'
  ) %>% 
  glimpse()

list(
  'DPC変換テーブル_手術_手術処置1' = df_long,
  'DPC期間2の経年比較_疾患別手術別手術処置1別' = df_wide
) %>% 
  write_xlsx('output/tmp/DPC期間2の経年比較_DPC期間2の経年比較_疾患別手術別手術処置1別.xlsx')
