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

# 診断群分類(DPC)電子点数表の読込み
filename <- list.files('input/',pattern = '.xlsx$',full.names = T) %>% print()

# setting
# filepath <- 'input/診断群分類_DPC_電子点数表_20190522.xlsx'
# fy <- '2018'
# filepath <- 'input/診断群分類_DPC_電子点数表_20211124.xlsx'
# fy <- '2020'
# filepath <- 'input/診断群分類_DPC_電子点数表_20231121.xlsx'
# fy <- '2022'
filepath <- 'input/診断群分類_DPC_電子点数表_20250520.xlsx'
fy <- '2024'

################################################################################

# outputdirの設定
outputdir <- str_c('output/tmp/',fy,'/') %>% print()

# outputdirがなかったら作成する
if(!dir.exists(outputdir)){
  dir.create(outputdir,recursive = T)
}else{
  # すでに存在していたら中身を削除
  unlink(outputdir,recursive = T)
  dir.create(outputdir,recursive = T)
}

################################################################################

# １）ＭＤＣ名称の前処理
sheet <- '１）ＭＤＣ名称'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

# データの読み込み
df<- readxl::read_excel(
  filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_mdc02.rds'))

################################################################################

# ２）分類名称の前処理
sheet <- '２）分類名称'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()


# データの読み込み
df <- readxl::read_excel(filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_mdc06.rds'))

################################################################################

# ３）病態等分類
sheet <- '３）病態等分類'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()


# データの読み込み
df <- readxl::read_excel(
  filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_byotai.rds'))

################################################################################

# ４）ＩＣＤの前処理
sheet <- '４）ＩＣＤ'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()


# データの読み込み
df <- readxl::read_excel(filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_mdc06_meisyo_icdcord.rds'))

################################################################################

# ６）手術の前処理
sheet <- '６）手術 '
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

# データの読み込み
df <- readxl::read_excel(filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_mdc10.rds'))

################################################################################

# ７）手術・処置等１
sheet <- '７）手術・処置等１'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

# データの読み込み
df<- readxl::read_excel(filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_syoti1.rds'))

################################################################################

# ８）手術・処置等２
sheet <- '８）手術・処置等２'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

# データの読み込み
df <- readxl::read_excel(filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_syoti2.rds'))

################################################################################

# ９）定義副傷病名
sheet <- '９）定義副傷病名'
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

# データの読み込み
df <- readxl::read_excel(
  filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_hukusyobyo.rds'))

################################################################################

# 11）診断群分類点数表
sheet <- '11）診断群分類点数表'
nheader <- 2
nskip <- 2

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

# データの読み込み
df <- readxl::read_excel(
  filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_mdc14.rds'))

################################################################################

# 11）診断群分類点数表
sheet <- '12）変換テーブル '
nheader <- 2
nskip <- 0

# ヘッダを取得
colname <- get_colname_from_multiline_data(filepath,sheet=sheet,nheader=nheader,skip=nskip) %>%
  print()

colname <- colname %>% 
  str_replace_all('、','_') %>% 
  str_replace_all('　','') %>% 
  str_replace_all(' ','') %>%
  str_replace_all('-','_') %>% 
  
  print()

# データの読み込み
df <- readxl::read_excel(
  filepath,
  sheet = sheet,
  skip = nheader+nskip, 
  col_names = colname,
  col_types = "text") %>% 
  glimpse()

# rds保存
df %>% 
  saveRDS(str_c(outputdir,'dpcmst_henkan_table.rds'))

################################################################################

