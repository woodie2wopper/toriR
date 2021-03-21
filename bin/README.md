# README
```
date :2021-03-21
(c) woodie2wopper
```

## 使い方
- Macintoshのターミナルで使うことを想定しています。
- awk/sed/coreutilをbrewなどでインストールしてください。


## tools
|tool|Version|
|awk|GNU Awk 5.1.0, API: 3.0 (GNU MPFR 4.1.0, GNU MP 6.2.1)|
|sed| (GNU sed) 4.8|
|ls| (GNU coreutils) 8.32|
|soxi|SoX v|

## usage
```{bash}
$ # 引数なし
$ FileStamp_to_f666.bash 
  USAGE: FileStamp_to_f666.bash 030A_151204_1640.WAV [ifs|ifn] -090000 [show_org|-] show_maker
 
  機能：1. 音源をファイルスタンプベースに666フォーマットのファイル名で返す
        2. 拡張子は小文字にする
        3. 機器情報などlogファイルを出力します。場所は/Users/osaka/log です。
        4. ファイル名が同じフォーマットの場合、デバイス名をディレクトリ名から取得します。その場合、デバイス名はフルパスの2つ目のディレクトリと仮定しています
        5. オプションは順番通りに設定してください。[a|b]はaかbかの意味です。
  OPT : [ifs|ifn]はファイルのタイムスタンプあるいかファイル名の時刻を無視する(Ignore File Stamp/Ignore File Name)
  OPT : [timediff] 時差 : %H%M%Sで入力してください
  OPT : [show_org] オリジナルファイルを表示します。
  OPT : [show_maker] メーカ情報を表示します
  ```
  
