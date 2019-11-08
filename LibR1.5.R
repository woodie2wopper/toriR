# support functions
# @author woodiw2wopper <woodie2wopper@gmail.com>
# Copyright (C) 2019 woodiw2wopper
# R 用の自作関数の定義
# R1.3: 181013 HO: multiplot()を追加。
# R1.2: 180929 HO: トラツグミの声の分析関係を追加する
# R1.1.R 180810 H.Osaka
# R1.0.R 170805 H.Osaka
# 使用方法 ####
# source( "/Users/osaka/Desktop/daybreak/R/Script/LibR1.2.R" )

# [R1.5] HO 190721####
# clippingを追加。2つの閾値の指定でその範囲を超えるとクリッピング（振幅圧縮）が起こる
# xは定数でもベクトルでも行列でもいい
# clipping <- function(x, ratio, threshold){
#   return(ifelse(x > threshold, (x - threshold)/ratio + threshold, x))
# }
clipping <- function(x, ratio, threshold_lo,threshold_hi){
  return(
    ifelse(x > threshold_hi, (x - threshold_hi)/ratio + threshold_hi, 
           ifelse(x < threshold_lo, (x - threshold_lo)/ratio + threshold_lo, x)
    )
  )
}

# [R1.4] ####
# Bash側から読みだすのが本当だろうな
ext_fft_file     <- ".fft"
ext_fft_param    <- ".pfft"
ext_spgrm_parm   <- ".psgrm"
ext_spgrm_pdf    <- "_spgrm.pdf"

# [R1.3] ####
which_cond <- function(x, cond, func){
# 条件condの時のx[cond]のmaxとかminとかfuncを適用した時の位置を返す
  which(x == func(x[cond]))
}


