#!/usr/bin/env bash
# ICRKikimimi.bash; 64形式に対応
# 2021-03-21 (C) woofie2wopper

CMD_SESSION=$( basename $0 )
d_log=$HOME/log
[ -d $d_log ] || mkdir $d_log
f_log="$d_log/$CMD_SESSION.$(date '+%y%m%d_%H%M%S').$$.clog"
# ################################################################################
# 使い方の表示関数
# ################################################################################
# u[i++]=" USAGE: ${CMD_SESSION} 030A_151204_1640.WAV [mf|-] [ifs|ifn] -090000 [show_org|-] show_maker" 
function show_usage() {
    echo "USAGE: ${CMD_SESSION} [options] inputfile"
    echo "機能：ファイルスタンプベースに666フォーマットのファイル名を返します。logファイルを出力します。場所は\$HOME/logです。"
    echo "Options:"
		echo "  -S               ファイルスタンプ(LastModifiedTime)を録音開始時間に設定する。"
		echo "  -E               ファイルスタンプ(LastModifiedTime)を録音終了時間に設定する（デフォルト）。"
		echo "  -R [date] [time] [date] [time]を241031 123345とすれば録音開始時刻を2024年10月31日12時33分45秒に設定します。-Sか-Eを指定してください。指定がない場合は-Sがデフォルトです"
		echo "  -I [item]        [item]はDR05, DR05X, LS7, H6, DM750, XACTIなどです。"
    echo "  -f [format]      [format] フォーマット。mfは森下フォーマット。出力は[モズ高鳴き_202109250740_東京都国分寺市_植田睦之.wav]で、拡張子は変えない"
    echo "  -t [timediff]    [timediff] 時差 : %H%M%Sで入力してください"
    echo "  -o [command]     オリジナルファイルを表示します。[command] コマンド表示モード。command=[mv, cp]"
		echo "  -d               デバッグモード"
    echo "  -h               ヘルプを表示します"
    echo "  -O [dir]        出力ディレクトリを指定します。指定がない場合は入力ファイルと同じディレクトリになります。"
    exit 0
}

# 66形式からエポック秒を得る(241031 123456 -> 2024-10-31 12:34:56)
function change_to_epoch_from_66() {
	local time="20${1:0:2}-${1:2:2}-${1:4:2} ${2:0:2}:${2:2:2}:${2:4:2}"
	date -d "$time" +%s
}

function error {
	 echo "$@" 
	 exit 0
}
# ################################################################################
# 初期化
# ################################################################################
exec 2> $f_log 
set -xveu

# ################################################################################
# オプションの取得
# ################################################################################
[ $# -eq 0 ] && show_usage

# デフォルト値の設定
is_start="TRUE"
item="none"
is_rectime="FALSE"
fmt="-"
timediff="+000000"
show_org="TRUE"
rectime="0"
debug=":"
file_date=""
file_time=""
command="mv "
output_dir=""
while getopts "SE:R:I:f:t:o:O:dh" opt; do
  case $opt in
    S) is_start="TRUE" ;;
    E) is_start="FALSE" ;;
    R) if [[ -z "$OPTARG" || "$OPTARG" == -* ]]; then
          error "オプション -R には6桁数字の引数が二つが必要です" 
        fi
			  is_rectime="TRUE";
			  file_date="$OPTARG" 
			  file_time="${!OPTIND}"; 
			  shift
			  [[ ${is_start:-null} = null ]] && is_start="TRUE"
		;;
    o) command="$OPTARG";
		   show_org="TRUE" ;;
    d) debug="echo " ;;
    h) show_usage ;;
    t) is_timediff="TRUE"; timediff="$OPTARG" ;;
		I) item="$OPTARG" ;;
    f) fmt="$OPTARG" ;;
    O) output_dir="$OPTARG"
       [ ! -d "$output_dir" ] && error "出力ディレクトリ(${output_dir})が存在しません。" ;;
    \?) echo "無効なオプション: -$OPTARG" >&2; show_usage ;;
    :) echo "オプション -$OPTARG には引数が必要です" >&2; show_usage ;;
  esac
done
inputfile="${@: -1}";
[ -z $inputfile ] && error "ファイルが指定されていません。"
[ -f $inputfile ] || error "ファイル(${inputfile})がありません。"
# file_date, file_timeのチェック
[[ $is_rectime = "TRUE" ]] && {
  [[ $file_date =~ ^[0-9]{6}$ ]] || error "file_date=${file_date}は6桁の数字で入力してください"
  [[ $file_time =~ ^[0-9]{6}$ ]] || error "file_time=${file_time}は6桁の数字で入力してください"
}

