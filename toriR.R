# toriR.R 長時間音源から鳥の種の特定と鳴いた時刻の入力支援ツール
# 2020-05-05 (C) woodie2wopper 公開用にコードを整える
# 2019-12-11 (C) woodie2wopper ページ戻りができる
# 事前にシステムsoxがインストールされている必要があります。

programname <- "toriR.R"; 

## ユーザ設定1｜音源ファイル ##############################
path_wav <- "/Volumes/夜間長時間録音/2019/190804/190805_030002-040002.wav"; #MacOS
# path_wavfile <- "C:/Users/〇〇/190501_230000-0000.wav"; # Windows
if( ! file.exists(path_wav) ) {stop(paste("No file:",path_wav))};


## ユーザ設定2｜鳥の名前 ########################################
spices <- c(
  "再生", "WAY｜保存", "雑音",
  "頁戻り", "他の鳥",
  "ヤブサメ",
  "ホトトギス", "ヨタカ", "ヤイロチョウ", "イワツバメ",
  "フクロウ", "ミゾゴイ", "アオサギ", "アカショウビン", "ゴイサギ",
  "キビタキ", "クロツグミ", "アオバト", "ウグイス"
  );


## ユーザ設定3｜再生パラメータの設定 #############################
volume <- 8;         # play volume          ｜再生音量
length_preplay <- 1.;# play time befor click｜クリック前の再生時間
length_play    <- 4.;# play time after click｜クリック後の再生時間

## ユーザ設定4｜ライブラリの読み込み（初回のみ） #############################
#install.packages("png", dependencies = TRUE);
#install.packages("dplyr", dependencies = TRUE);
#install.packages("stringr", dependencies = TRUE);
#install.packages("seewave")

# R script from here ###########################################
library(png)
library(dplyr)
library(stringr)
library(tools)

## directory and files ##############
dir_dist <- dirname(path_wav)
basename_wav <- basename(path_wav)
dirname_wav  <- dirname(path_wav)
filebody_wav <- tools::file_path_sans_ext(basename_wav)
setwd(dir_dist)

### parameter file laod ####
file_param      <- stringr::str_replace(path_wav, ".wav", ".psgrm")
if( ! file.exists(file_param) ){
  stop(paste("No file:", file_param))
}else{
  load(file = file_param)
};

### output file csv) ####
csvfile_output  <- stringr::str_replace(path_wav, ".wav", ".csv")
if(file.exists(csvfile_output)) {
  cat("ファイルに追記します:", csvfile_output, "\n")
  };

### Recordint date and time ####
file_info <- stringr::str_split(filebody_wav, "[_-]") %>% unlist;
date_record <- file_info[1]; # 録音日
time_start  <- paste(date_record, file_info[2], sep =" ")
time_start  <- strptime(time_start, format="%y%m%d %H%M%S"); 
time_end    <- paste(date_record, file_info[3], sep = " "); # 録音終了時間
time_end    <- strptime( time_end, format="%y%m%d %H%M%S"); # 録音開始時刻

### png file setting ######
pngs <- list.files(pattern = paste0(filebody_wav, "_P[0-9][0-9].png"));
num_png <- length(pngs);

### time setting of toriR ######
now <- Sys.time(); 
today <- format(now,"%Y.%m.%d");
txt_kikimimi <- c(
  paste0("# ---------------------------------------------------------\n",
         "# プログラム:program=", programname, "\n", 
         "# 入力モード:mode=toriR\n",
         "# 入力音声ファイル:inputfile=\n",
         "# 解析開始時間:StartTime_toriR=", now, "\n",
         "# スクリプター:Scripter=\n",
         "# ICレコーダー:IC Recorder=\n",
         "# サンプリングレート:SamplingRate=\n",
         "# サンプリングサイズ:SamplingSize=\n",
         "# 編集日:EditDate=", today, "\n",
         "# サイト名前:Site_Name=\n",
         "# 記録場所:RecordingSite=\n",
         "# 天気:Weather=\n",
         "# 気温[ ℃  ]:Temparature=\n",
         "# GPSポジション:GPSposition=\n",
         "# 日の出時間:TimeOfSunrise=\n",
         "# ---------------------------------------------------------\n",
         format(time_start,"%Y.%m.%d,%H:%M:%S,,R,\n")
  )
)
cat(txt_kikimimi, file = csvfile_output, append = TRUE)

