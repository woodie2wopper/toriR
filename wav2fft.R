# wav2fft.R
# R script for FFT of monoralized wav file | wavファイルをモノラル化してFFT（絶対値）を出力する
# 2020-05-04 (C) woodiw2wopper
# Load a script
library("tools")
library("tuneR")
library("fftw")
library("data.table")
source("LibR.R")
## 引数設定 ####
args <- commandArgs(trailingOnly = T)
# cat(paste("args=",args,"\n"),file=stderr())
if( length(args) > 0) {
  debug_flag=F; # debugモードの設定（図面を作成）
  inputfile            <- as.character(args[1]);
  fft_size               <- as.numeric(args[2]);
  outputfile_fft       <- as.character(args[3]);
  outputfile_fft_param <- as.character(args[4]); #R1.2
  filter_window        <- as.character(args[5]); #R1.2
  
  inputfile_body <- tools::file_path_sans_ext(basename(inputfile));
  song_format <- tools::file_ext(inputfile);
  }else{
  debug_flag=T; # debugモードの設定（コンソールで表示）
  
  inputfile <- "190607_032842-042842_short.wav"
  inputfile <- "190607_032842-042842.wav"
  inputfile <- "160618_060000-070000.wav"
  song_format <- "wav" ;
  image_format <-"pdf"
  fft_size <- 1024 ;# FFTするサイズの指定
  f_lcf <- 1000; #  800 ; # Low Cut Filtterの周波数[Hz]
  f_hcf <- 6000; # 6000 ; # Low Cut Filtterの周波数[Hz]
  f_lcf <- 10; #  800 ; # Low Cut Filtterの周波数[Hz]
  f_hcf <- 8000; # 6000 ; # Low Cut Filtterの周波数[Hz]
  image_threshold <- 4 ;# 閾値の設定
  # k <- 1  ; # 解析するセクション番号
  # pages <- 3 ; # 解析するセクションの数
  page_time <- 60 ; #セクション時間の指定 [sec]
  page_time <- 20 ; #セクション時間の指定 [sec]
  image_flag <- TRUE
  inputfile_body		<- "190607_032842-042842"
  outputfile_fft		<- "190607_032842-042842.fft"
  outputfile_fft_param	<- "190607_032842-042842.pfft"
  inputfile_body		<- "160618_060000-07000"
  outputfile_fft		<- "160618_060000-07000.fft"
  outputfile_fft_param	<- "160618_060000-07000.pfft"
  filter_window			<- "Blackman"
}

#ファイルの有無の確認
cat(paste0("R> input | input file=", inputfile,"\n"), file=stderr() );

if (! file.exists(inputfile)) {
  stop(paste0("R> inputfile |", inputfile, "がありません。\n"));
  # q()
}
sound_file_body    <- basename(inputfile);

### ファイルの読み込み ####
# inputfile <- paste(inputfile_body, song_format, sep=".")
print_stderr_system.time(
  paste("read  | sound file=", inputfile, "\t\t|", sep =""),
  switch( song_format
          ,"wav" = data <- readWave(inputfile)
          ,"WAV" = data <- readWave(inputfile)
          ,"mp3" = data <- readMP3(inputfile)
          ,"MP3" = data <- readMP3(inputfile)
          ,exit.flag = 1  # 対応フォーマットがない
  )
)

### 音声データの解析するための設定値 ####
sample_rate <- data@samp.rate
if (length(data@right) == length(data@left)){
  mono_data   <- data@right + data@left; # モノラルに変換しておく
}else{
  mono_data   <- data@left; # モノラルに変換し
}

t_step      <- 1 / sample_rate; #[sec.]# 最小時間と最小周波数間隔
f_step      <- sample_rate / fft_size;#[Hz] # 最小周波数間隔(f_step)

N           <- length(mono_data);# ファイル（曲）のデータ数
slots_total <- trunc( N / fft_size ) ; # slotの個数、切り捨て
trunc_N <-  slots_total * fft_size ; # 解析対象のデータ数
record_time <- trunc_N  * t_step; # 一曲の録音時間（record time）
# 表示用、解析用軸の値の設定
f_max    <- f_step * fft_size / 2;# 最大周波数
f_set    <- 1:(fft_size / 2); # FFTの周波数セットの基礎配列
f_axis   <- f_step * f_set ; #[hcf][lcf]; # [Hz]
f_size <- fft_size/2; # f_size   <- length(f_axis);

# メモリアロケート####
wav_set_mt   <- matrix(NA_real_, nrow = fft_size, ncol = slots_total);
fft_set_mt   <- matrix(NA_real_, nrow  = f_size , ncol = slots_total);

# パラメータの出力 ####
wd<- getwd()
print_stderr_system.time(
  paste("save  | param file=", outputfile_fft_param, "\t\t|", sep=""),
  save(list = c("inputfile",
                "wd",
                "sound_file_body",
                "song_format",
                "fft_size",
                "f_size",
                "f_max",
                "f_step",
                "sample_rate",
                "N",
                "t_step", 
                "record_time",
                "slots_total",
                "filter_window"
  ), ascii = TRUE, file = outputfile_fft_param
  )
)

#### デバック用 
if ( debug_flag == TRUE) pages <- 1 ;j <- 1;

# blackman計算 ####
bw <- blackman_window(fft_size) # 窓関数の数列の定義
print_stderr_system.time(
  paste0("window| モノラル化 | \t\t\t|"),
   wav_set_mt <- matrix(mono_data[1:trunc_N], nrow = fft_size, ncol = slots_total)
)

if(filter_window == "Blackman"){
  print_stderr_system.time(
    paste0("window| windows filter=\t", filter_window, "\t\t\t|"),
    wav_set_mt <- apply(wav_set_mt, 2, function(x){return(x * bw)})
  ) 
}
 
# fft計算 ####
print_stderr_system.time(
  paste("FFT   | slot_total=",slots_total,"\t\t\t\t|", sep=""),
  fft_set_mt <- apply(wav_set_mt, 2, 
                    function(x){
                      return(
                        abs(fft(x)[2:floor( fft_size / 2 + 1 )])
                        )
                      }
                    )
)
  
fft_set_mt <- t(fft_set_mt); # 互換性維持のために転置行列をかけて、行は周波数、列はtime_slotにする


memory <- format(object.size(fft_set_mt), units = "auto", standard ="legacy")
print_stderr_system.time(
  paste("fwrite| fft file=", outputfile_fft, "(", memory, ")", "\t|", sep =""),
  data.table::fwrite(as.data.frame(fft_set_mt, stringAsFactors = F), col.names = F, outputfile_fft)
)