$debug "file_date: ${file_date:-"NONE"}"
$debug "file_time: ${file_time:-"NONE"}"
$debug "inputfile: ${inputfile:-"NONE"}"
$debug "item: ${item:-"NONE"}"
$debug "fmt: ${fmt:-"NONE"}"
$debug "timediff: ${timediff:-"NONE"}"
$debug "show_org: ${show_org:-"NONE"}"
$debug "command: ${command:-"NONE"}"
$debug "debug: ${debug:-"NONE"}"

# 時差のチェック
[[ $timediff =~ ^[+-][0-9]{6}$ ]] || error "ERROR: timediff=${timediff}は+/-付きの6桁の数字で入力してください"
sign_timediff="${timediff:0:1}"
second_timediff=$( echo ${timediff:1:2}*3600+${timediff:3:2}*60+${timediff:5:2} | bc )

# ################################################################################
# ファイル関係の設定
# ################################################################################
dirname=$( dirname ${inputfile} )	
basename=${inputfile##*/} 	#${変数##パターン}	# 先頭から最長一致した部分を取り除く
filebody=${basename%.*}		#${変数%パターン}	 # 末尾から最短一致した部分を取り除く
ext=${basename##*.} 		# exit # 拡張子を取り出す
case ${ext,,} in
  wav|mp3|aiff|flac|mp4|avi) : ;;
  *) error "ファイル形式(${ext})は音声・動画ファイルではありません。" ;;
esac

# ################################################################################
# 時間関係の設定
# ################################################################################
duration=$( ffprobe -i ${inputfile} -show_entries format=duration -v quiet -of csv="p=0" )
$debug "duration: ${duration}, $(TZ=UTC date -d @${duration} '+%H:%M:%S')"
# rectimeのパース|bc
if [ $is_rectime = "TRUE" ]; then
	epoch_filestamp=$( change_to_epoch_from_66 $file_date $file_time )
else
	epoch_filestamp=$( 	date -r ${inputfile} '+%s' 			);
fi
$debug "LastModifiedTime: $( date -d @${epoch_filestamp} '+%Y-%m-%d %H:%M:%S' )"
if [ $is_start = "TRUE" ]; then
  epoch_start=$( echo "$epoch_filestamp $sign_timediff $second_timediff"	| bc )
  epoch_stop=$(	 echo "$epoch_filestamp	$sign_timediff $second_timediff + $duration"	| bc )
else
  epoch_start=$( echo "$epoch_filestamp	$sign_timediff $second_timediff - $duration"	| bc )
  epoch_stop=$(	 echo "$epoch_filestamp	$sign_timediff $second_timediff"	| bc )
fi
# ################################################################################
# 森下フォーマットの入力
# ################################################################################
if [ $fmt = "mf" ]; then
	# 種名
	declare -a bird
	bird[1]="モズ高鳴き"
	bird[2]="モズグゼリ"
	bird[3]="ジョウビタキ地鳴き"
	bird[4]="ツグミ地鳴き"
	i=0;
	for value in ${bird[@]}; do
		i=$(echo $i + 1 |bc)
		echo "$i: ${value}" 
	done
	echo -n "番号を入力してください:" 
	read -p "番号を入力してください:" INPUT
	birdname=${bird[$INPUT]}
	# 観察場所の連想配列
	declare -a Site
	Site[1]="福井県越前市"
	Site[2]="神奈川県大磯町"
	echo "場所の入力："
	i=0;
	for value in ${Site[@]} ; do
		i=$(echo $i + 1 |bc)
		echo "${i}: ${value}" 
	done
	#echo -n "番号を入力してください:" 
	read -p "番号を入力してください:" INPUT
	place=${Site[$INPUT]}
	outputfile="${birdname}_$(date -d @$epoch_start '+%Y%m%d%H%M%S')_${place}_大坂英樹".$ext
fi

n__=$(	date -d @$epoch_start '+%y%m%d' )
_n_=$(	date -d @$epoch_start '+%H%M%S' )
__n=$(	date -d @$epoch_stop	'+%H%M%S' )

# ################################################################################
# 出力ファイルの生成 
# ################################################################################
$debug "show_org: ${show_org}"
[[ "$show_org" = "TRUE" 	]] && echo -n "$command ${inputfile} "

# 出力ディレクトリの設定
output_dir=${output_dir:-$dirname}

if [ $fmt = "mf" ]; then
  outputfile="${output_dir}/${birdname}_$(date -d @$epoch_start '+%Y%m%d%H%M%S')_${place}_大坂英樹".$ext
else
  outputfile="${output_dir}/${n__}_${_n_}_${__n}_${item}_${filebody}.$ext"