multiplot <- function(fft_mt, freq_peak_SL, freq_peak_SM, xset, f_axis, k = 1, ratio_bskt = 1.3, lambda = 3){
  # k <- 7
  # m1 <- (k - 1) * slots_a_page + 1; # pageの開始番号
  # m2 <- m1      + slots_a_page - 1; # pageの終了番号
  # if (m2 > slots_total) {
  #   m2 <- slots_total
  # }; # 少し余っても最後まで計算させる
  # 
  # 
  # 
  # freq_peak_SM <- 4550
  # freq_peak_SL <- 1750
  # multiplot(fft_mt, freq_peak_SL, freq_peak_SM, c(m1:m2), f_axis, 5)
  # 

    # STFTのデータを受け取って、6個グラフを表示する
  # 使い方：multiplot(fft_mt[m1:m2], peak_SL, c(m1,m2), )
  def.par <- par(no.readonly = TRUE) # save default, for resetting...
  nf <- layout(matrix(c(1, 2, 2, 0,
                        3, 4, 4, 5,
                        3, 4, 4, 5,
                        0, 6, 6, 0), 4, 4, byrow = TRUE)); #, respect = TRUE]
  ## show the regions that have been allocated to each plot
  # layout.show(nf)
  
  par(mar = c(3, 4, 2, 2));
  par(family = "HiraKakuProN-W3"); #familyを設定することで文字化けが防止できます
  
  m1 <- xset[1];
  m2 <- xset[length(xset)];
  mc <- (m1 + m2) / 2;

  # peak_SL <- fbin_peak;
  # f_axisはグローバル変数
  
  #P1
  #  情報エリア
  plot(NULL, xlim = c(0,10), ylim = c(0, 10),
       xlab = "", ylab = "", xaxs = "i", yaxs = "i", xaxt  = "n", yaxt = "n");
  par(ps=14); text(5, 9, labels = paste0("No. ", k)); par(ps=12);
  text(5, 8, labels = paste0("Slot = ",   m1, " : ", m2))
  text(5, 7, labels = paste0("Time = ",   floor(slotno2time(m1)), " : ", ceiling(slotno2time(m2))," [s]"))
  text(5, 6, labels = paste0("Fp(SL) = ", round(freq_peak_SL, digits = 0), "Hz"))
  text(5, 5, labels = paste0("Fp(SM) = ", round(freq_peak_SM, digits = 0), "Hz"))
  text(5, 4, labels = paste0("λ = ", lambda))
  
  
  #P2
  if (length(freq_peak_SM) > 0){
    ydata <- fft_mt[m1:m2, fb(freq_peak_SM)]
  }else{
    ydata <- m1:m2
  }
  plot(m1:m2, ydata, type = "l", 
       xlab = "", ylab = "", xaxs = "i", yaxs = "i", las = 1);
  renge_bsk_SM <- fb(freq_peak_SM) + (-num_freq_basket:num_freq_basket);
  fsum_bskt_SM <- apply(fft_mt[m1:m2, renge_bsk_SM], 1, sum)/length(renge_bsk_SL); # fbin方向に加算しておく
  
  mavg_bskt_SM <- ratio_bskt * stats::filter(fsum_bskt_SM, rep(1, num_moving_avarage)) / num_moving_avarage
  points(m1:m2, mavg_bskt_SM, col = "RED", type ="l")
  text(mean(c(m1,m2)),  min(fft_mt[m1:m2, fb(freq_peak_SM)]) + 3, labels = "peak_SMの生スペクトル時間変動")
  abline(h = thrsld_SNR_dB_mov_ave_SL,  col = "GREEN", lty = 2);
  
  #P3
  nf_mt_mean <- apply(fft_mt[m1:m2,], 2, mean);
  if(length(nf_mt_mean) > 0){   
    xdata <- nf_mt_mean; # fft_mt_nrmからすごく小さい値になるので枠だけの表示
  }else{
    xdata <- f_axis
  }
  plot(xdata, f_axis, type ="l", col = "BLACK",
       xlab = "", ylab = "", xaxs = "i", yaxs = "i", las = 1, yaxt = "n")
  axis(2, at = seq(100*round(first(f_axis)/100), 1000*ceiling(last(f_axis)/1000), 500), las =2)
  text(mean(xdata), 1200, labels = "NF mean")
  abline(h = freq_low_SL,  col = "RED");
  abline(h = freq_high_SL, col = "RED");
  abline(h = freq_low_SM,  col = "BLUE");
  abline(h = freq_high_SM, col = "BLUE");

  #P4 
  
  image(x = m1:m2, y = f_axis, 
        -box_cox(as.matrix(fft_mt[m1:m2,]), lambda), 
        col = gray(0:12/12),
        xaxt  = "n", yaxt = "n",
        xlab = "", ylab = "Freq [Hz]")
  axis(1, at = seq(10*round(m1/10), 10*ceiling(m2/10), 20), las = 1)
  axis(2, at = seq(100*round(first(f_axis)/100), 1000*ceiling(last(f_axis)/1000), 200), las = 2)
  abline(h = f_axis[fb(freq_peak_SL)], col = "RED",  lty = 2);
  abline(h = f_axis[fb(freq_peak_SM)], col = "BLUE", lty = 2);
  
  par(new = T);
  
  xlim= slotno2time(c(m1,m2)); ylim = c(1, length(f_axis));
  plot(NULL, type ="l", xlim = xlim, ylim = ylim,
       xlab = "", ylab = "", xaxs = "i", yaxs = "i", xaxt  = "n", yaxt = "n");
  axis(3, at = seq(floor(xlim[1]), ceiling(xlim[2]), 0.5))
  axis(4, at = seq(ylim[1], ceiling(ylim[2]), 10), las = 2)
  
  #P5
  nf_mt_sd <- apply(fft_mt[m1:m2,], 2, sd);
  plot(nf_mt_sd, f_axis, type ="l", col = "BLACK",       
       xlab = "", ylab = "", yaxs = "i", las = 1, yaxt = "n")
  axis(2, at = seq(100 * round(first(f_axis) / 100), 1000 * ceiling(last(f_axis) / 1000), 500), las =2)
  
  points(nf_mt_sd[fb(freq_peak_SL)], freq_peak_SL, col = "RED", pch = 19)
  points(nf_mt_sd[fb(freq_peak_SM)], freq_peak_SM, col = "BLUE", pch = 19)
  text(mean(nf_mt_sd), 1200, labels = "NF sd")
  # text(mean(nf_mt_sd), 1200, labels = "NF sd")
  
  abline(h = freq_low_SL,  col = "RED");
  abline(h = freq_high_SL, col = "RED");
  abline(h = freq_low_SM,  col = "BLUE");
  abline(h = freq_high_SM, col = "BLUE");
  
  #P6
  if (length(freq_peak_SL) > 0){
    ydata <- fft_mt[m1:m2, fb(freq_peak_SL)]
  }else{
    ydata <- m1:m2
  }
  plot(m1:m2,   ydata,     type ="l", xlab = "", ylab = "", xaxs = "i", yaxs = "i", las = 1);
  
  renge_bsk_SL <- fb(freq_peak_SL) + (-num_freq_basket:num_freq_basket);
  fsum_bskt_SL <- apply(fft_mt[m1:m2, renge_bsk_SL], 1, sum)/length(renge_bsk_SL); # fbin方向に加算しておく
  
  mavg_bskt_SL <- ratio_bskt * stats::filter(fsum_bskt_SL, rep(1, num_moving_avarage)) / num_moving_avarage
  points(m1:m2, mavg_bskt_SL, col = "RED", type ="l")
  text(mean(c(m1,m2)),  min(fft_mt[m1:m2, fb(freq_peak_SL)]) + 3, labels = "peak_SLの生スペクトル時間変動")
  abline(h = thrsld_SNR_dB_mov_ave_SL,  col = "GREEN", lty = 2);
  #後始末
  par(def.par);  #- reset to default
}

