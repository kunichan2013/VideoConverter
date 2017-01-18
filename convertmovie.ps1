
#
# 与えられたpath内のconvertフォルダ内の動画をMP4, FLVに変換する
#

$pathname = $Args[0]

$width=0   ## video 幅
$height=0  ## video 高さ
$maxwidth = 1024  ##  幅の最大値


function getmoviesize($fname) {
    
    $script:width=0
    $script:height=0
    
	$result = ffmpeg.exe -i $fname 2>&1 

	foreach($elm in $result) {

	    $ln=$elm.ToString()
	    
	    if ($ln.Contains("Video:")) {
	        ## echo "***** $i *****" $ln
	        if ($ln -match "\d{2,4}[x]\d{2,4}") {  ## 9999x9999 の文字列を取り出す
	            $size=$matches[0]
	            ## $size.split("x")
	            $script:width=  $size.split("x")[0] - 0  ## xの前の文字列を取り出し、数値変換のためにゼロを引く
	            $script:height= $size.split("x")[1] - 0  ## xの後の文字列を取り出し、数値変換のためにゼロを引く
	            ## echo "( $width,$height )"
	            return
	        }
	    }
	    
	}

}  ## end of funcion


if ($pathname -eq $null) 
{
  echo "引数なし エラー"
  exit
}

echo " "
echo "=============================================================="
echo " "

## Sub Dir 作成

cd -literalpath $pathname   ## -literalpathは絶対パスを含む処理にのみ使用する

if (-not(Test-Path ./MP4/))
{
    mkdir MP4
} 
if (-not(Test-Path ./FLV/))
{
    mkdir FLV
}
if (-not(Test-Path ./error/))
{
    mkdir error
}
if (-not(Test-Path ./source/))
{
    mkdir source
}


## Start

$dd = Get-Date

$dt = $dd.ToString("yyyy/MM/dd HH:mm:ss")

echo " "
echo "$dt <$pathname>の変換処理を開始します"

cd ./convert

$fnarray = dir  -include *.mp4,*.flv,*.mpg,*.mov,*.avi,*.wmv -Name

if (($fnarray.Length  -eq 0) -or ($fnarray -eq $null)  ) 
{
   echo 該当ファイルなしのため終了します
   exit
} 

if (Test-Path cvtlog.txt) {
    del cvtlog.txt
}



## MP4作成処理

echo " " 

foreach ($fname in $fnarray)
{
  echo "From <$fname>"   
  $mp4fname =  [System.IO.Path]::ChangeExtension($fname, ".mp4") 
  echo "To   <$mp4fname>" 

  ## 動画のサイズ調整

  getmoviesize($fname)
  
  if ($width -gt $maxwidth) {

      $height = $height * ($maxwidth/$width)
      $width = $maxwidth
      $resize =  [string]$width + "x" + [string]$height
      echo " $fname を $resize に変換"
    
  } else {
      $resize = [string]$width + "x" + [string]$height
  }


  ## ffmpeg -i $fname -f mp4 -s $resize -y -q:a 1  -q:v 1  -vcodec libx264 ../MP4/$mp4fname 2>> cvtlog.txt
  ffmpeg -i $fname -f mp4 -s $resize -y -q:a 1  -q:v 1  -pix_fmt yuv420p  ../MP4/$mp4fname 2>> cvtlog.txt

  ## ffmpegのパラメータとしてパラメータの識別子を含む文字列（例 "-s 1024x768")を渡すとエラーになるので
  ## パラメータの値のみ（"1024x768"）を変数で渡すこと
  <#   パラメータの意味　
        -i 入力ファイル
        -f mp4 　　 　　 MP4フォーマットで出力
        -s 画面サイズ
        -y   　　　　　　は出力を上書きする
        -q:a 1  -q:v 1 　 はオーディオもビデオもオリジナルと同じ品質と言う意味
        -pix_fmt yuv420p ピクセルフォーマット（カラーフォーマット）yuv420p　を用いる
        最後のパラメータが出力ファイル名

  #>
  

  if ($lastexitcode -eq 0) 
  {
    echo "MP4変換終了　\MP4 フォルダに保存しました"
    
  } else 
  {
    echo "変換エラー　リターンコード＝$lastexitcode"
    echo "音声データが正しく記録されていない場合にはエラーの可能性があるので、音声データを無視して再度変換します。"
    
    ## ffmpeg -i $fname -f mp4 -s $resize -y -q:a 1  -q:v 1  -an -vcodec libx264 ../MP4/$mp4fname 2>> cvtlog.txt
    ffmpeg -i $fname -f mp4 -s $resize -y -q:a 1  -q:v 1  -an -pix_fmt yuv420p  ../MP4/$mp4fname 2>> cvtlog.tx
      ## -anでオーディオなしとなる



    if ($lastexitcode -eq 0) 
    {
        echo "MP4音声なし変換終了　\MP4 フォルダに保存しました"
    } else 
    {

        echo "音声なし変換エラー　リターンコード＝$lastexitcode"

        $p1=$pathname+'\convert\'+$fname
        $p2=$pathname+'\error\'+$fname

        [System.IO.File]::Delete($p2)    
        [System.IO.File]::Move($p1,$p2)

        echo "\error フォルダに移動しました"
    
        $p3=$pathname+'\MP4\'+$mp4fname   
        [System.IO.File]::Delete($p3)    
        ## 変換後ファイルがあれば不正なので削除(ファイルなしでもエラーにはならない）
    }
  }
  
}
echo MP4作成終了しました



