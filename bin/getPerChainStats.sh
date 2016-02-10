ls run1/wekaOut/ | cut -d. -f1 > pdbids.txt
for i in $(cat pdbids.txt); do for j in {1..20}; do echo "$i, run $j"; calcStatsFromWEKAOutputCSV.pl -U ? S I run$j/wekaOut/$i.train.out ; done;  done
