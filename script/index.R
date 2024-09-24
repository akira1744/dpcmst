
# list.files('script',full.names = T) %>% dput()

# EXCELを読み込んで、RDSで出力
# 新しい年度のデータを追加する場合はfilepathとfyを追記せよ
source("script/010_dpcmst_by_year.R") 

# RDSを読み込んでSQLiteに出力
source("script/020_integrate_dpcmst.R")

# dpc_mdc2とdpc_mdc6を作成
source("script/030_make_dpc_mdc2_dpc_mdc6.R")

# dpc_mdc14とdpc_opecdopekbを作成
source("script/050_make_dpc_mdc14_dpc_opecdopekb.R")

# dpc_opecdknameを作成
source("script/060_make_dpc_mdc6_opecd_kcode.R")

# dpc_opecdknameを作成
source("script/061_make_dpc_syoti1.R")

# dpc_opecdknameを作成
source("script/062_make_dpc_syoti2.R")

# dpc_mdc6icdを作成
source("script/070_make_dpc_mdc6icd.R")

# dpc_mdc6hukuを作成
source("script/080_make_dpc_mdc6huku.R")

# 副傷病一覧.xlsxの出力
# set_dpcfy を書き換えればその年の副傷病一覧が出力可能
source("script/090_副傷病一覧の出力.R")
