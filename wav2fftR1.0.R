# ############ wavファイルをモノラル化してFFT（絶対値）を出力する28
# [R0.9] 190626 HO データがおかしいので直す
# [R0.8] 190623 HO ディレクトリの関係を整理する。入出力も全てのファイルはBASHで面倒を見る。
# [R0.7] 190617 HOまあこれでいいですか
# [R0.6] 未完成！！！！！180929 Ho:FFTのステレオは位相の重ね合わせで絶対値にする。blackman_windowをかける
# [R0.5] 180923 Ho:波形によってに無音があればこれを小さい値のランダムノイズを入れておく。
# [R0.4] 180826 Ho:波形によっては頭に"0"が入っている場合があるようだ。これを取っておく
# [R0.3] 180820 Ho:出力ファイル名を受け入れる
# [R0.1] 1807 Ho:新規作成
# 参考ファイル＝スペクトログラムトピークサーチR1.7_test.R 
# Load a script
# print(paste("getwd=",getwd()));
library("tools")
library("tuneR")
library("fftw")
library("data.table")
source("/Users/osaka/Desktop/daybreak/R/Script/LibR1.4.R")
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
  
  # setwd(                           args[1]); 
  # inputfile_body                <- args[2] ;
  # song_format                   <- args[3] ;
   # cat(paste("R> inputfile=", inputfile, "\n"))
  
    # dirname(inputfile)
  inputfile_body <- tools::file_path_sans_ext(basename(inputfile));
  song_format <- tools::file_ext(inputfile);
  # cat(paste0("song_format=", song_format, "\n"))
  }else{
  debug_flag=T; # debugモードの設定（コンソールで表示）
  
  # setwd("/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190606_No4_EVISTR")
  inputfile <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190606_No4_EVISTR/190607_032842-042842_short.wav"
  inputfile <- "/Users/osaka/Desktop/daybreak/R/test/test_fft2spectram.R/190606_No4_EVISTR/190607_032842-042842.wav"
  inputfile <- "/Users/osaka/toriR\ Dropbox/Osaka\ Hideki/Public/toriR/sound_kagawa/160618/160618_060000-070000.wav"
  song_format <- "wav" ;
  image_format <-"pdf"
  fft_size <- 1024 ;# FFTするサイズの指定
  f_lcf <- 1000; #  800 ; # Low Cut Filtterの周波数[Hz]
  f_hcf <- 6000; # 6000 ; # Low Cut Filtterの周波数[Hz]
  f_lcf <- 10; #  800 ; # Low Cut Filtterの周波数[Hz]
  f_hcf <- 8000; # 6000 ; # Low Cut Filtterの周波数[Hz]
  # slots_a_page <- 217*2; # pageのslotの個数 217個で約5秒
  image_threshold <- 4 ;# 閾値の設定
  # k <- 1  ; # 解析するセクション番号
  # pages <- 3 ; # 解析するセクションの数
  page_time <- 60 ; #セクション時間の指定 [sec]
  page_time <- 20 ; #セクション時間の指定 [sec]
  image_flag <- TRUE
  # ext_fft_file <- ".fft"
  inputfile_body <- "190607_032842-042842"
  outputfile_fft    <- "190607_032842-042842.fft"
  outputfile_fft_param  <- "190607_032842-042842.pfft"
  inputfile_body <- "160618_060000-07000"
  outputfile_fft    <- "160618_060000-07000.fft"
  outputfile_fft_param  <- "160618_060000-07000.pfft"
  # image_flag <- FALSE
  filter_window <- "Blackman"
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

# [R0.4] 頭に0があったら取っておく
# if(sum(mono_data[1:fft_size]) == 0){
#   mono_data <- mono_data[-c(1:fft_size)]
# };

N           <- length(mono_data);# ファイル（曲）のデータ数
slots_total <- trunc( N / fft_size ) ; # slotの個数、切り捨て
trunc_N <-  slots_total * fft_size ; # 解析対象のデータ数
record_time <- trunc_N  * t_step; # 一曲の録音時間（record time）
# 表示用、解析用軸の値の設定
f_max    <- f_step * fft_size / 2;# 最大周波数
f_set    <- 1:(fft_size / 2); # FFTの周波数セットの基礎配列
f_axis   <- f_step * f_set ; #[hcf][lcf]; # [Hz]
f_size <- fft_size/2; # f_size   <- length(f_axis);
# t_set   <- 1:slots_a_page; # slotのデータセットの基礎配列

# if (slots_total * fft_size > N){ slots_total <- slots_total -1 }; # Nを越えるとやめる

# メモリアロケート####
# http://nov12.hatenadiary.jp/entry/2018/02/23/041823
# fft_set_df   <-data.frame(matrix(NA_real_, nrow = slots_total, ncol = f_size )) ;
wav_set_mt   <- matrix(NA_real_, nrow = fft_size, ncol = slots_total);
fft_set_mt   <- matrix(NA_real_, nrow  = f_size , ncol = slots_total);

# パラメータの出力 ####
# save(param, file = outputfile_fft_param);# 設定を出力しておく(write.csvだとdataflameに変換されるようだ。だから変数をそのままsaveする)

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
                #"f_axis",
                "filter_window"
  ), ascii = TRUE, file = outputfile_fft_param
  )
)