# OSによる使い分け
os <- strsplit(osVersion, " ")[[1]][1];
str_play_trim <- function(os, volume, file_song, second_start=0, length_play=5){
  if (os == "Windows" ) {
    res <- sprintf("sox -V0 -v %d %s -t waveaudio trim %s %d", volume, file_song, second_start, length_play)
  }
  if (os == "macOS"){
    res <- sprintf("play -V0 -v %d %s trim %s %d", volume, file_song, second_start, length_play)
  }
  return(res)
}

### windowの表示画面上の場所指定 ####
if (windows_a_page == 4){
  xl <- 0.044; xr <- 0.93;  
  yb <- 0.805; yt <- 0.978;
  dy <- 0.25;
}

### 表示の設定####
if (os == "macOS") {
  par(family = "HiraKakuProN-W3")
}
if (os == "windows"){
  windowsFonts(MEI = windowsFont("Meiryo"))
  par(family = MEI)
}
images <- list(1:num_png)
for (i in 1:num_png){
  images[[i]] <- readPNG(pngs[i])
}
### toriRの結果データベース####
db <- tribble(
  ~num_png, ~x, ~y, ~label,~col_text,
  1,        0,   0,  "temp", "white"
)

i <- 1;
while( i <= num_png ){
  # for (i in 1:2){
  is_page_end <- FALSE;
  pngfile_input  <- pngs[i];
  # cat("R> i = ",i,"\n");
  cat("R>", pngfile_input, "\n");
  cat(paste0("# スペクトログラム:spectrogram=", pngfile_input, "\n"), file = csvfile_output, append =TRUE)
  #num_page <-   stringr::str_sub(pngfile_input, start = 23, end = 24) %>% as.numeric()
  par(mar=c(0, 0, 0, 0)); #外側のマージンをゼロにする
  plot(NULL
       , xlim = c(0,1), ylim = c(0, 1)
       , xlab = "", ylab = "", yaxt = "n", xaxt = "n",xaxs = 'i', yaxs = 'i'
  )
  rasterImage(images[[i]], 0, 0, 1, 1)
  #for( i in 0:(windows_a_page-1)){
  #  rect( xl, yb - i * dy, xr, yt - i * dy, col="transparent", border = "red")
  #}
  while ( is_page_end == FALSE ){
    cat("R> 声紋をクリックしてください。範囲外（白い部分）のクリックまたはESPキーで次頁に進みます。\n");
    z <- locator(n=1);
    if (is.null(z) == TRUE){# ESCが押されたなら
      is_page_end <- TRUE
      break;
    }
    x <- z$x; 
    y <- z$y; 
    y_position <- "out_of_range"
    for( k in 0:(windows_a_page - 1)) {# locator()の場所判定
      if(yb - k * dy <= y  && y < yt - k * dy) {y_position <- k}
    }
    if(y_position == "out_of_range"){break};# 範囲外選択
    points(x, y, col="RED", pch = 20);
    col_text <- "RED"; #抽出種名の文字の色
    
    time_offset <- (i - 1) * window_time * windows_a_page + window_time * y_position
    second_locator <- (time_offset + (x - xl) * (window_time)/(xr - xl)) 
    if(second_locator < 0)(length_preplay <- 0)
    txt_play <- str_play_trim(os, volume, path_wav, second_locator - length_preplay, length_play)
    time_locator   <- (time_offset + (x - xl) * (window_time)/(xr - xl) + time_start) %>% format("%Y.%m.%d,%H:%M:%S")
    freq_locator   <- (f_lcf + (y - (yb - y_position * dy)) * (f_hcf - f_lcf)/(yt - yb))
    
    answer <- menu(spices, title="\nR> 種類を選択してください（ESPで終了）:")

    if(answer == "0"){
      is_page_end <- TRUE;
      break;
    }
        # cat(paste0("Selected=", spices[answer]))
    while(spices[answer] == "再生") {#再生
      cat (txt_play);
      cat (paste0("# 再生:", txt_play, "\n"), file = csvfile_output, append = TRUE);
      
      system(txt_play);
      # play(dat_wav, from=second_locator - length_preplay, to=second_locator + length_play)
      answer <- menu(spices, title="R> 種類を選択してください（ESPで終了）:");
      cat(paste0("Reselection = ", spices[answer],"\n"))
    }
    if(spices[answer] ==  "WAY｜保存") {#
      time_locator_file  <- (time_offset + (x - xl) * (window_time)/(xr - xl) + time_start) %>% format("%y%m%d_%H%M%S")
      file_sox_save <- paste0(time_locator_file, "｜WAY.wav")
      txt_sox_save  <- sprintf("sox -v %d %s %s trim %s %d", volume, path_wav, file_sox_save, second_locator - length_preplay, length_play)
      system(txt_sox_save);
      col_text <- "YELLOW"
    }
    if( spices[answer] == "頁戻り" ){
      if (i == 1){
        i <- 0;
      }else{
        i <- i - 2;
      }
      break;
    }
    #else{
      # if(answer == "0"){
      #   is_page_end <- TRUE;
      #   break;
      # }
    #else{
    txt_kikimimi <- sprintf("%s,%s,F=%d[Hz]\n", time_locator , spices[answer], as.integer(freq_locator))
    cat(paste0("\nkikimimi>",txt_kikimimi))
    cat(txt_kikimimi, file = csvfile_output, append = TRUE)
    db <- rbind(db,c(i, x, y, spices[answer], col_text))
    text(x, y + 0.03, label = spices[answer], col= col_text); # 選択した文字列を図中に表示
      # }
    # }
  }
  if(i == num_png){
    dev.off()
    before <- now
    now <- Sys.time()
    txt_ending <- paste0(
      format(time_end,"%Y.%m.%d,%H:%M:%S,,STOP,\n"),
      "# 終了解析時間:StopTime_toriR=", now, "\n",
      "# 分析時間:AnalysisTime_toriR=", format(as.numeric(difftime(now, before, unit="min")), digit=2), "min.\n"
    )
    cat(txt_ending, file = csvfile_output, append = TRUE)
    cat(txt_ending)
  }
  i <- i + 1;
}


