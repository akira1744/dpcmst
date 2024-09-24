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

# con_dpcからdpc_mdc6を取得
dpc_mdc6 <- dbReadTable(con_dpc,'dpc_mdc6') %>% tibble() %>% print()

# con_dpcからdpcmst_opeを取得
dpcmst_mdc10 <- dbReadTable(con_dpc,'dpcmst_mdc10') %>% tibble() %>% print()

# dpcmst_mdc10を作成
dpc_mdc10 <- dpcmst_mdc10 %>% 
  tibble() %>% 
  mutate(mdc6cd = str_c(MDCコード,分類コード)) %>% 
  rename(mdc2cd=MDCコード,opecd=対応コード,stymd=有効期間_開始日,enymd=有効期間_終了日) %>%
  glimpse()

# 手術○_点数表名称を確認 → 手術4と手術5はなにも入っていなかった
dpc_mdc10 %>% 
  distinct(手術4_点数表名称) %>% 
  print()

# 先にreplace_naで空文字にする
dpc_mdc10 <- dpc_mdc10 %>% 
  mutate(手術1_点数表名称 = replace_na(手術1_点数表名称,''),
         手術2_点数表名称 = replace_na(手術2_点数表名称,''),
         手術3_点数表名称 = replace_na(手術3_点数表名称,''),
         手術4_点数表名称 = replace_na(手術4_点数表名称,''),
         手術5_点数表名称 = replace_na(手術5_点数表名称,''),
         手術1_Kコード = replace_na(手術1_Kコード,''),
         手術2_Kコード = replace_na(手術2_Kコード,''),
         手術3_Kコード = replace_na(手術3_Kコード,''),
         手術4_Kコード = replace_na(手術4_Kコード,''),
         手術5_Kコード = replace_na(手術5_Kコード,'')) %>% 
  glimpse()

# 手術1_点数表名称～手術5_Kコードまでを+で結合してkname と　kcodeを作成する。
dpc_mdc10 <- dpc_mdc10 %>% 
  mutate(kname = str_c(手術1_点数表名称,手術2_点数表名称,手術3_点数表名称,手術4_点数表名称,手術5_点数表名称,sep = '＋'),
         kcode = str_c(手術1_Kコード,手術2_Kコード,手術3_Kコード,手術4_Kコード,手術5_Kコード,sep = '＋')) %>% 
  glimpse()

# ＋で終わっているものは+を削除
dpc_mdc10 <- dpc_mdc10 %>% 
  mutate(kname = str_remove(kname,'[＋]*$'),
         kcode = str_remove(kcode,'[＋]*$')) %>% 
  glimpse()

# stymdからyear,monthを作成
dpc_mdc10 <- dpc_mdc10 %>% 
  mutate(stymd=ymd(stymd)) %>% 
  mutate(year = year(stymd),
         month = month(stymd)) %>% 
  glimpse()

# fyを作成
dpc_mdc10 <- dpc_mdc10 %>% 
  mutate(fy = if_else(month >= 4,year,year-1)) %>% 
  glimpse()

# fyが奇数の時は-1してdpcfyを作成
dpc_mdc10 <- dpc_mdc10 %>% 
  mutate(dpcfy = if_else(fy %% 2 == 1,fy-1,fy)) %>% 
  glimpse()

# 必要列に絞り込み
dpc_opecdkname <- dpc_mdc10 %>% 
  distinct(dpcfy,mdc6cd,opecd,kcode,kname) %>% 
  glimpse()

# 書き出し
dbWriteTable(con_dpc,'dpc_opecdkname',dpc_opecdkname,overwrite = T)

# con_dpcのtable一覧を確認
dbListTables(con_dpc) %>% print()

# 確認

tbl(con_dpc,'dpc_opecdkname')

