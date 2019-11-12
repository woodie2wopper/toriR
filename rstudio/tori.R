# Select or linsten bird's voice on R
# @author woodiw2wopper <woodie2wopper@gmail.com>,
#         marltake <otake.shigenori@gmail.com>
# Copyright (C) 2019 woodiw2wopper
# version########################################################
programname <- "tori.R"
version <- "0.9.0"

## ユーザ設定2｜鳥の名前 ########################################
spices <- c(
  "再生", "WAY｜保存", "雑音", 
  "フクロウ", "トラツグミ","ヨタカ", "ホトトギス",
  "ヤブサメ","ミゾゴイ", "アオサギ", "ゴイサギ"
);


## ユーザ設定3｜再生パラメータの設定 #############################
volume <- 8;         # play volume          ｜再生音量
length_preplay <- 1.;# play time befor click｜クリック前の再生時間
length_play    <- 4.;# play time after click｜クリック後の再生時間


# R script from here ###########################################
library(png)
library(dplyr)
library(stringr)
library(tools)
library(htmltools)
library(tuneR)
library(extrafont)
font_import(prompt = FALSE)
par(family="IPAMincho")

setwd("/home/rstudio/data")

start <- function(path_of_wav) {
  ret <- check_and_goto_target_dir(path_of_wav);
  dir_to_return <- ret$return_dir;
  add_to_base <- ret$add_to_base;

  ### Recordint date and time ####
  ret <- parse_666filename(path_of_wav);
  time_start <- ret$start;
  time_end <- ret$end;

  ### png file setting ######
  pngs = list.files(pattern = add_to_base("_P[0-9][0-9].png"));
  num_png <- length(pngs)

  # load wave file
  wave_data = tuneR::readWave(add_to_base(".wav"));

  ### time setting of toriR ######
  csvfile_output <- add_to_base(".csv");
  now <- Sys.time()
  txt_kikimimi <- c(
    paste0("# プログラム:programname=", programname, version, "\n", 
          "# 解析開始時間:StartTime_toriR=", now, "\n",
          format(time_start,"%Y.%m.%d,%H:%M:%S,R,,\n")
    )
  )
  cat(txt_kikimimi, file = csvfile_output, append = TRUE)

  ### windowの表示画面上の場所指定 ####
  if (windows_a_page == 4){
    xl <- 0.044; xr <- 0.93;  
    yb <- 0.805; yt <- 0.978;
    dy <- 0.25;
  }
  images <- list(1:num_png)
  for (num_page in 1:num_png){
    images[[num_page]] <- readPNG(pngs[num_page])
  }

  ### toriRの結果データベース####
  db <- tribble(
    ~num_png, ~x, ~y, ~label,~col_text,
    1,        0,   0,  "temp", "white"
  )
  for (num_page in 1:num_png){
    # for (num_page in 1:2){
    flag_page_end <- FALSE;
    pngfile_input  <- pngs[num_page];
    cat("R> num_page = ",num_page,"\n")
    cat("R> ", pngfile_input, "\n")
    cat(paste0("# スペクトログラム:spectrogram=", pngfile_input, "\n"), file = csvfile_output, append =TRUE)
    num_page <-   stringr::str_sub(pngfile_input, start = 23, end = 24) %>% as.numeric()
    par(mar=c(0, 0, 0, 0)); #外側のマージンをゼロにする
    plot(NULL
        , xlim = c(0,1), ylim = c(0, 1)
        , xlab = "", ylab = "", yaxt = "n", xaxt = "n",xaxs = 'i', yaxs = 'i'
    )
    rasterImage(images[[num_page]], 0, 0, 1, 1)
    for( i in 0:(windows_a_page-1)){
      rect( xl, yb - i * dy, xr, yt - i * dy, col="transparent", border = "red")
    }
    while (flag_page_end == FALSE){
      cat("R> 声紋をクリック。無ければ範囲外（白い部分）をクリック。またはESPキー");
      z <- locator(n=1);
      if (is.null(z) == TRUE){# ESCが押されたなら
        flag_page_end <- TRUE
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
      
      time_offset <- (num_page - 1) * window_time * windows_a_page + window_time * y_position
      second_locator <- (time_offset + (x - xl) * (window_time)/(xr - xl)) 
      if(second_locator < 0)(length_preplay <- 0)
      time_locator   <- (time_offset + (x - xl) * (window_time)/(xr - xl) + time_start) %>% format("%Y.%m.%d,%H:%M:%S")
      freq_locator   <- (f_lcf + (y - (yb - y_position * dy)) * (f_hcf - f_lcf)/(yt - yb))
      
      answer <- menu(spices, title="\nR> 種類を選択してください:")
      # cat(paste0("Select:", spices[answer]))
      while(spices[answer] == "再生") {#再生
        start_play = second_locator - length_preplay;
        period = length_preplay + length_play;
        cat ("play", start_play, "to", start_play + period);
        cat (paste0("# 再生: ", start_play, " to ", start_play + period, "\n"), file = csvfile_output, append = TRUE);
        save_and_play(wave_data, add_to_base(), start_play, period);
        answer <- menu(spices, title="R> 種類を再選択してください");
        cat(paste0("Reselection = ", spices[answer],"\n"))
      }
      if(spices[answer] ==  "WAY｜保存") {#
        time_locator_file  <- (time_offset + (x - xl) * (window_time)/(xr - xl) + time_start) %>% format("%y%m%d_%H%M%S")
        file_sox_save <- paste0(time_locator_file, "｜WAY.wav")
        txt_sox_save  <- sprintf("sox -v %d %s %s trim %s %d", volume, path_wav, file_sox_save, second_locator - length_preplay, length_play)
        system(txt_sox_save);
        col_text <- "YELLOW"
      }
      if (answer == "0") {
        flag_page_end <- TRUE;
        break;
      }else{
        txt_kikimimi <- sprintf("%s,%s,F=%d[Hz]\n", time_locator , spices[answer], as.integer(freq_locator))
        cat(paste0("\nkikimimi>",txt_kikimimi))
        cat(txt_kikimimi, file = csvfile_output, append = TRUE)
        db <- rbind(db,c(num_page, x, y, spices[answer], col_text))
        text(x, y + 0.03, label = spices[answer], col= col_text); # 選択した文字列を図中に表示
      }
    }
    if(num_page == num_png){
      dev.off()
      before <- now
      now <- Sys.time()
      txt_ending <- paste0(
        format(time_end,"%Y.%m.%d,%H:%M:%S,STOP,,\n"),
        "# 終了解析時間:StopTime_toriR=", now, "\n",
        "# 分析時間:AnalysisTime_toriR=", format(as.numeric(difftime(now, before, unit="min")), digit=2), "min.\n"
      )
      cat(txt_ending, file = csvfile_output, append = TRUE)
      cat(txt_ending)
    }
  }


  ##画像に抽出結果を出力する ####
  answer <- menu(c("上書き", "終了"), title="\nR> 画像ファイルの処理")
  if (answer == 1){
    db <- db[-1,];
    cat("画像ファイルに結果を出力します")
    for (num_page in 1:num_png){
      # for (num_page in 1:2){
      pngfile_input  <- pngs[num_page];
      pngfile_output <- stringr::str_replace(pngfile_input, ".png", "_toriR.png");
      pngfile_output <- pngfile_input;
      png(pngfile_output, width = width_image, height = windows_a_page * height_image, bg="white")
      par(mar=c(0, 0, 0, 0)); #外側のマージンをゼロにする
      plot(NULL, xlim = c(0,1), ylim = c(0, 1), xlab = "a", ylab = "", yaxt = "n", xaxt = "n",xaxs = 'i', yaxs = 'i')
      rasterImage(images[[num_page]], 0, 0, 1, 1)
      text(0.9,0.99,label="toriR",col="RED")
      for (ii in 1:nrow(db)){
        w <- db[ii,];
        if ( num_page == w$num_png ){
          points(w$x, w$y, col=w$col_text, pch = 20);
          text(as.numeric(w$x), as.numeric(w$y) + 0.03, label = w$label, col= w$col_text);
        }
      }
      dev.off()
    }
  }
  setwd(dir_to_return)
}

config_add_to_base <- function(base_filename) {
  function(toadd="") {
    paste0(base_filename, toadd);
  };
}

check_and_goto_target_dir <- function(path_of_wav) {
  return_dir <- getwd();
  setwd(dirname(path_of_wav));
  add_to_base <- config_add_to_base(stringr::str_replace(basename(path_of_wav), ".wav", ""));
  ### parameter file laod ####
  file_param = add_to_base(".psgrm")
  if( ! file.exists(file_param) ){
    setwd(return_dir);
    stop(paste("No file:", file_param))
  }else{
    load(file = file_param, envir=parent.frame(n=2));
  };
  ### output file csv) ####
  csvfile_output = add_to_base(".csv");
  if(file.exists(csvfile_output)) {cat("ファイルに追記します: ", csvfile_output,"\n", sep="")};
  return(list(return_dir=return_dir, add_to_base=add_to_base));
}

parse_666filename <- function(path_wave) {
  info666 = stringr::str_split(basename(path_wave), "[._-]") %>% unlist;
  start = strptime(paste(info666[1], info666[2]), format="%y%m%d %H%M%S"); 
  end = strptime(paste(info666[1], info666[3]), format="%y%m%d %H%M%S"); 
  return(list(start=start, end=end))
}

find_pngs <- function(path_base) {
  path_dir = dirname(path_base);
  pngs = list.files(path = normalizePath(path_dir),
                    pattern = paste0(basename(path_base), "_P[0-9][0-9].png"));
  for (i in 1:length(pngs)) {
    pngs[[i]] = paste(path_dir, pngs[[i]], sep = "/")
  }
  return(pngs)
}

save_and_play <- function(wave_data, base_name, start, period) {
  start = as.integer(start);
  stop = as.integer(start + period);
  wave_file = sprintf("%s_%04d-%04d.wav", base_name, start, stop)
  if( ! file.exists(wave_file) ){
    start_frame = wave_data@samp.rate * start + 1
    stop_frame = wave_data@samp.rate * stop
    tuneR::writeWave(wave_data[start_frame:stop_frame], filename = wave_file)
  }
  # TODO how to get route to wd
  REL_PATH <- stringr::str_replace(getwd(), "/home/rstudio/data/", "");
  # relpath getwd() from /home/rstudio/data ?
  wave_URL = sprintf("http://localhost:8000/%s/%s", REL_PATH, wave_file)
  audio = tags$audio(
  controls="", autoplay="", name="media", 
  tags$source(src=wave_URL, type="audio/x-wav")
  )
  htmltools::html_print(audio)
}
