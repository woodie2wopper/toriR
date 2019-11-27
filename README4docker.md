<!--
Select or linsten bird's voice on R
@author woodiw2wopper <woodie2wopper@gmail.com>
Copyright (C) 2019 woodiw2wopper
-->

# docker-compose による立上げ方法

## 前提

* docker, docker-compose インストール済、dockerのAdvanced>memory設定は8GBに変更済み(default 2GB)
* toriR用データ入手済 たとえば 190501とか

## 立上げ方法

* `git clone https://github.com/woodie2wopper/toriR.git` : リポジトリをclone
* `cd toriR` : cloneしたディレクトリに移動
* dataフォルダ以下にtoriR用データを展開。(wav, psgrm, pngが必要)。
    * dockerはシンボリックリンクを追跡できないので、実際のファイルを配置してください。
    * 190501の例では以下のフォルダ構成。以降これを前提に説明
```
data
└── 190501
    ├── 190501_220000-230000.psgrm
    ├── 190501_220000-230000.wav
    ├── 190501_220000-230000_P01.png
    ├── 190501_220000-230000_P02.png
    ├── 190501_220000-230000_P03.png
    ├── 190501_220000-230000_P04.png
    ├── 190501_220000-230000_P05.png
    ├── 190501_220000-230000_P06.png
    ├── 190501_220000-230000_P07.png
    ├── 190501_220000-230000_P08.png
    ├── 190501_220000-230000_P09.png
    ├── 190501_220000-230000_P10.png
    ├── 190501_220000-230000_P11.png
    ├── 190501_220000-230000_P12.png
    ├── 190501_220000-230000_P13.png
    ├── 190501_220000-230000_P14.png
    └── 190501_220000-230000_P15.png
```
* `docker-compose pull` : docker-compose.ymlに従いdocker imageを取得
* `docker-compose up -d` : docker-compose.ymlに従いdocker containerを起動
    * http://localhost:8787 にブラウザでアクセスする
    * ブラウザでRstuio相当の画面が立ちあがっているので、そのRプロンプトで、`toriRstart("data/190501/190501_220000-230000.wav")` を実行すると、toriRが起動する
    * macの場合は準備ができて、`R> 声紋をクリック。無ければ範囲外（白い部分）をクリック。またはESPキー` のメッセージが出るまでちょっと時間がかかります。Windowsなら10秒程度。

## 停止方法

* `docker-compose down` : サービスを停止します