fb <- function(x){
  # x[Hz]がf_axisの最も近いfbinを返す
  which.min(abs(x - f_axis))
}

rm_na <- function(lst, cond){
  # 関数 NAを取り去る
  res  <- lst[cond]
  if (sum(is.na(res)) > 0){
    res[-which(is.na(res))];# NAを削除する  
  }else{res}
  
}

append_NA <- function(flag_short, lst, num_NA){
  # flagをみてNAをnum_NA個追加する
  if (flag_short){
    append(lst, rep(NA, num_NA))
  }else{lst}
}



# [R1.2] #####

#### リストがあってそれを条件で表示する
# condplot <- function(lst, condition, ...){
#   plot((1:length(lst))[condition],lst[condition], ...)
# }
# condpoints <- function(lst, condition, ...){
#   points((1:length(lst))[condition],lst[condition], ...)
# }
condplot   <- function(lst, condition, xlim, ...){
  if(sum(lst[condition], na.rm = T) >0){
    plot  ((xlim[1]:xlim[2])[condition], lst[condition], ...)
  }
}

condpoints <- function(lst, condition, xlim, ...){
  if(sum(lst[condition], na.rm = T) >0){
    points((xlim[1]:xlim[2])[condition], lst[condition], ...)  
  }
}

#｜ Slot_NoとTimeの変換の関数定義 
slotno2time <- function(slot_no, fft_size = 1024, sample_rate = 44100) {
  return(slot_no * fft_size / sample_rate)
}
time2slotno <- function(time, fft_size = 1024, sample_rate = 44100) {
  return(trunc(time * sample_rate / fft_size))
}



# [R1.1] ####
#### 現在のディレクトリをコピーする
gd <- function(){
  dir <- getwd()
  cat(dir, file=stderr());
  cat(dir, file=pipe("pbcopy"))
  }
# 使い方：gd()とタイプすれば現在のディレクトリをMacにコピーできる