## FLV作成処理

$fnarray = dir  -include *.mp4,*.flv,*.mpg,*.mov,*.avi,*.wmv -Name ##再度ファイル名を取得

echo " " 

foreach ($fname in $fnarray)
{
  if ($fname -eq $null) { break } ##MP4変換でエラーのファイルは移動しているのでファイルリストがNULLならば終了
  
  echo "From <$fname>"   
  $flvfname =  [System.IO.Path]::ChangeExtension($fname, ".flv") 
  echo "To   <$flvfname>" 

  ffmpeg -i $fname -f flv -s $resize  -y -q:a 1  -q:v 1 -vcodec flv ../FLV/$flvfname 2>> cvtlog.txt

  ## echo "<<$lastexitcode>>"
  if ($lastexitcode -eq 0) 
  {
    echo "FLV変換終了　\FLV フォルダに保存しました"
    $p1=$pathname+'\convert\'+$fname
    $p2=$pathname+'\source\'+$fname
    
    [System.IO.File]::Delete($p2)    
    [System.IO.File]::Move($p1,$p2)
    
    echo "変換前のファイルは\source フォルダに移動しました"
    
  } else 
  {
    echo "変換エラー　リターンコード＝$lastexitcode"
    echo "音声データが正しく記録されていない場合にはエラーの可能性があるので、音声データを無視して再度変換します。"
    
    ffmpeg -i $fname -f flv -s $resize -y -q:a 1  -q:v 1 -an -vcodec flv ../FLV/$flvfname 2>> cvtlog.txt

    if ($lastexitcode -eq 0) 
    {
        echo "FLV音声なし変換終了　\FLV フォルダに保存しました"
        $p1=$pathname+'\convert\'+$fname
        $p2=$pathname+'\source\'+$fname
    
        [System.IO.File]::Delete($p2)    
        [System.IO.File]::Move($p1,$p2)
    
        echo "変換前のファイルは\source フォルダに移動しました"

    } else 
    {
        echo "音声なし変換エラー　リターンコード＝$lastexitcode"

        $p1=$pathname+'\convert\'+$fname
        $p2=$pathname+'\error\'+$fname

        [System.IO.File]::Delete($p2)    
        [System.IO.File]::Move($p1,$p2)

        echo "\error フォルダに移動しました"
    
        $p3=$pathname+'\FLV\'+$flvfname   
        [System.IO.File]::Delete($p3)    
        ## 変換後ファイルがあれば不正なので削除(ファイルなしでもエラーにはならない）
    }       
  }
  
}

echo FLV作成終了しました

##  全体終了

$dd = Get-Date

$dt = $dd.ToString("yyyy/MM/dd hh:mm:ss")

echo " "
echo "$dt <$pathname>の変換処理が終了しました"
echo "=============================================================="
echo " "

## End Of Script