##画像に抽出結果を出力する ####
answer <- menu(c("上書き", "終了"), title="\nR> 画像ファイルに種名を上書きしますか？")
if (answer == 1){
  db <- db[-1,];
  cat("画像ファイルに結果を出力します")
  for (i in 1:num_png){
    # for (i in 1:2){
    pngfile_input  <- pngs[i];
    pngfile_output <- stringr::str_replace(pngfile_input, ".png", "_toriR.png");
    pngfile_output <- pngfile_input;
    png(pngfile_output, width = width_image, height = windows_a_page * height_image, bg="white")
    par(mar=c(0, 0, 0, 0)); #外側のマージンをゼロにする
    plot(NULL, xlim = c(0,1), ylim = c(0, 1), xlab = "a", ylab = "", yaxt = "n", xaxt = "n",xaxs = 'i', yaxs = 'i')
    rasterImage(images[[i]], 0, 0, 1, 1)
    text(0.9,0.99,label="toriR",col="RED")
    for (ii in 1:nrow(db)){
      w <- db[ii,];
      if ( i == w$num_png ){
        points(w$x, w$y, col=w$col_text, pch = 20);
        text(as.numeric(w$x), as.numeric(w$y) + 0.03, label = w$label, col= w$col_text);
      }
    }
    dev.off()
  }
}
