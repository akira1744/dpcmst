################################################################################

# 作成日: 20240610

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
set_dpcfy1 <- 2022
set_dpcfy2 <- 2024

# データベースのpath
db_dpc <- 'output/dpcmst.sqlite'

# connect
con_dpc = dbConnect(SQLite(), db_dpc, synchronous="off")

# dpc_mdc6icdを読み込み
dpc_mdc6 <- dbReadTable(con_dpc, 'dpc_mdc6') %>% tibble() %>% glimpse()

# 前期のmdc6一覧を取得
dpc_mdc6_1 <- dpc_mdc6 %>% 
  filter(dpcfy==set_dpcfy1) %>% 
  select(-mdc2cd,-dpcfy) %>% 
  print()

# 今期のmdc6一覧を取得
dpc_mdc6_2 <- dpc_mdc6 %>% 
  filter(dpcfy==set_dpcfy2) %>% 
  select(-mdc2cd,-dpcfy) %>% 
  print()

# 結合
dpc_mdc6_21 <- dpc_mdc6_2 %>% 
  left_join(dpc_mdc6_1,by=c('mdc6cd'),suffix=c('_2024','_2022')) %>% 
  glimpse()

################################################################################
# 意味合い的な変更がないかどうかを目検

# 前期にあったが今期にないもの
dpc_mdc6_21 %>% 
  filter(is.na(mdc6_2024))

# 今期にあるが前期になかったもの
dpc_mdc6_21 %>% 
  filter(is.na(mdc6_2022))

# 名称変更がおきたもの
dpc_mdc6_21 %>% 
  filter(mdc6_2024 != mdc6_2022)

################################################################################

# 意味合い的に大きな変更はないので、mdc6_2024に名称を寄せることにする
dpc_mdc6_21 <- dpc_mdc6_21 %>% 
  mutate(mdc6_2022 = case_when(
    is.na(mdc6_2022)  ~ mdc6_2022,
    mdc6_2022 != mdc6_2024 ~ mdc6_2024,
    TRUE ~ mdc6_2022
  )) %>%
  glimpse()

# mdc6の名称を最新年度に名寄せしたのでmdc6_2022列は削除
dpc_mdc6_21 <- dpc_mdc6_21 %>% 
  select(-mdc6_2022) %>% 
  glimpse()

# mdc6の名称から年度を削除
dpc_mdc6_21 <- dpc_mdc6_21 %>% 
  rename(mdc6 = mdc6_2024) %>% 
  glimpse()

################################################################################

# dpc_mdc6hukuを読み込み
dpc_mdc6huku <- dbReadTable(con_dpc, 'dpc_mdc6huku') %>% tibble() %>% glimpse()

################################################################################

# 前期の副傷病一覧を取得
dpc_mdc6huku_1 <- dpc_mdc6huku %>% 
  filter(dpcfy==set_dpcfy1) %>% 
  distinct(mdc6cd,hukumdc6cd) %>% 
  glimpse()

# 今期のmdc6名称をjoin
dpc_mdc6huku_1 <- dpc_mdc6huku_1 %>% 
  left_join(dpc_mdc6_2,by=c('hukumdc6cd'='mdc6cd')) %>% 
  rename(hukumdc6 = mdc6) %>%
  glimpse()

# 副傷病のcodeと名称を結合
dpc_mdc6huku_1 <- dpc_mdc6huku_1 %>% 
  group_by(mdc6cd) %>%
  mutate(huku2022 = str_c(hukumdc6cd,'_',hukumdc6)) %>%
  ungroup() %>%
  select(mdc6cd,huku2022) %>% 
  glimpse()

# mdc6ごとに副傷病名をリスト化
dpc_mdc6huku_1_list <- dpc_mdc6huku_1 %>% 
  group_by(mdc6cd) %>%
  summarise(huku2022=list(huku2022)) %>%
  glimpse()

################################################################################

# 今期の副傷病一覧を取得
dpc_mdc6huku_2 <- dpc_mdc6huku %>% 
  filter(dpcfy==set_dpcfy2) %>% 
  distinct(mdc6cd,hukumdc6cd,hukumdc6) %>% 
  
  glimpse()

# 副傷病のcodeと名称を結合
dpc_mdc6huku_2 <- dpc_mdc6huku_2 %>% 
  group_by(mdc6cd) %>%
  mutate(huku2024 = str_c(hukumdc6cd,'_',hukumdc6)) %>%
  ungroup() %>%
  select(mdc6cd,huku2024) %>% 
  glimpse()

# mdc6ごとに副傷病名をリスト化
dpc_mdc6huku_2_list <- dpc_mdc6huku_2 %>%
  group_by(mdc6cd) %>%
  summarise(huku2024=list(huku2024)) %>%
  glimpse()

################################################################################

# 副傷病のlistを結合
dpc_mdc6_huku_21 <- dpc_mdc6_21 %>% 
  left_join(dpc_mdc6huku_2_list,by='mdc6cd') %>% 
  left_join(dpc_mdc6huku_1_list,by='mdc6cd') %>% 
  glimpse()

# huku2024にあって,hukum2022にないものを副傷病名_増分という列にまとめる
dpc_mdc6_huku_21 <- dpc_mdc6_huku_21 %>% 
  mutate(
    副傷病名_増分 = map2(huku2024,huku2022,setdiff)
  ) %>% 
  glimpse()

# huku2022にあって,hukum2024にないものを副傷病名_削除という列にまとめる
dpc_mdc6_huku_21 <- dpc_mdc6_huku_21 %>% 
  mutate(
    副傷病名_削除 = map2(huku2022,huku2024,setdiff)
  ) %>% 
  glimpse()

# list型の列はすべて以下の処理をする
# 処理:要素を/r/nで結合して文字列にする
dpc_mdc6_huku_21 <- dpc_mdc6_huku_21 %>% 
  mutate(
    huku2024 = map_chr(huku2024,str_c,collapse = '\r\n'),
    huku2022 = map_chr(huku2022,str_c,collapse = '\r\n'),
    副傷病名_増分 = map_chr(副傷病名_増分,str_c,collapse = '\r\n'),
    副傷病名_削除 = map_chr(副傷病名_削除,str_c,collapse = '\r\n')
  ) %>% 
  glimpse()

# 列名変更
dpc_mdc6_huku_21 <- dpc_mdc6_huku_21 %>% 
  rename(
    副傷病名_2024 = huku2024,
    副傷病名_2022 = huku2022
  ) %>% 
  glimpse()


# excel出力
dpc_mdc6_huku_21 %>% 
  write_xlsx('output/診療報酬改定による副傷病の差分一覧_2024.xlsx')

# sqliteに書き込み
dbWriteTable(con_dpc,'dpc_mdc6_huku_diff2024',dpc_mdc6_huku_21,overwrite = T)

# rdsに書き込み
saveRDS(dpc_mdc6_huku_21,'output/dpc_mdc6_huku_diff2024.rds')

