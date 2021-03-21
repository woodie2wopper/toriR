#!/usr/bin/env bash
# ICRKikimimi.bash; 64形式に対応
# 2021-03-21 (C) woofie2wopper

# ################################################################################
# 初期化
# ################################################################################
CMD_SESSION=$( basename $0 )
d_log=$HOME/log
[ -d $d_log ] || mkdir $d_log
f_log="$d_log/$CMD_SESSION.$(date '+%y%m%d_%H%M%S').$$.clog"
exec 2> $f_log
set -xveu
#
# 66形式からエポック秒を得る
function _66_to_epoch() {
	uxtime="20${1:0:2}-${1:2:2}-${1:4:2} ${2:0:2}:${2:2:2}:${2:4:2}"
	gdate -d "$uxtime" +%s
}

#
# abort
function abort {
   echo "$@" 
   exit 1
}

#debug="echo "
debug=":"

u=(); i=0; j=0;
u[i++]=" USAGE: ${CMD_SESSION} 030A_151204_1640.WAV [ifs|ifn] -090000 [show_org|-] show_maker" 
u[i++]=""
u[i++]=" 機能：1. 音源をファイルスタンプベースに666フォーマットのファイル名で返す"
u[i++]="       2. 拡張子は小文字にする"
u[i++]="       3. 機器情報などlogファイルを出力します。場所は$HOME/log です。"
u[i++]="       4. ファイル名が同じフォーマットの場合、デバイス名をディレクトリ名から取得します。その場合、デバイス名はフルパスの2つ目のディレクトリと仮定しています"
u[i++]="       5. オプションは順番通りに設定してください。[a|b]はaかbかの意味です。"
u[i++]=" OPT : [ifs|ifn]はファイルのタイムスタンプあるいかファイル名の時刻を無視する(Ignore File Stamp/Ignore File Name)"
u[i++]=" OPT : [timediff] 時差 : %H%M%Sで入力してください"
u[i++]=" OPT : [show_org] オリジナルファイルを表示します。"
u[i++]=" OPT : [show_maker] メーカ情報を表示します"

