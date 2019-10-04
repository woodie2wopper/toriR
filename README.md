# toriR（トリル）｜トリを読み取る on R (Select or linsten bird's voice on R;  (tori in Japanese is bird) )
## 概要（できること）
- ICレコーダの録音データから変換されたスペクトログラムを`RStudio`上で表示します。
- 見覚えのある声紋があればクリックし、メニューから種名を選択することで、スペクトログラムのファイル名の日時情報からクリックした場所に相当する時刻と選択した種名、クリックした周波数の情報をcsvファイルとして出力します。
- 迷う場合はメニューから"再生"を選べば、音が再生できます（事前に`SoX`のインストールが必要）。

## 対応OS
1. MacOSX
2. Windows10
3. 多分Linux系もOKでしょう

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

例えば、2019年05月01日23:00:00から翌日の05月02日02:00:00までの音源データなら
"`開始日にち_開始時刻-終了時刻_xxx.拡張子`”という風に変更してください。”_”と”-“を区別してください。xxxの部分はあってもなくても構いません。

original filename: `DS700143.WMA`
modified filename: `190501_230000-020000_DS700143.WMA`

これを6_6-6形式とあるいは単純に666形式と呼んでいます。
### ディレクトリの構成
```{bash}
$tree -d
.
└── toriR_demo
    ├── 190501
    └── ORG
```    
- ICレコーダの音源はORGというフォルダに入れてください。その親のフォルダに日にち毎のディレクトリが作られて、そこに音声ファイル(.wav)と、スペクトログラム(.png)、設定ファイル(.psgrm)ができます。()は拡張子です。

### スペクトログラム作成するための設定パラメータ
```{bash}
# value is default.
fftsize=1024;#Fast Fourie Transfer size (512 or 1024)｜FFTサイズ
f_lcf=0000;           #Frequency of low cut filter[Hz]｜周波数の加減
f_hcf=12000;          #Frequency of high cut filter[Hz]｜周波数の上限
height_image="125";   #Image height of Spectrogram
ratio_clip="20";      #Clipping ratio of sound spectrogram generated
thrsd_clip_lo="-200"; #Threshold of clipping value of low side of spectrogram gererated
thrsd_clip_hi="-100"; #Threshold of clipping value of high side of spectrogram gererated
window_time="60";     #Spectrogram time window｜スペクトログラムの時間幅
width_image="624";    #Image width of Spectrogram
windows_a_page="4";   #Spectrograms a page｜1頁のあたりのスペクトログラム
```

## How to use `toriR` (`toriR`の使い方)
### Load source code 'toriR' (`toriR`コードを読む)
1. Open `RStudio`;      # `RStudio`を開く
2. Load 'toriR.R` code; # `toriR`コードを読み込む

### Set and edit parameters in the `toriR` source code; (`toriR`のソースコード無いのパラメータを編集する)
1. Set date parameter `date_analysis`: date_analysis <- 190501;(`date_analysis`を6桁の日にちを指定)
2. Set time parameter `time_analysis_sart` as a charactor: (`time_analysis`を文字列として開始時刻を指定する)
3. Edit candidates of bird's name of `spices` as a vector: (`spices`に鳥の声の種名を登録する。種名を""の中に入れる)
```{R}
spices <- c(
"play", "WAY｜save", "noise", "owl", "White's Thrush", "Japanese Green Pigeon"
);
```
4. Edit playing setting(option)(再生の設定(オプション))
```{R}
`volume` <- 8;# play volume;(再生音量の`volume`を設定)
`length_preplay` <- 1.; # length of playing time befor click(クリックより前の再生時間)
`length_play` <- 3;     # length of playing time after click(クリックの後の再生時間)
```

### Run `toriR`(トリルの実行)
```{R}
1. Run of all `toriR` source code(`toriR`の全てのソースコードを実行する)
2. Click bird's voice on the spectrogram image(`toriR`のスペクトログラム画像上の鳥の声紋をクリック)
3. Select bird's name or play from list after moving focus on console)(コンソール上にフォーカスし、リストから鳥の名前を選ぶ)
4. When move to the next page, click the white area outside of the spectrogrum range on Plots or press `ESC` key(次のページに移動するにはPlots上のスペクトログラムの範囲外の白い部分をクリックするか`ESC`キーを押す)
5. When skip the rest of pages, press `ESC` immediately after clicking on the plot(残りのページをスキップしたい場合は、プロット上をクリックした直後に`Esc`キーを押します)
```


