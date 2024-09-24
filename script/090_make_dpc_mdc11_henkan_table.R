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

DBI::dbListTables(con_dpc) %>% print() 

# 変換テーブル
henkan_table <- tbl(con_dpc,'dpcmst_henkan_table') %>%
  # filter(有効期間_開始日=='20180401') %>% 
  collect() %>% 
  glimpse()

# 変換テーブルの必要列だけ抽出
henkan_table <- henkan_table %>% 
  mutate(dpcfy = str_sub(有効期間_開始日,1,4)) %>% 
  mutate(dpcfy = as.numeric(dpcfy)) %>% 
  rename(
    dpc=診断群分類番号
    ,opecd=手術
    ,syoti1cd = 手術_処置等1
  ) %>% 
  mutate(mdc6cd = str_sub(dpc,1,6)) %>% 
  mutate(mdc7cd = str_sub(dpc,7,7)) %>% 
  mutate(mdc8cd = str_sub(dpc,8,8)) %>% 
  select(dpcfy,dpc,mdc6cd,mdc7cd,mdc8cd,opecd,syoti1cd) %>% 
  glimpse()


# 変換テーブルをmdc6cdとopecdとsyoti1cdでdistinctする(dpcの昇順にして上を残す)
henkan_table_distinct <- henkan_table %>% 
  arrange(dpcfy,mdc6cd,mdc7cd,mdc8cd,opecd,syoti1cd,dpc) %>% 
  distinct(dpcfy,mdc6cd,mdc7cd,mdc8cd,opecd,syoti1cd,.keep_all=T) %>% 
  print()

# 変換テーブルのMDCと分類コードを結合したものとmdc6cd
dpc_mdc6 <- tbl(con_dpc,"dpc_mdc6") %>% 
  # filter(dpcfy==2018) %>% 
  select(dpcfy,mdc6cd,mdc6) %>% 
  collect() %>%
  glimpse()

# 変換tableの手術とopecd
dpc_opecdkname <- tbl(con_dpc,'dpc_opecdkname') %>%
  # filter(dpcfy==2018) %>% 
  collect() %>%
  glimpse()

# 変換tableの手術_処置等1とsyoti1cd
dpc_syoti1 <- tbl(con_dpc,'dpc_syoti1') %>%
  # filter(dpcfy==2018) %>% 
  collect() %>%
  glimpse()

my_henkan_table <- henkan_table_distinct %>% 
  left_join(dpc_mdc6,by=c('dpcfy','mdc6cd')) %>% 
  print()

my_henkan_table <- my_henkan_table %>% 
  left_join(dpc_opecdkname,by=c('dpcfy','mdc6cd','opecd')) %>% 
  print()

my_henkan_table <- my_henkan_table %>% 
  left_join(dpc_syoti1,by=c('dpcfy','mdc6cd','syoti1cd')) %>% 
  print()

my_henkan_table <- my_henkan_table %>% 
  replace_na(list(syoti1_kcode='',syoti1_kname=''))

# 問題があったくみあわせ２→手直しが必要
my_henkan_table %>% 
  filter(mdc6cd=='050210',syoti1cd=='0') 

my_henkan_table %>% 
  glimpse()

my_henkan_table %>% 
  distinct(dpcfy,mdc6cd,kcode,syoti1_kcode)

my_henkan_table %>% 
  filter(dpcfy==2024,mdc6cd=='050161')

# 処置1のdpccodeが0なのに、syoti1にkcodeが入っているものがある
# 2024年を確認したところ、分岐がなくなって※印がついているものだった。
# 2022年は・・・・
# kcodeなしというマスタを作る必要があるので、抜粋してhenkan_tableにrbindすることにする
syoti1_hokan <- my_henkan_table %>% 
  filter(syoti1cd=='0') %>% 
  mutate(syoti1_kcode='') %>% 
  mutate(syoti1_kname='') %>% 
  print()

my_henkan_table_hokan <- rbind(my_henkan_table,syoti1_hokan)

my_henkan_table_hokan <- my_henkan_table_hokan %>% 
  distinct(dpcfy,mdc6cd,mdc7cd,mdc8cd,kcode,syoti1_kcode,.keep_all=T)

my_henkan_table_hokan %>% 
  filter(dpcfy==2024,mdc6cd=='050161',syoti1_kcode=='')

my_henkan_table_hokan %>% 
  filter(syoti1cd=='0') %>% 
  filter(mdc6cd=='050210') 

my_henkan_table_hokan %>% 
  filter(dpcfy==2022) %>% 
  filter(mdc6cd=='110200') 

my_henkan_table_hokan %>% 
  glimpse()

my_henkan_table_hokan <- my_henkan_table_hokan %>% 
  select(dpcfy,mdc6cd,mdc7cd,mdc8cd,kcode,syoti1_kcode,mdc14cd=dpc) %>% 
  print()

dbWriteTable(con_dpc, 'dpc_mdc11_henkan_table', my_henkan_table_hokan, overwrite = T)
