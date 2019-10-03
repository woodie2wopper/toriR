# toriR（トリル）｜トリを聴き取る on R (listen and select birds voice on R;  (tori in Japanese is bird) )
## 概要（できること）
- ICレコーダの録音データから変換されたスペクトログラムを`RStudio`上で表示します。
- 見覚えのある声紋があればクリックし、メニューから種名を選択することで、スペクトログラムのファイル名の日時情報からクリックした場所に相当する時刻と選択した種名、クリックした周波数の情報をcsvファイルとして出力します。
- 迷う場合はメニューから"再生"を選べば、音が再生できます（事前に`SoX`のインストールが必要）。

## 環境準備（下記をインストールし、pathに登録してください）
1. `R`
2. `RStudio`
3. `SoX`

## version
| No.  | soft    | version          | link                                                         |
| ---- | ------- | ---------------- | ------------------------------------------------------------ |
| 1    | SoX     | v14.4.2          | [qiita](https://qiita.com/teteyateiya/items/e4dc27e384d947b9946d) |
| 2    | R       | R3.6.1           | [cran.r-project.org](https://cran.r-project.org/)            |
| 3    | RStudio | Version 1.2.5001 | [rstudio](https://www.rstudio.com/)                          |

~編集中~

## 音源データの準備
ファイル名を下記の666形式の録音日時に変更してください。

例えば、2019年05月01日23:00:00からよく、05月02日02:00:00までの音源データなら
"`開始日にち_開始時刻-終了時刻_xxx.拡張子`”という風に変更してください。”_”と”-“を区別してください。xxxの部分はあってもなくても構いません。

original filename: `DS700143.WMA`
modified filename: `190501_230000-020000_DS700143.WMA`

これを6_6-6形式とあるいは単純に666形式と読んでいます。