[ $# -lt 1 ] && for mes in "${u[@]}"; do echo " ${mes}" ; done && exit

prompt="${CMD_SESSION}> "

_date=$( date +%y%m%d );
_time=$( date "+%H%M%S" );
_date_time="${_date} ${_time}"

inputfile=${1}; 
[ -f ${inputfile} ] ||  abort "ファイル(${inputfile})がありません。終了します。" 

diffstd=60 ; # ファイルの時間とファイル名の時間のとの差である基準時間

# オプションの取得
[ $# -ge 2 ] && ifs=${2}  			||	ifs=""
[ $# -ge 3 ] && timediff=${3}		||	timediff="+000000"
[ $# -ge 4 ] && show_org=${4}		||	show_org=""
[ $# -ge 5 ] && show_maker=${5}	||	show_maker=""

[[ $timediff =~ ^[+-][0-9]{6}$ ]]	|| abort "ERROR: timediff=${timediff}は+/-付きの6桁の数字で入力してください"
sign_timediff="${timediff:0:1}"
second_timediff=$( bc <<< ${timediff:1:2}*3600+${timediff:3:2}*60+${timediff:5:2})

# ファイル関係の設定
dirname=$( dirname ${inputfile} )	
basename=${inputfile##*/} 	#${変数##パターン}  # 先頭から最長一致した部分を取り除く
filebody=${basename%.*}		#${変数%パターン}   # 末尾から最短一致した部分を取り除く
$debug $filebody
ext=${basename##*.} 		# exit # 拡張子を取り出す
[   ${dirname} = "." ] && fulldirname=$( pwd ); 
[ ! ${dirname} = "." ] && fulldirname=$( pwd )/${dirname};  
fulldirname=$( echo ${fulldirname} | sed -e 's#//*#/#' ) ; # 複数の///を一つにする
devicename=$( echo ${fulldirname} | awk '{split($0,a,"/"); print a[3]}' ) # 2つ目のディレクトリ名がデバイス名

# ログファイルの設定
dir_wav2aiff="${HOME}/.wav2aiff"
logfile="${dir_wav2aiff}/ICR2Kikimimi_$( gdate +%y%m%d-%H%M%S ).$$.log"; 
[ -e ${dir_wav2aiff} ] || mkdir ${dir_wav2aiff}
[ -e ${logfile} ]      || touch ${logfile}
echo -n ${logfile} | pbcopy

# 時間関係の設定
filedate=$(  		gls  -l --time-style=+%y%m%d ${inputfile} |awk '{print $6}' );
filestamp=$( 		gls  -l --time-style=+%H%M%S ${inputfile} |awk '{print $6}' );
epoch_filestamp=$( 	gls  -l --time-style="+%Y-%m-%d %H:%M:%S" ${inputfile} |awk '{print $6, $7}'| xargs -I{} gdate -d {} +%s );
epoch_filestamp=$( 	date -r ${inputfile} '+%s' );

_duration=$( soxi -d ${inputfile}) 
epoch_duration=$( echo  ${_duration:0:2}*3600+${_duration:3:2}*60+${_duration:6} | bc )

## ファイル名からメーカと機種(item)の決定 ###
### 666のKikimimiフォーマットなら時間変更だけ受け付ける
if [[ $filebody =~ ^[0-5][0-9][01][0-9][0-3][0-9]_[0-2][0-9][0-5][0-9][0-5][0-9]-[0-2][0-9][0-5][0-9][0-5][0-9]_[A-Z]* ]] ;then
	maker="Kikimimi"
	item="Kikimimi"

## $filebody=19090101場合：
elif [[ "$filebody" =~ ^[0-2][0-9][01][0-9][0-3][0-9][0-9][0-9]$ ]] ; then 
	# ファイル名＝15010100.WAV
	maker="SONY" ; # PCM-D1@SONY
	item="D1" ; # PCM-D1@SONY
# 同じファイル名の場合の振り分け
elif [[ $filebody =~ ^[0-2][0-9][01][0-9][0-3][0-9]_[0-9][0-9][0-9][0-9] ]]; then
    if	[[ ${devicename} = "DR-05" ]]; then
	# TASCAM filename=/Volumes/DR-05/190904_0005.mp3 
		maker="TASCAM";
		item="DR5";
	elif	 [[ $ext == "WAV" || $ext == "MP3" ]] ; then
	# DM-750は$filebodyだけだとAppleと区別できないなー。なので拡張子が大文字か小文字かで判別する
	# DM-750のfilename=/Volumes/DM750/RECORDER/FOLDER_A/191003_0017.MP3
		maker="OLYMPUS" ;
		item="DM" ;
	else
	# ファイル名＝160813_0000.wav
		maker="Apple" ; # 処理はSONYのD1と同じなのでそう設定する。
		item="iPhone" ; # Apple iPhoneのPCMRecoderのアプリの場合
    fi
elif [[ "$filebody" =~ ^[0-9][0-9][0-9][A-Z]_[0-2][0-9][01][0-9][0-3][0-9]_[0-2][0-9][0-5][0-9] ]] ; then 
	# ファイル名＝001A_170607_0201.MP3
	maker="SANYO" ; #Xacti@Sanyo1
	item="XT" ; # PCM-D1@SONY
elif [[ "$filebody" =~ ^[0-9][0-9][0-9]_[0-2][0-9][01][0-9][0-3][0-9]_[0-2][0-9][0-5][0-9] ]] ; then 
	# ファイル名＝001A_170607_0201.MP3
	maker="PANASONIC" ;  # RR-XS455@PANASONIC
	item="RR" ; # PCM-D1@SONY
elif [[ "$filebody" =~ ^ZOOM[0-9][0-9][0-9][0-9] ]] ; then # Zoomだ
	maker="ZOOM" ; 
	item="H6" ; # PCM-D1@SONY
elif [[ $filebody =~ ^LS ]]; then
	maker="OLYMPUS" ;
	item="L7" ;
elif [[ $filebody =~ ^REC[0-9][0-9][0-9] ]]; then
	maker="PECHAM" ;
	item="PE" ;
elif [[ $filebody =~ ^20[12][0-9]-[01][0-9]-[0-3][0-9]-[0-2][0-9]-[0-5][0-9]-[0-5][0-9] ]] && [ ${devicename} = "EVISTER-L36" ]; then
	maker="EVISTR" ;
	item="EV" ;
elif [[ $filebody =~ ^20[12][0-9]-[01][0-9]-[0-3][0-9]-[0-2][0-9]-[0-5][0-9]-[0-5][0-9] ]] && [ ${devicename} = "COOAU" ]; then
	maker="COOAU" ;
	item="CO" ;
elif [[ $filebody =~ ^20[12][0-9]-[01][0-9]-[0-3][0-9]-[0-2][0-9]-[0-5][0-9]-[0-5][0-9] ]] && [ ${devicename} = "TENSWALL" ]; then
	maker="TENSWALL" ;
	item="VR" ;
### [Xacti ICR^PS286RMの場合
elif [[ $filebody =~ ^IC_[A-D]_[0-9][0-9][0-9] ]] ; then
	maker="SANYO" ;
	item="XR" ;
else
     maker="un" ; # unkown
     echo "Maker is unkown. Quit!" >&2
     exit 1
fi

# Makerによりファイルの録音開始時間(filestart)と録音終了時間(filestop)を決定する
namestart=;
namestop=;
case "${item}" in 
	"DR")
		log='TASCAM';
		filewhich="終了"
		namedate=${filebody:0:6};
		;;
    "VR")
		logo='VoiveR';
		filewhich="終了"
		namedate=${filebody:2:2}${filebody:5:2}${filebody:8:2} ;
		namestart=${filebody:11:2}${filebody:14:2}${filebody:17:2} ;
		ifs="ifs"; #タイムスタンプを無視するモードにして名前の情報を使う
	;;
    "CO")
		logo='COOAU';
		filewhich="終了"
		namedate=${filebody:2:2}${filebody:5:2}${filebody:8:2} ;
		namestart=${filebody:11:2}${filebody:14:2}${filebody:17:2} ;
		ifs="ifs"; #タイムスタンプを無視するモードにして名前の情報を使う
	;;
    "EV")
		logo='EVISTR';
		filewhich="終了"
		namedate=${filebody:2:2}${filebody:5:2}${filebody:8:2} ;
		namestart=${filebody:11:2}${filebody:14:2}${filebody:17:2} ;
		ifs="ifs"; #タイムスタンプを無視するモードにして名前の情報を使う
	;;
    "PE")
		logo='PECHAM';
		filewhich="終了"
		namedate=;
	;;
    "L7")
		logo='OLYMPUS LS-7';
		filewhich="終了"
		namedate=; # ファイル名に日付情報がない
	;;
    "DM")
		logo='OLYMPUS DM-750';
		filewhich="開始"
		namedate=${filebody:0:6} ;
		namestart=${filebody:7:4}00: # 00秒を足しておく
	;;
    "iPhone" )
		logo='Apple iPhone'; 
		filewhich="終了" ; # filewhichはファイルスタンプの意味が開始か終了時間かでSANYOは開始時間
        namedate=${filebody:0:6} ;
		namestart=${filebody:7:6};
     ;;
     "D1" )     
		logo='SONY PCM-D1'
		filewhich="終了" ; # filewhichはファイルスタンプの意味が開始か終了時間かでSANYOは開始時間
        namedate=${filebody:0:6} ;
     ;;
     "RR" )
		logo='PANASONIC_RR-XS455' ;#  echo "$logo"
		filewhich="開始" ; # filewhichはファイルスタンプの意味が開始か終了時間か
        namedate=${filebody:4:6} ; # ファイル名の日付
		namestart="${filebody:11:4}00" ; # ファイル名の録音開始時間
     ;;
     "XT" )
		logo='SANYO_Xacti'
		filewhich="開始" ; # filewhichはファイルスタンプの意味が開始か終了時間かでSANYOは開始時間
		namedate=${filebody:5:6} ;
		namestart="${filebody:12:4}00" ; # ファイル名の録音開始時間
     ;;
     "XR" )
		logo='SANYO_Xacti'
		filewhich="開始" ; # filewhichはファイルスタンプの意味が開始か終了時間かでSANYOは開始時間
		namedate=${filedate}
		namestart=${filestamp} ; # ファイル名の録音開始時間
		namestop=$( add_time ${namestart} ${duration} ); #  "SANYO-namestop" ) 	;  echo "namestop=${namestop}"
     ;;

     "H6" )
		logo='Zoom_H6'
		filewhich="終了"
		hprjfile=$( ls ${dirname}/*.hprj )
		hprjbasename=${hprjfile##*/}
		hprjfilename=${hprjbasename%.*}
		namedate=${hprjfilename:0:6}
		namestart=${hprjfilename:7:6}
	;;

	"DR5" )
		logo='TASCAM_DR-05'
		filewhich="終了"
		namedate=$filedate
		
	;;

	"Kikimimi" )
		filewhich="開始"
		logo=
		namedate=${filebody:0:6};
		namestart=${filebody:7:6}
		filebody=${filebody:21};# 666の後の文字列を再入力する
