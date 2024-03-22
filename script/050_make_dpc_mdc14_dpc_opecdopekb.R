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

# con_dpcからdpcmst_を取得
dpcmst_mdc14 <- dbReadTable(con_dpc,'dpcmst_mdc14') %>% tibble() %>% glimpse()

dpcmst_mdc14 %>% glimpse()

# 列名変更
dpc_mdc14 <- dpcmst_mdc14 %>% 
  rename(
    mdc14cd = 診断群分類番号,
    mdc6 = 傷病名,
    opekb = 手術名,
    syoti1kb = 手術_処置等1,
    syoti2kb = 手術_処置等2,
    hukusyobyokb=定義副傷病,
    jusyodokb = 重症度等,
    stymd=有効期間_開始日,
    kikan1 = 入院日日_I,
    kikan2 = 入院日日_II,
    kikan3 = 入院日日_III,
    kikan1ten = 点数点_入院期間I,
    kikan2ten = 点数点_入院期間II,
    kikan3ten = 点数点_入院期間III
  ) %>% 
  glimpse()

# stymdからyear,monthを作成
dpc_mdc14 <- dpc_mdc14 %>% 
  mutate(
    stymd = ymd(stymd),
    year = year(stymd),
    month = month(stymd),
  ) %>% print()

# 年度としてdpcfy列を作成
dpc_mdc14 <- dpc_mdc14 %>% 
  mutate(
    dpcfy = case_when(
      month >= 4 ~ year,
      month < 4 ~ year - 1
    )
  ,.before=mdc14cd) %>%
  glimpse()


# 確認
dpc_mdc14 %>% 
  count(stymd,dpcfy)

# mdc14から各mdc番号を抽出
dpc_mdc14 <- dpc_mdc14 %>% 
  mutate(
    mdc2cd = str_sub(mdc14cd,1,2)
    ,mdc6cd = str_sub(mdc14cd,1,6)
    ,opecd = str_sub(mdc14cd,9,10)
    ,syoti1cd = str_sub(mdc14cd,11,11)
    ,syoti2cd = str_sub(mdc14cd,12,12)
    ,hukusyobyocd = str_sub(mdc14cd,13,13) 
    ,jusyodocd = str_sub(mdc14cd,14,14)
  ,.after=mdc14cd) %>% 
  glimpse()

# 不要列削除
dpc_mdc14 <- dpc_mdc14 %>% 
  select(-番号,-更新日,-有効期間_終了日,-year,-month,-stymd,-変更区分) %>% 
  glimpse()

# 書き込み
dbWriteTable(con_dpc, 'dpc_mdc14', dpc_mdc14, overwrite = TRUE)

# con_dpcのtable一覧を確認
dbListTables(con_dpc) %>% print()


################################################################################

# 手術区分のデータを作成
dpc_opecdopekb <- dpc_mdc14 %>% 
  distinct(dpcfy,mdc6cd,opecd,opekb) %>% 
  glimpse()

# mdc6とopecdでopekbがユニークになっていることを確認
dpc_opecdopekb %>% 
  group_by(dpcfy,mdc6cd,opecd) %>% 
  filter(n()>1)

# 書き込み
dbWriteTable(con_dpc, 'dpc_opecdopekb', dpc_opecdopekb, overwrite = TRUE)

# con_dpcのtable一覧を確認
dbListTables(con_dpc) %>% print()

################################################################################
