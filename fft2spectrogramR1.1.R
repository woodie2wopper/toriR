# ############ FFTからSpectrogramを出力するプログラム
# [R1.1] 190721 HO クリッピングの設定
# [R1.0] 190630 HO imagep()のカラーの指定
# [R0.9] 190630 HO  windowでデータが足りない場合は打ち切りとした。時間でwindowを区切った
# [R0.8] 190630 HO 図面がきちんと出ないバグがあるのと、高速化する。単位系をKHzからHzに戻す
# [R0.7] 190625 HO ファイルとディレクトリはbashが受け持つ
# [R0.6] 190622 HO 一枚あたりの図面の数を引数で受け取る
# [R0.5] 190616 HO
# [R0.4] 190615 HO: 
# [R0.3] 190528 HO: pageの意味を変える。一つ一つのSpectrogramは窓(window)と呼ぶことにする"
# options(warn=-1);

programname <- "fft2spectrogramR1.1.R";

# library("stringr", warn.conflicts=F); #https://heavywatal.github.io/rstats/stringr.html
library("data.table", warn.conflicts=F)
library("oce",warn.conflicts=F);

# 引数を評価・初期値 ####
args <- commandArgs(trailingOnly = T);

# ライブラリの読み込み ####
source("/Users/osaka/Desktop/daybreak/R/Script/LibR1.5.R")

# cat(paste("args=",args,"\n"),file=stderr())
if( length(args) > 0) {
  debug_flag=F; # debugモードの設定（図面を作成）
  input_fft_file     <- as.character(args[1]);
  input_fft_param    <- as.character(args[2]); #R1.2
  output_spgrm_param <- as.character(args[3]);
  output_image_body  <- as.character(args[4]);
  lambda               <- as.numeric(args[5]); #R1.2
  f_lcf                <- as.numeric(args[6]);
  f_hcf                <- as.numeric(args[7]);
  image_format       <- as.character(args[8]); #R1.2
  window_time          <- as.numeric(args[9]);
  test_mode           <- as.logical(args[10]); #テストモードか？
  windows_a_page      <- as.numeric(args[11]); #
  image_flag          <- as.character(args[12]);
  width_image           <- as.numeric(args[13]); 
  height_image          <- as.numeric(args[14]); 
  color_opt           <- as.character(args[15]);
  ratio_clipping        <- as.numeric(args[16]); # クリッピングのレートデフォルト＝4
  threshold_clipping_lo    <- as.numeric(args[17]); # クリッピングのレートデフォルト＝4
  threshold_clipping_hi    <- as.numeric(args[18]); # クリッピングのレートデフォルト＝4
  mode_comp             <- args[19]
  cat(paste("color_opt=",color_opt))
}else{
  debug_flag=T; # debugモードの設定（コンソールで表示）

  input_fft_file     <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/180420_051000-052000.fft"
  input_fft_param    <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/180420_051000-052000.pfft"
  output_spgrm_param <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/180420_051000-052000.psgrm"
  output_image_body  <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/180420_051000-052000"
  
  # input_fft_file <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190606_No4_EVISTR/190607_032842-042842_short.fft"
  # input_fft_param <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190606_No4_EVISTR/190607_032842-042842_short.pfft"
  # output_spgrm_param<- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190606_No4_EVISTR/190607_032842-042842_short.psgrm"

  input_fft_file     <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190501_233200-233600.fft"
  input_fft_param    <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190501_233200-233600.pfft"
  output_spgrm_param <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190501_233200-233600.psgrm"
  output_image_body  <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190501_233200-233600"
  
  input_fft_file     <- "/Volumes/Bird_Song-10TB/Y夜間自動録音/O1904-大峰城址/190427/190427_180000-190000.fft"
  input_fft_param    <- "/Volumes/Bird_Song-10TB/Y夜間自動録音/O1904-大峰城址/190427/190427_180000-190000.pfft"
    output_spgrm_param <- "/Volumes/Bird_Song-10TB/Y夜間自動録音/O1904-大峰城址/190427/190427_180000-190000.psgrm"
    output_image_body  <- "/Volumes/Bird_Song-10TB/Y夜間自動録音/O1904-大峰城址/190427/190427_180000-190000"
  image_format <-"png"
  f_lcf <- 0; #  800 ; # Low Cut Filtterの周波数[Hz]
  f_hcf <- 12000; # 6000 ; # Low Cut Filtterの周波数[Hz]
  window_time <- 60 ; #セクション時間の指定 [sec]
  lambda <- 0.5
  test_mode <- TRUE
  windows_a_page <- 4; # 1ページあたりのウィンドウの数
  image_flag <- FALSE; # 画像のファイル出力
  # 設定｜出力グラフ ####
  
  width_image <- 312*2# 出力の幅(pixel)
  height_image <- 125; # 出力の高さ(pixel)
  color_opt <- "color"
  ratio_clipping <- 4; 
  threshold_clipping_lo <- -200; #dB
  threshold_clipping_hi <- -100; #dB
  mode_comp <- "clip"; # "boxcox"; #clip"
}
# if (mode_comp == "") {cat("R> mode_compが未設定です"): q()}
# 入出力ファイル ####
inputfile_basename <- basename(input_fft_file)