esac     


#
# 名前とデュレテーション時間から時間を復元する
# 名前に時刻があればそれは開始と終了とに対応しているはずであるという仮定をおいている。
if [ -z $namestart ] && [ -z $namestop ]; then
	#名前に時間の情報がないのでifsを-にする
	ifs="-"
fi
if [ -z ${namestart} ] && [ ! -z $namestop ]; then 
	epoch_namestop=$( _66_to_epoch $namedate $namestop )
	epoch_namestart=$(bc <<< "$epoch_namestop - $epoch_duration" )
fi
if [ ! -z $namestart ] && [ -z ${namestop} ]; then
	epoch_namestart=$( _66_to_epoch $namedate $namestart )
	epoch_namestop=$(bc <<< "$epoch_namestart + $epoch_duration" )
fi
if [ ! -z $namestart ] && [ ! -z $namestop ]; then
	epoch_namestart=$( _66_to_epoch $namedate $namestart	)
	epoch_namestop=$(  _66_to_epoch $namedate $namestop		)
fi

#
# 開始と終了によりファイルスタンプから名前を得る
if [[ ${filewhich} = "開始" ]]; then 
	epoch_start=$epoch_filestamp
	epoch_stop=$(bc <<< "$epoch_start + $epoch_duration" )
	[ ! $ifs = "-" ]	&& diff=$( bc <<< "$epoch_start - $epoch_namestart");
