#!/usr/bin/env bash
#
# media manager



function img::c {
  fd -d1 -e ${1:-pdf} -x gm mogrify -format ${2:-png} -density ${3:-300}
}

function img::e {
  fd -d1 -e ${1:-png} -x gm mogrify -border 100 -bordercolor white
}

function img::m {
  [[ ! -d $1 ]] && return
  fd . $1 -e png -x gm composite $de/m.png {} {}
}

function img::o {
  local opts=(-flatten +dither -white-threshold 97% -colors 128)
  #fd -p $1 -e png | xm gm convert "${opts[@]}" {} {}
  #fd -p $1 -e png | xargs -P8 -I@ gm convert "${opts[@]}" @ @
  #fd -p $1 -e png -x gm convert "${opts[@]}" {} {}
  fd -p $1 -e png | parallel --bar gm convert "${opts[@]}" {} {}
  mda::e
}

function img::r {
  fd -d1 -e ${2:-png} -x gm mogrify -resize ${1:-1800}\>
}

function img::s {
  fd -d1 -e ${1:-jpg} -x gm mogrify -strip
  mda::e
}

function img::t {
  fd -d1 -e ${1:-png} -x gm mogrify -trim
}

function img::x {
  local opts=(-trim -resize ${1:-1800}\> -border 100 -bordercolor white)
  fd -d1 -e ${1:-png} -x gm mogrify "${opts[@]}"
}

function img::? {
  printf "\n$c3 image commands$cr\n\n usage:\t$(basename $0) -$switch$c3 opts$cr [args$cd defaults$cr]\n
  $c3   c $cr convert     images from [ext$cd pdf$cr] to [ext$cd png$cr] with [density$cd 300$cr] in current dir
  $c3   e $cr extend      add white border to images [ext$cd png$cr] in current dir
  $c3   m $cr modify      composite$cb m.png$cr over images in [dir]
  $c3   o $cr optimize    recursively optimize images in [dir$cd current$cr]
  $c3   r $cr resize      reduce images to [size$cd 1800$cr] with [ext$cd png$cr] in current dir
  $c3   t $cr trim        images [ext$cd png$cr] in current dir
  $c3   h $cr help        \n\n"
}


function mda::c {
  [[ ! -f $1 || ! -f $2 ]] && mda::?
  exiftool -overwrite_original -q -TagsFromFile $1 -all $2
}

function mda::e {
  exiftool -overwrite_original -r -q -all= ${1:-.} 2>&-
  rn -c
}

function mda::l {
  local i='$album,$duration,$avgbitrate,$bitdepth,$imagewidth,$imageheight,'
  local f='$filepermissions,$filesize,$directory,$filename'
  local e="-ext m4a -ext mp4 -ext jpg -ext jpeg -ext heic -ext png -ext webp"
  exiftool -T -p $i$f $e ${1:-.} | column -ts, | sort -k11 | rg "$2"
}

function mda::m {
  [[ -d $1 ]] && b=${1%/} e=$2 || return
  case $e in
    gif) gm convert -delay ${3:-10} -loop 1 $1/*.* $b.$e ;;
    pdf) gm convert $1/*.* $b.$e ;;
  esac
}

function mda::s {
  [[ -f $1 ]] && d=${1%.*} e=${1##*.} || return
  case $e in
    gif) mkdir -p $d; gm convert -coalesce -quality ${2:-85} +adjoin $1 $d/%03d.jpg ;;
    pdf) mkdir -p $d; gm convert $1 +adjoin $d/%03d.$e ;;
  esac
}

function mda::? {
  printf "\n$c3 metadata commands$cr\n\n usage:\t$(basename $0) -$switch$c3 opts$cr args$cd defaults$cr\n
  $c3   c $cr copy        metadata from [file] to [file]
  $c3   e $cr erase       metadata for all files in [dir$cd current$cr] recursively
  $c3   l $cr list        metadata for all media files in [dir$cd current$cr]
  $c3   h $cr help        \n\n"
}



function vid::a {
  local s=(-vn)
  vid::x "$1" mp3 "${s[@]}"
}

function vid::c {
  local s=(-c copy)
  vid::x "$1" mp4 "${s[@]}"
}

function vid::o {
  local s=(-c:v libx264 -c:a aac)
  vid::x "$1" mp4 "${s[@]}"
}

function vid::r {
  local s=(-pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2")
  vid::x "$1" mp4 "${s[@]}"
}

function vid::s {
  local s=(-vf scale=-1:720 -c:v libx264 -c:a aac)
  vid::x "$1" mp4 "${s[@]}"
}

function vid::t {
  local d=$(ffprobe "$1" 2>$1 | rg Duration |  awk '{print $2}' | tr -d ,)
  vid::x "$1" mp4 -c copy -ss ${2:-"00:00:00"} -t ${3:-$d}
}

function vid::x {
  [[ ! -f $1 ]] && vid::?
  ffmpeg -v 0 -stats -i "$1" "${@:3}" "_${1%.*}".$2
}

function vid::? {
  printf "\n$c3 video commands$cr\n\n usage:\t$(basename $0) -$switch$c3 opts$cr [args$cd defaults$cr]\n
  $c3   a $cr audio       stream from [video] saved to mp3
  $c3   c $cr copy        video and audio streams from [video] to mp4
  $c3   o $cr optimize    convert and optimize [video] and save to mp4
  $c3   r $cr repair      [video] scale and save to mp4
  $c3   s $cr scale       [video] to 720p and save to mp4
  $c3   t $cr trim        [video] from [start time$cd 00:00:00$cr] for [duration$cd full$cr]
  $c3   h $cr help        \n\n"
}



function main::setopt {
  case $switch in
    i) com=img; setopt=cemorstx ;;
    m) com=mda; setopt=celms ;;
    v) com=vid; setopt=acorst ;;
    *) com=main;;
  esac
}

function main::switch {
  declare option OPTIND
  while getopts :$setopt option; do
    [[ $option == \? ]] && $com::? && exit
    $com::$option "${@:2}"
  done
  [[ $OPTIND == 1 ]] && $com::?
}

function main {
  if getopts :imv switch; then
    main::setopt
    main::switch "-${1:2}" "${@:2}"
  else
    mda::l "${@}"
  fi
}

function main::? {
  printf "\n$c3 media manager$cr\n\n usage:\t$(basename $0)$c3 switch$cr [opts] args\n
  $c3  -i $cr [cemorth]  $cb image$cr [convert extend modify optimize resize strip trim help]
  $c3  -m $cr [celmsh]   $cb metadata$cr [copy erase list merge split help]
  $c3  -v $cr [acorsth]  $cb video$cr [audio copy optimize repair scale trim help]
  $c3  -h $cr            $cb help$cr \n\n"

  printf "\n requires: bash_profile$cd colors$cr exiftool fd ffmpeg graphicsmagick parallel $cr\n\n"
}

main "${@}"
