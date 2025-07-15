# 診断群分類（DPC）電子点数表を前処理してDB化

## ファイルの説明

- input

DPC早見表

- 完成版

output/dpcmst.sqlite

## scriptの説明

### 010_dpcmst_by_year.R

settingでfilepathとfyを指定してスクリプトを流すと、ouytput/tmp/以下にRDSが作成される

- 1)MDC名称:"dpcmst_mdc02"
- 2)分類名称:"dpcmst_mdc06"
- 3)病態等分類:"dpcmst_byotai"
- 4)ICD::"dpcmst_mdc06_meisyo_icdcord"
- 6)手術:"dpcmst_mdc10"
- 7)手術・処置等1:"dpcmst_ope_syoti1"
- 8)手術・処置等2:"dpcmst_ope_syoti2"
- 9)定義副傷病名:"dpcmst_hukusyobyo"
- 11)診断群分類点数表:"dpcmst_mdc14"
- 12)変換テーブル:"dpcmst_henkan_table"

### 020_integrate_dpcmst.R

output/tmp/以下のRDSを統合して、output/dpcmst_original.sqliteを作成する

table名はすべて「dpcmst_〇〇」で統一

### 030から080で、データを正規化してデータベースに格納

table名はすべて「dpc_〇〇」で統一

### 090_副傷病一覧の出力

DPC毎の副傷病一覧をxlsxにして出力


### 100_診療報酬改定による副傷病の差分一覧

2024と2022の副傷病名の差分を確認するための一覧を取得する為のスクリプト

### 作業歴20250715

DPC早見表を最新versionに変更する