##### 混合行列 
confusion_matrix <- function(CM){
  #http://kusanagi.hatenablog.jp/entry/2017/03/02/131510
  # 適中率/Accuracy（全体の内，真陽性と真陰性が占める割合）
  # エラー率/Error Rate（1-的中率）
  # 感度/Sensitivity （真の状態が陽性であるもののうち，陽性と判断できた割合）
  # 特異度/Specificity （真の状態が陰性であるもののうち，陰性と判断できた割合）
  # 陽性適中率　（陽性と判断したもののうち，真の状態が陽性である割合）
  # 陰性適中率　（陰性と判断したもののうち，真の状態が陰性である割合）
  # 陽性尤度比　（真の状態が陽性であるひとが陰性であるひとよりも何倍検査結果が陽性になるか）
  # 陰性尤度比　（真の状態が陰性であるひとが陽性であるひとよりも何倍検査結果が陰性になるか）
  # 尤度比（ゆうどひ）とは、尤度（検査における感度や特異度など）の比であり、比率として実数で表す。なお、尤度（なりやすさ、起こりやすさ）は確率であり、通常は比率として0～1で表すが、％として0％～100％で表す場合もある。
  # 検査結果が陽性の場合の陽性尤度比と、検査結果が陰性の場合の陰性尤度比がある。
  # 一般に、尤度比と言われれば、検査が陽性だった場合の陽性尤度比を表す場合が多い。
  # なお、尤度比はROC曲線の傾き、即ち「感度/(1－特異度)」であり、「感度＝1－特異度」（つまり「感度＋特異度＝1」）の場合は「尤度比＝1」である。
  Rate<-CM/sum(CM)
  TP   <- CM[1,1]
  FP   <- CM[1,2]
  FN   <- CM[2,1]
  TN   <- CM[2,2]
  TPR  <- TP/(TP + FN)
  FPR  <- FP/(FP + TN)
  FNR  <- FN/(FN + TP)
  TNR  <- TN/(TN + FP)
  Acc  <- (TP+TN)/sum(CM)
  Err  <- 1-Acc
  Sens <- TP/(TP+FN)
  Spec <- TN/(FP+TN)
  PPV  <- TP/(TP+FP)
  NPV  <- TN/(FN+TN)
  LRP  <- Sens/(1-Spec)
  LRN  <- (1-Sens)/Spec
  
  # Result<-list(
  #   "Confusion Matrix｜混合行列"=CM,
  #   "Confusion Rates｜混合行列比率"=Rate,
  #   "Accuracy｜適中率"=Acc,
  #   "Error Rate｜エラー率"=Err,
  #   "Sensitivity｜感度"=Sens,
  #   "Sepcificity｜特異度"=Spec,
  #   "PPV｜陽性適中率"=PPV,
  #   "NPV｜陰性適中率"=NPV,
  #   "LR+｜陽性尤度比"=LRP,
  #   "LR-｜陰性尤度比"=LRN
  # )	
  Result<-list(
    ConfusionMatrix=CM,
    ConfusionRates=Rate,
    Accuracy=Acc,
    ErrorRate=Err,
    Sensitivity=Sens,
    Sepcificity=Spec,
    PPV=PPV,
    NPV=NPV,
    LRP=LRP,
    LRN=LRN,
    TPR=TPR,
    FPR=FPR,
    TNR=TNR,
    FNR=FNR
  )
  return(Result)
}

#｜BOX COX（冪正規変換）
#  180527追加：image()のための変換 0.6 0.7がちょうどいい
box_cox <- function(y, lambda){
  # 使い方：fft_page <- box_cox(fft_set_mt[seq_x,], lambda = lambda)
  if(lambda != 0){
    (y^lambda -1 ) / lambda
  }else{
    log(y)
  }
}
#### blackman_window()｜ブラックマン窓関数 
blackman_window <- function(n){
  lst <- (1:n-n/2)/n*2
  return(sapply(lst,function(x){
    if (- 1 <= x && x <= 1 ){
      1/50*( 25* cos (pi*x) + 4* cos (2*pi*x) + 21 )
    }else{0}
  }
  )
  )
}
# plot(blackman_window(100),type="l")

# 関数の計算時間をメッセージとともに表示
print_stderr_system.time <- function( message, func ){
  # メッセージは；paste("R> 計算中: slot数",slots_total),
  cat( sprintf("R> %s", message), file = stderr())
  cpu_time <- sprintf( "%05f", system.time(func)[1])
  message_res <- paste(" CPU (User) time =", cpu_time, "[sec]\n", sep = " ")
  cat(message_res,file=stderr())
}

# my.read.csv()｜ファイルが存在しなければ終了する
my.read.csv <- function(file,header=TRUE,comment.char="#",as.is=1){
  # as.is はfactorにしない
  # 呼び出す時＝read.csv(file=bird.file, header=TRUE)
  if ( ! file.exists(file)) {
    cat(paste(" R> ファイルがありません：",file),"\n")
    browser()
  }
  return(read.csv(file,header,comment.char="#"))
}

