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

# con_dpcのtableをすべて読み込みして、同名の変数に格納
dbListTables(con_dpc) %>% 
  map(~dbReadTable(con_dpc, .x)) %>% 
  set_names(dbListTables(con_dpc)) %>% 
  list2env(envir = .GlobalEnv)

################################################################################

# dpcmst_mdc2を作成
dpc_mdc2 <- dpcmst_mdc02 %>% 
  tibble() %>% 
  select(mdc2cd=MDCコード,mdc2=MDC名称) %>% 
  distinct(mdc2cd,mdc2) %>% 
  mutate(mdc2 = case_when(
    mdc2cd=='01' ~ '神経系',
    mdc2cd=='02' ~ '眼科系',
    mdc2cd=='03' ~ '耳鼻咽喉科系',
    mdc2cd=='04' ~ '呼吸器系',
    mdc2cd=='05' ~ '循環器系',
    mdc2cd=='06' ~ '消化器系',
    mdc2cd=='07' ~ '筋骨格系',
    mdc2cd=='08' ~ '皮膚系',
    mdc2cd=='09' ~ '乳房系',
    mdc2cd=='10' ~ '内分泌系',
    mdc2cd=='11' ~ '腎尿路系',
    mdc2cd=='12' ~ '女性生殖器系',
    mdc2cd=='13' ~ '血液系',
    mdc2cd=='14' ~ '新生児系',
    mdc2cd=='15' ~ '小児系',
    mdc2cd=='16' ~ '外傷系',
    mdc2cd=='17' ~ '精神系',
    mdc2cd=='18' ~ 'その他',
    TRUE ~ 'error'
  )) %>% 
  print()

# dpcmst_mdc2をshiny.sqliteに書き込み
dbWriteTable(con_dpc, 'dpc_mdc2', dpc_mdc2, overwrite = TRUE,row_names = FALSE)

################################################################################

# dpcmst_mdc6を作成
dpc_mdc6 <- dpcmst_mdc06 %>% 
  tibble() %>% 
  mutate(mdc6cd = str_c(MDCコード,分類コード)) %>% 
  select(mdc2cd=MDCコード,mdc6cd,mdc6=名称,stymd=有効期間_開始日,enymd=有効期間_終了日) %>%
  print()

# stymdからyear列とmonth列を作成
dpc_mdc6 <- dpc_mdc6 %>% 
  mutate(stymd = ymd(stymd)) %>% 
  mutate(year = year(stymd),month = month(stymd)) %>% 
  print()

# yearとmonthからdpcfyの列を作成
dpc_mdc6 <- dpc_mdc6 %>% 
  mutate(dpcfy = case_when(
    month >= 4 ~ year,
    month < 4 ~ year - 1
  )) %>% 
  print()

# dpcfyの確認
dpc_mdc6 %>% 
  count(stymd,year,month,dpcfy)

# 必要列だけに整理
dpc_mdc6 <- dpc_mdc6 %>% 
  select(dpcfy,mdc2cd,mdc6cd,mdc6) %>% 
  print()

# dpcmst_mdc6をshiny.sqliteに書き込み

dbWriteTable(con_dpc, 'dpc_mdc6', dpc_mdc6, overwrite = TRUE,row_names = FALSE)

################################################################################