else
	epoch_stop=$epoch_filestamp
	epoch_start=$(bc <<< "$epoch_stop - $epoch_duration" )
	[ ! $ifs = "-" ] 	&& diff=$(  bc <<< "$epoch_stop - $epoch_namestop");
fi

#
# ファイルスタンプと名前の時刻との整合性を確認する
[ ! $ifs = "-" ] && diff=$( bc <<< "sqrt( ( $(printf "%.0f" $diff ) )^2 )" )	|| diff=0

#  ifsの処理と時間差の計算===========

# ifsでファイルスタンプを無視して、名前からファイル名生成を試みる
case $ifs in
	"ifs" )
	# ファイル名から時刻を生成
	epoch_start=$(bc <<< "$epoch_namestart $sign_timediff $second_timediff" )
	epoch_stop=$( bc <<< "$epoch_namestop  $sign_timediff $second_timediff" )
	;;

	"ifn" )
	# ファイルのタイムスタンプで計算する
	epoch_start=$(bc <<< "$epoch_start $sign_timediff $second_timediff" )
	epoch_stop=$( bc <<< "$epoch_stop  $sign_timediff $second_timediff" )
	;;

	* )
	# 指定がないと止める
	[ ! -z ${namedate}           ] && \
	[ ${namedate} != ${filedate} ] && \
	abort 														\
		"$prompt ERROR:${logo}:ファイルスタンプ(filedate=${filedate})とファイル名(namedate=${namedate})の日付が合いません。ファイルスタンプを無視する場合はifsを、ファイル名の時刻を無視する場合はifnを設定してください"
	# ファイルスタンプの検証
	[ $diff -gt $diffstd 				 ] && \
	abort 														\
		"$prompt ERROR:${logo} ファイルスタンプとファイル名が${diffstd}秒以上の差があります。diff=$diff}。ファイル名から名前を生成する場合はifsオプション(ifs:1ignore file stamp)を追加してください"