#### デバック用 
if ( debug_flag == TRUE) pages <- 1 ;j <- 1;
#### デバック用 
# system.time(



# blackman計算 ####
bw <- blackman_window(fft_size) # 窓関数の数列の定義

# small_number <- 1 / 100000; #小さい値として-100dBとした。
# print_stderr_system.time(
#   paste0("window| monauralized | \t\t\t|"),
#   for (j in 1:slots_total){
#     s1 <- (j - 1) * fft_size + 1;# 絶対データ番号に変換。j=1の時最初のデータのため1足しておく
#     s2 <- s1    + fft_size - 1; # slotのサイズはfft_size。大きさはfft_sizeなので1引いておく
#     wav_set_mt[,j]  <- mono_data[s1:s2]
#   }
# )

print_stderr_system.time(
  paste0("window| モノラル化 | \t\t\t|"),
   wav_set_mt <- matrix(mono_data[1:trunc_N], nrow = fft_size, ncol = slots_total)
)

# margin=1で行であるfft_size分の波形データに作用させる。しかし戻り値は行列が入れ替わってしまう。なのでmargin=2として行列が入れ替わらないようにする。
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
# cat(dim(fft_set_mt))
# for (j in 1:slots_total){
#     # message(paste("R> Process:j=", j));
#     s1 <- (j - 1) * fft_size + 1; # 絶対データ番号に変換。j=1の時最初のデータのため1足しておく
#     s2 <- s1    + fft_size - 1; # slotのサイズはfft_size。大きさはfft_sizeなので1引いておく
#     
#     fft_data <- fft(wav_data)[2:floor( fft_size / 2 + 1 )]; # 第1のデータはDCなので取っておく
#     fft_abs  <- abs(fft_data); #[hcf][lcf] ; # フィルタをかける。上から削除するのが鉄則
#     fft_set_mt[j, ] <- fft_abs; # 行列の生成。各rowにFFTの結果が入っている
#     # property_mt[j,3:property_col_no] <-  c(j, property(fft_abs));# ここは少しトリッキー、#1,#2は録音日と録音開始時間
#   }
# )



# write.table(property_df, sep = ",", quote = FALSE, row.name = FALSE, file = outputfile_peak);
# cat(paste("R> property_dfを出力(write.table)しました：", outputfile_peak, "\n"), file=stderr());
memory <- format(object.size(fft_set_mt), units = "auto", standard ="legacy")
print_stderr_system.time(
  paste("fwrite| fft file=", outputfile_fft, "(", memory, ")", "\t|", sep =""),
  data.table::fwrite(as.data.frame(fft_set_mt, stringAsFactors = F), col.names = F, outputfile_fft)
)
# stringAsFactors = Fにしないとfactor()になってしまい面倒
# cat(paste("R> fft_set_mtを出力(data.table::fwrite)しました：", outputfile_fft, "\n"), file=stderr())