# 日付の設定####
file_info <- unlist(stringr::str_split(inputfile_basename,"[_-]")); # unlistが必要。最初の3つを取り出す
record_date <- file_info[1]; # 録音日
start_time  <- paste(record_date, file_info[2], sep =" ")
start_time  <- strptime( start_time, format="%y%m%d %H%M%S") ; # 録音開始時刻
# end_time    <- paste(record_date, file_info[3], sep = " "); # 録音終了時間
# end_time    <- strptime( end_time, format="%y%m%d %H%M%S") ; # 録音開始時刻


#### パラメータファイルの読み込み ####
print_stderr_system.time(
  paste("load \t|parameter file=", input_fft_param, "\t|",sep=""),
  load(input_fft_param) #saveで変数保存したため
)


#### 読み込み｜FFTファイル ####
print_stderr_system.time(
  paste("fread\t|fft file=", input_fft_file, "\t|",sep=""),
  fft_mt <- as.matrix(data.table::fread(file = input_fft_file, data.table = FALSE))
)

# 値の設定
f_max   <- f_step * fft_size / 2;# 最大周波数
f_set   <- 1:(fft_size / 2); # FFTの周波数セットの基礎配列
f_set  <- f_step * f_set ; #[hcf][lcf]; # [Hz]

# 周波数フィルタの設定 #####
## HCFの設定周波数がデータの持つ最大周波数より大きければ何もしない
if (f_hcf > f_max) {f_hcf <- f_max}; # 高すぎる最高周波数の対応
if (f_hcf < f_max){
  hcf <- -c(ceiling(f_hcf / f_step):floor(fft_size / 2)) ;# ceilingは切り上げ
}else{
  hcf <- 1:floor(fft_size / 2); # 何も変更しない
}

if (f_lcf > f_step) { #
  lcf <- -c(1:floor(f_lcf / f_step - 1)); # Low Cut Filtter。f_lcfを含めるために1引いておく
}else{
  # len_lcf <- length(hcf)
  len_lcf <- floor(fft_size / 2)- length(hcf); #R1.1でデバックした
  lcf <- 1:len_lcf; # 何も変更しない
}


f_set <- f_set[hcf][lcf];
num_faxis <- length(f_set);

slots_a_window <- ceiling(window_time * sample_rate / fft_size); # windowあたりのslot数(slots_a_window)　

# 間引く数を設定####
# 表示幅(width_image)より窓のスロットの数(slots_a_window)が小さい場合：
if (slots_a_window > width_image){
  num_decimation <- trunc(slots_a_window / width_image)
}else{
  num_decimation <- 1
}


# windowとpageの設定 ####
total_windows <- ceiling(record_time / window_time); # 全体のwindowの数
total_pages   <- ceiling(total_windows / windows_a_page); # 全体のページ数

slots_total_of_pages <- slots_a_window * total_windows; #全ページのスロット数
slots_of_last_window <- slots_total_of_pages - slots_total; # 最後のwindowで足りないslots

#### 行列への生成 ####
#｜窓で足りない部分をゼロ埋めする ####
fft_rmt   <- fft_mt[,hcf][,lcf]; # 行列から指定外周波数のデータを削除する
zero_row <- matrix(0, nrow = slots_of_last_window, ncol =num_faxis);
fft_rmt <- rbind(fft_rmt, zero_row)

# clipping <- function(x, ratio, threshold){
#   return(ifelse(x > threshold, (x - threshold)/ratio + threshold, x))
# }
# ｜BoxCox変換とノーマライズ ####
fft_rmt_norm <- fft_rmt/ max(fft_rmt)
if(mode_comp == "boxcox"){
  print_stderr_system.time(
    paste("BoxCox変換\t|\t\t\t\t\t|",sep=""),
    fft_boxcox <-
      - 1 * apply(fft_rmt_norm, 2,
            function(x){box_cox(x, lambda=lambda)}
      )
  ) # 
  fft_compressed <- fft_boxcox
} 

if(mode_comp == "clip"){
  print_stderr_system.time(
    paste("Clipping-dB 変換\t|ratio=", ratio_clipping, ", threshold_clipping=", threshold_clipping_lo, ",",threshold_clipping_hi,"\t|",sep=""),
    fft_rmt_db_clip <- clipping(-20 * log(fft_rmt), ratio_clipping, threshold_clipping_lo, threshold_clipping_hi)
  )
  fft_compressed <- fft_rmt_db_clip
} 