# my.read.table()｜ファイルが存在しなければ終了する
my.read.table <- function(file, ...){
  # 呼び出す時＝read.csv(file=bird.file, header=TRUE)
  if ( ! file.exists(file)) {
    cat(paste(" R> ファイルがありません：",file),"\n")
    browser()
  }
  return(read.table(file, ...))
}


# sun.height.from.time()｜鳴出しの高度を求める 
#sun.height.from.time <- function(t1,tw){-(6-0.53)*as.numeric(t1)/as.numeric(tw)}; 
sun.height.from.time <- function(t1,tw){-(6-0.85)*as.numeric(t1)/as.numeric(tw)};
# sun.height.from.time 時刻(t1)の時の太陽高度、twは市民薄明開始時刻

# intensity.from.sunheight())｜高度から照度に変換する 
#I=exp{(H一 β)/α}(2) 
## パラメータ1：height 数字で太陽の高度(deg.)
## パラメータ2：weather 文字＝快　晴　曇　雨　霧
intensity.from.sunheight <- function(height,weather){
  alpha <- 0.87;
  if (weather == "快") {beta <- -7.43};# 快晴(0/10)で一7.43
  if (weather == "晴") {beta <- -7.03};# 晴(5/10)で一7.03
  if (weather == "曇") {beta <- -6.40};# 中層雲による曇天(10/10)で一6.40
  if (weather == "雨") {beta <- -5.15};# 下層雲による曇天(10/10)で一5.15
  if (weather == "霧") {beta <- -5.15};# 下層雲による曇天(10/10)で一5.15
  if (height > 0 || height < -7 ){ res <-NA
  }else{res<-exp((height-beta)/alpha)
  }
  return(res)
}

# daysdata2monthdata()｜日数データを月毎のデータに変換
# パラメータ1(x.data)はlist()でdaysごとのデータが入っている。
# パラメータ2(x.days)はx.dataと同じ長さのリストで、日数が入っている
# 呼び出し方：daysdata2monthdata(data$鳴き出し時間,data$日数)とかでデータを月毎に区分する。
daysdata2monthdata<-function(x.data,x.days){ 
  monthdays<-seq(as.Date("2015-01-01"), as.Date("2015-12-31"), by="months")
  days.month <- sapply(
    monthdays,function(x) {
      return (length(seq(as.Date("2015-01-01"),as.Date(x),"days"))-1)
      }
    )
  monthdata <- list()
  for(i in 1:11){
    monthdata <- c(monthdata, list(x.data[ days.month[i]< x.days & x.days < days.month[i+1]]))
  }
  i=12;
  monthdata <- c(monthdata, list(x.data[days.month[i] < x.days] ))
  names(monthdata) <- paste(seq(1:12), "月", sep = "")
  return(monthdata)
}

# cat.stderr()｜catでSTDERRに出力する
# 呼び出し方：cat("Goodbye, cruel World!\n", file = stderr())
cat.stderr <- function(x.list){
  cat(x.list, file = stderr())
}

# delta.twilight()｜生沢の市民薄明の時間を返す関数
# 引数無し
delta.twilight <- function(){
  filename  <- "/Users/osaka/Desktop/daybreak/reference/各地（大磯・密陽・仙台）の情報｜日の出、地図、天候）/日の出（大磯）.txt"
  #/Users/osaka/Desktop/daybreak/reference/日の出（大磯）.txt"
  data  <- read.csv(filename,header=T)
  days  <- as.Date(data$日付,format="%Y/%m/%d")-as.Date(data$日付[1],format="%Y/%m/%d")
  times <- data$日の出
  times.sunrise <- as.POSIXct(paste("2016/01/01",times,sep=" "), 
                              format="%Y/%m/%d %H:%M:%S") 
  times <-data$市民薄明開始
  times.twilight <- as.POSIXct(paste("2016/01/01",times,sep=" "), 
                               format="%Y/%m/%d %H:%M:%S") 
  result <- times.twilight-times.sunrise
  return(result)
  # abline(h=0,col="red")
  # points(days,delta.twilight,type="l",col="red",ylim=c(-40,-20))
  # par(ps = 10);text (90,-20,"市民薄明")
}
