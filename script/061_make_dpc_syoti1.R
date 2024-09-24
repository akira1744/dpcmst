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

################################################################################

# 手術
dpcmst_syoti1 <- tbl(con_dpc,'dpcmst_syoti1') %>% 
  collect() %>% 
  glimpse()

# 列名整理
dpcmst_syoti1 <- dpcmst_syoti1 %>% 
  mutate(mdc6cd = str_c(MDCコード,分類コード)) %>% 
  rename(
    syoti1cd=対応コード
    ,stymd = 有効期間_開始日
    ,enymd = 有効期間_終了日
  ) %>% 
  glimpse()

# NAを空文字で埋める 
dpcmst_syoti1 <- dpcmst_syoti1 %>%
  mutate(across(everything(), ~replace_na(., ''))) %>%
  glimpse()

# *で文字列結合して、末尾の+を削除
dpcmst_syoti1 <- dpcmst_syoti1 %>% 
  mutate(
    syoti1_kname = str_c(処置等1_名称,処置2_名称,sep = '＋'),
    syoti1_kcode = str_c(処置等1_コード,処置2_コード,手術との組み合わせ条件,sep = '＋')
  ) %>%
  mutate(
    syoti1_kname = str_remove(syoti1_kname,'[＋]*$'),
    syoti1_kcode = str_remove(syoti1_kcode,'[＋]*$')) %>% 
  glimpse()
  
# 確認
dpcmst_syoti1 %>% 
  filter(str_detect(syoti1_kname,'＋')) %>% 
  glimpse()

# stymdからyear,monthを作成
dpcmst_syoti1 <- dpcmst_syoti1 %>% 
  mutate(stymd=ymd(stymd)) %>% 
  mutate(year = year(stymd),
         month = month(stymd)) %>% 
  glimpse()

# fyを作成
dpcmst_syoti1 <- dpcmst_syoti1 %>% 
  mutate(fy = if_else(month >= 4,year,year-1)) %>% 
  glimpse()

# fyが奇数の時は-1してdpcfyを作成
dpcmst_syoti1 <- dpcmst_syoti1 %>% 
  mutate(dpcfy = if_else(fy %% 2 == 1,fy-1,fy)) %>% 
  glimpse()

# 必要列抽出
dpc_syoti1 <- dpcmst_syoti1 %>% 
  select(dpcfy,mdc6cd,syoti1cd,syoti1_kcode,syoti1_kname) %>%
  glimpse()

# データベースに書き込み
dbWriteTable(con_dpc,'dpc_syoti1',dpc_syoti1,overwrite = T)