if(mode_comp == "norm")   fft_compressed <- fft_rmt_norm



#### デバック用 ####
if ( debug_flag == TRUE) {
  i <- 1;
  k<-1;
  # windows_a_page <- 6;
}


if (color_opt == "color"){
  col_opt <- oce.colorsViridis;
  # fft_boxcox <- - fft_boxcox;
  col_str <- "WHITE";
}else{
  col_opt  <- grey(0:12/12)
  col_str <- "BLUE"
}
# 作図｜image() ####
print_stderr_system.time(
  paste0("作図(PNG)\t|total_pages=",total_pages,"\t\t\t\n"),
  for (i in 1:total_pages){
  # 複数の図をプロットする ##### pageごとの出力
      imagefile <- paste0(output_image_body, "_P", sprintf("%02d",i), ".", image_format)
      png(file = imagefile, width = width_image, height = windows_a_page * height_image, bg="white")
      par(mfrow=c(windows_a_page, 1)); # 画面を m 行 n 列に分割する．
      par(mar=c(1, 4, 1, 1));  # 底辺，左側，上側，右側の順に余白の大きさを行で指定．
      
      for (k in 1:windows_a_page){ # window毎の周波数解析
        # windowの表示slot範囲指定
        # m1 <- (i - 1) * windows_a_page * slots_a_window + (k - 1) * slots_a_window + 1; # windowの開始番号
        time_start_window <- window_time * ((i - 1) *  windows_a_page + (k - 1))
        if(time_start_window >= trunc(record_time)){break}
        m1 <- time2slotno(time_start_window, fft_size = fft_size, sample_rate = sample_rate)
        m2 <- m1 + slots_a_window - 1; # 
      　if (m2 > slots_total) {m2 <- slots_total_of_pages}
        if (m1 > m2){break}; # 最後が変になったらloopをでる
        # m_seq  <- seq(from = m1, to = m2); # 間引く
        m_seq  <- seq(from = m1, to = m2 , by = num_decimation); # 間引く
        # tmin   <- round(slotno2time(m1,fft_size = fft_size, sample_rate = sample_rate)); # 表示時間の最小値
        # tmax   <- round(slotno2time(m2,fft_size = fft_size, sample_rate = sample_rate)); # 表示時間の最大値
        tmin   <- time_start_window
        tmax   <- tmin + window_time
        t_set <- slotno2time(m_seq, fft_size = fft_size, sample_rate = sample_rate); #a, b 間を n 等分する等差数列を生成．
        cat(paste("tmin=", tmin, "\ttmax=", tmax, "\n"))
        par(ps = 16)
        
        fft_window <- - fft_compressed[m_seq, ];
        imagep(t_set, f_set # 軸も周波数と時刻に同期
            , fft_window
            , xlab = "", ylab = "", yaxt = "n", xaxt = "n",xaxs = 'i', yaxs = 'i'
            , decimate=FALSE
            , col = col_opt
          )# https://hansenjohnson.org/post/spectrograms-in-r/
        

        # windows の表示 ###
        par(ps = 18)
        xpos <- t_set[1] + (tail(t_set, n=1) - t_set[1]) * 0.3;
        ypos <- f_lcf + (f_hcf - f_lcf)  * 0.9; 
        
        # start_timeflame <- start_time + round(slotno2time(m1, fft_size = fft_size, sample_rate = sample_rate));
        # end_timeflame   <- start_time + round(slotno2time(m2, fft_size = fft_size, sample_rate = sample_rate));
        start_timeflame <- start_time + tmin;
        end_timeflame   <- start_time + tmax;
        info_timeflame <- paste0(format(start_timeflame, "%Y-%m-%d,%H:%M:%S-"),
                                format(end_timeflame, "%M:%S ["), mode_comp, "]");
        text(xpos, ypos, info_timeflame, col = col_str);
      }
      cat(paste("png file output:",imagefile, "\n" ))
      dev.off() 
  }
)

now  <-  Sys.time()

# パラメータの出力####
print_stderr_system.time(
  paste("save  | spgrm file=\t", output_spgrm_param, "\t\t|", sep=""),
  save(list = c(
    "now",
    "fft_size",
    "input_fft_file",
    "input_fft_param",
    "lambda",
    "f_lcf",
    "f_hcf",
    "f_max",
    "image_format",
    "window_time",
    "total_pages",
    "windows_a_page",
    "width_image",
    "height_image",
    "test_mode",
    "num_decimation",
    "color_opt",
    "ratio_clipping",
    "threshold_clipping_lo",
    "threshold_clipping_hi",
    "mode_comp"
  ), ascii = TRUE, file = output_spgrm_param
  )
)