esac
	

n__=$(	gdate -d @$epoch_start '+%y%m%d' )
_n_=$(	gdate -d @$epoch_start '+%H%M%S' )
__n=$(	gdate -d @$epoch_stop  '+%H%M%S' )

# ##### 出力ファイルの生成 ###################################
ext=${ext,,}; # 小文字化 ${v,,}
# 666形式のkikimimiなら何も出力しないが、その他は_を追加する
[ $item = "Kikimimi" ] && separator"" || separator="_"
outputfile="${n__}_${_n_}-${__n}_${item}${separator}${filebody}.$ext"
[[ "$show_org" 		= show_org 		]] && echo -n "$inputfile "
[[ "$show_maker" 	= show_maker 	]] && echo -n "$maker" "$item "

echo "$outputfile"  

# ######## バードリストやその他設定
birdlist="bird.list.20${namedate:0:2}.${namedate:2:2}.${namedate:4:2}.csv"
rate=$( soxi ${inputfile}  | grep "Sample Rate" 	| awk 'BEGIN{FS=": "}{print $2}')
depth=$(soxi ${inputfile}  | grep Precision 		| awk 'BEGIN{FS=": "}{print $2}')
depth=${depth:0:2} ; # 頭の2文字だけ取り出す
codec="pcm_s${depth}be"; 

######### 　表示　############################################    
echo "#${CMD_SESSION}> ************************************************"                  1>&2
echo "#${CMD_SESSION}> 処理日                      :now=$( date '+%Y-%m-%d %H:%M:%S')"    1>&2
echo "#${CMD_SESSION}> 入力ファイル名              :inputfile=${inputfile}"               1>&2
echo "#${CMD_SESSION}> 入力ファイルのディレクトリ名:fulldirname=${fulldirname}"           1>&2
echo "#${CMD_SESSION}> 出力ファイル名              :outputfile=${outputfile}"             1>&2
echo "#${CMD_SESSION}> メーカ                      :maker=${maker}"                       1>&2
echo "#${CMD_SESSION}> item                        :item=${item}"                         1>&2
echo "#${CMD_SESSION}> 機種                        :logo=${logo}"                         1>&2
echo "#${CMD_SESSION}> ファイル名日付              :namedate=${namedate}"                 1>&2
echo "#${CMD_SESSION}> ファイル名にある録音開始時間:namestart=${namestart}"               1>&2
echo "#${CMD_SESSION}> ファイル名にある録音終了時間:namestop=${namestop}"                 1>&2
echo "#${CMD_SESSION}> タイムスタンプ(日付)        :filedate=${filedate}"                 1>&2
echo "#${CMD_SESSION}> タイムスタンプ(時間)        :filestamp=${filestamp}"               1>&2
echo "#${CMD_SESSION}> タイムスタンプ(開始｜終了)  :filewhich=${filewhich}"               1>&2
echo "#${CMD_SESSION}> 曲の長さの時間              :duration=${_duration}"                1>&2
echo "#${CMD_SESSION}> 指定の時間差                :timediff=${timediff}"                 1>&2
echo "#${CMD_SESSION}> バードリスト                :birdlist=${birdlist}"                 1>&2
echo "#${CMD_SESSION}> サンプリングレート          :Sampling_Rate=${rate}"                1>&2
echo "#${CMD_SESSION}> サンプリングデプス          :Sampling_Depth=${depth}"              1>&2
echo "#${CMD_SESSION}> コーデック                  :codec=${codec}"                       1>&2

exit 0;
