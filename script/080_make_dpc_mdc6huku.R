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

# dpc_mdc6icdを読み込み
dpc_mdc6icd <- dbReadTable(con_dpc, 'dpc_mdc6icd') %>% tibble() %>% print()

# dpcmst_hukusyobyoを読み込み
dpcmst_hukusyobyo <- dbReadTable(con_dpc, 'dpcmst_hukusyobyo') %>% tibble() %>% glimpse()

# 有効期間開始日を確認しつつdpcfyを作成する
df <- dpcmst_hukusyobyo %>% 
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
    hukusyobyocd = 対応コード,
    hukusyobyoflag = 定義副傷病フラグ,
    hukuicd = ICDコード,
    hukuicdname=ICD名称
  ) %>% 
  glimpse()

# icdがdpcmdc6icdに含まれているものであることを確認
df %>% 
  filter(!hukuicd %in% dpc_mdc6icd$icd) %>% 
  count()

# icdname列を削除
df <- df %>% 
  select(-hukuicdname) %>% 
  glimpse()


# icdとmdc6cdのmstを作成
mst_icd_mdc6cd <- dpc_mdc6icd %>% 
  distinct(dpcfy,icd,mdc6cd,mdc6) %>% 
  rename(
    hukuicd=icd,
    hukumdc6cd=mdc6cd,
    hukumdc6 = mdc6     
  ) %>% 
  print()

# hukuicdで結合しhukumdc6cdを作成
df2 <- df %>% 
  left_join(mst_icd_mdc6cd, by=c('dpcfy','hukuicd')) %>% 
  glimpse()

# 確認用
df2 %>% 
  filter(mdc6cd == '010069',dpcfy==2022)

# icd列を消してdistinct
df3 <- df2 %>% 
  distinct(dpcfy,mdc6cd,hukusyobyocd,hukusyobyoflag,hukumdc6cd,hukumdc6)

# 確認用
df3 %>% 
  filter(mdc6cd == '010069',dpcfy==2022)

################################################################################

# opeflagで結合できるように加工をする

# opecdが99の場合はhukusyobyoflagが1と2の副傷病が該当になる
openasi <- df3 %>% 
  filter(hukusyobyoflag %in% c('1','2')) %>% 
  mutate(opeflag = 0,.after=hukusyobyoflag) %>% 
  print()

# opecdが99以外の場合はhukusyobyoflagが1と3の副傷病が該当になる
opeari <- df3 %>% 
  filter(hukusyobyoflag %in% c('1','3')) %>% 
  mutate(opeflag = 1,.after=hukusyobyoflag) %>% 
  print()

# 縦に連結
df4 <- bind_rows(openasi,opeari) %>% 
  glimpse()

# 確認
df4 %>% 
  filter(mdc6cd == '010069',dpcfy==2022)

################################################################################

# 必要列だけにする
dpc_mdc6huku <- df4 %>% 
  select(-hukusyobyoflag) %>% 
  print()

################################################################################

# 手術有無によって副傷病名の分岐があるものにフラグを立てる

# opeflagのcountをする
dpc_opeflagcnt <- dpc_mdc6huku %>%
  distinct(dpcfy,mdc6cd,hukusyobyocd,opeflag) %>% 
  group_by(dpcfy,mdc6cd,hukusyobyocd) %>% 
  summarise(opeflagcnt = n()) %>% 
  ungroup() %>%
  print()

df5 <- dpc_mdc6huku %>% 
  left_join(dpc_opeflagcnt,by=c('dpcfy','mdc6cd','hukusyobyocd')) %>% 
  glimpse()


# dpcfy,mdc6cd,hukusyobyocd,hukumdc6cdごとにhukumdc6cdの登場回数をカウント
df5 <- df5 %>% 
  group_by(dpcfy,mdc6cd,hukusyobyocd,hukumdc6cd) %>% 
  mutate(hukumdc6cdcnt = n()) %>% 
  ungroup() %>% 
  print()


# opeflagcntとhukumdc6cdcntが一致しないものにflagを立てる
df5 <- df5 %>% 
  mutate(hukubunki = case_when(
    opeflagcnt == hukumdc6cdcnt ~ 0,
    TRUE ~ 1
  )) %>%
  glimpse()


# hukubunkiが1のものを抽出
df5 %>% 
  filter(hukubunki == 1,dpcfy==2024) %>% 
  print()

# opeflagcntとhukumdc6cdcnt列を削除
dpc_mdc6huku <- df5 %>% 
  select(-opeflagcnt,-hukumdc6cdcnt) %>% 
  glimpse()

# hukubunkiの列を移動
dpc_mdc6huku <- dpc_mdc6huku %>% 
  relocate(hukubunki,.after=opeflag) %>% 
  glimpse()

# DBに書き出し
dbWriteTable(con_dpc, 'dpc_mdc6huku', dpc_mdc6huku, overwrite = T)

################################################################################



