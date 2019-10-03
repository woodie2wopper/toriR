# toriR（トリル）｜トリを聴き取る on R (listen and select birds (tori in Japanese) voice on R)
## 概要（できること）
- ICレコーダの録音データから変換されたスペクトログラムを`RStudio`上で表示します。
- 見覚えのある声紋があればクリックし、メニューから種名を選択することで、スペクトログラムのファイル名の日時情報からクリックした場所に相当する時刻と選択した種名、クリックした周波数の情報をcsvファイルとして出力します。
- 迷う場合はメニューから"再生"を選べば、音が再生できます（事前に`SoX`のインストールが必要）。

## 準備（下記をインストールし、pathに登録してください）
1. `R`
2. `RStudio`
3. `SoX`

## version
| No.  | soft    | version          | link                                                         |
| ---- | ------- | ---------------- | ------------------------------------------------------------ |
| 1    | SoX     | v14.4.2          | [qiita](https://qiita.com/teteyateiya/items/e4dc27e384d947b9946d) |
| 2    | R       | R3.6.1           | [cran.r-project.org](https://cran.r-project.org/)            |
| 3    | RStudio | Version 1.2.5001 | [rstudio](https://www.rstudio.com/)                          |

