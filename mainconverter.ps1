
$root = ".\videos"   # root directory to convert videos  
$Env:Path += ';..\..\bin' ## pathにffmpeg追加 通常は絶対パスを使用する
$dirstr = " ディレクトリ: "  ## dirコマンドの出力でディレクトリを意味するキーワード　実行の言語環境により要変更

dir $root  -recurse convert > temp.txt  ## convert というフォルダを探す

$d1 = select-string 'ディレクトリ:' temp.txt  ## ディレクトリ名を含む行を配列に格納


foreach($elm in $d1) {
  $elms= [String] $elm
  if ($elms -eq $null) {break}

  $dirstrlen = $dirstr.Length
  $len = $elms.Length
  $pos = $elms.IndexOf($dirstr)
  $cvtp = $elms.Substring($pos+$dirstrlen,$len-$pos-$dirstrlen)  ## convert フォルダへのフルパスを取り出す
  echo $cvtp
  .\convertmovie.ps1 $cvtp  ## 該当フォルダの変換処理を実行
}