fi
echo "$outputfile"	
exit 0;

################################################################################
# 名前とデュレテーション時間から時間を復元する
################################################################################
# ファイルの時間とファイル名の時間のとの差である基準時間
# diffstd=60; 
# 名前に時刻があればそれは開始と終了とに対応しているはずであるという仮定をおいている。
# [[ $namestart =~ ^[0-9]{6}$ ]] && isValidNameStart=TRUE || isValidNameStart=FALSE
# [[ $namestop =~ ^[0-9]{6}$ ]] && isValidNameStop=TRUE || isValidNameStop=FALSE
# 
# if [ $isValidNameStart ] && [ $isValidNameStop ]; then
	# 名前に時間の情報がないのでifsを-にする
	# ifs="-"
# fi
# if [ $isValidNameStart ] && [ ! $isValidNameStop ]; then 
	# epoch_namestop=$( change_to_epoch_from_66 $namedate $namestop )
	# epoch_namestart=$( echo "$epoch_namestop - $duration" | bc )
# fi
# if [ ! $isValidNameStart ] && [ $isValidNameStop ]; then
	# epoch_namestart=$( change_to_epoch_from_66 $namedate $namestart )
	# epoch_namestop=$( echo "$epoch_namestart + $duration" | bc )
# fi
# if [ ! $isValidNameStart ] && [ ! $isValidNameStop ]; then
	# epoch_namestart=$( change_to_epoch_from_66 $namedate $namestart	)
	# epoch_namestop=$(	change_to_epoch_from_66 $namedate $namestop		)
# fi

# ################################################################################
# 開始と終了によりファイルスタンプから名前を得る
# ################################################################################
#  if [[ ${filewhich} = "開始" ]]; then 
#  	epoch_start=$epoch_filestamp
#  	epoch_stop=$( echo "$epoch_start + $duration" | bc )
#  	[ ! $ifs = "-" ]	&& diff=$( echo "$epoch_start - $epoch_namestart" | bc );
#  else
#  	epoch_stop=$epoch_filestamp
#  	epoch_start=$( echo "$epoch_stop - $duration" | bc )
#  	[ ! $ifs = "-" ] 	&& diff=$(	echo "$epoch_stop - $epoch_namestop" | bc );
#  fi
#  
#  # ファイルスタンプと名前の時刻との整合性を確認する
#  [ ! $ifs = "-" ] && diff=$( echo "sqrt( ( $(printf "%.0f" $diff ) )^2 )" | bc )	|| diff=0
#  
#  #	ifsの処理と時間差の計算===========
#  
#  # ifsでファイルスタンプを無視して、名前からファイル名生成を試みる
#  case $ifs in
#  	"ifs" )
#  		# ファイル名から時刻を生成
#  		epoch_start=$( echo "$epoch_namestart $sign_timediff $second_timediff"	| bc )
#  		epoch_stop=$(	echo "$epoch_namestop	$sign_timediff $second_timediff"	| bc )
#  	;;
#  
#  	"ifn" )
#  		# ファイルのタイムスタンプで計算する
#  		epoch_start=$( echo "$epoch_start $sign_timediff $second_timediff"	| bc )
#  		epoch_stop=$(	echo "$epoch_stop	$sign_timediff $second_timediff"	| bc )
#  	;;
#  
#  	* )
#  	# 指定がないと止める
#  	[ ! -z ${namedate}					 ] && \
#  	[ ${namedate} != ${filedate} ] && \
#  	error 														\
#  		"$prompt ERROR:${logo}:ファイルスタンプ(filedate=${filedate})とファイル名(namedate=${namedate})の日付が合いません。ファイルスタンプを無視する場合はifsを、ファイル名の時刻を無視する場合はifnを設定してください"
#  	# ファイルスタンプの検証
#  	[ $diff -gt $diffstd 				 ] && \
#  	error 														\
#  		"$prompt ERROR:${logo} ファイルスタンプとファイル名が${diffstd}秒以上の差があります。diff=$diff}。ファイル名から名前を生成する場合はifsオプション(ifs:1ignore file stamp)を追加してください"
#  
#  esac
#  	
# epoch_rectimeが0でなければ強制的にepoch_startをepoch_rectimeにする
#  [ $epoch_rectime != "0" ] && epoch_start=$epoch_rectime && epoch_stop=$( echo "$epoch_start + $duration" | bc )
#  
#  n__=$(	date -d @$epoch_start '+%y%m%d' )
#  _n_=$(	date -d @$epoch_start '+%H%M%S' )
#  __n=$(	date -d @$epoch_stop	 '+%H%M%S' )
