################################################################################

# 作成日: 2023-12-20

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

################################################################################

## setting

# sqliteのpathを指定
db_dpc <- 'output/dpcmst.sqlite'

# もしdb_dpcが存在していたら削除
if(file.exists(db_dpc)){
  file.remove(db_dpc)
}

# sqliteにconnect
con_dpc = dbConnect(SQLite(), db_dpc, synchronous="off")

################################################################################

# 2018年のデータからdpcmst内のすべてのrdsファイル名を取得
targets <- list.files(path = 'output/tmp/2018',
                      pattern = '.rds',
                      recursive = TRUE) %>% 
  print()

# dpcmst内のすべてのrdsファイル名を取得
files <- list.files(path = 'output/tmp',
                    pattern = '.rds',
                    full.names = TRUE,
                    recursive = TRUE) %>% 
  print()

################################################################################

# 各年度のdpcmstを読み込んで、縦結合する

for(target in targets){
  
  targetfile <- files %>% 
    str_subset(target) %>% 
    print()
  
  # データを読み込んで縦に結合
  df <- targetfile %>% 
    map_dfr(readRDS) %>% 
    print()
  
  dbname <- str_remove(target,'.rds') %>% print()
  
  # dbに書き出し
  dbWriteTable(con_dpc,dbname,df,overwrite = TRUE,row.names = FALSE)
}

# dbのtable一覧を確認
dbListTables(con_dpc) %>% print()

